//==================================================================================================
//  Filename      : dimmer.v
//  Created On    : 2015-09-08 23:27:20
//  Last Modified : 2015-09-08 23:41:34
//  Revision      : 1
//  Author        : Danny Dutton
//  Class         : ECE4514
//
//  Description   : This Verilog module will cycle through 16 different duty cycles for a set of
//					LEDs using PWM. KEY0 raises the duty cycle, KEY1 lowers the duty cycle. KEY3 is
//					an asynchronus reset. SW0 controls the test mode which scales the speed of
//					cycling through duty cycles by a factor of 10. SW9 controls the Kitt mode which
//					is not present in this current code.
//					
//					Refresh period = 200 Hz = .005 s
// 					Wave Period = .005 s * 50 MHz = 250000
// 					Step Count = 16
// 					Step Delay = 250000/16 = 15625
// 					log2(Wave Period) = log2(250000) = 18 bits
//
// 					So we will refresh the LEDs every 200 Hz (.005 sec). This refresh period will be controlled by a counter going from 0 to 2^(18)-1.
// 					The counter will be compared to the StepDelay*StepCount.
// 					DutyCycle = StepDelay*StepCount/CycleCount
//
//==================================================================================================

module dimmer(clock_50, clr_n, up_n, down_n, test, mode, leds);

	input clock_50;			// 50 MHz clock on board
	input clr_n;			// System reset, active low, KEY[3]
	input up_n;				// KEY0, raises duty cycle
	input down_n;			// KEY1, lowers duty cycle
	input test;				// SW0, scales time factors
	input mode;				// SW9, controls Kitt mode
	output [9:0] leds;		// 10 LEDs

	reg [3:0] scale;				// Time scale value, either 1 or 10
	reg buttonpressed;				// Current state of either KEY0 or 1 being pressed
	reg nextbuttonpressed;			// Next state of either KEY0 or 1 being pressed
	reg [4:0] stepcounter;			// Step of LED brightness, 0-15
	reg [4:0] nextstepcounter;		// Next step of LED brightness, 0-15
	reg [17:0] cyclecounter;		// LED refresh rate cycle counter, 0-249999
	reg [25:0] upbuttoncounter;		// Timer tracking hold time of up button, 0-49999999
	reg [25:0] downbuttoncounter;	// Timer tracking hold time of down button, 0-49999999

	// Logic for next button state, set 1 when buttons pressed
	always @(negedge up_n or negedge down_n) begin		
		// Reset button counters and turn flag on to denote a button is being pushed
		if (up_n == 0) begin
			nextbuttonpressed <= 1;
		end
		else if (down_n == 0) begin
			nextbuttonpressed <= 1;
		end
		// No more buttons are being pushed so reset the flag state
		else begin
			nextbuttonpressed <= 0;
		end
	end
	
	// Logic for next step count state
	always @(upbuttoncounter or downbuttoncounter) begin
		// Up button is being pushed so turn up the brightness
		if (!up_n && (upbuttoncounter == 0) && buttonpressed) begin
			nextstepcounter <= (stepcounter < 4'd15) ? stepcounter + 4'b1 : stepcounter;
		end
		// Down button is being pushed so turn down the brightness
		else if (!down_n && (downbuttoncounter == 0) && buttonpressed) begin
			nextstepcounter <= (stepcounter > 0) ? stepcounter - 4'b1 : stepcounter;
		end
		// Nothing is being pushed anymore so keep state
		else begin
			nextstepcounter <= stepcounter;
		end
	end

	// Logic for next counter state
	always @(posedge clock_50 or negedge clr_n) begin
		
		// Reset count values
		if (clr_n == 0) begin
			cyclecounter <= 0;
			stepcounter <= 0;
			buttonpressed <= 0;
			upbuttoncounter <= 0;
			downbuttoncounter <= 0;	
		end
		else begin
			// Set state to the next state
			scale = test ? 4'b1010 : 1'b1;
			stepcounter <= nextstepcounter;
			buttonpressed <= nextbuttonpressed;

			// Increment cycle count always
			cyclecounter <= cyclecounter + 13'b1;
			// Cycle counter next state
			if (cyclecounter >= (250000/scale)) begin
				cyclecounter <= 0;
			end
						
			// Set up button counter next state
			if (upbuttoncounter >= (50000000/scale) || (up_n == 1)) begin
				upbuttoncounter <= 0;
			end
			else begin
				upbuttoncounter <= upbuttoncounter + 18'b1;
			end
			
			// Set down button counter next state
			if (downbuttoncounter >= (50000000/scale) || (down_n == 1)) begin
				downbuttoncounter <= 0;
			end
			else begin
				downbuttoncounter <= downbuttoncounter + 18'b1;
			end
		end
	end

// Turn on LEDs if cycle count is within the duty cycle
assign leds = (cyclecounter < stepcounter*(15625/scale)) ? 10'b1111111111 : 10'b0;

endmodule