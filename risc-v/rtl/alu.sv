import types::*;

module alu (
    input logic [31:0] alu_in1,
    input logic [31:0] alu_in2,
    input logic [2:0] funct3,
    input logic funct7_5,
    output logic [31:0] alu_result,
    output logic predicate  // predicate for branch instructions
);

  logic [31:0] add_result;
  logic [31:0] sub_result;
  logic lt, ltu, eq;  // less than, less than unsigned, equal

  assign eq = (alu_in1 == alu_in2);
  assign lt = ($signed(alu_in1) < $signed(alu_in2));
  assign ltu = (alu_in1 < alu_in2);
  assign add_result = alu_in1 + alu_in2;
  assign sub_result = alu_in1 - alu_in2;


  always_comb begin
    unique case (funct3)
      // B-type
      FUNCT3_BEQ | FUNCT3_BNE:   predicate = (funct3 == FUNCT3_BEQ) ? eq : !eq;
      FUNCT3_BLT | FUNCT3_BGE:   predicate = (funct3 == FUNCT3_BLT) ? lt : !lt;
      FUNCT3_BLTU | FUNCT3_BGEU: predicate = (funct3 == FUNCT3_BLTU) ? ltu : !ltu;

      // I-type
      FUNCT3_ADDI: alu_result = add_result;
      FUNCT3_SLTI: alu_result = lt;
      FUNCT3_SLTIU: alu_result = ltu;
      FUNCT3_XORI: alu_result = alu_in1 ^ alu_in2;
      FUNCT3_ORI: alu_result = alu_in1 | alu_in2;
      FUNCT3_ANDI: alu_result = alu_in1 & alu_in2;
      FUNCT3_SLLI: alu_result = alu_in1 << alu_in2;
      FUNCT3_SRLI | FUNCT3_SRAI:
      alu_result = funct7_5 ? (alu_in1 >>> alu_in2) : (alu_in1 >> alu_in2);
      FUNCT3_LB | FUNCT3_LH | FUNCT3_LW | FUNCT3_LBU | FUNCT3_LHU:
      alu_result = add_result;  // Load instructions; rs1 + imm_ext

      // R-type
      FUNCT3_ADD | FUNCT3_SUB: alu_result = funct7_5 ? sub_result : add_result;
      FUNCT3_SRL | FUNCT3_SRA: alu_result = funct7_5 ? (alu_in1 >>> alu_in2) : (alu_in1 >> alu_in2);
      FUNCT3_SLL: alu_result = alu_in1 << alu_in2;
      FUNCT3_SLT: alu_result = lt;
      FUNCT3_SLTU: alu_result = ltu;
      FUNCT3_XOR: alu_result = alu_in1 ^ alu_in2;
      FUNCT3_OR: alu_result = alu_in1 | alu_in2;
      FUNCT3_AND: alu_result = alu_in1 & alu_in2;

      // S-type
      FUNCT3_SB | FUNCT3_SH | FUNCT3_SW:
      alu_result = add_result;  // Store instructions; rs1 + imm_ext
    endcase
  end
endmodule
