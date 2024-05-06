#include <stdio.h>

__sfr __at(0x00) uart0_DATA;
__sfr __at(0x01) uart0_INT_EN;
__sfr __at(0x02) uart0_INT_ID;
__sfr __at(0x03) uart0_LINE_CTRL;
__sfr __at(0x04) uart0_MODEM_CTRL;
__sfr __at(0x05) uart0_LINE_STAT;
__sfr __at(0x06) uart0_MODEM_STAT;

#define uart0_UART_DIV_L uart0_DATA
#define uart0_UART_DIV_H uart0_INT_EN

__sfr __at(0x80) uart1_DATA;
__sfr __at(0x81) uart1_INT_EN;
__sfr __at(0x82) uart1_INT_ID;
__sfr __at(0x83) uart1_LINE_CTRL;
__sfr __at(0x84) uart1_MODEM_CTRL;
__sfr __at(0x85) uart1_LINE_STAT;
__sfr __at(0x86) uart1_MODEM_STAT;

#define uart1_UART_DIV_L uart1_DATA
#define uart1_UART_DIV_H uart1_INT_EN


void init_uart(void) {
    // For 115200 baud at a 18MHz clock (which is the default sim setup) we need to set the divisor to 10
    uart0_INT_EN = 0;
    uart0_LINE_CTRL = 0x80; // set DLAB bit
    uart0_UART_DIV_H = 0;
    uart0_UART_DIV_L = 10;
    uart0_LINE_CTRL =
        (0x3 << 0) | // 8 data bits
        (0x1 << 2) | // 2 stop bits
        (0x0 << 3) | // no parity
        (0x0 << 4) | // parity odd/even
        (0x0 << 5) | // stick parity
        (0x0 << 6) | // break
        (0x0 << 7);  // DLAB bit

    uart1_INT_EN = 0;
    uart1_LINE_CTRL = 0x80; // set DLAB bit
    uart1_UART_DIV_H = 0;
    uart1_UART_DIV_L = 10;
    uart1_LINE_CTRL =
        (0x3 << 0) | // 8 data bits
        (0x1 << 2) | // 2 stop bits
        (0x0 << 3) | // no parity
        (0x0 << 4) | // parity odd/even
        (0x0 << 5) | // stick parity
        (0x0 << 6) | // break
        (0x0 << 7);  // DLAB bit
}

int putchar (int c) {
    while ((uart0_LINE_STAT & (1 << 5)) == 0);
    uart0_DATA = c;
    return c;
}

int getchar(void) {
    while ((uart0_LINE_STAT & (1 << 0)) == 0);
    return uart0_DATA;
}

int main(void) {
    init_uart();
    puts("Hello world\n");
    return 0;
}
