`include "config.v"

`ifndef __CPU__
`define __CPU__

// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

  wire           ic_to_mem_valid;
  wire [31:0]    ic_to_mem_addr;
  wire           mem_to_ic_valid;
  wire [31:0]    mem_to_ic_inst;
  wire           if_to_ic_valid;
  wire [31:0]    if_to_ic_pc;
  wire           ic_to_if_valid;
  wire [31:0]    ic_to_if_inst;
  wire           if_to_issue_valid;
  wire [31:0]    if_to_issue_inst;
  wire [31:0]    if_to_issue_pc;

  wire           rob_to_if_valid;
  wire [31:0]    rob_to_if_pc;


  MemCtrl mem_ctrl(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .mem_din(mem_din),
    .mem_dout(mem_dout),
    .mem_a(mem_a),
    .mem_wr(mem_wr),
    .io_buffer_full(io_buffer_full),
    .ic_valid(ic_to_mem_valid),
    .addr_from_ic(ic_to_mem_addr),
    .ic_enable(mem_to_ic_valid),
    .inst_to_ic(mem_to_ic_inst)
  );

  ICache icache(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .if_valid(if_to_ic_valid),
    .pc_from_if(if_to_ic_pc),
    .inst_enable(ic_to_if_valid),
    .inst_to_if(ic_to_if_inst),
    .addr_enable(ic_to_mem_valid),
    .addr_to_mem(ic_to_mem_addr),
    .mem_valid(mem_to_ic_valid),
    .inst_from_mem(mem_to_ic_inst)
  );

  InstFetch if_stage(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .pc_send_enable(if_to_ic_valid),
    .pc_to_ic(if_to_ic_pc),
    .inst_get_ready(ic_to_if_valid),
    .inst_from_ic(ic_to_if_inst),
    .inst_send_enable(if_to_issue_valid),
    .inst_to_issue(if_to_issue_inst),
    .pc_to_issue(if_to_issue_pc),
    .jump_flag(rob_to_if_valid),
    .target_pc(rob_to_if_pc)
  );

endmodule

`endif