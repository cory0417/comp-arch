filename    ?= top
init_file 	?= $(PWD)/tb/prog
sv_sources	:= ./rtl/*.sv
v_sources	:= ./rtl/verilog/*.v
pcf_file    := ../iceBlinkPico.pcf
ifdef DEBUG
  SV2V_DEFINE := --define=DEBUG=1
else
  SV2V_DEFINE :=
endif

build:
	../sv2v/sv2v --write=rtl/verilog $(SV2V_DEFINE) $(sv_sources) --top=$(filename)
	sed -i '' "s|@INIT_FILE@|$(init_file)|g" "rtl/verilog/$(filename).v"
	yosys -p "synth_ice40 -top $(filename) -json $(filename).json" $(v_sources)
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc --freq 12
	icepack $(filename).asc $(filename).bin

prog:
	dfu-util --device 1d50:6146 --alt 0 -D $(filename).bin -R

clean:
	rm -f $(filename).asc $(filename).json $(filename).bin

.PHONY: build prog clean