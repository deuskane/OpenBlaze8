-------------------------------------------------------------------------------
-- Title      : OpenBlaze8
-- Project    : 
-------------------------------------------------------------------------------
-- File       : OpenBlaze8.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2014-03-21
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
-- 2014-03-21  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.math_pkg.all;
use work.OpenBlaze8_pkg.all;

entity OpenBlaze8 is
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
    address_o         : out std_logic_vector(ADDR_INST_WIDTH downto 1);
    instruction_i     : in  std_logic_vector(18 downto 1);
    port_id_o         : out std_logic_vector(DATA_WIDTH downto 1);
    in_port_i         : in  std_logic_vector(DATA_WIDTH downto 1);
    out_port_o        : out std_logic_vector(DATA_WIDTH downto 1);
    read_strobe_o     : out std_logic;
    write_strobe_o    : out std_logic;
    interrupt_i       : in  std_logic;
    interrupt_ack_o   : out std_logic;
    debug_o           : out OpenBlaze8_debug_t
    );
end OpenBlaze8;

architecture rtl of OpenBlaze8 is
  -- =====[ Types ]===============================

  -- =====[ Registers ]===========================

  -- =====[ Signals ]=============================
  signal clock_internal            : std_logic;
  signal reset_internal            : std_logic;
  signal cycle_phase               : std_logic;

  signal pc_write_en               : std_logic;
  signal pc_next_mux               : std_logic_vector( 3 downto 1);
                                   
  signal decode_opcode1            : std_logic_vector( 5 downto 1);
  signal decode_opcode2            : std_logic_vector( 4 downto 1);
  signal decode_operand_mux        : std_logic                    ;
  signal decode_branch_cond        : std_logic_vector( 3 downto 1);
  signal decode_imm10              : std_logic_vector(10 downto 1);
  signal decode_inhib              : std_logic;
  alias  decode_address            : std_logic_vector(ADDR_INST_WIDTH downto 1) is decode_imm10(ADDR_INST_WIDTH downto 1);
  alias  decode_imm                : std_logic_vector(DATA_WIDTH downto 1) is decode_imm10(DATA_WIDTH downto 1);
                                   
  signal stack_push_val            : std_logic;
  signal stack_push_data           : std_logic_vector(ADDR_INST_WIDTH downto 1);
  signal stack_pop_ack             : std_logic;
  signal stack_pop_data            : std_logic_vector(ADDR_INST_WIDTH downto 1);
                                   
  signal reg1_read_en              : std_logic;
  signal reg1_write_en             : std_logic;
  signal reg1_addr                 : std_logic_vector(log2(REGFILE_DEPTH) downto 1);
  signal reg1_read_data            : std_logic_vector(DATA_WIDTH downto 1);
  signal reg1_write_data           : std_logic_vector(DATA_WIDTH downto 1);
  signal reg2_read_en              : std_logic;
  signal reg2_addr                 : std_logic_vector(log2(REGFILE_DEPTH) downto 1);
  signal reg2_read_data            : std_logic_vector(DATA_WIDTH downto 1);

  signal alu_op_arith_cy           : std_logic;
  signal alu_op_arith              : std_logic;
  signal alu_op_logic              : std_logic_vector( 2 downto 1);
  signal alu_op_rotate_shift_right : std_logic;
  signal alu_op_rotate_shift       : std_logic_vector( 2 downto 1);
  signal alu_op_rotate_shift_cst   : std_logic;
  signal alu_op_type               : std_logic_vector( 2 downto 1);
