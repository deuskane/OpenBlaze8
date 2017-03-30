-------------------------------------------------------------------------------
-- Title      : dpram_pkg
-- Project    : dpram
-------------------------------------------------------------------------------
-- File       : dpram_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2016-11-18
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
library work;
use work.math_pkg.all;

package dpram_pkg is

  component dpram is
    generic (
      WIDTH : natural;
      DEPTH : natural
      );
    port (
      clk_i        : in  std_logic;
      cke_i        : in  std_logic;
      rstn_i       : in  std_logic;
      -- MEM_READ
      re_i         : in  std_logic;
      raddr_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0);
      rdata_o      : out std_logic_vector(WIDTH       -1 downto 0);
      -- MEM_WRITE
      we_i         : in  std_logic;
      waddr_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0);
      wdata_i      : in  std_logic_vector(WIDTH       -1 downto 0)    
      );
  end component;

end package dpram_pkg;

