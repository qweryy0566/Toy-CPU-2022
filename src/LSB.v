`include "config.v"

`ifndef __LSBuffer__
`define __LSBuffer__

module LSBuffer (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire                  jump_flag,

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

  // debug
  output wire                 debug_out_bit,
  output wire                 isReady_3,
  output wire [`ROB_LOG - 1:0] debug_out_Q,

  output wire                 LSB_next_full
);

  reg                  isBusy[`LSB_SIZE - 1:0];
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

  reg[`ROB_LOG - 1:0]  head, tail;
  wire                 isEmpty;
  wire [4:0]           top_id = head + 1 & `ROB_SIZE - 1;
  wire [4:0]           next = tail + 1 & `ROB_SIZE - 1;
  integer i, j, cnt, empty_pos;

  assign LSB_next_full = (tail + 2 & `ROB_SIZE - 1) == head;
  assign isEmpty = head == tail;

  reg                  isWaitingMem;

  // debug
  assign debug_out_bit = Rj[3];
  assign debug_out_Q = Qj[3];
  assign isReady_3 = isReady[3];


  // issue value should be updated from the broadcast value
  wire [31:0]           real_Vj = exc_valid && exc_RobId == issue_Qj
                                    ? exc_value
                                    : B_enable && B_RobId == issue_Qj ? B_value : issue_Vj;
  wire [31:0]           real_Vk = exc_valid && exc_RobId == issue_Qk
                                    ? exc_value
                                    : B_enable && B_RobId == issue_Qk ? B_value : issue_Vk;
  wire                  real_Rj = exc_valid && exc_RobId == issue_Qj 
                                    ? 1
                                    : B_enable && B_RobId == issue_Qj ? 1 : issue_Rj;
  wire                  real_Rk = exc_valid && exc_RobId == issue_Qk 
                                    ? 1
                                    : B_enable && B_RobId == issue_Qk ? 1 : issue_Rk;
  wire [`ROB_LOG - 1:0] real_Qj = exc_valid && exc_RobId == issue_Qk 
                                    ? 0
                                    : B_enable && B_RobId == issue_Qj ? 0 : issue_Qj;
  wire [`ROB_LOG - 1:0] real_Qk = exc_valid && exc_RobId == issue_Qk 
                                    ? 0
                                    : B_enable && B_RobId == issue_Qk ? 0 : issue_Qk;

  always @(posedge clk) begin
    if (rst) begin
      head <= 0;
      tail <= 0;
      isWaitingMem <= 0;
      for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        isReady[i] <= 0;
        isBusy[i] <= 0;
      end 
    end else if (~rdy) begin
      
    end else if (jump_flag) begin
      if (~isEmpty && isReady[top_id])
        tail <= top_id;
      else
        tail <= head;
      for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        isBusy[i] <= 0;
      end
      if (isWaitingMem && (mem_success || ~isEmpty && OpType[top_id] < `OP_SB)) begin
        isWaitingMem <= `FALSE;
        mem_enable <= `FALSE;
        head <= top_id;
        tail <= top_id;
      end
    end else begin
      if (issue_valid) begin
        isBusy[next] <= 1;
        isReady[next] <= 0;
        OpType[next] <= issue_op;
        Vj[next] <= real_Vj;
        Vk[next] <= real_Vk;
        Rj[next] <= real_Rj;
        Rk[next] <= real_Rk;
        Qj[next] <= real_Qj;
        Qk[next] <= real_Qk;
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

      store_enable <= `FALSE;
      if (OpType[top_id] >= `OP_SB && Rj[top_id] && Rk[top_id]) begin
        store_enable <= `TRUE;
        store_RobId <= DestRob[top_id];
      end

      if (rob_committed)
        for (i = 0; i < `LSB_SIZE; i = i + 1)
          if (DestRob[i] == rob_RobId)
            isReady[i] <= `TRUE;

      B_enable <= `FALSE;
      if (isWaitingMem) begin
        if (mem_success) begin
          mem_enable <= `FALSE;
          if (mem_wr_tag == `LOAD) begin
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
          isWaitingMem <= `FALSE;
          head <= top_id;
          isBusy[top_id] <= `FALSE;
        end
      end else begin
        if (~isEmpty && Rj[top_id] && Rk[top_id]) begin
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