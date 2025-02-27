`timescale 10ns / 10ns

module top_tb;
  // Testbench Signals
  logic clk;
  logic LED;
  logic RGB_R, RGB_G, RGB_B;

  // Clock Generation (12 MHz simulation)
  localparam int ClkPeriod = 8;  // 1 / 12MHz = 83.33ns ~= 80ns
  always #(ClkPeriod / 2) clk = ~clk;  // Toggle clock every half period

  // Instantiate the DUT (Device Under Test)
  top uut (
      .clk  (clk),
      .LED  (LED),
      .RGB_R(RGB_R),
      .RGB_G(RGB_G),
      .RGB_B(RGB_B)
  );

  // Monitor Output Changes
  initial begin
    $dumpfile("top_tb.vcd");  // Generate waveform file
    $dumpvars(0, top_tb);  // Dump all variables in scope
    $dumpvars(0, uut);  // Also dump all internal variables of the DUT

    // Initialize signals
    clk = 0;

    // Run simulation for a reasonable time
    #100_000_000;  // Run for 1 s
    $finish;  // Stop simulation
  end
endmodule
