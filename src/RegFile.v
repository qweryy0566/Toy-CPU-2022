`include "config.v"

`ifndef __REGFILE__
`define __REGFILE__

module RegFile (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire [4:0]   rs1,
  input wire [4:0]   rs2,

  output reg [31:0]            Vj_to_issue,
  output reg                   Rj_to_issue,
  output reg [`ROB_LOG - 1:0]  Qj_to_issue,
  output reg [31:0]            Vk_to_issue,
  output reg                   Rk_to_issue,
  output reg [`ROB_LOG - 1:0]  Qk_to_issue,

  input wire                   commit_valid,
  input wire [4:0]             commit_dest,
  input wire [31:0]            commit_value,
  input wire [`ROB_LOG - 1:0]  commit_RobId,

  input wire                   rename_valid,
  input wire [4:0]             issue_rd,
  input wire [`ROB_LOG - 1:0]  issue_RobId,

  input wire                   jump_flag

);

  reg [31:0] regFile [31:0];
  reg [`ROB_LOG - 1:0] reorder[31:0];
  reg        isReorder[31:0]; // 超级�? bug, 原来�?直用 reorder != 0 来判断是否重命名.
  integer i;

  always @(*) begin
    if (isReorder[rs1] && commit_valid && commit_RobId == reorder[rs1]) begin
      Vj_to_issue = commit_value;
      Rj_to_issue = 1;
      Qj_to_issue = 0;
    end else begin
      Vj_to_issue = regFile[rs1];
      Rj_to_issue = ~isReorder[rs1];
      Qj_to_issue = reorder[rs1];
    end
  end

  always @(*) begin
    if (isReorder[rs2] && commit_valid && commit_RobId == reorder[rs2]) begin
      Vk_to_issue = commit_value;
      Rk_to_issue = 1;
      Qk_to_issue = 0;
    end else begin
      Vk_to_issue = regFile[rs2];
      Rk_to_issue = ~isReorder[rs2];
      Qk_to_issue = reorder[rs2];
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < 32; i = i + 1) begin
        regFile[i] <= 0;
        reorder[i] <= 0;
        isReorder[i] <= 0;
      end
    end else if (~rdy) begin

    end else begin
      if (commit_valid) begin
        if (isReorder[commit_dest] && commit_RobId == reorder[commit_dest]) begin
          reorder[commit_dest] <= 0;
          isReorder[commit_dest] <= 0;
        end if (commit_dest != 0)
          regFile[commit_dest] <= commit_value;
      end
      if (jump_flag) begin
        for (i = 0; i < 32; i = i + 1) begin
          reorder[i] <= 0;
          isReorder[i] <= 0;
        end
      end else begin
        if (rename_valid && issue_rd != 0) begin
          reorder[issue_rd] <= issue_RobId; // 原来写成组合 = 了�?��?��??
          isReorder[issue_rd] <= 1;
        end
      end
    end
  end

endmodule

`endif