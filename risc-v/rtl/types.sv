package types;

  typedef enum logic [2:0] {
    U_TYPE,
    J_TYPE,
    R_TYPE,
    I_TYPE,
    S_TYPE,
    B_TYPE
  } instruction_t;

  typedef enum logic [1:0] {
    FETCH_INSTR,
    EXECUTE,
    WAIT_MEM
  } cpu_state_t;

  // verilog_lint: waive-start parameter-name-style
  // Opcodes
  localparam logic [6:0] OP_LUI = 7'b0110111;
  localparam logic [6:0] OP_AUIPC = 7'b0010111;
  localparam logic [6:0] OP_JAL = 7'b1101111;
  localparam logic [6:0] OP_JALR = 7'b1100111;
  localparam logic [6:0] OP_BRANCH = 7'b1100011;
  localparam logic [6:0] OP_LOAD = 7'b0000011;
  localparam logic [6:0] OP_STORE = 7'b0100011;
  localparam logic [6:0] OP_REG = 7'b0110011;
  localparam logic [6:0] OP_IMM = 7'b0010011;

  // funct3
  // B-type
  localparam logic [2:0] FUNCT3_BEQ = 3'b000;
  localparam logic [2:0] FUNCT3_BNE = 3'b001;
  localparam logic [2:0] FUNCT3_BLT = 3'b100;
  localparam logic [2:0] FUNCT3_BGE = 3'b101;
  localparam logic [2:0] FUNCT3_BLTU = 3'b110;
  localparam logic [2:0] FUNCT3_BGEU = 3'b111;
  // I-type
  localparam logic [2:0] FUNCT3_LB = 3'b000;
  localparam logic [2:0] FUNCT3_LH = 3'b001;
  localparam logic [2:0] FUNCT3_LW = 3'b010;
  localparam logic [2:0] FUNCT3_LBU = 3'b100;
  localparam logic [2:0] FUNCT3_LHU = 3'b101;
  localparam logic [2:0] FUNCT3_ADDI = 3'b000;
  localparam logic [2:0] FUNCT3_SLTI = 3'b010;
  localparam logic [2:0] FUNCT3_SLTIU = 3'b011;
  localparam logic [2:0] FUNCT3_XORI = 3'b100;
  localparam logic [2:0] FUNCT3_ORI = 3'b110;
  localparam logic [2:0] FUNCT3_ANDI = 3'b111;
  localparam logic [2:0] FUNCT3_SLLI = 3'b001;
  localparam logic [2:0] FUNCT3_SRLI = 3'b101;
  localparam logic [2:0] FUNCT3_SRAI = 3'b101;
  // S-type
  localparam logic [2:0] FUNCT3_SB = 3'b000;
  localparam logic [2:0] FUNCT3_SH = 3'b001;
  localparam logic [2:0] FUNCT3_SW = 3'b010;
  // R-type
  localparam logic [2:0] FUNCT3_ADD = 3'b000;
  localparam logic [2:0] FUNCT3_SUB = 3'b000;
  localparam logic [2:0] FUNCT3_SLL = 3'b001;
  localparam logic [2:0] FUNCT3_SLT = 3'b010;
  localparam logic [2:0] FUNCT3_SLTU = 3'b011;
  localparam logic [2:0] FUNCT3_XOR = 3'b100;
  localparam logic [2:0] FUNCT3_SRL = 3'b101;
  localparam logic [2:0] FUNCT3_SRA = 3'b101;
  localparam logic [2:0] FUNCT3_OR = 3'b110;
  localparam logic [2:0] FUNCT3_AND = 3'b111;

  // === Funct7 (bit 5) ===
  // Only R-type and I-type (shift instructions) use funct7 field.

  // I-types
  localparam logic FUNCT7_5_SLLI = 1'b0;
  localparam logic FUNCT7_5_SRLI = 1'b0;
  localparam logic FUNCT7_5_SRAI = 1'b1;

  // R-types
  localparam logic FUNCT7_5_ADD = 1'b0;
  localparam logic FUNCT7_5_SUB = 1'b1;
  localparam logic FUNCT7_5_SLL = 1'b0;
  localparam logic FUNCT7_5_SLT = 1'b0;
  localparam logic FUNCT7_5_SLTU = 1'b0;
  localparam logic FUNCT7_5_XOR = 1'b0;
  localparam logic FUNCT7_5_SRL = 1'b0;
  localparam logic FUNCT7_5_SRA = 1'b1;
  localparam logic FUNCT7_5_OR = 1'b0;
  localparam logic FUNCT7_5_AND = 1'b0;

  // verilog_lint: waive-end parameter-name-style
endpackage
