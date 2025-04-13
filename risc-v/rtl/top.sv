module top #(
    parameter string INIT_FILE = ""
) (
    input  logic clk,
    output logic LED,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);

  logic [31:0] mem_ra, mem_wa, mem_rd, mem_wd;
  logic mem_wen;
  logic [2:0] mem_funct3;

  risc_v u_risc_v (
      .clk(clk),
      .mem_wen(mem_wen),
      .mem_ra(mem_ra),
      .mem_wa(mem_wa),
      .mem_wd(mem_wd),
      .mem_rd(mem_rd),
      .mem_funct3(mem_funct3)
  );

  memory #(
      .INIT_FILE(INIT_FILE)
  ) u_memory (
      .clk(clk),
      .write_mem(mem_wen),
      .funct3(mem_funct3),
      .write_address(mem_wa),
      .write_data(mem_wd),
      .read_address(mem_ra),
      .read_data(mem_rd),
      .led(LED),
      .red(RGB_R),
      .green(RGB_G),
      .blue(RGB_B)
  );
endmodule
