-------------------------------------------------------------------------------
-- Title      : Gated Clock
-- Project    : 
-------------------------------------------------------------------------------
-- File       : gated_clock.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2017-03-31
-- Last update: 2017-04-11
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-31  1.0      rosière	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

use work.nxpPackage.all;

entity gated_clock is
    port   (clk_i        : in  std_logic;
            cmd_i        : in  std_logic;
            clk_gated_o  : out std_logic);
end gated_clock;

architecture rtl of gated_clock is
begin
  ins_NXP_CKS: NXP_CKS
    port map (
      CKI => clk_i,
      CMD => cmd_i,
      CKO => clk_gated_o
    );
end rtl;

