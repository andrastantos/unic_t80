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
        ld      c,b
        reti

        .org    0x66 ; interrupt vector for non-maskable interrupts
nmi:
        dec     b
        retn

        .org    0x100
init:
        ld b,0
        ld a,0
        im 1    ; set interrupt mode 1
        ; Schedule interrupt and an NMI to the same clock cycle
        ld a,2
        out 0xfa
        ld a,11+128
        out 0xfa

        ld  a,1
        ld  b,a
        ld  a, 255
        ei      ; enable interrupts
        jr  wait
        nop
        nop
        nop
wait:
        dec a
        jr nz,wait

        ld a,c   ; if the interrupt fired before the NMI, we should fail the test
        out 0xfb ; terminate
done:
        jp done
