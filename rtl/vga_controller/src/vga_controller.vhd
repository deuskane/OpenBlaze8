-------------------------------------------------------------------------------
-- Title      : display VGA
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : display_VGA.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2017-03-31
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-- Register Map :
-- [0] Read  : config
-- [1] Read  : color
-- [0] Write : config
-- [1] Write : color
-- [2] Write : text buffer
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-02-07  0.2      rosiere bus_read_data : protection during a reset
-- 2013-12-26  0.1      rosiere	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity vga_controller is
  generic(FSYS     : positive := 50_000_000;
          SIZE_ADDR: natural  := 2         ;
          SIZE_DATA: natural  := 8
          );
    Port (clk_i          : in  STD_LOGIC;
          arstn_i        : in  STD_LOGIC;

          -- To IP
          cs_i           : in    std_logic;
          re_i           : in    std_logic;
          we_i           : in    std_logic;
          addr_i         : in    std_logic_vector (SIZE_ADDR-1 downto 0);
          wdata_i        : in    std_logic_vector (SIZE_DATA-1 downto 0);
          rdata_o        : out   std_logic_vector (SIZE_DATA-1 downto 0);
          busy_o         : out   std_logic;

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
  constant raddr_cfg               : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(0,SIZE_ADDR));
  constant raddr_color             : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(1,SIZE_ADDR));
--constant raddr_text_buffer       : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(2,SIZE_ADDR));

  constant waddr_cfg               : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(0,SIZE_ADDR));
  constant waddr_color             : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(1,SIZE_ADDR));
  constant waddr_text_buffer       : std_logic_vector (SIZE_ADDR-1 downto 0) := std_logic_vector(to_unsigned(2,SIZE_ADDR));
                                   
  -----------------------------------------------------------------------------
  -- Local parameters
  -----------------------------------------------------------------------------
  constant display_x_max           : natural := 640;
  constant display_y_max           : natural := 480;
  constant char_x_max              : natural := 8 ;    -- 640x480 : 
  constant char_y_max              : natural := 16;    -- 640x480 : 
  constant text_buffer_x_max       : natural := display_x_max/char_x_max;
  constant text_buffer_y_max       : natural := display_y_max/char_y_max;
  constant text_buffer_depth_max   : natural := text_buffer_x_max * text_buffer_y_max;  -- 640x480 : 80x30 character
  constant text_buffer_addr_size_max  : natural := 13;
  constant text_buffer_addr_x_size : natural := 7;
  constant text_buffer_addr_y_size : natural := 5;
--constant font_memory_depth_max   : natural := 2**8;  -- ASCII : 8bits

  constant text_buffer_x_cur         : natural := 8;
  constant text_buffer_y_cur         : natural := 8;
  constant text_buffer_depth_cur     : natural := 64;
  constant text_buffer_addr_size_cur : natural := 6;
  
  constant mode_text               : std_logic_vector(1 downto 0) := "00";
  constant mode_unicolor           : std_logic_vector(1 downto 0) := "01";

  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  signal   config_r                : std_logic_vector(7 downto 0);
  signal   color_r                 : std_logic_vector(7 downto 0);

  signal   text_buffer_write_addr_x_r: std_logic_vector(text_buffer_addr_x_size-1 downto 0);
  signal   text_buffer_write_addr_y_r: std_logic_vector(text_buffer_addr_y_size-1 downto 0);
  -----------------------------------------------------------------------------
  -- Signal
  -----------------------------------------------------------------------------
  signal   arst                    : std_logic;
  
  signal   text_buffer_read_en     : std_logic;
  signal   text_buffer_read_addr   : std_logic_vector(text_buffer_addr_size_cur-1 downto 0);
  signal   text_buffer_read_addr_x : std_logic_vector(text_buffer_addr_x_size-1 downto 0);
  signal   text_buffer_read_addr_y : std_logic_vector(text_buffer_addr_y_size-1 downto 0);
  signal   text_buffer_read_code   : std_logic_vector(7 downto 0);
  signal   text_buffer_write_en    : std_logic;
  signal   text_buffer_write_addr  : std_logic_vector(text_buffer_addr_size_cur-1 downto 0);
  signal   text_buffer_write_code  : std_logic_vector(7 downto 0);
  signal   font_memory_read_addr   : std_logic_vector(7 downto 0);
  signal   character_read_addr_x   : std_logic_vector(2 downto 0);
  signal   character_read_addr_y   : std_logic_vector(3 downto 0);
  signal   pixel                   : std_logic;
  
  -- config
  alias    cfg_mode                : std_logic_vector(1 downto 0) is config_r(1 downto 0);

  signal   vga_RGB                 : std_logic_vector(7 downto 0);
  signal   vga_RGB_unicolor        : std_logic_vector(7 downto 0);
  signal   vga_RGB_text            : std_logic_vector(7 downto 0);
  signal   vga_RGB_text_background : std_logic_vector(7 downto 0);
  signal   vga_RGB_text_foreground : std_logic_vector(7 downto 0);
           
  signal   clk_25Mhz               : std_logic;
