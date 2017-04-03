-------------------------------------------------------------------------------
-- Title      : OB8_SOC
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OB8_SOC.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-04-03
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

entity OB8_SOC is
  port (
    clk_i      : in  std_logic;
    arstn_i    : in  std_logic;

    switch_i   : in  std_logic_vector(5 downto 0);
    led_o      : out std_logic_vector(7 downto 0);

    vga_HSYNC_o: out std_logic;
    vga_VSYNC_o: out std_logic;
    vga_Red_o  : out std_logic;
    vga_Green_o: out std_logic;
    vga_Blue_o : out std_logic;

    --UART
    srx_i      : in  std_logic;
    stx_o      : out std_logic;
    bdr_o      : out std_logic
    );
end OB8_SOC;

architecture rtl of OB8_SOC is
  constant FSYS                       : positive:= 25_000_000;
  constant FSYS_INT                   : positive:= 25_000_000;
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
  constant ID_VGA                     : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := "00001000";
  --                                                                                    "00000011"
  constant ID_UART                    : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := "00011000";
  --                                                                                    "00000111"
  
  signal clk                          : std_logic;

  signal iaddr                        : std_logic_vector(OPENBLAZE8_ADDR_INST_WIDTH-1 downto 0);
  signal idata                        : std_logic_vector(17 downto 0);
  signal pbi_ini                      : pbi_ini_t;
  signal pbi_tgt                      : pbi_tgt_t;
  signal pbi_tgt_switch               : pbi_tgt_t;
  signal pbi_tgt_led                  : pbi_tgt_t;
  signal pbi_tgt_vga                  : pbi_tgt_t;
  signal pbi_tgt_uart                 : pbi_tgt_t;

  signal vga_Red                      : std_logic_vector (2 downto 0);
  signal vga_Green                    : std_logic_vector (2 downto 0);
  signal vga_Blue                     : std_logic_vector (2 downto 1);
  
begin  -- architecture rtl

  ins_clock_divider : entity work.clock_divider(rtl)
    generic map(
      RATIO            => FSYS/FSYS_INT
      )
    port map (
      clk_i            => clk_i  ,
      arstn_i          => arstn_i,
      clk_div_o        => clk
      );
  
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
      clk_i            => clk    ,
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

  pbi_tgt.rdata <= pbi_tgt_switch.rdata or
                   pbi_tgt_led   .rdata or
                   pbi_tgt_vga   .rdata or
                   pbi_tgt_uart  .rdata;
  pbi_tgt.busy  <= pbi_tgt_switch.busy  or
                   pbi_tgt_led   .busy  or
                   pbi_tgt_vga   .busy  or
                   pbi_tgt_uart  .busy;

  ins_pbi_OpenBlaze8_ROM : entity work.OpenBlaze8_ROM(rtl)
    port map (
      clk_i            => clk    ,
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
      clk_i            => clk           ,
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
      clk_i            => clk        ,
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
      FSYS             => FSYS_INT  ,
      ID               => ID_VGA
      )
    port  map(
      clk_i            => clk        ,
      cke_i            => '1'        ,
      arstn_i          => arstn_i    ,
      pbi_ini_i        => pbi_ini    ,
      pbi_tgt_o        => pbi_tgt_vga,
      vga_HSYNC_o      => vga_HSYNC_o,
      vga_VSYNC_o      => vga_VSYNC_o,
      vga_Red_o        => vga_Red    ,
      vga_Green_o      => vga_Green  ,
      vga_Blue_o       => vga_Blue 
      );

  vga_Red_o   <= vga_Red  (2) or vga_Red  (1) or vga_Red  (0);
  vga_Green_o <= vga_Green(2) or vga_Green(1) or vga_Green(0);
  vga_Blue_o  <= vga_Blue (2) or vga_Blue (1);  

  ins_pbi_uart : entity work.pbi_uart(rtl)
    generic map(
      UART_BASE_FREQ  => FSYS_INT,
      IT_ENABLE       => false,
      ID              => ID_UART
      )
    port map  (
      clk_i           => clk,
      cke_i           => '1',
      arstn_i         => arstn_i,
      pbi_ini_i       => pbi_ini,
      pbi_tgt_o       => pbi_tgt_uart,

      sRX_i           => srx_i,
      sTX_o           => stx_o,
      bdr_o           => bdr_o,
      interrupt_o     => open,
      interrupt_ack_i => '0'
      );

end architecture rtl;


