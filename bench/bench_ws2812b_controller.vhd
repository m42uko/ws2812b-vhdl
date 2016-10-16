-- ----------------------------------------------------------------------------
--                         WS2812B CONTROLLER FOR FPGAS                        
-- ----------------------------------------------------------------------------
-- bench_ws2812b_controller.vhd : Testbench for the SRAM controller module
--                              : to drive the WS2812B LEDs.
-- ----------------------------------------------------------------------------
-- Author          : Markus Koch <markus@notsyncing.net>
-- Contributors    : None 
-- Created on      : 2016/10/16
-- License         : Mozilla Public License (MPL) Version 2
-- ----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library design;
use design.all;

entity bench_ws2812b_controller is
end entity bench_ws2812b_controller;

architecture RTL of bench_ws2812b_controller is
	constant length : integer := 4;

	signal clk           : std_logic;
	signal rst           : std_logic;
	signal so            : std_logic;
	signal addr          : std_logic_vector(integer(ceil(log2(real(length - 1)))) downto 0);
	signal data_red      : std_logic_vector(7 downto 0);
	signal data_green    : std_logic_vector(7 downto 0);
	signal data_blue     : std_logic_vector(7 downto 0);
	signal dataOut_red   : std_logic_vector(7 downto 0);
	signal dataOut_green : std_logic_vector(7 downto 0);
	signal dataOut_blue  : std_logic_vector(7 downto 0);
	signal we            : std_logic;
	signal render        : std_logic;
	signal vsync         : std_logic;

begin
	ws2812b_controller_inst : entity design.ws2812b_controller
		generic map(
			length => length,
			f_clk  => 100000000)
		port map(
			clk           => clk,
			rst           => rst,
			so            => so,
			addr          => addr,
			data_red      => data_red,
			data_green    => data_green,
			data_blue     => data_blue,
			dataOut_red   => dataOut_red,
			dataOut_green => dataOut_green,
			dataOut_blue  => dataOut_blue,
			we            => we,
			render        => render,
			vsync         => vsync
		);

	clock_driver : process
		constant period : time := 10 ns;
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process clock_driver;

	test : process is
	begin
		rst        <= '1';
		addr       <= (others => '0');
		data_red   <= (others => '0');
		data_green <= (others => '0');
		data_blue  <= (others => '0');
		render     <= '0';
		wait for 20 ns;

		rst <= '0';
		wait for 60 ns;
		render <= '1';
		wait for 20 ns;
		render <= '0';

		wait;
	end process test;

end architecture RTL;
