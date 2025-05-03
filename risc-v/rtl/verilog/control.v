module control (
	op,
	funct3,
	funct7_5,
	pc_src,
	result_src,
	alu_control,
	alu_src,
	instruction_type
);
	reg _sv2v_0;
	input wire [6:0] op;
	input wire [2:0] funct3;
	input wire funct7_5;
	output reg [1:0] pc_src;
	output reg [2:0] result_src;
	output reg [3:0] alu_control;
	output reg alu_src;
	output reg [2:0] instruction_type;
	localparam [6:0] types_OP_AUIPC = 7'b0010111;
	localparam [6:0] types_OP_BRANCH = 7'b1100011;
	localparam [6:0] types_OP_IMM = 7'b0010011;
	localparam [6:0] types_OP_JAL = 7'b1101111;
	localparam [6:0] types_OP_JALR = 7'b1100111;
	localparam [6:0] types_OP_LOAD = 7'b0000011;
	localparam [6:0] types_OP_LUI = 7'b0110111;
	localparam [6:0] types_OP_REG = 7'b0110011;
	localparam [6:0] types_OP_STORE = 7'b0100011;
	always @(*) begin
		if (_sv2v_0)
			;
		case (op)
			types_OP_LUI: instruction_type = 3'd0;
			types_OP_AUIPC: instruction_type = 3'd0;
			types_OP_JAL: instruction_type = 3'd1;
			types_OP_REG: instruction_type = 3'd2;
			types_OP_IMM: instruction_type = 3'd3;
			types_OP_JALR: instruction_type = 3'd3;
			types_OP_LOAD: instruction_type = 3'd3;
			types_OP_STORE: instruction_type = 3'd4;
			types_OP_BRANCH: instruction_type = 3'd5;
			default: instruction_type = 3'd2;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (op)
			types_OP_JALR: pc_src = 2'b00;
			types_OP_JAL: pc_src = 2'b01;
			types_OP_BRANCH: pc_src = 2'b10;
			default: pc_src = 2'b11;
		endcase
	end
	localparam [2:0] types_FUNCT3_ADD = 3'b000;
	localparam [2:0] types_FUNCT3_ADDI = 3'b000;
	localparam [2:0] types_FUNCT3_AND = 3'b111;
	localparam [2:0] types_FUNCT3_ANDI = 3'b111;
	localparam [2:0] types_FUNCT3_BEQ = 3'b000;
	localparam [2:0] types_FUNCT3_BGE = 3'b101;
	localparam [2:0] types_FUNCT3_BGEU = 3'b111;
	localparam [2:0] types_FUNCT3_BLT = 3'b100;
	localparam [2:0] types_FUNCT3_BLTU = 3'b110;
	localparam [2:0] types_FUNCT3_BNE = 3'b001;
	localparam [2:0] types_FUNCT3_OR = 3'b110;
	localparam [2:0] types_FUNCT3_ORI = 3'b110;
	localparam [2:0] types_FUNCT3_SLL = 3'b001;
	localparam [2:0] types_FUNCT3_SLLI = 3'b001;
	localparam [2:0] types_FUNCT3_SLT = 3'b010;
	localparam [2:0] types_FUNCT3_SLTI = 3'b010;
	localparam [2:0] types_FUNCT3_SLTIU = 3'b011;
	localparam [2:0] types_FUNCT3_SLTU = 3'b011;
	localparam [2:0] types_FUNCT3_SRL = 3'b101;
	localparam [2:0] types_FUNCT3_SRLI = 3'b101;
	localparam [2:0] types_FUNCT3_XOR = 3'b100;
	localparam [2:0] types_FUNCT3_XORI = 3'b100;
	always @(*) begin
		if (_sv2v_0)
			;
		case (op)
			types_OP_REG: begin
				alu_src = 0;
				(* full_case, parallel_case *)
				case (funct3)
					types_FUNCT3_ADD: alu_control = (funct7_5 ? 4'd1 : 4'd0);
					types_FUNCT3_SLL: alu_control = 4'd2;
					types_FUNCT3_SLT: alu_control = 4'd3;
					types_FUNCT3_SLTU: alu_control = 4'd4;
					types_FUNCT3_XOR: alu_control = 4'd5;
					types_FUNCT3_SRL: alu_control = (funct7_5 ? 4'd7 : 4'd6);
					types_FUNCT3_OR: alu_control = 4'd8;
					types_FUNCT3_AND: alu_control = 4'd9;
				endcase
			end
			types_OP_IMM: begin
				alu_src = 1;
				(* full_case, parallel_case *)
				case (funct3)
					types_FUNCT3_ADDI: alu_control = 4'd0;
					types_FUNCT3_SLTI: alu_control = 4'd3;
					types_FUNCT3_SLTIU: alu_control = 4'd4;
					types_FUNCT3_XORI: alu_control = 4'd5;
					types_FUNCT3_ORI: alu_control = 4'd8;
					types_FUNCT3_ANDI: alu_control = 4'd9;
					types_FUNCT3_SLLI: alu_control = 4'd2;
					types_FUNCT3_SRLI: alu_control = (funct7_5 ? 4'd7 : 4'd6);
				endcase
			end
			types_OP_BRANCH: begin
				alu_src = 0;
				case (funct3)
					types_FUNCT3_BEQ: alu_control = 4'd10;
					types_FUNCT3_BNE: alu_control = 4'd11;
					types_FUNCT3_BLT: alu_control = 4'd12;
					types_FUNCT3_BGE: alu_control = 4'd13;
					types_FUNCT3_BLTU: alu_control = 4'd14;
					types_FUNCT3_BGEU: alu_control = 4'd15;
					default: alu_control = 4'd10;
				endcase
			end
			default: begin
				alu_control = 4'b0000;
				alu_src = 0;
			end
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (op)
			types_OP_IMM, types_OP_REG: result_src = 0;
			types_OP_LUI: result_src = 1;
			types_OP_AUIPC: result_src = 2;
			types_OP_JAL, types_OP_JALR: result_src = 3;
			types_OP_LOAD: result_src = 4;
			default: result_src = 5;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
