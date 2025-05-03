module register_file (
    input logic clk,
    input logic reset_n,
    input logic [4:0] a1,  // source register address 2
    input logic [4:0] a2,  // source register address 2
    input logic [4:0] a3,  // destination register address
    input logic [31:0] wd,  // write data
    input logic wen,  // write enable
    output logic [31:0] rd1,  // read data 1
    output logic [31:0] rd2  // read data 2
);

  logic [31:0] registers[32];
  initial begin
    // Initialize registers to zero
    for (int i = 0; i < 32; i++) begin
      registers[i] = 32'b0;
    end
  end

  assign rd1 = (a1 != 0) ? registers[a1] : 32'b0;
  assign rd2 = (a2 != 0) ? registers[a2] : 32'b0;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      for (int i = 0; i < 32; i++) begin
        registers[i] <= 32'b0;
      end
    end else if (wen && a3 != 5'd0) begin
      registers[a3] <= wd;
    end
  end
endmodule
