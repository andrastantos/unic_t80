GHDL=ghdl
GHDLFLAGS= -fsynopsys -fexplicit --std=08
GHDLRUNFLAGS= --vcd=_out/debugsystem_tb.vcd

# Default target : elaborate
all: run

VHDL_SRC =  \
    StimLog.vhd \
    ../T80_Pack.vhd \
    ../T80a.vhd \
    _obj/test.vhd \
    SSRAM2.vhd \
    T16450.vhd \
    DebugSystem.vhd \
    DebugSystem_TB.vhd \
    ../T80.vhd \
    ../T80_MCode.vhd \
    ../T80_ALU.vhd \
    ../T80_Reg.vhd \
    AsyncStim.vhd \
    AsyncLog.vhd

# Run target
run: $(VHDL_SRC)
	-mkdir _out
	$(GHDL) -c $(GHDLFLAGS) $(VHDL_SRC) -r debugsystem_tb $(GHDLRUNFLAGS)


force:

_obj/test.ihx: test.c
	-mkdir _obj
	sdcc -mz80 $^ -o $@

_obj/test.bin: _obj/test.ihx
	-mkdir _obj
	objcopy --input-target=ihex --output-target=binary $< $@

#_obj/hex2rom: hex2rom.cpp
#	-mkdir _obj
#	g++ $^ -o $@

#_obj/test.vhd: _obj/test.bin
_obj/test.vhd: _obj/zexall.bin sram_template.vhd
	-mkdir _obj
	./ram_init.py -i $< -o $@ -t sram_template.vhd -n ROM

zmac/zmac:
	make -C zmac zmac

_obj/zexall.hex: zexall.asm zmac/zmac
	-mkdir _obj
	zmac/zmac $< -o $@

_obj/zexall.bin: _obj/zexall.hex
	-mkdir _obj
	objcopy --input-target=ihex --output-target=binary $< $@