--signal alu_op_flag_z             : std_logic;
  signal alu_op_flag_c             : std_logic_vector( 2 downto 1);
  signal alu_op1                   : std_logic_vector(DATA_WIDTH downto 1);
  signal alu_op2                   : std_logic_vector(DATA_WIDTH downto 1);
  signal alu_res                   : std_logic_vector(DATA_WIDTH downto 1);

  signal flag_c                    : std_logic;
  signal flag_z                    : std_logic;
  signal flag_c_next               : std_logic;
  signal flag_z_next               : std_logic;

  signal flag_write_c              : std_logic;
  signal flag_write_z              : std_logic;
  signal flag_save                 : std_logic;
  signal flag_restore              : std_logic;

  signal ram_read_en               : std_logic;
  signal ram_write_en              : std_logic;
  alias  ram_addr                  : std_logic_vector(log2(RAM_DEPTH) downto 1) is alu_op2(log2(RAM_DEPTH) downto 1);
  signal ram_read_data             : std_logic_vector(DATA_WIDTH downto 1);
  alias  ram_write_data            : std_logic_vector(DATA_WIDTH downto 1) is alu_op1;

  signal io_access_en              : std_logic;
  signal io_read_en                : std_logic;
  signal io_write_en               : std_logic;
  alias  io_addr                   : std_logic_vector(DATA_WIDTH downto 1) is alu_op2;
  signal io_data_read              : std_logic_vector(DATA_WIDTH downto 1);
  alias  io_data_write             : std_logic_vector(DATA_WIDTH downto 1) is alu_op1;

  signal result_mux                : std_logic_vector(2 downto 1);

  signal interrupt_enable          : std_logic;
  signal interrupt_disable         : std_logic;
  signal it_en                     : std_logic;

  begin  -- rtl

    -----------------------------------------------------------------------------
    -- Instance
    -----------------------------------------------------------------------------
    ins_OpenBlaze8_Clock : entity work.OpenBlaze8_Clock(rtl)
    generic map (
      multi_cycle                 => MULTI_CYCLE
      )
    port map (
      clock_i                     => clock_i
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_i       
     ,clock_o                     => clock_internal
     ,reset_o                     => reset_internal       
     ,cycle_phase_o               => cycle_phase
    );

    ins_OpenBlaze8_Program_Counter : entity work.OpenBlaze8_Program_Counter(rtl)
    generic map(
      size_addr_inst              => ADDR_INST_WIDTH
      )
    port map(
      clock_i                     => clock_internal
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,pc_write_en_i               => pc_write_en
     ,pc_next_mux_i               => pc_next_mux
     ,decode_address_i            => decode_address
     ,stack_push_data_o           => stack_push_data
     ,stack_pop_data_i            => stack_pop_data
     ,inst_address_o              => address_o
    );

    ins_OpenBlaze8_Stack : entity work.OpenBlaze8_Stack(rtl)
    generic map(
      size_stack                  => STACK_DEPTH    
     ,size_addr_inst              => ADDR_INST_WIDTH
      )
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,stack_push_val_i            => stack_push_val
     ,stack_push_data_i           => stack_push_data
     ,stack_pop_ack_i             => stack_pop_ack
     ,stack_pop_data_o            => stack_pop_data
    );

    ins_OpenBlaze8_Decode : entity work.OpenBlaze8_Decode(rtl)
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,instruction_i               => instruction_i
     ,decode_opcode1_o            => decode_opcode1
     ,decode_opcode2_o            => decode_opcode2
     ,decode_operand_mux_o        => decode_operand_mux
     ,decode_branch_cond_o        => decode_branch_cond
     ,decode_num_regx_o           => reg1_addr
     ,decode_num_regy_o           => reg2_addr
     ,decode_imm_o                => decode_imm10
     ,decode_inhib_i              => decode_inhib
      );

    ins_OpenBlaze8_Operand : entity work.OpenBlaze8_Operand(rtl)
    generic map (
      size_data                   => DATA_WIDTH
     ) 
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,decode_operand_mux_i        => decode_operand_mux
     ,decode_imm_i                => decode_imm
     ,reg_op1_i                   => reg1_read_data
     ,reg_op2_i                   => reg2_read_data
     ,operand_op1_o               => alu_op1
     ,operand_op2_o               => alu_op2
      );

   ins_OpenBlaze8_RegFile : entity work.OpenBlaze8_RegFile(rtl)
    generic map (
      size_data                   => DATA_WIDTH
     ,nb_reg                      => REGFILE_DEPTH
     )
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,regx_read_en_i              => reg1_read_en
     ,regx_write_en_i             => reg1_write_en
     ,regx_addr_i                 => reg1_addr
     ,regx_data_i                 => reg1_write_data
     ,regx_data_o                 => reg1_read_data
     ,regy_read_en_i              => reg2_read_en
     ,regy_addr_i                 => reg2_addr
     ,regy_data_o                 => reg2_read_data
      );
    
    ins_OpenBlaze8_ALU : entity work.OpenBlaze8_ALU(rtl)
    generic map (
      size_data                   => DATA_WIDTH
     )
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,alu_op_arith_cy_i           => alu_op_arith_cy          
     ,alu_op_arith_i              => alu_op_arith             
     ,alu_op_logic_i              => alu_op_logic             
     ,alu_op_rotate_shift_right_i => alu_op_rotate_shift_right
     ,alu_op_rotate_shift_i       => alu_op_rotate_shift      
     ,alu_op_rotate_shift_cst_i   => alu_op_rotate_shift_cst  
     ,alu_op_type_i               => alu_op_type              
