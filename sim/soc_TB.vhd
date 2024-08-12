library IEEE;
use IEEE.std_logic_1164.all;
use std.env.stop;

entity soc_TB is
end entity soc_TB;

architecture behaviour of soc_TB is

	signal Reset_n		: std_logic;
	signal Clk			: std_logic := '0';
    signal rxd          : std_logic := '0';
    signal txd          : std_logic;
    signal int_n        : std_logic;
    signal nmi_n        : std_logic;
begin

	dut : entity work.soc_top
		port map(
			Reset_n => Reset_n,
			Clk27 => Clk,

    		INT_n   => int_n,
	    	NMI_n   => nmi_n,

            M1_n    => open,
            MREQ_n  => open,
            IORQ_n  => open,
            RD_n    => open,
            WR_n    => open,
            RFSH_n  => open,
            HALT_n  => open,
            BUSAK_n => open,
            A       => open,
            D       => open,

            -- UART signals
            RXD     => rxd,
            TXD     => txd
    );


	Reset_n <= '0', '1' after 1 us;
    -- These two are generating an interrupt and an NMI
    nmi_n <= '1', '0' after 2 us;
    int_n <= '1', '0' after 4 us;

    -- Running off of a 27MHz clock.
	Clk <= not Clk after 18.5 ns;

	terminate: process
	begin
		wait for 100 us;
		stop;
	end process terminate;
end;
