-------------------------------------------------------------------------------
-- Title      : tb_GPIO_bidir
-- Project    : GPIO
-------------------------------------------------------------------------------
-- File       : tb_GPIO_bidir.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2017-03-25
-- Last update: 2018-06-01
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-25  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_bit.all;
--use ieee.std_logic_arith.all;

library work;

entity tb_GPIO_bidir is

end tb_GPIO_bidir;

architecture tb of tb_GPIO_bidir is

  -- =====[ Constants ]===========================
  constant SIZE_ADDR        : natural:=8;     -- Bus Address Width
  constant SIZE_DATA        : natural:=8;     -- Bus Data    Width
  constant NB_IO            : natural:=8;     -- Number of IO. Must be <= SIZE_DATA
  constant DATA_OE_INIT     : boolean:=false; -- Direction of the IO after a reset
  constant DATA_OE_FORCE    : boolean:=false; -- Can change the direction of the IO
  constant IT_ENABLE        : boolean:=false; -- GPIO can generate interruption

  -- =====[ Signals ]=============================
  signal clk_i            : std_logic := '0';
  signal cke_i            : std_logic;
  signal arstn_i          : std_logic;
  signal cs_i             : std_logic;
  signal re_i             : std_logic;
  signal we_i             : std_logic;
  signal addr_i           : std_logic_vector (SIZE_ADDR-1 downto 0);
  signal wdata_i          : std_logic_vector (SIZE_DATA-1 downto 0);
  signal rdata_o          : std_logic_vector (SIZE_DATA-1 downto 0);
  signal busy_o           : std_logic;
  signal data_i           : std_logic_vector (NB_IO-1     downto 0);
  signal data_o           : std_logic_vector (NB_IO-1     downto 0);
  signal data_oe_o        : std_logic_vector (NB_IO-1     downto 0);
  signal interrupt_o      : std_logic;
  signal interrupt_ack_i  : std_logic;
begin

  ------------------------------------------------
  -- Instance of DUT
  ------------------------------------------------
  GPIO : entity work.GPIO(rtl)
  generic map(
    SIZE_ADDR        => SIZE_ADDR      ,
    SIZE_DATA        => SIZE_DATA      ,
    NB_IO            => NB_IO          ,
    DATA_OE_INIT     => DATA_OE_INIT   ,
    DATA_OE_FORCE    => DATA_OE_FORCE  ,
    IT_ENABLE        => IT_ENABLE    
    )
  port map(
    clk_i            => clk_i          ,
    cke_i            => cke_i          ,
    arstn_i          => arstn_i        ,
    cs_i             => cs_i           ,
    re_i             => re_i           ,
    we_i             => we_i           ,
    addr_i           => addr_i         ,
    wdata_i          => wdata_i        ,
    rdata_o          => rdata_o        ,
    busy_o           => busy_o         ,

    data_i           => data_i         ,
    data_o           => data_o         ,
    data_oe_o        => data_oe_o      ,
    
    interrupt_o      => interrupt_o    ,
    interrupt_ack_i  => interrupt_ack_i
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
    arstn_i         <= '0';
    cke_i           <= '1';

    cs_i            <= '0';
    re_i            <= '0';
    we_i            <= '0';
    addr_i          <= X"00";
    wdata_i         <= X"00";
    interrupt_ack_i <= '0';
    data_i          <= (others => 'L');
    
    wait until rising_edge(clk_i);
    arstn_i         <= '1';
    wait until rising_edge(clk_i);

    report "[TESTBENCH] Goto OUT mode";
    cs_i            <= '1';
    addr_i          <= X"01";
    wdata_i         <= X"FF";
    wait until rising_edge(clk_i);
    we_i            <= '1';

    wait until rising_edge(clk_i);
    cs_i            <= '0';
    we_i            <= '0';
    
    for i in 0 to SIZE_DATA-1 loop
    report "[TESTBENCH] Write data";
    cs_i            <= '1';
    addr_i          <= X"00";
    wdata_i         <= X"00";
    wdata_i(i)      <= '1';
    wait until rising_edge(clk_i);
    we_i            <= '1';

    wait until rising_edge(clk_i);
    cs_i            <= '0';
    we_i            <= '0';
    end loop;  -- i

    report "[TESTBENCH] Goto IN mode";
    cs_i            <= '1';
    addr_i          <= X"01";
    wdata_i         <= X"00";
    wait until rising_edge(clk_i);
    we_i            <= '1';

    wait until rising_edge(clk_i);
    cs_i            <= '0';
    we_i            <= '0';
    
    for i in 0 to SIZE_DATA-1 loop
    report "[TESTBENCH] Write data";
    cs_i            <= '1';
    addr_i          <= X"00";
    data_i          <= (i=> 'H', others => 'L');
    wait until rising_edge(clk_i);
    re_i            <= '1';

    wait until rising_edge(clk_i);
    cs_i            <= '0';
    re_i            <= '0';
    end loop;  -- i
    
    
    wait until rising_edge(clk_i);
    report "[TESTBENCH] Test End";
    wait;
  end process tb_gen;

  
end tb;
