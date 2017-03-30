-------------------------------------------------------------------------------
-- Title      : ram_1r1w
-- Project    : ram_1r1w
-------------------------------------------------------------------------------
-- File       : ram_1r1w.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2017-03-14
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

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.math_pkg.all;

entity ram_1r1w is
  -- =====[ Interfaces ]==========================
  generic (
    WIDTH : natural := 32;
    DEPTH : natural := 32
    );
  port (
    clk_i        : in  std_logic;
    cke_i        : in  std_logic;
--  arstn_i      : in  std_logic;
    -- MEM_READ
    re_i         : in  std_logic;
    raddr_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0);
    rdata_o      : out std_logic_vector(WIDTH       -1 downto 0);
    -- MEM_WRITE
    we_i         : in  std_logic;
    waddr_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0);
    wdata_i      : in  std_logic_vector(WIDTH       -1 downto 0)    
    );
end ram_1r1w;

architecture rtl of ram_1r1w is
  -- =====[ Types ]===============================
  type ram_t is array (DEPTH-1 downto 0) of std_logic_vector(WIDTH -1 downto 0);

  -- =====[ Registers ]===========================
  signal ram_r  : ram_t;
  
  -- =====[ Signals ]=============================
  signal raddr  : integer range 0 to DEPTH-1;
  signal waddr  : integer range 0 to DEPTH-1;

begin  -- rtl

  -- Convert address to integer
  raddr  <= to_integer(unsigned(raddr_i));
  waddr  <= to_integer(unsigned(waddr_i));

  transition: process (clk_i)
  begin  -- process transition
    if (clk_i'event and clk_i = '1') then  -- rising clk_i edge
      if (cke_i = '1') then
        if (we_i = '1') then
          ram_r (waddr) <= wdata_i;
        end if;
      end if;
    end if;
  end process transition;

  rdata_o <= ram_r(raddr);
  
end rtl;
