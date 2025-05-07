module uart (
	clk,
	reset_n,
	rx_fifo_full_ack,
	rx,
	tx,
	rx_fifo_wd,
	rx_fifo_wa,
	rx_fifo_wen,
	rx_fifo_full
);
	input wire clk;
	input wire reset_n;
	input wire rx_fifo_full_ack;
	input wire rx;
	output wire tx;
	output reg [7:0] rx_fifo_wd;
	output reg [8:0] rx_fifo_wa;
	output reg rx_fifo_wen;
	output reg rx_fifo_full;
	wire rx_data_ready;
	reg rx_data_ack;
	wire [7:0] rx_data;
	uart_rx u_uart_rx(
		.clk(clk),
		.reset_n(reset_n),
		.rx(rx),
		.rx_data_ack(rx_data_ack),
		.rx_data(rx_data),
		.rx_data_ready(rx_data_ready)
	);
	reg rx_fifo_state;
	reg data_written;
	always @(posedge clk or negedge reset_n)
		if (!reset_n) begin
			rx_data_ack <= 0;
			rx_fifo_full <= 0;
			rx_fifo_wa <= 0;
			rx_fifo_wen <= 0;
			rx_fifo_wd <= 0;
			rx_fifo_state <= 1'd0;
			data_written <= 0;
		end
		else if (rx_fifo_full_ack) begin
			rx_data_ack <= 0;
			rx_fifo_full <= 0;
			rx_fifo_wa <= 0;
			rx_fifo_wen <= 0;
			rx_fifo_wd <= 0;
			rx_fifo_state <= 1'd0;
			data_written <= 0;
		end
		else
			case (rx_fifo_state)
				1'd0: begin
					rx_fifo_wen <= 0;
					if (rx_data_ready) begin
						rx_fifo_state <= 1'd1;
						rx_fifo_wd <= rx_data;
						rx_data_ack <= 1;
					end
				end
				1'd1: begin
					rx_data_ack <= 0;
					if (!data_written) begin
						rx_fifo_wen <= 1;
						data_written <= 1;
					end
					else
						rx_fifo_wen <= 0;
					if (rx_fifo_wa == 9'd511)
						rx_fifo_full <= 1;
					if (!rx_data_ready) begin
						rx_fifo_state <= 1'd0;
						data_written <= 0;
						rx_fifo_wa <= rx_fifo_wa + 1;
					end
				end
				default: begin
					rx_data_ack <= 0;
					rx_fifo_full <= 0;
					rx_fifo_wa <= 0;
					rx_fifo_wen <= 0;
					rx_fifo_wd <= 0;
					rx_fifo_state <= 1'd0;
					data_written <= 0;
				end
			endcase
endmodule
