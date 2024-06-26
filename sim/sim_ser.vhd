--
-- Asynchronous serial input with binary file log
--
-- Version : 0146
--
-- Copyright (c) 2001 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--       http://www.opencores.org/cvsweb.shtml/t51/
--
-- Limitations :
--
-- File history :
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sim_ser is
    generic(
        FileName              : string
    );
    port(
--              Clk        : in std_logic;
        CS_n       : in std_logic;
        Rd_n       : in std_logic;
        Wr_n       : in std_logic;
        A          : in std_logic_vector(2 downto 0);
        D_In       : in std_logic_vector(7 downto 0);
        D_Out      : out std_logic_vector(7 downto 0)
    );
end sim_ser;

architecture behaviour of sim_ser is

    function to_char(
        constant Byte : std_logic_vector(7 downto 0)
    ) return character is
    begin
        return character'val(to_integer(unsigned(Byte)));
    end function;

    signal last_data: std_logic_vector(7 downto 0);
begin

    process (CS_n, Rd_n, Wr_n)
        type ChFile is file of character;
        file OutFile : ChFile open write_mode is FileName;
    begin
        if CS_n'event or Rd_n'event or Wr_n'event then
            if CS_n = '0' then
                if Rd_n = '0' then
                    -- READ logic
                    D_Out <= "00000000";
                elsif Wr_n = '0' then
                    -- WRITE logic
                    case A is
                    when "000" | "001" =>
                        last_data <= D_In;
                        write(OutFile, to_char(D_In));
                        flush(OutFile);
                    when others =>
                        null;
                    end case;
                end if;
            end if;
        end if;
    end process;
end;

