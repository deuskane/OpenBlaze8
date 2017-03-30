-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Flags
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Flags.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-05-22
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
-- 2014-05-22  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_Flags is
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset
    
    -- read flags
    flag_c_o             : out std_logic;  -- Flag Carry
    flag_z_o             : out std_logic;  -- Flag Zero

    -- write flags
    flag_c_i             : in  std_logic;  -- Flag Carry
    flag_z_i             : in  std_logic;  -- Flag Zero

    -- control 
    flag_write_c_i       : in  std_logic;
    flag_write_z_i       : in  std_logic;

    flag_save_i          : in  std_logic;  -- Interruption
    flag_restore_i       : in  std_logic   -- RETI
    );
end OpenBlaze8_Flags;

architecture rtl of OpenBlaze8_Flags is

  signal flag_c_r           : std_logic;
  signal flag_c_preserved_r : std_logic;

  signal flag_z_r           : std_logic;
  signal flag_z_preserved_r : std_logic;

  signal cycle_1   : std_logic;
  
begin  -- rtl

  -----------------------------------------------------------------------------
  -- Flag out
  -----------------------------------------------------------------------------
  flag_c_o <= flag_c_r;
  flag_z_o <= flag_z_r;
  
  -----------------------------------------------------------------------------
  -- Transition
  -----------------------------------------------------------------------------
  transition: process (clock_i)
  begin  -- process transition
    if clock_i'event and clock_i = '1' then
      if reset_i = '1' then
        -- synchronous reset
        flag_c_r           <= '0';
        flag_c_preserved_r <= '0';
        flag_z_r           <= '0';
        flag_z_preserved_r <= '0';
      elsif clock_enable_i = '1' then

        if flag_save_i = '1' then
          flag_c_preserved_r <= flag_c_r;
          flag_z_preserved_r <= flag_z_r;
        end if;

        if flag_restore_i = '1' then
          flag_c_r           <= flag_c_preserved_r;
          flag_z_r           <= flag_z_preserved_r;
        else
          if flag_write_c_i = '1' then
          flag_c_r           <= flag_c_i;
          end if;
          if flag_write_z_i = '1' then
          flag_z_r           <= flag_z_i;
          end if;
        end if;
        
      end if;
    end if;
  end process transition;
  
end rtl;
