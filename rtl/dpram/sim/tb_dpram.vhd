-------------------------------------------------------------------------------
-- Title      : tb_dpram
-- Project    : dpram
-------------------------------------------------------------------------------
-- File       : tb_dpram.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2016-11-16
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
--use ieee.numeric_bit.all;
--use ieee.std_logic_arith.all;

library work;
use work.math_pkg.all;
use work.dpram_pkg.all;

entity tb_dpram is

end tb_dpram;

architecture tb of tb_dpram is

  -- =====[ Constants ]===========================
  constant WIDTH : natural := 8;
  constant DEPTH : natural := 8;

  -- =====[ Signals ]=============================
  signal clk_i        : std_logic := '0';
  signal cke_i        : std_logic;
  signal rstn_i       : std_logic;
  signal re_i         : std_logic;
  signal raddr_i      : std_logic_vector(log2(DEPTH) -1 downto 0);
  signal rdata_o      : std_logic_vector(WIDTH       -1 downto 0);
  signal we_i         : std_logic;
  signal waddr_i      : std_logic_vector(log2(DEPTH) -1 downto 0);
  signal wdata_i      : std_logic_vector(WIDTH       -1 downto 0);
begin

  ------------------------------------------------
  -- Instance of DUT
  ------------------------------------------------
  
  dut : dpram
    generic map
    (WIDTH => WIDTH
    ,DEPTH => DEPTH
     )
    port map
    (clk_i   => clk_i  
    ,cke_i   => cke_i  
    ,rstn_i  => rstn_i 
    ,re_i    => re_i   
    ,raddr_i => raddr_i
    ,rdata_o => rdata_o
    ,we_i    => we_i   
    ,waddr_i => waddr_i
    ,wdata_i => wdata_i
     );

  ------------------------------------------------
  -- Clock process
  ------------------------------------------------
  clk_i <= not clk_i after 10ns;
  
  ------------------------------------------------
  -- Test process
  ------------------------------------------------
  -- purpose: Testbench process
  -- type   : combinational
  -- inputs : 
  -- outputs: All dut design with clk_i
  tb_gen: process is
  begin  -- process tb_gen
    report "[TESTBENCH] Test Begin";

    wait until rising_edge(clk_i);

    -- Reset
    report "[TESTBENCH] Reset";
    rstn_i <= '0';
    we_i   <= '0';
    re_i   <= '0';
    wait until rising_edge(clk_i);
    rstn_i <= '1';
    wait until rising_edge(clk_i);

    cke_i  <= '1';
    
    report "[TESTBENCH] Write Only Sequence";
    we_i   <= '1';
    for x in 0 to DEPTH-1
    loop
      waddr_i <= std_logic_vector(to_unsigned(x,waddr_i'length));
      wdata_i <= std_logic_vector(to_unsigned(x,wdata_i'length));

      wait until rising_edge(clk_i);
    end loop;  -- x
    we_i   <= '0';
    
    report "[TESTBENCH] Read Only Sequence";
    re_i   <= '1';
    for x in 0 to DEPTH-1
    loop
      raddr_i <= std_logic_vector(to_unsigned(x,raddr_i'length));

      wait until rising_edge(clk_i);

      assert rdata_o = std_logic_vector(to_unsigned(x,rdata_o'length)) report "Unexpected value" severity failure;
    end loop;  -- x
    re_i   <= '0';
    
    report "[TESTBENCH] Write/Read Sequence";
    we_i   <= '1';
    for x in 0 to 2*DEPTH-1
    loop
      waddr_i <= std_logic_vector(to_unsigned(x,waddr_i'length));
      wdata_i <= not std_logic_vector(to_unsigned(x,wdata_i'length));
      if x>0 then
        re_i   <= '1';
        raddr_i <= std_logic_vector(to_unsigned(x-1,raddr_i'length));
      end if;

      wait until rising_edge(clk_i);

      if x>0 then
      assert rdata_o = not std_logic_vector(to_unsigned(x-1,rdata_o'length)) report "Unexpected value" severity failure;
      end if;
    end loop;  -- x
    we_i   <= '0';
    re_i   <= '0';
    
    report "[TESTBENCH] Test End";
    wait;
  end process tb_gen;

  
end tb;
