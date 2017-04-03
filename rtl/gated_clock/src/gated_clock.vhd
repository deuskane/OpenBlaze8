-------------------------------------------------------------------------------
-- Title      : Gated Clock
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : gated_clock.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2017-03-31
-- Last update: 2017-04-03
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-31  1.0      rosière	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity gated_clock is
    port   (clk_i        : in  std_logic;
            cmd_i        : in  std_logic;
            clk_gated_o  : out std_logic);
end gated_clock;

architecture rtl of gated_clock is
  signal cmd_l : std_logic;
begin
  
  -- Latch 
  process (clk_i,cmd_i) is
  begin  -- process
    if clk_i = '0'
    then
      cmd_l <= cmd_i;
    end if;
  end process;

  -- Gated output
  clk_gated_o <= clk_i and cmd_l;
  
end rtl;

