// Z80 pin-compatible top level

module t80_top (
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

    output logic io1a,
    output logic io1b,
    output logic io2a,
    output logic io2b,
    output logic io3a,
    output logic io3b,
    output logic io4a,
    output logic io4b,
    output logic io5a,
    output logic io5b,

    output logic TXD,
    input logic RXD
);
    logic [7:0] CPU_DI;
    logic [7:0] CPU_DO;
    logic DO_EN_n;
    logic MREQ_n_i;
    logic IORQ_n_i;
    logic RD_n_i;
    logic WR_n_i;
    logic RFSH_n_i;
    logic BUSAK_n_i;
    logic [15:0] A_i;
    logic DBG_out;

    //assign GND = 1'b0;
    assign GND = 1'bz;

    logic oled_clk;

    OSC osc_inst (
        .OSCOUT(oled_clk)
    );

    //defparam osc_inst.FREQ_DIV = 10; // Sets clk to about 21MHz
    defparam osc_inst.FREQ_DIV = 4; // Sets clk to about 50MHz
    defparam osc_inst.DEVICE = "GW1NR-9C";


    assign lcd_rst_n = 1'b0;
    assign lcd_cs_n = 1'b1;
    assign psram_cs_n = 1'b1;
    assign flash_cs_n = 1'b1;
    assign spi_mosi_io0 = 1'b1;
    assign spi_clk = 1'b1;

    assign CPU_DI = D;
    assign D      = ~DO_EN_n ? CPU_DO : 8'bZ;
	assign MREQ_n = BUSAK_n_i ? MREQ_n_i : 1'bZ;
	assign IORQ_n = BUSAK_n_i ? IORQ_n_i : 1'bZ;
	assign RD_n   = BUSAK_n_i ? RD_n_i : 1'bZ;
	assign WR_n   = BUSAK_n_i ? WR_n_i : 1'bZ;
	assign RFSH_n = BUSAK_n_i ? RFSH_n_i : 1'bZ;
	assign A      = BUSAK_n_i ? A_i : 16'bZ;
    assign BUSAK_n = BUSAK_n_i;


    T80a_dido #(
        .Mode(0),
        .IOWait(1),
        .R800_mode(0)
    ) z80 (
        .RESET_n (RESET_n   ),
        .CLK_n   (CLK_n     ),
        .WAIT_n  (WAIT_n    ),
        .INT_n   (INT_n     ),
        .NMI_n   (NMI_n     ),
        .BUSRQ_n (BUSRQ_n   ),
        .M1_n    (M1_n      ),
        .MREQ_n  (MREQ_n_i  ),
        .IORQ_n  (IORQ_n_i  ),
        .RD_n    (RD_n_i    ),
        .WR_n    (WR_n_i    ),
        .RFSH_n  (RFSH_n_i  ),
        .HALT_n  (HALT_n    ),
        .BUSAK_n (BUSAK_n_i ),
        .A       (A_i       ),
        .DI      (CPU_DI    ),
        .DO      (CPU_DO    ),
        .DO_EN_n (DO_EN_n   ),
        .DBG_out (DBG_out   )
    );


    assign io1a = 1'bz;
    assign io1b = 1'bz;
    assign io2a = 1'bz;
    assign io2b = 1'bz;
    assign io3a = 1'bz;
    assign io3b = 1'bz;
    assign io4a = 1'bz;
    assign io4b = 1'bz;
    assign io5a = 1'bz;
    assign io5b = 1'bz;
    assign TXD = 1'bz;

endmodule

