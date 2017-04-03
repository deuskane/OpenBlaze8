-------------------------------------------------------------------------------
-- Title      : uart
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : uart_wrapper.vhd
-- Author     : Cédric DEBARGE
-- Company    :
-- Created    : 2017-03-30
-- Last update: 2017-04-03
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-- Just a simple wrapper around gh uart without interruption nor handshakes
-- Register Map :
-- [0] Read  : TBD
-- [0] Write : TBD
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-12-26  0.1      debarge	Creation
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;

library work;
use work.math_pkg.all;

entity uart_wrapper is
	generic(
		SIZE_DATA	: natural:=8;							-- Bus Data    Width
		CLK_FREQ	: natural:=50_000_000		-- 50MHz  is the devkit default osc
	);
	port(
		clk_i     : in std_logic;
		cke_i			: in std_logic;
		resetn_i  : in std_logic;

		-- Cpu Interface
		cs_i             : in    std_logic;
		re_i             : in    std_logic;
		we_i             : in    std_logic;
		addr_i           : in    std_logic_vector(2 downto 0);
		wdata_i          : in    std_logic_vector(SIZE_DATA-1 downto 0);
		rdata_o          : out   std_logic_vector(SIZE_DATA-1 downto 0);
		busy_o           : out   std_logic;

		-- Serial interface
		sRX_i	    : in std_logic;
		sTX_o     : out std_logic;
		bdr_o			: out std_logic
	);
end entity;

architecture rtl of uart_wrapper is

	component gh_uart_16550 is
		port(
			clk     : in std_logic;
			BR_clk  : in std_logic;
			rst     : in std_logic;
			CS      : in std_logic;
			WR      : in std_logic;
			ADD     : in std_logic_vector(2 downto 0);
			D       : in std_logic_vector(7 downto 0);

			sRX	    : in std_logic;
			CTSn    : in std_logic := '1';
			DSRn    : in std_logic := '1';
			RIn     : in std_logic := '1';
			DCDn    : in std_logic := '1';

			sTX     : out std_logic;
			DTRn    : out std_logic;
			RTSn    : out std_logic;
			OUT1n   : out std_logic;
			OUT2n   : out std_logic;
			TXRDYn  : out std_logic;
			RXRDYn  : out std_logic;

			IRQ     : out std_logic;
			B_CLK   : out std_logic;
			RD      : out std_logic_vector(7 downto 0)
			);
	end component;

	constant PC16550_DEFAULT_OSC : natural := 115200*16;
--	constant CLK_DIV_MAX : natural := CLK_FREQ/(2*PC16550_DEFAULT_OSC);

	signal reset : std_logic;
	signal s_clk : std_logic;
--	signal clk_div: std_logic_vector(log2(CLK_DIV_MAX) downto 0);

begin

	-- Main UART instance
	gh_uart : gh_uart_16550
		port map(
			clk     => clk_i,
			BR_clk  => s_clk,
			rst     => reset,
			CS      => cs_i,
			WR      => we_i,
			ADD     => addr_i,
			D       => wdata_i,
			RD      => rdata_o,

			sRX     => sRx_i,
			CTSn    => '0',
			DSRn    => '0',
			RIn     => '0',
			DCDn    => '0',

			sTX     => sTx_o,
			DTRn    => Open,
			RTSn    => Open,
			OUT1n   => Open,
			OUT2n   => Open,
			TXRDYn  => Open,
			RXRDYn  => Open,

			IRQ     => Open,
			B_CLK   => bdr_o	-- out the baudrate for debug purposes
			);

--	-- Serial clk generation
--	s_clk_gen : process(clk_i, reset)
--	begin
--		if reset = '1' then
--			s_clk <= '0';
--			clk_div <= (Others => '0');
--		elsif rising_edge(clk_i) then
--			if clk_div = std_logic_vector(to_unsigned(CLK_DIV_MAX, clk_div'length)) then
--				s_clk <= not s_clk;
--				clk_div <= (Others => '0');
--			else
--				clk_div <= std_logic_vector(unsigned(clk_div) + 1);
--			end if;
--		end if;
--	end process s_clk_gen;

        ins_clock_divider : entity work.clock_divider(rtl)
          generic map(
            RATIO            => CLK_FREQ/PC16550_DEFAULT_OSC
            )
          port map (
            clk_i            => clk_i  ,
            arstn_i          => resetn_i,
            clk_div_o        => s_clk
            );

        
	reset <= not resetn_i;
	busy_o <= '0'; -- never busy

end rtl;
