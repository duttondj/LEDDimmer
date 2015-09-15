`timescale 1ns/100ps
module TB_dimmer();
	reg clock_50;
	reg up_n;
	reg down_n;
	reg test;
	reg mode;
	reg clr_n;
	wire [9:0] leds;
	wire [3:0] stepcounter;
	wire [17:0] cyclecounter;

	dimmer U1(clock_50, clr_n, up_n, down_n, test, mode, leds, stepcounter, cyclecounter);

	initial begin
		clock_50 = 0;
		clr_n = 1;
		up_n = 1;
		down_n = 1;
		test = 0;
		mode = 0;
		#100 clr_n = 0;
		#50 clr_n = 1;
		#100 up_n = 0;
		#20 up_n = 1;
	end

	always begin
		#20 clock_50 = ~clock_50;
	end
endmodule