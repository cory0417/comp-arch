module uart_rx (
	clk,
	reset_n,
	rx,
	rx_data_ack,
	rx_data,
	rx_data_ready
);
	input wire clk;
	input wire reset_n;
	input wire rx;
	input wire rx_data_ack;
	output reg [7:0] rx_data;
	output reg rx_data_ready;
	reg [1:0] rx_state;
	reg [2:0] data_bit_counter;
	wire [2:0] oversample_counter;
	localparam [2:0] SampleOffset = 4;
	localparam [2:0] OversampleRate = 7;
	localparam [6:0] TicksPerBaud = 104;
	localparam [6:0] OffsetTicks = 52;
	reg [$clog2(7'd104) - 1:0] baud_counter;
	reg [2:0] rx_shift_reg;
	wire rx_debounced;
	assign rx_debounced = ((rx_shift_reg[0] & rx_shift_reg[1]) | (rx_shift_reg[1] & rx_shift_reg[2])) | (rx_shift_reg[0] & rx_shift_reg[2]);
	always @(posedge clk or negedge reset_n)
		if (!reset_n) begin
			rx_shift_reg <= 3'b111;
			rx_data <= 8'h00;
			rx_state <= 2'd0;
			data_bit_counter <= 0;
			rx_data_ready <= 0;
			baud_counter <= 0;
		end
		else begin
			rx_shift_reg <= {rx_shift_reg[1:0], rx};
			if (rx_data_ack) begin
				rx_data_ready <= 0;
				rx_data <= 8'h00;
				baud_counter <= 0;
			end
			else
				case (rx_state)
					2'd0: begin
						rx_data_ready <= 0;
						if (~rx_debounced) begin
							baud_counter <= baud_counter + 1;
							if (baud_counter == (OffsetTicks - 1)) begin
								rx_state <= 2'd1;
								baud_counter <= 0;
							end
						end
						else
							baud_counter <= 0;
					end
					2'd1:
						if (baud_counter == (TicksPerBaud - 1)) begin
							rx_state <= 2'd2;
							data_bit_counter <= 0;
							baud_counter <= 0;
						end
						else
							baud_counter <= baud_counter + 1;
					2'd2:
						if (baud_counter == 0) begin
							rx_data <= {rx_debounced, rx_data[7:1]};
							baud_counter <= baud_counter + 1;
						end
						else if (baud_counter == (TicksPerBaud - 1)) begin
							data_bit_counter <= data_bit_counter + 1;
							if (data_bit_counter == 7)
								rx_state <= 2'd3;
							baud_counter <= 0;
						end
						else
							baud_counter <= baud_counter + 1;
					2'd3:
						if (rx_debounced) begin
							rx_state <= 2'd0;
							rx_data_ready <= 1;
						end
						else begin
							rx_state <= 2'd0;
							rx_data_ready <= 0;
							rx_data <= 8'h00;
						end
					default: rx_state <= 2'd0;
				endcase
		end
endmodule
