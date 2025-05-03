module uart_clk (
	clk,
	reset_n,
	out_clk
);
	input wire clk;
	input wire reset_n;
	output reg out_clk;
	localparam [3:0] OversampleDiv = 13;
	reg [3:0] counter;
	always @(posedge clk or negedge reset_n)
		if (!reset_n) begin
			out_clk <= 0;
			counter <= 0;
		end
		else begin
			counter <= counter + 1;
			if (counter == (OversampleDiv - 1)) begin
				counter <= 0;
				out_clk <= ~out_clk;
			end
		end
endmodule
