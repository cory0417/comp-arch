module uart_clk (
    input  logic clk,
    input  logic reset_n,
    output logic baud_clk
);
  localparam logic [3:0] BaudRateDiv = 13;  // 24 MHz / (16 * 115200 Hz) ~= 13
  localparam logic [3:0] SampleOffset = 7;  // Sample offset from the falling edge of start bit
  // Since we are oversampling, we don't need to be very accurate about when we start the baud clock
  // being off by 1 or 2 ticks is acceptable for the starting off the baud clock detection

  logic [3:0] counter;
  logic did_reset;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      baud_clk  <= 0;
      counter   <= 0;
      did_reset <= 1;
    end else begin
      counter <= counter + 1;
      if (did_reset & counter == SampleOffset - 1) begin
        did_reset <= 0;
        counter   <= 0;
      end else if (counter == BaudRateDiv - 1) begin
        counter  <= 0;
        baud_clk <= ~baud_clk;  // Toggle baud clock
      end
    end
  end

endmodule
