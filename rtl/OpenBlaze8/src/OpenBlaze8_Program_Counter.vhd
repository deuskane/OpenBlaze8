-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Program Counter
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Program_Counter.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-03-21
-- Last update: 2016-11-20
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-03-21  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_Program_Counter is
  -- =====[ Parameters ]==========================
  generic (
     size_addr_inst : natural := 10);
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic;

    pc_write_en_i        : in  std_logic;                                  --write in PC

    pc_next_mux_i        : in  std_logic_vector( 3 downto 1);              -- Next Program Counter Source
                                                                      -- 001 pc+1
                                                                      -- 110 Interrupt Go to ISR
                                                                      -- 100 call/jump (use immediat)
                                                                      -- 011 ret  (use stack+1)
                                                                      -- 010 reti (use stack)

    decode_address_i     : in  std_logic_vector(size_addr_inst downto 1);  -- Decoded branch condition

    stack_push_data_o    : out std_logic_vector(size_addr_inst downto 1);  -- Stack push data
    stack_pop_data_i     : in  std_logic_vector(size_addr_inst downto 1);  -- Stack push data

    inst_address_o       : out std_logic_vector(size_addr_inst downto 1)   -- Instruction Address

    );
end OpenBlaze8_Program_Counter;

architecture rtl of OpenBlaze8_Program_Counter is

  signal pc_r      : std_logic_vector(size_addr_inst downto 1);  -- Program Counter
  signal pc_next   : std_logic_vector(size_addr_inst downto 1);  -- Program Counter
  signal pc_r_next : std_logic_vector(size_addr_inst downto 1);  -- Program Counter

begin  -- rtl
  -----------------------------------------------------------------------------
  -- To Instruction ROM
  -----------------------------------------------------------------------------
  inst_address_o <= pc_r;

  -----------------------------------------------------------------------------
  -- Next Program Counter
  -----------------------------------------------------------------------------
  pc_next <=
    (others => '1')  when (pc_next_mux_i(3 downto 2) = "11") else -- Go to ISR
    decode_address_i when (pc_next_mux_i(3 downto 2) = "10") else -- CALL/JUMP
    stack_pop_data_i when (pc_next_mux_i(3 downto 2) = "01") else -- RETURN/RETURNi
    pc_r;

  pc_r_next <=
    pc_next when pc_next_mux_i(1) = '0' else
    std_logic_vector(unsigned(pc_next)+1);
  
  -----------------------------------------------------------------------------
  -- To Stack
  -----------------------------------------------------------------------------
  stack_push_data_o <= pc_r;

  -----------------------------------------------------------------------------
  -- Program Counter
  -----------------------------------------------------------------------------
  transition: process (clock_i)
  begin  -- process transition
    if clock_i'event and clock_i = '1' then
      if reset_i = '1' then
        -- synchronous reset
        pc_r <= (others => '0');
      elsif clock_enable_i = '1' then
        if (pc_write_en_i = '1') then
          pc_r <= pc_r_next;
        end if;
      end if;
    end if;
  end process transition;

end rtl;
