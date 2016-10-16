-- ----------------------------------------------------------------------------
--                         WS2812B CONTROLLER FOR FPGAS                        
-- ----------------------------------------------------------------------------
-- bench_demo_rainbow.vhd : Testbench for the rainbow demo.
-- ----------------------------------------------------------------------------
-- Author          : Markus Koch <markus@notsyncing.net>
-- Contributors    : None 
-- Created on      : 2016/10/16
-- License         : Mozilla Public License (MPL) Version 2
-- ----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library design;
use design.all;

entity bench_demo_rainbow is
end entity bench_demo_rainbow;

architecture RTL of bench_demo_rainbow is
	signal clk    : std_logic;
	signal rst_hw : std_logic;
	signal btn_n  : std_logic;
	signal so     : std_logic;
begin
	demo_rainbow_inst : entity design.demo_rainbow
		port map(
			clk    => clk,
			rst_hw => rst_hw,
			btn_n  => btn_n,
			so     => so
		);

	clock_driver : process
		constant period : time := 20 ns;
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process clock_driver;

	test_p : process is
	begin
		rst_hw <= '0';
		btn_n  <= '1';

		wait for 20 ns;
		rst_hw <= '1';

		wait;
	end process test_p;

end architecture RTL;