--signal   clk_40Mhz               : std_logic;
--signal   vga_Resolution          : std_logic;
  signal   vga_Blank               : std_logic;
  signal   vga_HCOUNT              : std_logic_vector (10 downto 0);
  signal   vga_HCOUNT_ext          : std_logic_vector (text_buffer_addr_size_max-1  downto 0);
  signal   vga_HCOUNT_ext1         : std_logic_vector (text_buffer_addr_size_max-1  downto 0);
  signal   vga_HCOUNT_ext2         : std_logic_vector (text_buffer_addr_size_max-1  downto 0);
  signal   vga_HCOUNT_en           : std_logic;
  signal   vga_VCOUNT              : std_logic_vector (10 downto 0); 
  signal   vga_VCOUNT_ext          : std_logic_vector (text_buffer_addr_size_max-1  downto 0);
  signal   vga_VCOUNT_ext1         : std_logic_vector (text_buffer_addr_size_max-1  downto 0);
  signal   vga_VCOUNT_ext2         : std_logic_vector (text_buffer_addr_size_max-1  downto 0);
  signal   vga_VCOUNT_en           : std_logic;
begin

  arst   <= not arstn_i;
  -----------------------------------------------------------------------------
  -- Text Buffer
  -----------------------------------------------------------------------------
  instance_text_buffer : entity work.vga_text_buffer(rtl)
  generic map (
    SIZE_CODE => 8,
    DEPTH     => text_buffer_depth_cur,
    SIZE_ADDR => text_buffer_addr_size_cur)

  port map (
    clk_i         => clk_i
   ,arstn_i       => arstn_i

   ,read_en_i     => text_buffer_read_en
   ,read_addr_i   => text_buffer_read_addr
   ,read_code_o   => text_buffer_read_code

   ,write_en_i    => text_buffer_write_en    
   ,write_addr_i  => text_buffer_write_addr
   ,write_code_i  => text_buffer_write_code
    );

  -----------------------------------------------------------------------------
  -- Font ROM
  -----------------------------------------------------------------------------
  instance_font_memory : entity work.vga_font_memory(rtl)
  port map (
--  clk_i            => clk_i
-- ,arstn_i          => arstn_i
    character_id_i => font_memory_read_addr
   ,character_x_i  => character_read_addr_x
   ,character_y_i  => character_read_addr_y
   ,pixel_o        => pixel
    );

  -----------------------------------------------------------------------------
  -- Instance VGA Controller
  -----------------------------------------------------------------------------

  instance_vga_controller : entity work.vga_controller_640_60(Behavioral)
  port map (
    pixel_clk   => clk_25Mhz
   ,rst         => arst
   ,HS          => vga_HSYNC_o
   ,VS          => vga_VSYNC_o
   ,hcount      => vga_HCOUNT
   ,vcount      => vga_VCOUNT
   ,blank       => vga_Blank
   );
  
  -----------------------------------------------------------------------------
  -- Clock Divider
  -----------------------------------------------------------------------------
  instance_clk_25Mhz: entity work.clock_divider(rtl)
  generic map (ratio => FSYS/25_000_000)
  port    map (
     clk_i          => clk_i
    ,arstn_i        => arstn_i
    ,clk_div_o      => clk_25Mhz
    );

  -----------------------------------------------------------------------------
  -- Display
  -----------------------------------------------------------------------------
