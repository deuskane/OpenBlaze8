-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 ALU
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_ALU.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-05-20
-- Last update: 2017-03-31
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-05-20  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_ALU is
  -- =====[ Parameters ]==========================
  generic (
     size_data      : natural := 8);
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

    -- From Control
    alu_op_arith_cy_i    : in  std_logic;
    alu_op_arith_i       : in  std_logic;                      -- Arithmetic instructions
    alu_op_logic_i       : in  std_logic_vector( 2 downto 1);          -- Logic instructions

    alu_op_rotate_shift_right_i : in  std_logic;  -- Rotate or shift is right
    alu_op_rotate_shift_i       : in  std_logic_vector( 2 downto 1);  -- Rotate or shift operation :
                                                  -- 00 : insert the flag C (sla,sra)
                                                  -- 01 : insert the data msb (rl,srx)
                                                  -- 10 : insert the data lsb (rr,slx)
                                                  -- 11 : insert a constant   (sl0, sl1, sr0, sr1)

    alu_op_rotate_shift_cst_i   : in   std_logic;  -- Rotate or shift is right

    alu_op_type_i               : in   std_logic_vector( 2 downto 1);         -- Operation type
                                                                      -- 00 Load
                                                                      -- 01 Rotate/Shift
                                                                      -- 11 Arith
                                                                      -- 10 Logic

--  alu_op_flag_z_i             : in  std_logic;                      -- Operation on flag z
--                                                                    -- 1 opx is nul
--                                                                    -- 0 res is nul

    alu_op_flag_c_i             : in  std_logic_vector( 2 downto 1);  -- Operation on flag c
                                                                      -- 01 res MSB (arith or compare)
                                                                      -- 00 0 (logic)
                                                                      -- 10 bit out (rotate/shift)
                                                                      -- 11 odd (test)
    

    -- From Operand
    alu_op1_i            : in  std_logic_vector(size_data downto 1);
    alu_op2_i            : in  std_logic_vector(size_data downto 1);

    -- From Flag
    flag_c_i             : in  std_logic;
    flag_z_i             : in  std_logic;

    -- To result
    alu_res_o            : out std_logic_vector(size_data downto 1);

    -- To flag
    flag_c_o             : out std_logic;
    flag_z_o             : out std_logic
    );
end OpenBlaze8_ALU;

architecture rtl of OpenBlaze8_ALU is
  signal alu_op1              : unsigned(size_data+1 downto 1);
  signal alu_op2              : unsigned(size_data+1 downto 1);
  signal flag_c               : unsigned(1 downto 1);
  
  signal res_add              : unsigned(size_data+1 downto 1);
  signal res_add_nc           : unsigned(size_data+1 downto 1);
  signal res_add_c            : unsigned(size_data+1 downto 1);
  signal res_sub              : unsigned(size_data+1 downto 1);
  signal res_sub_nc           : unsigned(size_data+1 downto 1);
  signal res_sub_c            : unsigned(size_data+1 downto 1);
  signal res_and              : unsigned(size_data downto 1);
  signal res_or               : unsigned(size_data downto 1);
  signal res_xor              : unsigned(size_data downto 1);
  signal res_arith            : unsigned(size_data+1 downto 1);
  signal res_logic            : unsigned(size_data downto 1);
  signal res_load             : unsigned(size_data downto 1);
  signal res                  : unsigned(size_data downto 1);

  signal res_for_zero         : unsigned(size_data downto 1);

  
  signal res_rotate_shift_bit_in  : std_logic;
  signal res_rotate_shift_bit_out : std_logic;
  signal res_rotate_shift         : std_logic_vector(size_data downto 1);

  signal test_gt  : std_logic;
  signal test_odd : std_logic;
  signal test_zero: std_logic;

