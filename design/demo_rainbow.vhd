-- ----------------------------------------------------------------------------
--                         WS2812B CONTROLLER FOR FPGAS                        
-- ----------------------------------------------------------------------------
-- top.vhd : Demo code to demonstrate the WS2812B Controller module.
--         : This uses only the PHY to create a rotating rainbow effect.
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

entity demo_rainbow is
	port(
		clk    : in  std_logic;
		rst_hw : in  std_logic;
		btn_n  : in  std_logic;
		so     : out std_logic
	);
end entity demo_rainbow;

architecture RTL of demo_rainbow is
	constant F_CLK     : integer := 50000000;
	constant F_SYSTICK : integer := 100
	-- pragma translate_off
	-- pragma synthesis_off
	* 10
--pragma translate_on
-- pragma synthesis_on
;
	constant LENGTH : integer := 120
	-- pragma translate_off
	-- pragma synthesis_off
	/ 10
--pragma translate_on
-- pragma synthesis_on
;
	constant INCREMENT   : integer := 10;
	constant PIXDATA_MAX : integer := 250; -- Must be a multiple of INCREMENT

	signal rst : std_logic;

	signal pixData_red         : unsigned(7 downto 0);
	signal pixData_green       : unsigned(7 downto 0);
	signal pixData_blue        : unsigned(7 downto 0);
	signal pixData_red_start   : unsigned(7 downto 0);
	signal pixData_green_start : unsigned(7 downto 0);
	signal pixData_blue_start  : unsigned(7 downto 0);
	signal pixData_valid       : std_logic;
	signal pixData_next        : std_logic;

	type color_transition_t is (RY, YG, GC, CB, BP, PR);
	signal color_transition_live  : color_transition_t;
	signal color_transition_start : color_transition_t;
	signal pixCount               : integer range 0 to LENGTH - 1;
	signal render_active          : std_logic;
	signal render_stb             : std_logic;

	signal systick : std_logic;
begin
	rst <= not rst_hw;

	ws2812b_phy_inst : entity work.ws2812b_phy
		generic map(
			f_clk => F_CLK
		)
		port map(
			clk           => clk,
			rst           => rst,
			so            => so,
			pixData_red   => std_logic_vector(pixData_red),
			pixData_green => std_logic_vector(pixData_green),
			pixData_blue  => std_logic_vector(pixData_blue),
			pixData_valid => pixData_valid,
			pixData_next  => pixData_next
		);

	systick_p : process(clk, rst) is
		constant cmax : integer := (F_CLK / F_SYSTICK);
		variable cnt  : integer range 0 to cmax;
	begin
		if rst = '1' then
			cnt     := 0;
			systick <= '0';
		elsif rising_edge(clk) then
			systick <= '0';
			if cnt = cmax then
				cnt     := 0;
				systick <= '1';
			else
				cnt := cnt + 1;
			end if;
		end if;
	end process systick_p;

	rainbow_p : process(clk, rst) is
		procedure incr(signal col : inout unsigned(7 downto 0); next_transition : in color_transition_t; is_live : boolean) is
		begin
			col <= col + INCREMENT;
			if col = PIXDATA_MAX - INCREMENT then
				if is_live then
					color_transition_live <= next_transition;
				else
					color_transition_start <= next_transition;
				end if;
			end if;
		end procedure;

		procedure decr(signal col : inout unsigned(7 downto 0); next_transition : in color_transition_t; is_live : boolean) is
		begin
			col <= col - INCREMENT;
			if col = INCREMENT then
				if is_live then
					color_transition_live <= next_transition;
				else
					color_transition_start <= next_transition;
				end if;
			end if;
		end procedure;
	begin
		if rst = '1' then
			pixData_red           <= to_unsigned(PIXDATA_MAX, pixData_red'length);
			pixData_green         <= (others => '0');
			pixData_blue          <= (others => '0');
			pixData_red_start     <= to_unsigned(PIXDATA_MAX, pixData_red'length);
			pixData_green_start   <= (others => '0');
			pixData_blue_start    <= (others => '0');
			--pixData_valid         <= '0';
			color_transition_live <= RY;
			pixCount              <= 0;
			render_active         <= '0';
		elsif rising_edge(clk) then
			-- Render one strip
			if render_active = '1' then
				if pixData_next = '1' then
					--pixData_valid <= '1';
					if pixCount = LENGTH - 1 then
						pixCount      <= 0;
						--pixData_valid <= '0'; -- Insert inter-strip delay
						render_active <= '0';
					else
						pixCount <= pixCount + 1;
						-- Rotate colors
						case color_transition_live is
							when RY =>
								incr(pixData_green, YG, true);
							when YG =>
								decr(pixData_red, GC, true);
							when GC =>
								incr(pixData_blue, CB, true);
							when CB =>
								decr(pixData_green, BP, true);
							when BP =>
								incr(pixData_red, PR, true);
							when PR =>
								decr(pixData_blue, RY, true);
						end case;
					end if;
				end if;
			end if;

			-- Advance image on trigger
			if systick = '1' then
				report "rainbow: render strobe" severity note;

				case color_transition_start is
					when RY =>
						incr(pixData_green_start, YG, false);
					when YG =>
						decr(pixData_red_start, GC, false);
					when GC =>
						incr(pixData_blue_start, CB, false);
					when CB =>
						decr(pixData_green_start, BP, false);
					when BP =>
						incr(pixData_red_start, PR, false);
					when PR =>
						decr(pixData_blue_start, RY, false);
				end case;

				render_active <= '1';
				if render_active = '0' then
					pixData_red           <= pixData_red_start;
					pixData_green         <= pixData_green_start;
					pixData_blue          <= pixData_blue_start;
					color_transition_live <= color_transition_start;
				end if;
			end if;
		end if;
	end process rainbow_p;
	pixData_valid <= render_active;
end architecture RTL;
