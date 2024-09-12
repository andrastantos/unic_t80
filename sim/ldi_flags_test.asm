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
        ld a,2
        ld bc,10
        ld hl,src
        ld de,0x2000 ; some random target address
loop:
        out 0x02 ; just something to mark the trace
        ldi
        push af
        pop af
        jp pe, loop

        out 0x9a ; terminate
done:
        jp done

src:
        db	0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0xff
