-------------------------------------------------------------------------------
-- Title      : OB8_VGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OB8_VGA.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-05-13
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
use work.pbi_pkg.all;

entity OB8_VGA is
  generic (
    FSYS       : positive := 50_000_000;
    FSYS_INT   : positive := 50_000_000;
    USE_KCPSM  : boolean  := false;
    NB_SWITCH  : positive := 8;
    NB_LED     : positive := 8
    );
  port (
    clk_i      : in  std_logic;
    arstn_i    : in  std_logic;

    switch_i   : in  std_logic_vector(NB_SWITCH-1 downto 0);
    led_o      : out std_logic_vector(NB_LED   -1 downto 0);

    vga_HSYNC_o: out std_logic;
    vga_VSYNC_o: out std_logic;
    vga_Red_o  : out std_logic_vector (2 downto 0);
    vga_Green_o: out std_logic_vector (2 downto 0);
    vga_Blue_o : out std_logic_vector (2 downto 1)
);
end OB8_VGA;

architecture rtl of OB8_VGA is 
  constant ID_SWITCH                  : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := "00000000";
  --                                                                                    "00000011"
  constant ID_LED                     : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := "00000100";
  --                                                                                    "00000011"
  constant ID_VGA                     : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := "10000000";
  --                                                                                    "00001111"
  constant ID_TIMER                   : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := "00010000";
  --                                                                                    "00000111"

  signal clk                          : std_logic;
  
  signal iaddr                        : std_logic_vector(10-1 downto 0);
  signal idata                        : std_logic_vector(17 downto 0);
  signal pbi_ini                      : pbi_ini_t;
  signal pbi_tgt                      : pbi_tgt_t;
  signal pbi_tgt_switch               : pbi_tgt_t;
  signal pbi_tgt_led                  : pbi_tgt_t;
  signal pbi_tgt_vga                  : pbi_tgt_t;
  signal pbi_tgt_timer                : pbi_tgt_t;
  
begin  -- architecture rtl

  ins_clock_divider : entity work.clock_divider(rtl)
    generic map(
      RATIO            => FSYS/FSYS_INT
      )
    port map (
      clk_i            => clk_i  ,
      arstn_i          => arstn_i,
      cke_i            => '1',
      clk_div_o        => clk
      );
  
  ins_pbi_PicoBlaze : entity work.pbi_PicoBlaze(rtl)
  generic map(
     USE_KCPSM       => USE_KCPSM
     )
  port map (
    clk_i            => clk    ,
    cke_i            => '1'    ,
    arstn_i          => arstn_i,
    iaddr_o          => iaddr  ,
    idata_i          => idata  ,
    pbi_ini_o        => pbi_ini,
    pbi_tgt_i        => pbi_tgt,
    interrupt_i      => '0'    ,
    interrupt_ack_o  => open 
    );

  pbi_tgt.rdata <= pbi_tgt_switch.rdata or
                   pbi_tgt_led   .rdata or
                   pbi_tgt_vga   .rdata or
                   pbi_tgt_timer .rdata;
  pbi_tgt.busy  <= pbi_tgt_switch.busy  or
                   pbi_tgt_led   .busy  or
                   pbi_tgt_vga   .busy  or
                   pbi_tgt_timer .busy;

  ins_pbi_OpenBlaze8_ROM : entity work.OpenBlaze8_ROM(rtl)
    port map (
      clk_i            => clk  ,
      addr_i           => iaddr  ,
      data_o           => idata  
      );
  
  ins_pbi_switch : entity work.pbi_GPIO(rtl)
    generic map(
      NB_IO            => NB_SWITCH,
      DATA_OE_INIT     => false,
      DATA_OE_FORCE    => true ,
      IT_ENABLE        => false, -- GPIO can generate interruption
      ID               => ID_SWITCH
      )
    port map  (
      clk_i            => clk         ,
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
      NB_IO            => NB_LED,
      DATA_OE_INIT     => true ,
      DATA_OE_FORCE    => true ,
      IT_ENABLE        => false, -- GPIO can generate interruption
      ID               => ID_LED
      )
    port map  (
      clk_i            => clk      ,
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

  ins_pbi_vga_controller : entity work.pbi_vga_controller(rtl)
    generic map(
      FSYS             => FSYS_INT   ,
      ID               => ID_VGA
      )
    port  map(
      clk_i            => clk      ,
      cke_i            => '1'        ,
      arstn_i          => arstn_i    ,
      pbi_ini_i        => pbi_ini    ,
      pbi_tgt_o        => pbi_tgt_vga,
      vga_HSYNC_o      => vga_HSYNC_o,
      vga_VSYNC_o      => vga_VSYNC_o,
      vga_Red_o        => vga_Red_o  ,
      vga_Green_o      => vga_Green_o,
      vga_Blue_o       => vga_Blue_o
      );

  ins_pbi_timer : entity work.pbi_timer(rtl)
    generic map(
--    FSYS             => FSYS_INT,
--    TICK_PERIOD      => 0.001, -- 1ms
      TICK             => positive(real(FSYS_INT)*0.001),
      IT_ENABLE        => false,
      ID               => ID_TIMER
      )
    port map  (
      clk_i            => clk           ,
      cke_i            => '1'           ,
      arstn_i          => arstn_i       ,
      pbi_ini_i        => pbi_ini       ,
      pbi_tgt_o        => pbi_tgt_timer ,
      interrupt_o      => open          ,
      interrupt_ack_i  => '0'
      );

--pbi_tgt_timer .rdata <= X"00";
--pbi_tgt_timer .busy  <= '0';

end architecture rtl;
    
  
