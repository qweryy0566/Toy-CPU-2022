`include "config.v"

module InstDecode (
  input wire [31:0]  inst,
  
  output reg [5:0] op_type,
  output reg [4:0] rd,
  output reg [4:0] rs1,
  output reg [4:0] rs2,
  output reg [31:0] imm
);
  wire [6:0] opcode = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];
  always @(*) begin
    rd = 0;
    rs1 = 0;
    rs2 = 0;
    case (opcode)
      7'b0110111: begin
        op_type = `OP_LUI;
        rd = inst[11:7];
        imm = inst[31:12] << 12;
      end
      7'b0010111: begin
        op_type = `OP_AUIPC;
        rd = inst[11:7];
        imm = inst[31:12] << 12;
      end
      7'b1101111: begin
        op_type = `OP_JAL;
        rd = inst[11:7];
        imm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
      end
      7'b1100111: begin
        op_type = `OP_JALR;
        rd = inst[11:7];
        rs1 = inst[19:15];
        imm = { {21{inst[31]}}, inst[30:20] };
      end
      7'b0110011: begin
        rd = inst[11:7];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        case (funct3)
          3'b000: begin
            case (funct7)
              7'b0000000: op_type = `OP_ADD;
              7'b0100000: op_type = `OP_SUB;
            endcase
          end
          3'b001: op_type = `OP_SLL;
          3'b010: op_type = `OP_SLT;
          3'b011: op_type = `OP_SLTU;
          3'b100: op_type = `OP_XOR;
          3'b101: begin
            case (funct7)
              7'b0000000: op_type = `OP_SRL;
              7'b0100000: op_type = `OP_SRA;
            endcase
          end
          3'b110: op_type = `OP_OR;
          3'b111: op_type = `OP_AND;
        endcase
      end
      7'b0010011: begin
        rd = inst[11:7];
        rs1 = inst[19:15];
        imm = { {21{inst[31]}}, inst[30:20] };
        case (funct3)
          3'b000: op_type = `OP_ADDI;
          3'b001: op_type = `OP_SLLI;  // shamt = imm[4:0]
          3'b010: op_type = `OP_SLTI;
          3'b011: op_type = `OP_SLTIU;
          3'b100: op_type = `OP_XORI;
          3'b101: begin  // shamt = imm[4:0]
            case (funct7)
              7'b0000000: op_type = `OP_SRLI;
              7'b0100000: op_type = `OP_SRAI;
            endcase
          end
          3'b110: op_type = `OP_ORI;
          3'b111: op_type = `OP_ANDI;
        endcase
      end
      7'b0000011: begin
        rs1 = inst[19:15];
        imm = { {21{inst[31]}}, inst[30:20] };
        case (funct3)
          3'b000: op_type = `OP_LB;
          3'b001: op_type = `OP_LH;
          3'b010: op_type = `OP_LW;
          3'b100: op_type = `OP_LBU;
          3'b101: op_type = `OP_LHU;
        endcase
      end
      7'b0100011: begin
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        imm = { {21{inst[31]}}, inst[30:25], inst[11:7] };
        case (funct3)
          3'b000: op_type = `OP_SB;
          3'b001: op_type = `OP_SH;
          3'b010: op_type = `OP_SW;
        endcase
      end
      7'b1100011: begin
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        imm = { {21{inst[31]}}, inst[7], inst[30:25], inst[11:8] };
        case (funct3)
          3'b000: begin
            case (funct7)
              7'b0000000: op_type = `OP_BEQ;
              7'b0000001: op_type = `OP_BNE;
            endcase
          end
          3'b001: op_type = `OP_BGE;
          3'b100: op_type = `OP_BLT;
          3'b101: op_type = `OP_BGEU;
          3'b110: op_type = `OP_BLTU;
        endcase
      end
    endcase
  end
endmodule