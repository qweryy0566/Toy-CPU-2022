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
  // If RegFile cannot answer, then it will send a request to the ROB
  // C++ code:
  // if (reg_in.Reorder(inst.rs1))
  //   if (ROB_in[reg_in.Reorder(inst.rs1)].isReady)
  //     send.Vj = ROB_in[reg_in.Reorder(inst.rs1)].value, send.Qj = 0;
  //   else
  //     send.Qj = reg_in.Reorder(inst.rs1);
  // else
  //   send.Vj = reg_in[inst.rs1], send.Qj = 0;
  output reg [`ROB_LOG - 1:0] check_rob_rs1,
  output reg                  check_rob_rs1_enable,
  output reg [`ROB_LOG - 1:0] check_rob_rs2,
  output reg                  check_rob_rs2_enable,
  input wire                  rob_rs1_ready,
  input wire                  rob_rs2_ready,
  input wire [31:0]           rob_rs1_value,
  input wire [31:0]           rob_rs2_value,         

  input wire [`ROB_LOG - 1:0] rob_next,
  output reg                  rob_send_enable,
  output reg [`OP_LOG -1:0]   rob_send_op,
  output reg [4:0]            rob_send_dest,
  output reg [31:0]           rob_send_pc,

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
  reg [31:0]           Vj, Vk;
  reg                  Rj, Rk;
  reg [`ROB_LOG - 1:0] Qj, Qk;

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
    rs1_enable = 0;
    rs2_enable = 0;
    check_rob_rs1_enable = 0;
    check_rob_rs2_enable = 0;
    rob_send_enable = 0;
    reg_send_enable = 0;
    rs_send_enable = 0;
    lsb_send_enable = 0;
    if (inst_valid) begin
      rs1_enable = 1;
      rs2_enable = 1;
      check_rob_rs1_enable = 1;
      check_rob_rs2_enable = 1;

      rob_send_enable = 1;
      rob_send_op = op_type;
      rob_send_dest = rd;
      rob_send_pc = pc_from_if;

      reg_send_enable = 1;
      reg_send_index = rd;
      
      send_RobId = rob_next;
      
      if (~Rj_from_reg) begin
        check_rob_rs1 = Qj_from_reg;
        if (rob_rs1_ready) begin
          Vj = rob_rs1_value;
          Rj = 1;
        end else begin
          Rj = 0;
          Qj = Qj_from_reg;
        end
      end else begin
        Vj = Vj_from_reg;
        Rj = 1;
      end
      if (~Rk_from_reg) begin
        check_rob_rs2 = Qk_from_reg;
        if (rob_rs2_ready) begin
          Vk = rob_rs2_value;
          Rk = 1;
        end else begin
          Rk = 0;
          Qk = Qk_from_reg;
        end
      end else begin
        Vk = Vk_from_reg;
        Rk = 1;
      end

      if (op_type >= `OP_LB && op_type <= `OP_SW) begin
        lsb_send_enable = 1;
        lsb_send_op = op_type;
        lsb_send_Vj = Vj;
        lsb_send_Rj = Rj;
        lsb_send_Qj = Qj;
        lsb_send_Vk = Vk;
        lsb_send_Rk = Rk;
        lsb_send_Qk = Qk;
        lsb_send_Imm = imm;
      end else begin
        rs_send_enable = 1;
        rs_send_op = op_type;
        rs_send_Vj = Vj;
        rs_send_Rj = Rj;
        rs_send_Qj = Qj;
        rs_send_Vk = Vk;
        rs_send_Rk = Rk;
        rs_send_Qk = Qk;
        rs_send_Imm = imm;
        rs_send_CurPc = pc_from_if;
      end
    end
  end
endmodule

`endif