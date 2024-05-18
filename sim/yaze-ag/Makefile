# Makefile for yaze-ag

BUILD = " (build for INTEL x86_64Bit (corei7))"

# CC must be an ANSI-C compiler
CC            =	gcc

#where you want the binaries and manual page
BINDIR	      = /usr/local/bin
MANDIR	      = /usr/local/man/man1
LIBDIR	      = /usr/local/lib/yaze
DSKDIR        = $(LIBDIR)/disks
DOCDIR        = $(LIBDIR)/doc
DOCHTMLDIR    = $(LIBDIR)/doc_html

OPTIMIZE      = -g
#OPTIMIZE      = -g -O2

# -DUSE_GNU_READLINE for command recall/editing and filename completion
# -DBGii_BUG works around a problem in Backgrounder II
# -DBIOS to build a CP/M bios and monitor program into the emulator
#  (see also YAZE_OBJS, below)
#
# -- The following options are new:
#
# -DMMU compiles support for MMU-switched memory and CP/M 3.1 extensions
# -DMMUTABLES=<val> sets the no of MMU tables (default 16)
# -DYAZEPAGESIZE=<val> sets the page size for every page pointer (default 4 KB)
#		(The MMUPAGEPOINTERS are generated automatically)
# -DSHOWMMU shows at start the MMU tables (will be defined if MMUTEST is def.)
# -DMMUTEST setup pages for 3000h - BFFFh to pages above 64K
#	    (-DSHOWMMU will be set and the MMU-Table 7 will be selected)
#	    (Only used unter CP/M 2.2. See README-1.20 for details)
#	    (DO NOT USE IT IF YOU WANT TO RUN CP/M 3.1 - THIS IS ONLY FOR TEST!)
#
# -DMEMSIZE=<val> sets size of memory in KBytes (default 64KB, with MMU:  512KB)
#
# -DBOOTSYS loads yaze-cpm3.boot at 0100H  instead of  yaze.boot (CP/M 2.2).
#	    yaze-cpm3.boot is idendical with A: CPM3.COM. Inside there is
#	    the CP/M 3.1 loader BOOTSYS.COM + CPM3.SYS (see BOOTSYS.Z80
#	    on drive P: ). You can generate CPM3.COM with
#		"pip cpm3.com=bootsys.com,cpm3.sys".
#	    If BOOTSYS is given you can boot CP/M 2.2 (SUPERDOS) with
#		"yaze -l -1 -b yaze.boot".
#
# -DSHOWDRV shows the entries in @dtbl, the DPHs and the DPBs when CP/M 3.1
#	    starts or "mount.com" or "sys mount" is running.
# -DMULTIO  Use Multi-I/O disk transfere
# -DRWDEBUG Set the debug mode for read/write operations. If MULTIO is defined
#	    and multi sector count is set by the bdos the multi sector read
#	    and write will be displayed with "r" and "w". The rest will be
#	    displayed with ".". Reads/writes without multi sector count will
#	    be displayed with "R" and "W".
#
# -DUCSD    Set mode if you want to use UCSD-pascal version for CP/M.
#	    It was neccessary because UCSD-Pascal-System does not use the
#	    register B when it gives Sektor or Track to the BIOS. With this
#	    Flag only the Register C of BC is used in SETTRK & SETSEC. It
#	    was neccessary because yaze-ag crashes.
#
# --
# solaris2, freebsd and cygwin needs -D__EXTENSIONS__
# linux needs -D_BSD_SOURCE -D_POSIX_SOURCE
#
#OPTIONS	= -DBIOS -D_DEFAULT_SOURCE -D_POSIX_SOURCE -DMMU -DBOOTSYS -DMULTIO \
#		-DUSE_GNU_READLINE \
		# -DSHOWDRV
OPTIONS	= -DDEBUG -D_DEFAULT_SOURCE -D_POSIX_SOURCE -DBOOTSYS -DMULTIO

# Link with CP/M BIOS support,
#YAZE_OBJS     = yaze.o mem_mmu.o simz80.o simz80_wts.o ytimer.o ybios.o \
#		monitor.o keytran.o conin.o
# or link as a naked Z80
YAZE_OBJS    = _obj/yaze.o _obj/simz80.o _obj/io.o _obj/mem_mmu.o

# Keyboard translation test program
KT_OBJS       = _obj/keytest.o _obj/conin.o _obj/keytran.o _obj/nulrq.o

# -lreadline -lcurses -liberty if you defined USE_GNU_READLINE
#  (you don't need -liberty on linux or BSD systems)
#
#LIBS	      = -lreadline -lncurses
LIBS	      =

# CWARN	      = -ansi -pedantic -Wall -Wshadow \
#		-Wpointer-arith -Wnested-externs -Winline
CWARN	      = -pedantic -Wall -Wshadow \
		-Wpointer-arith -Wnested-externs -Winline \
		-Wno-attributes -Wno-char-subscripts -Wno-unused-variable \
		-Wno-unused-result -Wno-builtin-declaration-mismatch
# CWARN	      = -ansi -Wall
CFLAGS        =	$(CWARN) $(OPTIMIZE) $(OPTIONS) -DLIBDIR=\"$(LIBDIR)/\" \
		-DBUILD=\"$(BUILD)\"

all: setup _bin/yaze_bin _obj/zexall.bin

run: all
		_bin/yaze_bin -b _obj/zexall.bin -l 0

setup:
		-mkdir _obj
		-mkdir _bin

clean:
		rm -rf _obj/*
		rm -rf _bin/*

_bin/yaze_bin: $(YAZE_OBJS)
		-mkdir _bin
		$(CC) $(CFLAGS) $(YAZE_OBJS) $(LIBS) -o $@
		ln -f -s yaze.sh yaze

_obj/simz80.c: simz80.pl
		-mkdir _obj
		rm -f $@
		perl -w $< >$@
		chmod a-w $@

_obj/yaze.o: yaze.c simz80.h yaze.h mem_mmu.h ytypes.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/ybios.o: ybios.c simz80.h yaze.h ybios.h mem_mmu.h ytypes.h ktt.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/mem_mmu.o: mem_mmu.c mem_mmu.h simz80.h ytypes.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/simz80.o: simz80.c simz80.h mem_mmu.h ytypes.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/simz80_wts.o: simz80_wts.c simz80.h mem_mmu.h ytypes.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/ytimer.o: ytimer.c ytypes.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/monitor.o: monitor.c yaze.h ybios.h chan.h mem_mmu.h ytypes.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/keytran.o: keytran.c ktt.h ytypes.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/conin.o: conin.c ytypes.h ktt.h chan.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/io.o: io.c simz80.h yaze.h mem_mmu.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/keytest.o: keytest.c ytypes.h ktt.h
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@

_obj/nulrq.o: nulrq.c
		$(CC) -c $(CFLAGS) $< $(LIBS) -o $@




../zmac/zmac:
	make -C ../zmac zmac

_obj/zexall.hex:  ../zexall.asm ../zmac/zmac
	-mkdir _obj
	../zmac/zmac $< -o $@ -o $(@: .hex=.lst)

_obj/zexall.bin:  _obj/zexall.hex
	-mkdir _obj
	objcopy --input-target=ihex --output-target=binary $< $@

z:  _obj/zexall.bin

