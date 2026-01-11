# CS303 – FPGA Codebreaking Game (Tang Nano 9K)

## Overview
This project is a **Mastermind-style codebreaking game** implemented in **Verilog HDL**
as part of the **CS303 Digital Design** course.

The design was deployed on a **Tang Nano 9K FPGA board** using a
**university-produced daughter board** that provides switches, LEDs, and
seven-segment displays. The project focuses on **finite state machine (FSM)
design**, synchronous logic, and real hardware integration.

---

## Hardware Platform
- **FPGA Board:** Tang Nano 9K (Gowin GW1NR-9)
- **Expansion:** University-provided daughter board
- **Inputs:** Push buttons / switches
- **Outputs:** LEDs and seven-segment displays
- **Constraints:** Pin mappings defined via a provided `.cst` file

---

## Hardware Demonstration
![FPGA hardware demo](docs/hardware_demo.jpg)

The image above shows the project running on **real FPGA hardware**, with LEDs
and seven-segment displays active.

---

## Repository Structure

