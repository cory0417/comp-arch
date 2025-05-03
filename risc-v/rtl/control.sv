import types::*;

module control (
    input logic [6:0] op,
    input logic [2:0] funct3,
    input logic funct7_5,

    output logic [1:0] pc_src,  // mux select for program counter
    output logic [2:0] result_src,  // mux select for result
    output logic [3:0] alu_control,  // ALU function control
    output logic alu_src,  // mux select for ALU operand (immediate or read data)
    output instruction_t instruction_type  // instruction type
);
  always_comb begin
    case (op)
      OP_LUI: instruction_type = U_TYPE;  // LUI
      OP_AUIPC: instruction_type = U_TYPE;  // AUIPC
      OP_JAL: instruction_type = J_TYPE;  // JAL
      OP_REG: instruction_type = R_TYPE;
      OP_IMM: instruction_type = I_TYPE;  // ADDI, SLTI, etc.
      OP_JALR: instruction_type = I_TYPE;  // JALR
      OP_LOAD: instruction_type = I_TYPE;  // LB, LH, LW
      OP_STORE: instruction_type = S_TYPE;  // SB, SH, SW
      OP_BRANCH: instruction_type = B_TYPE;  // BEQ, BNE, BLT, BGE, BLTU, BGEU
      default: instruction_type = R_TYPE;  // Default to R_TYPE for unused opcodes
    endcase
  end

  // Program counter select
  always_comb begin
    case (op)
      OP_JALR: pc_src = 2'b00;
      OP_JAL: pc_src = 2'b01;
      OP_BRANCH: pc_src = 2'b10;
      default: pc_src = 2'b11;
    endcase
  end

  // ALU control
  always_comb begin
    case (op)
      OP_REG: begin
        alu_src = 0;  // rs1, rs2
        unique case (funct3)
          // FUNCT3_SUB is same as FUNCT3_ADD
          FUNCT3_ADD:  alu_control = funct7_5 ? ALU_SUB : ALU_ADD;
          FUNCT3_SLL:  alu_control = ALU_SLL;
          FUNCT3_SLT:  alu_control = ALU_SLT;
          FUNCT3_SLTU: alu_control = ALU_SLTU;
          FUNCT3_XOR:  alu_control = ALU_XOR;
          // FUNCT3_SRA is same as FUNCT3_SRL
          FUNCT3_SRL:  alu_control = funct7_5 ? ALU_SRA : ALU_SRL;
          FUNCT3_OR:   alu_control = ALU_OR;
          FUNCT3_AND:  alu_control = ALU_AND;
        endcase
      end
      OP_IMM: begin
        alu_src = 1;  // rs1, imm
        unique case (funct3)
          FUNCT3_ADDI:  alu_control = ALU_ADD;
          FUNCT3_SLTI:  alu_control = ALU_SLT;
          FUNCT3_SLTIU: alu_control = ALU_SLTU;
          FUNCT3_XORI:  alu_control = ALU_XOR;
          FUNCT3_ORI:   alu_control = ALU_OR;
          FUNCT3_ANDI:  alu_control = ALU_AND;
          FUNCT3_SLLI:  alu_control = ALU_SLL;
          // FUNCT3_SRAI is same as FUNCT3_SRLI
          FUNCT3_SRLI:  alu_control = funct7_5 ? ALU_SRA : ALU_SRL;
        endcase
      end
      OP_BRANCH: begin
        alu_src = 0;  // rs1, rs2
        case (funct3)
          FUNCT3_BEQ: alu_control = ALU_BEQ;
          FUNCT3_BNE: alu_control = ALU_BNE;
          FUNCT3_BLT: alu_control = ALU_BLT;
          FUNCT3_BGE: alu_control = ALU_BGE;
          FUNCT3_BLTU: alu_control = ALU_BLTU;
          FUNCT3_BGEU: alu_control = ALU_BGEU;
          default: alu_control = ALU_BEQ;  // Default to BEQ
        endcase
      end
      default: begin  // Unused for: LUI, AUIPC, LOAD, STORE, JALR, JAL
        alu_control = 4'b0;
        alu_src = 0;
      end
    endcase
  end

  // Register file write data source (ALU, imm, imm + PC, PC + 4, memory read data)
  always_comb begin
    case (op)
      OP_IMM, OP_REG: result_src = 0;  // ALU result
      OP_LUI: result_src = 1;  // Zero-extended immediate
      OP_AUIPC: result_src = 2;  // PC + immediate
      OP_JAL, OP_JALR: result_src = 3;  // PC + 4
      OP_LOAD: result_src = 4;  // Memory read data
      default: result_src = 5;  // No write data
    endcase
  end
endmodule
