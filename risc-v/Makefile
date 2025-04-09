filename      ?= top
sources       := ./rtl/types.sv \
                 ./rtl/control.sv \
                 ./rtl/pc_selector.sv \
                 ./rtl/alu.sv \
                 ./rtl/register_file.sv \
                 ./rtl/imm_extender.sv \
                 ./rtl/memory.sv \
                 ./rtl/risc_v.sv \
                 ./rtl/$(filename).sv
pcf_file      := ../iceBlinkPico.pcf

build:
	yosys -p "synth_ice40 -top $(filename) -json $(filename).json" $(sources)
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog:
	dfu-util --device 1d50:6146 --alt 0 -D $(filename).bin -R

clean:
	rm -f $(filename).asc $(filename).json $(filename).bin

.PHONY: build prog clean