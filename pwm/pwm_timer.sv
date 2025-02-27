module pwm_timer #(
    parameter int BITS = 7
) (
    input logic clk,
    input logic [BITS-1:0] threshold,
    output logic pwm_pulse
);
  logic [BITS-1:0] count = 0;
  always_ff @(posedge clk) begin
    count <= count + 1;
  end

  always_ff @(posedge clk) begin
    if (threshold == 0) pwm_pulse <= 1;
    else pwm_pulse <= (count > threshold);
  end
endmodule

