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
  logic reset_n;  // active low reset for simulation

  initial begin
    // Initialize registers to zero
    for (int i = 0; i < 32; i++) begin
      registers[i] = 32'b0;
    end
    reset_n = 1'b1;
  end

  always_ff @(posedge clk) begin
    if (wen) begin
      if (a3 != 0) registers[a3] <= wd;  // block writing to x0 (zero register)
    end
    if (~reset_n) begin
      for (int i = 0; i < 32; i++) begin
        registers[i] <= 32'b0;  // reset all registers to zero
      end
    end
  end

  assign rd1 = registers[a1];
  assign rd2 = registers[a2];

`ifdef COCOTB_SIM
  integer i;
  initial begin
    $dumpfile("register_file_tb.vcd");
    $dumpvars(0, register_file);
    for (i = 0; i < 32; i = i + 1) begin
      $dumpvars(0, registers[i]);
    end
  end
`endif

endmodule
