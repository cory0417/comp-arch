module memory_array (
	clk,
	write_enable,
	write_address,
	write_data,
	read_address,
	read_data
);
	parameter INIT_FILE = "";
	input wire clk;
	input wire write_enable;
	input wire [10:0] write_address;
	input wire [7:0] write_data;
	input wire [10:0] read_address;
	output reg [7:0] read_data;
	reg [7:0] memory [0:2047];
	reg signed [31:0] i;
	initial if (INIT_FILE)
		$readmemh(INIT_FILE, memory);
	else
		for (i = 0; i < 2048; i = i + 1)
			memory[i] <= 8'd0;
	always @(posedge clk) read_data <= memory[read_address];
	always @(posedge clk)
		if (write_enable)
			memory[write_address] <= write_data;
endmodule
