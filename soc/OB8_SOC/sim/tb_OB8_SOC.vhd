-------------------------------------------------------------------------------
-- Title      : tb_OB8_SOC
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_OB8_SOC.vhd
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

entity tb_OB8_SOC is
  
end entity tb_OB8_SOC;

architecture tb of tb_OB8_SOC is
    signal clk_i            : std_logic := '0';
    signal arstn_i          : std_logic;
    signal switch_i         : std_logic_vector(7 downto 0);
    signal led_o            : std_logic_vector(7 downto 0);
    signal vga_HSYNC_o      : std_logic;
    signal vga_VSYNC_o      : std_logic;
    signal vga_Red_o        : std_logic_vector (2 downto 0);
    signal vga_Green_o      : std_logic_vector (2 downto 0);
    signal vga_Blue_o       : std_logic_vector (2 downto 1);
    signal sRX_i            : std_logic;
    signal sTX_o            : std_logic;
    signal bdr_o            : std_logic;
begin  -- architecture tb

  dut : entity work.OB8_SOC(rtl)
  port map(
    clk_i      => clk_i      ,
    arstn_i    => arstn_i    ,
    switch_i   => switch_i   ,
    led_o      => led_o      ,
    vga_HSYNC_o=> vga_HSYNC_o,
    vga_VSYNC_o=> vga_VSYNC_o,
    vga_Red_o  => vga_Red_o  ,
    vga_Green_o=> vga_Green_o,
    vga_Blue_o => vga_Blue_o ,
    sRX_i      => sRX_i      ,
    sTX_o      => sTX_o      ,
    bdr_o      => bdr_o

    );

  clk_i <= not clk_i after 10ns;

  process is
  begin  -- process

      arstn_i <= '0';
        
      wait for 20ns;

      arstn_i <= '1';

      switch_i <= "10010110";
      sRX_i    <= '0';
      
      wait;
        
  end process;
    
  

end architecture tb;
