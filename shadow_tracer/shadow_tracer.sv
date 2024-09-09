// Z80 pin-compatible top level

module shadow_tracer_top (
    //input logic clk27,

    output logic lcd_rst_n,
    output logic lcd_cs_n,
    output logic psram_cs_n,
    output logic flash_cs_n,
    //input  logic spi_miso_io1,
    output logic spi_mosi_io0,
    output logic spi_clk,
    //output logic spi_io3,
    //output logic spi_io2,

	input logic RESET_n,
	input logic CLK_n,
	input logic WAIT_n,
	input logic INT_n,
	input logic NMI_n,
	input logic BUSRQ_n,
    output logic M1_n,
    output logic MREQ_n,
    output logic IORQ_n,
    output logic RD_n,
    output logic WR_n,
    output logic RFSH_n,
    output logic HALT_n,
    output logic BUSAK_n,
    output logic [15:0] A,
	inout logic [7:0] D,

    output logic GND,

    output logic TXD
);
    logic [7:0] CPU_DI;
    logic [7:0] CPU_DO;
    logic DO_EN_n;

    //assign GND = 1'b0;
    assign GND = 1'bz;

    logic oled_clk;

    OSC osc_inst (
        .OSCOUT(oled_clk)
    );

    //defparam osc_inst.FREQ_DIV = 10; // Sets clk to about 21MHz
    defparam osc_inst.FREQ_DIV = 20; // Sets clk to about 10MHz
    defparam osc_inst.DEVICE = "GW1NR-9C";

    assign lcd_rst_n = 1'b0;
    assign lcd_cs_n = 1'b1;
    assign psram_cs_n = 1'b1;
    assign flash_cs_n = 1'b1;
    assign spi_mosi_io0 = 1'b1;
    assign spi_clk = 1'b1;

    assign CPU_DI = D;
    assign D = ~DO_EN_n ? CPU_DO : 8'bZ;



    T80a_dido #(
        .Mode(0),
        .IOWait(1),
        .R800_mode(0)
    ) z80 (
        .RESET_n (RESET_n ),
        .CLK_n   (CLK_n   ),
        .WAIT_n  (WAIT_n  ),
        .INT_n   (INT_n   ),
        .NMI_n   (NMI_n   ),
        .BUSRQ_n (BUSRQ_n ),
        .M1_n    (M1_n    ),
        .MREQ_n  (MREQ_n  ),
        .IORQ_n  (IORQ_n  ),
        .RD_n    (RD_n    ),
        .WR_n    (WR_n    ),
        .RFSH_n  (RFSH_n  ),
        .HALT_n  (HALT_n  ),
        .BUSAK_n (BUSAK_n ),
        .A       (A       ),
        .DI      (CPU_DI  ),
        .DO      (CPU_DO  ),
        .DO_EN_n (DO_EN_n ),
        .DBG_out (DBG_out )
    );

    // We create a signal that fires when we get an IRQ while an NMI is in progress
    logic prev_int_n;
    logic int_edge;
    logic int_while_nmi;

    always @(posedge CLK_n) prev_int_n <= INT_n;
    always @(posedge CLK_n) int_edge <= prev_int_n & ~INT_n;
    assign int_while_nmi = ~NMI_n & int_edge;
    assign TXD = DBG_out;

    // Analyzer helpers
    // NOTE: mem and I/O cycles end on a falling edge, while M1 cycles end on a rising one. Lovely!
    logic mem_rd;
    logic mem_wr;
    logic io_rd;
    logic io_wr;

    assign mem_rd = MREQ_n | RD_n;
    assign mem_wr = MREQ_n | WR_n;
    assign io_rd = IORQ_n | RD_n;
    assign io_wr = IORQ_n | WR_n;


endmodule
