module pc_selector (
	pc_src,
	rs1,
	imm,
	alu_result,
	pc,
	pc_next
);
	input wire [1:0] pc_src;
	input wire [31:0] rs1;
	input wire [31:0] imm;
	input wire [31:0] alu_result;
	input wire [31:0] pc;
	output wire [31:0] pc_next;
	wire [31:0] pc_jalr;
	wire [31:0] pc_jal;
	wire [31:0] pc_branch;
	wire [31:0] pc_4;
	assign pc_4 = pc + 4;
	assign pc_jalr = rs1 + $signed(imm);
	assign pc_jal = pc + $signed(imm);
	assign pc_branch = pc + $signed(imm);
	assign pc_next = (pc_src == 2'b00 ? pc_jalr : (pc_src == 2'b01 ? pc_jal : ((pc_src == 2'b10) && (alu_result == 32'b00000000000000000000000000000001) ? pc_branch : pc_4)));
endmodule
