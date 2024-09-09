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
        out 0x9a ; terminate
done:
        jp done
