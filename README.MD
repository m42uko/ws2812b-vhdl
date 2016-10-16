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

*Documentation coming soon*

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