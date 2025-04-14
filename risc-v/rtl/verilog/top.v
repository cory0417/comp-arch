module top (
	LED,
	RGB_R,
	RGB_G,
	RGB_B
);
	parameter INIT_FILE = "@INIT_FILE@";
	output wire LED;
	output wire RGB_R;
	output wire RGB_G;
	output wire RGB_B;
	wire clk_12mhz;
	wire clk_48mhz;
	SB_HFOSC #(.CLKHF_DIV("0b00")) hfosc_inst(
		.CLKHFEN(1'b1),
		.CLKHFPU(1'b1),
		.CLKHF(clk_48mhz)
	);
	SB_PLL40_CORE #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'd3),
		.DIVF(7'd63),
		.DIVQ(3'd6),
		.FILTER_RANGE(3'd1)
	) pll_inst(
		.REFERENCECLK(clk_48mhz),
		.PLLOUTCORE(clk_12mhz),
		.BYPASS(1'b0),
		.RESETB(1'b1)
	);
	wire [31:0] mem_ra;
	wire [31:0] mem_wa;
	wire [31:0] mem_rd;
	wire [31:0] mem_wd;
	wire mem_wen;
	wire [2:0] mem_funct3;
	risc_v u_risc_v(
		.clk(clk_12mhz),
		.mem_wen(mem_wen),
		.mem_ra(mem_ra),
		.mem_wa(mem_wa),
		.mem_wd(mem_wd),
		.mem_rd(mem_rd),
		.mem_funct3(mem_funct3)
	);
	memory #(.INIT_FILE(INIT_FILE)) u_memory(
		.clk(clk_12mhz),
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
