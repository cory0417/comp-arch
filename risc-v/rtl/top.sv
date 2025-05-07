module top #(
    // verilog_lint: waive explicit-parameter-storage-type
    parameter INIT_FILE = "@INIT_FILE@"  // Replaced by Makefile
) (
`ifdef DEBUG
    output logic _31b,
    output logic _29b,
    output logic _37a,
    output logic _36b,
    output logic _39a,
`endif
    output logic LED,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B,
    // UART
    output logic _20a,  // UART TX
`ifdef COCOTB_SIM
    input logic rx  // Drive from cocotb
`else
    input logic _18a  // Physical pin
`endif
);

`ifndef COCOTB_SIM  // Hard IP doesn't work in cocotb simulation
  logic clk;
  SB_HFOSC #(
      .CLKHF_DIV("0b10")  // 48 MHz; 0b00 = 48 MHz, 0b01 = 24 MHz, 0b10 = 12 MHz, 0b11 = 6 MHz
  ) hfosc_inst (
      .CLKHFEN(1'b1),
      .CLKHFPU(1'b1),
      .CLKHF  (clk)
  );
  // SB_PLL40_CORE #(
  //     .FEEDBACK_PATH("SIMPLE"),
  //     .DIVR         (4'd0),      // Divide by (3+1); 0,1,2,…,15
  //     .DIVF         (7'd63),     // Multiply by (63+1); 0,1,..,63
  //     .DIVQ         (3'd5),      // Divide by (2^6=64) => 12 MHz; 1,2,…,6
  //     .FILTER_RANGE (3'd1)
  // ) pll_inst (
  //     .REFERENCECLK(clk),
  //     .PLLOUTCORE(clk_24mhz),
  //     .BYPASS(1'b0),
  //     .RESETB(1'b1)
  // );
`else
  logic clk;
`endif
`ifdef DEBUG
  logic rx_data_ready, rx_data_ack;
  // For debugging
  always_ff @(posedge clk) begin
    _31b <= LED;
    _29b <= RGB_R;  // rx_fifo_full;
    _37a <= RGB_G;  // rx_data_ready;
    _36b <= RGB_B;  // internal_rx_sync2;
  end
`endif

  /* CPU */
  logic cpu_reset_n;

  // CPU memory interface
  logic [31:0] mem_ra, mem_wa, mem_rd, mem_wd;
  logic mem_wen;
  logic [2:0] mem_funct3;

  logic did_boot;
  logic reset_counter;
  initial did_boot = 0;
  initial reset_counter = 0;
  logic rx_fifo_full;

  always_ff @(posedge clk) begin
    did_boot <= 1;
    if (!did_boot) begin
      reset_counter <= 1;
    end else reset_counter <= 0;
  end
  logic boot_reset_n;
  assign boot_reset_n = ~reset_counter;

  // Reset CPU when UART FIFO is full and reinitializing memory
  assign cpu_reset_n  = ~rx_fifo_full & boot_reset_n;
  risc_v u_risc_v (
      .clk(clk),
      .reset_n(cpu_reset_n),
      .mem_wen(mem_wen),
      .mem_ra(mem_ra),
      .mem_wa(mem_wa),
      .mem_wd(mem_wd),
      .mem_rd(mem_rd),
      .mem_funct3(mem_funct3)
  );

  // Muxes for memory write from UART or CPU
  logic [31:0] mem_wd_mux;
  logic [31:0] mem_wa_mux;
  logic mem_wen_mux;
  logic [2:0] mem_funct3_mux;

  logic uart_reset_n, rx_fifo_full_ack, rx_fifo_wen;
  logic [7:0] rx_fifo_wd;
  logic [8:0] rx_fifo_wa;
  logic [7:0] instr_mem_reinit_data;
  logic [8:0] rx_fifo_addr, instr_mem_reinit_addr, buffered_instr_mem_reinit_addr, mem_instr_addr;
  logic mem_wen_reinit;


  assign mem_wd_mux = (rx_fifo_full) ? {24'b0, instr_mem_reinit_data} : mem_wd;
  assign mem_wa_mux = (rx_fifo_full) ? {23'b0, mem_instr_addr} : mem_wa;
  assign mem_wen_mux = (rx_fifo_full) ? mem_wen_reinit : mem_wen;
  assign mem_funct3_mux = (rx_fifo_full) ? 3'b000 : mem_funct3;  // Store byte at a time

  memory #(
      .INIT_FILE(INIT_FILE)
  ) u_memory (
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
  logic internal_rx;
`ifdef COCOTB_SIM
  assign internal_rx = rx;
`else
  assign internal_rx = _18a;
`endif

  uart u_uart (
      .clk(clk),
      .reset_n(uart_reset_n & boot_reset_n),
      .rx_fifo_full_ack(rx_fifo_full_ack),
      .rx(internal_rx),
      .tx(_20a),
      .rx_fifo_wd(rx_fifo_wd),
      .rx_fifo_wa(rx_fifo_wa),
      .rx_fifo_wen(rx_fifo_wen),
      .rx_fifo_full(rx_fifo_full)
  );

  uart_fifo u_uart_rx_fifo (
      .clk (clk),
      .wd  (rx_fifo_wd),
      .addr(rx_fifo_addr),
      .wen (rx_fifo_wen),
      .rd  (instr_mem_reinit_data)
  );

  logic rx_fifo_addr_sel;
  assign rx_fifo_addr = (rx_fifo_addr_sel) ? instr_mem_reinit_addr : rx_fifo_wa;

  always_ff @(posedge clk) begin
    if (rx_fifo_full) begin
      mem_wen_reinit <= 1;
      mem_instr_addr <= buffered_instr_mem_reinit_addr;
      buffered_instr_mem_reinit_addr <= instr_mem_reinit_addr;
      instr_mem_reinit_addr <= instr_mem_reinit_addr + 1;
      if (instr_mem_reinit_addr == 511) begin
        rx_fifo_full_ack <= 1;
      end else begin
        rx_fifo_full_ack <= 0;
      end
      rx_fifo_addr_sel <= 1'b1;
    end else begin
      instr_mem_reinit_addr <= 0;
      rx_fifo_full_ack <= 0;
      mem_wen_reinit <= 0;
      buffered_instr_mem_reinit_addr <= 0;
      rx_fifo_addr_sel <= 1'b0;
      mem_instr_addr <= 0;
    end
  end

`ifdef COCOTB_SIM
  logic [1:0] uart_rx_state;
  logic [7:0] uart_rx_data;
  logic [31:0] registers[32];

  assign uart_rx_state = u_uart.u_uart_rx.rx_state;
  assign uart_rx_data = u_uart.rx_data;
  assign registers = u_risc_v.u_register_file.registers;
`endif
`ifdef DEBUG
  assign rx_data_ready = u_uart.rx_data_ready;
  assign rx_data_ack   = u_uart.rx_data_ack;
`endif

endmodule
