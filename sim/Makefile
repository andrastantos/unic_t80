GHDL=ghdl
GHDLFLAGS= -fsynopsys -fexplicit --std=08 -O2
GHDLRUNFLAGS=

PROGRAM = ldi_flags_test

# Default target : elaborate
all: run

VHDL_SRC =  \
	../T16450.vhd \
    ../T80_Pack.vhd \
    ../T80a.vhd \
    _obj/test.vhd \
    _obj/sram_with_init.vhd \
    SSRAM2.vhd \
    sim_ser.vhd \
    ../soc_top.vhd \
    soc_TB.vhd \
    DebugSystem.vhd \
    DebugSystem_TB.vhd \
    ../T80.vhd \
    ../T80_MCode.vhd \
    ../T80_ALU.vhd \
    ../T80_Reg.vhd

# Run target
elab: $(VHDL_SRC)
	-mkdir _out
	-mkdir _obj
	cd _obj && $(GHDL) -a $(GHDLFLAGS) $(patsubst %, ../%, $(VHDL_SRC))
	cd _obj && $(GHDL) -e $(GHDLFLAGS) debugsystem_tb

run: elab
	cd _obj && time $(GHDL) -r $(GHDLFLAGS) debugsystem_tb $(GHDLRUNFLAGS) --vcd=../_out/debugsystem_tb.vcd

sim: elab
	cd _obj && time $(GHDL) -r $(GHDLFLAGS) debugsystem_tb $(GHDLRUNFLAGS)

run_soc: elab
	cd _obj && time $(GHDL) -r $(GHDLFLAGS) soc_tb $(GHDLRUNFLAGS) --vcd=../_out/soc_tb.vcd

sim_soc: elab
	cd _obj && time $(GHDL) -r $(GHDLFLAGS) soc_tb $(GHDLRUNFLAGS)



force:

_obj/test.vhd: _obj/$(PROGRAM).bin sram_template.vhd
	-mkdir _obj
	python ./ram_init.py -i $< -o $@ -t sram_template.vhd -n ROM

_obj/sram_with_init.vhd: _obj/$(PROGRAM).bin ../SSRAM_template.vhd
	-mkdir _obj
	python ./ram_init.py -i $< -o $@ -t ../SSRAM_template.vhd -n SSRAM_with_init

zmac/zmac:
	make -C zmac zmac

#_obj/zexall.hex: zexall.asm zmac/zmac
#	-mkdir _obj
#	zmac/zmac $< -o $@ -o $(@:.hex=.lst)
#
#_obj/zexall.bin: _obj/zexall.hex
#	-mkdir _obj
#	objcopy --input-target=ihex --output-target=binary $< $@
#
#
#_obj/irq_test.hex: irq_test.asm zmac/zmac
#	-mkdir _obj
#	zmac/zmac $< -o $@ -o $(@:.hex=.lst)
#
#_obj/irq_test.bin: _obj/irq_test.hex
#	-mkdir _obj
#	objcopy --input-target=ihex --output-target=binary $< $@
#
#


_obj/%.hex: %.asm zmac/zmac
	-mkdir _obj
	zmac/zmac $< -o $@ -o $(@:.hex=.lst)

_obj/%.hex: %.c
	-mkdir _obj
	sdcc -mz80 $^ -o $@

_obj/%.bin: _obj/%.hex
	-mkdir _obj
	objcopy --input-target=ihex --output-target=binary $< $@
