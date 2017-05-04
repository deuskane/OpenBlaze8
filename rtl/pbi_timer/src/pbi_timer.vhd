-------------------------------------------------------------------------------
-- Title      : pbi_timer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pbi_timer.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-04-26
-- Last update: 2017-04-28
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-04-26  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.pbi_pkg.all;

entity pbi_timer is
  generic(
--  FSYS             : positive := 50_000_000;
--  TICK_PERIOD      : real     := 0.001; -- 1ms
    TICK             : positive := 1000; -- FSYS * TICK_PERIOD
    IT_ENABLE        : boolean  := false; -- Timer can generate interruption
    ID               : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := (others => '0')
    );
  port   (
    clk_i            : in    std_logic;
    cke_i            : in    std_logic;
    arstn_i          : in    std_logic; -- asynchronous reset

    -- Bus
    pbi_ini_i        : in    pbi_ini_t;
    pbi_tgt_o        : out   pbi_tgt_t;
    
    -- To/From IT Ctrl
    interrupt_o      : out   std_logic;
    interrupt_ack_i  : in    std_logic
    );

end entity pbi_timer;

architecture rtl of pbi_timer is
  constant SIZE_ADDR_IP : natural := 3;
  
  signal ip_cs               :  std_logic;
  signal ip_re               :  std_logic;
  signal ip_we               :  std_logic;
  signal ip_addr             :  std_logic_vector (SIZE_ADDR_IP-1   downto 0);
  signal ip_wdata            :  std_logic_vector (PBI_DATA_WIDTH-1 downto 0);
  signal ip_rdata            :  std_logic_vector (PBI_DATA_WIDTH-1 downto 0);
  signal ip_busy             :  std_logic;

begin  -- architecture rtl

  ins_pbi_wrapper_target : entity work.pbi_wrapper_target(rtl)
  generic map(
    SIZE_DATA      => PBI_DATA_WIDTH,
    SIZE_ADDR_IP   => SIZE_ADDR_IP  ,
    ID             => ID
     )
  port map(
    clk_i          => clk_i         ,
    cke_i          => cke_i         ,
    arstn_i        => arstn_i       ,
    ip_cs_o        => ip_cs         ,
    ip_re_o        => ip_re         ,
    ip_we_o        => ip_we         ,
    ip_addr_o      => ip_addr       ,
    ip_wdata_o     => ip_wdata      ,
    ip_rdata_i     => ip_rdata      ,
    ip_busy_i      => ip_busy       ,
    pbi_ini_i      => pbi_ini_i     ,
    pbi_tgt_o      => pbi_tgt_o     
    );

  ins_timer : entity work.timer(rtl)
  generic map(
--  FSYS             => FSYS          ,
--  TICK_PERIOD      => TICK_PERIOD   ,
    TICK             => TICK          ,
    SIZE_ADDR        => SIZE_ADDR_IP  ,
    SIZE_DATA        => PBI_DATA_WIDTH,  
    IT_ENABLE        => IT_ENABLE  
    )
  port map(
    clk_i            => clk_i          ,
    cke_i            => cke_i          ,
    arstn_i          => arstn_i        ,
    cs_i             => ip_cs          ,
    re_i             => ip_re          ,
    we_i             => ip_we          ,
    addr_i           => ip_addr        ,
    wdata_i          => ip_wdata       ,
    rdata_o          => ip_rdata       ,
    busy_o           => ip_busy        ,
    interrupt_o      => interrupt_o    ,
    interrupt_ack_i  => interrupt_ack_i
    );
  
end architecture rtl;
