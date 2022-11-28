`include "config.v"

module MemCtrl (
  input wire        clk,
  input wire        rst,
  input wire        rdy,

  input wire [7:0]  mem_din,
  output reg [7:0]  mem_dout,
  output reg [31:0] mem_a,
  output reg        mem_wr,
  input wire        io_buffer_full, // 1 if uart buffer is full

  input wire        ic_valid,
  input wire [31:0] addr_from_ic,
  output reg        ic_enable,
  output reg [31:0] inst_to_ic
);

  reg [2:0] state;
  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      ic_enable <= `LOW;
    end else if (~rdy) begin
      state <= 0;
      ic_enable <= `LOW;
    end else begin
      // TODO : fake Memory Controller
      if (ic_valid) begin     
        if (state == 0) begin
          mem_a <= addr_from_ic;
          mem_wr <= `LOW;
          ic_enable <= `LOW;
          state <= state + 1;
        end else begin
          case (state)
            3'h2: inst_to_ic[7:0] <= mem_din;
            3'h3: inst_to_ic[15:8] <= mem_din;
            3'h4: inst_to_ic[23:16] <= mem_din;
            3'h5: inst_to_ic[31:24] <= mem_din;
          endcase
          if (state == 3'h5) begin
            ic_enable <= `HIGH;
            state <= 0;
          end else begin
            ic_enable <= `LOW;
            state <= state + 1;
            mem_a <= mem_a + 1;
          end
        end
      end else begin
        mem_wr <= `LOW;
        ic_enable <= `LOW;
      end 
    end
  end
  
endmodule
