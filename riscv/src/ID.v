`include "config.v"

module InstDecode (
  input wire          clk,
  input wire          rst,  
  input wire          rdy,

  input wire         inst_valid,
  input wire [31:0]  inst_from_if,
  input wire [31:0]  pc_from_if
);

endmodule