`include "config.v"
`include "ID.v"

`ifndef __ISSUE__
`define __ISSUE__

module Issue (
  input wire         inst_valid,
  input wire [31:0]  inst_from_if,
  input wire [31:0]  pc_from_if,

  // RegFile
  output reg                  rs1_enable,
  output wire [4:0]           rs1_to_reg,
  output reg                  rs2_enable,
  output wire [4:0]           rs2_to_reg,
  input wire [31:0]           Vj_from_reg,
  input wire                  Rj_from_reg,
  input wire [`ROB_LOG - 1:0] Qj_from_reg,
  input wire [31:0]           Vk_from_reg,
  input wire                  Rk_from_reg,
  input wire [`ROB_LOG - 1:0] Qk_from_reg,

  input wire [`ROB_LOG - 1:0] rob_next,
  output reg                  rob_send_enable,
  output reg [`OP_LOG -1:0]   rob_send_op,
  output reg [4:0]            rob_send_dest,

  output reg                  reg_send_enable,
  output reg [4:0]            reg_send_index,

  output reg [`ROB_LOG - 1:0] send_RobId,

  output reg                  rs_send_enable,
  output reg [`OP_LOG - 1:0]  rs_send_op,
  output reg [31:0]           rs_send_Vj,
  output reg                  rs_send_Rj,
  output reg [`ROB_LOG - 1:0] rs_send_Qj,
  output reg [31:0]           rs_send_Vk,
  output reg                  rs_send_Rk,
  output reg [`ROB_LOG - 1:0] rs_send_Qk,
  output reg [31:0]           rs_send_Imm,
  output reg [31:0]           rs_send_CurPc,

  output reg                  lsb_send_enable,
  output reg [`OP_LOG - 1:0]  lsb_send_op,
  output reg [31:0]           lsb_send_Vj,
  output reg                  lsb_send_Rj,
  output reg [`ROB_LOG - 1:0] lsb_send_Qj,
  output reg [31:0]           lsb_send_Vk,
  output reg                  lsb_send_Rk,
  output reg [`ROB_LOG - 1:0] lsb_send_Qk,
  output reg [31:0]           lsb_send_Imm
);
  wire [`OP_LOG - 1:0] op_type;
  wire [4:0]           rd, rs1, rs2;
  wire [31:0]          imm;

  reg [5:0] issue_op;
  reg [4:0] issue_rd, issue_rs1, issue_rs2;
  reg [31:0] issue_imm;

  InstDecode inst_decode (
    .inst(inst_from_if),
    .op_type(op_type),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .imm(imm)
  );

  assign rs1_to_reg = rs1;
  assign rs2_to_reg = rs2;

  always @(*) begin
    if (inst_valid) begin
      rs1_enable = 1;
      rs2_enable = 1;

      rob_send_enable = 1;
      rob_send_op = op_type;
      rob_send_dest = rd;

      reg_send_enable = 1;
      reg_send_index = rd;
      
      send_RobId = rob_next;

      if (op_type >= `OP_LB && op_type <= `OP_SW) begin
        lsb_send_enable = 1;
        lsb_send_op = op_type;
        lsb_send_Vj = Vj_from_reg;
        lsb_send_Rj = Rj_from_reg;
        lsb_send_Qj = Qj_from_reg;
        lsb_send_Vk = Vk_from_reg;
        lsb_send_Rk = Rk_from_reg;
        lsb_send_Qk = Qk_from_reg;
        lsb_send_Imm = imm;
      end else begin
        rs_send_enable = 1;
        rs_send_op = op_type;
        rs_send_Vj = Vj_from_reg;
        rs_send_Rj = Rj_from_reg;
        rs_send_Qj = Qj_from_reg;
        rs_send_Vk = Vk_from_reg;
        rs_send_Rk = Rk_from_reg;
        rs_send_Qk = Qk_from_reg;
        rs_send_Imm = imm;
        rs_send_CurPc = pc_from_if;
      end
    end else begin
      rs1_enable = 0;
      rs2_enable = 0;
      rob_send_enable = 0;
      reg_send_enable = 0;
      rs_send_enable = 0;
    end
  end
endmodule

`endif