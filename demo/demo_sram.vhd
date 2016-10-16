-- ----------------------------------------------------------------------------
--                         WS2812B CONTROLLER FOR FPGAS                        
-- ----------------------------------------------------------------------------
-- top.vhd : Top level design to test the WS2812B controller modules.
--         : Real demo applications coming soon.
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

library ws2812b;
use ws2812b.all;

entity demo_sram is
	port(
		clk    : in  std_logic;
		rst_hw : in  std_logic;
		btn_n  : in  std_logic;
		so     : out std_logic
	);
end entity demo_sram;

architecture RTL of demo_sram is
	constant length : integer := 120;

	signal rst           : std_logic;
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
	signal done          : std_logic;
	signal colIdx        : std_logic_vector(1 downto 0);
begin
	rst <= not rst_hw;

	colIdx <= addr(1 downto 0);

	ws2812b_controller_inst : entity ws2812b.ws2812b_controller
		generic map(
			length => length,
			f_clk  => 50000000
		)
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

	prog : process(clk, rst) is
		variable colRot : unsigned(1 downto 0);
		variable c2     : integer range 0 to 25000000;
	begin
		if rst = '1' then
			addr       <= (others => '1');
			data_red   <= (others => '0');
			data_green <= (others => '0');
			data_blue  <= (others => '0');
			we         <= '0';
			done       <= '1';
			c2         := 0;
			colRot     := "00";
			render     <= '0';
		elsif rising_edge(clk) then
			we     <= '0';
			render <= '0';
			if done = '0' then
				addr <= std_logic_vector(unsigned(addr) + 1);

				-- If we wrote the entire strip, render the data!
				if to_integer(unsigned(addr)) = length - 1 then
					done   <= '1';
					render <= '1';
				end if;

				if unsigned(colIdx) = colRot then
					data_red   <= (others => '1');
					data_green <= (others => '0');
					data_blue  <= (others => '0');
				elsif unsigned(colIdx) = colRot + 1 then
					data_red   <= (others => '0');
					data_green <= (others => '1');
					data_blue  <= (others => '0');
				elsif unsigned(colIdx) = colRot + 2 then
					data_red   <= (others => '0');
					data_green <= (others => '0');
					data_blue  <= (others => '1');
				else
					data_red   <= std_logic_vector(to_unsigned(127, 8));
					data_green <= std_logic_vector(to_unsigned(127, 8));
					data_blue  <= (others => '0');
				end if;

				if (btn_n = '0') then
					data_red   <= (others => '1');
					data_green <= (others => '1');
					data_blue  <= (others => '1');
				end if;
				we <= '1';
			else
				if c2 = 10000000 then
					done   <= '0';
					c2     := 0;
					colRot := colRot + 1;
				else
					c2 := c2 + 1;
				end if;
			end if;
		end if;
	end process prog;

end architecture RTL;
