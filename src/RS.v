`include "config.v"

`ifndef __RS__
`define __RS__

module RS (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire                   issue_valid,
  input wire [`OP_LOG - 1:0]   issue_op,
  input wire [31:0]            issue_Vj,
  input wire                   issue_Rj,
  input wire [`ROB_LOG - 1:0]  issue_Qj,
  input wire [31:0]            issue_Vk,
  input wire                   issue_Rk,
  input wire [`ROB_LOG - 1:0]  issue_Qk,
  input wire [31:0]            issue_Imm,
  input wire [`ROB_LOG - 1:0]  issue_DestRob,
  input wire [31:0]            issue_CurPC,

  input wire                   exc_valid,
  input wire [`ROB_LOG - 1:0]  exc_RobId,
  input wire [31:0]            exc_value,

  output reg                   FU_enable,
  output reg [`OP_LOG - 1:0]   FU_op,
  output reg [31:0]            FU_Vj,
  output reg [31:0]            FU_Vk,
  output reg [31:0]            FU_Imm,
  output reg [`ROB_LOG - 1:0]  FU_DestRob,
  output reg [31:0]            FU_CurPC,

  input wire                   LSB_valid,
  input wire [`ROB_LOG - 1:0]  LSB_RobId,
  input wire [31:0]            LSB_value,

  output reg                   RS_next_full
);
  
  reg                   isBusy[`RS_SIZE - 1:0];
  reg [`OP_LOG - 1:0]   OpType[`RS_SIZE - 1:0];
  reg [31:0]            Vj[`RS_SIZE - 1:0];
  reg [31:0]            Vk[`RS_SIZE - 1:0];
  reg                   Rj[`RS_SIZE - 1:0];  // value is ready
  reg                   Rk[`RS_SIZE - 1:0];  // value is ready
  reg [`ROB_LOG - 1:0]  Qj[`RS_SIZE - 1:0];
  reg [`ROB_LOG - 1:0]  Qk[`RS_SIZE - 1:0];
  reg [31:0]            Imm[`RS_SIZE - 1:0];
  reg [`ROB_LOG - 1:0]  DestRob[`RS_SIZE - 1:0];
  reg [31:0]            CurPC[`RS_SIZE - 1:0];

  integer i, j, cnt, empty_pos;

  always @(*) begin
    cnt = 0;
    for (j = 0; j < `RS_SIZE; j = j + 1)
      if (isBusy[j])
        cnt = cnt + 1;
      else
        empty_pos = j;
    if (cnt + 1 >= `RS_SIZE)
      RS_next_full = 1;
    else
      RS_next_full = 0;
  end

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < `RS_SIZE; i = i + 1) begin
        isBusy[i] <= 0;
      end
      FU_enable <= 0;
      empty_pos <= 0;
    end else if (~rdy) begin
      FU_enable <= 0;
    end else begin
      if (issue_valid) begin
        isBusy[empty_pos] <= 1;
        OpType[empty_pos] <= issue_op;
        Vj[empty_pos] <= issue_Vj;
        Vk[empty_pos] <= issue_Vk;
        Rj[empty_pos] <= issue_Rj;
        Rk[empty_pos] <= issue_Rk;
        Qj[empty_pos] <= issue_Qj;
        Qk[empty_pos] <= issue_Qk;
        Imm[empty_pos] <= issue_Imm;
        DestRob[empty_pos] <= issue_DestRob;
        CurPC[empty_pos] <= issue_CurPC;
      end
      // now check if there i a ready instruction
      FU_enable <= 0;
      for (i = 0; i < `RS_SIZE; i = i + 1) begin
        if (isBusy[i] && Rj[i] && Rk[i]) begin
          FU_enable <= 1;
          FU_op <= OpType[i];
          FU_Vj <= Vj[i];
          FU_Vk <= Vk[i];
          FU_Imm <= Imm[i];
          FU_DestRob <= DestRob[i];
          FU_CurPC <= CurPC[i];
        end
      end
      // now receive the result from the FU
      if (exc_valid) begin
        for (i = 0; i < `RS_SIZE; i = i + 1)
          if (isBusy[i]) begin
            if (~Rj[i] && Qj[i] == exc_RobId) begin
              Rj[i] <= 1;
              Vj[i] <= exc_value;
            end
            if (~Rk[i] && Qk[i] == exc_RobId) begin
              Rk[i] <= 1;
              Vk[i] <= exc_value;
            end
          end
      end
      // now receive the result from the LSB
      if (LSB_valid) begin
        for (i = 0; i < `RS_SIZE; i = i + 1)
          if (isBusy[i]) begin
            if (~Rj[i] && Qj[i] == LSB_RobId) begin
              Rj[i] <= 1;
              Vj[i] <= LSB_value;
            end
            if (~Rk[i] && Qk[i] == LSB_RobId) begin
              Rk[i] <= 1;
              Vk[i] <= LSB_value;
            end
          end
      end
    end
  end
endmodule

`endif