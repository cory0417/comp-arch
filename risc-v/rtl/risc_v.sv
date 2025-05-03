import types::*;

module risc_v (
    input logic clk,
    input logic reset_n,

    output logic mem_wen,  // memory write enable
    output logic [31:0] mem_ra,  // address to read in memory
    output logic [31:0] mem_wa,  // address to write in memory
    output logic [31:0] mem_wd,  // memory write at clk posedge
    input logic [31:0] mem_rd,  // memory read at clk posedge
    output logic [2:0] mem_funct3  // function code for memory operation
);

  logic [31:0] instr;
  logic [31:0] alu_result;

  logic [ 2:0] result_src;
  logic alu_src, reg_wen;
  logic [1:0] pc_src;
  logic [3:0] alu_control;
  instruction_t instruction_type;
  logic [31:0] imm_ext;

  logic [6:0] op;
  logic [2:0] funct3;
  assign op = instr[6:0];
  assign funct3 = instr[14:12];

  logic is_store, is_load, is_branch, is_jal;
  assign is_store  = (op == OP_STORE);
  assign is_load   = (op == OP_LOAD);
  assign is_branch = (op == OP_BRANCH);
  assign is_jal    = (op == OP_JAL);

  /*--- CONTROL ---*/
  control u_control (
      .op(op),
      .funct3(funct3),
      .funct7_5(instr[30]),
      .pc_src(pc_src),
      .result_src(result_src),
      .alu_control(alu_control),
      .alu_src(alu_src),
      .instruction_type(instruction_type)
  );

  /*--- REGISTER FILE ---*/
  logic [4:0] rs1_addr, rs2_addr, rd_addr;
  logic [31:0] rs1, rs2, rd_data;
  assign rs1_addr = instr[19:15];
  assign rs2_addr = instr[24:20];
  assign rd_addr  = instr[11:7];

  // Memory-related signals based on instruction
  assign mem_wd   = rs2;  // Write data to memory is always rs2
  assign mem_wa   = rs1 + imm_ext;  // Address to write in memory is always rs1 + immediate

  register_file u_register_file (
      .clk(clk),
      .reset_n(reset_n),
      .a1(rs1_addr),
      .a2(rs2_addr),
      .a3(rd_addr),
      .wd(rd_data),
      .wen(reg_wen),  // from control unit
      .rd1(rs1),
      .rd2(rs2)
  );

  /*--- IMMEDIATE EXTENDER ---*/
  imm_extender u_imm_extender (
      .instr  (instr),
      .imm_ext(imm_ext)
  );

  /*--- PROGRAM COUNTER ---*/
  logic [31:0] pc_next, pc;

  pc_selector u_pc_selector (
      .pc_src(pc_src),  // from control unit
      .rs1(rs1),
      .imm(imm_ext),
      .alu_result(alu_result),  // uses ALU result for branch
      .pc(pc),
      .pc_next(pc_next)
  );

  /*--- ALU ---*/
  logic [31:0] alu_in1, alu_in2;
  assign alu_in1 = rs1;
  assign alu_in2 = alu_src ? imm_ext : rs2;

  // ALU control signal
  alu u_alu (
      .alu_control(alu_control),  // from control unit
      .alu_in1(alu_in1),
      .alu_in2(alu_in2),
      .alu_result(alu_result)
  );

  /*--- Register File Writeback ---*/
  always_comb begin
    case (result_src)
      0: rd_data = alu_result;  // OP_IMM, OP_REG
      1: rd_data = imm_ext;  // OP_LUI
      2: rd_data = pc + imm_ext;  // OP_AUIPC
      3: rd_data = pc + 4;  // OP_JAL, OP_JALR
      4: rd_data = mem_rd;  // OP_LOAD
      default: rd_data = 32'b0;  // No write data
    endcase
  end

  /*--- STATE MACHINE ---*/
  cpu_state_t state;
  // No write enable for branch and store
  assign reg_wen = !(is_branch | is_store) & (state != FETCH_INSTR);
  assign mem_funct3 = ((is_load | is_store) & state != WAIT_MEM) ? funct3 : 3'b010;
  assign mem_wen = is_store & state == EXECUTE;  // Memory write enable only for store

  always_comb begin
    if (state == WAIT_MEM) begin
      mem_ra = pc;
    end else begin  // state == FETCH_INSTR or EXECUTE
      if (is_load) begin
        mem_ra = rs1 + imm_ext;  // Address to load from during execution
      end else begin
        mem_ra = pc_next;  // Update memory address for instruction fetch
      end
    end
  end


  always_ff @(posedge clk) begin
    if (!reset_n) begin
      pc <= 32'b0;  // Initialize program counter to -4 to start at 0 when it loads pc+4
      state <= WAIT_MEM;  // Start in instruction fetch state
    end else begin
      case (state)
        FETCH_INSTR: begin
          if (is_jal) pc <= pc_next;
          state <= EXECUTE;
          instr <= mem_rd;
        end
        EXECUTE: begin
          if (!is_jal) pc <= pc_next;
          // Two cases for next state
          if (is_load | is_store) begin
            state <= WAIT_MEM;  // Wait for memory operation
          end else begin
            state <= FETCH_INSTR;  // Go back to fetch next instruction
          end
        end
        default: begin  // state == WAIT_MEM
          state <= FETCH_INSTR;  // Just need this extra state to wait for memory
        end
      endcase
    end
  end
endmodule
