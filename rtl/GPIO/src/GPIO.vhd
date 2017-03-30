-------------------------------------------------------------------------------
-- Title      : GPIO
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : GPIO.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2017-03-30
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-- It's a GPIO component
-- Register Map :
-- [0] Read  : data
-- [0] Write : data
-- [1] Write : data oe (if data_oe_force = 0)
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
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
    data_io          : inout std_logic_vector (NB_IO-1     downto 0);

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
  -----------------------------------------------------------------------------
  -- Address
  -----------------------------------------------------------------------------
  constant addr_read_data   : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(0, SIZE_ADDR));
  constant addr_write_data  : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(0, SIZE_ADDR));
  constant addr_write_cfg   : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(1, SIZE_ADDR));

  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  constant data_oe_r_init   : std_logic_vector(NB_IO-1 downto 0) := (others => to_stdulogic(DATA_OE_INIT));
  signal   data_out_r       : std_logic_vector(NB_IO-1 downto 0);
  signal   data_in_r        : std_logic_vector(NB_IO-1 downto 0);
  signal   data_oe_r        : std_logic_vector(NB_IO-1 downto 0);
  signal   data_oe          : std_logic_vector(NB_IO-1 downto 0);
begin
  -----------------------------------------------------------------------------
  -- Data I/O
  -----------------------------------------------------------------------------
  gen_data_io_force_out_on: if IO_OUT_ONLY generate
    data_io    <= data_out_r;
  end generate gen_data_io_force_out_on;
  
  gen_data_io_force_off: if not DATA_OE_FORCE generate
  gen_data_io: for i in NB_IO-1 downto 0 generate
    data_io(i) <= data_out_r(i) when data_oe(i) = '1' else 'Z';
  end generate gen_data_io;
  end generate gen_data_io_force_off;
  
  -----------------------------------------------------------------------------
  -- IP Output
  -----------------------------------------------------------------------------
  busy_o   <= '0'; -- never busy

  gen_rdata_force_out_on: if IO_OUT_ONLY generate
  rdata_o  <= (others => '0');
  end generate gen_rdata_force_out_on;

  gen_rdata_force_out_off: if not IO_OUT_ONLY generate
--rdata_o  <= data_in_r when (addr_i = addr_read_data) else
--                (others => '0');

  rdata_o  <= (rdata_o'range => data_in_r -- Only one read register
              ,others => '0');
  end generate gen_rdata_force_out_off;
    
  -----------------------------------------------------------------------------
  -- IO Direction
  -----------------------------------------------------------------------------
  gen_data_oe_force_on : if     DATA_OE_FORCE generate
    data_oe <= data_oe_r_init;
  end generate gen_data_oe_force_on;

  gen_data_oe_force_off: if not DATA_OE_FORCE generate
    data_oe <= data_oe_r;

    process(clk_i,arstn_i )
    begin 
      if (arstn_i='0') -- arstn_i actif haut
      then
        data_oe_r <= data_oe_r_init;
      elsif rising_edge(clk_i)
      then  -- rising clock edge
        if cke_i = '1'
        then
          if (cs_i = '1' and we_i = '1')
          then
            if (addr_i = addr_write_cfg)
            then
              data_oe_r <= wdata_i(NB_IO-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;

  end generate gen_data_oe_force_off;
  
  -----------------------------------------------------------------------------
  -- IO Data output
  -----------------------------------------------------------------------------
  process(clk_i,arstn_i )
  begin 
    if (arstn_i='0') -- arstn_i actif haut
    then
      data_out_r    <= (others => '0');
    elsif rising_edge(clk_i)
    then  -- rising clock edge
      if cke_i = '1'
      then
        if (cs_i = '1' and we_i = '1')
        then
          if (addr_i = addr_write_data)
          then
            data_out_r <= wdata_i(NB_IO-1 downto 0);
          end if;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- IO Data input
  -----------------------------------------------------------------------------
  process(clk_i)
  begin 
    if rising_edge(clk_i)
    then  -- rising clock edge
      data_in_r <= data_io;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Interrupt
  -----------------------------------------------------------------------------
  interrupt_o <= '0';
end rtl;
