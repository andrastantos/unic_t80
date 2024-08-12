-- Z80, 16k RAM (initalized) and an 16450 UARTs
-- that can be synthesized. It also exposes all
-- Z80 pins so it can be integrated into an existing socket
-- RAM is mapped to address 0
-- UART is mapped to I/O address 0x88

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- synthesis translate_off
use STD.textio.all;
use std.env.stop;
-- synthesis translate_on

entity soc_top is
	generic(
		RAM_BASE      : integer := 0;
		UART_BASE     : integer := 16#88#;
        SIM_UART_BASE : integer := 0
	);
	port(
        -- Z80 signals
        -- For now, all inputs are tied to something inert inside
		RESET_n         : in std_logic;
		--CLK_n        : in  std_logic; -- We don't have the clock input on it's normal location; it's mapped to the internal 27MHz oscillator
		--WAIT_n          : in std_logic;
		INT_n           : in std_logic;
		NMI_n           : in std_logic;
		--BUSRQ_n         : in std_logic;
		M1_n            : out std_logic;
		MREQ_n          : out std_logic;
		IORQ_n          : out std_logic;
		RD_n            : out std_logic;
		WR_n            : out std_logic;
		RFSH_n          : out std_logic;
		HALT_n          : out std_logic;
		BUSAK_n         : out std_logic;
		A               : out std_logic_vector(15 downto 0);
		D               : inout std_logic_vector(7 downto 0);

        -- UART signals
        RXD             : in std_logic;
        TXD             : out std_logic;

        -- The true clock
        CLK27           : in std_logic
    );
end soc_top;

architecture struct of soc_top is
    signal WAIT_n: std_logic;
    signal BUSRQ_n: std_logic;
    signal CLK: std_logic;


    signal RESET_s        : std_logic;
    signal ROM_D        : std_logic_vector(7 downto 0);
    signal SRAM_D        : std_logic_vector(7 downto 0);
    signal UART_D        : std_logic_vector(7 downto 0);
    signal SIM_UART_D        : std_logic_vector(7 downto 0);
    signal CPU_DI        : std_logic_vector(7 downto 0);
    signal CPU_DO        : std_logic_vector(7 downto 0);

    signal DO_EN_n       : std_logic;

    signal IOWR_n        : std_logic;
    signal RAMCS_n        : std_logic;
    signal UARTCS_n     : std_logic;
    signal SIM_UARTCS_n     : std_logic;

    signal BaudOut        : std_logic;

    signal SUART_BASE    : std_logic_vector(7 downto 0);
    signal SSIM_UART_BASE : std_logic_vector(7 downto 0);
    signal SRAM_BASE       : std_logic_vector(15 downto 0);

    signal I_M1_n            : std_logic;
    signal I_MREQ_n          : std_logic;
    signal I_IORQ_n          : std_logic;
    signal I_RD_n            : std_logic;
    signal I_WR_n            : std_logic;
    signal I_RFSH_n          : std_logic;
    signal I_HALT_n          : std_logic;
    signal I_BUSAK_n         : std_logic;
    signal I_A               : std_logic_vector(15 downto 0);

