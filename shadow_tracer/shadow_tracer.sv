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
    input logic M1_n,
    input logic MREQ_n,
    input logic IORQ_n,
    input logic RD_n,
    input logic WR_n,
    input logic RFSH_n,
    input logic HALT_n,
    input logic BUSAK_n,
    input logic [15:0] A,
	input logic [7:0] D,

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
    //output logic io6a,
    //output logic io6b
);
    logic [7:0] CPU_DI;
    logic [7:0] CPU_DO;
    logic DO_EN_n;
    logic HALT_n_i;
    logic M1_n_i;
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
    defparam osc_inst.FREQ_DIV = 20; // Sets clk to about 10MHz
    defparam osc_inst.DEVICE = "GW1NR-9C";

    assign lcd_rst_n = 1'b0;
    assign lcd_cs_n = 1'b1;
    assign psram_cs_n = 1'b1;
    assign flash_cs_n = 1'b1;
    assign spi_mosi_io0 = 1'b1;
    assign spi_clk = 1'b1;

    assign CPU_DI = D;
    //assign D      = ~DO_EN_n ? CPU_DO : 8'bZ;
	//assign MREQ_n = BUSAK_n_i ? MREQ_n_i : 1'bZ;
	//assign IORQ_n = BUSAK_n_i ? IORQ_n_i : 1'bZ;
	//assign RD_n   = BUSAK_n_i ? RD_n_i : 1'bZ;
	//assign WR_n   = BUSAK_n_i ? WR_n_i : 1'bZ;
	//assign RFSH_n = BUSAK_n_i ? RFSH_n_i : 1'bZ;
	//assign A      = BUSAK_n_i ? A_i : 16'bZ;

    logic RESET_n_i;
    // We need to delay RESET by one cycle to match the behavior of the true Z80
    always @(posedge CLK_n) RESET_n_i <= RESET_n;
    T80a_dido #(
        .Mode(0),
        .IOWait(1),
        .R800_mode(0)
    ) z80 (
        .RESET_n (RESET_n_i ),
        .CLK_n   (CLK_n     ),
        .WAIT_n  (WAIT_n    ),
        .INT_n   (INT_n     ),
        .NMI_n   (NMI_n     ),
        .BUSRQ_n (BUSRQ_n   ),
        .M1_n    (M1_n_i    ),
        .MREQ_n  (MREQ_n_i  ),
        .IORQ_n  (IORQ_n_i  ),
        .RD_n    (RD_n_i    ),
        .WR_n    (WR_n_i    ),
        .RFSH_n  (RFSH_n_i  ),
        .HALT_n  (HALT_n_i  ),
        .BUSAK_n (BUSAK_n_i ),
        .A       (A_i       ),
        .DI      (CPU_DI    ),
        .DO      (CPU_DO    ),
        .DO_EN_n (DO_EN_n   ),
        .DBG_out (DBG_out   )
    );

    // We compare our 'outputs' to the ones comeing from the outside. We'll have to be a bit careful though:
    // They only need to match on the appropriate edge of the clock
    logic fall_match;
    logic rise_match;
    logic ctrl_match;
    logic data_match;
    logic addr_match;

    assign ctrl_match =
        (M1_n_i == M1_n) &&
        (MREQ_n_i == MREQ_n) &&
        (IORQ_n_i == IORQ_n) &&
        (RD_n_i == RD_n) &&
        (WR_n_i == WR_n) &&
        (RFSH_n_i == RFSH_n) &&
        (HALT_n_i == HALT_n) &&
        (BUSAK_n_i == BUSAK_n);

    assign data_match = (CPU_DO == D) | DO_EN_n | (MREQ_n_i && IORQ_n_i);
    assign addr_match = A_i == A;
    always @(posedge CLK_n) begin
        rise_match <= ~RESET_n | ctrl_match; //& data_match & addr_match;
    end;

    always @(negedge CLK_n) begin
        fall_match <= ~RESET_n | ctrl_match; //& data_match & addr_match;
    end;

    logic match;
    assign match = rise_match && fall_match;

    assign io1a = M1_n_i;
    assign io1b = MREQ_n_i;
    assign io2a = IORQ_n_i;
    assign io2b = RD_n_i;
    assign io3a = WR_n_i;
    assign io3b = RFSH_n_i;
    assign io4a = data_match;
    //assign io4b = addr_match;
    assign io4b = CLK_n;

    assign io5a = ctrl_match;
    assign io5b = DO_EN_n;
    //assign io6a = 1'b0;
    //assign io6b = 1'b0;

    assign TXD = RXD; // Just to make PnR happy
endmodule

