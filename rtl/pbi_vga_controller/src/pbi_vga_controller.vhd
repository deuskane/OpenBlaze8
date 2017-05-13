-------------------------------------------------------------------------------
-- Title      : pbi_vga_controller
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : pbi_vga_controller.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-05-13
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

entity pbi_vga_controller is
  generic(
    FSYS             : positive := 50_000_000;
    ID               : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := (others => '0')
    );
  port   (
    clk_i            : in    std_logic;
    cke_i            : in    std_logic;
    arstn_i          : in    std_logic; -- asynchronous reset

    -- Bus
    pbi_ini_i        : in    pbi_ini_t;
    pbi_tgt_o        : out   pbi_tgt_t;
    
    -- To IO
    vga_HSYNC_o      : out std_logic;
    vga_VSYNC_o      : out std_logic;
    vga_Red_o        : out std_logic_vector (2 downto 0);
    vga_Green_o      : out std_logic_vector (2 downto 0);
    vga_Blue_o       : out std_logic_vector (2 downto 1)
    );

end entity pbi_vga_controller;

architecture rtl of pbi_vga_controller is
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

  ins_vga_controller : entity work.vga_controller(rtl)
  generic map(
    FSYS             => FSYS          ,
    SIZE_DATA        => PBI_DATA_WIDTH
    )
  port map(
    clk_i            => clk_i          ,
--  cke_i            => cke_i          ,
    arstn_i          => arstn_i        ,
    cs_i             => ip_cs          ,
    re_i             => ip_re          ,
    we_i             => ip_we          ,
    addr_i           => ip_addr        ,
    wdata_i          => ip_wdata       ,
    rdata_o          => ip_rdata       ,
    busy_o           => ip_busy        ,
    vga_HSYNC_o      => vga_HSYNC_o    ,
    vga_VSYNC_o      => vga_VSYNC_o    ,
    vga_Red_o        => vga_Red_o      ,
    vga_Green_o      => vga_Green_o    ,
    vga_Blue_o       => vga_Blue_o 
    );
end architecture rtl;
