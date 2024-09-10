        aseg
        ;; Reset vector
        .org    0
        jp      init

        .org    0x08
        reti
        .org    0x10
        reti
        .org    0x18
        reti
        .org    0x20
        reti
        .org    0x28
        reti
        .org    0x30
        reti
        .org    0x38 ; interrupt vector for maskable interrupts
irq:
        inc     b
        reti

        .org    0x66 ; interrupt vector for non-maskable interrupts
nmi:
        inc     b
        retn

        .org    0x100
init:
        ld b,0
        ld a,2
        cp b
        jr nz,first
        nop
        nop
        nop
        nop
first:
        jr z,second
        nop
        nop
        nop
        nop
second:
        ; test add hl ... group as those theoretically raise 'nojump' in M1, which *should* take wait-states into account, albeit that only happens in GB mode (mode 3), which I'm not even sure is the correct behavior, to be honest.
        ld hl,0x1234
        ld bc,0x8765
        ld sp,0x1000
        push bc

        ld a,h
        out 0x80 ; just to see something in the trace
        ld a,l
        out 0x80 ; just to see something in the trace

        ex (sp),hl

        ld a,h
        out 0x80 ; just to see something in the trace
        ld a,l
        out 0x80 ; just to see something in the trace

        ld a,h
        cp 0x87
        jr nz, fatal
        ld a,l
        cp 0x65
        jr nz, fatal

        pop hl
        ld a,h
        cp 0x12
        jr nz, fatal
        ld a,l
        cp 0x34
        jr nz, fatal

        out 0x9a ; terminate
done:
        jp done
fatal:
        out 0x9b ; terminate
        jp done
