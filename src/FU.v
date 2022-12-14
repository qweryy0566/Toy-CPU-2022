`include "config.v"

`ifndef __FU__
`define __FU__

module FU (
  input wire                  RS_valid,
  input wire [`OP_LOG - 1:0]  RS_op,
  input wire [31:0]           RS_Vj,
  input wire [31:0]           RS_Vk,
  input wire [31:0]           RS_Imm,
  input wire [`ROB_LOG - 1:0] RS_DestRob,
  input wire [31:0]           RS_CurPC,

  output reg                  B_enable,
  output reg [31:0]           B_value,
  output reg [`ROB_LOG - 1:0] B_RobId,
  output reg [31:0]           B_toPC
);

  always @(*) begin
    B_enable = 0;
    if (RS_valid && RS_op != `OP_NOP) begin
      B_enable = 1;
      B_RobId = RS_DestRob;
      B_toPC = -1;
      case (RS_op)
        `OP_LUI:
          B_value = RS_Imm;
        `OP_AUIPC:
          B_value = RS_CurPC + RS_Imm;
        `OP_JAL: begin
          B_value = RS_CurPC + 4;
          B_toPC = RS_CurPC + RS_Imm;
        end
        `OP_JALR: begin
          B_value = RS_CurPC + 4;
          B_toPC = RS_Vj + RS_Imm & 32'hFFFFFFFE;
        end
        `OP_BEQ:
          if (RS_Vj == RS_Vk)
            B_toPC = RS_CurPC + RS_Imm;
        `OP_BNE:
          if (RS_Vj != RS_Vk)
            B_toPC = RS_CurPC + RS_Imm;
        `OP_BLT:
          if ($signed(RS_Vj) < $signed(RS_Vk))
            B_toPC = RS_CurPC + RS_Imm;
        `OP_BGE:
          if ($signed(RS_Vj) >= $signed(RS_Vk))
            B_toPC = RS_CurPC + RS_Imm;
        `OP_BLTU:
          if (RS_Vj < RS_Vk)
            B_toPC = RS_CurPC + RS_Imm;
        `OP_BGEU:
          if (RS_Vj >= RS_Vk)
            B_toPC = RS_CurPC + RS_Imm;
        `OP_ADDI:
          B_value = RS_Vj + RS_Imm;
        `OP_SLTI:
          B_value = $signed(RS_Vj) < $signed(RS_Imm);
        `OP_SLTIU:
          B_value = RS_Vj < RS_Imm;
        `OP_XORI:
          B_value = RS_Vj ^ RS_Imm;
        `OP_ORI:
          B_value = RS_Vj | RS_Imm;
        `OP_ANDI:
          B_value = RS_Vj & RS_Imm;
        `OP_SLLI:
          B_value = RS_Vj << RS_Imm[4:0];
        `OP_SRLI:
          B_value = RS_Vj >> RS_Imm[4:0];
        `OP_SRAI:
          B_value = $signed(RS_Vj) >>> RS_Imm[4:0];
        `OP_ADD:
          B_value = RS_Vj + RS_Vk;
        `OP_SUB:
          B_value = RS_Vj - RS_Vk;
        `OP_SLL:
          B_value = RS_Vj << RS_Vk[4:0];
        `OP_SLT:
          B_value = $signed(RS_Vj) < $signed(RS_Vk) ? 1 : 0;
        `OP_SLTU:
          B_value = RS_Vj < RS_Vk ? 1 : 0;
        `OP_XOR:
          B_value = RS_Vj ^ RS_Vk;
        `OP_SRL:
          B_value = RS_Vj >> RS_Vk[4:0];
        `OP_SRA:
          B_value = $signed(RS_Vj) >>> RS_Vk[4:0];
        `OP_OR:
          B_value = RS_Vj | RS_Vk;
        `OP_AND:
          B_value = RS_Vj & RS_Vk;
      endcase
    end
  end

endmodule

`endif