`include "config.v"

`ifndef __ROB__
`define __ROB__

module ROB (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire                  issue_valid,
  input wire [`OP_LOG - 1:0]  issue_op,
  input wire [4:0]            issue_dest,

  input wire                  exc_valid,
  input wire [31:0]           exc_value,
  input wire [31:0]           exc_toPC,
  input wire [`ROB_LOG - 1:0] exc_RobId,

  input wire                  lsb_valid,
  input wire [31:0]           lsb_value,
  input wire [`ROB_LOG - 1:0] lsb_RobId,

  input wire                  store_valid,
  input wire [`ROB_LOG - 1:0] store_RodId,

  // commit wire
  output reg                  reg_enable,
  output reg [4:0]            reg_index,
  output reg [`ROB_LOG - 1:0] reg_RobId,
  output reg [31:0]           reg_value,
  
  output reg                  jump_flag,
  output reg [31:0]           if_toPC,

  output reg                  lsb_begin_store,
  output reg [`ROB_LOG - 1:0] lsb_store_RobId,

  input wire [`ROB_LOG - 1:0] issue_query_rs1,
  input wire [`ROB_LOG - 1:0] issue_query_rs2,
  output reg                  rs1_ready,
  output reg [31:0]           rs1_value,
  output reg                  rs2_ready,
  output reg [31:0]           rs2_value,

  output reg                  rob_next_full,
  output reg [`ROB_LOG - 1:0] rob_next
);

  reg[`ROB_LOG - 1:0]  head, tail;
  reg                  isEmpty;
  reg                  isReady[`ROB_SIZE - 1:0];
  reg [`OP_LOG - 1:0]  OpType[`ROB_SIZE - 1:0];
  reg[4:0]             DestReg[`ROB_SIZE - 1:0];
  reg[31:0]            Value[`ROB_SIZE - 1:0];
  reg[31:0]            ToPC[`ROB_SIZE - 1:0];


  wire [4:0] top_id = head + 1 & `ROB_SIZE - 1;
  integer i, j, cnt, empty_pos;

  always @(*) begin
    rob_next_full = (tail + 2 & `ROB_SIZE - 1) == head;
    rob_next = tail + 1 & `ROB_SIZE - 1;
    isEmpty = head == tail;
  end

  always @(*) begin
    if (isReady[issue_query_rs1]) begin
      rs1_ready = 1;
      rs1_value = Value[issue_query_rs1];
    end else begin
      rs1_ready = 0;
      rs1_value = 0;
    end
    if (isReady[issue_query_rs2]) begin
      rs2_ready = 1;
      rs2_value = Value[issue_query_rs2];
    end else begin
      rs2_ready = 0;
      rs2_value = 0;
    end
  end

  always @(posedge clk) begin
    if (rst || jump_flag) begin
      head <= 0;
      tail <= 0;
      for (i = 0; i < `ROB_SIZE; i = i + 1) begin
        isReady[i] <= 0;
        ToPC[i] <= -1;
      end 
      jump_flag <= 0;
    end else if (~rdy) begin

    end else begin
      if (issue_valid) begin
        isReady[rob_next] <= 0;
        OpType[rob_next] <= issue_op;
        DestReg[rob_next] <= issue_dest;
        tail <= rob_next;
      end
      if (exc_valid) begin
        isReady[exc_RobId] <= 1;
        Value[exc_RobId] <= exc_value;
        ToPC[exc_RobId] <= exc_toPC;
      end
      if (lsb_valid) begin
        isReady[lsb_RobId] <= 1;
        Value[lsb_RobId] <= lsb_value;
      end
      if (store_valid) begin
        isReady[store_RodId] <= 1;
      end

      jump_flag <= 0;
      reg_enable <= 0;
      lsb_begin_store <= 0;
      if (~isEmpty && isReady[top_id]) begin
        case (OpType[top_id])
          `OP_BEQ, `OP_BNE, `OP_BLT, `OP_BGE, `OP_BLTU, `OP_BGEU:
            if (~ToPC[top_id] != 0) begin
              jump_flag <= 1;
              if_toPC <= ToPC[top_id];
            end
          `OP_SB, `OP_SH, `OP_SW: begin
            lsb_begin_store <= 1;
            lsb_store_RobId <= top_id;
          end
          default: begin
            if (~ToPC[top_id] != 0) begin
              jump_flag <= 1;
              if_toPC <= ToPC[top_id];
            end
            reg_enable <= 1;
            reg_index <= DestReg[top_id];
            reg_RobId <= top_id;
            reg_value <= Value[top_id];
          end
        endcase
        head <= head + 1 & `ROB_SIZE - 1; 
      end
    end
  end
  
endmodule

`endif