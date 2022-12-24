`include "config.v"

`ifndef __REGFILE__
`define __REGFILE__

module RegFile (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire [4:0]   rs1,
  input wire [4:0]   rs2,

  output wire [31:0]           Vj_to_issue,
  output wire                  Rj_to_issue,
  output wire [`ROB_LOG - 1:0] Qj_to_issue,
  output wire [31:0]           Vk_to_issue,
  output wire                  Rk_to_issue,
  output wire [`ROB_LOG - 1:0] Qk_to_issue,

  input wire                   commit_valid,
  input wire [4:0]             commit_dest,
  input wire [31:0]            commit_value,
  input wire [`ROB_LOG - 1:0]  commit_RobId,

  input wire                   rename_valid,
  input wire [4:0]             issue_rd,
  input wire [`ROB_LOG - 1:0]  issue_RobId,

  input wire                   jump_flag

);

  reg [31:0]           regFile [31:0];
  reg [`ROB_LOG - 1:0] reorder[31:0];
  reg                  isReorder[31:0]; // 超级大 bug, 原来是直接用 reorder != 0 来判断是否重命名.
  integer i;

  assign Vj_to_issue = isReorder[rs1] && commit_valid && commit_RobId == reorder[rs1] ? commit_value : regFile[rs1];
  assign Rj_to_issue = isReorder[rs1] && commit_valid && commit_RobId == reorder[rs1] || ~isReorder[rs1];
  assign Qj_to_issue = reorder[rs1];

  assign Vk_to_issue = isReorder[rs2] && commit_valid && commit_RobId == reorder[rs2] ? commit_value : regFile[rs2];
  assign Rk_to_issue = isReorder[rs2] && commit_valid && commit_RobId == reorder[rs2] || ~isReorder[rs2];
  assign Qk_to_issue = reorder[rs2];

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
          reorder[issue_rd] <= issue_RobId; // 原来写成组合 = 了。。
          isReorder[issue_rd] <= 1;
        end
      end
    end
  end

endmodule

`endif