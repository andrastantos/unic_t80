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
        im 1    ; set interrupt mode 1
        ei      ; enable interrupts
        ; Schedule interrupt 100 cycles into the operation, NMI into 200 cycles
        ld a,50
        out 0xfa
        ld a,100+128
        out 0xfa

wait:
        cp b
        jr nz,wait

        ld a,0
        out 0xfb ; terminate
done:
        jp done
