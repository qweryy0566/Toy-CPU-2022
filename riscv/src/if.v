module inst_fetch
(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
  input  wire					        rdy_in,			// ready signal, pause cpu when low
  input  wire [31:0]          pc_in,			// program counter
  output wire [31:0]          pc_out,			// program counter
  output wire [31:0]          inst_out,		// instruction output
  
  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
  
  output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

  always @(posedge clk_in) begin
    
  end

endmodule
