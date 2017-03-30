-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Clock
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Clock.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-03-22
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
-- 2014-03-22  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_Clock is
  -- =====[ Parameters ]==========================
  generic (
     multi_cycle    : natural := 1);
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous clock
    reset_o              : out std_logic; -- synchronous clock

    clock_o              : out std_logic;
    cycle_phase_o        : out std_logic  -- 0 = first cycle, 1 = second cycle

  );
end OpenBlaze8_Clock;

architecture rtl of OpenBlaze8_Clock is
  signal cycle_phase_r : std_logic;     -- Phase of the cycle
  signal reset_r       : std_logic_vector(1 downto 0);
  signal reset_internal: std_logic;
begin  -- rtl

  cycle_phase_o <= cycle_phase_r;
  reset_o       <= reset_internal;
  -----------------------------------------------------------------------------
  -- Reset
  -----------------------------------------------------------------------------
  reset: process (clock_i)
  begin  -- process transition
    if clock_i'event and clock_i = '1' then
      if reset_i = '1' then
        reset_r <= (others => '1');
      else
        reset_r <= '0' & reset_r(1);
      end if;
    end if;
  end process reset;

--reset_internal <= reset_r(0);
  reset_internal <= reset_i;
  
  -----------------------------------------------------------------------------
  -- Clock divider
  -----------------------------------------------------------------------------
  gen_div2: if multi_cycle = 0 generate
    clock_o       <= not cycle_phase_r;
  end generate gen_div2;

  gen_div2_n: if multi_cycle /= 0 generate
    clock_o       <= clock_i;
  end generate gen_div2_n;

  -- =====[ Transition ]==========================
  transition: process (clock_i,reset_internal)
  begin  -- process transition
    if reset_internal = '1' then
      -- asynchronous reset
      cycle_phase_r <= '0';
      else
        if clock_i'event and clock_i = '1' then
          if clock_enable_i = '1' then
            cycle_phase_r <= not cycle_phase_r;
          end if;
        end if;
    end if;
  end process transition;

end rtl;
