-------------------------------------------------------------------------------
-- Title      : display VGA
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : display_VGA.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2017-05-13
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-- Register Map :
-- [0] R/W : config
--           [1:0] Mode
--                 00 Text mode
--                 01 Unicolor mode
-- [1] R/W : color
--           In Text mode :
--           [7]   Reserved
--           [6]   Background red
--           [5]   Background green
--           [4]   Background blue
--           [3]   Foreground light
--           [2]   Foreground red
--           [1]   Foreground green
--           [0]   Foreground blue
--           In Unicolor
--           [7:5] Red
--           [4:2] Green
--           [1:0] Blue
-- [2]   W : text buffer
--           [7:0] ASCII Code
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-05-13  0.5      rosiere add frame_buffer
-- 2017-04-28  0.4      rosiere clean up code
-- 2017-03-31  0.3      rosiere change bus interface 
-- 2014-02-07  0.2      rosiere bus_read_data : protection during a reset
-- 2013-12-26  0.1      rosiere	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

use work.math_pkg.all;

entity vga_controller is
  generic(FSYS           : positive := 50_000_000;
          NB_FRAME       : natural  := 1;     -- 0 to 16
          TEXT_MODE      : boolean  := false;
          SIZE_ADDR      : positive := 3;
          SIZE_DATA      : positive := 8
          );
    Port (clk_i          : in  STD_LOGIC;
          arstn_i        : in  STD_LOGIC;

          -- Bus
          cs_i           : in  std_logic;
          re_i           : in  std_logic;
          we_i           : in  std_logic;
          addr_i         : in  std_logic_vector (SIZE_ADDR-1 downto 0);
          wdata_i        : in  std_logic_vector (SIZE_DATA-1 downto 0);
          rdata_o        : out std_logic_vector (SIZE_DATA-1 downto 0);
          busy_o         : out std_logic;

          -- VGA
          vga_HSYNC_o    : out std_logic;
          vga_VSYNC_o    : out std_logic;
          vga_Red_o      : out std_logic_vector (2 downto 0);
          vga_Green_o    : out std_logic_vector (2 downto 0);
          vga_Blue_o     : out std_logic_vector (2 downto 1)
          );
end vga_controller;

architecture rtl of vga_controller is

  -----------------------------------------------------------------------------
  -- Address
  -----------------------------------------------------------------------------
  constant ADDR_CFG                     : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(0,SIZE_ADDR));
--constant ADDR_COLOR                   : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(1,SIZE_ADDR));
--constant ADDR_TEXT_BUFFER             : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(2,SIZE_ADDR));
  constant ADDR_FRAME_BUFFER_NUM        : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(1,SIZE_ADDR));
  constant ADDR_FRAME_BUFFER_COLOR      : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(2,SIZE_ADDR));
  constant ADDR_FRAME_BUFFER_ADDR_X_LSB : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(3,SIZE_ADDR));
  constant ADDR_FRAME_BUFFER_ADDR_X_MSB : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(4,SIZE_ADDR));
  constant ADDR_FRAME_BUFFER_ADDR_Y_LSB : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(5,SIZE_ADDR));
  constant ADDR_FRAME_BUFFER_ADDR_Y_MSB : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(6,SIZE_ADDR));
  constant ADDR_FRAME_BUFFER_DATA       : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(7,SIZE_ADDR));
  
  constant RADDR_CFG                    : std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_CFG               ;
  constant RADDR_FRAME_BUFFER_NUM       : std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_NUM  ;
  constant RADDR_FRAME_BUFFER_COLOR     : std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_COLOR;
                                        
  constant WADDR_CFG                    : std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_CFG               ;
  constant WADDR_FRAME_BUFFER_NUM       : std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_NUM  ;
  constant WADDR_FRAME_BUFFER_COLOR     : std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_COLOR;
  constant WADDR_FRAME_BUFFER_ADDR_X_LSB: std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_ADDR_X_LSB;
  constant WADDR_FRAME_BUFFER_ADDR_X_MSB: std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_ADDR_X_MSB;
  constant WADDR_FRAME_BUFFER_ADDR_Y_LSB: std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_ADDR_Y_LSB;
  constant WADDR_FRAME_BUFFER_ADDR_Y_MSB: std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_ADDR_Y_MSB;
  constant WADDR_FRAME_BUFFER_DATA      : std_logic_vector (SIZE_ADDR-1 downto 0) := ADDR_FRAME_BUFFER_DATA ;
                                   
  -----------------------------------------------------------------------------
  -- Local parameters
  -----------------------------------------------------------------------------
  -- Static configuration for 640x480 60Hz
  constant CLK_PIXEL_RATIO           : natural := FSYS/25_000_000;
  constant DISPLAY_X_LINES           : natural := 640;
  constant DISPLAY_Y_LINES           : natural := 480;

  constant ADDR_X                    : natural := 11;
  constant ADDR_Y                    : natural := 11;

  -- 640*480 -> 307_200 bits
  -- Downscale |   X |   Y | size
  --         1 | 640 | 480 | 307_200
  --        16 |  40 |  30 |   1_200
  --        20 |  32 |  24 |     768
  --        32 |  20 |  15 |     600

  constant FRAME_BUFFER_DOWNSCALE    : natural := 32;
  constant FRAME_BUFFER_X_LINES      : natural := DISPLAY_X_LINES/FRAME_BUFFER_DOWNSCALE;
  constant FRAME_BUFFER_Y_LINES      : natural := DISPLAY_Y_LINES/FRAME_BUFFER_DOWNSCALE;
  constant FRAME_BUFFER_ADDR_X       : natural := clog2(FRAME_BUFFER_X_LINES);
  constant FRAME_BUFFER_ADDR_Y       : natural := clog2(FRAME_BUFFER_Y_LINES);
  constant FRAME_BUFFER_WIDTH        : natural := 1;
  constant FRAME_BUFFER_SIZE         : natural := (FRAME_BUFFER_X_LINES*FRAME_BUFFER_Y_LINES);
  constant FRAME_BUFFER_DEPTH        : natural := FRAME_BUFFER_SIZE/FRAME_BUFFER_WIDTH;
  constant FRAME_BUFFER_ADDR         : natural := clog2(FRAME_BUFFER_SIZE);
  constant FRAME_BUFFER_ADDR_INDEX   : natural := clog2(FRAME_BUFFER_DEPTH);
  constant FRAME_BUFFER_ADDR_OFFSET  : natural :=  log2(FRAME_BUFFER_WIDTH);
  
