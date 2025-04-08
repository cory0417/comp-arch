module pc (
    input  logic [ 1:0] pc_src,
    input  logic [31:0] rs1,
    input  logic [31:0] imm,
    input  logic [31:0] alu_result,
    input  logic [31:0] pc,
    output logic [31:0] pc_next
);
  /* 4 cases for pc_src
  * 1. pc_jalr = rs1 + imm_ext_i; rd_data = pc + 4; JALR (I-type)
  * 2. pc_jal = pc + imm_ext_j; rd_data = pc + 4; JAL (J-type)
  * 3. pc_branch = pc + imm_ext_b OR pc = pc + 4; predicate-dependent
  * 4. pc_4 = pc + 4; default
  */
  assign pc_4 = pc + 4;  // PC + 4
  assign pc_jalr = rs1 + imm;  // JALR
  assign pc_jal = pc + imm;  // JAL
  assign pc_branch = pc + imm;  // Branch instruction (BEQ, BNE, etc.)

  assign pc_next = (pc_src == 2'b00) ? pc_jalr :
                   (pc_src == 2'b01) ? pc_jal :
                   (pc_src == 2'b10 && alu_result == {31'b0, 1'b1}) ? pc_branch : pc_4;

`ifdef COCOTB_SIM
  initial begin
    $dumpfile("pc_tb.vcd");
    $dumpvars(0, pc);
  end
`endif
endmodule