begin
    CLK <= CLK27;

    WAIT_n <= '1';
    BUSRQ_n <= '1';


    SUART_BASE <= std_logic_vector(to_unsigned(UART_BASE, 8));
    SSIM_UART_BASE <= std_logic_vector(to_unsigned(SIM_UART_BASE, 8));
    SRAM_BASE <= std_logic_vector(to_unsigned(RAM_BASE, 16));

    process (Reset_n, Clk)
    begin
        if Reset_n = '0' then
            Reset_s <= '0';
        elsif Clk'event and Clk = '1' then
            Reset_s <= '1';
        end if;
    end process;

    -- synthesis translate_off
    process (Clk)
    begin
        if rising_edge(Clk) then
            if I_IORQ_n = '0' and I_WR_n = '0' then
                case I_A(7 downto 0) is
                when "11111111" => -- write to I/O address 0xff terminates the simulation
                    stop;
                when others => null;
                end case;
            end if;
        end if;
    end process;
    -- synthesis translate_on

    IOWR_n       <= I_WR_n or I_IORQ_n;
    RAMCS_n      <= '0' when I_MREQ_n = '0' and I_A(15 downto 14) = SRAM_BASE(15 downto 14) else '1';
    UARTCS_n     <= '0' when I_IORQ_n = '0' and I_A(7 downto 3) = SUART_BASE(7 downto 3) else '1';
    -- synthesis translate_off
    SIM_UARTCS_n <= '0' when I_IORQ_n = '0' and I_A(7 downto 3) = SSIM_UART_BASE(7 downto 3) else '1';
    -- synthesis translate_on

    -- synthesis translate_off
    process (CLK)
        variable log_row          : line;
    begin
        if Clk'event and Clk = '0' then
            if M1_n = '0' and RD_n = '0' then
                --report "M1 at address 0x" & to_hstring(A) & " value 0x" & to_hstring(D);
                --write(log_row, "M1 at address 0x" & to_hstring(A) & " value 0x" & to_hstring(D));
                --writeline(sim_log,log_row);
            end if;
        end if;
    end process;
    -- synthesis translate_on

    CPU_DI <=
        SRAM_D when RAMCS_n = '0' else
        UART_D when UARTCS_n = '0' else
        -- synthesis translate_off
        SIM_UART_D when SIM_UARTCS_n = '0' else
        -- synthesis translate_on
        D;
    D <= CPU_DO when DO_EN_n = '0' else (others => 'Z');

    z80 : entity work.T80a_dido
            generic map(Mode => 0, IOWait => 1, R800_mode => 0)
            port map(
                RESET_n => RESET_s,
                CLK_n   => Clk,
                WAIT_n  => WAIT_n,
                INT_n   => INT_n,
                NMI_n   => NMI_n,
                BUSRQ_n => BUSRQ_n,
                M1_n    => I_M1_n,
                MREQ_n  => I_MREQ_n,
                IORQ_n  => I_IORQ_n,
                RD_n    => I_RD_n,
                WR_n    => I_WR_n,
                RFSH_n  => I_RFSH_n,
                HALT_n  => I_HALT_n,
                BUSAK_n => I_BUSAK_n,
                A       => I_A,
                DI      => CPU_DI,
                DO      => CPU_DO,
                DO_EN_n => DO_EN_n);

    M1_n            <= I_M1_n;
    MREQ_n          <= I_MREQ_n;
    IORQ_n          <= I_IORQ_n;
    RD_n            <= I_RD_n;
    WR_n            <= I_WR_n;
    RFSH_n          <= I_RFSH_n;
    HALT_n          <= I_HALT_n;
    BUSAK_n         <= I_BUSAK_n;
    A               <= I_A;

    sram : entity work.SSRAM_with_init
            generic map(
                AddrWidth => 14)
            port map(
                Clk => Clk,
                CE_n => RAMCS_n,
                WE_n => I_WR_n,
                A => I_A(13 downto 0),
                DIn => CPU_DO,
                DOut => SRAM_D);

    uart : entity work.T16450
            port map(
                MR_n => Reset_s,
                XIn => Clk,
                RClk => BaudOut,
                CS_n => UARTCS_n,
                Rd_n => I_RD_n,
                Wr_n => IOWR_n,
                A => I_A(2 downto 0),
                D_In => CPU_DO,
                D_Out => UART_D,

                SIn => RXD,
                CTS_n => '1',
                DSR_n => '1',
                RI_n => '1',
                DCD_n => '1',
                SOut => TXD,
                RTS_n => open,
                DTR_n => open,
                OUT1_n => open,
                OUT2_n => open,
                BaudOut => BaudOut,
                Intr => open);

    -- synthesis translate_off
    sim_uart : entity work.sim_ser
            generic map(
                FileName => "../_out/uart0_rx.log"
            )
            port map(
                CS_n => SIM_UARTCS_n,
                Rd_n => I_RD_n,
                Wr_n => I_WR_n,
                A => A(2 downto 0),
                D_In => CPU_DO,
                D_Out => SIM_UART_D);
    -- synthesis translate_on

end;
