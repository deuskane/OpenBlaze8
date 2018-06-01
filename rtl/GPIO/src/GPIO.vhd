-------------------------------------------------------------------------------
-- Title      : GPIO
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : GPIO.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2018-06-01
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-- It's a GPIO component
-- Register Map :
-- [0] Read/Write : data    (with data_oe mask apply)
-- [1] Write      : data oe (if data_oe_force = 0)
-- [2] Read       : data_in
-- [3] Read/Write : data_out

-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-06-01  0.4      rosiere Add to address for a direct access at data_in_r
--                              and data_out_r
-- 2014-06-05  0.3      rosiere Extract bus in another IP
-- 2014-02-07  0.2      rosiere bus_read_data : protection during a reset
-- 2013-12-26  0.1      rosiere	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity GPIO is
  generic(
    SIZE_ADDR        : natural:=2;     -- Bus Address Width
    SIZE_DATA        : natural:=8;     -- Bus Data    Width
    NB_IO            : natural:=8;     -- Number of IO. Must be <= SIZE_DATA
    DATA_OE_INIT     : boolean:=false; -- Direction of the IO after a reset
    DATA_OE_FORCE    : boolean:=false; -- Can change the direction of the IO
    IT_ENABLE        : boolean:=false  -- GPIO can generate interruption
    );
  port   (
    clk_i            : in    std_logic;
    cke_i            : in    std_logic;
    arstn_i          : in    std_logic; -- asynchronous reset

    -- To IP
    cs_i             : in    std_logic;
    re_i             : in    std_logic;
    we_i             : in    std_logic;
    addr_i           : in    std_logic_vector (SIZE_ADDR-1 downto 0);
    wdata_i          : in    std_logic_vector (SIZE_DATA-1 downto 0);
    rdata_o          : out   std_logic_vector (SIZE_DATA-1 downto 0);
    busy_o           : out   std_logic;

    -- To/From IO
    data_i           : in    std_logic_vector (NB_IO-1     downto 0);
    data_o           : out   std_logic_vector (NB_IO-1     downto 0);
    data_oe_o        : out   std_logic_vector (NB_IO-1     downto 0);
    
    -- To/From IT Ctrl
    interrupt_o      : out   std_logic;
    interrupt_ack_i  : in    std_logic
    );
end GPIO;

architecture rtl of GPIO is
  function to_stdulogic( V: Boolean ) return std_ulogic is 
  begin 
    if V
    then 
      return '1'; 
    else 
      return '0';
    end if;     
  end to_stdulogic;

  -----------------------------------------------------------------------------
  -- Local parameters
  -----------------------------------------------------------------------------
  constant IO_OUT_ONLY         : boolean := DATA_OE_FORCE and     DATA_OE_INIT;
  constant IO_IN_ONLY          : boolean := DATA_OE_FORCE and not DATA_OE_INIT;
  constant IO_OUT              : boolean := not DATA_OE_FORCE or IO_OUT_ONLY;
  constant IO_IN               : boolean := not DATA_OE_FORCE or IO_IN_ONLY;
  
  -----------------------------------------------------------------------------
  -- Address
  -----------------------------------------------------------------------------
  constant raddr_data       : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(0, SIZE_ADDR));
  constant raddr_data_in    : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(2, SIZE_ADDR));
  constant raddr_data_out   : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(3, SIZE_ADDR));
  constant waddr_data       : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(0, SIZE_ADDR));
  constant waddr_data_oe    : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(1, SIZE_ADDR));
  constant waddr_data_out   : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(3, SIZE_ADDR));

  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  constant data_oe_r_init   : std_logic_vector(NB_IO-1 downto 0) := (others => to_stdulogic(DATA_OE_INIT));
  signal   data_out_r       : std_logic_vector(NB_IO-1 downto 0);
  signal   data_in_r        : std_logic_vector(NB_IO-1 downto 0);
  signal   data_oe_r        : std_logic_vector(NB_IO-1 downto 0);

  -----------------------------------------------------------------------------
  -- Signal
  -----------------------------------------------------------------------------
  signal   data_oe          : std_logic_vector(NB_IO-1 downto 0);
  signal   rdata            : std_logic_vector(NB_IO-1 downto 0);

begin
  -----------------------------------------------------------------------------
  -- Data I/O
  -----------------------------------------------------------------------------
  data_o     <= data_out_r;
  data_oe_o  <= data_oe;
  
  -----------------------------------------------------------------------------
  -- IP Output
  -----------------------------------------------------------------------------
  busy_o   <= '0'; -- never busy

  rdata_o  <= std_logic_vector(resize(unsigned(rdata), rdata_o'length));
  
  gen_rdata_io_out_only: if IO_OUT_ONLY generate
    rdata <= data_out_r;
  end generate;

  gen_rdata_io_in_only: if IO_IN_ONLY generate
    rdata <= data_in_r;
  end generate;

  gen_rdata_force_off: if not DATA_OE_FORCE generate
    rdata <= data_in_r  when (addr_i = raddr_data_in ) else
             data_out_r when (addr_i = raddr_data_out) else
             ((data_out_r and     data_oe_r) or
              (data_in_r  and not data_oe_r));
  end generate;
    
  -----------------------------------------------------------------------------
  -- IO Direction
  -----------------------------------------------------------------------------
  gen_data_oe_force_on : if     DATA_OE_FORCE generate
    data_oe <= data_oe_r_init;
  end generate;

  gen_data_oe_force_off: if not DATA_OE_FORCE generate
    data_oe <= data_oe_r;

    process(clk_i,arstn_i )
    begin 
      if (arstn_i='0') -- arstn_i actif bas
      then
        data_oe_r <= data_oe_r_init;
      elsif rising_edge(clk_i)
      then  -- rising clock edge
        if cke_i = '1'
        then
          if (cs_i = '1' and we_i = '1')
          then
            if (addr_i = waddr_data_oe)
            then
              data_oe_r <= wdata_i(NB_IO-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;

  end generate;
  
  -----------------------------------------------------------------------------
  -- IO Data output
  -----------------------------------------------------------------------------
  gen_data_out_r_off: if not IO_OUT generate
    data_out_r <= (others => '0');
  end generate;

  gen_data_out_r_on : if     IO_OUT     generate
    process(clk_i,arstn_i )
    begin 
      if (arstn_i='0') -- arstn_i actif bas
      then
        data_out_r <= (others => '0');
      elsif rising_edge(clk_i)
      then  -- rising clock edge
        if cke_i = '1'
        then
          if (cs_i = '1' and we_i = '1')
          then
            if ((addr_i = waddr_data) or
                (addr_i = waddr_data_out))
            then
              data_out_r <= wdata_i(NB_IO-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;
  end generate;

  -----------------------------------------------------------------------------
  -- IO Data input
  -- Sampling input data
  -- Don't care metastability
  -----------------------------------------------------------------------------
  gen_data_in_r_on : if IO_IN generate
    process(clk_i)
    begin 
      if rising_edge(clk_i)
      then  -- rising clock edge
        data_in_r <= data_i;
      end if;
    end process;
  end generate;

  -----------------------------------------------------------------------------
  -- Interrupt
  -----------------------------------------------------------------------------
  interrupt_o <= '0';
end rtl;
