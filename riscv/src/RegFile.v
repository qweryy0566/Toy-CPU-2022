`include "config.v"

`ifndef __REGFILE__
`define __REGFILE__

module RegFile (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire         rs1_valid,
  input wire [31:0]  rs1,
  input wire         rs2_valid,
  input wire [31:0]  rs2,

  output reg [31:0]            Vj_to_issue,
  output reg [`ROB_LOG - 1:0]  Qj_to_issue,
  output reg [31:0]            Vk_to_issue,
  output reg [`ROB_LOG - 1:0]  Qk_to_issue,

  input wire                   commit_valid,
  input wire [4:0]             commit_dest,
  input wire [31:0]            commit_value,
  input wire [`ROB_LOG - 1:0]  commit_reorder

);

  reg [31:0] regFile [31:0];
  reg [`ROB_LOG - 1:0] reorder[31:0];
  integer i;

  always @(*) begin
    if (rs1_valid) begin
      if (reorder[rs1] == 0) begin
        Vj_to_issue = regFile[rs1];
        Qj_to_issue = 0;
      end else if (commit_valid && commit_reorder == reorder[rs1]) begin
        Vj_to_issue = commit_value;
        Qj_to_issue = 0;
      end else begin
        Vj_to_issue = 0;
        Qj_to_issue = reorder[rs1];
      end
    end else begin
      Vj_to_issue = 0;
      Qj_to_issue = 0;
    end
  end

  always @(*) begin
    if (rs2_valid) begin
      if (reorder[rs2] == 0) begin
        Vk_to_issue = regFile[rs2];
        Qk_to_issue = 0;
      end else if (commit_valid && commit_reorder == reorder[rs2]) begin
        Vk_to_issue = commit_value;
        Qk_to_issue = 0;
      end else begin
        Vk_to_issue = 0;
        Qk_to_issue = reorder[rs2];
      end
    end else begin
      Vk_to_issue = 0;
      Qk_to_issue = 0;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < 32; i = i + 1) begin
        regFile[i] <= 0;
        reorder[i] <= 0;
      end
    end else if (~rdy) begin
    end else begin
      
    end
  end

endmodule

`endif