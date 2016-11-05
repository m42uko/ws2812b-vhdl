# WS2812B CONTROLLER FOR FPGAS
A controller for the WorldSemi WS2812B RGB LEDs written in plain VHDL.

## Directory structure
* ws2812b: Contains the actual library.
* demo: Contains demo designs to visualize the functionality of the design.
* bench: Contains various test benches used during the development of the library.
* gtkwave: Contains GtkWave layouts for some test benches.

For directories containing VHDL source files, the directory name denotes the VHDL library.

## Entity description
### ws2812b_phy
Low level driver for the WorldSemi WS2812B RGB LEDs. Handles bit timing and command separation. 

<pre>
                                        +    +
                                        |    |
                                        |    |
+-----------+    +----------------------v----v------+
|           +----> pixData_red[7:0]    clk  rst     |
|           |    |                                  |
|           +----> pixData_green[7:0]               |
|           |    |                                  |    +----+
|   User    +----> pixData_blue[7:0]             so +---->LEDs|
|   Logic   |    |                                  |    +----+
|           |    |                                  |
|           +----> pixData_valid                    |
|           |    |                                  |
|           <----+ pixData_next                     |
+-----------+    +----------------------------------+

        _   _   _   _   _   _         _   _   _   _         _   _   _   _
clk   _/ \_/ \_/ \_/ \_/ \_/ \_   / /  \_/ \_/ \_/ \_   / /  \_/ \_/ \_/ \_
                _______ _______  / /  _______          / /
data  ---------<_______X_______ |  |  _______>------- | |   ----------------
                _______________ \  \  _______          \ \
valid _________/                 \  \        \_______   \ \ ________________
                    ___          |  |     ___           | |      ___
next  _____________/   \_______  /  / ___/   \_______   / / ____/   \_______
                                /  /                   / /
               1   2   3                 4   5                  6

1: User applies first LED's data and asserts pixData_valid.
2: PHY acknowledges that it latched the data and starts supplying the
   information to the LED string.
3: User logic sees the pixData_next strobe and prepares the next data.
4: Next data is latched. Steps 3 and 4 are to be repeated until each LED in
   the string has been given a value.
5: User logic sees the pixData_next strobe. As all LEDs have already been
   given a value, pixData_valid is deasserted to signal the end of a string.
6: The completion of the reset time is signalled using another
   pixData_next strobe.
</pre>

For an example, see Rainbow.

### ws2812b_controller
WS2812B Controller to render picture data from SRAM.

*Documentation coming soon*

For an example, see demo_sram.

## Demos
### Rainbow
Displays a simple moving rainbow pattern over a strip of fixed length.

Make sure the `F_CLK` is set to the actual frequency present on the hardware for `clk`.

To set the length, change the `LENGTH` constant. To change the speed of the animation, change the `F_SYSTICK` constant. To change the length of one iteration of the rainbow, set the `INCREMENT` constant. To change the maximum brightness, change the `PIXDATA_MAX` constant while making sure that it is a multiple of `INCREMENT`.

### demo_sram
Steps through some predefined colors by writing the to the controller's RAM and simply issuing a *render* strobe.

Make sure the `F_CLK` is set to the actual frequency present on the hardware for `clk`.

## License
This work is released under the Mozilla Public License (MPL) Version 2. It may be interpreted in the same way the Open Hardware Description License (OHDL) by Julius Baxter does. Read more about it here: http://juliusbaxter.net/ohdl/ohdl.txt

Authors: Markus Koch <markus@notsyncing.net>
