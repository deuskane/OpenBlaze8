-------------------------------------------------------------------------------
-- Title      : OB8_VGA_Basys1
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OB8_VGA_Basys1.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-05-01
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
library work;

entity OB8_VGA_Basys1 is
  port (
    clk_i      : in  std_logic;
    arst_i     : in  std_logic;

    switch_i   : in  std_logic_vector(7 downto 0);
    led_o      : out std_logic_vector(7 downto 0);

    vga_HSYNC_o: out std_logic;
    vga_VSYNC_o: out std_logic;
    vga_Red_o  : out std_logic_vector (2 downto 0);
    vga_Green_o: out std_logic_vector (2 downto 0);
    vga_Blue_o : out std_logic_vector (2 downto 1)
);
end OB8_VGA_Basys1;

architecture rtl of OB8_VGA_Basys1 is 
  constant FSYS                       : positive:= 50_000_000;
  constant FSYS_INT                   : positive:= 50_000_000;

  signal arstn                        : std_logic;
  
  signal vga_Red                      : std_logic_vector (2 downto 0);
  signal vga_Green                    : std_logic_vector (2 downto 0);
  signal vga_Blue                     : std_logic_vector (2 downto 1);
  
begin  -- architecture rtl

  arstn <= not arst_i;
  
  ins_OB8_VGA : entity work.OB8_VGA(rtl)
    generic map
    (FSYS       => FSYS
    ,FSYS_INT   => FSYS_INT
    ,USE_KCPSM  => false
    ,NB_SWITCH  => 8
    ,NB_LED     => 8
    )
    port map
    (clk_i      => clk_i      
    ,arstn_i    => arstn
    ,switch_i   => switch_i   
    ,led_o      => led_o      
    ,vga_HSYNC_o=> vga_HSYNC_o
    ,vga_VSYNC_o=> vga_VSYNC_o
    ,vga_Red_o  => vga_Red
    ,vga_Green_o=> vga_Green
    ,vga_Blue_o => vga_Blue
     );

  vga_Red_o   <= vga_Red  (2) & vga_Red  (1) & "0";
  vga_Green_o <= vga_Green(2) & vga_Green(1) & "0";
  vga_Blue_o  <= vga_Blue (2) & vga_Blue (1);  
end architecture rtl;
    
  
