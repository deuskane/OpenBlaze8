-------------------------------------------------------------------------------
-- Title      : pbi_PicoBlaze
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pbi_PicoBlaze.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-03-30
-- Last update: 2017-05-01
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-30  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.OpenBlaze8_pkg.all;
use work.pbi_pkg.all;

entity pbi_PicoBlaze is
  generic (
     USE_KCPSM       : boolean := false
     );
  port   (
    clk_i            : in    std_logic;
    cke_i            : in    std_logic;
    arstn_i          : in    std_logic; -- asynchronous reset

    -- Instructions
    iaddr_o          : out std_logic_vector(10-1 downto 0);
    idata_i          : in  std_logic_vector(17 downto 0);
    
    -- Bus
    pbi_ini_o        : out   pbi_ini_t;
    pbi_tgt_i        : in    pbi_tgt_t;

    -- To/From IT Ctrl
    interrupt_i      : in    std_logic;
    interrupt_ack_o  : out   std_logic
    );
  
end entity pbi_PicoBlaze;

architecture rtl of pbi_PicoBlaze is
  signal clk  : std_logic;
  signal cke  : std_logic;
  signal arst : std_logic;
begin  -- architecture rtl

  arst <= not arstn_i;
  cke  <= cke_i or not pbi_tgt_i.busy;

  gen_kcpsm: if USE_KCPSM
  generate
    ins_gated_clock : entity work.gated_clock(rtl)
      port map
      (clk_i       => clk_i
      ,cmd_i       => cke
      ,clk_gated_o => clk
       );

    kcpsm3 : entity work.kcpsm3(low_level_definition)
      port map
      (clk           => clk          
      ,reset         => arst           
      ,address       => iaddr_o        
      ,instruction   => idata_i        
      ,port_id       => pbi_ini_o.addr   
      ,in_port       => pbi_tgt_i.rdata  
      ,out_port      => pbi_ini_o.wdata  
      ,read_strobe   => pbi_ini_o.re     
      ,write_strobe  => pbi_ini_o.we     
      ,interrupt     => interrupt_i      
      ,interrupt_ack => interrupt_ack_o
        );
    
  end generate gen_kcpsm;

  gen_openblaze8: if not USE_KCPSM
  generate
    OpenBlaze8 : entity work.OpenBlaze8(rtl)
      generic map
      (STACK_DEPTH     => 32
      ,RAM_DEPTH       => 64
      ,DATA_WIDTH      => 8 
      ,ADDR_INST_WIDTH => 10
      ,REGFILE_DEPTH   => 16
      ,MULTI_CYCLE     => 1 
        )
      port map
      (clock_i           => clk_i          
      ,clock_enable_i    => cke            
      ,reset_i           => arst           
      ,address_o         => iaddr_o        
      ,instruction_i     => idata_i        
      ,port_id_o         => pbi_ini_o.addr   
      ,in_port_i         => pbi_tgt_i.rdata  
      ,out_port_o        => pbi_ini_o.wdata  
      ,read_strobe_o     => pbi_ini_o.re     
      ,write_strobe_o    => pbi_ini_o.we     
      ,interrupt_i       => interrupt_i    
      ,interrupt_ack_o   => interrupt_ack_o
      ,debug_o           => open
        );
  end generate gen_openblaze8;

end architecture rtl;
