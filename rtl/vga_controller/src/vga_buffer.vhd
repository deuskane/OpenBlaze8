-------------------------------------------------------------------------------
-- Title      : vga_buffer
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : vga_buffer.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2014-01-04
-- Last update: 2017-05-13
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-04-28  0.2      rosière Update 
-- 2014-01-04  0.1      rosière	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

library work;
use work.math_pkg.all;

entity vga_buffer is 
  generic(WIDTH        : natural := 8;     -- Number bits to coding one character 
          DEPTH        : natural := 80*30  -- Depth of the text buffer
          );
  port   (clk_i        : in   std_logic;                                -- Clock
          arstn_i      : in   std_logic;                                -- Asynchonous reset (low)

          re_i         : in   std_logic;                                -- Read enable
          raddr_i      : in   std_logic_vector(clog2(DEPTH)-1 downto 0); -- Read address
          rovf_o       : out  std_logic;                                -- Overflow on read address
          rdata_o      : out  std_logic_vector(WIDTH-1 downto 0);       -- Read Code
          
          we_i         : in   std_logic;                                -- Write enable               
          waddr_i      : in   std_logic_vector(clog2(DEPTH)-1 downto 0); -- Write address              
          wdata_i      : in   std_logic_vector(WIDTH-1 downto 0);       -- Overflow on write address  
          wovf_o       : out  std_logic                                 -- Write Code
          );
end vga_buffer;

architecture rtl of vga_buffer is
  -----------------------------------------------------------------------------
  -- Constant / Parameter
  -----------------------------------------------------------------------------
  constant SIZE_ADDR               : natural := clog2(DEPTH);
  
  -----------------------------------------------------------------------------
  -- Type
  -----------------------------------------------------------------------------
  type buffer_t  is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);

  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  signal   buffer_r                : buffer_t;
  signal   rdata_r                 : std_logic_vector(WIDTH-1 downto 0);   -- Read Code
  
  -----------------------------------------------------------------------------
  -- Signal
  -----------------------------------------------------------------------------
  signal   rovf                    : std_logic; -- Overflow on read  address
  signal   wovf                    : std_logic; -- Overflow on write address

  signal   rdata_r_next            : std_logic_vector(WIDTH-1 downto 0);   -- Read Code (next)

begin
  -----------------------------------------------------------------------------
  -- Overflow condition
  -----------------------------------------------------------------------------
  rovf <= '1' when to_integer(unsigned(raddr_i)) >= DEPTH else
          '0';
  
  wovf <= '1' when to_integer(unsigned(waddr_i)) >= DEPTH else
          '0';

  -----------------------------------------------------------------------------
  -- Read Text 
  -----------------------------------------------------------------------------
  rdata_r_next <= buffer_r(to_integer(unsigned(raddr_i))) when re_i = '1' and rovf = '0' else
                  (others => '0') -- '\0' character
                  ;
  
  -----------------------------------------------------------------------------
  -- Character RAM
  -- WARNING : this ram is reseted and dual port, it's for a FPGA target
  --           Else, user must init the text buffer in "reset routine"
  -----------------------------------------------------------------------------
  process(clk_i,arstn_i)
  begin
    -- Asynchronous reset, set all buffer to '\0' character
    if arstn_i='0'
    then
    for x in 0 to DEPTH-1
    loop
      buffer_r(x) <= (others => '0'); -- '\0' character
    end loop;  -- y
    elsif rising_edge(clk_i)
    then
      -- Text Buffer write
      if (we_i = '1' and wovf = '0')
      then
          buffer_r(to_integer(unsigned(waddr_i))) <= wdata_i;
      end if;

      -- Text Buffer Read
      if (re_i = '1')
      then
        rdata_r <= rdata_r_next;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Output Buffer
  -----------------------------------------------------------------------------
  -- Read data
  rdata_o <= rdata_r;
--rdata_o <= rdata_r_next;

  -- Overflow
  rovf_o  <= rovf;
  wovf_o  <= wovf;

end rtl;
