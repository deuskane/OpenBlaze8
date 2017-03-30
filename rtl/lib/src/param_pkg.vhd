-------------------------------------------------------------------------------
-- Title      : param
-- Project    : 
-------------------------------------------------------------------------------
-- File       : param_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2017-03-15
-- Last update: 2017-03-18
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Collection of paramematics function
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

package param_pkg is
  constant PARAM_ADDR_WIDTH : natural := 8;
  constant PARAM_DATA_WIDTH : natural := 8;
end param_pkg;

