-- Z80, Monitor ROM, 4k RAM and two 16450 UARTs
-- that can be synthesized and used with
-- the NoICE debugger that can be found at
-- http://www.noicedebugger.com/

library IEEE;
use IEEE.std_logic_1164.all;

entity DebugSystem is
	port(
		Reset_n		: in std_logic;
		Clk			: in std_logic;
		NMI_n		: in std_logic;
		RXD0		: in std_logic;
		CTS0		: in std_logic;
		DSR0		: in std_logic;
		RI0			: in std_logic;
		DCD0		: in std_logic;
		TXD0		: out std_logic;
		RTS0		: out std_logic;
		DTR0		: out std_logic
	);
end DebugSystem;

architecture struct of DebugSystem is

	signal M1_n			: std_logic;
	signal MREQ_n		: std_logic;
	signal IORQ_n		: std_logic;
	signal RD_n			: std_logic;
	signal WR_n			: std_logic;
	signal RFSH_n		: std_logic;
	signal HALT_n		: std_logic;
	signal WAIT_n		: std_logic;
	signal INT_n		: std_logic;
	signal RESET_s		: std_logic;
	signal BUSRQ_n		: std_logic;
	signal BUSAK_n		: std_logic;
	signal A			: std_logic_vector(15 downto 0);
	signal D			: std_logic_vector(7 downto 0);
	signal ROM_D		: std_logic_vector(7 downto 0);
	signal SRAM_D		: std_logic_vector(7 downto 0);
	signal UART0_D		: std_logic_vector(7 downto 0);
	signal CPU_D		: std_logic_vector(7 downto 0);

	signal Mirror		: std_logic;

	signal IOWR_n		: std_logic;
	signal RAMCS_n		: std_logic;
	signal UART0CS_n	: std_logic;

	signal BaudOut0		: std_logic;

begin

	Wait_n <= '1';
	BusRq_n <= '1';
	INT_n <= '1';

	process (Reset_n, Clk)
	begin
		if Reset_n = '0' then
			Reset_s <= '0';
			Mirror <= '0';
		elsif Clk'event and Clk = '1' then
			Reset_s <= '1';
			if IORQ_n = '0' and A(7 downto 4) = "1111" then -- write to I/O address 0xf0 sets the 'mirror' bit from D0
				Mirror <= D(0);
			end if;
		end if;
	end process;

	IOWR_n <= WR_n or IORQ_n;
	RAMCS_n <= (not Mirror and not A(15)) or MREQ_n; -- RAM is from 0x8000 if Mirror is '0', 0x0000 otherwise
	UART0CS_n <= '0' when IORQ_n = '0' and A(7 downto 3) = "00000" else '1'; -- 0x00 - 0x07

	CPU_D <=
		SRAM_D when RAMCS_n = '0' else
		UART0_D when UART0CS_n = '0' else
		ROM_D;
	D <= CPU_D when RD_n = '0' else "ZZZZZZZZ";

	z80 : entity work.T80a
			generic map(Mode => 1, IOWait => 0, R800_mode => 0)
			port map(
				RESET_n => RESET_s,
				CLK_n => Clk,
				WAIT_n => WAIT_n,
				INT_n => INT_n,
				NMI_n => NMI_n,
				BUSRQ_n => BUSRQ_n,
				M1_n => M1_n,
				MREQ_n => MREQ_n,
				IORQ_n => IORQ_n,
				RD_n => RD_n,
				WR_n => WR_n,
				RFSH_n => RFSH_n,
				HALT_n => HALT_n,
				BUSAK_n => BUSAK_n,
				A => A,
				D => D);

	rom : entity work.rom
			port map(
				Clk => Clk,
				A => A(14 downto 0),
				D => ROM_D);

	sram : entity work.SSRAM
			generic map(
				AddrWidth => 15)
			port map(
				Clk => Clk,
				CE_n => RAMCS_n,
				WE_n => WR_n,
				A => A(14 downto 0),
				DIn => D,
				DOut => SRAM_D);

	uart : entity work.T16450
			port map(
				MR_n => Reset_s,
				XIn => Clk,
				RClk => BaudOut0,
				CS_n => UART0CS_n,
				Rd_n => RD_n,
				Wr_n => IOWR_n,
				A => A(2 downto 0),
				D_In => D,
				D_Out => UART0_D,
				SIn => RXD0,
				CTS_n => CTS0,
				DSR_n => DSR0,
				RI_n => RI0,
				DCD_n => DCD0,
				SOut => TXD0,
				RTS_n => RTS0,
				DTR_n => DTR0,
				OUT1_n => open,
				OUT2_n => open,
				BaudOut => BaudOut0,
				Intr => open);
end;
