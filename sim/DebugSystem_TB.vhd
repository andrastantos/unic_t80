library IEEE;
use IEEE.std_logic_1164.all;
use std.env.stop;

entity DebugSystem_TB is
end entity DebugSystem_TB;

architecture behaviour of DebugSystem_TB is

	signal Reset_n		: std_logic;
	signal Clk			: std_logic := '0';
	signal NMI_n		: std_logic := '1';
	signal INT_n		: std_logic := '1';

begin

	ni : entity work.DebugSystem
		port map(
			Reset_n => Reset_n,
			Clk => Clk,
			NMI_n => NMI_n,
			INT_n => INT_n
		);


	Reset_n <= '0', '1' after 1 us;

	-- NMI_n <= '1', '0' after 2000 ns;
	-- INT_n <= '1', '0' after 2500 ns;

	Clk <= not Clk after 5 ns;

	--terminate: process
	--begin
	--	wait for 5*100000*2 ns;
	--	stop;
	--end process terminate;
end;
