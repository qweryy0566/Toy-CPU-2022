`include "config.v" 

module inst_fetch (
  input wire          clk,
  input wire          rst,
  input wire					rdy,

  output reg         pc_send_enable,
  output reg [31:0]  pc_to_ic,

  input wire         inst_get_ready,  // hit
  input wire [31:0]  inst_from_ic,   // I-cache

  output reg         inst_send_enable,
  output reg [31:0]  inst_to_dec, 

  input wire         jump_flag,
  input wire [31:0]  target_pc
);
  reg [31:0] pc;
  reg        isBusy;

  always @(posedge clk) begin
    if (rst) begin
      isBusy <= `FALSE;
      pc_send_enable <= `LOW;
      pc_to_ic <= 0;
      inst_send_enable <= `LOW;
      inst_to_dec <= 0;
    end else if (!rdy) begin
      isBusy <= `FALSE;
      pc_send_enable <= `LOW;
      inst_send_enable <= `LOW;
    end else if (jump_flag) begin
      pc <= target_pc;
      isBusy <= `FALSE;
      pc_send_enable <= `LOW;
      inst_send_enable <= `LOW;
    end else begin
      if (isBusy) begin
        if (inst_get_ready) begin
          inst_send_enable <= `HIGH;
          inst_to_dec <= inst_from_ic;
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
      end
    end
  end
  
endmodule
