`include "config.v"
`include "ID.v"

`ifndef __ISSUE__
`define __ISSUE__

module Issue (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire        inst_valid,
  input wire [31:0] inst_from_if,
  input wire [31:0] pc_from_if,

  // RegFile
  output reg        rs1_enable,
  output reg [31:0] rs1_to_reg,
  output reg        rs2_enable,
  output reg [31:0] rs2_to_reg,

  output reg        issue_stall,

  output reg        rs_send_enable
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
  

  always @(*) begin
    if (inst_valid) begin
      
    end
  end



endmodule

`endif