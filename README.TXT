# ===========================================================================
# Computer Architecture & VLSI Systems Laborartory (CARV)
# Institute of Computer Science (ICS)
# Foundation for Research & Technology - Hellas (FORTH)
# 
# Release of 512-core hardware prototype, July 2012
# 
# Copyright (c) 2010-2012
# Licensed under the TAPR Open Hardware License (www.tapr.org/NCL)
# ===========================================================================

The hdl/ directory structure is organized as follows:

hdl/top/
========
Contains the top-level Formic designs. Three variants are included:

hdl/top/formic_m8g8.v:  the full design (8 MBS blocks, 8 GTP ports)
hdl/top/formic_m8.v:    reduced design, with only the 8 MBS blocks
hdl/top/formic_m1.v:    even more reduced design, just a single MBS


htl/rtl/mbs
===========
The MicroBlaze Slice (MBS) design. The top-level module is hdl/rtl/mbs/mbs.v.


hdl/rtl/noc
===========
Network-on-chip modules. We include three variants of the crossbar:

hdl/rtl/noc/xbar_formic_m8g8.v: 22-port crossbar, for the formic_m8g8 design
hdl/rtl/noc/xbar_formic_m8.v:   reduced 14-port crossbar (formic_m8 design)
hdl/rtl/noc/xbar_formic_m1.v:   reduced 7-port crossbar (formic_m1 design)

The crossbar interface block (XBI) is in hdl/rtl/noc/xbi.v (16-bit version)
and hdl/rtl/noc/xbi32.v (32-bit version).


hdl/rtl/comm
============
Communication modules. The GTP modules are organized in two groups of 4xGTP
each. The top-level for these GTP groups is hdl/rtl/comm/gtp_quad.v. The 
top-level for the UART controller is hdl/rtl/comm/uart.v and the I2C slave
is in hdl/rtl/comm/i2c_slave.v.


hdl/rtl/mem
===========
Memory-related modules. The TLB top-level is hdl/rtl/mem/tlb.v. The SRAM
controller top-level is hdl/rtl/mem/sram_ctl.v. We also include here the 
boot manager (hdl/rtl/mem/boot.v) and the boot ROM (hdl/rtl/mem/boot_mem.v).


hdl/rtl/board_ctl
=================
The Formic board controller block. The top-level is 
hdl/rtl/board_ctl/formic_bctl.v.


hdl/rtl/clk
===========
Clock manager and reset manager for the Formic board. The two top-levels are
hdl/rtl/clk/clk_mgr_formic.v and hdl/rtl/clk/rst_mgr_formic.v.


htl/rtl/misc
============
Collection of miscellaneous, small, helper modules, such as FIFOs, clock
domain crossing blocks, pseudo-random number generators, encoders/decoders,
etc.


hdl/xilinx
==========
Xilinx IP wrappers and synthesizable memories. The DRAM controller wrapper
is in hdl/xilinx/xil_ddr_ctl.vhd. The MicroBlaze wrapper is in
hdl/xilinx/xil_microblaze.vhd.


Usage of Xilinx IP blocks
=========================
Most of the code is plain Verilog RTL. In some cases, we use Xilinx-specific
primitives (e.g. IOBUF in hdl/rtl/mem/zbt_ctl.v) or full IP cores, such as:

- MicroBlaze RISC core    in hdl/xilinx/xil_microblaze.vhd
- DDR2 SDRAM controller   in hdl/xilinx/xil_ddr_ctl.vhd
- GTPA1_DUAL hard macro   in hdl/rtl/comm/rio_gtps6.vhd
- XPS UART Lite core      in hdl/rtl/comm/uart.v
- MicroBlaze Debug module in hdl/xilinx/xil_mdm.vhd

We do not include any Xilinx IP code in this distribution. You may obtain
a valid Xilinx IP codebase through the Xilinx website (www.xilinx.com).
The version we have used for the Formic design is EDK 12.4.

For more information, please contact us at ligeraki@ics.forth.gr
