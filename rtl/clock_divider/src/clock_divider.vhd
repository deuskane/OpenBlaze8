-------------------------------------------------------------------------------
-- Title      : Clock Divider
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : clock_divider.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2017-03-31
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-07-12  1.1      rosière	Change Port name
-- 2013-12-26  1.0      rosière	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity clock_divider is
    generic(ratio        : positive := 2
            );
    port   (clk_i        : in  std_logic;
            arstn_i      : in  std_logic;
            clk_div_o    : out std_logic);
end clock_divider;

architecture rtl of clock_divider is
  signal clock_count : integer range 0 to ratio-1;
  signal clock_div   : std_logic;
begin

  process(arstn_i,clk_i)
  begin 
    if arstn_i='0' then
      clock_count <= 0;
      clock_div   <= '0';
    elsif rising_edge(clk_i) then

      -- decrease clock diviser
      if (clock_count = ratio-1) then
        clock_count <= 0;
        clock_div   <= '1';
      else
        clock_count <= clock_count+1;
        clock_div   <= '0';
      end if;
    end if;
  end process;

  --clk_div_o <= clock_div;
  ins_gated_clock : entity work.gated_clock(rtl)
    port map (
      clk_i       => clk_i,
      cmd_i       => clock_div,
      clk_gated_o => clk_div_o
      );
  
end rtl;

