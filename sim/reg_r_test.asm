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
        reti
        .org    0x66 ; interrupt vector for non-maskable interrupts
nmi:
        retn

        .org    0x100
init:
        ; Some instructions to crank up the refresh counter
        ld a, 0
        ld a, 0
        ld a, 0
        ld a, 0
        ld a, 0
        ld a, 0

        ld a,r
        out 0x80

        ld a,0
        out 0xfb ; terminate
done:
        jp done
