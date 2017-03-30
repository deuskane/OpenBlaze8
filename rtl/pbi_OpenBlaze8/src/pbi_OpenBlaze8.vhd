-------------------------------------------------------------------------------
-- Title      : pbi_OpenBlaze8
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pbi_OpenBlaze8.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-03-30
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

entity pbi_OpenBlaze8 is
  generic (
     STACK_DEPTH     : natural := 32;
     RAM_DEPTH       : natural := 64;
     DATA_WIDTH      : natural := 8;
     ADDR_INST_WIDTH : natural := 10;
     REGFILE_DEPTH   : natural := 16;
     MULTI_CYCLE     : natural := 1);
  port   (
    clk_i            : in    std_logic;
    cke_i            : in    std_logic;
    arstn_i          : in    std_logic; -- asynchronous reset

    -- Instructions
    iaddr_o          : out std_logic_vector(ADDR_INST_WIDTH-1 downto 0);
    idata_i          : in  std_logic_vector(17 downto 0);
    
    -- Bus
    pbi_ini_o        : out   pbi_ini_t;
    pbi_tgt_i        : in    pbi_tgt_t;

    -- To/From IT Ctrl
    interrupt_i      : in    std_logic;
    interrupt_ack_o  : out   std_logic;

    debug_o          : out OpenBlaze8_debug_t
    );
  
end entity pbi_OpenBlaze8;

architecture rtl of pbi_OpenBlaze8 is
  signal cke  : std_logic;
  signal arst : std_logic;
begin  -- architecture rtl

  arst <= not arstn_i;
  cke  <= cke_i or pbi_tgt_i.busy;
  
  OpenBlaze8 : entity work.OpenBlaze8(rtl)
  generic map(
     STACK_DEPTH     => STACK_DEPTH    ;
     RAM_DEPTH       => RAM_DEPTH      ;
     DATA_WIDTH      => DATA_WIDTH     ;
     ADDR_INST_WIDTH => ADDR_INST_WIDTH;
     REGFILE_DEPTH   => REGFILE_DEPTH  ;
     MULTI_CYCLE     => MULTI_CYCLE    
     );
  port map(
    clock_i           => clk_i          ;
    clock_enable_i    => cke            ;
    reset_i           => arst           ;
    address_o         => iaddr_o        ;
    instruction_i     => idata_i        ;
    port_id_o         => pbi_ini.addr   ;
    in_port_i         => pbi_tgt.rdata  ;
    out_port_o        => pbi_ini.wdata  ;
    read_strobe_o     => pbi_ini.re     ;
    write_strobe_o    => pbi_ini.we     ;
    interrupt_i       => interrupt_i    ;
    interrupt_ack_o   => interrupt_ack_o;
    debug_o           => debug_o
    );
end OpenBlaze8;

  
  

end architecture rtl;
