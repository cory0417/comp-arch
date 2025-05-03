module uart_rx (
    input logic clk,
    input logic reset_n,
    input logic rx,
    input logic rx_data_ack,
    output logic [7:0] rx_data,
    output logic rx_data_ready
);
  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } rx_state_t;

  rx_state_t rx_state;

  logic [2:0] data_bit_counter;
  logic [2:0] oversample_counter;
  localparam logic [2:0] SampleOffset = 4;  // Offset for oversampling
  localparam logic [2:0] OversampleRate = 7;  // Oversampling rate

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_data <= 8'h00;
      rx_state <= IDLE;
      data_bit_counter <= 0;
      oversample_counter <= 0;
      rx_data_ready <= 0;
    end else if (rx_data_ack) begin
      rx_data_ready <= 0;
      rx_data <= 8'h00;
    end else begin
      case (rx_state)
        IDLE: begin
          rx_data_ready <= 0;
          oversample_counter <= 0;  // reset counter if start bit not detected
          if (~rx) begin
            rx_state <= START;
          end
        end
        START: begin
          oversample_counter <= oversample_counter + 1;
          if (oversample_counter == SampleOffset - 1) begin
            oversample_counter <= 0;
            rx_state <= DATA;
            data_bit_counter <= 0;
          end
        end
        DATA: begin
          oversample_counter <= oversample_counter + 1;
          if (oversample_counter == OversampleRate) begin
            data_bit_counter <= data_bit_counter + 1;
            rx_data <= {rx, rx_data[7:1]};  // shift in data bits (LSB first)
            if (data_bit_counter == 7) begin
              rx_state <= STOP;
            end
          end
        end
        STOP: begin
          oversample_counter <= oversample_counter + 1;
          if (oversample_counter == OversampleRate) begin
            if (rx) begin  // stop bit detected
              rx_state <= IDLE;
              rx_data_ready <= 1;
            end else begin  // error detected (stop bit not asserted)
              rx_state <= IDLE;
              rx_data <= 8'h00;  // clear data
              oversample_counter <= 0;
            end
          end
        end
        default: rx_state <= IDLE;
      endcase
    end
  end


endmodule
