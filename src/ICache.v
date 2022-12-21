`include "config.v"

`ifndef __ICache__
`define __ICache__

module ICache (
  input wire         clk,
  input wire         rst,
  input wire         rdy,

  input wire         if_valid,
  input wire [31:0]  pc_from_if,

  output reg         inst_enable,  // hit
  output reg [31:0]  inst_to_if,

  output reg         addr_enable,
  output reg [31:0]  addr_to_mem,

  input wire         mem_valid,
  input wire [31:0]  inst_from_mem
);
  integer i;
  reg     isBusy;
  reg          valid [`CacheEntries - 1:0];
  reg [17:10]  tag   [`CacheEntries - 1:0];
  reg [31:0]   data  [`CacheEntries - 1:0];

  wire hit = valid[pc_from_if[9:2]] && tag[pc_from_if[9:2]] == pc_from_if[17:10];

  always @(posedge clk) begin
    if (rst) begin
      isBusy <= `FALSE;
      inst_enable <= `LOW;
      for (i = 0; i << 2 < `CacheEntries; i = i + 1) begin
        valid[i << 2] <= `FALSE;
        valid[i << 2 | 1] <= `FALSE;
        valid[i << 2 | 2] <= `FALSE;
        valid[i << 2 | 3] <= `FALSE;
      end
    end else if (~rdy) begin

    end else begin
      if (if_valid) begin
        if (hit) begin
          inst_enable <= `HIGH;
          inst_to_if <= data[pc_from_if[9:2]];
        end else begin
          inst_enable <= `LOW;
          if (isBusy) begin
            if (mem_valid) begin
              valid[pc_from_if[9:2]] <= `TRUE;
              tag[pc_from_if[9:2]]   <= pc_from_if[17:10];
              data[pc_from_if[9:2]]  <= inst_from_mem;
              addr_enable <= `LOW;
            end else begin
              addr_enable <= `HIGH;
              inst_enable <= `LOW;
            end
          end else begin
            isBusy <= `TRUE;
            addr_enable <= `HIGH;
            addr_to_mem <= pc_from_if;
            inst_enable <= `LOW;
          end
        end
      end else begin
        isBusy <= `FALSE;
        inst_enable <= `LOW;
        addr_enable <= `LOW;
      end
    end
  end

endmodule

`endif