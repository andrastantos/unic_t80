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
        ld a,0
        im 1    ; set interrupt mode 1
        ;ei      ; enable interrupts
        ; Schedule interrupt 50 cycles into the operation
        ld a,25
        out 0xfa

wait:
        dec a
        jr nz,wait

        ld a,b   ; if the interrupt fired, we should fail the test
        jr z, ok1
        out 0xfb ; terminate
ok1:
        ei
        jr loop2
        nop
        nop
        nop
loop2:
        ld a, 25
wait2:
        dec a
        jr nz,wait2

        ld a,b   ; if the interrupt hasn't, we should fail the test
        dec a
        out 0xfb ; terminate
done:
        jp done
