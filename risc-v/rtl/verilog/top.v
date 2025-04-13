module top (
	clk,
	LED,
	RGB_R,
	RGB_G,
	RGB_B
);
	parameter INIT_FILE = "";
	input wire clk;
	output wire LED;
	output wire RGB_R;
	output wire RGB_G;
	output wire RGB_B;
	wire [31:0] mem_ra;
	wire [31:0] mem_wa;
	wire [31:0] mem_rd;
	wire [31:0] mem_wd;
	wire mem_wen;
	wire [2:0] mem_funct3;
	risc_v u_risc_v(
		.clk(clk),
		.mem_wen(mem_wen),
		.mem_ra(mem_ra),
		.mem_wa(mem_wa),
		.mem_wd(mem_wd),
		.mem_rd(mem_rd),
		.mem_funct3(mem_funct3)
	);
	memory #(.INIT_FILE(INIT_FILE)) u_memory(
		.clk(clk),
		.write_mem(mem_wen),
		.funct3(mem_funct3),
		.write_address(mem_wa),
		.write_data(mem_wd),
		.read_address(mem_ra),
		.read_data(mem_rd),
		.led(LED),
		.red(RGB_R),
		.green(RGB_G),
		.blue(RGB_B)
	);
endmodule
