-------------------------------------------------------------------------------
-- Title      : OB8_UART_DK625V0
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OB8_UART_DK625V0.vhd
-- Author     : Cédric DEBARGE
-- Company    :
-- Created    : 2017-03-31
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
-- 2017-03-31  1.0      cdebarge Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;

entity OB8_UART_DK625V0 is
  port (
    clk_i    : in  std_logic;
    arstn_i  : in  std_logic;

    -- GPIOs
    switch_i : in  std_logic_vector(5 downto 0);
    led_o    : out std_logic_vector(7 downto 0);

    --UART
    srx_i    : in std_logic;
    stx_o    : out std_logic;
    bdr_o    : out std_logic
    );
end OB8_UART_DK625V0;

architecture rtl of OB8_UART_DK625V0 is
  constant FSYS       : positive := 50_000_000;
  constant FSYS_INT   : positive := 50_000_000;

begin  -- architecture rtl
  ins_OB8_UART : entity work.OB8_UART(rtl)
  generic map
    (FSYS      => FSYS    
    ,FSYS_INT  => FSYS_INT
    ,USE_KCPSM => false
    ,NB_SWITCH => 6
    ,NB_LED    => 8
    )
  port
    (clk_i    => clk_i   
    ,arstn_i  => arstn_i 
    ,switch_i => switch_i
    ,led_o    => led_o   
    ,srx_i    => srx_i   
    ,stx_o    => stx_o   
    ,bdr_o    => bdr_o   
    );

end architecture rtl;
