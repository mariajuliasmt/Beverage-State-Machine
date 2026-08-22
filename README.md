# Beverage-State-Machine
Final assignment on Digital Logic Design 

This repo tracks the development of a Moore Finite State Machine using Verilog HDL on Quartus II, targeting the Cyclone II - EP2C35F672C6 FPGA.

This Beverage FSM has five states: S0, S1, S2, S3 and S4. Its state progression is S0 -> S1 -> S2 -> S3 -> S4 -> S0

S0: IDLE, machine has credit = 0, waiting for input

S1: SELECTION, customer presses a button linked to their beverage of preference, credit = 0

S2: CREDIT, machine has credit ≠ 0, yet credit < price

S3: RELEASE, machine has credit >= price, releases chosen beverage

S4: CHANGE, display screens change value (whether change = price - credit equals zero or not); if change ≠ 0, machine releases change


