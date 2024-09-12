
PROGRAM = ldi_test

LD_LIBRARY_PATH=./tools/lib
CPMTOOLSFMT=pcw
ZMAC=tools/bin/zmac
CPMCP=LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) CPMTOOLSFMT=$(CPMTOOLSFMT) tools/bin/cpmcp

OBJ=_obj/
BIN=_bin/

all: setup make_dsk

setup:
	-mkdir $(BIN)
	-mkdir $(OBJ)

make_dsk: $(OBJ)$(PROGRAM).com
	echo "setdef m:,* [order = (sub,com) temporary = m:]" > $(OBJ)/profile.sub
	echo "$(PROGRAM)" >> $(OBJ)/profile.sub
	cp base.dsk $(BIN)/$(PROGRAM).dsk
	$(CPMCP) -t $(BIN)/$(PROGRAM).dsk $(OBJ)/profile.sub 0:profile.sub
	$(CPMCP) $(BIN)/$(PROGRAM).dsk $(OBJ)/$(PROGRAM).com 0:$(PROGRAM).com



############## RULES TO CREATE A BINARY COM FILE FORM SOURCES

$(ZMAC): ../sim/zmac/zmac
	cp $< $@

../sim/zmac/zmac:
	make -C ../sim/zmac zmac

$(OBJ)%.hex: %.asm $(ZMAC)
	$(ZMAC) $< -o $@ -o $(@:.hex=.lst)

$(OBJ)%.hex: %.c
	sdcc -mz80 $^ -o $@

$(OBJ)%.com: $(OBJ)%.hex
	objcopy --input-target=ihex --output-target=binary $< $@
