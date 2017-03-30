-------------------------------------------------------------------------------
-- Title      : stack
-- Project    : stack
-------------------------------------------------------------------------------
-- File       : stack.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2017-03-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2016-11-11  1.0      mrosiere Created
-- 2017-03-05  1.0.1    mrosiere Fix sensitive list
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;
use work.ram_1r1w_pkg.all;

entity stack is
  -- =====[ Parameters ]==========================
  generic (
     WIDTH     : natural := 32;
     DEPTH     : natural := 4;
     OVERWRITE : natural := 0
     );
  -- =====[ Interfaces ]==========================
  port (
    clk_i       : in  std_logic;
    cke_i       : in  std_logic;
    arstn_i      : in  std_logic;
    -- stack push
    push_val_i  : in  std_logic;
    push_ack_o  : out std_logic;
    push_data_i : in  std_logic_vector(WIDTH -1 downto 0);
    -- stack pop
    pop_val_o   : out std_logic;
    pop_ack_i   : in  std_logic;
    pop_data_o  : out std_logic_vector(WIDTH -1 downto 0));
end stack;
architecture rtl of stack is
  -- =====[ Types ]===============================

  -- =====[ Signals ]=============================

  signal push_ack       : std_logic;
  signal pop_val        : std_logic;
  signal push           : std_logic;
  signal pop            : std_logic;
                               
  signal nb_elt_r       : unsigned(log2(DEPTH)+1 -1 downto 0);
  signal ptr_last_r     : unsigned(log2(DEPTH)   -1 downto 0);
  signal empty          : std_logic;
  signal full           : std_logic;

  signal ram_read_val   : std_logic;
  signal ram_read_addr  : std_logic_vector(log2(DEPTH)   -1 downto 0);
  signal ram_read_data  : std_logic_vector(WIDTH         -1 downto 0);
  signal ram_write_val  : std_logic;
  signal ram_write_addr : std_logic_vector(log2(DEPTH)   -1 downto 0);
  signal ram_write_data : std_logic_vector(WIDTH         -1 downto 0);

  begin  -- rtl

  -----------------------------------------------------------------------------
  -- Output
  -----------------------------------------------------------------------------
  push_ack_o   <= push_ack;

  pop_val_o    <= pop_val;
  pop_data_o   <= ram_read_data;

  -----------------------------------------------------------------------------
  -- Flags
  -----------------------------------------------------------------------------
  full         <= '1' when (nb_elt_r(log2(DEPTH)) = '1') else '0';
  empty        <= '1' when (nb_elt_r = 0) else '0';

  -----------------------------------------------------------------------------
  -- Commands
  -----------------------------------------------------------------------------
  pop_val      <= not empty;
  pop          <= pop_val and pop_ack_i;
  
  gen_OVERWRITE_n: if (OVERWRITE = 0)
  generate
  push_ack     <= not full; 
  push         <= push_val_i and push_ack;
  end generate gen_OVERWRITE_n;

  gen_OVERWRITE  : if (OVERWRITE /= 0)
  generate
  push_ack     <= '1'; 
  push         <= push_val_i;
  end generate gen_OVERWRITE;
  
  -----------------------------------------------------------------------------
  -- Transition
  -----------------------------------------------------------------------------
  transition: process (clk_i)
  begin  -- process transition
    if (clk_i'event and clk_i = '1')
    then  -- rising clk_i edge
      if (arstn_i = '0')
      then
        nb_elt_r      <= (others => '0');
        ptr_last_r    <= (others => '0');
      else
        if (cke_i = '1')
        then
          -- push and pop
          if     ((push ='1') and (pop='1'))
          then
          -- push only
          elsif  (push ='1')
          then
            if (full = '0')
            then
              nb_elt_r <= nb_elt_r  + 1;
            end if;
            ptr_last_r <= ptr_last_r+ 1;
          -- pop only
          elsif  (pop ='1')
          then
            nb_elt_r   <= nb_elt_r  - 1;
            ptr_last_r <= ptr_last_r- 1;
          end if;
        end if;
      end if;
    end if;
  end process transition;
  
  -----------------------------------------------------------------------------
  -- RAM Instance
  -----------------------------------------------------------------------------
  ram_write_val  <= push;
  ram_write_addr <= std_logic_vector(ptr_last_r) when  ram_read_val = '0' else
                    ram_read_addr;
  ram_write_data <= push_data_i;

  ram_read_val   <= pop;
  ram_read_addr  <= std_logic_vector(ptr_last_r-1);

  ins_ram_1r1w : ram_1r1w
    generic map
    (WIDTH    => WIDTH
    ,DEPTH    => DEPTH
    )
    port map
    (clk_i    => clk_i
    ,cke_i    => cke_i
--  ,arstn_i  => arstn_i        
    ,re_i     => ram_read_val  
    ,raddr_i  => ram_read_addr 
    ,rdata_o  => ram_read_data 
    ,we_i     => ram_write_val 
    ,waddr_i  => ram_write_addr
    ,wdata_i  => ram_write_data
    );

end rtl;
