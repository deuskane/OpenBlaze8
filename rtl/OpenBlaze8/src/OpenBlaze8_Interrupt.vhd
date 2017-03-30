-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Interrupt
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Interrupt.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-05-22
-- Last update: 2016-11-20
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-05-22  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_Interrupt is
  -- =====[ Interfaces ]==========================
  port (
    clock_i                    : in  std_logic;
    clock_enable_i             : in  std_logic;
    reset_i                    : in  std_logic; -- synchronous reset

    interrupt_enable_i         : in  std_logic;  -- eint or reti enable
    interrupt_disable_i        : in  std_logic;  -- dint or reti disable
    
    it_en_o                    : out std_logic;  -- Have an interruption

    interrupt_i                : in  std_logic;
    interrupt_ack_o            : out std_logic    
    );
end OpenBlaze8_Interrupt;

architecture rtl of OpenBlaze8_Interrupt is
  
begin  -- rtl
  -----------------------------------------------------------------------------
  -- Interrupt output
  -----------------------------------------------------------------------------
  it_en_o         <= '0';
  interrupt_ack_o <= '0';
  
end rtl;
