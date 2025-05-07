module uart_rx (
    input logic clk,
    input logic reset_n,
    input logic rx,
    input logic rx_data_ack,
    output logic [7:0] rx_data,
    output logic rx_data_ready
);

  // 115200 baud at 12 MHz (12 MHz / 115200 baud ~= 104.17)
  localparam logic [6:0] TicksPerBaud = 104;
  localparam logic [6:0] OffsetTicks = 52;

  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } rx_state_t;
  rx_state_t       rx_state;


  logic      [6:0] baud_counter;
  logic      [2:0] data_bit_counter;

  // Debouncing logic
  logic      [2:0] rx_shift_reg;  // 3-bit shift register for majority voting
  logic            rx_debounced;  // Debounced rx signal

  assign rx_debounced = (rx_shift_reg[0] & rx_shift_reg[1]) |
                       (rx_shift_reg[1] & rx_shift_reg[2]) |
                       (rx_shift_reg[0] & rx_shift_reg[2]);

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_shift_reg <= 3'b111;  // Initialize to idle state
      rx_data <= 8'h00;
      rx_state <= IDLE;
      data_bit_counter <= 0;
      rx_data_ready <= 0;
      baud_counter <= 0;
    end else begin
      // Update shift register
      rx_shift_reg <= {rx_shift_reg[1:0], rx};
      if (rx_data_ack) begin
        rx_data_ready <= 0;
        rx_data <= 8'h00;
        baud_counter <= 0;
      end else begin
        case (rx_state)
          IDLE: begin
            rx_data_ready <= 0;
            if (~rx_debounced) begin
              baud_counter <= baud_counter + 1;
              if (baud_counter == OffsetTicks - 1) begin
                rx_state <= START;
                baud_counter <= 0;
              end
            end else begin
              baud_counter <= 0;
            end
          end
          START: begin
            if (baud_counter == TicksPerBaud - 1) begin
              rx_state <= DATA;
              data_bit_counter <= 0;
              baud_counter <= 0;
            end else begin
              baud_counter <= baud_counter + 1;
            end
          end
          DATA: begin
            if (baud_counter == 0) begin
              rx_data <= {rx_debounced, rx_data[7:1]};  // shift in data bits (LSB first)
              baud_counter <= baud_counter + 1;
            end else if (baud_counter == TicksPerBaud - 1) begin
              data_bit_counter <= data_bit_counter + 1;
              if (data_bit_counter == 7) begin
                rx_state <= STOP;
              end
              baud_counter <= 0;
            end else begin
              baud_counter <= baud_counter + 1;
            end
          end
          STOP: begin
            if (rx_debounced) begin  // stop bit detected
              rx_state <= IDLE;
              rx_data_ready <= 1;
            end else begin  // error detected (stop bit not asserted)
              rx_state <= IDLE;
              rx_data_ready <= 0;
              rx_data <= 8'h00;
            end
          end
          default: rx_state <= IDLE;
        endcase
      end
    end
  end

endmodule
