module imm_extender (
	instr,
	imm_ext
);
	reg _sv2v_0;
	input wire [31:0] instr;
	output reg [31:0] imm_ext;
	wire [6:0] op;
	assign op = instr[6:0];
	localparam [6:0] types_OP_AUIPC = 7'b0010111;
	localparam [6:0] types_OP_BRANCH = 7'b1100011;
	localparam [6:0] types_OP_IMM = 7'b0010011;
	localparam [6:0] types_OP_JAL = 7'b1101111;
	localparam [6:0] types_OP_JALR = 7'b1100111;
	localparam [6:0] types_OP_LOAD = 7'b0000011;
	localparam [6:0] types_OP_LUI = 7'b0110111;
	localparam [6:0] types_OP_STORE = 7'b0100011;
	always @(*) begin
		if (_sv2v_0)
			;
		case (op)
			types_OP_IMM, types_OP_JALR, types_OP_LOAD: imm_ext = {{20 {instr[31]}}, instr[31:20]};
			types_OP_STORE: imm_ext = {{20 {instr[31]}}, instr[31:25], instr[11:7]};
			types_OP_BRANCH: imm_ext = {{20 {instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
			types_OP_JAL: imm_ext = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
			types_OP_LUI, types_OP_AUIPC: imm_ext = {instr[31:12], {12 {1'sb0}}};
			default: imm_ext = 32'b00000000000000000000000000000000;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
