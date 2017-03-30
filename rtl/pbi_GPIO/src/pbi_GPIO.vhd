-------------------------------------------------------------------------------
-- Title      : pbi_GPIO
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : pbi_GPIO.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-03-30
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-30  0.1      rosiere	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.pbi_pkg.all;

entity pbi_GPIO is
  generic(
--  SIZE_ADDR        : natural:=8;     -- Bus Address Width
--  SIZE_DATA        : natural:=8;     -- Bus Data    Width
    NB_IO            : natural:=8;     -- Number of IO. Must be <= SIZE_DATA
    DATA_OE_INIT     : boolean:=false; -- Direction of the IO after a reset
    DATA_OE_FORCE    : boolean:=false; -- Can change the direction of the IO
    IT_ENABLE        : boolean:=false; -- GPIO can generate interruption
    ID               : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := (others => '0')
    );
  port   (
    clk_i            : in    std_logic;
    cke_i            : in    std_logic;
    arstn_i          : in    std_logic; -- asynchronous reset

    -- Bus
    pbi_ini_i        : in    pbi_ini_t;
    pbi_tgt_o        : out   pbi_tgt_t;
    
    -- To/From IO
--  data_io          : inout std_logic_vector (NB_IO-1     downto 0);
    data_i           : in    std_logic_vector (NB_IO-1     downto 0);
    data_o           : out   std_logic_vector (NB_IO-1     downto 0);
    data_oe_o        : out   std_logic_vector (NB_IO-1     downto 0);

    -- To/From IT Ctrl
    interrupt_o      : out   std_logic;
    interrupt_ack_i  : in    std_logic
    );

end entity pbi_GPIO;

architecture rtl of pbi_GPIO is
  constant SIZE_ADDR_IP : natural := 2;
  
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

  ins_GPIO : entity work.GPIO(rtl)
  generic map(
    SIZE_DATA        => PBI_DATA_WIDTH,
    NB_IO            => NB_IO         ,
    DATA_OE_INIT     => DATA_OE_INIT  ,
    DATA_OE_FORCE    => DATA_OE_FORCE ,
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
--  data_io          => data_io        ,
    data_i           => data_i         ,
    data_o           => data_o         ,
    data_oe_o        => data_oe_o      ,
    interrupt_o      => interrupt_o    ,
    interrupt_ack_i  => interrupt_ack_i
    );
  
end architecture rtl;
