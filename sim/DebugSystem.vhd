-- Z80, Monitor ROM, 4k RAM and two 16450 UARTs
-- that can be synthesized and used with
-- the NoICE debugger that can be found at
-- http://www.noicedebugger.com/

-- NOTES:
-- There's a visual (netlist-based) reference here: https://floooh.github.io/visualz80remix/
-- the corresponding writeup is here: https://floooh.github.io/2021/12/06/z80-instruction-timing.html
-- This confirms that prefixed instructions generate two M1-cycles, in fact two referesh cycles as well.A
--
-- It also confirms that LDIR (and presumably all other similar ones) re-read the instruction (with M1 and refersh cycles)
-- for every iteration.

library IEEE;
use IEEE.std_logic_1164.all;
use STD.textio.all;
use STD.env.stop;
use ieee.numeric_std.all;

entity DebugSystem is
    port(
        Reset_n        : in std_logic;
        Clk            : in std_logic;
        NMI_n          : in std_logic;
        INT_n          : in std_logic
    );
end DebugSystem;

architecture struct of DebugSystem is

    signal M1_n            : std_logic;
    signal MREQ_n        : std_logic;
    signal IORQ_n        : std_logic;
    signal RD_n            : std_logic;
    signal WR_n            : std_logic;
    signal RFSH_n        : std_logic;
    signal HALT_n        : std_logic;
    signal WAIT_n        : std_logic;
    signal RESET_s        : std_logic;
    signal BUSRQ_n        : std_logic;
    signal BUSAK_n        : std_logic;
    signal A            : std_logic_vector(15 downto 0);
    signal D            : std_logic_vector(7 downto 0);
    signal ROM_D        : std_logic_vector(7 downto 0);
    signal SRAM_D        : std_logic_vector(7 downto 0);
    signal UART0_D        : std_logic_vector(7 downto 0);
    signal CPU_D        : std_logic_vector(7 downto 0);

    signal Mirror        : std_logic;

    signal IOWR_n        : std_logic;
    signal RAMCS_n        : std_logic;
    signal ROMCS_n        : std_logic;
    signal UART0CS_n    : std_logic;

    signal BaudOut0        : std_logic;

    file sim_log            : text open write_mode is "sim.log";

    signal wait_cnt : unsigned(7 downto 0);

begin

    --Wait_n <= '1';
    BusRq_n <= '1';

    -- Wait timer
    -- This version adds 5 wait-states to every cycle
    --process (Reset_n, Clk)
    --begin
    --    if Reset_n = '0' then
    --        wait_cnt <= (others => '0');
    --    elsif Clk'event and Clk = '1' then
    --        if MREQ_n = '0' then
    --            wait_cnt <= wait_cnt + 1;
    --            if wait_cnt > 5 then
    --                WAIT_n <= '1';
    --            else
    --                WAIT_n <= '0';
    --            end if;
    --        else
    --            wait_cnt <= (others => '0');
    --            WAIT_n <= '1';
    --        end if;
    --    end if;
    --end process;

    -- This version creates a 25% duty-cycle free-running counter
    process (Reset_n, Clk)
    begin
        if Reset_n = '0' then
            wait_cnt <= (others => '0');
        elsif Clk'event and Clk = '1' then
            wait_cnt <= wait_cnt + 1;
            if wait_cnt = 3 then
                wait_cnt <= (others => '0');
                WAIT_n <= '1';
            else
                WAIT_n <= '0';
            end if;
        end if;
    end process;


    process (Reset_n, Clk)
    begin
        if Reset_n = '0' then
            Reset_s <= '0';
            Mirror <= '0';
        elsif Clk'event and Clk = '1' then
            Reset_s <= '1';
            if IORQ_n = '0' and WR_n = '0' then
                case A(7 downto 0) is
                when "11111110" => -- write to I/O address 0xfe sets the 'mirror' bit from D0
                    Mirror <= D(0);
                when "11111111" => -- write to I/O address 0xff terminates the simulation
                    stop;
                when others => null;
                end case;
            end if;
        end if;
    end process;

    IOWR_n    <= WR_n or IORQ_n;
    RAMCS_n   <= '0' when Mirror /= A(15) and MREQ_n = '0' else '1'; -- RAM is from 0x8000 if Mirror is '0', 0x0000 otherwise
    ROMCS_n   <= '0' when Mirror  = A(15) and MREQ_n = '0' else '1'; -- ROM is from 0x0000 if Mirror is '0', 0x8000 otherwise
    UART0CS_n <= '0' when IORQ_n = '0' and A(7 downto 3) = "00000" else '1'; -- 0x00 - 0x07

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

    CPU_D <=
        SRAM_D when RAMCS_n = '0' else
        ROM_D when ROMCS_n = '0' else
        UART0_D when UART0CS_n = '0' else
        "XXXXXXXX";
    D <= CPU_D when RD_n = '0' else "ZZZZZZZZ";

    z80 : entity work.T80a
            generic map(Mode => 1, IOWait => 1, R800_mode => 0)
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

    rom : entity work.ROM
            generic map(
                AddrWidth => 15)
            port map(
                Clk => Clk,
                CE_n => ROMCS_n,
                WE_n => WR_n,
                A => A(14 downto 0),
                DIn => D,
                DOut => ROM_D);

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

    uart : entity work.sim_ser
            generic map(
				FileName => "../_out/uart0_rx.log"
			)
            port map(
                CS_n => UART0CS_n,
                Rd_n => RD_n,
                Wr_n => IOWR_n,
                A => A(2 downto 0),
                D_In => D,
                D_Out => UART0_D);
end;
