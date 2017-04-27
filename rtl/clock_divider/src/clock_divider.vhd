-------------------------------------------------------------------------------
-- Title      : Clock Divider
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : clock_divider.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2017-04-27
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-04-27  1.2      rosière Add 2 algo
-- 2014-07-12  1.1      rosière	Change Port name
-- 2013-12-26  1.0      rosière	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.math_pkg.all;

entity clock_divider is
    generic(RATIO        : positive := 2;
            ALGO         : natural  := 0;         -- 0   : pulse
                                                  -- 1   : 50%
                                                  -- >=2 : area save
            GATED_CLK    : boolean  := true       -- Add clock gated
            );
    port   (clk_i        : in  std_logic;
            cke_i        : in  std_logic;
            arstn_i      : in  std_logic;
            clk_div_o    : out std_logic);
end clock_divider;

architecture rtl of clock_divider is
  constant WIDTH : natural := log2(RATIO-1)+1;
  
  signal clock_counter_r      : natural range 0 to RATIO-1;
  signal clock_div_r_next     : std_logic;
  signal clock_div_r          : std_logic;

  signal clk_gated_in         : std_logic;
  signal clk_gated_cmd        : std_logic;
  signal clk_gated_out        : std_logic;
  
begin
  -- Ratio = 1, then clock is unchanged
  gen_ratio_eq_1: if RATIO=1
  generate
    clk_div_o <= clk_i;
  end generate gen_ratio_eq_1;

  gen_ratio_gt_1: if RATIO > 1
  generate

    -- Generate a pulse of 1 cycle
    gen_algo_pulse: if ALGO = 0
    generate
      clock_div_r_next <= '1' when (clock_counter_r = 0) else
                          '0';

      clk_gated_in  <= clk_i      ;
      clk_gated_cmd <= clock_div_r;
    end generate gen_algo_pulse;
    
    -- Generate clock with closest of 50% duty cycle
    gen_algo_50percent: if ALGO = 1
    generate
      clock_div_r_next <= '0' when (clock_counter_r < RATIO/2) else
                          '1';

      clk_gated_in  <= clock_div_r;
      clk_gated_cmd <= '1';
    end generate gen_algo_50percent;
    
    -- Generate clock with duty cycle depending of RATIO
    gen_algo_area_save: if ALGO >= 2
    generate
      gen_counter_msb: block is
        signal clock_counter_r_vec  : std_logic_vector(WIDTH-1 downto 0);
      begin  -- block gen_counter_msb
        clock_counter_r_vec <= std_logic_vector(to_unsigned(clock_counter_r,clock_counter_r_vec'length));
        clock_div_r_next <= clock_counter_r_vec(WIDTH-1);
      end block gen_counter_msb;

      clk_gated_in  <= clock_div_r;
      clk_gated_cmd <= '1';
    end generate gen_algo_area_save;

    process(arstn_i,clk_i)
    begin 
      if arstn_i='0'
      then
        clock_counter_r <= RATIO-1;
        clock_div_r     <= '0';
      elsif rising_edge(clk_i)
      then
        if (cke_i = '1')
        then
          clock_div_r     <= clock_div_r_next;

          -- decrease clock diviser
          if (clock_counter_r = 0)
          then
            clock_counter_r <= RATIO-1;
          else
            clock_counter_r <= clock_counter_r-1;
          end if;
        end if;
      end if;
    end process;

    -- Use Gated Clock
    gen_clock_gated: if GATED_CLK = true
    generate
      ins_gated_clock : entity work.gated_clock(rtl)
        port map (
          clk_i       => clk_gated_in ,
          cmd_i       => clk_gated_cmd,
          clk_gated_o => clk_gated_out
          );

      clk_div_o <= clk_gated_out;
    end generate gen_clock_gated;

    -- Don't use gated clock
    gen_clock_gated_n: if GATED_CLK = false
    generate
      clk_div_o <= clk_gated_in;
    end generate gen_clock_gated_n;
    
  end generate gen_ratio_gt_1;
end rtl;

