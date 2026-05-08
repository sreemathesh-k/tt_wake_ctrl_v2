# wake_ctrl_v2

## What it does

This block solves a problem I kept reading about in IoT research papers - batteryless sensors waste energy because they have no good way to decide when to wake up the main processor. So I built one.

It watches 4 sensor threshold inputs continuously. When an input goes high, it has to stay high for 8 clock cycles before it counts as a real event (this removes noise and glitches). Once a valid event is confirmed, it tells you which channel fired and generates a clean pulse to wake a sleeping processor.

The AND/OR mode lets you choose whether all enabled channels need to fire together (AND) or just any one of them (OR). The priority encoder tells you which channel fired first when multiple channels activate at the same time.

## How to use it

Set `ui[3:0]` to your 4 sensor threshold inputs. Set `ui[7:4]` to enable the channels you want. Set `ui[4]` high for AND mode, low for OR mode.

After 8 clock cycles of stable input, `uo[0]` (wake_out) will pulse high for 16 cycles. `uo[4:1]` shows which channels fired. `uo[6:5]` gives the highest priority channel number (0 = highest).

To test: hold `ui[0]` high and all of `ui[7:4]` high for 10+ cycles with rst_n high. You should see `uo[0]` go high.

## Where I use this

Flood sensors, soil moisture monitors, structural vibration detectors - anywhere you have a sensor node that needs to sleep most of the time and only wake up when something real happens.

## Why I built this

I'm a 2nd year ECE student at SRM IST and I wanted to do a real ASIC tapeout. I used OpenROAD and Yosys to take this same design to GDS2 on SKY130 - zero DRC violations, zero timing violations. This TinyTapeout submission is the next step to getting actual silicon back.

## Author

Sreemathesh K — B.E. ECE 2nd Year, SRM Institute of Science and Technology, Kattankulathur, India — 2025
