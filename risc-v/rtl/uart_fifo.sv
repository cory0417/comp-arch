// Adaptation of inferred BRAM Verilog in the "Memory Usage Guide for iCE40 Devices"

module uart_fifo #(
    parameter int ADDR_WIDTH = 9,  // 512 addresses
    parameter int DATA_WIDTH = 8   // 8 bits
) (
    input logic clk,
    input logic [DATA_WIDTH-1:0] wd,
    input [ADDR_WIDTH-1:0] addr,
    input logic wen,
    output logic [DATA_WIDTH-1:0] rd
);

  logic [DATA_WIDTH-1:0] mem[1<<ADDR_WIDTH];

  always_ff @(posedge clk) begin
    if (wen) mem[(addr)] <= wd;
    rd <= mem[addr];
  end
endmodule
