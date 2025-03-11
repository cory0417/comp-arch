module memory #(
    parameter SINE_FILE = "",
    parameter int N_QUARTER_SAMPLES = 128
) (
    input logic clk,
    input logic [8:0] read_address,
    output logic [9:0] read_data
);
  typedef enum {
    LUT,
    MIRRORED,
    NEGATED,
    MIRRORED_NEGATED
  } sine_quarter_t;
  sine_quarter_t quarter;
  logic [$clog2(N_QUARTER_SAMPLES)-1:0] index;
  logic [9:0] sine_out;
  logic [8:0] sample_memory[N_QUARTER_SAMPLES];
  
  initial begin
    if (SINE_FILE != "") begin
      $readmemh(SINE_FILE, sample_memory);
    end
  end

  always_ff @(posedge clk) begin
    read_data <= sine_out;
  end


  always_comb begin
    quarter = sine_quarter_t'(read_address >> $clog2(N_QUARTER_SAMPLES));
    index   = read_address % N_QUARTER_SAMPLES;

    case (quarter)
      LUT: sine_out = 512 + sample_memory[index];
      MIRRORED: sine_out = 512 + sample_memory[N_QUARTER_SAMPLES-1-index];
      NEGATED: sine_out = 512 - sample_memory[index];
      MIRRORED_NEGATED: sine_out = 512 - sample_memory[N_QUARTER_SAMPLES-1-index];
      default: sine_out = 512;
    endcase
  end
endmodule

