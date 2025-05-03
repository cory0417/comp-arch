module memory (
	clk,
	write_mem,
	funct3,
	write_address,
	write_data,
	read_address,
	read_data,
	led,
	red,
	green,
	blue
);
	reg _sv2v_0;
	parameter INIT_FILE = "";
	input wire clk;
	input wire write_mem;
	input wire [2:0] funct3;
	input wire [31:0] write_address;
	input wire [31:0] write_data;
	input wire [31:0] read_address;
	output reg [31:0] read_data;
	output wire led;
	output wire red;
	output wire green;
	output wire blue;
	reg [31:0] read_value = 32'd0;
	reg [31:0] leds = 32'd0;
	reg [31:0] millis = 32'd0;
	reg [31:0] micros = 32'd0;
	reg [7:0] pwm_counter = 8'd0;
	reg [13:0] millis_counter = 14'd0;
	reg [3:0] micros_counter = 4'd0;
	reg read_address0;
	reg read_address1;
	reg read_word;
	reg read_half;
	reg read_unsigned;
	wire [15:0] read_value10;
	wire [15:0] read_value32;
	wire [7:0] read_value0;
	wire [7:0] read_value1;
	wire [7:0] read_value2;
	wire [7:0] read_value3;
	wire sign_bit0;
	wire sign_bit1;
	wire sign_bit2;
	wire sign_bit3;
	wire [31:0] read_val;
	wire write_address0;
	wire write_address1;
	wire write_word;
	wire write_half;
	wire [7:0] write_data0;
	wire [7:0] write_data1;
	wire [7:0] write_data2;
	wire [7:0] write_data3;
	wire mem_write_enable;
	reg mem_write_enable0;
	reg mem_write_enable1;
	reg mem_write_enable2;
	reg mem_write_enable3;
	reg [7:0] mem_write_data0;
	reg [7:0] mem_write_data1;
	reg [7:0] mem_write_data2;
	reg [7:0] mem_write_data3;
	reg mem_read_enable;
	wire [7:0] mem_read_data0;
	wire [7:0] mem_read_data1;
	wire [7:0] mem_read_data2;
	wire [7:0] mem_read_data3;
	memory_array #(.INIT_FILE((INIT_FILE != "" ? $sformatf("%s0.txt", INIT_FILE) : ""))) mem0(
		.clk(clk),
		.write_enable(mem_write_enable0),
		.write_address(write_address[12:2]),
		.write_data(mem_write_data0),
		.read_address(read_address[12:2]),
		.read_data(mem_read_data0)
	);
	memory_array #(.INIT_FILE((INIT_FILE != "" ? $sformatf("%s0.txt", INIT_FILE) : ""))) mem1(
		.clk(clk),
		.write_enable(mem_write_enable1),
		.write_address(write_address[12:2]),
		.write_data(mem_write_data1),
		.read_address(read_address[12:2]),
		.read_data(mem_read_data1)
	);
	memory_array #(.INIT_FILE((INIT_FILE != "" ? $sformatf("%s0.txt", INIT_FILE) : ""))) mem2(
		.clk(clk),
		.write_enable(mem_write_enable2),
		.write_address(write_address[12:2]),
		.write_data(mem_write_data2),
		.read_address(read_address[12:2]),
		.read_data(mem_read_data2)
	);
	memory_array #(.INIT_FILE((INIT_FILE != "" ? $sformatf("%s0.txt", INIT_FILE) : ""))) mem3(
		.clk(clk),
		.write_enable(mem_write_enable3),
		.write_address(write_address[12:2]),
		.write_data(mem_write_data3),
		.read_address(read_address[12:2]),
		.read_data(mem_read_data3)
	);
	wire is_mem_read;
	assign is_mem_read = read_address[31:13] == 19'd0;
	initial mem_read_enable = 1'b1;
	always @(posedge clk) mem_read_enable <= is_mem_read;
	assign read_val = (mem_read_enable ? {mem_read_data3, mem_read_data2, mem_read_data1, mem_read_data0} : read_value);
	always @(posedge clk) begin
		read_address1 <= read_address[1];
		read_address0 <= read_address[0];
		read_word <= funct3[1];
		read_half <= funct3[0];
		read_unsigned <= funct3[2];
		if (read_address[31:13] == 19'h7ffff)
			case (read_address[12:2])
				11'h7ff: read_value <= leds;
				11'h7fe: read_value <= millis;
				11'h7fd: read_value <= micros;
				default: read_value <= 32'd0;
			endcase
		else
			read_value <= 32'd0;
	end
	assign read_value10 = read_val[15:0];
	assign read_value32 = read_val[31:16];
	assign read_value0 = read_val[7:0];
	assign read_value1 = read_val[15:8];
	assign read_value2 = read_val[23:16];
	assign read_value3 = read_val[31:24];
	assign sign_bit0 = read_val[7];
	assign sign_bit1 = read_val[15];
	assign sign_bit2 = read_val[23];
	assign sign_bit3 = read_val[31];
	always @(*) begin
		if (_sv2v_0)
			;
		if (read_word)
			read_data = read_val;
		else if (read_half && !read_unsigned)
			read_data = (read_address1 ? {{16 {sign_bit3}}, read_value32} : {{16 {sign_bit1}}, read_value10});
		else if (read_half && read_unsigned)
			read_data = (read_address1 ? {16'd0, read_value32} : {16'd0, read_value10});
		else if (!read_half && !read_unsigned)
			case ({read_address1, read_address0})
				2'b00: read_data = {{24 {sign_bit0}}, read_value0};
				2'b01: read_data = {{24 {sign_bit1}}, read_value1};
				2'b10: read_data = {{24 {sign_bit2}}, read_value2};
				2'b11: read_data = {{24 {sign_bit3}}, read_value3};
			endcase
		else
			case ({read_address1, read_address0})
				2'b00: read_data = {24'd0, read_value0};
				2'b01: read_data = {24'd0, read_value1};
				2'b10: read_data = {24'd0, read_value2};
				2'b11: read_data = {24'd0, read_value3};
			endcase
	end
	assign mem_write_enable = (write_address[31:13] == 19'd0) & write_mem;
	assign write_address0 = write_address[0];
	assign write_address1 = write_address[1];
	assign write_word = funct3[1];
	assign write_half = funct3[0];
	assign write_data0 = write_data[7:0];
	assign write_data1 = write_data[15:8];
	assign write_data2 = write_data[23:16];
	assign write_data3 = write_data[31:24];
	always @(*) begin
		if (_sv2v_0)
			;
		if (write_word) begin
			mem_write_enable0 = mem_write_enable;
			mem_write_enable1 = mem_write_enable;
			mem_write_enable2 = mem_write_enable;
			mem_write_enable3 = mem_write_enable;
			mem_write_data0 = write_data0;
			mem_write_data1 = write_data1;
			mem_write_data2 = write_data2;
			mem_write_data3 = write_data3;
		end
		else if (write_half & ~write_address1) begin
			mem_write_enable0 = mem_write_enable;
			mem_write_enable1 = mem_write_enable;
			mem_write_enable2 = 1'b0;
			mem_write_enable3 = 1'b0;
			mem_write_data0 = write_data0;
			mem_write_data1 = write_data1;
			mem_write_data2 = 8'd0;
			mem_write_data3 = 8'd0;
		end
		else if (write_half & write_address1) begin
			mem_write_enable0 = 1'b0;
			mem_write_enable1 = 1'b0;
			mem_write_enable2 = mem_write_enable;
			mem_write_enable3 = mem_write_enable;
			mem_write_data0 = 8'd0;
			mem_write_data1 = 8'd0;
			mem_write_data2 = write_data0;
			mem_write_data3 = write_data1;
		end
		else
			case ({write_address1, write_address0})
				2'b00: begin
					mem_write_enable0 = mem_write_enable;
					mem_write_enable1 = 1'b0;
					mem_write_enable2 = 1'b0;
					mem_write_enable3 = 1'b0;
					mem_write_data0 = write_data0;
					mem_write_data1 = 8'd0;
					mem_write_data2 = 8'd0;
					mem_write_data3 = 8'd0;
				end
				2'b01: begin
					mem_write_enable0 = 1'b0;
					mem_write_enable1 = mem_write_enable;
					mem_write_enable2 = 1'b0;
					mem_write_enable3 = 1'b0;
					mem_write_data0 = 8'd0;
					mem_write_data1 = write_data0;
					mem_write_data2 = 8'd0;
					mem_write_data3 = 8'd0;
				end
				2'b10: begin
					mem_write_enable0 = 1'b0;
					mem_write_enable1 = 1'b0;
					mem_write_enable2 = mem_write_enable;
					mem_write_enable3 = 1'b0;
					mem_write_data0 = 8'd0;
					mem_write_data1 = 8'd0;
					mem_write_data2 = write_data0;
					mem_write_data3 = 8'd0;
				end
				2'b11: begin
					mem_write_enable0 = 1'b0;
					mem_write_enable1 = 1'b0;
					mem_write_enable2 = 1'b0;
					mem_write_enable3 = mem_write_enable;
					mem_write_data0 = 8'd0;
					mem_write_data1 = 8'd0;
					mem_write_data2 = 8'd0;
					mem_write_data3 = write_data0;
				end
			endcase
	end
	always @(posedge clk)
		if (write_mem) begin
			if (write_address[31:2] == 30'h3fffffff) begin
				if (funct3[1])
					leds <= write_data;
				else if (funct3[0]) begin
					if (write_address[1])
						leds[31:16] <= write_data[15:0];
					else
						leds[15:0] <= write_data[15:0];
				end
				else
					case (write_address[1:0])
						2'b00: leds[7:0] <= write_data[7:0];
						2'b01: leds[15:8] <= write_data[7:0];
						2'b10: leds[23:16] <= write_data[7:0];
						2'b11: leds[31:24] <= write_data[7:0];
					endcase
			end
		end
	always @(posedge clk) pwm_counter <= pwm_counter + 1;
	assign led = pwm_counter < leds[31:24];
	assign red = pwm_counter < leds[23:16];
	assign green = pwm_counter < leds[15:8];
	assign blue = pwm_counter < leds[7:0];
	always @(posedge clk)
		if (millis_counter == 11999) begin
			millis_counter <= 14'd0;
			millis <= millis + 1;
		end
		else
			millis_counter <= millis_counter + 1;
	always @(posedge clk)
		if (micros_counter == 11) begin
			micros_counter <= 4'd0;
			micros <= micros + 1;
		end
		else
			micros_counter <= micros_counter + 1;
	initial _sv2v_0 = 0;
endmodule
