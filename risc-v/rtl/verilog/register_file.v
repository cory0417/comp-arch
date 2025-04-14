module register_file (
	clk,
	a1,
	a2,
	a3,
	wd,
	wen,
	rd1,
	rd2
);
	input wire clk;
	input wire [4:0] a1;
	input wire [4:0] a2;
	input wire [4:0] a3;
	input wire [31:0] wd;
	input wire wen;
	output wire [31:0] rd1;
	output wire [31:0] rd2;
	reg [31:0] registers [0:31];
	initial begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < 32; i = i + 1)
			registers[i] = 32'b00000000000000000000000000000000;
	end
	assign rd1 = (a1 != 0 ? registers[a1] : 32'b00000000000000000000000000000000);
	assign rd2 = (a2 != 0 ? registers[a2] : 32'b00000000000000000000000000000000);
	always @(posedge clk)
		if (wen && (a3 != 5'd0))
			registers[a3] <= wd;
endmodule
