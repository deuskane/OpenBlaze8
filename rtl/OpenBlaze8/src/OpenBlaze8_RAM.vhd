-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 RAM
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_RAM.vhd
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
use work.ram_1r1w_pkg.all;

entity OpenBlaze8_RAM is
  -- =====[ Parameters ]==========================
  generic (
     size_data      : natural := 8;
     size_ram       : natural := 64
   );
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

    ram_read_en_i       : in  std_logic;
    ram_write_en_i      : in  std_logic;
    ram_addr_i          : in  std_logic_vector(log2(size_ram) downto 1);
    ram_read_data_o     : out std_logic_vector(size_data downto 1);
    ram_write_data_i    : in  std_logic_vector(size_data downto 1)
    );
end OpenBlaze8_RAM;

architecture rtl of OpenBlaze8_RAM is

  signal resetn : std_logic;
  
begin  -- rtl

  resetn <= not reset_i;
  -----------------------------------------------------------------------------
  -- RAM output
  -----------------------------------------------------------------------------

  ins_RAM : ram_1r1w
    generic map (
      WIDTH => size_data
     ,DEPTH => size_ram
      )
    port map(
      clk_i   => clock_i
     ,cke_i   => clock_enable_i
--   ,rstn_i  => resetn      
     ,re_i    => ram_read_en_i
     ,raddr_i => ram_addr_i
     ,rdata_o => ram_read_data_o
     ,we_i    => ram_write_en_i
     ,waddr_i => ram_addr_i
     ,wdata_i => ram_write_data_i
      );
end rtl;
