-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Decode
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Decode.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-03-22
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
-- 2014-03-22  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_Decode is
  -- =====[ Parameters ]==========================
  generic (
     multi_cycle    : natural := 1);
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

    instruction_i        : in  std_logic_vector(18 downto 1); -- Instruction from the ROM

    decode_opcode1_o     : out std_logic_vector( 5 downto 1);
    decode_opcode2_o     : out std_logic_vector( 4 downto 1);
    decode_operand_mux_o : out std_logic                    ;
    decode_branch_cond_o : out std_logic_vector( 3 downto 1);
    decode_num_regx_o    : out std_logic_vector( 4 downto 1);
    decode_num_regy_o    : out std_logic_vector( 4 downto 1);
    decode_imm_o         : out std_logic_vector(10 downto 1);

    decode_inhib_i       : in  std_logic                      -- Need inhibit the instruction
    
  );
end OpenBlaze8_Decode;

architecture rtl of OpenBlaze8_Decode is
  -----------------------------------------------------------------------------
  -- opcode1          : Instruction type (add, shift, ...)
  -- opcode2          : Instruction operation (rl, rr, ...)
  -- operand_mux      : Use immediat (0) or register (1)
  -- branch condition : The flag used by the branchment (C,NC,Z,NZ)
  -- num_regx         : register number for operand X
  -- num_regy         : register number for operand Y
  -- imm10            : immediat on 10bits
  -----------------------------------------------------------------------------
  alias decoded_opcode1     : std_logic_vector( 5 downto 1) is instruction_i(18 downto 14);
  alias decoded_opcode2     : std_logic_vector( 4 downto 1) is instruction_i( 4 downto  1);
  alias decoded_operand_mux : std_logic                     is instruction_i(13);
  alias decoded_branch_cond : std_logic_vector( 3 downto 1) is instruction_i(13 downto 11);
  alias decoded_num_regx    : std_logic_vector( 4 downto 1) is instruction_i(12 downto 9);
  alias decoded_num_regy    : std_logic_vector( 4 downto 1) is instruction_i( 8 downto 5);
  alias decoded_imm         : std_logic_vector(10 downto 1) is instruction_i(10 downto 1);

  -- decode_xxx is decoded_xxx with interruption inhib
  signal decode_opcode1     : std_logic_vector( 5 downto 1);
  signal decode_opcode2     : std_logic_vector( 4 downto 1);
  signal decode_operand_mux : std_logic                    ;
  signal decode_branch_cond : std_logic_vector( 3 downto 1);
  signal decode_num_regx    : std_logic_vector( 4 downto 1);
  signal decode_num_regy    : std_logic_vector( 4 downto 1);
  signal decode_imm         : std_logic_vector(10 downto 1);
  
begin  -- rtl
  -----------------------------------------------------------------------------
  -- Decoded operation (before interruption mask)
  -- if interruption -> change current instruction in load sX,sX
  -----------------------------------------------------------------------------
  decode_opcode1       <= decoded_opcode1     when decode_inhib_i = '0' else (others => '0');
  decode_opcode2       <= decoded_opcode2     ;
  decode_operand_mux   <= decoded_operand_mux when decode_inhib_i = '0' else '1';
  decode_branch_cond   <= decoded_branch_cond ;
  decode_num_regx      <= decoded_num_regx    ;
  decode_num_regy      <= decoded_num_regy    when decode_inhib_i = '0' else decode_num_regx;
  decode_imm           <= decoded_imm         ;

  -----------------------------------------------------------------------------
  -- Decoded operation
  -----------------------------------------------------------------------------
  decode_opcode1_o     <= decode_opcode1     ;
  decode_opcode2_o     <= decode_opcode2     ;
  decode_operand_mux_o <= decode_operand_mux ;
  decode_branch_cond_o <= decode_branch_cond ;
  decode_num_regx_o    <= decode_num_regx    ;
  decode_num_regy_o    <= decode_num_regy    ;
  decode_imm_o         <= decode_imm         ;
  
end rtl;