begin  -- rtl

  -----------------------------------------------------------------------------
  -- Operand
  -----------------------------------------------------------------------------
  alu_op1   <= unsigned('0'&alu_op1_i);
  alu_op2   <= unsigned('0'&alu_op2_i);
  flag_c(1) <= flag_c_i;

  -----------------------------------------------------------------------------
  -- Result
  -----------------------------------------------------------------------------
  res_add_nc  <= alu_op1 + alu_op2;
  res_add_c   <= alu_op1 + alu_op2 + flag_c;
  res_add     <= res_add_c when alu_op_arith_cy_i = '1' else
                 res_add_nc;
  
  res_sub_nc  <= alu_op1 - alu_op2;
  res_sub_c   <= alu_op1 - alu_op2 - flag_c; 
  res_sub     <= res_sub_c when alu_op_arith_cy_i = '1' else
                 res_sub_nc;

  res_and     <= alu_op1(size_data downto 1) and alu_op2(size_data downto 1); 
  res_or      <= alu_op1(size_data downto 1) or  alu_op2(size_data downto 1); 
  res_xor     <= alu_op1(size_data downto 1) xor alu_op2(size_data downto 1);
  res_arith   <= res_sub when alu_op_arith_i = '1'  else  -- add/addcy
                 res_add;
  res_logic   <= res_and when alu_op_logic_i(2) = '0' else
                 res_or  when alu_op_logic_i(1) = '0' else
                 res_xor;
  res_load    <= alu_op2(size_data downto 1);

  res_rotate_shift_bit_in <= flag_c_i             when alu_op_rotate_shift_i = "00" else
                             alu_op1_i(size_data) when alu_op_rotate_shift_i = "01" else
                             alu_op1_i(1)         when alu_op_rotate_shift_i = "10" else
                             alu_op_rotate_shift_cst_i;

  res_rotate_shift_bit_out<= alu_op1_i(1)         when alu_op_rotate_shift_right_i = '1' else
                             alu_op1_i(size_data);
  
  res_rotate_shift        <= res_rotate_shift_bit_in & alu_op1_i(size_data downto 2) when alu_op_rotate_shift_right_i = '1' else
                             alu_op1_i(7 downto 1) & res_rotate_shift_bit_in;

  res <= res_arith(size_data downto 1) when alu_op_type_i = "11" else  -- arith
         res_logic                     when alu_op_type_i = "10" else  -- logic
         unsigned(res_rotate_shift)    when alu_op_type_i = "01" else  -- rotate/shift
         res_load;

  alu_res_o <= std_logic_vector(res);
  -----------------------------------------------------------------------------
  -- Flag
  -----------------------------------------------------------------------------
--res_for_zero <= res when alu_op_flag_z_i = '0' else
--                alu_op1(size_data downto 1);

  res_for_zero <= res;
  
  p_test_zero: process (res_for_zero)
    variable zero : std_logic;
  begin  -- process p_test_zero
    zero := '1';
    for i in res_for_zero'range loop
      zero := zero and not res_for_zero(i);      -- for test, use res_and
    end loop;  -- i
    test_zero <= zero;
  end process p_test_zero;

  p_test_odd: process (res_and)
    variable odd : std_logic;
  begin  -- process p_test_odd
    odd := '0';
    for i in res_and'range loop
      odd := odd xor res_and(i);
    end loop;  -- i
    test_odd <= odd;
  end process p_test_odd;

  
  test_gt <= '1' when alu_op2 > alu_op1 else
             '0';
  
  
--flag_c_o <= res_arith(size_data+1)   when alu_op_flag_c_i = "011" else  -- add/addcy/sub/subcy
--            test_gt                  when alu_op_flag_c_i = "110" else  -- compare
--            res_arith(size_data+1)   when alu_op_flag_c_i = "110" else  -- compare
--            test_odd                 when alu_op_flag_c_i = "111" else  -- test
--            res_rotate_shift_bit_out when alu_op_flag_c_i = "100" else  -- rotate/shift
--            '0'                       -- and,or,xor
--            ;

  flag_c_o <= res_arith(size_data+1)   when alu_op_flag_c_i = "01" else  -- add/addcy/sub/subcy
              test_odd                 when alu_op_flag_c_i = "11" else  -- test
              res_rotate_shift_bit_out when alu_op_flag_c_i = "10" else  -- rotate/shift
              '0'                       -- and,or,xor
              ;
  
  flag_z_o <= test_zero   -- add/addcy/sub/subcy/and,or,xor,test
              ;
end rtl;
