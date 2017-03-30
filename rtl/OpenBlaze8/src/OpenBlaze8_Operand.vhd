-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Operand
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Operand.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-05-20
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
-- 2014-05-20  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_Operand is
  -- =====[ Parameters ]==========================
  generic (
     size_data      : natural := 8);
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

    decode_operand_mux_i : in  std_logic;  -- 0 : register, 1 immediat
    decode_imm_i         : in  std_logic_vector(size_data downto 1);

    reg_op1_i            : in  std_logic_vector(size_data downto 1);
    reg_op2_i            : in  std_logic_vector(size_data downto 1);
    
    operand_op1_o        : out std_logic_vector(size_data downto 1);
    operand_op2_o        : out std_logic_vector(size_data downto 1)
    );
end OpenBlaze8_Operand;

architecture rtl of OpenBlaze8_Operand is
  
begin  -- rtl
  -----------------------------------------------------------------------------
  -- Operand output
  -----------------------------------------------------------------------------
  operand_op1_o <= reg_op1_i;
  operand_op2_o <= reg_op2_i when decode_operand_mux_i = '1' else decode_imm_i;

  
end rtl;
