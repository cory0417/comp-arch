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
	reg [2:0] oversample_counter;
	localparam [2:0] SampleOffset = 4;
	localparam [2:0] OversampleRate = 7;
	always @(posedge clk or negedge reset_n)
		if (!reset_n) begin
			rx_data <= 8'h00;
			rx_state <= 2'd0;
			data_bit_counter <= 0;
			oversample_counter <= 0;
			rx_data_ready <= 0;
		end
		else if (rx_data_ack) begin
			rx_data_ready <= 0;
			rx_data <= 8'h00;
		end
		else
			case (rx_state)
				2'd0: begin
					rx_data_ready <= 0;
					if (~rx) begin
						rx_state <= 2'd1;
						oversample_counter <= oversample_counter + 1;
						if (oversample_counter == (SampleOffset - 1))
							oversample_counter <= 0;
					end
					else
						oversample_counter <= 0;
				end
				2'd1: begin
					oversample_counter <= oversample_counter + 1;
					if (oversample_counter == (SampleOffset - 1)) begin
						oversample_counter <= 0;
						rx_state <= 2'd2;
						data_bit_counter <= 0;
					end
				end
				2'd2: begin
					oversample_counter <= oversample_counter + 1;
					if (oversample_counter == OversampleRate) begin
						data_bit_counter <= data_bit_counter + 1;
						rx_data <= {rx, rx_data[7:1]};
						if (data_bit_counter == 7)
							rx_state <= 2'd3;
					end
				end
				2'd3: begin
					oversample_counter <= oversample_counter + 1;
					if (oversample_counter == OversampleRate) begin
						if (rx) begin
							rx_state <= 2'd0;
							rx_data_ready <= 1;
						end
						else begin
							rx_state <= 2'd0;
							rx_data <= 8'h00;
							oversample_counter <= 0;
						end
					end
				end
				default: rx_state <= 2'd0;
			endcase
endmodule
