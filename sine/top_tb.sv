`timescale 10ns / 10ns

module top_tb;
  // Testbench Signals
  logic clk;
  logic [9:0] sine;
  always #4 clk = ~clk;  // Toggle clock every half period

  // Instantiate the DUT (Device Under Test)
  top uut (
      .clk (clk),
      ._9b (sine[0]),
      ._6a (sine[1]),
      ._4a (sine[2]),
      ._2a (sine[3]),
      ._0a (sine[4]),
      ._5a (sine[5]),
      ._3b (sine[6]),
      ._49a(sine[7]),
      ._45a(sine[8]),
      ._48b(sine[9])
  );

  // Monitor Output Changes
  initial begin
    $dumpfile("top_tb.vcd");  // Generate waveform file
    $dumpvars(0, top_tb);  // Dump all variables in scope
    $dumpvars(0, uut);  // Also dump all internal variables of the DUT

    clk = 0;
    #12288;  // Run for 512*3*8 clock ticks (3 periods with 512 samples)
    $finish;
  end
endmodule

