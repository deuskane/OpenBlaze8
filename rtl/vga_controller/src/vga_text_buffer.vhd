-------------------------------------------------------------------------------
-- Title      : vga_text_buffer
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : vga_text_buffer.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2014-01-04
-- Last update: 2017-03-31
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-01-04  0.1      rosière	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity vga_text_buffer is
  generic(SIZE_CODE         : natural := 8;
          DEPTH             : natural := 80*30;
          SIZE_ADDR         : natural := 12
          );
  port   (clk_i          : in   std_logic;
          arstn_i        : in   std_logic;

          read_en_i        : in   std_logic;
          read_addr_i      : in   std_logic_vector(SIZE_ADDR-1 downto 0);
          read_code_o      : out  std_logic_vector(SIZE_CODE-1 downto 0);

          write_en_i       : in   std_logic;
          write_addr_i     : in   std_logic_vector(SIZE_ADDR-1 downto 0);
          write_code_i     : in   std_logic_vector(SIZE_CODE-1 downto 0)
          );
end vga_text_buffer;

architecture rtl of vga_text_buffer is
  -- =====[ Types ]===============================
  type text_buffer_t  is array (0 to DEPTH-1) of std_logic_vector(SIZE_CODE-1 downto 0);

  -- =====[ Registers ]===========================
  
  -- =====[ Signals ]=============================
  signal   text_buffer_r           : text_buffer_t;

begin
  read_code_o <= text_buffer_r(to_integer(unsigned(read_addr_i))) when read_en_i = '1' else
               (others => '0');
  
  process(arstn_i,clk_i)
  begin 
    if arstn_i='0'
    then
    for x in 0 to DEPTH-1 loop
      text_buffer_r(x) <= (others => '0');
    end loop;  -- y
    elsif rising_edge(clk_i)
    then 
      if (write_en_i = '1')
      then
          text_buffer_r(to_integer(unsigned(write_addr_i))) <= write_code_i;
      end if;
    end if;
  end process;
  
end rtl;
