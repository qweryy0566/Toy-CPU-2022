`include "config.v"

`ifndef __MemCtrl__
`define __MemCtrl__

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
  output reg [31:0] inst_to_ic,

  input wire        lsb_valid,
  input wire [31:0] lsb_addr,
  input wire [31:0] lsb_store_data,
  input wire [2:0]  lsb_size,
  input wire        lsb_wr_tag,
  output reg        lsb_enable,
  output reg [31:0] lsb_load_data,

  input wire        jump_flag
);

  reg [2:0] pos;
  reg [1:0] status;
  always @(posedge clk) begin
    if (rst) begin
      pos <= 0;
      mem_wr <= `LOW;
      status <= `STATUS_IDLE;
      ic_enable <= `LOW;
      lsb_enable <= `LOW;
    end else if (~rdy) begin
      mem_wr <= `LOW;
      status <= `STATUS_IDLE; 
      ic_enable <= `LOW;
      lsb_enable <= `LOW;
    end else begin
      mem_wr <= `LOW;
      case (status)
        `STATUS_IDLE: begin
          ic_enable <= `LOW;
          lsb_enable <= `LOW;
          if (~ic_enable && ~lsb_enable)
            if (lsb_valid) begin
              if (lsb_wr_tag) begin
                status <= `STATUS_STORE;
                mem_a <= 0;
              end else begin
                status <= `STATUS_LOAD;
                mem_a <= lsb_addr;
              end
              pos <= 0;
            end else if (ic_valid) begin
              status <= `STATUS_IF;
              mem_a <= addr_from_ic;
              mem_wr <= `LOW;
              pos <= 0;
            end
        end
        `STATUS_IF: if (ic_valid) begin
          case (pos)
            3'd1: inst_to_ic[7:0] <= mem_din;
            3'd2: inst_to_ic[15:8] <= mem_din;
            3'd3: inst_to_ic[23:16] <= mem_din;
            3'd4: inst_to_ic[31:24] <= mem_din;
          endcase
          if (pos == 3'd4) begin
            status <= `STATUS_IDLE;
            ic_enable <= `HIGH;
          end else begin
            pos <= pos + 1;
            mem_a <= mem_a + 1;
          end
        end else status <= `STATUS_IDLE;
        `STATUS_LOAD: if (lsb_valid) begin
          case (pos)
            3'd1: lsb_load_data[7:0] <= mem_din;
            3'd2: lsb_load_data[15:8] <= mem_din;
            3'd3: lsb_load_data[23:16] <= mem_din;
            3'd4: lsb_load_data[31:24] <= mem_din; 
          endcase
          if (pos == lsb_size) begin
            status <= `STATUS_IDLE;
            lsb_enable <= `HIGH;
          end else begin
            pos <= pos + 1;
            mem_a <= mem_a + 1;
          end
        end else status <= `STATUS_IDLE;
        `STATUS_STORE: if (lsb_valid) begin
          mem_wr <= `HIGH;
          case (pos)
            3'd0: mem_dout <= lsb_store_data[7:0];
            3'd1: mem_dout <= lsb_store_data[15:8];
            3'd2: mem_dout <= lsb_store_data[23:16];
            3'd3: mem_dout <= lsb_store_data[31:24]; 
          endcase
          if (pos == lsb_size) begin
            mem_wr <= `LOW;
            mem_a <= 0;
            status <= `STATUS_IDLE;
            lsb_enable <= `HIGH;
          end else  begin
            pos <= pos + 1;
            if (pos > 0) mem_a <= mem_a + 1;
            else mem_a <= lsb_addr;
          end
        end else status <= `STATUS_IDLE;
      endcase
    end
  end
  
endmodule

`endif