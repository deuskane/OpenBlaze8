-------------------------------------------------------------------------------
-- Title      : OB8_TIMER_Basys1
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OB8_TIMER_Basys1.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-04-30
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
-- 2017-04-30  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OB8_TIMER_Basys1 is
  generic (
    FSYS       : positive:= 50_000_000;
    FSYS_INT   : positive:= 50_000_000
    );
  port (
    clk_i      : in  std_logic;
    arst_i     : in  std_logic;

    switch_i   : in  std_logic_vector(7 downto 0);
    led_o      : out std_logic_vector(7 downto 0)
);
end OB8_TIMER_Basys1;

architecture rtl of OB8_TIMER_Basys1 is

  signal arstn : std_logic;
  
begin  -- architecture rtl

  arstn <= not arst_i;
  
  ins_OB8_TIMER : entity work.OB8_TIMER(rtl)
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
    );

end architecture rtl;
