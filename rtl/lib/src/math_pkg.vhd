-------------------------------------------------------------------------------
-- Title      : math
-- Project    : 
-------------------------------------------------------------------------------
-- File       : math_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2017-05-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Collection of mathematics function
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-05-13  1.1      mrosiere Add min/max function
-- 2016-11-11  1.0      mrosiere Created
-------------------------------------------------------------------------------

package math_pkg is

  function log2 ( i : natural) return integer;
  function clog2( i : natural) return integer;

  function max ( x1,x2 : integer) return integer;
  function max2( x1,x2 : integer) return integer;
  function min ( x1,x2 : integer) return integer;
  function min2( x1,x2 : integer) return integer;
  
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

  function clog2( i : natural) return integer is
    variable log2_i : integer := 0;
    variable pow2   : integer := 0; 
  begin
    log2_i := 0;
    pow2   := 1;
    
    while i > pow2 loop
      log2_i := log2_i + 1;
      pow2   := pow2 * 2;
    end loop;

    return log2_i;
  end function;

  function max2 (x1,x2 : integer) return integer is
  begin
    if x1 > x2
    then
      return x1;
    else
      return x2;
    end if;
  end function;

  function max (x1,x2 : integer) return integer is
  begin
    return max2(x1,x2);
  end function;

  function min2 (x1,x2 : integer) return integer is
  begin
    if x1 < x2
    then
      return x1;
    else
      return x2;
    end if;
  end function;

  function min (x1,x2 : integer) return integer is
  begin
    return min2(x1,x2);
  end function;

    
end math_pkg;
