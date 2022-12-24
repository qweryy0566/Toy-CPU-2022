`include "config.v" 
`include "ID.v"

`ifndef __InstFetch__
`define __InstFetch__

module InstFetch (
  input wire          clk,
  input wire          rst,
  input wire					rdy,

  output wire [31:0]        pc_to_ic,

  input wire                inst_get_ready,  // hit
  input wire [31:0]         inst_from_ic,   // I-cache

  output reg                 inst_send_enable,
  output reg [31:0]          pc_to_issue,
  output reg                 pred_to_issue,
  output reg [`OP_LOG - 1:0] op_type_to_issue,
  output reg [4:0]           rd_to_issue,
  output reg [4:0]           rs1_to_reg,
  output reg [4:0]           rs2_to_reg,
  output reg [31:0]          imm_to_issue,

  input wire                jump_flag,
  input wire [31:0]         target_pc,

  input wire                rob_next_full,
  input wire                rs_next_full,
  input wire                lsb_next_full,
  // Branch Prediction
  input wire                upd_pred_valid,
  input wire [`PRED_RANGE]  upd_pred_index,
  input wire                upd_pred_need_jump
);
  reg [31:0] pc;
  reg [1:0]  predCnt[`PRED_SIZE - 1:0];
  integer    i;
  wire [`OP_LOG - 1:0] op_type;
  wire [4:0]           rd, rs1, rs2;
  wire [31:0]          imm;

  assign pc_to_ic = pc;

  InstDecode u_InstDecode (
    .inst(inst_from_ic),
    .op_type(op_type),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .imm(imm)
  );

  always @(posedge clk) begin
    if (rst) begin
      pc <= 0;
      inst_send_enable <= `LOW;
      for (i = 0; i < `PRED_SIZE; i = i + 1)
        predCnt[i] <= 2'b00;
    end else if (!rdy) begin

    end else begin
      // Branch Prediction
      if (upd_pred_valid) begin
        if (predCnt[upd_pred_index] > 2'b00 && ~upd_pred_need_jump)
          predCnt[upd_pred_index] <= predCnt[upd_pred_index] - 2'b01;
        else if (predCnt[upd_pred_index] < 2'b11 && upd_pred_need_jump)
          predCnt[upd_pred_index] <= predCnt[upd_pred_index] + 2'b01;
      end

      if (jump_flag) begin
        pc <= target_pc;
        inst_send_enable <= `LOW;
      end else if (rob_next_full || rs_next_full || lsb_next_full) begin
        inst_send_enable <= `LOW;
      end else begin
        if (inst_get_ready) begin
          inst_send_enable <= `HIGH;
          op_type_to_issue <= op_type;
          rd_to_issue <= rd;
          rs1_to_reg <= rs1;
          rs2_to_reg <= rs2;
          imm_to_issue <= imm;
          pc_to_issue <= pc;
          if (inst_from_ic[6:0] == 7'b1100011 && predCnt[pc[`PRED_RANGE]] >= 2'b10) begin
            pc <= pc + imm;
            pred_to_issue <= `TRUE;
          end else begin
            pc <= pc + 4;
            pred_to_issue <= `FALSE;
          end
        end else begin
          inst_send_enable <= `LOW;
        end
      end
    end
  end
  
endmodule

`endif
