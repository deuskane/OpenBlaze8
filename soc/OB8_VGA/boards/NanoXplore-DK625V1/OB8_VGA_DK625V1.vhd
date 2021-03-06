-------------------------------------------------------------------------------
-- Title      : OB8_VGA_DK625V1
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OB8_VGA_DK625V1.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-04-11
-- Last update: 2017-06-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-04-11  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;

entity OB8_VGA_DK625V1 is
  port (
    clk_i      : in  std_logic;
    arstn_i    : in  std_logic;

    switch_i   : in  std_logic_vector(5 downto 0);
    led_o      : out std_logic_vector(7 downto 0);

    vga_HSYNC_o: out std_logic;
    vga_VSYNC_o: out std_logic;
    vga_Red_o  : out std_logic;
    vga_Green_o: out std_logic;
    vga_Blue_o : out std_logic
);
end OB8_VGA_DK625V1;

architecture rtl of OB8_VGA_DK625V1 is 
  constant FSYS                       : positive:= 25_000_000;
  constant FSYS_INT                   : positive:= 25_000_000;

  signal vga_Red                      : std_logic_vector (2 downto 0);
  signal vga_Green                    : std_logic_vector (2 downto 0);
  signal vga_Blue                     : std_logic_vector (2 downto 1);
  
begin  -- architecture rtl

  ins_OB8_VGA : entity work.OB8_VGA(rtl)
    generic map
    (FSYS       => FSYS
    ,FSYS_INT   => FSYS_INT
    ,USE_KCPSM  => false
    ,NB_SWITCH  => 6
    ,NB_LED     => 8
    )
    port map
    (clk_i      => clk_i      
    ,arstn_i    => arstn_i
    ,switch_i   => switch_i   
    ,led_o      => led_o      
    ,vga_HSYNC_o=> vga_HSYNC_o
    ,vga_VSYNC_o=> vga_VSYNC_o
    ,vga_Red_o  => vga_Red
    ,vga_Green_o=> vga_Green
    ,vga_Blue_o => vga_Blue
     );

  vga_Red_o   <= vga_Red  (2);
  vga_Green_o <= vga_Green(2);
  vga_Blue_o  <= vga_Blue (2);
end architecture rtl;
    
  
