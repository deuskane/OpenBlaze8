-------------------------------------------------------------------------------
-- Title      : pbi
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pbi_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2017-03-15
-- Last update: 2017-03-18
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Collection of pbiematics function
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-15  1.0      mrosiere	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.param_pkg.all;

package pbi_pkg is
  constant PBI_ADDR_WIDTH : natural := 8;
  constant PBI_DATA_WIDTH : natural := 8;
  
  type pbi_ini_t is record
    re         : std_logic;                              -- READ_STROBE
    we         : std_logic;                              -- WRITE_STROBE
    addr       : std_logic_vector(PBI_ADDR_WIDTH-1 downto 0); -- PORT_ID
    wdata      : std_logic_vector(PBI_DATA_WIDTH-1 downto 0); -- IN_PORT
  end record pbi_init_t;

  type pbi_tgt_t is record
    busy       : std_logic;                                   -- Additional port
    rdata      : std_logic_vector(PBI_DATA_WIDTH-1 downto 0); -- OUT_PORT
  end record pbi_tgt_t;

end pbi_pkg;