--   ,alu_op_flag_z_i             => alu_op_flag_z            
     ,alu_op_flag_c_i             => alu_op_flag_c            
     ,alu_op1_i                   => alu_op1
     ,alu_op2_i                   => alu_op2
     ,alu_res_o                   => alu_res
     ,flag_c_i                    => flag_c     
     ,flag_z_i                    => flag_z     
     ,flag_c_o                    => flag_c_next
     ,flag_z_o                    => flag_z_next
    );

    ins_OpenBlaze8_RAM : entity work.OpenBlaze8_RAM(rtl)
    generic map(
      size_data                   => DATA_WIDTH
     ,size_ram                    => RAM_DEPTH 
     )
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,ram_read_en_i               => ram_read_en
     ,ram_write_en_i              => ram_write_en
     ,ram_addr_i                  => ram_addr
     ,ram_read_data_o             => ram_read_data
     ,ram_write_data_i            => ram_write_data
      );

    ins_OpenBlaze8_LoadStore : entity work.OpenBlaze8_LoadStore(rtl)
    generic map(
      size_data                   => DATA_WIDTH
     )
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,io_access_en_i              => io_access_en
     ,io_read_en_i                => io_read_en 
     ,io_write_en_i               => io_write_en
     ,io_addr_i                   => io_addr
     ,io_data_read_o              => io_data_read
     ,io_data_write_i             => io_data_write
     ,port_id_o                   => port_id_o
     ,in_port_i                   => in_port_i
     ,out_port_o                  => out_port_o
     ,read_strobe_o               => read_strobe_o
     ,write_strobe_o              => write_strobe_o
     );

    ins_OpenBlaze8_Result : entity work.OpenBlaze8_Result(rtl)
    generic map (
      size_data                   => DATA_WIDTH
     )
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,result_mux_i                => result_mux
     ,alu_res_i                   => alu_res
     ,ram_fetch_data_i            => ram_read_data
     ,io_input_data_i             => io_data_read
     ,res_o                       => reg1_write_data
    );

    ins_OpenBlaze8_Flags : entity work.OpenBlaze8_Flags(rtl)
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,flag_c_o                    => flag_c     
     ,flag_z_o                    => flag_z     
     ,flag_c_i                    => flag_c_next
     ,flag_z_i                    => flag_z_next
     ,flag_write_c_i              => flag_write_c
     ,flag_write_z_i              => flag_write_z
     ,flag_save_i                 => flag_save   
     ,flag_restore_i              => flag_restore
     );

    ins_OpenBlaze8_Interrupt : entity work.OpenBlaze8_Interrupt(rtl)
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,interrupt_enable_i          => interrupt_enable 
     ,interrupt_disable_i         => interrupt_disable
     ,it_en_o                     => it_en            
     ,interrupt_i                 => interrupt_i
     ,interrupt_ack_o             => interrupt_ack_o
    );

    ins_OpenBlaze8_Control : entity work.OpenBlaze8_Control(rtl)
    port map(
      clock_i                     => clock_internal       
     ,clock_enable_i              => clock_enable_i
     ,reset_i                     => reset_internal       
     ,cycle_phase_i               => cycle_phase
     ,decode_opcode1_i            => decode_opcode1
     ,decode_opcode2_i            => decode_opcode2
     ,decode_operand_mux_i        => decode_operand_mux
     ,decode_branch_cond_i        => decode_branch_cond
     ,decode_inhib_o              => decode_inhib
     ,pc_write_en_o               => pc_write_en
     ,pc_next_mux_o               => pc_next_mux
     ,stack_push_val_o            => stack_push_val
     ,stack_pop_ack_o             => stack_pop_ack
     ,regx_read_en_o              => reg1_read_en
     ,regx_write_en_o             => reg1_write_en
     ,regy_read_en_o              => reg2_read_en
     ,alu_op_arith_cy_o           => alu_op_arith_cy          
     ,alu_op_arith_o              => alu_op_arith             
     ,alu_op_logic_o              => alu_op_logic             
     ,alu_op_rotate_shift_right_o => alu_op_rotate_shift_right
     ,alu_op_rotate_shift_o       => alu_op_rotate_shift      
     ,alu_op_rotate_shift_cst_o   => alu_op_rotate_shift_cst  
     ,alu_op_type_o               => alu_op_type              
--   ,alu_op_flag_z_o             => alu_op_flag_z            
     ,alu_op_flag_c_o             => alu_op_flag_c            
     ,result_mux_o                => result_mux
     ,io_access_en_o              => io_access_en
     ,io_read_en_o                => io_read_en
     ,io_write_en_o               => io_write_en
     ,ram_read_en_o               => ram_read_en 
     ,ram_write_en_o              => ram_write_en
     ,flag_c_i                    => flag_c
     ,flag_z_i                    => flag_z
     ,flag_write_c_o              => flag_write_c
     ,flag_write_z_o              => flag_write_z
     ,flag_save_o                 => flag_save   
     ,flag_restore_o              => flag_restore
     ,interrupt_enable_o          => interrupt_enable 
     ,interrupt_disable_o         => interrupt_disable
     ,it_en_i                     => it_en            
    );

    -----------------------------------------------------------------------------
    -- Debug
    -----------------------------------------------------------------------------
    debug_o.dummy <= '1';
end rtl;
