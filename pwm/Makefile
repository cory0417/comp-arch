filename ?= top
pcf_file = ../iceBlinkPico.pcf
pcf_unconstrained ?= 0

build:
	yosys -p "synth_ice40 -top $(filename) -json $(filename).json" $(filename).sv pwm_timer.sv
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc $(if $(pcf_unconstrained),--pcf-allow-unconstrained)
	icepack $(filename).asc $(filename).bin

prog: #for sram
	dfu-util --device 1d50:6146 --alt 0 -D $(filename).bin -R

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).json $(filename).bin

sim:
	iverilog -g2012 -o $(filename)_tb.vvp $(filename).sv pwm_timer.sv $(filename)_tb.sv
	vvp $(filename)_tb.vvp

lint:
	verible-verilog-lint --rules=-explicit-parameter-storage-type $(filename).sv || exit 1

format:
	verible-verilog-format --indentation_spaces=4 --inplace $(filename).sv

lint-fix: format lint

.PHONY: build prog clean sim lint format lint-fix
