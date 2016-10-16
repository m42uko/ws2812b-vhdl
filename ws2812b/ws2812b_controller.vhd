-- ----------------------------------------------------------------------------
--                         WS2812B CONTROLLER FOR FPGAS                        
-- ----------------------------------------------------------------------------
-- ws2812b_controller.vhd : WS2812B Controller to render picture data from
--                        : SRAM.
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

entity ws2812b_controller is
	generic(
		length : integer := 16;         -- Amount of LEDs on the link
		f_clk  : natural := 50000000;
		T0H    : real    := 0.00000035;
		T1H    : real    := 0.0000009;
		T0L    : real    := 0.0000009;
		T1L    : real    := 0.00000035;
		DEL    : real    := 0.0000001;  -- Must be bigger than others
		RES    : real    := 0.0000050
	);
	port(
		clk           : in  std_logic;
		rst           : in  std_logic;
		-- Hardware Connection
		so            : out std_logic;  -- Serial output to WS2812B
		-- Data Link
		addr          : in  std_logic_vector(integer(ceil(log2(real(length - 1)))) downto 0); -- Address of the LED
		data_red      : in  std_logic_vector(7 downto 0);
		data_green    : in  std_logic_vector(7 downto 0);
		data_blue     : in  std_logic_vector(7 downto 0);
		dataOut_red   : out std_logic_vector(7 downto 0);
		dataOut_green : out std_logic_vector(7 downto 0);
		dataOut_blue  : out std_logic_vector(7 downto 0);
		we            : in  std_logic;  -- Write to RAM
		render        : in  std_logic;  -- Send data to LEDs
		vsync         : out std_logic   -- Finished sending data out 
	);
end entity ws2812b_controller;

architecture RTL of ws2812b_controller is
	type memory_t is array (length - 1 downto 0) of std_logic_vector(23 downto 0);
	signal memory : memory_t;
	signal rdaddr : std_logic_vector(integer(ceil(log2(real(length - 1)))) downto 0);
	type state_t is (IDLE, PRESENT, WAITEMPTY);
	signal state         : state_t;
	signal pixData_red   : std_logic_vector(7 downto 0);
	signal pixData_green : std_logic_vector(7 downto 0);
	signal pixData_blue  : std_logic_vector(7 downto 0);
	signal pixData_valid : std_logic;
	signal pixData_next  : std_logic;
begin
	-- -----------------------
	-- Bit Timing Driver
	-- -----------------------
	ws2812b_phy_inst : entity work.ws2812b_phy
		generic map(
			f_clk => f_clk,
			T0H   => T0H,
			T1H   => T1H,
			T0L   => T0L,
			T1L   => T1L,
			DEL   => DEL,
			RES   => RES
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

	-- -----------------------
	-- Memory Interface
	-- -----------------------
	mem_writer : process(rst, clk) is
	begin
		if rst = '1' then
			dataOut_red   <= (others => '0');
			dataOut_green <= (others => '0');
			dataOut_blue  <= (others => '0');
		elsif rising_edge(clk) then
			dataOut_red   <= memory(to_integer(unsigned(addr)))(23 downto 16);
			dataOut_green <= memory(to_integer(unsigned(addr)))(15 downto 8);
			dataOut_blue  <= memory(to_integer(unsigned(addr)))(7 downto 0);
			if we = '1' then
				memory(to_integer(unsigned(addr))) <= data_red & data_green & data_blue;
			end if;
		end if;
	end process mem_writer;

	-- -----------------------
	-- Main Controller FSM
	-- -----------------------
	main : process(rst, clk) is
	begin
		if rst = '1' then
			rdaddr <= (others => '0');
			state  <= IDLE;
			vsync  <= '0';
		elsif rising_edge(clk) then
			vsync <= '0';
			case state is
				when IDLE =>
					rdaddr <= (others => '0');
					if render = '1' then
						report "SIZE=" & integer'image(integer(ceil(log2(real(length - 1)))));
						state <= PRESENT;
					end if;
				when PRESENT =>
					if pixData_next = '1' then
						if to_integer(unsigned(rdaddr)) = length - 1 then
							rdaddr <= (others => '0');
							state  <= WAITEMPTY;
							vsync  <= '1';
						else
							rdaddr <= std_logic_vector(unsigned(rdaddr) + 1);
						end if;
					end if;
				when WAITEMPTY =>
					rdaddr <= (others => '0');
					if pixData_next = '1' then
						state <= IDLE;
					end if;
			end case;
		end if;
	end process main;

	pixData_valid <= '1' when state = PRESENT else '0';

	pixData_red   <= memory(to_integer(unsigned(rdaddr)))(23 downto 16);
	pixData_green <= memory(to_integer(unsigned(rdaddr)))(15 downto 8);
	pixData_blue  <= memory(to_integer(unsigned(rdaddr)))(7 downto 0);

end architecture RTL;
