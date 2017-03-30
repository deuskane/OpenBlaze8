-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Stack
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Stack.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-05-21
-- Last update: 2017-03-14
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-05-21  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;
use work.stack_pkg.all;

entity OpenBlaze8_Stack is
  -- =====[ Parameters ]==========================
  generic (
     size_stack     : natural := 32;
     size_addr_inst : natural := 10
   );
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

    stack_push_val_i     : in  std_logic;
    stack_push_data_i    : in  std_logic_vector(size_addr_inst downto 1);  -- Stack push data

    stack_pop_ack_i      : in  std_logic;
    stack_pop_data_o     : out std_logic_vector(size_addr_inst downto 1)  -- Stack push data
    );
end OpenBlaze8_Stack;

architecture rtl of OpenBlaze8_Stack is

  signal resetn             : std_logic;
  signal stack_push_ack     : std_logic;
  signal stack_pop_val      : std_logic;
  
begin  -- rtl

  resetn <= not reset_i;
  -----------------------------------------------------------------------------
  -- Stack output
  -----------------------------------------------------------------------------
  ins_stack : stack
  -- =====[ Parameters ]==========================
  generic map(
     WIDTH     => size_addr_inst
    ,DEPTH     => size_stack
    ,OVERWRITE => 1
     )
  -- =====[ Interfaces ]==========================
  port map(
    clk_i       => clock_i         
   ,cke_i       => clock_enable_i  
   ,arstn_i     => resetn          
   ,push_val_i  => stack_push_val_i
   ,push_ack_o  => stack_push_ack  
   ,push_data_i => stack_push_data_i
   ,pop_val_o   => stack_pop_val   
   ,pop_ack_i   => stack_pop_ack_i 
   ,pop_data_o  => stack_pop_data_o

    
    );

end rtl;
