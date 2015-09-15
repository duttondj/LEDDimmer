# LEDDimmer
This Verilog module will cycle through 16 different duty cycles for a set of LEDs using PWM. KEY0 raises the duty cycle, KEY1 lowers the duty cycle. KEY3 is an asynchronus reset. SW0 controls the test mode which scales the speed of cycling through duty cycles by a factor of 10. SW9 controls the Kitt mode which is not present in this current code.
