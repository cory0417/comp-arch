filename    ?= top
INIT_FILE 	?= $(PWD)/prog/prog
sv_sources	:= ./rtl/*.sv
v_sources	:= ./rtl/verilog/*.v
pcf_file    := ../iceBlinkPico.pcf
ifdef DEBUG
  SV2V_DEFINE := --define=DEBUG=1
else
  SV2V_DEFINE :=
endif

SRC := blink.c
SRC_NAME := $(basename $(SRC))
SRC_PATH := ./prog/$(SRC_NAME)
BUILD_DIR := ./prog/build
LINKER := ./prog/link.ld
STARTUP := ./prog/startup.S
GCC_FLAGS := -march=rv32i -mabi=ilp32 -Os -nostdlib -T $(LINKER) -Wl,--gc-sections,--print-gc-sections -Wall -Wextra

build:
	../sv2v/sv2v --write=rtl/verilog $(SV2V_DEFINE) $(sv_sources) --top=$(filename)
	python prog/split_memhfile.py $(INIT_FILE).txt
	sed -i '' "s|@INIT_FILE@|$(INIT_FILE)|g" "rtl/verilog/$(filename).v"
	yosys -p "synth_ice40 -top $(filename) -json $(filename).json" $(v_sources)
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc --freq 12
	icepack $(filename).asc $(filename).bin

prog:
	dfu-util --device 1d50:6146 --alt 0 -D $(filename).bin -R

clean:
	rm -f $(filename).asc $(filename).json $(filename).bin prog/*[0-3].txt
	rm -rf $(BUILD_DIR)

compile:
	mkdir -p $(BUILD_DIR)
	riscv-none-elf-gcc -o $(BUILD_DIR)/$(SRC_NAME).elf $(SRC_PATH).c $(STARTUP) ./prog/peripherals.h $(GCC_FLAGS)
	riscv-none-elf-objcopy -O binary $(BUILD_DIR)/$(SRC_NAME).elf $(BUILD_DIR)/$(SRC_NAME).bin
	od -An -H -v $(BUILD_DIR)/$(SRC_NAME).bin | sed -E 's/[[:space:]]+/\n/g' | sed -E '/^[[:space:]]*$$/d' > $(BUILD_DIR)/$(SRC_NAME).txt
# For debugging, generate assembly code without linking
	riscv-none-elf-gcc -S $(GCC_FLAGS) $(SRC_PATH).c -o $(BUILD_DIR)/$(SRC_NAME).s

.PHONY: build prog clean compile