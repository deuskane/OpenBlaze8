-------------------------------------------------------------------------------
-- Title      : tb_clock_divider
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_clock_divider.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-04-27
-- Last update: 2017-04-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-04-27  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity tb_clock_divider is
  
end entity tb_clock_divider;

architecture tb of tb_clock_divider is

  constant ALGO : natural := 0;
  signal clk_i             : std_logic := '0';
  signal cke_i             : std_logic;
  signal arstn_i           : std_logic;
  signal clk_div1_o        : std_logic;
  signal clk_div2_o        : std_logic;
  signal clk_div3_o        : std_logic;
  signal clk_div4_o        : std_logic;
  signal clk_div5_o        : std_logic;
  signal clk_div6_o        : std_logic;
  signal clk_div7_o        : std_logic;
  signal clk_div8_o        : std_logic;
  signal clk_div25_algo0_o : std_logic;
  signal clk_div25_algo1_o : std_logic;
  signal clk_div25_algo2_o : std_logic;

procedure run
    (constant n : in positive           -- nb cycle
    ) is
    
    begin
      for i in 0 to n-1
      loop
        wait until rising_edge(clk_i);        
      end loop;  -- i
    end run;

begin  -- architecture tb

  dut_div1 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 1
    ,ALGO         => ALGO
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div1_o    
     );
    
  dut_div2 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 2
    ,ALGO         => ALGO
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div2_o    
     );
    
  dut_div3 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 3
    ,ALGO         => ALGO
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div3_o    
     );
    
  dut_div4 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 4
    ,ALGO         => ALGO
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div4_o    
     );
    
  dut_div5 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 5
    ,ALGO         => ALGO
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div5_o    
     );
    
  dut_div6 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 6
    ,ALGO         => ALGO
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div6_o    
     );
    
  dut_div7 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 7
    ,ALGO         => ALGO
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div7_o    
     );
    
  dut_div8 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 8
    ,ALGO         => ALGO
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div8_o    
     );

  dut_div25_algo0 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 25
    ,ALGO         => 0
    )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div25_algo0_o    
     );

    dut_div25_algo1 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 25
    ,ALGO         => 1
    )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div25_algo1_o    
     );

    dut_div25_algo2 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 25
    ,ALGO         => 2
    )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div25_algo2_o    
     );

  clk_i <= not clk_i after 5ns;
  
  gen_pattern: process is
  begin  -- process gen_pattern
    report "[TESTBENCH] Test Begin";


    run(1);

    -- Reset
    report "[TESTBENCH] Reset";
    arstn_i <= '0';
    cke_i   <= '1';
    run(10);
    cke_i   <= '1';
    arstn_i <= '1';
    run(1000);


    report "[TESTBENCH] Test End";
    wait;
  end process gen_pattern;
  
    
  

end architecture tb;
