-------------------------------------------------------------------------------
-- Title      : timer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : timer.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-04-12
-- Last update: 2018-06-01
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-- Register Map :
-- [0] R     : Status
--             b0 Timer Event  (reset on reset)
-- [1] R/W   : Control
--             b0 Timer Enable (start/stop)
--             b1 Autostart after Event
--             b2 Event managed by interruption
--             b3 Tick count (else clock count)
-- [2]       : Reserved
-- [3]       : Reserved
-- [4] R/W   : Counter (byte 0)
-- [5] R/W   : Counter (byte 1)
-- [6] R/W   : Counter (byte 2)
-- [7] R/W   : Counter (byte 3)
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date       Version Author   Description
-- 2018-06-01 1.1     mrosiere Move Event in dedicated register	
-- 2017-04-12 1.0     mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity timer is
  generic(
--  FSYS             : positive := 50_000_000;
--  TICK_PERIOD      : real     := 0.001; -- 1ms
    TICK             : positive := 1000;
    SIZE_ADDR        : natural  := 3;     -- Bus Address Width
    SIZE_DATA        : natural  := 8;     -- Bus Data    Width
    IT_ENABLE        : boolean  := false  -- Timer can generate interruption
    );

  port (
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
    
    -- To/From IT Ctrl
    interrupt_o      : out   std_logic;
    interrupt_ack_i  : in    std_logic
    );

end entity timer;

architecture rtl of timer is
  constant CST0 : std_logic_vector(1024-1 downto 0) := (others => '0');
--constant TICK : positive := positive(real(FSYS)*TICK_PERIOD);
  
  -----------------------------------------------------------------------------
  -- Address
  -----------------------------------------------------------------------------
  constant raddr_status     : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(0, SIZE_ADDR));
  constant raddr_control    : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(1, SIZE_ADDR));
  constant raddr_data       : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(4, SIZE_ADDR));
  constant raddr_data_byte0 : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(4, SIZE_ADDR));
  constant raddr_data_byte1 : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(5, SIZE_ADDR));
  constant raddr_data_byte2 : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(6, SIZE_ADDR));
  constant raddr_data_byte3 : std_logic_vector(SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(7, SIZE_ADDR));

  constant waddr_control    : std_logic_vector(SIZE_ADDR-1 downto 0) := raddr_control;
  constant waddr_data       : std_logic_vector(SIZE_ADDR-1 downto 0) := raddr_data   ;
  constant waddr_data_byte0 : std_logic_vector(SIZE_ADDR-1 downto 0) := raddr_data_byte0;
  constant waddr_data_byte1 : std_logic_vector(SIZE_ADDR-1 downto 0) := raddr_data_byte1;
  constant waddr_data_byte2 : std_logic_vector(SIZE_ADDR-1 downto 0) := raddr_data_byte2;
  constant waddr_data_byte3 : std_logic_vector(SIZE_ADDR-1 downto 0) := raddr_data_byte3;

  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  signal timer_enable_r    : std_logic;    -- Timer is enable (1 : start, 0 : stop)
  signal timer_enable_r2   : std_logic;    -- Timer is enable (registered)
  signal timer_event_r     : std_logic;    -- Timer have generated an event
  signal timer_autostart_r : std_logic;    -- Timer relunch after event
  signal timer_it_enable_r : std_logic;    -- Timer generate an interruption on event
  signal timer_use_tick_r  : std_logic;    -- Timer source (0 : clock, 1 : tick)

  signal status_r          : std_logic_vector(1 -1 downto 0);
  signal control_r         : std_logic_vector(4 -1 downto 0);

  signal counter_r         : std_logic_vector(32-1 downto 0);  -- Counter value
  signal counter_cur_r     : std_logic_vector(32-1 downto 0);  -- Counter value

  signal tick_counter_r    : natural range 0 to TICK-1;
  
  -----------------------------------------------------------------------------
  -- Signal
  -----------------------------------------------------------------------------
  signal timer_begin       : std_logic;    -- First cycle where timer is enable
  signal timer_end         : std_logic;    -- Threshold is reach
  signal timer_count       : std_logic;    -- timer counting

  signal tick_rst          : std_logic;    -- tick timer reset
  signal tick_cke          : std_logic;    -- tick timer clock enable
  signal tick_event        : std_logic;    -- tick timer event
  
  signal counter_r_we      : std_logic_vector(4 -1 downto 0);  -- Counter write enable
  signal counter_r_next    : std_logic_vector(32-1 downto 0);  -- Counter value (next)

  signal counter_cur       : std_logic_vector(32-1 downto 0);
  signal counter_test      : std_logic_vector(32-1 downto 0);
  signal counter_cur_r_rst : std_logic;
  signal counter_cur_r_next: std_logic_vector(32-1 downto 0);
  signal counter_cur_null  : std_logic;    -- counter_r equal 0
  
  signal counter_rdata     : std_logic_vector(SIZE_DATA-1 downto 0);
begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- IP Output
  -----------------------------------------------------------------------------
  busy_o   <= '0'; -- never busy

  gen_counter_read_8b: if SIZE_DATA = 8
  generate
    counter_rdata <= counter_cur_r( 8-1 downto  0) when (addr_i = raddr_data_byte0) else
                     counter_cur_r(16-1 downto  8) when (addr_i = raddr_data_byte1) else
                     counter_cur_r(24-1 downto 16) when (addr_i = raddr_data_byte2) else
                     counter_cur_r(32-1 downto 24);
  end generate gen_counter_read_8b;

  gen_counter_read_16b: if SIZE_DATA = 16
  generate
    counter_rdata <= counter_cur_r(16-1 downto  0) when (addr_i = raddr_data_byte0) else
                     counter_cur_r(32-1 downto 16);
  end generate gen_counter_read_16b;

  gen_counter_read_32b: if SIZE_DATA >= 32
  generate
    counter_rdata <= std_logic_vector(resize(unsigned(counter_cur_r), counter_rdata'length));
  end generate gen_counter_read_32b;

  -- Control register
  status_r(0) <= timer_event_r;

  -- Control register
  control_r <= (timer_use_tick_r  &
                timer_it_enable_r &
                timer_autostart_r &
                timer_enable_r);

  -- Read data multiplexor
  rdata_o   <= std_logic_vector(resize(unsigned(status_r ), rdata_o'length)) when (addr_i = raddr_status ) else
               std_logic_vector(resize(unsigned(control_r), rdata_o'length)) when (addr_i = raddr_control) else
               counter_rdata;

  -----------------------------------------------------------------------------
  -- IP Write Counter
  -----------------------------------------------------------------------------
  gen_counter_write_8b: if SIZE_DATA = 8
  generate
    counter_r_we   <= "0001" when (addr_i = waddr_data_byte0) else
                      "0010" when (addr_i = waddr_data_byte1) else
                      "0100" when (addr_i = waddr_data_byte2) else
                      "1000" when (addr_i = waddr_data_byte3) else
                      "0000";
    
    counter_r_next <= (wdata_i( 8-1 downto 0) &
                       wdata_i( 8-1 downto 0) &
                       wdata_i( 8-1 downto 0) &
                       wdata_i( 8-1 downto 0));
  end generate gen_counter_write_8b;

  gen_counter_write_16b: if SIZE_DATA = 16
  generate
    counter_r_we   <= "0011" when (addr_i = raddr_data_byte0) else
                      "1100" when (addr_i = raddr_data_byte2) else
                      "0000";
    
    counter_r_next <= (wdata_i(16-1 downto 0) &
                       wdata_i(16-1 downto 0));
  end generate gen_counter_write_16b;

  gen_counter_write_32b: if SIZE_DATA >= 32
  generate
    counter_r_we   <= "1111";
    counter_r_next <= wdata_i(32-1 downto 0);
  end generate gen_counter_write_32b;

  -----------------------------------------------------------------------------
  -- Counter next value
  -----------------------------------------------------------------------------
  counter_cur_r_next <= std_logic_vector(unsigned(counter_cur) - 1);

  -- Event after (counter_r + 2) ticks + 1 cycle
  counter_cur_r_rst  <= timer_begin;
  
  counter_cur        <= counter_cur_r;

  counter_test       <= counter_cur_r;
  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  gen_reg: process (clk_i, arstn_i) is
  begin  -- process gen_reg
    if arstn_i = '0'
    then -- asynchronous reset (active low)
      timer_enable_r    <= '0';
      timer_enable_r2   <= '0';
      timer_event_r     <= '0';
      timer_autostart_r <= '0';
      timer_it_enable_r <= '0';
      timer_use_tick_r  <= '0';
      
      counter_cur_r     <= (others => '0');
      counter_r         <= (others => '0');
    elsif clk_i'event and clk_i = '1'
    then  -- rising clock edge
      if cke_i = '1'
      then
        -- Save Timer enable for begin condition
        timer_enable_r2 <= timer_enable_r;

        -- Decrease counter
        if (timer_count = '1')
        then
          counter_cur_r <= counter_cur_r_next;
        end if;

        -- Init counter
        if (counter_cur_r_rst = '1')
        then
          counter_cur_r <= counter_r;
        end if;

        -- Disable timer if end is reach
        if (timer_end = '1' and timer_autostart_r = '0')
        then
          timer_enable_r <= '0';
        end if;

        -- User Read
        if (cs_i = '1' and we_i = '0')
        then
          if (addr_i = raddr_status)
          then
            -- Reset on read
            timer_event_r     <= '0';
          end if;
        end if;
          
        -- User Write
        if (cs_i = '1' and we_i = '1')
        then
          if (addr_i = waddr_control)
          then
            timer_enable_r    <= wdata_i(0);
            timer_autostart_r <= wdata_i(1);
            timer_it_enable_r <= wdata_i(2);
            timer_use_tick_r  <= wdata_i(3);
          end if;
          
          for i in 3 downto 0
          loop
            if counter_r_we(i) = '1'
            then
              counter_r((i+1)*8-1 downto i*8) <= counter_r_next((i+1)*8-1 downto i*8);
            end if;
          end loop;
        end if;

        -- Timer is finished : have an event
        -- After user write, because new event is more prior than user event
        if (timer_end = '1')
        then
          timer_event_r <= '1';
        end if;
      end if;
    end if;
  end process gen_reg;

  -----------------------------------------------------------------------------
  -- Tick control
  -----------------------------------------------------------------------------
  tick_cke   <= cke_i and timer_enable_r and timer_use_tick_r;
  tick_rst   <= tick_event or timer_begin;
  tick_event <= '1' when tick_counter_r = 0 else
                '0';
  
  process(clk_i)
  begin 
    if rising_edge(clk_i)
    then
      if (tick_cke = '1')
      then
        if (tick_rst='1')
        then
          tick_counter_r <= TICK-1;
        else
          tick_counter_r <= tick_counter_r-1;
        end if;
      end if;
    end if;
  end process;
  -----------------------------------------------------------------------------
  -- Timer control
  -----------------------------------------------------------------------------
  counter_cur_null   <= '1' when counter_test = CST0(counter_r'range) else
                        '0';
  
  -- First cycle
  -- or last cycle and autostart
  timer_begin        <= (timer_enable_r and not timer_enable_r2) or (timer_end and timer_autostart_r);
  timer_end          <= timer_enable_r2 and counter_cur_null;
  timer_count        <= timer_enable_r when timer_use_tick_r = '0' else
                        tick_event; -- count each cycle

  -----------------------------------------------------------------------------
  -- Interruption
  -----------------------------------------------------------------------------
  interrupt_o        <= '0'; -- TODO
end architecture rtl;
