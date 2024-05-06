GHDL=ghdl
GHDLFLAGS= -fsynopsys -fexplicit --std=08
GHDLRUNFLAGS= --vcd=debugsystem_tb.vcd

# Default target : elaborate
all : elab

# Elaborate target.  Almost useless
elab : init
	$(GHDL) -c $(GHDLFLAGS) -e debugsystem_tb

# Run target
run : init
	$(GHDL) -c $(GHDLFLAGS) -r debugsystem_tb $(GHDLRUNFLAGS)

# Targets to analyze libraries
init: force test.vhd
	-rm work-obj93.cf
	# /usr/lib/ghdl/mcode/vhdl/ieee/v93/../../src/ieee/v93/std_logic_1164.vhdl
	# /usr/lib/ghdl/mcode/vhdl/ieee/v93/../../src/ieee/v93/std_logic_1164-body.vhdl
	$(GHDL) -a $(GHDLFLAGS) StimLog.vhd
	# /usr/lib/ghdl/mcode/vhdl/ieee/v93/../../src/ieee/v93/numeric_std.vhdl
	# /usr/lib/ghdl/mcode/vhdl/ieee/v93/../../src/ieee/v93/numeric_std-body.vhdl
	# /usr/lib/ghdl/mcode/vhdl/ieee/v93/../../src/synopsys/std_logic_arith.vhdl
	# /usr/lib/ghdl/mcode/vhdl/ieee/v93/../../src/synopsys/std_logic_unsigned.vhdl
	$(GHDL) -a $(GHDLFLAGS) ../T80_Pack.vhd
	$(GHDL) -a $(GHDLFLAGS) ../T80s.vhd
	$(GHDL) -a $(GHDLFLAGS) test.vhd
	$(GHDL) -a $(GHDLFLAGS) SSRAM2.vhd
	$(GHDL) -a $(GHDLFLAGS) T16450.vhd
	$(GHDL) -a $(GHDLFLAGS) DebugSystem.vhd
	$(GHDL) -a $(GHDLFLAGS) DebugSystem_TB.vhd
	$(GHDL) -a $(GHDLFLAGS) ../T80.vhd
	$(GHDL) -a $(GHDLFLAGS) ../T80_MCode.vhd
	$(GHDL) -a $(GHDLFLAGS) ../T80_ALU.vhd
	$(GHDL) -a $(GHDLFLAGS) ../T80_Reg.vhd
	$(GHDL) -a $(GHDLFLAGS) AsyncStim.vhd
	$(GHDL) -a $(GHDLFLAGS) AsyncLog.vhd

force:

test.ihx: test.c
	sdcc -mz80 $^ -o $@

test.bin: test.ihx
	objcopy --input-target=ihex --output-target=binary $< $@

hex2rom: hex2rom.cpp
	g++ $^ -o $@

test.vhd: test.bin hex2rom
	./hex2rom $< MonZ80 15l8s $@
