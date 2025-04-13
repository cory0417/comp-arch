import types::*;

module imm_extender (
    input  logic [31:0] instr,
    output logic [31:0] imm_ext
);

  logic [6:0] op;
  assign op = instr[6:0];
  always_comb begin
    case (op)
      OP_IMM, OP_JALR, OP_LOAD: begin  // 12 bits, sign-extended to 32 bits
        imm_ext = {{20{instr[31]}}, instr[31:20]};
      end
      OP_STORE: begin  // 12-bits, sign-extended to 32 bits
        imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      end
      OP_BRANCH: begin  // 13 bits, sign-extended to 32 bits
        imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      end
      OP_JAL: begin  // 21 bits, sign-extended to 32 bits
        imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      end
      OP_LUI, OP_AUIPC: begin  // 20 bits, zero-extended for lower 12 bits
        imm_ext = {instr[31:12], {12{'0}}};
      end
      default: imm_ext = 32'b0;
    endcase
  end
endmodule
