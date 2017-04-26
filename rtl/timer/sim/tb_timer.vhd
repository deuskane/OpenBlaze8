-------------------------------------------------------------------------------
-- Title      : tb_stack
-- Project    : stack
-------------------------------------------------------------------------------
-- File       : tb_stack.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2017-04-26
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
--use work.timer_pkg.all;

entity tb_timer is

end tb_timer;

architecture tb of tb_timer is

  -- =====[ Constants ]===========================
  constant FSYS             : positive := 50_000_000;
  constant PERIOD           : time     := 20ns;
  constant TICK_PERIOD      : real     := 0.001; -- 1ms
  constant SIZE_ADDR        : natural  := 3;   
  constant SIZE_DATA        : natural  := 8;   
  constant IT_ENABLE        : boolean  := false;

  -- =====[ Signals ]=============================
  signal clk_i        : std_logic := '0';
  signal cke_i        : std_logic;
  signal arstn_i      : std_logic;
    -- To IP
  signal cs_i             : std_logic;
  signal re_i             : std_logic;
  signal we_i             : std_logic;
  signal addr_i           : std_logic_vector (SIZE_ADDR-1 downto 0);
  signal wdata_i          : std_logic_vector (SIZE_DATA-1 downto 0);
  signal rdata_o          : std_logic_vector (SIZE_DATA-1 downto 0);
  signal busy_o           : std_logic;
  signal interrupt_o      : std_logic;
  signal interrupt_ack_i  : std_logic;

  procedure run
    (constant n : in positive           -- nb cycle
    ) is
    
    begin
      for i in 0 to n-1
      loop
        wait until rising_edge(clk_i);        
      end loop;  -- i
    end run;

begin

  ------------------------------------------------
  -- Instance of DUT
  ------------------------------------------------
  dut : entity work.timer(rtl)
  generic map
   (FSYS             => FSYS      
   ,TICK_PERIOD      => TICK_PERIOD
   ,SIZE_ADDR        => SIZE_ADDR 
   ,SIZE_DATA        => SIZE_DATA 
   ,IT_ENABLE        => IT_ENABLE 
    )
  port map
   (clk_i            => clk_i          
   ,cke_i            => cke_i          
   ,arstn_i          => arstn_i        
   ,cs_i             => cs_i           
   ,re_i             => re_i           
   ,we_i             => we_i           
   ,addr_i           => addr_i         
   ,wdata_i          => wdata_i        
   ,rdata_o          => rdata_o        
   ,busy_o           => busy_o         
   ,interrupt_o      => interrupt_o    
   ,interrupt_ack_i  => interrupt_ack_i
    );

  

  ------------------------------------------------
  -- Clock process
  ------------------------------------------------
  clk_i <= not clk_i after PERIOD/2;
  
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

    run(1);

    -- Reset
    report "[TESTBENCH] Reset";
    arstn_i         <= '0';
    cke_i           <= '1';
    cs_i            <= '0';
    re_i            <= '0';
    we_i            <= '0';
    interrupt_ack_i <= '0';
    run(1);
    arstn_i         <= '1';
    run(1);
    
    report "[TESTBENCH] ------------------------------------------";
    report "[TESTBENCH] 1) Set 0xa in counter";
    report "[TESTBENCH] 2) Start Counter";
    report "[TESTBENCH] ------------------------------------------";
    
    cs_i            <= '1';
    we_i            <= '1';
    addr_i          <= "000"; -- control
    wdata_i         <= X"00"; -- Timer disable
    run(1);

    addr_i          <= "100"; -- byte 0
    wdata_i         <= X"0a";
    run(1);

    addr_i          <= "101"; -- byte 1
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "110"; -- byte 2
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "111"; -- byte 3
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "000"; -- control
    wdata_i         <= X"01"; -- Timer enable
    run(1);

    we_i            <= '0';
    re_i            <= '1';

    run(15);

    cs_i            <= '0';
    re_i            <= '0';

    
    report "[TESTBENCH] ------------------------------------------";
    report "[TESTBENCH] 1) Set 0xa in counter";
    report "[TESTBENCH] 2) Enable auto start";
    report "[TESTBENCH] 3) Start Counter";
    report "[TESTBENCH] ------------------------------------------";
    
    cs_i            <= '1';
    we_i            <= '1';

    addr_i          <= "000"; -- control
    wdata_i         <= X"00"; -- Timer disable
    run(1);

    addr_i          <= "100"; -- byte 0
    wdata_i         <= X"0a";
    run(1);

    addr_i          <= "101"; -- byte 1
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "110"; -- byte 2
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "111"; -- byte 3
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "000"; -- control
    wdata_i         <= X"05"; -- Timer enable, auto start enable
    run(1);

    we_i            <= '0';
    re_i            <= '1';

    run(100);

    cs_i            <= '0';
    re_i            <= '0';

    report "[TESTBENCH] ------------------------------------------";
    report "[TESTBENCH] 1) Set 0xa in counter";
    report "[TESTBENCH] 2) use tick";
    report "[TESTBENCH] 3) Start Counter";
    report "[TESTBENCH] ------------------------------------------";
    
    cs_i            <= '1';
    we_i            <= '1';

    addr_i          <= "000"; -- control
    wdata_i         <= X"00"; -- Timer disable
    run(1);

    addr_i          <= "100"; -- byte 0
    wdata_i         <= X"0a";
    run(1);

    addr_i          <= "101"; -- byte 1
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "110"; -- byte 2
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "111"; -- byte 3
    wdata_i         <= X"00";
    run(1);

    addr_i          <= "000"; -- control
    wdata_i         <= X"11"; -- Timer enable, tick enable
    run(1);

    we_i            <= '0';
    re_i            <= '1';

    run(200);

    cs_i            <= '0';
    re_i            <= '0';

    report "[TESTBENCH] Test End";
    wait;
  end process tb_gen;

  
end tb;
