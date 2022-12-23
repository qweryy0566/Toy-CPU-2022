`include "config.v"
`include "ID.v"

`ifndef __ISSUE__
`define __ISSUE__

module Issue (
  input wire                   rst,
  input wire                   rdy,
  input wire                   inst_valid,
  input wire [31:0]            inst_from_if,
  input wire [31:0]            pc_from_if,
  input wire                   pred_from_if,

  input wire                   exc_valid,
  input wire [`ROB_LOG - 1:0]  exc_RobId,
  input wire [31:0]            exc_value,
  input wire                   LSB_valid,
  input wire [`ROB_LOG - 1:0]  LSB_RobId,
  input wire [31:0]            LSB_value,

  // RegFile
  output wire [4:0]           rs1_to_reg,
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
  input wire                  rob_rs1_ready,
  input wire                  rob_rs2_ready,
  input wire [31:0]           rob_rs1_value,
  input wire [31:0]           rob_rs2_value,         

  input wire [`ROB_LOG - 1:0] rob_next,
  output reg                  rob_send_enable,
  output reg [`OP_LOG -1:0]   rob_send_op,
  output reg [4:0]            rob_send_dest,
  output reg [31:0]           rob_send_pc,
  output reg                  rob_send_pred,

  output reg                  reg_send_enable,
  output reg [4:0]            reg_send_index,

  output reg [`ROB_LOG - 1:0] send_RobId,

  output reg                  rs_send_enable,
  output wire [`OP_LOG - 1:0] op_type,
  output wire [31:0]           Vj,
  output wire [31:0]           Vk,
  output wire                  Rj,
  output wire                  Rk,
  output wire [`ROB_LOG - 1:0] Qj,
  output wire [`ROB_LOG - 1:0] Qk,
  output wire [31:0]          imm,
  output wire [31:0]          CurPc,

  output reg                  lsb_send_enable
);
  wire [4:0]           rd;

  InstDecode inst_decode (
    .inst(inst_from_if),
    .op_type(op_type),
    .rd(rd),
    .rs1(rs1_to_reg),
    .rs2(rs2_to_reg),
    .imm(imm)
  );

  assign CurPc = pc_from_if;
  assign Qj = Qj_from_reg;
  assign Qk = Qk_from_reg;
  assign Vj = Rj_from_reg ? Vj_from_reg : rob_rs1_ready ? rob_rs1_value : exc_valid && exc_RobId == Qj_from_reg ? exc_value : LSB_value;
  assign Rj = Rj_from_reg || rob_rs1_ready || (exc_valid && exc_RobId == Qj_from_reg) || (LSB_valid && LSB_RobId == Qj_from_reg);
  assign Vk = Rk_from_reg ? Vk_from_reg : rob_rs2_ready ? rob_rs2_value : exc_valid && exc_RobId == Qk_from_reg ? exc_value : LSB_value;
  assign Rk = Rk_from_reg || rob_rs2_ready || (exc_valid && exc_RobId == Qk_from_reg) || (LSB_valid && LSB_RobId == Qk_from_reg);

  always @(*) begin
    rob_send_enable = 0;
    rob_send_op = 0;
    rob_send_pc = 0;
    rob_send_dest = 0;
    rob_send_pred = 0;
    reg_send_enable = 0;
    rs_send_enable = 0;
    lsb_send_enable = 0;
    send_RobId = 0;
    reg_send_index = 0;

    if (~rst && rdy && inst_valid) begin
      rob_send_enable = 1;
      rob_send_op = op_type;
      rob_send_dest = rd;
      rob_send_pc = pc_from_if;
      rob_send_pred = pred_from_if;

      reg_send_enable = 1;
      reg_send_index = rd;
      
      send_RobId = rob_next;

      if (op_type >= `OP_LB && op_type <= `OP_SW) begin
        lsb_send_enable = 1;
      end else begin
        rs_send_enable = 1;
      end
    end
  end

endmodule

`endif