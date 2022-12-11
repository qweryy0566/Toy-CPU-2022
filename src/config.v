`define HIGH 1'b1;
`define LOW 1'b0;
`define TRUE 1'b1;
`define FALSE 1'b0;

`define CacheEntries 256

`define OP_NOP 6'd0
`define OP_ADD 6'd1
`define OP_SUB 6'd2
`define OP_XOR 6'd3
`define OP_OR 6'd4
`define OP_AND 6'd5
`define OP_SLL 6'd6
`define OP_SRL 6'd7
`define OP_SRA 6'd8
`define OP_SLT 6'd9
`define OP_SLTU 6'd10
`define OP_ADDI 6'd11
`define OP_XORI 6'd12
`define OP_ORI 6'd13
`define OP_ANDI 6'd14
`define OP_SLLI 6'd15
`define OP_SRLI 6'd16
`define OP_SRAI 6'd17
`define OP_SLTI 6'd18
`define OP_SLTIU 6'd19
`define OP_LB 6'd20
`define OP_LH 6'd21
`define OP_LW 6'd22
`define OP_LBU 6'd23
`define OP_LHU 6'd24
`define OP_SB 6'd25
`define OP_SH 6'd26
`define OP_SW 6'd27
`define OP_BEQ 6'd28
`define OP_BNE 6'd29
`define OP_BLT 6'd30
`define OP_BGE 6'd31
`define OP_BLTU 6'd32
`define OP_BGEU 6'd33
`define OP_JAL 6'd34
`define OP_JALR 6'd35
`define OP_LUI 6'd36
`define OP_AUIPC 6'd37

`define ROB_LOG 5
`define ROB_SIZE 32
`define RS_LOG 5
`define RS_SIZE 32
`define OP_LOG 6
`define OP_SIZE 38
`define LSB_LOG 5
`define LSB_SIZE 32



