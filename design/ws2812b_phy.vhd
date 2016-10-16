-- ----------------------------------------------------------------------------
--                         WS2812B CONTROLLER FOR FPGAS                        
-- ----------------------------------------------------------------------------
-- ws2812b_phy.vhd : Low level driver for the WorldSemi WS2812B RGB LEDs.
--                   Handles bit timing and command separation.
-- ----------------------------------------------------------------------------
-- Author          : Markus Koch <markus@notsyncing.net>
-- Contributors    : None 
-- Created on      : 2016/10/16
-- License         : Mozilla Public License (MPL) Version 2
-- ----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ws2812b_phy is
	generic(
		f_clk : natural := 50000000;
		T0H   : real    := 0.00000035;
		T1H   : real    := 0.0000009;
		T0L   : real    := 0.0000009;
		T1L   : real    := 0.00000035;
		DEL   : real    := 0.0000000;   -- 0.0000001
		RES   : real    := 0.00005000   -- Must be bigger than others
	);
	port(
		-- Global Signals
		clk           : in  std_logic;  -- System clock @ f_clk
		rst           : in  std_logic;  -- Asynchronous reset
		-- Hardware Connection
		so            : out std_logic;  -- Serial output to WS2812B
		-- Data Link
		pixData_red   : in  std_logic_vector(7 downto 0);
		pixData_green : in  std_logic_vector(7 downto 0);
		pixData_blue  : in  std_logic_vector(7 downto 0);
		pixData_valid : in  std_logic;
		pixData_next  : out std_logic
	);
end entity ws2812b_phy;

architecture RTL of ws2812b_phy is
	-- WS2812B Bit Encoder Signals and Definitions
	constant CYC_T0H : natural := natural(T0H / (real(1) / real(f_clk))) - 1;
	constant CYC_T1H : natural := natural(T1H / (real(1) / real(f_clk))) - 1;
	constant CYC_T0L : natural := natural(T0L / (real(1) / real(f_clk))) - 1;
	constant CYC_T1L : natural := natural(T1L / (real(1) / real(f_clk))) - 1;
	constant CYC_DEL : natural := natural(DEL / (real(1) / real(f_clk))) - 1;
	constant CYC_RES : natural := natural(RES / (real(1) / real(f_clk))) - 1;

	type state_t is (HIGH, LOW);
	signal bitState : state_t;

	signal bitCnt        : integer range 0 to CYC_RES; -- Timing counter
	signal bitData_i     : std_logic;
	signal bitData       : std_logic_vector(1 downto 0); -- 00: send 0 <br> 01: send 1 <br> 10: send reset <br> 11: send led-separator 
	signal bitData_valid : std_logic;   -- Applied data is valid -> TX request (keep valid until data_next)
	signal bitData_next  : std_logic;   -- Apply next bit or release valid to terminate transmission

	-- Serializer Signals and Definitions
	signal shiftreg : std_logic_vector(23 downto 0);
	signal pixCnt   : integer range 0 to 25;
begin
	-- -----------------------
	-- WS2812B Bit Encoder
	-- -----------------------
	bitEncoder : process(rst, clk) is
	begin
		if rst = '1' then
			bitCnt       <= 0;
			bitState     <= LOW;
			bitData_next <= '0';
		elsif rising_edge(clk) then
			bitData_next <= '0';
			if bitCnt /= 0 then
				bitCnt <= bitCnt - 1;
			end if;
			case bitState is
				when HIGH =>
					if bitCnt = 0 then
						bitState <= LOW;
						if bitData_i = '0' then
							bitCnt <= CYC_T0L;
						else
							bitCnt <= CYC_T1L;
						end if;
					end if;
				when LOW =>
					if bitCnt = 0 then
						if bitData_valid = '1' then
							bitData_next <= '1';
							bitData_i    <= bitData(0);
							if bitData(0) = '0' then
								bitCnt <= CYC_T0H;
							else
								bitCnt <= CYC_T1H;
							end if;
							if bitData(1) = '0' then
								bitState <= HIGH;
							else
								if bitData(0) = '0' then
									bitCnt <= CYC_RES;
								else
									bitCnt <= CYC_DEL;
								end if;
								bitState <= LOW;
							end if;
						end if;
					end if;
			end case;
		end if;
	end process bitEncoder;

	so <= '1' when bitState = HIGH else '0';

	-- -----------------------
	-- Pixel Data Serializer
	-- -----------------------
	pixSerializer : process(rst, clk) is
	begin
		if rst = '1' then
			bitData_valid <= '0';
			pixData_next  <= '0';
			pixCnt        <= 0;
		elsif rising_edge(clk) then
			pixData_next <= '0';
			if bitData_next = '1' then
				pixCnt <= pixCnt - 1;
				if pixCnt = 2 then      -- End of data
					bitData(1) <= '1';  -- Control sequence
					if pixData_valid = '1' then
						shiftreg(23) <= '1'; -- Trigger DEL sequence
						report "WS2812B: Send DELAY" severity note;
					else
						shiftreg(23) <= '0'; -- Trigger RES sequence
						report "WS2812B: Send RESET" severity note;
						pixData_next <= '1'; -- Acknowledge that the reset has been latched
					end if;
				elsif pixCnt = 1 then   -- End of control
					bitData_valid <= '0';
				else
					shiftreg <= shiftreg(22 downto 0) & '0';
				end if;
			end if;
			if pixCnt = 0 then          -- End of DEL
				pixCnt <= pixCnt;
				if pixData_valid = '1' then
					report "WS2812B: Latch pixel data" severity note;
					pixData_next  <= '1';
					shiftreg      <= pixData_green & pixData_red & pixData_blue;
					bitData_valid <= '1';
					pixCnt        <= 25;
					bitData(1)    <= '0'; -- Data bit
				--						else
				--							bitData(1)   <= '1'; -- Control sequence
				--							shiftreg(23) <= '1'; -- Trigger RES sequence
				end if;
			end if;

		end if;
	end process pixSerializer;

	bitData(0) <= shiftreg(23);

end architecture RTL;
