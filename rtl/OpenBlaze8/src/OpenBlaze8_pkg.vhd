-------------------------------------------------------------------------------
-- Title      : OpenBlaze8_pkg
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-16
-- Last update: 2016-11-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-16  1.0      mrosiere	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package OpenBlaze8_pkg is

type OpenBlaze8_debug_t is record
  dummy : std_logic;
end record OpenBlaze8_debug_t;
  
component OpenBlaze8 is
  -- =====[ Parameters ]==========================
  generic (
     STACK_DEPTH     : natural := 32;
     RAM_DEPTH       : natural := 64;
     DATA_WIDTH      : natural := 8;
     ADDR_INST_WIDTH : natural := 10;
     REGFILE_DEPTH   : natural := 16;
     MULTI_CYCLE     : natural := 1);
  -- =====[ Interfaces ]==========================
  port (
    clock_i           : in  std_logic;
    clock_enable_i    : in  std_logic;
    reset_i           : in  std_logic;
    address_o         : out std_logic_vector(ADDR_INST_WIDTH downto 1);
    instruction_i     : in  std_logic_vector(18 downto 1);
    port_id_o         : out std_logic_vector(DATA_WIDTH downto 1);
    in_port_i         : in  std_logic_vector(DATA_WIDTH downto 1);
    out_port_o        : out std_logic_vector(DATA_WIDTH downto 1);
    read_strobe_o     : out std_logic;
    write_strobe_o    : out std_logic;
    interrupt_i       : in  std_logic;
    interrupt_ack_o   : out std_logic;
    debug_o           : out OpenBlaze8_debug_t
    );
end component;
  
end package OpenBlaze8_pkg;
