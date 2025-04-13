`timescale 1ns / 1ns

module register_file (
    input logic clk,
    input logic [4:0] a1,  // source register address 2
    input logic [4:0] a2,  // source register address 2
    input logic [4:0] a3,  // destination register address
    input logic [31:0] wd,  // write data
    input logic wen,  // write enable
    output logic [31:0] rd1,  // read data 1
    output logic [31:0] rd2  // read data 2
);

  logic [31:0] registers[32];
  logic [31:0] rd1_local, rd2_local;

  initial begin
    // Initialize registers to zero
    for (int i = 0; i < 32; i++) begin
      registers[i] = 32'b0;
    end
  end

  always_comb begin
    rd1_local = (a1 != 0) ? registers[a1] : 32'b0;
    rd2_local = (a2 != 0) ? registers[a2] : 32'b0;
  end

  always_ff @(posedge clk) begin
    if (wen && a3 != 5'd0) begin
      registers[a3] <= wd;
    end
  end

  assign rd1 = rd1_local;
  assign rd2 = rd2_local;
endmodule
