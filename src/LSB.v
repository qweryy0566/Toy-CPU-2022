`include "config.v"

`ifndef __LSBuffer__
`define __LSBuffer__

module LSBuffer (
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

  output reg                  rs_enable,
  output reg [`ROB_LOG - 1:0] rs_RobId,
  output reg [31:0]           rs_value,

  input wire                  rob_committed,
  output reg                  rob_send_enable,
  output reg [`ROB_LOG - 1:0] rob_send_RobId,

  output reg                  mem_enable,
  output reg [2:0]            op_size,
  output reg [31:0]           mem_addr,
  output reg [31:0]           mem_wdata,
  output reg                  mem_wr_tag,
  input wire                  mem_valid,
  input wire [31:0]           mem_rdata,

  output reg                  LSB_next_full
);

  reg [`OP_LOG - 1:0]  OpType[`LSB_SIZE - 1:0];
  reg [31:0]           Vj[`LSB_SIZE - 1:0];
  reg [31:0]           Vk[`LSB_SIZE - 1:0];
  reg                  Rj[`LSB_SIZE - 1:0];  // value is ready
  reg                  Rk[`LSB_SIZE - 1:0];  // value is ready
  reg [`ROB_LOG - 1:0] Qj[`LSB_SIZE - 1:0];
  reg [`ROB_LOG - 1:0] Qk[`LSB_SIZE - 1:0];
  reg [31:0]           Imm[`LSB_SIZE - 1:0];
  reg [`ROB_LOG - 1:0] DestRob[`LSB_SIZE - 1:0];

  
endmodule

`endif