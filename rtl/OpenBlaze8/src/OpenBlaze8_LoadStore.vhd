-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 LoadStore
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_LoadStore.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-05-22
-- Last update: 2016-11-22
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

entity OpenBlaze8_LoadStore is
  -- =====[ Parameters ]==========================
  generic (
     size_data      : natural := 8);
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

--  cycle_phase_i        : in  std_logic;                      -- 0 = first cycle, 1 = second cycle
    
    io_access_en_i       : in  std_logic;
    io_read_en_i         : in  std_logic;
    io_write_en_i        : in  std_logic;
    io_addr_i            : in  std_logic_vector(size_data downto 1);
    io_data_read_o       : out std_logic_vector(size_data downto 1);
    io_data_write_i      : in  std_logic_vector(size_data downto 1);

    port_id_o            : out std_logic_vector(size_data downto 1);
    in_port_i            : in  std_logic_vector(size_data downto 1);
    out_port_o           : out std_logic_vector(size_data downto 1);
    read_strobe_o        : out std_logic;
    write_strobe_o       : out std_logic
    );
end OpenBlaze8_LoadStore;

architecture rtl of OpenBlaze8_LoadStore is
  
begin  -- rtl
  -----------------------------------------------------------------------------
  -- LoadStore output
  -----------------------------------------------------------------------------
  read_strobe_o  <= io_read_en_i ; -- and cycle_phase_i;
  write_strobe_o <= io_write_en_i; -- and cycle_phase_i;
  port_id_o      <= io_addr_i;
  out_port_o     <= io_data_write_i;
  io_data_read_o <= in_port_i;
  
--port_id_o      <= io_addr_i       when io_access_en_i = '1' else
--                  (others => '0');
--out_port_o     <= io_data_write_i when io_access_en_i = '1' else
--                  (others => '0');
  
end rtl;
