module top #(
    parameter int unsigned TRANSITION_INTERVAL = 12000000
) (
    input  logic clk,
    output logic LED,
    output logic RGB_B,
    output logic RGB_G,
    output logic RGB_R
);
  localparam logic [2:0] RED = 3'b001;
  localparam logic [2:0] GREEN = 3'b010;
  localparam logic [2:0] BLUE = 3'b100;

  logic [$clog2(TRANSITION_INTERVAL) - 1:0] count = 0;
  logic [2:0] bgr = RED;
  logic [2:0] color = RED;
  logic is_mixing = 1'b0;

  always_ff @(posedge clk) begin
    if (count == (TRANSITION_INTERVAL - 1)) begin
      count <= 0;
      is_mixing <= ~is_mixing;
      if (~is_mixing) begin
        color <= color | ((bgr == BLUE) ? RED : (bgr << 1));
      end else begin
        color <= color ^ bgr;
        bgr   <= (bgr == BLUE) ? RED : (bgr << 1);
      end
    end else count <= count + 1;
  end

  always_comb begin
    LED   = 1'b1;
    RGB_B = |(color & BLUE);
    RGB_G = |(color & GREEN);
    RGB_R = |(color & RED);
  end

endmodule
