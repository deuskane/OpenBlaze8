-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 RegFile
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_RegFile.vhd
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

entity OpenBlaze8_RegFile is
  -- =====[ Parameters ]==========================
  generic (
     size_data      : natural := 8;
     nb_reg         : natural := 16
   );
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

    regx_read_en_i       : in  std_logic;
    regx_write_en_i      : in  std_logic;
    regx_addr_i          : in  std_logic_vector(log2(nb_reg) downto 1);
    regx_data_i          : in  std_logic_vector(size_data downto 1);
    regx_data_o          : out std_logic_vector(size_data downto 1);

    regy_read_en_i       : in  std_logic;
    regy_addr_i          : in  std_logic_vector(log2(nb_reg) downto 1);
    regy_data_o          : out std_logic_vector(size_data downto 1)
    );
end OpenBlaze8_RegFile;

architecture rtl of OpenBlaze8_RegFile is

--signal resetn : std_logic;
  
begin  -- rtl

--resetn <= not reset_i;
  -----------------------------------------------------------------------------
  -- RegFile output
  -----------------------------------------------------------------------------
  RAMx : ram_1r1w
    generic map (
      WIDTH => size_data
     ,DEPTH => nb_reg
      )
    port map(
      clk_i   => clock_i
     ,cke_i   => clock_enable_i
--   ,rstn_i  => resetn      
     ,re_i    => regx_read_en_i
     ,raddr_i => regx_addr_i
     ,rdata_o => regx_data_o
     ,we_i    => regx_write_en_i
     ,waddr_i => regx_addr_i
     ,wdata_i => regx_data_i
      );

  RAMy : ram_1r1w
    generic map (
      WIDTH => size_data
     ,DEPTH => nb_reg
      )
    port map(
      clk_i   => clock_i
     ,cke_i   => clock_enable_i
--   ,rstn_i  => resetn      
     ,re_i    => regy_read_en_i
     ,raddr_i => regy_addr_i
     ,rdata_o => regy_data_o
     ,we_i    => regx_write_en_i
     ,waddr_i => regx_addr_i
     ,wdata_i => regx_data_i
      );

end rtl;
