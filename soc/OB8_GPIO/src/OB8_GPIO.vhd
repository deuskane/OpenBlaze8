-------------------------------------------------------------------------------
-- Title      : OB8_GPIO
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OB8_GPIO.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-03-31
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-30  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.OpenBlaze8_pkg.all;
use work.pbi_pkg.all;

entity OB8_GPIO is
  port (
    clk_i      : in  std_logic;
    arstn_i    : in  std_logic;

    switch_i   : in  std_logic_vector(5 downto 0);
    led_o      : out std_logic_vector(7 downto 0)
);
end OB8_GPIO;

architecture rtl of OB8_GPIO is
  constant OPENBLAZE8_STACK_DEPTH     : natural := 32;
  constant OPENBLAZE8_RAM_DEPTH       : natural := 64;
  constant OPENBLAZE8_DATA_WIDTH      : natural := 8;
  constant OPENBLAZE8_ADDR_INST_WIDTH : natural := 10;
  constant OPENBLAZE8_REGFILE_DEPTH   : natural := 16;
  constant OPENBLAZE8_MULTI_CYCLE     : natural := 1;
  
  constant ID_SWITCH                  : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := "00000000";
  --                                                                                    "00000011"
  constant ID_LED                     : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := "00000100";
  --                                                                                    "00000011"

  signal iaddr                        : std_logic_vector(OPENBLAZE8_ADDR_INST_WIDTH-1 downto 0);
  signal idata                        : std_logic_vector(17 downto 0);
  signal pbi_ini                      : pbi_ini_t;
  signal pbi_tgt                      : pbi_tgt_t;
  signal pbi_tgt_switch               : pbi_tgt_t;
  signal pbi_tgt_led                  : pbi_tgt_t;

begin  -- architecture rtl

  ins_pbi_OpenBlaze8 : entity work.pbi_OpenBlaze8(rtl)
  generic map(
     STACK_DEPTH     => OPENBLAZE8_STACK_DEPTH    ,
     RAM_DEPTH       => OPENBLAZE8_RAM_DEPTH      ,
     DATA_WIDTH      => OPENBLAZE8_DATA_WIDTH     ,
     ADDR_INST_WIDTH => OPENBLAZE8_ADDR_INST_WIDTH,
     REGFILE_DEPTH   => OPENBLAZE8_REGFILE_DEPTH  ,
     MULTI_CYCLE     => OPENBLAZE8_MULTI_CYCLE
     )
  port map (
    clk_i            => clk_i  ,
    cke_i            => '1'    ,
    arstn_i          => arstn_i,
    iaddr_o          => iaddr  ,
    idata_i          => idata  ,
    pbi_ini_o        => pbi_ini,
    pbi_tgt_i        => pbi_tgt,
    interrupt_i      => '0'    ,
    interrupt_ack_o  => open   ,
    debug_o          => open   
    );

  pbi_tgt.rdata <= pbi_tgt_switch.rdata or pbi_tgt_led.rdata;
  pbi_tgt.busy  <= pbi_tgt_switch.busy  or pbi_tgt_led.busy;

  ins_pbi_OpenBlaze8_ROM : entity work.OpenBlaze8_ROM(rtl)
    port map (
      clk_i            => clk_i  ,
      addr_i           => iaddr  ,
      data_o           => idata  
    );
  
  ins_pbi_switch : entity work.pbi_GPIO(rtl)
    generic map(
    NB_IO            => 6    ,
    DATA_OE_INIT     => false,
    DATA_OE_FORCE    => true ,
    IT_ENABLE        => false, -- GPIO can generate interruption
    ID               => ID_SWITCH
    )
  port map  (
    clk_i            => clk_i         ,
    cke_i            => '1'           ,
    arstn_i          => arstn_i       ,
    pbi_ini_i        => pbi_ini       ,
    pbi_tgt_o        => pbi_tgt_switch,
    data_i           => switch_i      ,
    data_o           => open          ,
    data_oe_o        => open          ,
    interrupt_o      => open          ,
    interrupt_ack_i  => '0'
    );

  ins_pbi_led : entity work.pbi_GPIO(rtl)
    generic map(
    NB_IO            => 8    ,
    DATA_OE_INIT     => true ,
    DATA_OE_FORCE    => true ,
    IT_ENABLE        => false, -- GPIO can generate interruption
    ID               => ID_LED
    )
  port map  (
    clk_i            => clk_i      ,
    cke_i            => '1'        ,
    arstn_i          => arstn_i    ,
    pbi_ini_i        => pbi_ini    ,
    pbi_tgt_o        => pbi_tgt_led,
    data_i           => X"00"      ,
    data_o           => led_o      ,
    data_oe_o        => open       ,
    interrupt_o      => open       ,
    interrupt_ack_i  => '0'
    );

end architecture rtl;
    
  
