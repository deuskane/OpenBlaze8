-------------------------------------------------------------------------------
-- Title      : tb_OB8_GPIO
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_OB8_GPIO.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-04-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-30  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_OB8_GPIO is
  
end entity tb_OB8_GPIO;

architecture tb of tb_OB8_GPIO is
    signal clk_i      : std_logic := '0';
    signal arstn_i    : std_logic;
    signal switch_i   : std_logic_vector(7 downto 0);
    signal led_o      : std_logic_vector(7 downto 0);
begin  -- architecture tb

  dut : entity work.OB8_GPIO(rtl)
  port map(
    clk_i      => clk_i   ,
    arstn_i    => arstn_i ,
    switch_i   => switch_i,
    led_o      => led_o   
    );


  clk_i <= not clk_i after 10ns;

  process is
  begin  -- process

      arstn_i <= '0';
        
      wait for 20ns;

      arstn_i <= '1';

      switch_i <= "01010110";

      wait for 10000ns;
        
  end process;
    
  

end architecture tb;
