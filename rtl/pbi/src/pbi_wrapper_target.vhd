-------------------------------------------------------------------------------
-- Title      : pbi wrapper target
-- Project    : pbi (Pico Bus)
-------------------------------------------------------------------------------
-- File       : pbi_wrapper_target.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2014-06-03
-- Last update: 2017-03-30
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-06-03  1.0      M. Rosière	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
--use work.param_pkg.all;
--use work.math_pkg.all;
use work.pbi_pkg.all;

entity pbi_wrapper_target is
  -- =====[ Parameters ]==========================
  generic (
--  SIZE_ADDR      : natural := 8;
    SIZE_DATA      : natural := 8;
--  SIZE_ADDR_ID   : natural := 8;
    SIZE_ADDR_IP   : natural := 0;
    ID             : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := (others => '0')
     );
  -- =====[ Interfaces ]==========================
  port (
    clk_i               : in    std_logic;
    cke_i               : in    std_logic;
    arstn_i             : in    std_logic; -- asynchronous reset

    -- To IP
    ip_cs_o             : out   std_logic;
    ip_re_o             : out   std_logic;
    ip_we_o             : out   std_logic;
    ip_addr_o           : out   std_logic_vector (SIZE_ADDR_IP-1 downto 0);
    ip_wdata_o          : out   std_logic_vector (SIZE_DATA-1    downto 0);
    ip_rdata_i          : in    std_logic_vector (SIZE_DATA-1    downto 0);
    ip_busy_i           : in    std_logic;
    
    -- From Bus
    pbi_ini_i           : in    pbi_ini_t;
    pbi_tgt_o           : out   pbi_tgt_t
    );
end pbi_wrapper_target;

architecture rtl of pbi_wrapper_target is
  constant SIZE_ADDR_ID : natural := PBI_ADDR_WIDTH-SIZE_ADDR_IP;
  
  alias pbi_id         : std_logic_vector(SIZE_ADDR_ID-1 downto 0) is pbi_ini_i.addr(PBI_ADDR_WIDTH-1 downto SIZE_ADDR_IP);
  alias tgt_id         : std_logic_vector(SIZE_ADDR_ID-1 downto 0) is ID            (PBI_ADDR_WIDTH-1 downto SIZE_ADDR_IP);

  signal cs             : std_logic;
  
begin  -- rtl

  -----------------------------------------------------------------------------
  -- Check Parameters
  -----------------------------------------------------------------------------
--  assert SIZE_ADDR_IP>PBI_ADDR_WIDTH report "Invalid value at the parameter 'SIZE_ADDR_IP'" severity FAILURE;
  
  -----------------------------------------------------------------------------
  -- Chip Select
  -----------------------------------------------------------------------------
  cs             <= '1' when (pbi_id = tgt_id) else
                    '0';

  -----------------------------------------------------------------------------
  -- To Bus
  -----------------------------------------------------------------------------
  pbi_tgt_o.rdata<= ip_rdata_i when cs='1' else
                    (others => '0');
  pbi_tgt_o.busy <= ip_busy_i  when cs='1' else
                    '0';
  
  -----------------------------------------------------------------------------
  -- To IP
  -----------------------------------------------------------------------------
  ip_cs_o        <= cs;
  ip_re_o        <= pbi_ini_i.re;
  ip_we_o        <= pbi_ini_i.we;
  ip_addr_o      <= pbi_ini_i.addr (ip_addr_o'range);
  ip_wdata_o     <= pbi_ini_i.wdata(ip_wdata_o'range);

end rtl;
