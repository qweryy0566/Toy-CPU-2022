`include "config.v"

module ROB (
  input wire         clk,
  input wire         rst,
  input wire         rdy,



  output reg                  rob_next_full,
  output reg [`ROB_LOG - 1:0] rob_next
);

  reg[`ROB_LOG:0]      head, tail;
  reg                  isReady[`ROB_SIZE - 1:0];
  reg [`OP_LOG - 1:0]  OpType[`ROB_SIZE - 1:0];
  reg[4:0]             DestReg[`ROB_SIZE - 1:0];
  reg[31:0]            Value[`ROB_SIZE - 1:0];
  reg[31:0]            ToPC[`ROB_SIZE - 1:0];


  integer i, j, cnt, empty_pos;

  always @(*) begin
    rob_next_full = (tail + 2 & `ROB_SIZE - 1) == head;
    rob_next = tail + 1 & `ROB_SIZE - 1;
  end

  always @(posedge clk) begin
    if (rst) begin
      head <= 0;
      tail <= 0;
      for (i = 0; i < `ROB_SIZE; i = i + 1)
        isReady[i] <= 0;
    end else if (~rdy) begin
      
    end else begin
      
    end
  end
  
endmodule