-------------------------------------------------------------------------------
-- Title      : OpenBlaze8 Control
-- Project    : OpenBlaze8
-------------------------------------------------------------------------------
-- File       : OpenBlaze8_Control.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-05-24
-- Last update: 2016-11-22
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-05-24  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;

entity OpenBlaze8_Control is
  -- =====[ Interfaces ]==========================
  port (
    clock_i              : in  std_logic;
    clock_enable_i       : in  std_logic;
    reset_i              : in  std_logic; -- synchronous reset

    -- From Clock
    cycle_phase_i        : in  std_logic;                      -- 0 = first cycle, 1 = second cycle

    -- From Decode
    decode_opcode1_i            : in  std_logic_vector( 5 downto 1);  -- Instruction type (add, shift, ...)
    decode_opcode2_i            : in  std_logic_vector( 4 downto 1);  -- Instruction operation (rl, rr, ...)        
    decode_operand_mux_i        : in  std_logic                    ;  -- Use immediat (0) or register (1)
    decode_branch_cond_i        : in  std_logic_vector( 3 downto 1);  -- The flag used by the branchment (C,NC,Z,NZ)

    -- To Decode
    decode_inhib_o              : out std_logic;                      -- Need inhibit the instruction
    
    -- To Program Counter
    pc_write_en_o               : out std_logic;                      -- PC must be modify
    pc_next_mux_o               : out std_logic_vector( 3 downto 1);  -- Next Program Counter Source
                                                                      -- 001 pc+1
                                                                      -- 110 Interrupt Go to ISR
                                                                      -- 100 call/jump (use immediat)
                                                                      -- 011 ret  (use stack+1)
                                                                      -- 010 reti (use stack)

    -- To Stack
    stack_push_val_o            : out std_logic;                      -- Stack Push enable
    stack_pop_ack_o             : out std_logic;                      -- Stack Pop  enable
                                
    -- To RegFile               
    regx_read_en_o              : out std_logic;                      -- First  register (x) read  enable
    regx_write_en_o             : out std_logic;                      -- First  register (x) write enable
    regy_read_en_o              : out std_logic;                      -- Second register (y) read  enable
                                
    -- To ALU                   
    alu_op_arith_cy_o           : out std_logic;                      -- '1' when instruction is addcy / subcy
    alu_op_arith_o              : out std_logic;                      -- Arithmetic instructions
                                                                      -- 0 Add/Addcy
                                                                      -- 1 sub/subcy
                                
    alu_op_logic_o              : out std_logic_vector( 2 downto 1);  -- Logic instructions
                                                                      -- 0x and
                                                                      -- 10 or
                                                                      -- 11 xor

    alu_op_rotate_shift_right_o : out std_logic;                      -- Rotate or shift is right
    alu_op_rotate_shift_o       : out std_logic_vector( 2 downto 1);  -- Rotate or shift operation :
                                                                      -- 00 : insert the flag C (sla,sra)
                                                                      -- 01 : insert the data msb (rl,srx)
                                                                      -- 10 : insert the data lsb (rr,slx)
                                                                      -- 11 : insert a constant   (sl0, sl1, sr0, sr1)

    alu_op_rotate_shift_cst_o   : out std_logic;                      -- Rotate or shift is right

    alu_op_type_o               : out std_logic_vector( 2 downto 1);  -- Operation type
                                                                      -- 00 Load
                                                                      -- 01 Rotate/Shift
                                                                      -- 11 Arith
                                                                      -- 10 Logic

--  alu_op_flag_z_o             : out std_logic;                      -- Operation on flag z
--                                                                    -- 1 opx is nul
--                                                                    -- 0 res is nul

    alu_op_flag_c_o             : out std_logic_vector( 2 downto 1);  -- Operation on flag c
                                                                      -- 00 0          (logic)
                                                                      -- 01 result MSB (arith/compare)
                                                                      -- 10 bit out    (rotate/shift)
                                                                      -- 11 odd       (test)

    -- To Result
    result_mux_o                : out std_logic_vector(2 downto 1);   -- Result source :
                                                                      -- 1x : alu
                                                                      -- 01 : RAM
                                                                      -- 00 : io
    
    -- To LoadStore
    io_access_en_o              : out std_logic;                       -- Have input or output instructions
    io_read_en_o                : out std_logic;                       -- 1 on the second cycle of input  instruction
    io_write_en_o               : out std_logic;                       -- 1 on the second cycle of output instruction

    -- To RAM
    ram_read_en_o               : out std_logic;                       -- 1 on                     fetch instruction
    ram_write_en_o              : out std_logic;                       -- 1 on the second cycle of store instruction
    
    -- From Flag
    flag_c_i                    : in  std_logic;                      -- Flag Carry
    flag_z_i                    : in  std_logic;                      -- Flag Zero

    -- To Flag
    flag_write_c_o              : out std_logic;  -- Flag write carry
    flag_write_z_o              : out std_logic;  -- Flag write zero
                                
    flag_save_o                 : out std_logic;  -- Interruption
    flag_restore_o              : out std_logic;  -- RETI

    -- From Interrupt
    it_en_i                     : in  std_logic;  -- Have an unmasked interruption
    
    -- To Interrupt
    interrupt_enable_o          : out std_logic;  -- eint or reti enable
    interrupt_disable_o         : out std_logic   -- dint or reti disable
    );
