module risc_v (
	clk,
	mem_wen,
	mem_ra,
	mem_wa,
	mem_wd,
	mem_rd,
	mem_funct3
);
	reg _sv2v_0;
	input wire clk;
	output wire mem_wen;
	output reg [31:0] mem_ra;
	output wire [31:0] mem_wa;
	output wire [31:0] mem_wd;
	input wire [31:0] mem_rd;
	output wire [2:0] mem_funct3;
	reg [31:0] instr;
	wire [31:0] alu_result;
	wire [2:0] result_src;
	wire alu_src;
	wire reg_wen;
	wire [1:0] pc_src;
	wire [3:0] alu_control;
	wire [2:0] instruction_type;
	wire [31:0] imm_ext;
	wire [6:0] op;
	wire [2:0] funct3;
	assign op = instr[6:0];
	assign funct3 = instr[14:12];
	wire is_store;
	wire is_load;
	wire is_branch;
	wire is_jal;
	localparam [6:0] types_OP_STORE = 7'b0100011;
	assign is_store = op == types_OP_STORE;
	localparam [6:0] types_OP_LOAD = 7'b0000011;
	assign is_load = op == types_OP_LOAD;
	localparam [6:0] types_OP_BRANCH = 7'b1100011;
	assign is_branch = op == types_OP_BRANCH;
	localparam [6:0] types_OP_JAL = 7'b1101111;
	assign is_jal = op == types_OP_JAL;
	control u_control(
		.op(op),
		.funct3(funct3),
		.funct7_5(instr[30]),
		.pc_src(pc_src),
		.result_src(result_src),
		.alu_control(alu_control),
		.alu_src(alu_src),
		.instruction_type(instruction_type)
	);
	wire [4:0] rs1_addr;
	wire [4:0] rs2_addr;
	wire [4:0] rd_addr;
	wire [31:0] rs1;
	wire [31:0] rs2;
	reg [31:0] rd_data;
	assign rs1_addr = instr[19:15];
	assign rs2_addr = instr[24:20];
	assign rd_addr = instr[11:7];
	assign mem_wd = rs2;
	assign mem_wa = rs1 + imm_ext;
	assign mem_wen = is_store;
	register_file u_register_file(
		.clk(clk),
		.a1(rs1_addr),
		.a2(rs2_addr),
		.a3(rd_addr),
		.wd(rd_data),
		.wen(reg_wen),
		.rd1(rs1),
		.rd2(rs2)
	);
	imm_extender u_imm_extender(
		.instr(instr),
		.imm_ext(imm_ext)
	);
	wire [31:0] pc_next;
	reg [31:0] pc;
	pc_selector u_pc_selector(
		.pc_src(pc_src),
		.rs1(rs1),
		.imm(imm_ext),
		.alu_result(alu_result),
		.pc(pc),
		.pc_next(pc_next)
	);
	wire [31:0] alu_in1;
	wire [31:0] alu_in2;
	assign alu_in1 = rs1;
	assign alu_in2 = (alu_src ? imm_ext : rs2);
	alu u_alu(
		.alu_control(alu_control),
		.alu_in1(alu_in1),
		.alu_in2(alu_in2),
		.alu_result(alu_result)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		case (result_src)
			0: rd_data = alu_result;
			1: rd_data = imm_ext;
			2: rd_data = pc + imm_ext;
			3: rd_data = pc + 4;
			4: rd_data = mem_rd;
			default: rd_data = 32'b00000000000000000000000000000000;
		endcase
	end
	reg [1:0] state;
	assign reg_wen = !(is_branch | is_store) & (state != 2'd0);
	assign mem_funct3 = ((is_load | is_store) & (state != 2'd2) ? funct3 : 3'b010);
	always @(*) begin
		if (_sv2v_0)
			;
		if (state == 2'd2)
			mem_ra = pc;
		else if (is_load)
			mem_ra = rs1 + imm_ext;
		else
			mem_ra = pc_next;
	end
	always @(posedge clk)
		case (state)
			2'd0: begin
				if (is_jal)
					pc <= pc_next;
				state <= 2'd1;
				instr <= mem_rd;
			end
			2'd1: begin
				if (op != types_OP_JAL)
					pc <= pc_next;
				if (is_load | is_store)
					state <= 2'd2;
				else
					state <= 2'd0;
			end
			default: state <= 2'd0;
		endcase
	initial begin
		pc = 32'b00000000000000000000000000000000;
		state = 2'd2;
	end
	initial _sv2v_0 = 0;
endmodule
