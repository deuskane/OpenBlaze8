-------------------------------------------------------------------------------
-- Title      : OpenBlaze8_Embedded
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Embedded.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-20
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
-- 2016-11-20  1.0      cybertronic	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;
use work.OpenBlaze8_pkg.all;

entity OpenBlaze8_Embedded is
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
    port_id_o         : out std_logic_vector(DATA_WIDTH -1 downto 0);
    in_port_i         : in  std_logic_vector(DATA_WIDTH -1 downto 0);
    out_port_o        : out std_logic_vector(DATA_WIDTH -1 downto 0);
    read_strobe_o     : out std_logic;
    write_strobe_o    : out std_logic;
    interrupt_i       : in  std_logic;
    interrupt_ack_o   : out std_logic;
    debug_o           : out OpenBlaze8_debug_t
    );
end OpenBlaze8_Embedded;

architecture rtl of OpenBlaze8_Embedded is

  signal address         : std_logic_vector(ADDR_INST_WIDTH -1 downto 0);
  signal instruction     : std_logic_vector(18 -1 downto 0);
  
begin  -- architecture rtl

  ins_OpenBlaze8 : OpenBlaze8
    generic map
    (STACK_DEPTH     => STACK_DEPTH    
    ,RAM_DEPTH       => RAM_DEPTH      
    ,DATA_WIDTH      => DATA_WIDTH     
    ,ADDR_INST_WIDTH => ADDR_INST_WIDTH
    ,REGFILE_DEPTH   => REGFILE_DEPTH  
    ,MULTI_CYCLE     => MULTI_CYCLE    
    )
    port map
    (clock_i           => clock_i        
    ,clock_enable_i    => clock_enable_i 
    ,reset_i           => reset_i        
    ,address_o         => address
    ,instruction_i     => instruction
    ,port_id_o         => port_id_o      
    ,in_port_i         => in_port_i      
    ,out_port_o        => out_port_o     
    ,read_strobe_o     => read_strobe_o  
    ,write_strobe_o    => write_strobe_o 
    ,interrupt_i       => interrupt_i    
    ,interrupt_ack_o   => interrupt_ack_o
    ,debug_o           => debug_o        
    );

  ins_ROM : entity work.OpenBlaze8_ROM(mix)
    
    port map
    (clk             => clock_i
    ,reset           => open
    ,address         => address
    ,instruction     => instruction
    );

  
end architecture rtl;
