module top (
	LED,
	RGB_R,
	RGB_G,
	RGB_B,
	_20a,
	_18a
);
	parameter INIT_FILE = "/Users/dkim/projects/comp-arch/risc-v/prog/build/blink";
	output wire LED;
	output wire RGB_R;
	output wire RGB_G;
	output wire RGB_B;
	output wire _20a;
	input wire _18a;
	wire clk;
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
		.PLLOUTCORE(clk),
		.BYPASS(1'b0),
		.RESETB(1'b1)
	);
	wire cpu_reset_n;
	wire [31:0] mem_ra;
	wire [31:0] mem_wa;
	wire [31:0] mem_rd;
	wire [31:0] mem_wd;
	wire mem_wen;
	wire [2:0] mem_funct3;
	reg did_boot;
	reg reset_counter;
	initial did_boot = 0;
	initial reset_counter = 0;
	wire rx_fifo_full;
	always @(posedge clk) begin
		did_boot <= 1;
		if (!did_boot)
			reset_counter <= 1;
		else
			reset_counter <= 0;
	end
	wire boot_reset_n;
	assign boot_reset_n = ~reset_counter;
	assign cpu_reset_n = ~rx_fifo_full & boot_reset_n;
	risc_v u_risc_v(
		.clk(clk),
		.reset_n(cpu_reset_n),
		.mem_wen(mem_wen),
		.mem_ra(mem_ra),
		.mem_wa(mem_wa),
		.mem_wd(mem_wd),
		.mem_rd(mem_rd),
		.mem_funct3(mem_funct3)
	);
	wire [31:0] mem_wd_mux;
	wire [31:0] mem_wa_mux;
	wire mem_wen_mux;
	wire [2:0] mem_funct3_mux;
	wire uart_reset_n;
	reg rx_fifo_full_ack;
	wire rx_fifo_wen;
	wire [7:0] rx_fifo_wd;
	wire [8:0] rx_fifo_wa;
	wire [7:0] instr_mem_reinit_data;
	wire [8:0] rx_fifo_addr;
	reg [8:0] instr_mem_reinit_addr;
	reg [8:0] buffered_instr_mem_reinit_addr;
	reg mem_wen_reinit;
	reg use_uart_data = rx_fifo_full;
	assign mem_wd_mux = (use_uart_data ? {24'b000000000000000000000000, instr_mem_reinit_data} : mem_wd);
	assign mem_wa_mux = (use_uart_data ? {23'b00000000000000000000000, buffered_instr_mem_reinit_addr} : mem_wa);
	assign mem_wen_mux = (use_uart_data ? mem_wen_reinit : mem_wen);
	assign mem_funct3_mux = (use_uart_data ? 3'b000 : mem_funct3);
	memory #(.INIT_FILE(INIT_FILE)) u_memory(
		.clk(clk),
		.write_mem(mem_wen_mux),
		.funct3(mem_funct3_mux),
		.write_address(mem_wa_mux),
		.write_data(mem_wd_mux),
		.read_address(mem_ra),
		.read_data(mem_rd),
		.led(LED),
		.red(RGB_R),
		.green(RGB_G),
		.blue(RGB_B)
	);
	wire internal_rx = _18a;
	uart u_uart(
		.clk(clk),
		.reset_n(uart_reset_n),
		.rx_fifo_full_ack(rx_fifo_full_ack),
		.rx(internal_rx),
		.tx(_20a),
		.rx_fifo_wd(rx_fifo_wd),
		.rx_fifo_wa(rx_fifo_wa),
		.rx_fifo_wen(rx_fifo_wen),
		.rx_fifo_full(rx_fifo_full)
	);
	uart_fifo u_uart_rx_fifo(
		.clk(clk),
		.wd(rx_fifo_wd),
		.addr(rx_fifo_addr),
		.wen(rx_fifo_wen),
		.rd(instr_mem_reinit_data)
	);
	reg rx_fifo_addr_sel;
	assign rx_fifo_addr = (rx_fifo_addr_sel ? instr_mem_reinit_addr : rx_fifo_wa);
	always @(posedge clk)
		if (rx_fifo_full) begin
			mem_wen_reinit <= 1;
			buffered_instr_mem_reinit_addr <= instr_mem_reinit_addr;
			instr_mem_reinit_addr <= instr_mem_reinit_addr + 1;
			rx_fifo_full_ack <= instr_mem_reinit_addr == 511;
			rx_fifo_addr_sel <= 1'b1;
		end
		else begin
			instr_mem_reinit_addr <= 0;
			buffered_instr_mem_reinit_addr <= 0;
			mem_wen_reinit <= 0;
			rx_fifo_full_ack <= 0;
			rx_fifo_addr_sel <= 1'b0;
		end
endmodule