end OpenBlaze8_Control;

architecture rtl of OpenBlaze8_Control is

  -- Instruction decode
  signal inst_add          : std_logic;
  signal inst_addcy        : std_logic;
  signal inst_and          : std_logic;
  signal inst_call         : std_logic;
  signal inst_compare      : std_logic;
  signal inst_interrupt    : std_logic;
  signal inst_fetch        : std_logic;
  signal inst_input        : std_logic;
  signal inst_jump         : std_logic;
  signal inst_load         : std_logic;
  signal inst_or           : std_logic;
  signal inst_output       : std_logic;
  signal inst_return       : std_logic;
  signal inst_returni      : std_logic;
  signal inst_rotate_shift : std_logic;
  signal inst_store        : std_logic;
  signal inst_sub          : std_logic;
  signal inst_subcy        : std_logic;
  signal inst_test         : std_logic;
  signal inst_xor          : std_logic;

  signal branch_take        : std_logic;

  signal inst_rw_x_r_y : std_logic;     -- Instruction Read/Write Reg X and Read Reg Y
  signal inst_r_x_r_y  : std_logic;     -- Instruction Read       Reg X and Read Reg Y
  signal inst_rw_x     : std_logic;     -- Instruction Read/Write Reg X

  signal flag_write : std_logic;
  
  signal cycle_0 : std_logic;
  signal cycle_1 : std_logic;
begin  -- rtl

  cycle_0 <= not cycle_phase_i;
  cycle_1 <=     cycle_phase_i;
  
  -----------------------------------------------------------------------------
  -- Instruction decode
  -----------------------------------------------------------------------------
  inst_add          <= '1' when decode_opcode1_i = "01100" else '0';
  inst_addcy        <= '1' when decode_opcode1_i = "01101" else '0';
  inst_and          <= '1' when decode_opcode1_i = "00101" else '0';
  inst_call         <= '1' when decode_opcode1_i = "11000" else '0';
  inst_compare      <= '1' when decode_opcode1_i = "01010" else '0';
  inst_interrupt    <= '1' when decode_opcode1_i = "11110" else '0';
  inst_fetch        <= '1' when decode_opcode1_i = "00011" else '0';
  inst_input        <= '1' when decode_opcode1_i = "00010" else '0';
  inst_jump         <= '1' when decode_opcode1_i = "11010" else '0';
  inst_load         <= '1' when decode_opcode1_i = "00000" else '0';
  inst_or           <= '1' when decode_opcode1_i = "00110" else '0';
  inst_output       <= '1' when decode_opcode1_i = "10110" else '0';
  inst_return       <= '1' when decode_opcode1_i = "10101" else '0';
  inst_returni      <= '1' when decode_opcode1_i = "11100" else '0';
  inst_rotate_shift <= '1' when decode_opcode1_i = "10000" else '0';
  inst_store        <= '1' when decode_opcode1_i = "10111" else '0';
  inst_sub          <= '1' when decode_opcode1_i = "01110" else '0';
  inst_subcy        <= '1' when decode_opcode1_i = "01111" else '0';
  inst_test         <= '1' when decode_opcode1_i = "01001" else '0';
  inst_xor          <= '1' when decode_opcode1_i = "00111" else '0';

  -----------------------------------------------------------------------------
  -- Branch condition
  -----------------------------------------------------------------------------
  -- branch cond
  -- 0 x x : inconditionnal
  -- 1 0 0 : branch if  z
  -- 1 0 1 : branch if /z
  -- 1 1 0 : branch if  c
  -- 1 1 1 : branch if /c
  branch_take <=
    (not decode_branch_cond_i(3) or
     (not decode_branch_cond_i(2) and (decode_branch_cond_i(1) xor flag_z_i)) or
     (    decode_branch_cond_i(2) and (decode_branch_cond_i(1) xor flag_c_i))
     );
  
  -----------------------------------------------------------------------------
  -- Source of Next PC
  -----------------------------------------------------------------------------
  pc_write_en_o <= cycle_0;

  -- 000 unused
  -- 101 unused
  -- 111 unused
  -- 001 pc+1
  -- 011 return  (pop+1)
  -- 010 returni (pop)
  -- 100 call/jump (imm)
  -- 110 Go to ISR

  pc_next_mux_o <=
    "110" when it_en_i = '1' else
    "011" when (inst_return  = '1' and branch_take = '1') else -- RETURN
    "010" when (inst_returni = '1')                       else -- RETURNI
    "100" when ((inst_call    = '1' and branch_take = '1') or   -- CALL
                (inst_jump    = '1' and branch_take = '1'))else -- JUMP
    "001";

  -----------------------------------------------------------------------------
  -- Stack Command
  -----------------------------------------------------------------------------
  stack_push_val_o <=
    cycle_0 when (it_en_i = '1' or
                  (inst_call    = '1' and branch_take = '1')) else
    '0';
  
  stack_pop_ack_o <= 
    cycle_0 when ((inst_return  = '1' and branch_take = '1') or
                  (inst_returni = '1')) else
    '0';

  -----------------------------------------------------------------------------
  -- To Decode
  -----------------------------------------------------------------------------
  decode_inhib_o <= '0';

  -----------------------------------------------------------------------------
  -- RegFile Access
  -----------------------------------------------------------------------------

  inst_rw_x_r_y  <= (    inst_add
                      or inst_addcy
                      or inst_and
                      or inst_fetch
                      or inst_input
                      or inst_load         
                      or inst_or           
                      or inst_sub          
                      or inst_subcy        
                      or inst_xor          
                         );
  inst_r_x_r_y   <= (    inst_compare
                      or inst_output       
                      or inst_store        
                      or inst_test         
                         );
  inst_rw_x      <= (    inst_rotate_shift 
                        );

  regx_read_en_o <= (   inst_rw_x_r_y
                     or inst_r_x_r_y
                     or inst_rw_x
                        );
    
  regx_write_en_o<= (   inst_rw_x_r_y
                     or inst_rw_x
                        ) and cycle_1;
  regy_read_en_o <= ((  inst_rw_x_r_y
                     or inst_r_x_r_y
                         )
                     and decode_operand_mux_i
                     );

  -----------------------------------------------------------------------------
  -- ALU control
  -----------------------------------------------------------------------------
  alu_op_arith_cy_o           <= decode_opcode1_i(1);
  alu_op_arith_o              <= decode_opcode1_i(2);
  alu_op_logic_o              <= decode_opcode1_i(2 downto 1);

  alu_op_rotate_shift_o       <= decode_opcode2_i(3 downto 2);
  alu_op_rotate_shift_right_o <= decode_opcode2_i(4);
  alu_op_rotate_shift_cst_o   <= decode_opcode2_i(1);

  alu_op_type_o               <= "11" when decode_opcode1_i(5 downto 3) = "011"   else  -- add/addcy/sub/subcy
                                 "10" when decode_opcode1_i(5 downto 3) = "001"   else  -- logic
                                 '1'&decode_opcode1_i(2) when decode_opcode1_i(5 downto 3) = "010"  else  -- compare/test
