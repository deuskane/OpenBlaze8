-------------------------------------------------------------------------------
-- Title      : stack_pkg
-- Project    : stack
-------------------------------------------------------------------------------
-- File       : stack_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2017-03-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-11  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package stack_pkg is

  component stack is
    -- =====[ Parameters ]==========================
    generic (
      WIDTH     : natural := 32;
      DEPTH     : natural := 4;
      OVERWRITE : natural := 0
      );
    -- =====[ Interfaces ]==========================
    port (
      clk_i       : in  std_logic;
      cke_i       : in  std_logic;
      arstn_i     : in  std_logic;
      -- Stack push
      push_val_i  : in  std_logic;
      push_ack_o  : out std_logic;
      push_data_i : in  std_logic_vector(WIDTH -1 downto 0);
      -- Stack pop
      pop_val_o   : out std_logic;
      pop_ack_i   : in  std_logic;
      pop_data_o  : out std_logic_vector(WIDTH -1 downto 0)
      );
  end component;
  
end package stack_pkg;
