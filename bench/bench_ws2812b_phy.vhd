-- ----------------------------------------------------------------------------
--                         WS2812B CONTROLLER FOR FPGAS                        
-- ----------------------------------------------------------------------------
-- bench_ws2812b_phy.vhd : Development testbench for the WS2812B phy module.
-- ----------------------------------------------------------------------------
-- Author          : Markus Koch <markus@notsyncing.net>
-- Contributors    : None 
-- Created on      : 2016/10/16
-- License         : Mozilla Public License (MPL) Version 2
-- ----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ws2812b;
use ws2812b.all;

entity bench_ws2812b_phy is
end entity bench_ws2812b_phy;

architecture RTL of bench_ws2812b_phy is
	signal clk           : std_logic;
	signal rst           : std_logic;
	signal so            : std_logic;
	signal pixData_red   : std_logic_vector(7 downto 0);
	signal pixData_green : std_logic_vector(7 downto 0);
	signal pixData_blue  : std_logic_vector(7 downto 0);
	signal pixData_valid : std_logic;
	signal pixData_next  : std_logic;

begin
	clock_driver : process
		constant period : time := 10 ns;
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process clock_driver;

	ws2812b_phy_inst : entity ws2812b.ws2812b_phy
		generic map(
			f_clk => 100000000
		)
		port map(
			clk           => clk,
			rst           => rst,
			so            => so,
			pixData_red   => pixData_red,
			pixData_green => pixData_green,
			pixData_blue  => pixData_blue,
			pixData_valid => pixData_valid,
			pixData_next  => pixData_next
		);

	test : process is
	begin
		pixData_red   <= x"00";
		pixData_green <= x"80";
		pixData_blue  <= x"01";
		pixData_valid <= '0';
		rst           <= '1';
		wait for 20 ns;
		rst <= '0';
		wait for 20 ns;
		pixData_valid <= '1';

		wait until pixData_next = '1';  -- Pix 0
		wait until pixData_next = '1';  -- Pix 1
		pixData_valid <= '0';
		wait until pixData_next = '1';  -- Reset ack

		pixData_valid <= '1';
		wait until pixData_next = '1';  -- Pix 0
		wait until pixData_next = '1';  -- Pix 1
		pixData_valid <= '0';
		wait until pixData_next = '1';  -- Reset ack

		wait;
	end process test;

end architecture RTL;
