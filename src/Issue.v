`include "config.v"

`ifndef __ISSUE__
`define __ISSUE__

module Issue (
  input wire                   rst,
  input wire                   rdy,
  input wire                   inst_valid,
  input wire [`OP_LOG - 1:0]   op_type_from_if,

  input wire                   exc_valid,
  input wire [`ROB_LOG - 1:0]  exc_RobId,
  input wire [31:0]            exc_value,
  input wire                   LSB_valid,
  input wire [`ROB_LOG - 1:0]  LSB_RobId,
  input wire [31:0]            LSB_value,

  // RegFile
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

  output reg                  reg_send_enable,

  output reg [`ROB_LOG - 1:0] send_RobId,

  output reg                   rs_send_enable,
  output wire [31:0]           Vj,
  output wire [31:0]           Vk,
  output wire                  Rj,
  output wire                  Rk,
  output wire [`ROB_LOG - 1:0] Qj,
  output wire [`ROB_LOG - 1:0] Qk,

  output reg                  lsb_send_enable
);
  assign Qj = Qj_from_reg;
  assign Qk = Qk_from_reg;
  assign Vj = Rj_from_reg ? Vj_from_reg : rob_rs1_ready ? rob_rs1_value : exc_valid && exc_RobId == Qj_from_reg ? exc_value : LSB_value;
  assign Rj = Rj_from_reg || rob_rs1_ready || exc_valid && exc_RobId == Qj_from_reg || LSB_valid && LSB_RobId == Qj_from_reg;
  assign Vk = Rk_from_reg ? Vk_from_reg : rob_rs2_ready ? rob_rs2_value : exc_valid && exc_RobId == Qk_from_reg ? exc_value : LSB_value;
  assign Rk = Rk_from_reg || rob_rs2_ready || exc_valid && exc_RobId == Qk_from_reg || LSB_valid && LSB_RobId == Qk_from_reg;

  always @(*) begin
    rob_send_enable = 0;
    reg_send_enable = 0;
    rs_send_enable = 0;
    lsb_send_enable = 0;
    send_RobId = 0;

    if (~rst && rdy && inst_valid) begin
      rob_send_enable = 1;

      reg_send_enable = 1;
      
      send_RobId = rob_next;

      if (op_type_from_if >= `OP_LB && op_type_from_if <= `OP_SW)
        lsb_send_enable = 1;
      else
        rs_send_enable = 1;
    end
  end

endmodule

`endif