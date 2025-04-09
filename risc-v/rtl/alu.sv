import types::*;

module alu (
    input alu_control_t alu_control,
    input logic [31:0] alu_in1,
    input logic [31:0] alu_in2,
    output logic [31:0] alu_result
);

  logic [31:0] add_result, sub_result;
  logic lt, ltu, eq;  // less than, less than unsigned, equal

  assign eq = (alu_in1 == alu_in2);
  assign lt = ($signed(alu_in1) < $signed(alu_in2));
  assign ltu = (alu_in1 < alu_in2);
  assign add_result = alu_in1 + alu_in2;
  assign sub_result = alu_in1 - alu_in2;

  always_comb begin
    case (alu_control)
      ALU_ADD:  alu_result = add_result;
      ALU_SUB:  alu_result = sub_result;
      ALU_SLL:  alu_result = alu_in1 << (alu_in2 & 5'b11111);
      ALU_SLT:  alu_result = lt;
      ALU_SLTU: alu_result = ltu;
      ALU_XOR:  alu_result = alu_in1 ^ alu_in2;
      ALU_SRL:  alu_result = alu_in1 >> (alu_in2 & 5'b11111);
      ALU_SRA:  alu_result = $signed(alu_in1) >>> (alu_in2 & 5'b11111);
      ALU_OR:   alu_result = alu_in1 | alu_in2;
      ALU_AND:  alu_result = alu_in1 & alu_in2;
      // Branch instructions
      ALU_BEQ:  alu_result = {31'b0, eq};
      ALU_BNE:  alu_result = {31'b0, !eq};
      ALU_BLT:  alu_result = {31'b0, lt};
      ALU_BGE:  alu_result = {31'b0, !lt};
      ALU_BLTU: alu_result = {31'b0, ltu};
      ALU_BGEU: alu_result = {31'b0, !ltu};
      default: begin
        alu_result = 0;
      end
    endcase
  end

`ifdef COCOTB_SIM
  initial begin
    $dumpfile("alu_tb.vcd");
    $dumpvars(0, alu);
  end
`endif
endmodule
