module uart_fifo (
	clk,
	wd,
	addr,
	wen,
	rd
);
	parameter signed [31:0] ADDR_WIDTH = 9;
	parameter signed [31:0] DATA_WIDTH = 8;
	input wire clk;
	input wire [DATA_WIDTH - 1:0] wd;
	input [ADDR_WIDTH - 1:0] addr;
	input wire wen;
	output reg [DATA_WIDTH - 1:0] rd;
	reg [DATA_WIDTH - 1:0] mem [0:(1 << ADDR_WIDTH) - 1];
	always @(posedge clk) begin
		if (wen)
			mem[addr] <= wd;
		rd <= mem[addr];
	end
endmodule
