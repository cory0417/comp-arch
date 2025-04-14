module top #(
    parameter string INIT_FILE = "@INIT_FILE@"  // Replaced by Makefile
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
    output logic RGB_B
);

`ifndef COCOTB_SIM  // Hard IP doesn't work in cocotb simulation
  logic clk_12mhz, clk_48mhz;
  SB_HFOSC #(
      .CLKHF_DIV("0b00")  // 48 MHz; 0b00 = 48 MHz, 0b01 = 24 MHz, 0b10 = 12 MHz, 0b11 = 6 MHz
  ) hfosc_inst (
      .CLKHFEN(1'b1),
      .CLKHFPU(1'b1),
      .CLKHF  (clk_48mhz)
  );
  SB_PLL40_CORE #(
      .FEEDBACK_PATH("SIMPLE"),
      .DIVR         (4'd3),      // Divide by (3+1); 0,1,2,…,15
      .DIVF         (7'd63),     // Multiply by (63+1); 0,1,..,63
      .DIVQ         (3'd6),      // Divide by (2^6=64) => 12 MHz; 1,2,…,6
      .FILTER_RANGE (3'd1)
  ) pll_inst (
      .REFERENCECLK(clk_48mhz),
      .PLLOUTCORE(clk_12mhz),
      .BYPASS(1'b0),
      .RESETB(1'b1)
  );
`else
  logic clk;
`endif
`ifdef DEBUG
  // For debugging
  assign _39a = clk_12mhz;
  always_ff @(posedge clk_12mhz) begin
    _31b <= LED;
    _29b <= RGB_R;
    _37a <= RGB_G;
    _36b <= RGB_B;
  end
`endif

  logic [31:0] mem_ra, mem_wa, mem_rd, mem_wd;
  logic mem_wen;
  logic [2:0] mem_funct3;

  risc_v u_risc_v (
`ifdef COCOTB_SIM
      .clk(clk),
`else
      .clk(clk_12mhz),
`endif
      .mem_wen(mem_wen),
      .mem_ra(mem_ra),
      .mem_wa(mem_wa),
      .mem_wd(mem_wd),
      .mem_rd(mem_rd),
      .mem_funct3(mem_funct3)
  );

  memory #(
      .INIT_FILE(INIT_FILE)
  ) u_memory (
`ifdef COCOTB_SIM
      .clk(clk),
`else
      .clk(clk_12mhz),
`endif
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
