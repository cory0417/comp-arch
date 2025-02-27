module top #(
    parameter int TRANSITION_INTERVAL = 2_000_000  // 6 state changes per 12e6 clock ticks
) (
    input  logic clk,
    output logic LED,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);
  localparam int BITS = 7;
  localparam int PwmThresholdUpdateInterval = TRANSITION_INTERVAL >> BITS;
  // 2-bits grouped together for total of 6 states
  localparam logic [11:0] ThresholdDeltaSeq = 12'b00_01_00_00_10_00;
  logic [BITS-1:0] red_pwm_threshold, green_pwm_threshold, blue_pwm_threshold;
  logic [1:0] red_threshold_delta, green_threshold_delta, blue_threshold_delta;
  logic [2:0] red_threshold_state, green_threshold_state, blue_threshold_state;

  // Set intial states
  initial begin
    LED = 1;
    red_threshold_state = 0;
    green_threshold_state = 4;
    blue_threshold_state = 2;
    red_pwm_threshold = (1 << BITS) - 1;
    green_pwm_threshold = 0;
    blue_pwm_threshold = 0;
  end

  // Top-level counter for clock ticks
  logic [$clog2(TRANSITION_INTERVAL)-1:0] count = 0;
  always_ff @(posedge clk) begin
    if (count == TRANSITION_INTERVAL - 1) count <= 0;
    else count <= count + 1;
  end

  // Transition for fade direction of the PWM
  always_ff @(posedge clk) begin
    if (count == TRANSITION_INTERVAL - 1) begin
      red_threshold_state   <= (red_threshold_state + 1) % 6;
      green_threshold_state <= (green_threshold_state + 1) % 6;
      blue_threshold_state  <= (blue_threshold_state + 1) % 6;
    end
  end

  always_comb begin
    red_threshold_delta   = ThresholdDeltaSeq[(red_threshold_state*2)+:2];
    green_threshold_delta = ThresholdDeltaSeq[(green_threshold_state*2)+:2];
    blue_threshold_delta  = ThresholdDeltaSeq[(blue_threshold_state*2)+:2];
  end

  // Update the threshold values
  logic [$clog2(PwmThresholdUpdateInterval)-1:0] pwm_threshold_update_counter = 0;
  always_ff @(posedge clk) begin
    pwm_threshold_update_counter <= pwm_threshold_update_counter + 1;
    if (pwm_threshold_update_counter == (PwmThresholdUpdateInterval - 1)) begin
      case (red_threshold_delta)
        2: red_pwm_threshold <= red_pwm_threshold - 1;
        0: red_pwm_threshold <= red_pwm_threshold;
        1: red_pwm_threshold <= red_pwm_threshold + 1;
        default: red_pwm_threshold <= red_pwm_threshold;
      endcase
      case (green_threshold_delta)
        2: green_pwm_threshold <= green_pwm_threshold - 1;
        0: green_pwm_threshold <= green_pwm_threshold;
        1: green_pwm_threshold <= green_pwm_threshold + 1;
        default: green_pwm_threshold <= green_pwm_threshold;
      endcase
      case (blue_threshold_delta)
        2: blue_pwm_threshold <= blue_pwm_threshold - 1;
        0: blue_pwm_threshold <= blue_pwm_threshold;
        1: blue_pwm_threshold <= blue_pwm_threshold + 1;
        default: blue_pwm_threshold <= blue_pwm_threshold;
      endcase
    end
  end


  pwm_timer #(
      .BITS(BITS)
  ) red_pwm (
      .clk(clk),
      .pwm_pulse(RGB_R),
      .threshold(red_pwm_threshold)
  );
  pwm_timer #(
      .BITS(BITS)
  ) green_pwm (
      .clk(clk),
      .pwm_pulse(RGB_G),
      .threshold(green_pwm_threshold)
  );
  pwm_timer #(
      .BITS(BITS)
  ) blue_pwm (
      .clk(clk),
      .pwm_pulse(RGB_B),
      .threshold(blue_pwm_threshold)
  );

endmodule