--vga_Resolution          <= cfg_resolution; -- 640x480
  vga_RGB_unicolor        <= color_r;
  vga_RGB_text_background <= color_r(6) & "00" &  -- Red
                             color_r(5) & "00" &  -- Green
                             color_r(4) & "0"  ;  -- Blue
  vga_RGB_text_foreground <= color_r(2) & color_r(3) & "0" &  -- Red
                             color_r(1) & color_r(3) & "0" &  -- Green
                             color_r(0) & color_r(3);         -- Blue -- TODO TEST
  vga_RGB_text            <= vga_RGB_text_foreground when pixel = '1' else
                             vga_RGB_text_background;
  vga_RGB                 <= vga_RGB_unicolor when cfg_mode = mode_unicolor else
                             vga_RGB_text     when cfg_mode = mode_text     else
                             (others => '0');  -- black
                             
  vga_Red_o               <= vga_RGB(7 downto 5) when vga_Blank = '0' else (others => '0');
  vga_Green_o             <= vga_RGB(4 downto 2) when vga_Blank = '0' else (others => '0');
  vga_Blue_o              <= vga_RGB(1 downto 0) when vga_Blank = '0' else (others => '0');
  
  -----------------------------------------------------------------------------
  -- Configuration Register
  -----------------------------------------------------------------------------
  process(arstn_i,clk_i)
  begin 
    if arstn_i='0'         -- reset actif haut
    then
      config_r                 <= (others => '0');
      color_r                  <= (others => '0');

      text_buffer_write_addr_x_r <= (others => '0');
      text_buffer_write_addr_y_r <= (others => '0');
    elsif rising_edge(clk_i)
    then 
      if (cs_i = '1' and we_i = '1')
      then
        if (addr_i = waddr_cfg)
        then 
          config_r <= wdata_i;
        end if;
        
        if (addr_i = waddr_color)
        then 
          color_r <= wdata_i;
        end if;

        if (addr_i = waddr_text_buffer)
        then
          if ((unsigned(text_buffer_write_addr_x_r)+1) < to_unsigned(text_buffer_x_cur,text_buffer_addr_x_size))
          then
            text_buffer_write_addr_x_r <= std_logic_vector(unsigned(text_buffer_write_addr_x_r) + to_unsigned(1,text_buffer_addr_x_size));
          else
            text_buffer_write_addr_x_r <= (others => '0');

            if ((unsigned(text_buffer_write_addr_y_r)+1) < to_unsigned(text_buffer_y_cur,text_buffer_addr_y_size))
            then
              text_buffer_write_addr_y_r <= std_logic_vector(unsigned(text_buffer_write_addr_y_r) + to_unsigned(1,text_buffer_addr_y_size));
            else
              text_buffer_write_addr_y_r <= (others => '0');
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Address
  -----------------------------------------------------------------------------
  vga_HCOUNT_ext          <= "00"&vga_HCOUNT;
  vga_HCOUNT_ext1         <= std_logic_vector(unsigned(vga_HCOUNT_ext)/to_unsigned(char_x_max,text_buffer_addr_size_max));
  vga_HCOUNT_en           <= '1' when unsigned(vga_HCOUNT_ext1)<to_unsigned(text_buffer_x_cur,text_buffer_addr_size_max) else '0';
  vga_HCOUNT_ext2         <= vga_HCOUNT_ext1 when vga_HCOUNT_en = '1' else (others => '0');
  vga_VCOUNT_ext          <= "00"&vga_VCOUNT;
  vga_VCOUNT_ext1         <= std_logic_vector(unsigned(vga_VCOUNT_ext)/to_unsigned(char_y_max,text_buffer_addr_size_max));
  vga_VCOUNT_en           <= '1' when unsigned(vga_VCOUNT_ext1)<to_unsigned(text_buffer_y_cur,text_buffer_addr_size_max) else '0';
  vga_VCOUNT_ext2         <= vga_VCOUNT_ext1 when vga_VCOUNT_en = '1' else (others => '0');

  text_buffer_read_en     <= not vga_Blank and vga_HCOUNT_en and vga_VCOUNT_en;
  text_buffer_read_addr_x <= vga_HCOUNT_ext2(text_buffer_addr_x_size-1 downto 0);
  text_buffer_read_addr_y <= vga_VCOUNT_ext2(text_buffer_addr_y_size-1 downto 0);
  text_buffer_read_addr   <= text_buffer_read_addr_y(2 downto 0) & text_buffer_read_addr_x(2 downto 0);
  
  text_buffer_write_en    <= '1' when (cs_i = '1' and we_i = '1') and (addr_i = waddr_text_buffer) else
                             '0';
  text_buffer_write_code  <= wdata_i;
  text_buffer_write_addr  <= text_buffer_write_addr_y_r(2 downto 0) & text_buffer_write_addr_x_r(2 downto 0);
  
  font_memory_read_addr   <= text_buffer_read_code;
  character_read_addr_x   <= vga_HCOUNT(2 downto 0);
  character_read_addr_y   <= vga_VCOUNT(3 downto 0);

  -----------------------------------------------------------------------------
  -- read internal register
  -----------------------------------------------------------------------------
  busy_o         <= '0';
  rdata_o        <= color_r           when (addr_i = raddr_color      ) else
                    config_r; --      when (addr_i = raddr_cfg        );
                    
end rtl;

