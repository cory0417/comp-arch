from pathlib import Path
import serial
from tb.utils import load_hex_from_txt

parent_dir = Path(__file__).parent


def uart_prog():
    """UART program to send data to the UART receiver."""
    serial_port = "/dev/tty.usbserial-AB9EUWNP"
    baud_rate = 115200
    timeout_sec = 1

    try:
        ser = serial.Serial(
            serial_port,
            baudrate=baud_rate,
            timeout=timeout_sec,
            parity="N",
            stopbits=1,
            bytesize=8,
        )
        assert ser.isOpen()
    except serial.SerialException as e:
        print(f"Failed to open serial port: {e}")
        return

    # Load program from hex file
    prog = load_hex_from_txt(parent_dir / "prog/build/blink.txt")

    if len(prog) > 128:
        print("Error: Program too large to fit in 512-byte UART image")
        ser.close()
        return

    # Flatten the 32-bit word list into a byte list (little endian)
    prog_bytes = []
    for word in prog:
        prog_bytes.extend(word.to_bytes(4, byteorder="little"))

    # Pad to 512 bytes
    prog_bytes += [0x00] * (512 - len(prog_bytes))
    assert len(prog_bytes) == 512

    print(f"Sending {len(prog_bytes)} bytes over UART...")

    for byte in prog_bytes:
        ser.write(byte.to_bytes(1, byteorder="big"))
        # time.sleep(0.001)  # 1 ms delay to ensure receiver catches all bytes
        print(f"Sent byte: {byte:#04x}")

    ser.close()
    print("Transmission complete.")


if __name__ == "__main__":
    uart_prog()
