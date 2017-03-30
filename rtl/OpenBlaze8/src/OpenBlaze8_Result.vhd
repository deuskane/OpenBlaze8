-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Result
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Result.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-05-21
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
-- 2014-05-21  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_Result is
  -- =====[ Parameters ]==========================
  generic (
     size_data      : natural := 8);
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

    result_mux_i         : in  std_logic_vector(2 downto 1); -- 00 : io, 01 ram, else alu

    alu_res_i            : in  std_logic_vector(size_data downto 1);
    ram_fetch_data_i     : in  std_logic_vector(size_data downto 1);
    io_input_data_i      : in  std_logic_vector(size_data downto 1);

    res_o                : out std_logic_vector(size_data downto 1)
    );
end OpenBlaze8_Result;

architecture rtl of OpenBlaze8_Result is
  
begin  -- rtl
  -----------------------------------------------------------------------------
  -- Result output
  -----------------------------------------------------------------------------

  res_o <= alu_res_i        when result_mux_i(2) = '1' else
           ram_fetch_data_i when result_mux_i(1) = '1' else
           io_input_data_i;
  
  
end rtl;
