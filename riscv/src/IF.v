`include "config.v" 

module InstFetch (
  input wire          clk,
  input wire          rst,
  input wire					rdy,

  output reg         pc_send_enable,
  output reg [31:0]  pc_to_ic,

  input wire         inst_get_ready,  // hit
  input wire [31:0]  inst_from_ic,   // I-cache

  output reg         inst_send_enable,
  output reg [31:0]  inst_to_issue, 
  output reg [31:0]  pc_to_issue,

  input wire         jump_flag,
  input wire [31:0]  target_pc,

  input wire        rob_full,
  input wire        rs_full,
  input wire        lsb_full
);
  reg [31:0] pc;
  reg        isBusy;

  always @(posedge clk) begin
    if (rst) begin
      isBusy <= `FALSE;
      pc_send_enable <= `LOW;
      pc <= 0;
      inst_send_enable <= `LOW;
      inst_to_issue <= 0;
    end else if (!rdy) begin
      isBusy <= `FALSE;
      pc_send_enable <= `LOW;
      inst_send_enable <= `LOW;
    end else if (jump_flag) begin
      pc <= target_pc;
      isBusy <= `FALSE;
      pc_send_enable <= `LOW;
      inst_send_enable <= `LOW;
    end else if (rob_full || rs_full || lsb_full) begin
      isBusy <= `FALSE;
      pc_send_enable <= `LOW;
      inst_send_enable <= `LOW;
    end else begin
      if (isBusy) begin
        if (inst_get_ready) begin
          inst_send_enable <= `HIGH;
          inst_to_issue <= inst_from_ic;
          pc_to_issue <= pc;
          isBusy <= `FALSE;
          pc <= pc + 3'b100;
          pc_send_enable <= `LOW;
        end else begin
          pc_send_enable <= `HIGH;
          inst_send_enable <= `LOW;
        end
      end else begin
        isBusy <= `TRUE;
        pc_to_ic <= pc;
        pc_send_enable <= `HIGH;
        inst_send_enable <= `LOW;
      end
    end
  end
  
endmodule
