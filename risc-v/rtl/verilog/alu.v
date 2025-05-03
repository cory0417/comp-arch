module alu (
	alu_control,
	alu_in1,
	alu_in2,
	alu_result
);
	reg _sv2v_0;
	input wire [3:0] alu_control;
	input wire [31:0] alu_in1;
	input wire [31:0] alu_in2;
	output reg [31:0] alu_result;
	wire [31:0] add_result;
	wire [31:0] sub_result;
	wire lt;
	wire ltu;
	wire eq;
	assign eq = alu_in1 == alu_in2;
	assign lt = $signed(alu_in1) < $signed(alu_in2);
	assign ltu = alu_in1 < alu_in2;
	assign add_result = alu_in1 + alu_in2;
	assign sub_result = alu_in1 - alu_in2;
	always @(*) begin
		if (_sv2v_0)
			;
		case (alu_control)
			4'd0: alu_result = add_result;
			4'd1: alu_result = sub_result;
			4'd2: alu_result = alu_in1 << (alu_in2 & 32'h0000001f);
			4'd3: alu_result = {31'b0000000000000000000000000000000, lt};
			4'd4: alu_result = {31'b0000000000000000000000000000000, ltu};
			4'd5: alu_result = alu_in1 ^ alu_in2;
			4'd6: alu_result = alu_in1 >> (alu_in2 & 32'h0000001f);
			4'd7: alu_result = $signed(alu_in1) >>> (alu_in2 & 32'h0000001f);
			4'd8: alu_result = alu_in1 | alu_in2;
			4'd9: alu_result = alu_in1 & alu_in2;
			4'd10: alu_result = {31'b0000000000000000000000000000000, eq};
			4'd11: alu_result = {31'b0000000000000000000000000000000, !eq};
			4'd12: alu_result = {31'b0000000000000000000000000000000, lt};
			4'd13: alu_result = {31'b0000000000000000000000000000000, !lt};
			4'd14: alu_result = {31'b0000000000000000000000000000000, ltu};
			4'd15: alu_result = {31'b0000000000000000000000000000000, !ltu};
			default: alu_result = 0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
