module uart (
    input logic clk,
    input logic reset_n,
    input logic rx_fifo_full_ack,
    input logic rx,  // mapped to physical pin
    output logic [7:0] rx_fifo_wd,
    output logic [8:0] rx_fifo_wa,
    output logic rx_fifo_wen,
    output logic rx_fifo_full
);

  // UART Rx
  logic rx_data_ready, rx_data_ack;
  logic [7:0] rx_data;

  uart_rx u_uart_rx (
      .clk(clk),
      .reset_n(reset_n),
      .rx(rx),
      .rx_data_ack(rx_data_ack),
      .rx_data(rx_data),
      .rx_data_ready(rx_data_ready)
  );

  // UART Rx FIFO
  typedef enum logic {
    IDLE,
    WRITE_FIFO
  } fifo_state_t;

  fifo_state_t rx_fifo_state;
  logic data_written;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_data_ack <= 0;
      rx_fifo_full <= 0;
      rx_fifo_wa <= 0;
      rx_fifo_wen <= 0;
      rx_fifo_wd <= 0;
      rx_fifo_state <= IDLE;
      data_written <= 0;
    end else if (rx_fifo_full_ack) begin
      rx_data_ack   <= 0;
      rx_fifo_full  <= 0;
      rx_fifo_wa    <= 0;
      rx_fifo_wen   <= 0;
      rx_fifo_wd    <= 0;
      rx_fifo_state <= IDLE;
      data_written  <= 0;
    end else begin
      case (rx_fifo_state)
        IDLE: begin
          rx_fifo_wen <= 0;
          if (rx_data_ready) begin
            rx_fifo_state <= WRITE_FIFO;
            rx_fifo_wd <= rx_data;
            rx_data_ack <= 1;
          end
        end
        WRITE_FIFO: begin
          rx_data_ack <= 0;
          if (!data_written) begin
            rx_fifo_wen  <= 1;
            data_written <= 1;
          end else begin
            rx_fifo_wen <= 0;
          end
          // Flag FIFO full
          if (rx_fifo_wa == 9'd511) rx_fifo_full <= 1;
          if (!rx_data_ready) begin
            rx_fifo_state <= IDLE;
            data_written  <= 0;
            rx_fifo_wa    <= rx_fifo_wa + 1;
          end
        end
        default: begin
          rx_data_ack   <= 0;
          rx_fifo_full  <= 0;
          rx_fifo_wa    <= 0;
          rx_fifo_wen   <= 0;
          rx_fifo_wd    <= 0;
          rx_fifo_state <= IDLE;
          data_written  <= 0;
        end
      endcase
    end
  end

endmodule
