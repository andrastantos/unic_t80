GHDL=ghdl
GHDLFLAGS= -fsynopsys -fexplicit --std=08
GHDLRUNFLAGS= --vcd=debugsystem_tb.vcd

# Default target : elaborate
all: run

VHDL_SRC =  \
    StimLog.vhd \
    ../T80_Pack.vhd \
    ../T80s.vhd \
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
	$(GHDL) -c $(GHDLFLAGS) $(VHDL_SRC) -r debugsystem_tb $(GHDLRUNFLAGS)


force:

_obj/test.ihx: test.c
	-mkdir _obj
	sdcc -mz80 $^ -o $@

_obj/test.bin: _obj/test.ihx
	-mkdir _obj
	objcopy --input-target=ihex --output-target=binary $< $@

_obj/hex2rom: hex2rom.cpp
	-mkdir _obj
	g++ $^ -o $@

_obj/test.vhd: _obj/test.bin _obj/hex2rom
	-mkdir _obj
	_obj/hex2rom $< MonZ80 15l8s $@
