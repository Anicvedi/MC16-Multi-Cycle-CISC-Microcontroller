# MC16: 16-Bit Multi-Cycle CISC Microcontroller with Concurrent Instruction Prefetch

[![Verilog HDL](https://img.shields.io/badge/Language-Verilog_HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Target](https://img.shields.io/badge/FPGA-Xilinx_Basys_3_Artix--7-red.svg)](https://www.xilinx.com)
[![Architecture](https://img.shields.io/badge/Architecture-16--bit_Multi--Cycle_CISC-blue.svg)]()
[![Course](https://img.shields.io/badge/Course-E3_245_Processor_System_Design-purple.svg)](https://iisc.ac.in)

Author: **Anirudh Chaturvedi**  
M.Tech in Microelectronics & VLSI Design, Indian Institute of Science (IISc), Bangalore  
Department of Electronic Systems Engineering (DESE)

---

## 1. Architectural Highlights

MC16 is a custom 16-bit multi-cycle CISC microcontroller architected from RTL primitives for high-efficiency embedded control on the **Digilent Basys 3 (AMD Xilinx Artix-7 `XC7A35T`)**.

- **8 General Purpose Registers (GPRs):** `R0` through `R7`, plus Status Register flags ($C$ - Carry, $Z$ - Zero).
- **Single Shared Internal Data Bus:** Tri-state bus emulation utilizing centralized multiplexing.
- **Hierarchical 3-Level FSM Controller:** Separating Fetch, Decode, and multi-cycle Execute phases.
- **Instruction Prefetch Register (`IPR` $ightarrow$ `IR`):** Concurrently prefetching the next instruction word from memory during the final execute cycle of the current instruction, effectively hiding fetch latency.
- **Hardware Division Validation:** Verified 16-bit unsigned restoring division executing on Basys 3 hardware with 4-digit multiplexed 7-segment display readout.

Complete documentation available in [`docs/Guide_2_MC16_Multi_Cycle_Microcontroller.pdf`](docs/Guide_2_MC16_Multi_Cycle_Microcontroller.pdf).
