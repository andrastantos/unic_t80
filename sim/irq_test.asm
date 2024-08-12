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
        jp      irq
        reti

        .org    0x66 ; interrupt vector for non-maskable interrupts
nmi:
        jp      nmi
        retn

        .org    0x100
init:
        im 1    ; set interrupt mode 1
        ei      ; enable interrupts
done:
        jp done
