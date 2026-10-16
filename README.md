# UART Transmitter and Receiver Using Verilog

## Project overview
This project implements a UART (Universal Asynchronous Receiver/Transmitter) transmitter and receiver in Verilog HDL. The transmitter output is connected directly to the receiver input for loopback verification.

## Features
- 8-bit UART data
- 8N1 frame format: 8 data bits, no parity, 1 stop bit
- Least-significant-bit-first transmission
- Parameterized clock cycles per bit (`CPB`)
- Two-flop synchronizer on the receiver input
- Self-checking loopback testbench
- Four directed test cases and 50 pseudorandom test cases

## Tools
- Verilog HDL
- EDA Playground
- Icarus Verilog
- EPWave

## Verification results
The EDA Playground simulation log reported:
- Total tests: 54
- Passed: 54
- Failed: 0

These results apply to the provided loopback testbench and simulation setup. They do not establish behavior under every baud-rate mismatch, framing error, or hardware condition.

## Files
- `design.sv` — UART transmitter and receiver RTL modules
- `testbench.sv` — self-checking loopback testbench
- `results/simulation_results.png` — simulation log evidence (if included)
- `results/uart_waveform.png` — waveform evidence (if included)

## Run the simulation
In EDA Playground, choose Icarus Verilog, put `testbench.sv` in the testbench editor and `design.sv` in the design editor, then click Run. The testbench writes a VCD file named `dump.vcd`.

## Future improvements
- Add framing-error reporting and recovery tests
- Test different `CPB` values and timing mismatches
- Add more directed and randomized tests with reproducible seeds
- Add configurable parity and data width
