`include "config.v" 

`ifndef __InstFetch__
`define __InstFetch__

module InstFetch (
  input wire          clk,
  input wire          rst,
  input wire					rdy,

  output wire        pc_send_enable,
  output wire [31:0] pc_to_ic,

  input wire         inst_get_ready,  // hit
  input wire [31:0]  inst_from_ic,   // I-cache

  output reg         inst_send_enable,
  output reg [31:0]  inst_to_issue, 
  output reg [31:0]  pc_to_issue,
  output reg         pred_to_issue,

  input wire         jump_flag,
  input wire [31:0]  target_pc,

  input wire         rob_next_full,
  input wire         rs_next_full,
  input wire         lsb_next_full,
  // Branch Prediction
  input wire         upd_pred_valid,
  input wire [31:0]  upd_pred_pc,
  input wire         upd_pred_need_jump
);
  reg [31:0] pc;
  reg        isBusy;
  reg [1:0]  predCnt[`PRED_SIZE - 1:0];
  integer    i;

  assign pc_to_ic = pc;
  assign pc_send_enable = isBusy;

  always @(posedge clk) begin
    if (rst) begin
      isBusy <= `FALSE;
      pc <= 0;
      inst_send_enable <= `LOW;
      inst_to_issue <= 0;
      for (i = 0; i << 2 < `PRED_SIZE; i = i + 1) begin
        predCnt[i << 2] <= 2'b00;
        predCnt[i << 2 | 1] <= 2'b00;
        predCnt[i << 2 | 2] <= 2'b00;
        predCnt[i << 2 | 3] <= 2'b00;
      end
    end else if (!rdy) begin

    end else begin
      // Branch Prediction
      if (upd_pred_valid) begin
        if (predCnt[upd_pred_pc & `PRED_SIZE - 1] > 2'b00 && ~upd_pred_need_jump)
          predCnt[upd_pred_pc & `PRED_SIZE - 1] <= predCnt[upd_pred_pc & `PRED_SIZE - 1] - 2'b01;
        else if (predCnt[upd_pred_pc & `PRED_SIZE - 1] < 2'b11 && upd_pred_need_jump)
          predCnt[upd_pred_pc & `PRED_SIZE - 1] <= predCnt[upd_pred_pc & `PRED_SIZE - 1] + 2'b01;
      end

      if (jump_flag) begin
        pc <= target_pc;
        isBusy <= `FALSE;
        inst_send_enable <= `LOW;
      end else if (rob_next_full || rs_next_full || lsb_next_full) begin
        inst_send_enable <= `LOW;
      end else begin
        if (isBusy) begin
          if (inst_get_ready) begin
            inst_send_enable <= `HIGH;
            inst_to_issue <= inst_from_ic;
            pc_to_issue <= pc;
            isBusy <= `FALSE;
            if (inst_from_ic[6:0] == 7'b1100011 && predCnt[pc & `PRED_SIZE - 1] >= 2'b10) begin
              pc <= pc + { {20{inst_from_ic[31]}}, inst_from_ic[7], inst_from_ic[30:25], inst_from_ic[11:8], 1'b0 };
              pred_to_issue <= `TRUE;
            end else begin
              pc <= pc + 4;
              pred_to_issue <= `FALSE;
            end
          end else begin
            inst_send_enable <= `LOW;
          end
        end else begin
          isBusy <= `TRUE;
          inst_send_enable <= `LOW;
        end
      end
      if (inst_send_enable)
        inst_send_enable <= `LOW;
    end
  end
  
endmodule

`endif