--constant CHAR_X_MAX                : natural := 8 ;    -- 640x480 : 
--constant CHAR_Y_MAX                : natural := 16;    -- 640x480 : 
--constant TEXT_BUFFER_X_MAX         : natural := DISPLAY_X_LINES/CHAR_X_MAX;
--constant TEXT_BUFFER_Y_MAX         : natural := DISPLAY_Y_LINES/CHAR_Y_MAX;
--constant TEXT_BUFFER_DEPTH_MAX     : natural := TEXT_BUFFER_X_MAX * TEXT_BUFFER_Y_MAX;  -- 640x480 : 80x30 character
--constant TEXT_BUFFER_ADDR_SIZE_MAX : natural := 13;
--constant TEXT_BUFFER_ADDR_X_SIZE   : natural := 7;
--constant TEXT_BUFFER_ADDR_Y_SIZE   : natural := 5;
--
--constant TEXT_BUFFER_X_CUR         : natural := 8;
--constant TEXT_BUFFER_Y_CUR         : natural := 8;
--constant TEXT_BUFFER_DEPTH_CUR     : natural := 64;
--constant TEXT_BUFFER_ADDR_SIZE_CUR : natural := 6;
--
  constant MODE_TEXT                 : std_logic_vector(1 downto 0) := "11";
  constant MODE_UNICOLOR             : std_logic_vector(1 downto 0) := "01";
  constant MODE_FRAME                : std_logic_vector(1 downto 0) := "00";

  -----------------------------------------------------------------------------
  -- Function
  -----------------------------------------------------------------------------
  -- Compute (base+offset)%max
  function address
    (
    signal   base   : std_logic_vector;
    signal   offset : std_logic_vector;
    constant max    : natural)
    return std_logic_vector is

    variable addr : unsigned(base'range);
  begin
    addr := unsigned(base)+unsigned(offset);

    if addr < max
    then
      return std_logic_vector(addr);
    else
      return std_logic_vector(addr-max);
    end if;
  end function;

  -- Convert 2D to 1D address
  function conv_address
    (
    signal   x      : std_logic_vector;
    signal   y      : std_logic_vector;
    constant x_max  : natural
    )
    return std_logic_vector is

  begin
    return std_logic_vector(unsigned(y)*x_max+unsigned(x));
  end function;

  -- Convert 2D to 1D address
  function address_downscale
    (
    signal   addr   : std_logic_vector;
    constant ratio  : natural
    )
    return std_logic_vector is

  begin
    return std_logic_vector(unsigned(addr)/ratio);
  end function;

  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
--  signal   color_r                   : std_logic_vector(7 downto 0);
--  --                                   In Text mode :
--  --                                   [7]   Reserved
--  --                                   [6]   Background red
--  --                                   [5]   Background green
--  --                                   [4]   Background blue
--  --                                   [3]   Foreground light
--  --                                   [2]   Foreground red
--  --                                   [1]   Foreground green
--  --                                   [0]   Foreground blue
--  --                                   In Unicolor
--  --                                   [7:5] Red
--  --                                   [4:2] Green
--  --                                   [1:0] Blue
--  
--
--  signal   text_buffer_write_addr_x_r: std_logic_vector(TEXT_BUFFER_ADDR_X_SIZE-1 downto 0);
--  signal   text_buffer_write_addr_y_r: std_logic_vector(TEXT_BUFFER_ADDR_Y_SIZE-1 downto 0);
  -----------------------------------------------------------------------------
  -- Signal
  -----------------------------------------------------------------------------
  
  signal clk_pixel                     : std_logic;                                       -- Pixel Clock
  signal arst                          : std_logic;                                       -- Asynchronous reset (active on high level)
                                                                                          
  signal vga_HSYNC                     : std_logic;                                       -- Horizontal Synchronization
  signal vga_VSYNC                     : std_logic;                                       -- Vertical   Synchronization
  signal vga_Blank                     : std_logic;                                       -- Pixel is outside in the visible screen
  signal vga_HCOUNT                    : std_logic_vector(ADDR_X-1 downto 0);             -- Horizontal Position
  signal vga_VCOUNT                    : std_logic_vector(ADDR_Y-1 downto 0);             -- Vertical   Position

  signal frame_buffer_num_r            : std_logic_vector(max(1,clog2(NB_FRAME))-1 downto 0); -- Frame Buffer number

  signal frame_buffer_x_addr_r         : std_logic_vector(FRAME_BUFFER_ADDR_X-1 downto 0);             -- Address X position
  signal frame_buffer_y_addr_r         : std_logic_vector(FRAME_BUFFER_ADDR_Y-1 downto 0);             -- Address Y position
  
  signal frame_buffer_x_offset_r       : std_logic_vector(ADDR_X-1 downto 0);             -- Offset on X position
  signal frame_buffer_y_offset_r       : std_logic_vector(ADDR_Y-1 downto 0);             -- Offset on Y position
                                                                                   
  signal frame_buffer_x                : std_logic_vector(ADDR_X-1 downto 0);             -- X position
  signal frame_buffer_y                : std_logic_vector(ADDR_Y-1 downto 0);             -- Y position
                                       
  signal frame_buffer_x_raddr          : std_logic_vector(ADDR_X-1 downto 0);             -- X position
  signal frame_buffer_y_raddr          : std_logic_vector(ADDR_Y-1 downto 0);             -- Y position
  signal frame_buffer_x_waddr          : std_logic_vector(ADDR_X-1 downto 0);             -- X position
  signal frame_buffer_y_waddr          : std_logic_vector(ADDR_Y-1 downto 0);             -- Y position

  type frame_buffer_data_t  is array (1 to NB_FRAME) of std_logic_vector(FRAME_BUFFER_WIDTH-1 downto 0);
  type frame_buffer_color_t is array (0 to NB_FRAME) of std_logic_vector(8-1 downto 0);
  
  signal frame_buffer_read_en          : std_logic;                                       -- Frame buffer read enable
  signal frame_buffer_read_addr        : std_logic_vector(FRAME_BUFFER_ADDR -1 downto 0); -- Frame buffer read address
  signal frame_buffer_read_addr_index  : std_logic_vector(FRAME_BUFFER_ADDR_INDEX-1 downto 0) ;
  signal frame_buffer_read_addr_offset : std_logic_vector(FRAME_BUFFER_ADDR_OFFSET-1 downto 0);
  signal frame_buffer_read_data        : frame_buffer_data_t;                                    -- Frame buffer read data
                                       
  signal frame_buffer_write_en         : std_logic_vector(NB_FRAME downto 1);             -- Frame buffer write enable
  signal frame_buffer_write_addr       : std_logic_vector(FRAME_BUFFER_ADDR -1 downto 0); -- Frame buffer write address
  signal frame_buffer_write_addr_index : std_logic_vector(FRAME_BUFFER_ADDR_INDEX-1 downto 0);
  signal frame_buffer_write_data       : std_logic_vector(FRAME_BUFFER_WIDTH-1 downto 0); -- Frame buffer write data

  signal frame_buffer_color            : std_logic_vector(8-1 downto 0);                  -- Current frame color
  signal frame_buffer_color_r          : frame_buffer_color_t;                            -- Frame color register (NB_FRAME + Background)
  signal frame_buffer_color_rdata      : std_logic_vector(8-1 downto 0);                  -- Read data frame color
  
--                                     
--  signal   text_buffer_read_en       : std_logic;
--  signal   text_buffer_read_addr     : std_logic_vector(TEXT_BUFFER_ADDR_SIZE_CUR-1 downto 0);
--  signal   text_buffer_read_addr_x   : std_logic_vector(TEXT_BUFFER_ADDR_X_SIZE-1 downto 0);
--  signal   text_buffer_read_addr_y   : std_logic_vector(TEXT_BUFFER_ADDR_Y_SIZE-1 downto 0);
--  signal   text_buffer_read_code     : std_logic_vector(7 downto 0);
--  signal   text_buffer_write_en      : std_logic;
--  signal   text_buffer_write_addr    : std_logic_vector(TEXT_BUFFER_ADDR_SIZE_CUR-1 downto 0);
--  signal   text_buffer_write_code    : std_logic_vector(7 downto 0);
--  signal   font_memory_read_addr     : std_logic_vector(7 downto 0);
--  signal   character_read_addr_x     : std_logic_vector(2 downto 0);
--  signal   character_read_addr_y     : std_logic_vector(3 downto 0);
--  signal   pixel                     : std_logic;
--                                     
--  -- config                          
    signal   config_r                  : std_logic_vector(1 downto 0);
--                                      [1:0] Mode
--                                            00 Frame buffer mode
--                                            01 reserved (Unicolor mode)
--                                            10 reserved
--                                            11 Text mode
    alias    cfg_mode                  : std_logic_vector(1 downto 0) is config_r(1 downto 0);
--                                     
    signal   vga_RGB                   : std_logic_vector(8-1 downto 0);
    signal   vga_RGB_unicolor          : std_logic_vector(8-1 downto 0);
--  signal   vga_RGB_text              : std_logic_vector(8-1 downto 0);
--  signal   vga_RGB_text_background   : std_logic_vector(8-1 downto 0);
--  signal   vga_RGB_text_foreground   : std_logic_vector(8-1 downto 0);
    signal   vga_RGB_frame             : std_logic_vector(8-1 downto 0);
--                                     
--  signal   vga_HCOUNT_ext            : std_logic_vector (TEXT_BUFFER_ADDR_SIZE_MAX-1  downto 0);
--  signal   vga_HCOUNT_ext1           : std_logic_vector (TEXT_BUFFER_ADDR_SIZE_MAX-1  downto 0);
--  signal   vga_HCOUNT_ext2           : std_logic_vector (TEXT_BUFFER_ADDR_SIZE_MAX-1  downto 0);
--  signal   vga_HCOUNT_en             : std_logic;
--  signal   vga_VCOUNT_ext            : std_logic_vector (TEXT_BUFFER_ADDR_SIZE_MAX-1  downto 0);
--  signal   vga_VCOUNT_ext1           : std_logic_vector (TEXT_BUFFER_ADDR_SIZE_MAX-1  downto 0);
--  signal   vga_VCOUNT_ext2           : std_logic_vector (TEXT_BUFFER_ADDR_SIZE_MAX-1  downto 0);
--  signal   vga_VCOUNT_en             : std_logic;
begin

  -----------------------------------------------------------------------------
  -- Reset
  -----------------------------------------------------------------------------
  arst   <= not arstn_i;
  
  -----------------------------------------------------------------------------
  -- Clock
  -----------------------------------------------------------------------------
  ins_clk_pixel: entity work.clock_divider(rtl)
  generic map (RATIO => CLK_PIXEL_RATIO)
  port    map (
     clk_i          => clk_i
    ,arstn_i        => arstn_i
    ,cke_i          => '1'
    ,clk_div_o      => clk_pixel
    );

  -----------------------------------------------------------------------------
  -- VGA Controller
  -----------------------------------------------------------------------------
  ins_vga_controller : entity work.vga_controller_640_60(Behavioral)
  port map (
    pixel_clk   => clk_pixel
   ,rst         => arst
   ,HS          => vga_HSYNC
   ,VS          => vga_VSYNC
   ,hcount      => vga_HCOUNT
   ,vcount      => vga_VCOUNT
   ,blank       => vga_Blank
   );

  -----------------------------------------------------------------------------
  -- Frame Number
  -----------------------------------------------------------------------------
  process(arstn_i,clk_i)
  begin 
    if arstn_i='0'         -- reset actif haut
    then
      frame_buffer_num_r <= (others => '0');
    elsif rising_edge(clk_i)
    then 
      if (cs_i = '1' and we_i = '1')
      then
        if (addr_i = WADDR_FRAME_BUFFER_NUM)
        then 
          frame_buffer_num_r <= wdata_i(frame_buffer_num_r'range);
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Frame Offset
  -----------------------------------------------------------------------------
  process(arstn_i,clk_i)
  begin 
    if arstn_i='0'         -- reset actif haut
    then
      frame_buffer_x_offset_r <= (others=>'0');
      frame_buffer_y_offset_r <= (others=>'0'); 
    elsif rising_edge(clk_i)
    then
      -- TODO : implement frame offset
    end if;
  end process;

  -- Compute X and Y position
  -- Add the offset. If overflow, then make the modulo
  frame_buffer_x      <= address(vga_HCOUNT,frame_buffer_x_offset_r,DISPLAY_X_LINES);
  frame_buffer_y      <= address(vga_VCOUNT,frame_buffer_y_offset_r,DISPLAY_Y_LINES);

  -----------------------------------------------------------------------------
  -- Frame Buffer read address
  -----------------------------------------------------------------------------

  frame_buffer_x_raddr<= address_downscale(frame_buffer_x       ,FRAME_BUFFER_DOWNSCALE);
  frame_buffer_y_raddr<= address_downscale(frame_buffer_y       ,FRAME_BUFFER_DOWNSCALE);

  -----------------------------------------------------------------------------
  -- Frame Buffer write address
  -----------------------------------------------------------------------------
--process(arstn_i,clk_i)
--begin 
--  if arstn_i='0'         -- reset actif haut
--  then
--    frame_buffer_x_addr_r <= (others => '0');
--    frame_buffer_y_addr_r <= (others => '0');
--  elsif rising_edge(clk_i)
--  then 
--    if (cs_i = '1' and we_i = '1')
--    then
--      if (addr_i = WADDR_FRAME_BUFFER_ADDR_X_LSB)
--      then 
--        frame_buffer_x_addr_r(wdata_i'range) <= wdata_i;
--      end if;
--      if (addr_i = WADDR_FRAME_BUFFER_ADDR_X_MSB)
--      then 
--        frame_buffer_x_addr_r(frame_buffer_x_addr_r'high downto wdata_i'high+1) <= wdata_i(frame_buffer_x_addr_r'high-wdata_i'high downto 0);
--      end if;
--      if (addr_i = WADDR_FRAME_BUFFER_ADDR_Y_LSB)
--      then 
--        frame_buffer_y_addr_r(wdata_i'range) <= wdata_i;
--      end if;
--      if (addr_i = WADDR_FRAME_BUFFER_ADDR_Y_MSB)
--      then 
--        frame_buffer_y_addr_r(frame_buffer_y_addr_r'high downto wdata_i'high+1) <= wdata_i(frame_buffer_y_addr_r'high-wdata_i'high downto 0);
--      end if;
--    end if;
--  end if;
--end process;
--
--frame_buffer_x_waddr<= address_downscale(frame_buffer_x_addr_r,FRAME_BUFFER_DOWNSCALE);
--frame_buffer_y_waddr<= address_downscale(frame_buffer_y_addr_r,FRAME_BUFFER_DOWNSCALE);

  process(arstn_i,clk_i)
  begin 
    if arstn_i='0'         -- reset actif haut
    then
      frame_buffer_x_addr_r <= (others => '0');
      frame_buffer_y_addr_r <= (others => '0');
    elsif rising_edge(clk_i)
    then 
      if (cs_i = '1' and we_i = '1')
      then
        if (addr_i = WADDR_FRAME_BUFFER_ADDR_X_LSB)
        then 
          frame_buffer_x_addr_r <= wdata_i(frame_buffer_x_addr_r'range);
        end if;
        if (addr_i = WADDR_FRAME_BUFFER_ADDR_Y_LSB)
        then 
          frame_buffer_y_addr_r <= wdata_i(frame_buffer_y_addr_r'range);
        end if;
      end if;
    end if;
  end process;
  
  frame_buffer_x_waddr<= std_logic_vector(resize(unsigned(frame_buffer_x_addr_r), frame_buffer_x_waddr'length));
  frame_buffer_y_waddr<= std_logic_vector(resize(unsigned(frame_buffer_y_addr_r), frame_buffer_y_waddr'length));

  
  -----------------------------------------------------------------------------
  -- Frame Buffer
  -----------------------------------------------------------------------------
  frame_buffer_read_en    <= not vga_Blank;
  frame_buffer_read_addr  <= std_logic_vector(resize(unsigned(conv_address(frame_buffer_x_raddr,frame_buffer_y_raddr,FRAME_BUFFER_X_LINES)),frame_buffer_read_addr'length));

  frame_buffer_write_addr <= std_logic_vector(resize(unsigned(conv_address(frame_buffer_x_waddr,frame_buffer_y_waddr,FRAME_BUFFER_X_LINES)),frame_buffer_read_addr'length));
  frame_buffer_write_data <= wdata_i(frame_buffer_write_data'range);

  frame_buffer_write_addr_index <= frame_buffer_write_addr;
  
  gen_frame_buffer: for i in 1 to NB_FRAME
  generate
    frame_buffer_write_en(i) <= '1' when (cs_i = '1' and we_i = '1' and addr_i = WADDR_FRAME_BUFFER_DATA and to_integer(unsigned(frame_buffer_num_r)) = i) else
                                '0';

    ins_frame_buffer : entity work.vga_buffer(rtl)
      generic map
      (WIDTH    => FRAME_BUFFER_WIDTH,
       DEPTH    => FRAME_BUFFER_DEPTH
       )
      port map
      (clk_i    => clk_i
      ,arstn_i  => arstn_i
  
      ,re_i     => frame_buffer_read_en
      ,raddr_i  => frame_buffer_read_addr_index
      ,rdata_o  => frame_buffer_read_data(i)
      ,rovf_o   => open
      
      ,we_i     => frame_buffer_write_en (i)
      ,waddr_i  => frame_buffer_write_addr_index
      ,wdata_i  => frame_buffer_write_data
      ,wovf_o   => open
       );
  end generate gen_frame_buffer;

  -----------------------------------------------------------------------------
  -- Frame Color
  -----------------------------------------------------------------------------
  process(arstn_i,clk_i)
  begin 
    if arstn_i='0'         -- reset actif haut
    then
      for i in 0 to NB_FRAME
      loop
        frame_buffer_color_r(i) <= (others => '0');
      end loop;  -- i
    elsif rising_edge(clk_i)
    then
      if (cs_i = '1' and we_i = '1')
      then
        if (addr_i = WADDR_FRAME_BUFFER_COLOR)
        then
          for i in 0 to NB_FRAME
          loop
            if (to_integer(unsigned(frame_buffer_num_r)) = i)
            then 
              frame_buffer_color_r(i) <= wdata_i(frame_buffer_color_r(i)'range);
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;

  gen_frame_buffer_color_rdata: process (frame_buffer_color_r,
                                   frame_buffer_num_r) is
    variable color : std_logic_vector(8-1 downto 0);
  begin  -- process gen_frame_buffer_color_rdata
    color := frame_buffer_color_r(0);

    for i in 1 to NB_FRAME
    loop
      if (to_integer(unsigned(frame_buffer_num_r)) = i)
      then 
        frame_buffer_color_rdata <= frame_buffer_color_r(i);
      end if;
    end loop;  -- i

    frame_buffer_color_rdata <= color;
  end process gen_frame_buffer_color_rdata;

  gen_use_offset: if FRAME_BUFFER_ADDR_OFFSET>0
  generate
    frame_buffer_read_addr_index  <= frame_buffer_read_addr(FRAME_BUFFER_ADDR-1 downto FRAME_BUFFER_ADDR_OFFSET);
    frame_buffer_read_addr_offset <= frame_buffer_read_addr(FRAME_BUFFER_ADDR_OFFSET-1 downto 0);

    gen_frame_buffer_color: process (frame_buffer_color_r,
                                     frame_buffer_read_data,
                                     frame_buffer_read_addr_offset) is
      variable color : std_logic_vector(8-1 downto 0);
      variable pixel : std_logic;
    begin  -- process gen_frame_buffer_color
      color := frame_buffer_color_r(0);

      for i in 1 to NB_FRAME
      loop
        pixel := frame_buffer_read_data(i)(to_integer(unsigned(frame_buffer_read_addr_offset)));

        if pixel = '1'
        then
          color := frame_buffer_color_r(i);
        end if;
      end loop;  -- i

      frame_buffer_color <= color;
    end process gen_frame_buffer_color;
  end generate gen_use_offset;

  gen_dont_use_offset: if FRAME_BUFFER_ADDR_OFFSET=0
  generate
    frame_buffer_read_addr_index  <= frame_buffer_read_addr;

    gen_frame_buffer_color: process (frame_buffer_color_r,
                                     frame_buffer_read_data) is
      variable color : std_logic_vector(8-1 downto 0);
      variable pixel : std_logic;
    begin  -- process gen_frame_buffer_color
      color := frame_buffer_color_r(0);

      for i in 1 to NB_FRAME
      loop
        pixel := frame_buffer_read_data(i)(0);

        if pixel = '1'
        then
          color := frame_buffer_color_r(i);
        end if;
      end loop;  -- i

      frame_buffer_color <= color;
    end process gen_frame_buffer_color;
  end generate gen_dont_use_offset;

  vga_RGB_unicolor <= frame_buffer_color_r(0);
  vga_RGB_frame    <= frame_buffer_color;
  
--  -----------------------------------------------------------------------------
--  -- Text Buffer
--  -----------------------------------------------------------------------------
--  ins_text_buffer : entity work.vga_buffer(rtl)
--  generic map (
--    WIDTH    => 8,
--    DEPTH    => TEXT_BUFFER_DEPTH_CUR
--    )
--
--  port map (
--    clk_i    => clk_i
--   ,arstn_i  => arstn_i
--
--   ,re_i     => text_buffer_read_en
--   ,raddr_i  => text_buffer_read_addr
--   ,rdata_o  => text_buffer_read_code
--   ,rovf_o   => open
--
--   ,we_i     => text_buffer_write_en    
--   ,waddr_i  => text_buffer_write_addr
--   ,wdata_i  => text_buffer_write_code
--   ,wovf_o   => open
--    );
--
--  -----------------------------------------------------------------------------
--  -- Text Buffer Access
--  -----------------------------------------------------------------------------
--  text_buffer_read_en     <= not vga_Blank and vga_HCOUNT_en and vga_VCOUNT_en;
--  text_buffer_read_addr_x <= vga_HCOUNT_ext2(TEXT_BUFFER_ADDR_X_SIZE-1 downto 0);
--  text_buffer_read_addr_y <= vga_VCOUNT_ext2(TEXT_BUFFER_ADDR_Y_SIZE-1 downto 0);
--  text_buffer_read_addr   <= text_buffer_read_addr_y(2 downto 0) & text_buffer_read_addr_x(2 downto 0);
--
--  -- Write in the Text Buffer by the bus
--  text_buffer_write_en    <= '1' when (cs_i = '1' and we_i = '1') and (addr_i = WADDR_TEXT_BUFFER) else
--                             '0';
--  text_buffer_write_code  <= wdata_i;
--  text_buffer_write_addr  <= text_buffer_write_addr_y_r(2 downto 0) & text_buffer_write_addr_x_r(2 downto 0);
--  
--  -----------------------------------------------------------------------------
--  -- Font ROM access
--  -----------------------------------------------------------------------------
--  font_memory_read_addr   <= text_buffer_read_code;
--  character_read_addr_x   <= vga_HCOUNT(2 downto 0);
--  character_read_addr_y   <= vga_VCOUNT(3 downto 0);
--
--  -----------------------------------------------------------------------------
--  -- Font ROM
--  -----------------------------------------------------------------------------
--  ins_font_memory : entity work.vga_font_memory(rtl)
--  port map (
----  clk_i            => clk_i
---- ,arstn_i          => arstn_i
--    character_id_i => font_memory_read_addr
--   ,character_x_i  => character_read_addr_x
--   ,character_y_i  => character_read_addr_y
--   ,pixel_o        => pixel
--    );
--
--  -----------------------------------------------------------------------------
--  -- Display
--  -----------------------------------------------------------------------------
--  vga_RGB_unicolor        <= color_r;
--  vga_RGB_text_background <= color_r(6) & "00" &              -- Red
--                             color_r(5) & "00" &              -- Green
--                             color_r(4) & "0"  ;              -- Blue
--  vga_RGB_text_foreground <= color_r(2) & color_r(3) & "0" &  -- Red
--                             color_r(1) & color_r(3) & "0" &  -- Green
--                             color_r(0) & color_r(3);         -- Blue
--  vga_RGB_text            <= vga_RGB_text_foreground when pixel = '1' else
--                             vga_RGB_text_background;
--  vga_RGB                 <= vga_RGB_unicolor when cfg_mode = MODE_UNICOLOR else
--                             vga_RGB_text     when cfg_mode = MODE_TEXT     else
--                             vga_RGB_frame    when cfg_mode = MODE_FRAME    else
--                             (others => '0');  -- black
--                             
--  -----------------------------------------------------------------------------
--  -- Configuration Register
--  -----------------------------------------------------------------------------
--  process(arstn_i,clk_i)
--  begin 
--    if arstn_i='0'         -- reset actif haut
--    then
--      config_r                 <= (others => '0');
--      color_r                  <= (others => '0');
--
--      text_buffer_write_addr_x_r <= (others => '0');
--      text_buffer_write_addr_y_r <= (others => '0');
--    elsif rising_edge(clk_i)
--    then 
--      if (cs_i = '1' and we_i = '1')
--      then
--        if (addr_i = WADDR_CFG)
--        then 
--          config_r <= wdata_i(config_r'range);
--        end if;
--        
--        if (addr_i = WADDR_COLOR)
--        then 
--          color_r <= wdata_i;
--        end if;
--
--        if (addr_i = WADDR_TEXT_BUFFER)
--        then
--          if ((unsigned(text_buffer_write_addr_x_r)+1) < to_unsigned(TEXT_BUFFER_X_CUR,TEXT_BUFFER_ADDR_X_SIZE))
--          then
--            text_buffer_write_addr_x_r <= std_logic_vector(unsigned(text_buffer_write_addr_x_r) + to_unsigned(1,TEXT_BUFFER_ADDR_X_SIZE));
--          else
--            text_buffer_write_addr_x_r <= (others => '0');
--
--            if ((unsigned(text_buffer_write_addr_y_r)+1) < to_unsigned(TEXT_BUFFER_Y_CUR,TEXT_BUFFER_ADDR_Y_SIZE))
--            then
--              text_buffer_write_addr_y_r <= std_logic_vector(unsigned(text_buffer_write_addr_y_r) + to_unsigned(1,TEXT_BUFFER_ADDR_Y_SIZE));
--            else
--              text_buffer_write_addr_y_r <= (others => '0');
--            end if;
--          end if;
--        end if;
--      end if;
--    end if;
--  end process;
--
--  -----------------------------------------------------------------------------
--  -- Address - vga
--  -----------------------------------------------------------------------------
--  vga_HCOUNT_ext          <= "00"&vga_HCOUNT;
--  vga_HCOUNT_ext1         <= std_logic_vector(unsigned(vga_HCOUNT_ext)/to_unsigned(CHAR_X_MAX,TEXT_BUFFER_ADDR_SIZE_MAX));
--  vga_HCOUNT_en           <= '1' when unsigned(vga_HCOUNT_ext1)<to_unsigned(TEXT_BUFFER_X_CUR,TEXT_BUFFER_ADDR_SIZE_MAX) else '0';
--  vga_HCOUNT_ext2         <= vga_HCOUNT_ext1 when vga_HCOUNT_en = '1' else (others => '0');
--  vga_VCOUNT_ext          <= "00"&vga_VCOUNT;
--  vga_VCOUNT_ext1         <= std_logic_vector(unsigned(vga_VCOUNT_ext)/to_unsigned(CHAR_Y_MAX,TEXT_BUFFER_ADDR_SIZE_MAX));
--  vga_VCOUNT_en           <= '1' when unsigned(vga_VCOUNT_ext1)<to_unsigned(TEXT_BUFFER_Y_CUR,TEXT_BUFFER_ADDR_SIZE_MAX) else '0';
--  vga_VCOUNT_ext2         <= vga_VCOUNT_ext1 when vga_VCOUNT_en = '1' else (others => '0');

  -----------------------------------------------------------------------------
  -- Configuration Register
  -----------------------------------------------------------------------------
  process(arstn_i,clk_i)
  begin 
    if arstn_i='0'         -- reset actif haut
    then
      config_r                 <= (others => '0');
    elsif rising_edge(clk_i)
    then 
      if (cs_i = '1' and we_i = '1')
      then
        if (addr_i = WADDR_CFG)
        then 
          config_r <= wdata_i(config_r'range);
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Display
  -----------------------------------------------------------------------------
  vga_RGB                 <= vga_RGB_unicolor when cfg_mode = MODE_UNICOLOR else
--                           vga_RGB_text     when cfg_mode = MODE_TEXT     else
                             vga_RGB_frame    when cfg_mode = MODE_FRAME    else
                             (others => '0');  -- black

  -----------------------------------------------------------------------------
  -- read internal register
  -----------------------------------------------------------------------------
  busy_o                  <= '0'; -- Never Busy

  rdata_o                 <= std_logic_vector(resize(unsigned(frame_buffer_num_r      ), rdata_o'length))   when (addr_i = RADDR_FRAME_BUFFER_NUM  ) else
                             std_logic_vector(resize(unsigned(frame_buffer_color_rdata), rdata_o'length))   when (addr_i = RADDR_FRAME_BUFFER_COLOR) else
                             std_logic_vector(resize(unsigned(config_r                ), rdata_o'length));--when (addr_i = RADDR_CFG               );

  -----------------------------------------------------------------------------
  -- VGA Output
  -----------------------------------------------------------------------------
  vga_HSYNC_o             <= vga_HSYNC;
  vga_VSYNC_o             <= vga_VSYNC;
  vga_Red_o               <= vga_RGB(7 downto 5) when vga_Blank = '0' else (others => '0');
  vga_Green_o             <= vga_RGB(4 downto 2) when vga_Blank = '0' else (others => '0');
  vga_Blue_o              <= vga_RGB(1 downto 0) when vga_Blank = '0' else (others => '0');
  
end rtl;