--                               "11" when decode_opcode1_i(5 downto 2) = "0101"  else  -- compare
--                               "10" when decode_opcode1_i(5 downto 2) = "0100"  else  -- test
                                 "01" when decode_opcode1_i(5 downto 3) = "100"   else  -- rotate/shift
                                 "00";

--  alu_op_flag_z_o             <= '0';
  
--  alu_op_flag_z_o             <= '1' when (--inst_and = '1' or
--                                           --inst_or  = '1' or
--                                           --inst_xor = '1' or
--                                           inst_rotate_shift = '1') else
--                               
--                                 '0';   -- add/addcy/sub/subcy/and,test

--alu_op_flag_c_o             <= "110" when inst_compare = '1' else
--                               "111" when inst_test    = '1' else
--                               decode_opcode1_i(5 downto 3);

  alu_op_flag_c_o             <= "11" when inst_test    = '1' else
                                 decode_opcode1_i(5 downto 4);
  
  -----------------------------------------------------------------------------
  -- Result multiplexor
  -----------------------------------------------------------------------------
  result_mux_o(1) <= decode_opcode1_i (1);  -- 1=RAM, 0 =io
  result_mux_o(2) <= '0' when decode_opcode1_i (5 downto 2) = "0001" else -- fetch/input
                     '1';

  -----------------------------------------------------------------------------
  -- Input / Output
  -----------------------------------------------------------------------------
  io_access_en_o<= inst_input or inst_output;
  io_read_en_o  <= inst_input  and cycle_1;
  io_write_en_o <= inst_output and cycle_1;
 
  -----------------------------------------------------------------------------
  -- RAM
  -----------------------------------------------------------------------------
  ram_read_en_o  <= inst_fetch;
  ram_write_en_o <= inst_store and cycle_1;
 
  -----------------------------------------------------------------------------
  -- Flags
  -----------------------------------------------------------------------------
  flag_write         <= (    inst_add
                           or inst_addcy
                           or inst_and
                           or inst_compare
                           or inst_or
                        -- or inst_returni
                           or inst_rotate_shift
                           or inst_sub          
                           or inst_subcy
                           or inst_test
                           or inst_xor
                          
                         );
  
  flag_write_c_o      <= flag_write and cycle_1;
  flag_write_z_o      <= flag_write and cycle_1;

  flag_save_o         <= it_en_i;
  flag_restore_o      <= inst_returni;

  -----------------------------------------------------------------------------
  -- Interrupt
  -----------------------------------------------------------------------------
  -- To Interrupt
  interrupt_enable_o  <= (inst_interrupt or inst_returni) and     decode_opcode2_i(1);
  interrupt_disable_o <= ((inst_interrupt or inst_returni) and not decode_opcode2_i(1)) or it_en_i;
  
end rtl;
