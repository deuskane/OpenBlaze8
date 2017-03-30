-------------------------------------------------------------------------------
-- Title      : math
-- Project    : 
-------------------------------------------------------------------------------
-- File       : math_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2016-11-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Collection of mathematics function
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-11  1.0      mrosiere	Created
-------------------------------------------------------------------------------

package math_pkg is

  function log2( i : natural) return integer;
  
end math_pkg;

package body math_pkg is
  
  function log2( i : natural) return integer is
    variable tmp    : integer := i;
    variable log2_i : integer := 0; 
  begin					
    while tmp > 1 loop
      log2_i := log2_i + 1;
      tmp    := tmp / 2;     
    end loop;

    return log2_i;
  end function;
  
end math_pkg;
