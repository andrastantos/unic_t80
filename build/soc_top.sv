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
	inout logic [7:0] D
);
    logic [7:0] CPU_DI;
    logic [7:0] CPU_DO;
    logic DO_EN_n;

    logic oled_clk;

    OSC osc_inst (
        .OSCOUT(oled_clk)
    );

    defparam osc_inst.FREQ_DIV = 10; // Sets clk to about 21MHz
    defparam osc_inst.DEVICE = "GW1NR-4D";


    logic busy;
    logic spi_ncs;
    logic spi_mosi;
    logic [7:0] clk_divider;
    logic [7:0] rst_divider;

    logic [31:0] refresh_divider;
    logic refresh;
    logic lcd_nrst;


    always @(posedge oled_clk) begin
        if (refresh_divider == 10000000) begin
            refresh = 1'b1;
            refresh_divider = 0;
        end else begin
            refresh = 1'b0;
            refresh_divider = refresh_divider + 1'b1;
        end
    end

    /*
    assign refresh = refresh_divider[15:0] == 'hffff;
    always @(posedge oled_clk) begin
        if (refresh_divider != 'h3ffff) begin
            refresh_divider = refresh_divider + 1'b1;
        end
    end
    */

    //assign refresh = 1'b0;


    assign clk_divider = 20; // Roughly 1MHz SPI clk
    assign rst_divider = 100; // Roughly 5us of reset pulse

    OledCtrl oled_ctrl (
        .clk(oled_clk),
        .rst(1'b0),
        .reset(1'b0),
        .refresh(refresh),
        .busy(busy),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_ncs(spi_ncs),
        .lcd_nrst(lcd_nrst),
        .clk_divider(clk_divider),
        .rst_divider(rst_divider)
    );

    assign psram_cs_n = 1'b0;
    assign flash_cs_n = 1'b0;
    assign lcd_cs_n = spi_ncs;
    assign spi_mosi_io0 = spi_mosi;
    assign lcd_rst_n = lcd_nrst;

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
        .DO_EN_n (DO_EN_n )
    );

endmodule

