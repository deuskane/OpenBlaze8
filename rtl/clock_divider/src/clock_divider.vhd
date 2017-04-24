-------------------------------------------------------------------------------
-- Title      : Clock Divider
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : clock_divider.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2017-04-24
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
    generic(RATIO        : positive := 2
            );
    port   (clk_i        : in  std_logic;
            cke_i        : in  std_logic;
            arstn_i      : in  std_logic;
            clk_div_o    : out std_logic);
end clock_divider;

architecture rtl of clock_divider is
  signal clock_count : natural range 0 to RATIO-1;
  signal clock_div   : std_logic;
begin

  gen_ratio_eq_1: if RATIO=1 generate
  clk_div_o <= clk_i;
  end generate gen_ratio_eq_1;

  gen_ratio_gt_1: if RATIO > 1 generate
  process(arstn_i,clk_i)
  begin 
    if arstn_i='0'
    then
      clock_count <= 0;
      clock_div   <= '0';
    elsif rising_edge(clk_i)
    then
      if (cke_i = '1')
      then
        -- decrease clock diviser
        if (clock_count = RATIO-1)
        then
          clock_count <= 0;
          clock_div   <= '1';
        else
          clock_count <= clock_count+1;
          clock_div   <= '0';
        end if;
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
  end generate gen_ratio_gt_1;
end rtl;

