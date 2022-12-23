`include "config.v"

`ifndef __LSBuffer__
`define __LSBuffer__

module LSBuffer (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire                  jump_flag,
  input wire [`ROB_LOG - 1:0] rob_top_id,

  input wire                  issue_valid,
  input wire [`OP_LOG - 1:0]  issue_op,
  input wire [31:0]           issue_Vj,
  input wire                  issue_Rj,
  input wire [`ROB_LOG - 1:0] issue_Qj,
  input wire [31:0]           issue_Vk,
  input wire                  issue_Rk,
  input wire [`ROB_LOG - 1:0] issue_Qk,
  input wire [31:0]           issue_Imm,
  input wire [`ROB_LOG - 1:0] issue_DestRob,

  input wire                  rob_committed,
  input wire [`ROB_LOG - 1:0] rob_RobId,

  // broadcast from FU
  input wire                  exc_valid,
  input wire [`ROB_LOG - 1:0] exc_RobId,
  input wire [31:0]           exc_value,

  output reg                  mem_enable,
  output reg [2:0]            op_size,
  output reg [31:0]           mem_addr,
  output reg [31:0]           mem_wdata,
  output reg                  mem_wr_tag,
  input wire                  mem_success,
  input wire [31:0]           mem_rdata,

  // LSB broadcast to ROB, RS and LSB
  output reg                  B_enable,
  output reg [`ROB_LOG - 1:0] B_RobId,
  output reg [31:0]           B_value,

  // LSB broadcast to ROB specially for store
  output reg                  store_enable,
  output reg [`ROB_LOG - 1:0] store_RobId,

  output wire                 LSB_next_full
);

  reg                  isBusy[`LSB_SIZE - 1:0];
  reg                  isSendToRob[`LSB_SIZE - 1:0];
  reg                  isReady[`LSB_SIZE - 1:0];
  reg [`OP_LOG - 1:0]  OpType[`LSB_SIZE - 1:0];
  reg [31:0]           Vj[`LSB_SIZE - 1:0];
  reg [31:0]           Vk[`LSB_SIZE - 1:0];
  reg                  Rj[`LSB_SIZE - 1:0];  // value is ready
  reg                  Rk[`LSB_SIZE - 1:0];  // value is ready
  reg [`ROB_LOG - 1:0] Qj[`LSB_SIZE - 1:0];
  reg [`ROB_LOG - 1:0] Qk[`LSB_SIZE - 1:0];
  reg [31:0]           Imm[`LSB_SIZE - 1:0];
  reg [`ROB_LOG - 1:0] DestRob[`LSB_SIZE - 1:0];

  reg[`LSB_LOG - 1:0]   head, tail, lst_committed;
  wire                  isEmpty;
  wire [`LSB_LOG - 1:0] top_id = head + 1 & `LSB_SIZE - 1;
  wire [31:0]           top_addr = Vj[top_id] + Imm[top_id];
  wire [`LSB_LOG - 1:0] next = tail + 1 & `LSB_SIZE - 1;

  integer i, j, cnt, empty_pos;

  assign LSB_next_full = (tail + 2 & `LSB_SIZE - 1) == head;
  assign isEmpty = head == tail;

  reg                  isWaitingMem;

  always @(posedge clk) begin
    B_enable <= `FALSE;
    store_enable <= `FALSE;
    if (rst || jump_flag && lst_committed == head) begin
      head <= 0;
      tail <= 0;
      lst_committed <= 0;
      isWaitingMem <= 0;
      mem_enable <= 0;
      for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        isReady[i] <= 0;
        isBusy[i] <= 0;
        isSendToRob[i] <= 0;
        Rj[i] <= 0;
        Rk[i] <= 0;
      end 
    end else if (~rdy) begin
      
    end else if (jump_flag) begin
      tail <= lst_committed;
      for (i = 0; i < `LSB_SIZE; i = i + 1) 
        if (~isBusy[i] || ~isReady[i]) begin
          isBusy[i] <= 0;
          isSendToRob[i] <= 0;
          Rj[i] <= 0;
          Rk[i] <= 0;
        end
      if (isWaitingMem && mem_success) begin
        isWaitingMem <= `FALSE;
        mem_enable <= `FALSE;
        head <= top_id;
        if (lst_committed == head) lst_committed <= top_id;
        isBusy[top_id] <= `FALSE;
        isReady[top_id] <= `FALSE;
        isSendToRob[top_id] <= `FALSE;
        Rj[top_id] <= `FALSE;
        Rk[top_id] <= `FALSE;
      end
    end else begin
      if (issue_valid) begin
        isBusy[next] <= 1;
        isReady[next] <= 0;
        isSendToRob[next] <= 0;
        OpType[next] <= issue_op;
        Vj[next] <= issue_Vj;
        Vk[next] <= issue_Vk;
        Rj[next] <= issue_Rj;
        Rk[next] <= issue_Rk;
        Qj[next] <= issue_Qj;
        Qk[next] <= issue_Qk;
        Imm[next] <= issue_Imm;
        DestRob[next] <= issue_DestRob;
        tail <= next;
      end
      
      if (exc_valid)
        for (i = 0; i < `LSB_SIZE; i = i + 1)
          if (isBusy[i]) begin
            if (~Rj[i] && Qj[i] == exc_RobId) begin
              Rj[i] <= `TRUE;
              Vj[i] <= exc_value;
            end
            if (~Rk[i] && Qk[i] == exc_RobId) begin
              Rk[i] <= `TRUE;
              Vk[i] <= exc_value;
            end
          end

      if (B_enable)
        for (i = 0; i < `LSB_SIZE; i = i + 1)
          if (isBusy[i]) begin
            if (~Rj[i] && Qj[i] == B_RobId) begin
              Rj[i] <= `TRUE;
              Vj[i] <= B_value;
            end
            if (~Rk[i] && Qk[i] == B_RobId) begin
              Rk[i] <= `TRUE;
              Vk[i] <= B_value;
            end
          end

      if (~isEmpty && OpType[top_id] >= `OP_SB && Rj[top_id] && Rk[top_id] && !isSendToRob[top_id]) begin
        store_enable <= `TRUE;
        isSendToRob[top_id] <= `TRUE;
        store_RobId <= DestRob[top_id];
      end

      if (rob_committed)
        for (i = 0; i < `LSB_SIZE; i = i + 1)
          if (isBusy[i] && DestRob[i] == rob_RobId) begin
            isReady[i] <= `TRUE;
            lst_committed <= i;
          end

      if (isWaitingMem) begin
        if (mem_success) begin
          if (mem_wr_tag == `LOAD && mem_enable) begin
            B_enable <= `TRUE;
            B_RobId <= DestRob[top_id];
            case (OpType[top_id])
              `OP_LB: B_value <= {{24{mem_rdata[7]}}, mem_rdata[7:0]};
              `OP_LH: B_value <= {{16{mem_rdata[15]}}, mem_rdata[15:0]};
              `OP_LW: B_value <= mem_rdata;
              `OP_LBU: B_value <= {{24{1'b0}}, mem_rdata[7:0]};
              `OP_LHU: B_value <= {{16{1'b0}}, mem_rdata[15:0]};
            endcase
          end
          mem_enable <= `FALSE;
          isWaitingMem <= `FALSE;
          head <= top_id;
          if (lst_committed == head) lst_committed <= top_id;
          isBusy[top_id] <= `FALSE;
          isReady[top_id] <= `FALSE;
          Rj[top_id] <= `FALSE;
          Rk[top_id] <= `FALSE;
        end
      end else begin
        // Input 操作需要等到其成为 ROB 的 top 项才能开始
        if (~isEmpty && Rj[top_id] && Rk[top_id]
            && (!(top_addr[17:16] == 2'b11 && OpType[top_id] < `OP_SB) || DestRob[top_id] == rob_top_id)) begin
          case (OpType[top_id])
            `OP_LB, `OP_LBU: begin
              mem_enable <= `TRUE;
              op_size <= 3'b001;
              mem_addr <= Vj[top_id] + Imm[top_id];
              mem_wr_tag <= `LOAD;
              isWaitingMem <= `TRUE;
            end
            `OP_LH, `OP_LHU: begin
              mem_enable <= `TRUE;
              op_size <= 3'b010;
              mem_addr <= Vj[top_id] + Imm[top_id];
              mem_wr_tag <= `LOAD;
              isWaitingMem <= `TRUE;
            end
            `OP_LW: begin
              mem_enable <= `TRUE;
              op_size <= 3'b100;
              mem_addr <= Vj[top_id] + Imm[top_id];
              mem_wr_tag <= `LOAD;
              isWaitingMem <= `TRUE;
            end
            `OP_SB: 
              if(isReady[top_id]) begin
                mem_enable <= `TRUE;
                op_size <= 3'b001;
                mem_addr <= Vj[top_id] + Imm[top_id];
                mem_wdata <= Vk[top_id];
                mem_wr_tag <= `STORE;
                isWaitingMem <= `TRUE;
              end
            `OP_SH:
              if(isReady[top_id]) begin
                mem_enable <= `TRUE;
                op_size <= 3'b010;
                mem_addr <= Vj[top_id] + Imm[top_id];
                mem_wdata <= Vk[top_id];
                mem_wr_tag <= `STORE;
                isWaitingMem <= `TRUE;
              end
            `OP_SW:
              if(isReady[top_id]) begin
                mem_enable <= `TRUE;
                op_size <= 3'b100;
                mem_addr <= Vj[top_id] + Imm[top_id];
                mem_wdata <= Vk[top_id];
                mem_wr_tag <= `STORE;
                isWaitingMem <= `TRUE;
              end
          endcase
        end
      end
    end
  end

  
endmodule

`endif