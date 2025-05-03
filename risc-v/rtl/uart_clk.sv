module uart_clk (
    input  logic clk,
    input  logic reset_n,
    output logic out_clk
);
  localparam logic [3:0] OversampleDiv = 13;  // 24 MHz / (8 * 115200 Hz) / 2 ~= 13

  logic [3:0] counter;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      out_clk <= 0;
      counter <= 0;
    end else begin
      counter <= counter + 1;
      if (counter == OversampleDiv - 1) begin
        counter <= 0;
        out_clk <= ~out_clk;  // Toggle baud clock
      end
    end
  end

endmodule
