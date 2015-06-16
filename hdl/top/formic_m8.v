// ===========================================================================
//
//                              FORTH-ICS / CARV
//
//      Licensed under the TAPR Open Hardware License (www.tapr.org/NCL)
//                           Copyright (c) 2010-2012
//
//
// ==========================[ Static Information ]===========================
//
// Author        : Spyros Lyberis
// Abstract      : Formic board top-level (8xMBS, no GTP version)
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: formic_m8.v,v $
// CVS revision  : $Revision: 1.18 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns / 1ps

// synthesis translate_off
`define SYNTH_NEED_TRACING 1
`define SYNTH_NEED_DEBUG 1
// synthesis translate_on

module formic_m8 # (

  // Parameters
  parameter tb_mode = "FALSE"

)  (
  
  // DDR2 DRAM (top right)
  output [14:0] ddr_a,          
  output  [2:0] ddr_ba,         
  output        ddr_ras_n,      
  output        ddr_cas_n,      
  output        ddr_we_n,       
  output        ddr_clke,       
  output        ddr_clk,        
  output        ddr_clk_n,      
  inout  [15:0] ddr_dq,         
  inout         ddr_ldqs,       
  inout         ddr_ldqs_n,     
  inout         ddr_udqs,       
  inout         ddr_udqs_n,     
  output        ddr_udm,        
  output        ddr_ldm,        
  output        ddr_odt,        
  inout         ddr_rzq,        
  inout         ddr_zio,        
  output        ddr_cs_n,
  
  // SRAM 0 (bottom right)
  inout  [31:0] sram0_dq,       
  inout   [3:0] sram0_dqp,      
  output [17:0] sram0_a,        
  output        sram0_adv,      
  output  [3:0] sram0_bw_n,     
  output        sram0_we_n,     
  output        sram0_clke_n,   
  output        sram0_cs_n,     
  output        sram0_clk,      
  input         sram0_clk_fb,   

  // SRAM 1 (bottom left)
  inout  [31:0] sram1_dq,       
  inout   [3:0] sram1_dqp,      
  output [17:0] sram1_a,        
  output        sram1_adv,      
  output  [3:0] sram1_bw_n,     
  output        sram1_we_n,     
  output        sram1_clke_n,   
  output        sram1_cs_n,     
  output        sram1_clk,      
  input         sram1_clk_fb,   

  // SRAM 2 (top left)
  inout  [31:0] sram2_dq,       
  inout   [3:0] sram2_dqp,      
  output [17:0] sram2_a,        
  output        sram2_adv,      
  output  [3:0] sram2_bw_n,     
  output        sram2_we_n,     
  output        sram2_clke_n,   
  output        sram2_cs_n,     
  output        sram2_clk,      
  input         sram2_clk_fb,   

  // GTP links (all unused)
  input         sata0_rx_n,
  input         sata0_rx_p,
  output        sata0_tx_n,
  output        sata0_tx_p,
  input         sata1_rx_n,
  input         sata1_rx_p,
  output        sata1_tx_n,
  output        sata1_tx_p,
  input         sata2_rx_n,
  input         sata2_rx_p,
  output        sata2_tx_n,
  output        sata2_tx_p,
  input         sata3_rx_n,
  input         sata3_rx_p,
  output        sata3_tx_n,
  output        sata3_tx_p,
  input         sata4_rx_n,
  input         sata4_rx_p,
  output        sata4_tx_n,
  output        sata4_tx_p,
  input         sata5_rx_n,
  input         sata5_rx_p,
  output        sata5_tx_n,
  output        sata5_tx_p,
  input         sata6_rx_n,
  input         sata6_rx_p,
  output        sata6_tx_n,
  output        sata6_tx_p,
  input         sata7_rx_n,
  input         sata7_rx_p,
  output        sata7_tx_n,
  output        sata7_tx_p,

  // UART
  input         uart_rx,        
  output        uart_tx,        

  // I2C slave
  input         i2c_scl,        
  inout         i2c_sda,        
  
  // Dip switches
  input [11:0]  dip_sw,     

  // LEDs
  output [11:0] led,        
  
  // Reference clocks
  input         ref_clk_p,          // 200 MHz for logic
  input         ref_clk_n,                                               
  input         aref_clk0_p,        // 150 MHz for top-side GTP links
  input         aref_clk0_n,                                             
  input         aref_clk1_p,        // 150 MHz for bottom-side GTP links
  input         aref_clk1_n,
  
  // Reset button
  input         rst_n
);

  
  // ==========================================================================
  // Wires
  // ==========================================================================
  reg   [7:0] board_id_q;

  wire        bctl_tlb_enabled;
  wire        bctl_tlb_maint_cmd;
  wire        bctl_tlb_maint_wr_en;
  wire [11:0] bctl_tlb_virt_adr;
  wire  [6:0] bctl_tlb_phys_adr;
  wire        bctl_tlb_entry_valid;
  wire  [6:0] bctl_tlb_resp_phys_adr;
  wire        bctl_tlb_resp_entry_valid;
  wire  [4:0] bctl_tlb_drop;
  
  wire        bctl_uart_enq;
  wire  [7:0] bctl_uart_enq_data;
  wire [10:0] bctl_uart_tx_words;
  wire        bctl_uart_tx_full;
  wire        bctl_uart_deq;
  wire  [7:0] bctl_uart_deq_data;
  wire [10:0] bctl_uart_rx_words;
  wire        bctl_uart_rx_empty;
  wire        bctl_uart_byte_rcv;

  wire        bctl_i2c_miss_valid;
  wire [ 7:0] bctl_i2c_miss_adr;
  wire [ 1:0] bctl_i2c_miss_flags;
  wire        bctl_i2c_miss_wen;
  wire [ 3:0] bctl_i2c_miss_ben;
  wire [31:0] bctl_i2c_miss_wdata;
  wire        bctl_l2c_miss_stall;
  wire        bctl_i2c_fill_valid;
  wire [31:0] bctl_i2c_fill_data;
  wire        bctl_i2c_fill_stall;

  wire        bctl_boot_req;
  wire        bctl_boot_done;
  wire        bctl_rst_soft;
  wire        bctl_rst_hard;

  wire [17:0] mbs0_sram1_req_adr;
  wire        mbs0_sram1_req_we;
  wire [31:0] mbs0_sram1_req_wdata;
  wire [ 3:0] mbs0_sram1_req_be;
  wire        mbs0_sram1_req_valid;
  wire [31:0] mbs0_sram1_resp_rdata;
  wire        mbs0_sram1_resp_valid;

  wire [17:0] mbs1_sram1_req_adr;
  wire        mbs1_sram1_req_we;
  wire [31:0] mbs1_sram1_req_wdata;
  wire [ 3:0] mbs1_sram1_req_be;
  wire        mbs1_sram1_req_valid;
  wire [31:0] mbs1_sram1_resp_rdata;
  wire        mbs1_sram1_resp_valid;

  wire [17:0] mbs2_sram2_req_adr;
  wire        mbs2_sram2_req_we;
  wire [31:0] mbs2_sram2_req_wdata;
  wire [ 3:0] mbs2_sram2_req_be;
  wire        mbs2_sram2_req_valid;
  wire [31:0] mbs2_sram2_resp_rdata;
  wire        mbs2_sram2_resp_valid;

  wire [17:0] mbs3_sram2_req_adr;
  wire        mbs3_sram2_req_we;
  wire [31:0] mbs3_sram2_req_wdata;
  wire [ 3:0] mbs3_sram2_req_be;
  wire        mbs3_sram2_req_valid;
  wire [31:0] mbs3_sram2_resp_rdata;
  wire        mbs3_sram2_resp_valid;

  wire [17:0] mbs4_sram1_req_adr;
  wire        mbs4_sram1_req_we;
  wire [31:0] mbs4_sram1_req_wdata;
  wire [ 3:0] mbs4_sram1_req_be;
  wire        mbs4_sram1_req_valid;
  wire [31:0] mbs4_sram1_resp_rdata;
  wire        mbs4_sram1_resp_valid;

  wire [17:0] mbs5_sram1_req_adr;
  wire        mbs5_sram1_req_we;
  wire [31:0] mbs5_sram1_req_wdata;
  wire [ 3:0] mbs5_sram1_req_be;
  wire        mbs5_sram1_req_valid;
  wire [31:0] mbs5_sram1_resp_rdata;
  wire        mbs5_sram1_resp_valid;

  wire [17:0] mbs6_sram2_req_adr;
  wire        mbs6_sram2_req_we;
  wire [31:0] mbs6_sram2_req_wdata;
  wire [ 3:0] mbs6_sram2_req_be;
  wire        mbs6_sram2_req_valid;
  wire [31:0] mbs6_sram2_resp_rdata;
  wire        mbs6_sram2_resp_valid;

  wire [17:0] mbs7_sram2_req_adr;
  wire        mbs7_sram2_req_we;
  wire [31:0] mbs7_sram2_req_wdata;
  wire [ 3:0] mbs7_sram2_req_be;
  wire        mbs7_sram2_req_valid;
  wire [31:0] mbs7_sram2_resp_rdata;
  wire        mbs7_sram2_resp_valid;

  wire        bctl_tmr_drift_fw;
  wire        bctl_tmr_drift_bw;
  wire  [7:0] bctl_uart_irq;
  wire  [7:0] bctl_uart_irq_clear;

  wire  [3:0] mbs0_bctl_load_status;
  wire        mbs0_bctl_trc_valid;
  wire  [7:0] mbs0_bctl_trc_data;

  wire  [3:0] mbs1_bctl_load_status;
  wire        mbs1_bctl_trc_valid;
  wire  [7:0] mbs1_bctl_trc_data;

  wire  [3:0] mbs2_bctl_load_status;
  wire        mbs2_bctl_trc_valid;
  wire  [7:0] mbs2_bctl_trc_data;

  wire  [3:0] mbs3_bctl_load_status;
  wire        mbs3_bctl_trc_valid;
  wire  [7:0] mbs3_bctl_trc_data;

  wire  [3:0] mbs4_bctl_load_status;
  wire        mbs4_bctl_trc_valid;
  wire  [7:0] mbs4_bctl_trc_data;

  wire  [3:0] mbs5_bctl_load_status;
  wire        mbs5_bctl_trc_valid;
  wire  [7:0] mbs5_bctl_trc_data;

  wire  [3:0] mbs6_bctl_load_status;
  wire        mbs6_bctl_trc_valid;
  wire  [7:0] mbs6_bctl_trc_data;

  wire  [3:0] mbs7_bctl_load_status;
  wire        mbs7_bctl_trc_valid;
  wire  [7:0] mbs7_bctl_trc_data;

  wire  [2:0] xbar00_out_enq;
  wire  [5:0] xbar00_out_offset;
  wire        xbar00_out_eop;
  wire [15:0] xbar00_out_data;
  wire  [2:0] xbar00_out_full;
  wire  [2:0] xbar00_out_packets_vc0;
  wire  [2:0] xbar00_out_packets_vc1;
  wire  [2:0] xbar00_out_packets_vc2;
  wire  [2:0] xbar00_in_deq;
  wire  [5:0] xbar00_in_offset;
  wire        xbar00_in_eop;
  wire [15:0] xbar00_in_data;
  wire  [2:0] xbar00_in_empty;

  wire  [2:0] xbar01_out_enq;
  wire  [5:0] xbar01_out_offset;
  wire        xbar01_out_eop;
  wire [15:0] xbar01_out_data;
  wire  [2:0] xbar01_out_full;
  wire  [2:0] xbar01_out_packets_vc0;
  wire  [2:0] xbar01_out_packets_vc1;
  wire  [2:0] xbar01_out_packets_vc2;
  wire  [2:0] xbar01_in_deq;
  wire  [5:0] xbar01_in_offset;
  wire        xbar01_in_eop;
  wire [15:0] xbar01_in_data;
  wire  [2:0] xbar01_in_empty;

  wire  [2:0] xbar02_out_enq;
  wire  [5:0] xbar02_out_offset;
  wire        xbar02_out_eop;
  wire [15:0] xbar02_out_data;
  wire  [2:0] xbar02_out_full;
  wire  [2:0] xbar02_out_packets_vc0;
  wire  [2:0] xbar02_out_packets_vc1;
  wire  [2:0] xbar02_out_packets_vc2;
  wire  [2:0] xbar02_in_deq;
  wire  [5:0] xbar02_in_offset;
  wire        xbar02_in_eop;
  wire [15:0] xbar02_in_data;
  wire  [2:0] xbar02_in_empty;

  wire  [2:0] xbar03_out_enq;
  wire  [5:0] xbar03_out_offset;
  wire        xbar03_out_eop;
  wire [15:0] xbar03_out_data;
  wire  [2:0] xbar03_out_full;
  wire  [2:0] xbar03_out_packets_vc0;
  wire  [2:0] xbar03_out_packets_vc1;
  wire  [2:0] xbar03_out_packets_vc2;
  wire  [2:0] xbar03_in_deq;
  wire  [5:0] xbar03_in_offset;
  wire        xbar03_in_eop;
  wire [15:0] xbar03_in_data;
  wire  [2:0] xbar03_in_empty;

  wire  [2:0] xbar04_out_enq;
  wire  [5:0] xbar04_out_offset;
  wire        xbar04_out_eop;
  wire [15:0] xbar04_out_data;
  wire  [2:0] xbar04_out_full;
  wire  [2:0] xbar04_out_packets_vc0;
  wire  [2:0] xbar04_out_packets_vc1;
  wire  [2:0] xbar04_out_packets_vc2;
  wire  [2:0] xbar04_in_deq;
  wire  [5:0] xbar04_in_offset;
  wire        xbar04_in_eop;
  wire [15:0] xbar04_in_data;
  wire  [2:0] xbar04_in_empty;

  wire  [2:0] xbar05_out_enq;
  wire  [5:0] xbar05_out_offset;
  wire        xbar05_out_eop;
  wire [15:0] xbar05_out_data;
  wire  [2:0] xbar05_out_full;
  wire  [2:0] xbar05_out_packets_vc0;
  wire  [2:0] xbar05_out_packets_vc1;
  wire  [2:0] xbar05_out_packets_vc2;
  wire  [2:0] xbar05_in_deq;
  wire  [5:0] xbar05_in_offset;
  wire        xbar05_in_eop;
  wire [15:0] xbar05_in_data;
  wire  [2:0] xbar05_in_empty;

  wire  [2:0] xbar06_out_enq;
  wire  [5:0] xbar06_out_offset;
  wire        xbar06_out_eop;
  wire [15:0] xbar06_out_data;
  wire  [2:0] xbar06_out_full;
  wire  [2:0] xbar06_out_packets_vc0;
  wire  [2:0] xbar06_out_packets_vc1;
  wire  [2:0] xbar06_out_packets_vc2;
  wire  [2:0] xbar06_in_deq;
  wire  [5:0] xbar06_in_offset;
  wire        xbar06_in_eop;
  wire [15:0] xbar06_in_data;
  wire  [2:0] xbar06_in_empty;

  wire  [2:0] xbar07_out_enq;
  wire  [5:0] xbar07_out_offset;
  wire        xbar07_out_eop;
  wire [15:0] xbar07_out_data;
  wire  [2:0] xbar07_out_full;
  wire  [2:0] xbar07_out_packets_vc0;
  wire  [2:0] xbar07_out_packets_vc1;
  wire  [2:0] xbar07_out_packets_vc2;
  wire  [2:0] xbar07_in_deq;
  wire  [5:0] xbar07_in_offset;
  wire        xbar07_in_eop;
  wire [15:0] xbar07_in_data;
  wire  [2:0] xbar07_in_empty;

  wire  [2:0] xbar16_out_enq;
  wire  [5:0] xbar16_out_offset;
  wire        xbar16_out_eop;
  wire [15:0] xbar16_out_data;
  wire  [2:0] xbar16_out_full;
  wire  [2:0] xbar16_out_packets_vc0;
  wire  [2:0] xbar16_out_packets_vc1;
  wire  [2:0] xbar16_out_packets_vc2;
  wire  [2:0] xbar16_in_deq;
  wire  [5:0] xbar16_in_offset;
  wire        xbar16_in_eop;
  wire [15:0] xbar16_in_data;
  wire  [2:0] xbar16_in_empty;

  wire  [2:0] xbar17_out_enq;
  wire  [5:0] xbar17_out_offset;
  wire        xbar17_out_eop;
  wire [15:0] xbar17_out_data;
  wire  [2:0] xbar17_out_full;
  wire  [2:0] xbar17_out_packets_vc0;
  wire  [2:0] xbar17_out_packets_vc1;
  wire  [2:0] xbar17_out_packets_vc2;
  wire  [2:0] xbar17_in_deq;
  wire  [5:0] xbar17_in_offset;
  wire        xbar17_in_eop;
  wire [15:0] xbar17_in_data;
  wire  [2:0] xbar17_in_empty;

  wire  [2:0] xbar18_out_enq;
  wire  [5:0] xbar18_out_offset;
  wire        xbar18_out_eop;
  wire [15:0] xbar18_out_data;
  wire  [2:0] xbar18_out_full;
  wire  [2:0] xbar18_out_packets_vc0;
  wire  [2:0] xbar18_out_packets_vc1;
  wire  [2:0] xbar18_out_packets_vc2;
  wire  [2:0] xbar18_in_deq;
  wire  [5:0] xbar18_in_offset;
  wire        xbar18_in_eop;
  wire [15:0] xbar18_in_data;
  wire  [2:0] xbar18_in_empty;

  wire  [2:0] xbar19_out_enq;
  wire  [5:0] xbar19_out_offset;
  wire        xbar19_out_eop;
  wire [15:0] xbar19_out_data;
  wire  [2:0] xbar19_out_full;
  wire  [2:0] xbar19_out_packets_vc0;
  wire  [2:0] xbar19_out_packets_vc1;
  wire  [2:0] xbar19_out_packets_vc2;
  wire  [2:0] xbar19_in_deq;
  wire  [5:0] xbar19_in_offset;
  wire        xbar19_in_eop;
  wire [15:0] xbar19_in_data;
  wire  [2:0] xbar19_in_empty;

  wire  [2:0] xbar20_out_enq;
  wire  [5:0] xbar20_out_offset;
  wire        xbar20_out_eop;
  wire [15:0] xbar20_out_data;
  wire  [2:0] xbar20_out_full;
  wire  [2:0] xbar20_out_packets_vc0;
  wire  [2:0] xbar20_out_packets_vc1;
  wire  [2:0] xbar20_out_packets_vc2;
  wire  [2:0] xbar20_in_deq;
  wire  [5:0] xbar20_in_offset;
  wire        xbar20_in_eop;
  wire [15:0] xbar20_in_data;
  wire  [2:0] xbar20_in_empty;

  wire  [2:0] xbar21_out_enq;
  wire  [5:0] xbar21_out_offset;
  wire        xbar21_out_eop;
  wire [15:0] xbar21_out_data;
  wire  [2:0] xbar21_out_full;
  wire  [2:0] xbar21_out_packets_vc0;
  wire  [2:0] xbar21_out_packets_vc1;
  wire  [2:0] xbar21_out_packets_vc2;
  wire  [2:0] xbar21_in_deq;
  wire  [5:0] xbar21_in_offset;
  wire        xbar21_in_eop;
  wire [15:0] xbar21_in_data;
  wire  [2:0] xbar21_in_empty;

  wire        mdm_brk;
  wire        mdm_nm_brk;
  wire        mdm_sys_reset;

  wire        mdm0_clk;
  wire        mdm0_tdi;
  wire        mdm0_tdo;
  wire  [7:0] mdm0_reg_en;
  wire        mdm0_shift;
  wire        mdm0_capture;
  wire        mdm0_update;
  wire        mdm0_reset;

  wire        mdm1_clk;
  wire        mdm1_tdi;
  wire        mdm1_tdo;
  wire  [7:0] mdm1_reg_en;
  wire        mdm1_shift;
  wire        mdm1_capture;
  wire        mdm1_update;
  wire        mdm1_reset;

  wire        mdm2_clk;
  wire        mdm2_tdi;
  wire        mdm2_tdo;
  wire  [7:0] mdm2_reg_en;
  wire        mdm2_shift;
  wire        mdm2_capture;
  wire        mdm2_update;
  wire        mdm2_reset;

  wire        mdm3_clk;
  wire        mdm3_tdi;
  wire        mdm3_tdo;
  wire  [7:0] mdm3_reg_en;
  wire        mdm3_shift;
  wire        mdm3_capture;
  wire        mdm3_update;
  wire        mdm3_reset;

  wire        mdm4_clk;
  wire        mdm4_tdi;
  wire        mdm4_tdo;
  wire  [7:0] mdm4_reg_en;
  wire        mdm4_shift;
  wire        mdm4_capture;
  wire        mdm4_update;
  wire        mdm4_reset;

  wire        mdm5_clk;
  wire        mdm5_tdi;
  wire        mdm5_tdo;
  wire  [7:0] mdm5_reg_en;
  wire        mdm5_shift;
  wire        mdm5_capture;
  wire        mdm5_update;
  wire        mdm5_reset;

  wire        mdm6_clk;
  wire        mdm6_tdi;
  wire        mdm6_tdo;
  wire  [7:0] mdm6_reg_en;
  wire        mdm6_shift;
  wire        mdm6_capture;
  wire        mdm6_update;
  wire        mdm6_reset;

  wire        mdm7_clk;
  wire        mdm7_tdi;
  wire        mdm7_tdo;
  wire  [7:0] mdm7_reg_en;
  wire        mdm7_shift;
  wire        mdm7_capture;
  wire        mdm7_update;
  wire        mdm7_reset;

  wire          ddr_ctl_calib_done;

  wire          ddr_ctl_p0_cmd_en;
  wire    [2:0] ddr_ctl_p0_cmd_instr;
  wire    [5:0] ddr_ctl_p0_cmd_bl;
  wire   [29:0] ddr_ctl_p0_cmd_byte_addr;
  wire          ddr_ctl_p0_cmd_empty;
  wire          ddr_ctl_p0_cmd_full;
  wire          ddr_ctl_p0_wr_en;
  wire    [3:0] ddr_ctl_p0_wr_mask;
  wire   [31:0] ddr_ctl_p0_wr_data;
  wire          ddr_ctl_p0_wr_almost_full;
  wire          ddr_ctl_p0_rd_en;
  wire   [31:0] ddr_ctl_p0_rd_data;
  wire          ddr_ctl_p0_rd_empty;
  wire          ddr_ctl_p0_error;

  wire          ddr_ctl_p1_cmd_en;
  wire    [2:0] ddr_ctl_p1_cmd_instr;
  wire    [5:0] ddr_ctl_p1_cmd_bl;
  wire   [29:0] ddr_ctl_p1_cmd_byte_addr;
  wire          ddr_ctl_p1_cmd_empty;
  wire          ddr_ctl_p1_cmd_full;
  wire          ddr_ctl_p1_wr_en;
  wire    [3:0] ddr_ctl_p1_wr_mask;
  wire   [31:0] ddr_ctl_p1_wr_data;
  wire          ddr_ctl_p1_wr_almost_full;
  wire          ddr_ctl_p1_rd_en;
  wire   [31:0] ddr_ctl_p1_rd_data;
  wire          ddr_ctl_p1_rd_empty;
  wire          ddr_ctl_p1_error;

  wire          ddr_ctl_p2_cmd_en;
  wire    [2:0] ddr_ctl_p2_cmd_instr;
  wire    [5:0] ddr_ctl_p2_cmd_bl;
  wire   [29:0] ddr_ctl_p2_cmd_byte_addr;
  wire          ddr_ctl_p2_cmd_empty;
  wire          ddr_ctl_p2_cmd_full;
  wire          ddr_ctl_p2_wr_en;
  wire    [3:0] ddr_ctl_p2_wr_mask;
  wire   [31:0] ddr_ctl_p2_wr_data;
  wire          ddr_ctl_p2_wr_almost_full;
  wire          ddr_ctl_p2_rd_en;
  wire   [31:0] ddr_ctl_p2_rd_data;
  wire          ddr_ctl_p2_rd_empty;
  wire          ddr_ctl_p2_error;

  wire          ddr_ctl_p3_cmd_en;
  wire    [2:0] ddr_ctl_p3_cmd_instr;
  wire    [5:0] ddr_ctl_p3_cmd_bl;
  wire   [29:0] ddr_ctl_p3_cmd_byte_addr;
  wire          ddr_ctl_p3_cmd_empty;
  wire          ddr_ctl_p3_cmd_full;
  wire          ddr_ctl_p3_wr_en;
  wire    [3:0] ddr_ctl_p3_wr_mask;
  wire   [31:0] ddr_ctl_p3_wr_data;
  wire          ddr_ctl_p3_wr_almost_full;
  wire          ddr_ctl_p3_rd_en;
  wire   [31:0] ddr_ctl_p3_rd_data;
  wire          ddr_ctl_p3_rd_empty;
  wire          ddr_ctl_p3_error;


  // ==========================================================================
  // Clock manager
  // ==========================================================================
  clk_mgr_formic # (

    // Parameters
    .NEED_GTP0              ( 0 ),
    .NEED_GTP1              ( 0 ),
    .NEED_SRAM0             ( 0 ),
    .NEED_SRAM1             ( 1 ),
    .NEED_SRAM2             ( 1 ),
    .NEED_DDR               ( 1 ),
    .NEED_REF_CLK           ( 0 ),
    .NEED_MC                ( 1 ),
    .NEED_NI                ( 1 )
  
    ) i0_clk_mgr_formic (

    // External reference clock inputs
    .ref_clk_p              ( ref_clk_p ),
    .ref_clk_n              ( ref_clk_n ),

    // Reset inputs
    .rst_plls               ( rst_plls ),
    .rst_dig_dcms           ( rst_dig_dcms ),
    .rst_ext_clkouts        ( rst_ext_clkouts ),
    .rst_gtp0_dcm           ( 1'b0 ),
    .rst_gtp1_dcm           ( 1'b0 ),

    // Calibration done outputs
    .o_plls_locked          ( plls_locked ),
    .o_dig_dcms_locked      ( dig_dcms_locked ),
    .o_gtp0_dcm_locked      ( ),
    .o_gtp1_dcm_locked      ( ),

    // Clock outputs for in-FPGA logic
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_drp                ( clk_drp ),
    .clk_sram               ( clk_sram ),
    .clk_xbar               ( clk_xbar ),
    .clk_ddr                ( clk_ddr ),
    
    // Always-on 200 MHz reference clock
    .clk_ref                ( ),
    
    // Clock enables from reset manager
    .clk_mc_en              ( clk_mc_en ),
    .clk_ni_en              ( clk_ni_en ),
    .clk_ddr_en             ( clk_ddr_en ),
    .clk_xbar_en            ( clk_xbar_en ),

    // Clock interface to Xilinx DDR2 controller
    .clk_mcb                ( clk_mcb ),
    .clk_mcb_180            ( clk_mcb_180 ),
    .o_mcb_ce_0             ( mcb_ce_0 ),
    .o_mcb_ce_90            ( mcb_ce_90 ),

    // Clock interface to Xilinx GTP banks
    .gtp0_ref_clk_unbuf     ( 1'b0 ),
    .clk_gtp0               ( ),
    .clk_gtp0_2x            ( ),
    .gtp1_ref_clk_unbuf     ( 1'b0 ),
    .clk_gtp1               ( ),
    .clk_gtp1_2x            ( ),

    // Clock outputs to external pins
    .sram0_clk              ( ),
    .sram1_clk              ( sram1_clk ),
    .sram2_clk              ( sram2_clk ),

    // Feedback clock inputs from external pins
    .sram0_clk_fb           ( 1'b0 ),
    .sram1_clk_fb           ( sram1_clk_fb ),
    .sram2_clk_fb           ( sram2_clk_fb )
  );


  // ==========================================================================
  // Reset manager
  // ==========================================================================
  rst_mgr_formic # (

    // Parameters
    .NEED_GTP0              ( 0 ),
    .NEED_GTP1              ( 0 )

  ) i0_rst_mgr_formic (

    // Reset triggering events
    .rst_btn_n              ( rst_n ),
    .i_bctl_rst_soft        ( bctl_rst_soft ),
    .i_bctl_rst_hard        ( bctl_rst_hard ),
    .i_mdm_rst_sys          ( mdm_sys_reset ),

    // Clock inputs from clock manager
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_drp                ( clk_drp ),
    .clk_sram               ( clk_sram ),
    .clk_xbar               ( clk_xbar ),
    .clk_ddr                ( clk_ddr ),
    .clk_gtp0               ( 1'b0 ),
    .clk_gtp1               ( 1'b0 ),

    // Calibration inputs from clock manager
    .i_plls_locked          ( plls_locked ),
    .i_dig_dcms_locked      ( dig_dcms_locked ),
    .i_gtp0_dcm_locked      ( 1'b0 ),
    .i_gtp1_dcm_locked      ( 1'b0 ),

    // Calibration inputs from DDR and GTPs
    .i_ddr_ctl_calib_done   ( ddr_ctl_calib_done ),
    .o_ddr_boot_req         ( bctl_boot_req ),
    .i_ddr_boot_done        ( bctl_boot_done ),
    .i_gtp0_ref_clk_locked  ( 1'b0 ),
    .i_gtp1_ref_clk_locked  ( 1'b0 ),
    .i_gtp0_init_done       ( 1'b0 ),
    .i_gtp1_init_done       ( 1'b0 ),

    // Clock enable outputs to clock manager
    .clk_mc_en              ( clk_mc_en ),
    .clk_ni_en              ( clk_ni_en ),
    .clk_ddr_en             ( clk_ddr_en ),
    .clk_xbar_en            ( clk_xbar_en ),

    // Reset outputs to clock manager
    .rst_plls               ( rst_plls ),
    .rst_dig_dcms           ( rst_dig_dcms ),
    .rst_ext_clkouts        ( rst_ext_clkouts ),
    .rst_gtp_phy            ( ),
    .rst_gtp0_dcm           ( ),
    .rst_gtp1_dcm           ( ),

    // Resets to in-FPGA logic (complete, treated as false paths)
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_ddr                ( rst_ddr ),
    .rst_xbar               ( rst_xbar ),

    // Incomplete reset outputs for in-block reset generation
    .rst_master_assert      ( rst_master_assert ),
    .rst_drp_deassert       ( rst_drp_deassert ),
    .rst_sram_deassert      ( rst_sram_deassert ),
    .rst_gtp0_deassert      ( ),
    .rst_gtp1_deassert      ( )
  );


  // ==========================================================================
  // MBS 
  // ==========================================================================
  mbs i0_mbs (

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_xbar               ( clk_xbar ),
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_xbar               ( rst_xbar ),
    .i_boot_done            ( bctl_boot_done ),

    // Static configuration signals
    .i_board_id             ( board_id_q ),
    .i_node_id              ( 4'd0 ),
    .i_cpu_enable_rst_value ( 1'b1 ),

    // Board controller interface
    .o_bctl_load_status     ( mbs0_bctl_load_status ),
    .i_bctl_uart_irq        ( bctl_uart_irq[0] ),
    .o_bctl_uart_irq_clear  ( bctl_uart_irq_clear[0] ),
    .i_bctl_tmr_drift_fw    ( bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( bctl_tmr_drift_bw ),
    .o_bctl_trc_valid       ( mbs0_bctl_trc_valid ),
    .o_bctl_trc_data        ( mbs0_bctl_trc_data ),

    // SRAM Controller Interface
    .o_sctl_req_adr         ( mbs0_sram1_req_adr ),
    .o_sctl_req_we          ( mbs0_sram1_req_we ),
    .o_sctl_req_wdata       ( mbs0_sram1_req_wdata ),
    .o_sctl_req_be          ( mbs0_sram1_req_be ),
    .o_sctl_req_valid       ( mbs0_sram1_req_valid ),
    .i_sctl_resp_rdata      ( mbs0_sram1_resp_rdata ),
    .i_sctl_resp_valid      ( mbs0_sram1_resp_valid ),

    // Crossbar interface
    .i_xbar_out_enq         ( xbar00_out_enq ),
    .i_xbar_out_offset      ( xbar00_out_offset ),
    .i_xbar_out_eop         ( xbar00_out_eop ),
    .i_xbar_out_data        ( xbar00_out_data ),
    .o_xbar_out_full        ( xbar00_out_full ),
    .o_xbar_out_packets_vc0 ( xbar00_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( xbar00_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( xbar00_out_packets_vc2 ),
    .i_xbar_in_deq          ( xbar00_in_deq ),
    .i_xbar_in_offset       ( xbar00_in_offset ),
    .i_xbar_in_eop          ( xbar00_in_eop ),
    .o_xbar_in_data         ( xbar00_in_data ),
    .o_xbar_in_empty        ( xbar00_in_empty ),

    // Microblaze debug interface
    .i_mdm_brk              ( mdm_brk ),
    .i_mdm_nm_brk           ( mdm_nm_brk ),
    .i_mdm_clk              ( mdm0_clk ),
    .i_mdm_tdi              ( mdm0_tdi ),
    .o_mdm_tdo              ( mdm0_tdo ),
    .i_mdm_reg_en           ( mdm0_reg_en ),
    .i_mdm_shift            ( mdm0_shift ),
    .i_mdm_capture          ( mdm0_capture ),
    .i_mdm_update           ( mdm0_update ),
    .i_mdm_reset            ( mdm0_reset )
  );

  mbs i1_mbs (

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_xbar               ( clk_xbar ),
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_xbar               ( rst_xbar ),
    .i_boot_done            ( bctl_boot_done ),

    // Static configuration signals
    .i_board_id             ( board_id_q ),
    .i_node_id              ( 4'd1 ),
    .i_cpu_enable_rst_value ( 1'b0 ),

    // Board controller interface
    .o_bctl_load_status     ( mbs1_bctl_load_status ),
    .i_bctl_uart_irq        ( bctl_uart_irq[1] ),
    .o_bctl_uart_irq_clear  ( bctl_uart_irq_clear[1] ),
    .i_bctl_tmr_drift_fw    ( bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( bctl_tmr_drift_bw ),
    .o_bctl_trc_valid       ( mbs1_bctl_trc_valid ),
    .o_bctl_trc_data        ( mbs1_bctl_trc_data ),

    // SRAM Controller Interface
    .o_sctl_req_adr         ( mbs1_sram1_req_adr ),
    .o_sctl_req_we          ( mbs1_sram1_req_we ),
    .o_sctl_req_wdata       ( mbs1_sram1_req_wdata ),
    .o_sctl_req_be          ( mbs1_sram1_req_be ),
    .o_sctl_req_valid       ( mbs1_sram1_req_valid ),
    .i_sctl_resp_rdata      ( mbs1_sram1_resp_rdata ),
    .i_sctl_resp_valid      ( mbs1_sram1_resp_valid ),

    // Crossbar interface
    .i_xbar_out_enq         ( xbar01_out_enq ),
    .i_xbar_out_offset      ( xbar01_out_offset ),
    .i_xbar_out_eop         ( xbar01_out_eop ),
    .i_xbar_out_data        ( xbar01_out_data ),
    .o_xbar_out_full        ( xbar01_out_full ),
    .o_xbar_out_packets_vc0 ( xbar01_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( xbar01_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( xbar01_out_packets_vc2 ),
    .i_xbar_in_deq          ( xbar01_in_deq ),
    .i_xbar_in_offset       ( xbar01_in_offset ),
    .i_xbar_in_eop          ( xbar01_in_eop ),
    .o_xbar_in_data         ( xbar01_in_data ),
    .o_xbar_in_empty        ( xbar01_in_empty ),

    // Microblaze debug interface
    .i_mdm_brk              ( mdm_brk ),
    .i_mdm_nm_brk           ( mdm_nm_brk ),
    .i_mdm_clk              ( mdm1_clk ),
    .i_mdm_tdi              ( mdm1_tdi ),
    .o_mdm_tdo              ( mdm1_tdo ),
    .i_mdm_reg_en           ( mdm1_reg_en ),
    .i_mdm_shift            ( mdm1_shift ),
    .i_mdm_capture          ( mdm1_capture ),
    .i_mdm_update           ( mdm1_update ),
    .i_mdm_reset            ( mdm1_reset )
  );

  mbs i2_mbs (

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_xbar               ( clk_xbar ),
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_xbar               ( rst_xbar ),
    .i_boot_done            ( bctl_boot_done ),

    // Static configuration signals
    .i_board_id             ( board_id_q ),
    .i_node_id              ( 4'd2 ),
    .i_cpu_enable_rst_value ( 1'b0 ),

    // Board controller interface
    .o_bctl_load_status     ( mbs2_bctl_load_status ),
    .i_bctl_uart_irq        ( bctl_uart_irq[2] ),
    .o_bctl_uart_irq_clear  ( bctl_uart_irq_clear[2] ),
    .i_bctl_tmr_drift_fw    ( bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( bctl_tmr_drift_bw ),
    .o_bctl_trc_valid       ( mbs2_bctl_trc_valid ),
    .o_bctl_trc_data        ( mbs2_bctl_trc_data ),

    // SRAM Controller Interface
    .o_sctl_req_adr         ( mbs2_sram2_req_adr ),
    .o_sctl_req_we          ( mbs2_sram2_req_we ),
    .o_sctl_req_wdata       ( mbs2_sram2_req_wdata ),
    .o_sctl_req_be          ( mbs2_sram2_req_be ),
    .o_sctl_req_valid       ( mbs2_sram2_req_valid ),
    .i_sctl_resp_rdata      ( mbs2_sram2_resp_rdata ),
    .i_sctl_resp_valid      ( mbs2_sram2_resp_valid ),

    // Crossbar interface
    .i_xbar_out_enq         ( xbar02_out_enq ),
    .i_xbar_out_offset      ( xbar02_out_offset ),
    .i_xbar_out_eop         ( xbar02_out_eop ),
    .i_xbar_out_data        ( xbar02_out_data ),
    .o_xbar_out_full        ( xbar02_out_full ),
    .o_xbar_out_packets_vc0 ( xbar02_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( xbar02_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( xbar02_out_packets_vc2 ),
    .i_xbar_in_deq          ( xbar02_in_deq ),
    .i_xbar_in_offset       ( xbar02_in_offset ),
    .i_xbar_in_eop          ( xbar02_in_eop ),
    .o_xbar_in_data         ( xbar02_in_data ),
    .o_xbar_in_empty        ( xbar02_in_empty ),

    // Microblaze debug interface
    .i_mdm_brk              ( mdm_brk ),
    .i_mdm_nm_brk           ( mdm_nm_brk ),
    .i_mdm_clk              ( mdm2_clk ),
    .i_mdm_tdi              ( mdm2_tdi ),
    .o_mdm_tdo              ( mdm2_tdo ),
    .i_mdm_reg_en           ( mdm2_reg_en ),
    .i_mdm_shift            ( mdm2_shift ),
    .i_mdm_capture          ( mdm2_capture ),
    .i_mdm_update           ( mdm2_update ),
    .i_mdm_reset            ( mdm2_reset )
  );

  mbs i3_mbs (

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_xbar               ( clk_xbar ),
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_xbar               ( rst_xbar ),
    .i_boot_done            ( bctl_boot_done ),

    // Static configuration signals
    .i_board_id             ( board_id_q ),
    .i_node_id              ( 4'd3 ),
    .i_cpu_enable_rst_value ( 1'b0 ),

    // Board controller interface
    .o_bctl_load_status     ( mbs3_bctl_load_status ),
    .i_bctl_uart_irq        ( bctl_uart_irq[3] ),
    .o_bctl_uart_irq_clear  ( bctl_uart_irq_clear[3] ),
    .i_bctl_tmr_drift_fw    ( bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( bctl_tmr_drift_bw ),
    .o_bctl_trc_valid       ( mbs3_bctl_trc_valid ),
    .o_bctl_trc_data        ( mbs3_bctl_trc_data ),

    // SRAM Controller Interface
    .o_sctl_req_adr         ( mbs3_sram2_req_adr ),
    .o_sctl_req_we          ( mbs3_sram2_req_we ),
    .o_sctl_req_wdata       ( mbs3_sram2_req_wdata ),
    .o_sctl_req_be          ( mbs3_sram2_req_be ),
    .o_sctl_req_valid       ( mbs3_sram2_req_valid ),
    .i_sctl_resp_rdata      ( mbs3_sram2_resp_rdata ),
    .i_sctl_resp_valid      ( mbs3_sram2_resp_valid ),

    // Crossbar interface
    .i_xbar_out_enq         ( xbar03_out_enq ),
    .i_xbar_out_offset      ( xbar03_out_offset ),
    .i_xbar_out_eop         ( xbar03_out_eop ),
    .i_xbar_out_data        ( xbar03_out_data ),
    .o_xbar_out_full        ( xbar03_out_full ),
    .o_xbar_out_packets_vc0 ( xbar03_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( xbar03_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( xbar03_out_packets_vc2 ),
    .i_xbar_in_deq          ( xbar03_in_deq ),
    .i_xbar_in_offset       ( xbar03_in_offset ),
    .i_xbar_in_eop          ( xbar03_in_eop ),
    .o_xbar_in_data         ( xbar03_in_data ),
    .o_xbar_in_empty        ( xbar03_in_empty ),

    // Microblaze debug interface
    .i_mdm_brk              ( mdm_brk ),
    .i_mdm_nm_brk           ( mdm_nm_brk ),
    .i_mdm_clk              ( mdm3_clk ),
    .i_mdm_tdi              ( mdm3_tdi ),
    .o_mdm_tdo              ( mdm3_tdo ),
    .i_mdm_reg_en           ( mdm3_reg_en ),
    .i_mdm_shift            ( mdm3_shift ),
    .i_mdm_capture          ( mdm3_capture ),
    .i_mdm_update           ( mdm3_update ),
    .i_mdm_reset            ( mdm3_reset )
  );

  mbs i4_mbs (

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_xbar               ( clk_xbar ),
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_xbar               ( rst_xbar ),
    .i_boot_done            ( bctl_boot_done ),

    // Static configuration signals
    .i_board_id             ( board_id_q ),
    .i_node_id              ( 4'd4 ),
    .i_cpu_enable_rst_value ( 1'b0 ),

    // Board controller interface
    .o_bctl_load_status     ( mbs4_bctl_load_status ),
    .i_bctl_uart_irq        ( bctl_uart_irq[4] ),
    .o_bctl_uart_irq_clear  ( bctl_uart_irq_clear[4] ),
    .i_bctl_tmr_drift_fw    ( bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( bctl_tmr_drift_bw ),
    .o_bctl_trc_valid       ( mbs4_bctl_trc_valid ),
    .o_bctl_trc_data        ( mbs4_bctl_trc_data ),

    // SRAM Controller Interface
    .o_sctl_req_adr         ( mbs4_sram1_req_adr ),
    .o_sctl_req_we          ( mbs4_sram1_req_we ),
    .o_sctl_req_wdata       ( mbs4_sram1_req_wdata ),
    .o_sctl_req_be          ( mbs4_sram1_req_be ),
    .o_sctl_req_valid       ( mbs4_sram1_req_valid ),
    .i_sctl_resp_rdata      ( mbs4_sram1_resp_rdata ),
    .i_sctl_resp_valid      ( mbs4_sram1_resp_valid ),

    // Crossbar interface
    .i_xbar_out_enq         ( xbar04_out_enq ),
    .i_xbar_out_offset      ( xbar04_out_offset ),
    .i_xbar_out_eop         ( xbar04_out_eop ),
    .i_xbar_out_data        ( xbar04_out_data ),
    .o_xbar_out_full        ( xbar04_out_full ),
    .o_xbar_out_packets_vc0 ( xbar04_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( xbar04_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( xbar04_out_packets_vc2 ),
    .i_xbar_in_deq          ( xbar04_in_deq ),
    .i_xbar_in_offset       ( xbar04_in_offset ),
    .i_xbar_in_eop          ( xbar04_in_eop ),
    .o_xbar_in_data         ( xbar04_in_data ),
    .o_xbar_in_empty        ( xbar04_in_empty ),

    // Microblaze debug interface
    .i_mdm_brk              ( mdm_brk ),
    .i_mdm_nm_brk           ( mdm_nm_brk ),
    .i_mdm_clk              ( mdm4_clk ),
    .i_mdm_tdi              ( mdm4_tdi ),
    .o_mdm_tdo              ( mdm4_tdo ),
    .i_mdm_reg_en           ( mdm4_reg_en ),
    .i_mdm_shift            ( mdm4_shift ),
    .i_mdm_capture          ( mdm4_capture ),
    .i_mdm_update           ( mdm4_update ),
    .i_mdm_reset            ( mdm4_reset )
  );

  mbs i5_mbs (

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_xbar               ( clk_xbar ),
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_xbar               ( rst_xbar ),
    .i_boot_done            ( bctl_boot_done ),

    // Static configuration signals
    .i_board_id             ( board_id_q ),
    .i_node_id              ( 4'd5 ),
    .i_cpu_enable_rst_value ( 1'b0 ),

    // Board controller interface
    .o_bctl_load_status     ( mbs5_bctl_load_status ),
    .i_bctl_uart_irq        ( bctl_uart_irq[5] ),
    .o_bctl_uart_irq_clear  ( bctl_uart_irq_clear[5] ),
    .i_bctl_tmr_drift_fw    ( bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( bctl_tmr_drift_bw ),
    .o_bctl_trc_valid       ( mbs5_bctl_trc_valid ),
    .o_bctl_trc_data        ( mbs5_bctl_trc_data ),

    // SRAM Controller Interface
    .o_sctl_req_adr         ( mbs5_sram1_req_adr ),
    .o_sctl_req_we          ( mbs5_sram1_req_we ),
    .o_sctl_req_wdata       ( mbs5_sram1_req_wdata ),
    .o_sctl_req_be          ( mbs5_sram1_req_be ),
    .o_sctl_req_valid       ( mbs5_sram1_req_valid ),
    .i_sctl_resp_rdata      ( mbs5_sram1_resp_rdata ),
    .i_sctl_resp_valid      ( mbs5_sram1_resp_valid ),

    // Crossbar interface
    .i_xbar_out_enq         ( xbar05_out_enq ),
    .i_xbar_out_offset      ( xbar05_out_offset ),
    .i_xbar_out_eop         ( xbar05_out_eop ),
    .i_xbar_out_data        ( xbar05_out_data ),
    .o_xbar_out_full        ( xbar05_out_full ),
    .o_xbar_out_packets_vc0 ( xbar05_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( xbar05_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( xbar05_out_packets_vc2 ),
    .i_xbar_in_deq          ( xbar05_in_deq ),
    .i_xbar_in_offset       ( xbar05_in_offset ),
    .i_xbar_in_eop          ( xbar05_in_eop ),
    .o_xbar_in_data         ( xbar05_in_data ),
    .o_xbar_in_empty        ( xbar05_in_empty ),

    // Microblaze debug interface
    .i_mdm_brk              ( mdm_brk ),
    .i_mdm_nm_brk           ( mdm_nm_brk ),
    .i_mdm_clk              ( mdm5_clk ),
    .i_mdm_tdi              ( mdm5_tdi ),
    .o_mdm_tdo              ( mdm5_tdo ),
    .i_mdm_reg_en           ( mdm5_reg_en ),
    .i_mdm_shift            ( mdm5_shift ),
    .i_mdm_capture          ( mdm5_capture ),
    .i_mdm_update           ( mdm5_update ),
    .i_mdm_reset            ( mdm5_reset )
  );

  mbs i6_mbs (

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_xbar               ( clk_xbar ),
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_xbar               ( rst_xbar ),
    .i_boot_done            ( bctl_boot_done ),

    // Static configuration signals
    .i_board_id             ( board_id_q ),
    .i_node_id              ( 4'd6 ),
    .i_cpu_enable_rst_value ( 1'b0 ),

    // Board controller interface
    .o_bctl_load_status     ( mbs6_bctl_load_status ),
    .i_bctl_uart_irq        ( bctl_uart_irq[6] ),
    .o_bctl_uart_irq_clear  ( bctl_uart_irq_clear[6] ),
    .i_bctl_tmr_drift_fw    ( bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( bctl_tmr_drift_bw ),
    .o_bctl_trc_valid       ( mbs6_bctl_trc_valid ),
    .o_bctl_trc_data        ( mbs6_bctl_trc_data ),

    // SRAM Controller Interface
    .o_sctl_req_adr         ( mbs6_sram2_req_adr ),
    .o_sctl_req_we          ( mbs6_sram2_req_we ),
    .o_sctl_req_wdata       ( mbs6_sram2_req_wdata ),
    .o_sctl_req_be          ( mbs6_sram2_req_be ),
    .o_sctl_req_valid       ( mbs6_sram2_req_valid ),
    .i_sctl_resp_rdata      ( mbs6_sram2_resp_rdata ),
    .i_sctl_resp_valid      ( mbs6_sram2_resp_valid ),

    // Crossbar interface
    .i_xbar_out_enq         ( xbar06_out_enq ),
    .i_xbar_out_offset      ( xbar06_out_offset ),
    .i_xbar_out_eop         ( xbar06_out_eop ),
    .i_xbar_out_data        ( xbar06_out_data ),
    .o_xbar_out_full        ( xbar06_out_full ),
    .o_xbar_out_packets_vc0 ( xbar06_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( xbar06_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( xbar06_out_packets_vc2 ),
    .i_xbar_in_deq          ( xbar06_in_deq ),
    .i_xbar_in_offset       ( xbar06_in_offset ),
    .i_xbar_in_eop          ( xbar06_in_eop ),
    .o_xbar_in_data         ( xbar06_in_data ),
    .o_xbar_in_empty        ( xbar06_in_empty ),

    // Microblaze debug interface
    .i_mdm_brk              ( mdm_brk ),
    .i_mdm_nm_brk           ( mdm_nm_brk ),
    .i_mdm_clk              ( mdm6_clk ),
    .i_mdm_tdi              ( mdm6_tdi ),
    .o_mdm_tdo              ( mdm6_tdo ),
    .i_mdm_reg_en           ( mdm6_reg_en ),
    .i_mdm_shift            ( mdm6_shift ),
    .i_mdm_capture          ( mdm6_capture ),
    .i_mdm_update           ( mdm6_update ),
    .i_mdm_reset            ( mdm6_reset )
  );

  mbs i7_mbs (

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_mc                 ( clk_mc ),
    .clk_ni                 ( clk_ni ),
    .clk_xbar               ( clk_xbar ),
    .rst_mc                 ( rst_mc ),
    .rst_ni                 ( rst_ni ),
    .rst_xbar               ( rst_xbar ),
    .i_boot_done            ( bctl_boot_done ),

    // Static configuration signals
    .i_board_id             ( board_id_q ),
    .i_node_id              ( 4'd7 ),
    .i_cpu_enable_rst_value ( 1'b0 ),

    // Board controller interface
    .o_bctl_load_status     ( mbs7_bctl_load_status ),
    .i_bctl_uart_irq        ( bctl_uart_irq[7] ),
    .o_bctl_uart_irq_clear  ( bctl_uart_irq_clear[7] ),
    .i_bctl_tmr_drift_fw    ( bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( bctl_tmr_drift_bw ),
    .o_bctl_trc_valid       ( mbs7_bctl_trc_valid ),
    .o_bctl_trc_data        ( mbs7_bctl_trc_data ),

    // SRAM Controller Interface
    .o_sctl_req_adr         ( mbs7_sram2_req_adr ),
    .o_sctl_req_we          ( mbs7_sram2_req_we ),
    .o_sctl_req_wdata       ( mbs7_sram2_req_wdata ),
    .o_sctl_req_be          ( mbs7_sram2_req_be ),
    .o_sctl_req_valid       ( mbs7_sram2_req_valid ),
    .i_sctl_resp_rdata      ( mbs7_sram2_resp_rdata ),
    .i_sctl_resp_valid      ( mbs7_sram2_resp_valid ),

    // Crossbar interface
    .i_xbar_out_enq         ( xbar07_out_enq ),
    .i_xbar_out_offset      ( xbar07_out_offset ),
    .i_xbar_out_eop         ( xbar07_out_eop ),
    .i_xbar_out_data        ( xbar07_out_data ),
    .o_xbar_out_full        ( xbar07_out_full ),
    .o_xbar_out_packets_vc0 ( xbar07_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( xbar07_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( xbar07_out_packets_vc2 ),
    .i_xbar_in_deq          ( xbar07_in_deq ),
    .i_xbar_in_offset       ( xbar07_in_offset ),
    .i_xbar_in_eop          ( xbar07_in_eop ),
    .o_xbar_in_data         ( xbar07_in_data ),
    .o_xbar_in_empty        ( xbar07_in_empty ),

    // Microblaze debug interface
    .i_mdm_brk              ( mdm_brk ),
    .i_mdm_nm_brk           ( mdm_nm_brk ),
    .i_mdm_clk              ( mdm7_clk ),
    .i_mdm_tdi              ( mdm7_tdi ),
    .o_mdm_tdo              ( mdm7_tdo ),
    .i_mdm_reg_en           ( mdm7_reg_en ),
    .i_mdm_shift            ( mdm7_shift ),
    .i_mdm_capture          ( mdm7_capture ),
    .i_mdm_update           ( mdm7_update ),
    .i_mdm_reset            ( mdm7_reset )
  );

  
  // ==========================================================================
  // SRAM Controllers
  // ==========================================================================

  // Top-left SRAM
  sram_ctl i2_sram_ctl (

    // Clocks and Resets
    .clk_sram               ( clk_sram ),   
    .rst_master_assert      ( rst_master_assert ),
    .rst_sram_deassert      ( rst_sram_deassert ),

    // SRAM interface
    .io_sram_dq             ( {sram2_dqp, sram2_dq} ),
    .o_sram_adr             ( sram2_a ),
    .o_sram_bw_n            ( sram2_bw_n ),
    .o_sram_we_n            ( sram2_we_n ),
    .o_sram_en_n            ( sram2_cs_n ),

    // MBS #1 interface
    .i_mbs0_req_adr         ( mbs2_sram2_req_adr ),
    .i_mbs0_req_we          ( mbs2_sram2_req_we ),
    .i_mbs0_req_wdata       ( mbs2_sram2_req_wdata ),
    .i_mbs0_req_be          ( mbs2_sram2_req_be ),
    .i_mbs0_req_valid       ( mbs2_sram2_req_valid ),
    .o_mbs0_resp_rdata      ( mbs2_sram2_resp_rdata ),
    .o_mbs0_resp_valid      ( mbs2_sram2_resp_valid ),

    // MBS #2 interface
    .i_mbs1_req_adr         ( mbs3_sram2_req_adr ),
    .i_mbs1_req_we          ( mbs3_sram2_req_we ),
    .i_mbs1_req_wdata       ( mbs3_sram2_req_wdata ),
    .i_mbs1_req_be          ( mbs3_sram2_req_be ),
    .i_mbs1_req_valid       ( mbs3_sram2_req_valid ),
    .o_mbs1_resp_rdata      ( mbs3_sram2_resp_rdata ),
    .o_mbs1_resp_valid      ( mbs3_sram2_resp_valid ),

    // MBS #3 interface
    .i_mbs2_req_adr         ( mbs6_sram2_req_adr ),
    .i_mbs2_req_we          ( mbs6_sram2_req_we ),
    .i_mbs2_req_wdata       ( mbs6_sram2_req_wdata ),
    .i_mbs2_req_be          ( mbs6_sram2_req_be ),
    .i_mbs2_req_valid       ( mbs6_sram2_req_valid ),
    .o_mbs2_resp_rdata      ( mbs6_sram2_resp_rdata ),
    .o_mbs2_resp_valid      ( mbs6_sram2_resp_valid ),

    // MBS #7 interface
    .i_mbs3_req_adr         ( mbs7_sram2_req_adr ),
    .i_mbs3_req_we          ( mbs7_sram2_req_we ),
    .i_mbs3_req_wdata       ( mbs7_sram2_req_wdata ),
    .i_mbs3_req_be          ( mbs7_sram2_req_be ),
    .i_mbs3_req_valid       ( mbs7_sram2_req_valid ),
    .o_mbs3_resp_rdata      ( mbs7_sram2_resp_rdata ),
    .o_mbs3_resp_valid      ( mbs7_sram2_resp_valid )
  );

  // Reserved top-level outputs
  assign sram2_adv    = 1'b0;
  assign sram2_clke_n = 1'b0;


  // Bottom-left SRAM
  sram_ctl i1_sram_ctl (

    // Clocks and Resets
    .clk_sram               ( clk_sram ),   
    .rst_master_assert      ( rst_master_assert ),
    .rst_sram_deassert      ( rst_sram_deassert ),

    // SRAM interface
    .io_sram_dq             ( {sram1_dqp, sram1_dq} ),
    .o_sram_adr             ( sram1_a ),
    .o_sram_bw_n            ( sram1_bw_n ),
    .o_sram_we_n            ( sram1_we_n ),
    .o_sram_en_n            ( sram1_cs_n ),

    // MBS #0 interface
    .i_mbs0_req_adr         ( mbs0_sram1_req_adr ),
    .i_mbs0_req_we          ( mbs0_sram1_req_we ),
    .i_mbs0_req_wdata       ( mbs0_sram1_req_wdata ),
    .i_mbs0_req_be          ( mbs0_sram1_req_be ),
    .i_mbs0_req_valid       ( mbs0_sram1_req_valid ),
    .o_mbs0_resp_rdata      ( mbs0_sram1_resp_rdata ),
    .o_mbs0_resp_valid      ( mbs0_sram1_resp_valid ),

    // MBS #4 interface
    .i_mbs1_req_adr         ( mbs1_sram1_req_adr ),
    .i_mbs1_req_we          ( mbs1_sram1_req_we ),
    .i_mbs1_req_wdata       ( mbs1_sram1_req_wdata ),
    .i_mbs1_req_be          ( mbs1_sram1_req_be ),
    .i_mbs1_req_valid       ( mbs1_sram1_req_valid ),
    .o_mbs1_resp_rdata      ( mbs1_sram1_resp_rdata ),
    .o_mbs1_resp_valid      ( mbs1_sram1_resp_valid ),

    // MBS #5 interface
    .i_mbs2_req_adr         ( mbs4_sram1_req_adr ),
    .i_mbs2_req_we          ( mbs4_sram1_req_we ),
    .i_mbs2_req_wdata       ( mbs4_sram1_req_wdata ),
    .i_mbs2_req_be          ( mbs4_sram1_req_be ),
    .i_mbs2_req_valid       ( mbs4_sram1_req_valid ),
    .o_mbs2_resp_rdata      ( mbs4_sram1_resp_rdata ),
    .o_mbs2_resp_valid      ( mbs4_sram1_resp_valid ),

    // MBS #6 interface
    .i_mbs3_req_adr         ( mbs5_sram1_req_adr ),
    .i_mbs3_req_we          ( mbs5_sram1_req_we ),
    .i_mbs3_req_wdata       ( mbs5_sram1_req_wdata ),
    .i_mbs3_req_be          ( mbs5_sram1_req_be ),
    .i_mbs3_req_valid       ( mbs5_sram1_req_valid ),
    .o_mbs3_resp_rdata      ( mbs5_sram1_resp_rdata ),
    .o_mbs3_resp_valid      ( mbs5_sram1_resp_valid )
  );

  // Reserved top-level outputs
  assign sram1_adv    = 1'b0;
  assign sram1_clke_n = 1'b0;


  // ==========================================================================
  // TLB
  // ==========================================================================
  tlb i0_tlb (

    // Clocks and resets
    .clk_cpu                    ( clk_cpu ),
    .clk_ni                     ( clk_ni ),
    .clk_xbar                   ( clk_xbar ),
    .clk_ddr                    ( clk_ddr ),
    .rst_ni                     ( rst_ni ),
    .rst_xbar                   ( rst_xbar ),
    .rst_ddr                    ( rst_ddr ),

    // Board control TLB maintenance interface
    .i_bctl_tlb_enabled         ( bctl_tlb_enabled ),
    .i_bctl_maint_cmd           ( bctl_tlb_maint_cmd ),
    .i_bctl_maint_wr_en         ( bctl_tlb_maint_wr_en ),
    .i_bctl_virt_adr            ( bctl_tlb_virt_adr ),
    .i_bctl_phys_adr            ( bctl_tlb_phys_adr ),
    .i_bctl_entry_valid         ( bctl_tlb_entry_valid ),
    .o_bctl_phys_adr            ( bctl_tlb_resp_phys_adr ),
    .o_bctl_entry_valid         ( bctl_tlb_resp_entry_valid ),
    .o_bctl_drop                ( bctl_tlb_drop ),

    // Crossbar interface #0 
    .i_xbar0_out_enq            ( xbar16_out_enq ),
    .i_xbar0_out_offset         ( xbar16_out_offset ),
    .i_xbar0_out_eop            ( xbar16_out_eop ),
    .i_xbar0_out_data           ( xbar16_out_data ),
    .o_xbar0_out_full           ( xbar16_out_full ),
    .o_xbar0_out_packets_vc0    ( xbar16_out_packets_vc0 ),
    .o_xbar0_out_packets_vc1    ( xbar16_out_packets_vc1 ),
    .o_xbar0_out_packets_vc2    ( xbar16_out_packets_vc2 ),
    .i_xbar0_in_deq             ( xbar16_in_deq ),
    .i_xbar0_in_offset          ( xbar16_in_offset ),
    .i_xbar0_in_eop             ( xbar16_in_eop ),
    .o_xbar0_in_data            ( xbar16_in_data ),
    .o_xbar0_in_empty           ( xbar16_in_empty ),

    // Crossbar interface #1
    .i_xbar1_out_enq            ( xbar17_out_enq ),
    .i_xbar1_out_offset         ( xbar17_out_offset ),
    .i_xbar1_out_eop            ( xbar17_out_eop ),
    .i_xbar1_out_data           ( xbar17_out_data ),
    .o_xbar1_out_full           ( xbar17_out_full ),
    .o_xbar1_out_packets_vc0    ( xbar17_out_packets_vc0 ),
    .o_xbar1_out_packets_vc1    ( xbar17_out_packets_vc1 ),
    .o_xbar1_out_packets_vc2    ( xbar17_out_packets_vc2 ),
    .i_xbar1_in_deq             ( xbar17_in_deq ),
    .i_xbar1_in_offset          ( xbar17_in_offset ),
    .i_xbar1_in_eop             ( xbar17_in_eop ),
    .o_xbar1_in_data            ( xbar17_in_data ),
    .o_xbar1_in_empty           ( xbar17_in_empty ),

    // Crossbar interface #2
    .i_xbar2_out_enq            ( xbar18_out_enq ),
    .i_xbar2_out_offset         ( xbar18_out_offset ),
    .i_xbar2_out_eop            ( xbar18_out_eop ),
    .i_xbar2_out_data           ( xbar18_out_data ),
    .o_xbar2_out_full           ( xbar18_out_full ),
    .o_xbar2_out_packets_vc0    ( xbar18_out_packets_vc0 ),
    .o_xbar2_out_packets_vc1    ( xbar18_out_packets_vc1 ),
    .o_xbar2_out_packets_vc2    ( xbar18_out_packets_vc2 ),
    .i_xbar2_in_deq             ( xbar18_in_deq ),
    .i_xbar2_in_offset          ( xbar18_in_offset ),
    .i_xbar2_in_eop             ( xbar18_in_eop ),
    .o_xbar2_in_data            ( xbar18_in_data ),
    .o_xbar2_in_empty           ( xbar18_in_empty ),

    // Crossbar interface #3
    .i_xbar3_out_enq            ( xbar19_out_enq ),
    .i_xbar3_out_offset         ( xbar19_out_offset ),
    .i_xbar3_out_eop            ( xbar19_out_eop ),
    .i_xbar3_out_data           ( xbar19_out_data ),
    .o_xbar3_out_full           ( xbar19_out_full ),
    .o_xbar3_out_packets_vc0    ( xbar19_out_packets_vc0 ),
    .o_xbar3_out_packets_vc1    ( xbar19_out_packets_vc1 ),
    .o_xbar3_out_packets_vc2    ( xbar19_out_packets_vc2 ),
    .i_xbar3_in_deq             ( xbar19_in_deq ),
    .i_xbar3_in_offset          ( xbar19_in_offset ),
    .i_xbar3_in_eop             ( xbar19_in_eop ),
    .o_xbar3_in_data            ( xbar19_in_data ),
    .o_xbar3_in_empty           ( xbar19_in_empty ),

    // Crossbar interface #4
    .i_xbar4_out_enq            ( xbar20_out_enq ),
    .i_xbar4_out_offset         ( xbar20_out_offset ),
    .i_xbar4_out_eop            ( xbar20_out_eop ),
    .i_xbar4_out_data           ( xbar20_out_data ),
    .o_xbar4_out_full           ( xbar20_out_full ),
    .o_xbar4_out_packets_vc0    ( xbar20_out_packets_vc0 ),
    .o_xbar4_out_packets_vc1    ( xbar20_out_packets_vc1 ),
    .o_xbar4_out_packets_vc2    ( xbar20_out_packets_vc2 ),
    .i_xbar4_in_deq             ( xbar20_in_deq ),
    .i_xbar4_in_offset          ( xbar20_in_offset ),
    .i_xbar4_in_eop             ( xbar20_in_eop ),
    .o_xbar4_in_data            ( xbar20_in_data ),
    .o_xbar4_in_empty           ( xbar20_in_empty ),

    // DDR controller port #0
    .o_ddr0_cmd_en              ( ddr_ctl_p0_cmd_en ),
    .o_ddr0_cmd_instr           ( ddr_ctl_p0_cmd_instr ),
    .o_ddr0_cmd_bl              ( ddr_ctl_p0_cmd_bl ),
    .o_ddr0_cmd_byte_addr       ( ddr_ctl_p0_cmd_byte_addr ),
    .i_ddr0_cmd_empty           ( ddr_ctl_p0_cmd_empty ),
    .i_ddr0_cmd_full            ( ddr_ctl_p0_cmd_full ),
    .o_ddr0_wr_en               ( ddr_ctl_p0_wr_en ),
    .o_ddr0_wr_data             ( ddr_ctl_p0_wr_data ),
    .o_ddr0_wr_mask             ( ddr_ctl_p0_wr_mask ),
    .i_ddr0_wr_almost_full      ( ddr_ctl_p0_wr_almost_full ),
    .o_ddr0_rd_en               ( ddr_ctl_p0_rd_en ),
    .i_ddr0_rd_data             ( ddr_ctl_p0_rd_data ),
    .i_ddr0_rd_empty            ( ddr_ctl_p0_rd_empty ),

    // DDR controller port #1
    .o_ddr1_cmd_en              ( ddr_ctl_p1_cmd_en ),
    .o_ddr1_cmd_instr           ( ddr_ctl_p1_cmd_instr ),
    .o_ddr1_cmd_bl              ( ddr_ctl_p1_cmd_bl ),
    .o_ddr1_cmd_byte_addr       ( ddr_ctl_p1_cmd_byte_addr ),
    .i_ddr1_cmd_empty           ( ddr_ctl_p1_cmd_empty ),
    .i_ddr1_cmd_full            ( ddr_ctl_p1_cmd_full ),
    .o_ddr1_wr_en               ( ddr_ctl_p1_wr_en ),
    .o_ddr1_wr_data             ( ddr_ctl_p1_wr_data ),
    .o_ddr1_wr_mask             ( ddr_ctl_p1_wr_mask ),
    .i_ddr1_wr_almost_full      ( ddr_ctl_p1_wr_almost_full ),
    .o_ddr1_rd_en               ( ddr_ctl_p1_rd_en ),
    .i_ddr1_rd_data             ( ddr_ctl_p1_rd_data ),
    .i_ddr1_rd_empty            ( ddr_ctl_p1_rd_empty ),

    // DDR controller port #2
    .o_ddr2_cmd_en              ( ddr_ctl_p2_cmd_en ),
    .o_ddr2_cmd_instr           ( ddr_ctl_p2_cmd_instr ),
    .o_ddr2_cmd_bl              ( ddr_ctl_p2_cmd_bl ),
    .o_ddr2_cmd_byte_addr       ( ddr_ctl_p2_cmd_byte_addr ),
    .i_ddr2_cmd_empty           ( ddr_ctl_p2_cmd_empty ),
    .i_ddr2_cmd_full            ( ddr_ctl_p2_cmd_full ),
    .o_ddr2_wr_en               ( ddr_ctl_p2_wr_en ),
    .o_ddr2_wr_data             ( ddr_ctl_p2_wr_data ),
    .o_ddr2_wr_mask             ( ddr_ctl_p2_wr_mask ),
    .i_ddr2_wr_almost_full      ( ddr_ctl_p2_wr_almost_full ),
    .o_ddr2_rd_en               ( ddr_ctl_p2_rd_en ),
    .i_ddr2_rd_data             ( ddr_ctl_p2_rd_data ),
    .i_ddr2_rd_empty            ( ddr_ctl_p2_rd_empty ),

    // DDR controller port #3
    .o_ddr3_cmd_en              ( ddr_ctl_p3_cmd_en ),
    .o_ddr3_cmd_instr           ( ddr_ctl_p3_cmd_instr ),
    .o_ddr3_cmd_bl              ( ddr_ctl_p3_cmd_bl ),
    .o_ddr3_cmd_byte_addr       ( ddr_ctl_p3_cmd_byte_addr ),
    .i_ddr3_cmd_empty           ( ddr_ctl_p3_cmd_empty ),
    .i_ddr3_cmd_full            ( ddr_ctl_p3_cmd_full ),
    .o_ddr3_wr_en               ( ddr_ctl_p3_wr_en ),
    .o_ddr3_wr_data             ( ddr_ctl_p3_wr_data ),
    .o_ddr3_wr_mask             ( ddr_ctl_p3_wr_mask ),
    .i_ddr3_wr_almost_full      ( ddr_ctl_p3_wr_almost_full ),
    .o_ddr3_rd_en               ( ddr_ctl_p3_rd_en ),
    .i_ddr3_rd_data             ( ddr_ctl_p3_rd_data ),
    .i_ddr3_rd_empty            ( ddr_ctl_p3_rd_empty )
  );



  // ==========================================================================
  // Board controller
  // ==========================================================================
  formic_bctl i0_formic_bctl (

    // Clocks and resets
    .clk_xbar                   ( clk_xbar ),
    .clk_ddr                    ( clk_ddr ),
    .clk_ni                     ( clk_ni ),
    .clk_mc                     ( clk_mc ),
    .clk_cpu                    ( clk_cpu ),
    .rst_xbar                   ( rst_xbar ),
    .rst_ddr                    ( rst_ddr ),
    .rst_ni                     ( rst_ni ),
    .rst_mc                     ( rst_mc ),

    // Static configuration
    .i_board_id                 ( board_id_q ),
    .i_dip_sw                   ( dip_sw[11:8] ),

    // Reset Management Interface (asynchronous)
    .i_ddr_boot_req             ( bctl_boot_req ),
    .o_ddr_boot_done            ( bctl_boot_done ),
    .o_rst_soft                 ( bctl_rst_soft ),
    .o_rst_hard                 ( bctl_rst_hard ),

    // LEDs
    .o_led                      ( led ),

    // GTP Interface (asynchronus)
    .i_gtp_link_up              ( 8'b0 ),
    .i_gtp_link_error           ( 8'b0 ),
    .i_gtp_credit_error         ( 8'b0 ),
    .i_gtp_crc_error            ( 8'b0 ),

    // TLB maintenance interface (clk_ddr)
    .o_tlb_enabled              ( bctl_tlb_enabled ),
    .o_tlb_maint_cmd            ( bctl_tlb_maint_cmd ),
    .o_tlb_maint_wr_en          ( bctl_tlb_maint_wr_en ),
    .o_tlb_virt_adr             ( bctl_tlb_virt_adr ),
    .o_tlb_phys_adr             ( bctl_tlb_phys_adr ),
    .o_tlb_entry_valid          ( bctl_tlb_entry_valid ),
    .i_tlb_phys_adr             ( bctl_tlb_resp_phys_adr ),
    .i_tlb_entry_valid          ( bctl_tlb_resp_entry_valid ),
    .i_tlb_drop                 ( bctl_tlb_drop ),

    // DDR controller error monitoring (clk_ddr)
    .i_ddr_p0_error             ( ddr_ctl_p0_error ),
    .i_ddr_p1_error             ( ddr_ctl_p1_error ),
    .i_ddr_p2_error             ( ddr_ctl_p2_error ),
    .i_ddr_p3_error             ( ddr_ctl_p3_error ),

    // I2C Slave Interface (clk_mc)
    .i_i2c_miss_valid           ( bctl_i2c_miss_valid ),
    .i_i2c_miss_addr            ( bctl_i2c_miss_adr ),
    .i_i2c_miss_flags           ( bctl_i2c_miss_flags ),
    .i_i2c_miss_wen             ( bctl_i2c_miss_wen ),
    .i_i2c_miss_ben             ( bctl_i2c_miss_ben ),
    .i_i2c_miss_wdata           ( bctl_i2c_miss_wdata ),
    .o_i2c_miss_stall           ( bctl_l2c_miss_stall ),
    .o_i2c_fill_valid           ( bctl_i2c_fill_valid ),
    .o_i2c_fill_data            ( bctl_i2c_fill_data ),
    .i_i2c_fill_stall           ( bctl_i2c_fill_stall ),

    // UART Interface (clk_xbar and clk_ni)
    .o_uart_enq                 ( bctl_uart_enq ),
    .o_uart_enq_data            ( bctl_uart_enq_data ),
    .i_uart_tx_words            ( bctl_uart_tx_words ),
    .i_uart_tx_full             ( bctl_uart_tx_full ),
    .o_uart_deq                 ( bctl_uart_deq ),
    .i_uart_deq_data            ( bctl_uart_deq_data ),
    .i_uart_rx_words            ( bctl_uart_rx_words ),
    .i_uart_rx_empty            ( bctl_uart_rx_empty ),
    .i_uart_byte_rcv            ( bctl_uart_byte_rcv ),

    // MBS UART & Timer Interface (clk_cpu)
    .o_mbs_uart_irq             ( bctl_uart_irq ),
    .i_mbs_uart_irq_clear       ( bctl_uart_irq_clear ),
    .o_mbs_drift_fw             ( bctl_tmr_drift_fw ),
    .o_mbs_drift_bw             ( bctl_tmr_drift_bw ),

    // MBS Load Status interface (clk_ni)
    .i_mbs0_status              ( mbs0_bctl_load_status ),
    .i_mbs1_status              ( mbs1_bctl_load_status ),
    .i_mbs2_status              ( mbs2_bctl_load_status ),
    .i_mbs3_status              ( mbs3_bctl_load_status ),
    .i_mbs4_status              ( mbs4_bctl_load_status ),
    .i_mbs5_status              ( mbs5_bctl_load_status ),
    .i_mbs6_status              ( mbs6_bctl_load_status ),
    .i_mbs7_status              ( mbs7_bctl_load_status ),

     // MBS Trace Interface (clk_ni)
    .i_mbs0_trc_valid           ( mbs0_bctl_trc_valid ),
    .i_mbs0_trc_data            ( mbs0_bctl_trc_data ),
    .i_mbs1_trc_valid           ( mbs1_bctl_trc_valid ),
    .i_mbs1_trc_data            ( mbs1_bctl_trc_data ),
    .i_mbs2_trc_valid           ( mbs2_bctl_trc_valid ),
    .i_mbs2_trc_data            ( mbs2_bctl_trc_data ),
    .i_mbs3_trc_valid           ( mbs3_bctl_trc_valid ),
    .i_mbs3_trc_data            ( mbs3_bctl_trc_data ),
    .i_mbs4_trc_valid           ( mbs4_bctl_trc_valid ),
    .i_mbs4_trc_data            ( mbs4_bctl_trc_data ),
    .i_mbs5_trc_valid           ( mbs5_bctl_trc_valid ),
    .i_mbs5_trc_data            ( mbs5_bctl_trc_data ),
    .i_mbs6_trc_valid           ( mbs6_bctl_trc_valid ),
    .i_mbs6_trc_data            ( mbs6_bctl_trc_data ),
    .i_mbs7_trc_valid           ( mbs7_bctl_trc_valid ),
    .i_mbs7_trc_data            ( mbs7_bctl_trc_data ),

    // Crossbar interface (clk_xbar)
    .i_xbar_out_enq             ( xbar21_out_enq ),
    .i_xbar_out_offset          ( xbar21_out_offset ),
    .i_xbar_out_eop             ( xbar21_out_eop ),
    .i_xbar_out_data            ( xbar21_out_data ),
    .o_xbar_out_full            ( xbar21_out_full ),
    .o_xbar_out_packets_vc0     ( xbar21_out_packets_vc0 ),
    .o_xbar_out_packets_vc1     ( xbar21_out_packets_vc1 ),
    .o_xbar_out_packets_vc2     ( xbar21_out_packets_vc2 ),
    .i_xbar_in_deq              ( xbar21_in_deq ),
    .i_xbar_in_offset           ( xbar21_in_offset ),
    .i_xbar_in_eop              ( xbar21_in_eop ),
    .o_xbar_in_data             ( xbar21_in_data ),
    .o_xbar_in_empty            ( xbar21_in_empty )
  );


  // ==========================================================================
  // UART
  // ==========================================================================
  uart i0_uart (
    .clk_cpu                    ( clk_cpu ),
    .clk_ni                     ( clk_ni ),
    .rst_ni                     ( rst_ni ),
    .clk_xbar                   ( clk_xbar ),
    .rst_xbar                   ( rst_xbar ),
    .i_ddr_boot_done            ( bctl_boot_done ),

    // UART Interface (clk_cpu)
    .i_uart_enq                 ( bctl_uart_enq ), 
    .i_uart_enq_data            ( bctl_uart_enq_data ),
    .o_uart_tx_words            ( bctl_uart_tx_words ),
    .o_uart_tx_full             ( bctl_uart_tx_full ),
    .i_uart_deq                 ( bctl_uart_deq ),
    .o_uart_deq_data            ( bctl_uart_deq_data ),
    .o_uart_rx_words            ( bctl_uart_rx_words ),
    .o_uart_rx_empty            ( bctl_uart_rx_empty ),
    .o_uart_byte_rcv            ( bctl_uart_byte_rcv ),

    // Serial Interface
    .i_RX                       ( uart_rx ),
    .o_TX                       ( uart_tx )
  );


  // ==========================================================================
  // I2C
  // ==========================================================================
  i2c_slave i0_i2c_slave (
     .i_board_id                ( board_id_q[6:0] ),
     .Clk                       ( clk_mc ),
     .Reset                     ( rst_mc ),

     .o_i2c_miss_valid          ( bctl_i2c_miss_valid ),
     .o_i2c_miss_adr            ( bctl_i2c_miss_adr ),
     .o_i2c_miss_flags          ( bctl_i2c_miss_flags ),
     .o_i2c_miss_wen            ( bctl_i2c_miss_wen ),
     .o_i2c_miss_ben            ( bctl_i2c_miss_ben ),
     .o_i2c_miss_wdata          ( bctl_i2c_miss_wdata ),
     .i_l2c_miss_stall          ( bctl_l2c_miss_stall ),

     .i_i2c_fill_valid          ( bctl_i2c_fill_valid ),
     .i_i2c_fill_data           ( bctl_i2c_fill_data ),
     .o_i2c_fill_stall          ( bctl_i2c_fill_stall ),

     .SCL                       ( i2c_scl ),
     .SDA                       ( i2c_sda )
  );
  

  // ==========================================================================
  // Microblaze debug module
  // ==========================================================================
  generate
    if (`SYNTH_NEED_DEBUG == 1) begin

      xil_mdm i0_xil_mdm (
        .clk_cpu                    ( clk_cpu ),
        .rst_mc                     ( rst_mc ),
        .i_boot_done                ( bctl_boot_done ),

        .o_ext_brk                  ( mdm_brk ),
        .o_ext_nm_brk               ( mdm_nm_brk ),
        .o_sys_reset                ( mdm_sys_reset ),

        .o_mbs0_clk                 ( mdm0_clk ),
        .o_mbs0_tdi                 ( mdm0_tdi ),
        .i_mbs0_tdo                 ( mdm0_tdo ),
        .o_mbs0_reg_en              ( mdm0_reg_en ),
        .o_mbs0_shift               ( mdm0_shift ),
        .o_mbs0_capture             ( mdm0_capture ),
        .o_mbs0_update              ( mdm0_update ),
        .o_mbs0_reset               ( mdm0_reset ),

        .o_mbs1_clk                 ( mdm1_clk ),
        .o_mbs1_tdi                 ( mdm1_tdi ),
        .i_mbs1_tdo                 ( mdm1_tdo ),
        .o_mbs1_reg_en              ( mdm1_reg_en ),
        .o_mbs1_shift               ( mdm1_shift ),
        .o_mbs1_capture             ( mdm1_capture ),
        .o_mbs1_update              ( mdm1_update ),
        .o_mbs1_reset               ( mdm1_reset ),

        .o_mbs2_clk                 ( mdm2_clk ),
        .o_mbs2_tdi                 ( mdm2_tdi ),
        .i_mbs2_tdo                 ( mdm2_tdo ),
        .o_mbs2_reg_en              ( mdm2_reg_en ),
        .o_mbs2_shift               ( mdm2_shift ),
        .o_mbs2_capture             ( mdm2_capture ),
        .o_mbs2_update              ( mdm2_update ),
        .o_mbs2_reset               ( mdm2_reset ),

        .o_mbs3_clk                 ( mdm3_clk ),
        .o_mbs3_tdi                 ( mdm3_tdi ),
        .i_mbs3_tdo                 ( mdm3_tdo ),
        .o_mbs3_reg_en              ( mdm3_reg_en ),
        .o_mbs3_shift               ( mdm3_shift ),
        .o_mbs3_capture             ( mdm3_capture ),
        .o_mbs3_update              ( mdm3_update ),
        .o_mbs3_reset               ( mdm3_reset ),

        .o_mbs4_clk                 ( mdm4_clk ),
        .o_mbs4_tdi                 ( mdm4_tdi ),
        .i_mbs4_tdo                 ( mdm4_tdo ),
        .o_mbs4_reg_en              ( mdm4_reg_en ),
        .o_mbs4_shift               ( mdm4_shift ),
        .o_mbs4_capture             ( mdm4_capture ),
        .o_mbs4_update              ( mdm4_update ),
        .o_mbs4_reset               ( mdm4_reset ),

        .o_mbs5_clk                 ( mdm5_clk ),
        .o_mbs5_tdi                 ( mdm5_tdi ),
        .i_mbs5_tdo                 ( mdm5_tdo ),
        .o_mbs5_reg_en              ( mdm5_reg_en ),
        .o_mbs5_shift               ( mdm5_shift ),
        .o_mbs5_capture             ( mdm5_capture ),
        .o_mbs5_update              ( mdm5_update ),
        .o_mbs5_reset               ( mdm5_reset ),

        .o_mbs6_clk                 ( mdm6_clk ),
        .o_mbs6_tdi                 ( mdm6_tdi ),
        .i_mbs6_tdo                 ( mdm6_tdo ),
        .o_mbs6_reg_en              ( mdm6_reg_en ),
        .o_mbs6_shift               ( mdm6_shift ),
        .o_mbs6_capture             ( mdm6_capture ),
        .o_mbs6_update              ( mdm6_update ),
        .o_mbs6_reset               ( mdm6_reset ),

        .o_mbs7_clk                 ( mdm7_clk ),
        .o_mbs7_tdi                 ( mdm7_tdi ),
        .i_mbs7_tdo                 ( mdm7_tdo ),
        .o_mbs7_reg_en              ( mdm7_reg_en ),
        .o_mbs7_shift               ( mdm7_shift ),
        .o_mbs7_capture             ( mdm7_capture ),
        .o_mbs7_update              ( mdm7_update ),
        .o_mbs7_reset               ( mdm7_reset )
      );
    end
    else begin
      assign mdm_brk        = 1'b0;
      assign mdm_nm_brk     = 1'b0;
      assign mdm_sys_reset  = 1'b0;
      assign mdm0_clk       = 1'b0;
      assign mdm0_tdi       = 1'b0;
      assign mdm0_reg_en    = 8'b0;
      assign mdm0_shift     = 1'b0;
      assign mdm0_capture   = 1'b0;
      assign mdm0_update    = 1'b0;
      assign mdm0_reset     = 1'b0;
      assign mdm1_clk       = 1'b0;
      assign mdm1_tdi       = 1'b0;
      assign mdm1_reg_en    = 8'b0;
      assign mdm1_shift     = 1'b0;
      assign mdm1_capture   = 1'b0;
      assign mdm1_update    = 1'b0;
      assign mdm1_reset     = 1'b0;
      assign mdm2_clk       = 1'b0;
      assign mdm2_tdi       = 1'b0;
      assign mdm2_reg_en    = 8'b0;
      assign mdm2_shift     = 1'b0;
      assign mdm2_capture   = 1'b0;
      assign mdm2_update    = 1'b0;
      assign mdm2_reset     = 1'b0;
      assign mdm3_clk       = 1'b0;
      assign mdm3_tdi       = 1'b0;
      assign mdm3_reg_en    = 8'b0;
      assign mdm3_shift     = 1'b0;
      assign mdm3_capture   = 1'b0;
      assign mdm3_update    = 1'b0;
      assign mdm3_reset     = 1'b0;
      assign mdm4_clk       = 1'b0;
      assign mdm4_tdi       = 1'b0;
      assign mdm4_reg_en    = 8'b0;
      assign mdm4_shift     = 1'b0;
      assign mdm4_capture   = 1'b0;
      assign mdm4_update    = 1'b0;
      assign mdm4_reset     = 1'b0;
      assign mdm5_clk       = 1'b0;
      assign mdm5_tdi       = 1'b0;
      assign mdm5_reg_en    = 8'b0;
      assign mdm5_shift     = 1'b0;
      assign mdm5_capture   = 1'b0;
      assign mdm5_update    = 1'b0;
      assign mdm5_reset     = 1'b0;
      assign mdm6_clk       = 1'b0;
      assign mdm6_tdi       = 1'b0;
      assign mdm6_reg_en    = 8'b0;
      assign mdm6_shift     = 1'b0;
      assign mdm6_capture   = 1'b0;
      assign mdm6_update    = 1'b0;
      assign mdm6_reset     = 1'b0;
      assign mdm7_clk       = 1'b0;
      assign mdm7_tdi       = 1'b0;
      assign mdm7_reg_en    = 8'b0;
      assign mdm7_shift     = 1'b0;
      assign mdm7_capture   = 1'b0;
      assign mdm7_update    = 1'b0;
      assign mdm7_reset     = 1'b0;
    end
  endgenerate




  // ==========================================================================
  // Crossbar
  // ==========================================================================
  xbar_formic_m8 i0_xbar_formic_m8 (
    
    // Clock and reset
    .clk_xbar                   ( clk_xbar ),
    .rst_xbar                   ( rst_xbar ),

    // Static configuration
    .i_board_id                 ( board_id_q ),

    // Port #00 interface
    .o_port00_out_enq           ( xbar00_out_enq ),
    .o_port00_out_offset        ( xbar00_out_offset ),
    .o_port00_out_eop           ( xbar00_out_eop ),
    .o_port00_out_data          ( xbar00_out_data ),
    .i_port00_out_full          ( xbar00_out_full ),
    .i_port00_out_packets_vc0   ( xbar00_out_packets_vc0 ),
    .i_port00_out_packets_vc1   ( xbar00_out_packets_vc1 ),
    .i_port00_out_packets_vc2   ( xbar00_out_packets_vc2 ),
    .o_port00_in_deq            ( xbar00_in_deq ),
    .o_port00_in_offset         ( xbar00_in_offset ),
    .o_port00_in_eop            ( xbar00_in_eop ),
    .i_port00_in_data           ( xbar00_in_data ),
    .i_port00_in_empty          ( xbar00_in_empty ),

    // Port #01 interface
    .o_port01_out_enq           ( xbar01_out_enq ),
    .o_port01_out_offset        ( xbar01_out_offset ),
    .o_port01_out_eop           ( xbar01_out_eop ),
    .o_port01_out_data          ( xbar01_out_data ),
    .i_port01_out_full          ( xbar01_out_full ),
    .i_port01_out_packets_vc0   ( xbar01_out_packets_vc0 ),
    .i_port01_out_packets_vc1   ( xbar01_out_packets_vc1 ),
    .i_port01_out_packets_vc2   ( xbar01_out_packets_vc2 ),
    .o_port01_in_deq            ( xbar01_in_deq ),
    .o_port01_in_offset         ( xbar01_in_offset ),
    .o_port01_in_eop            ( xbar01_in_eop ),
    .i_port01_in_data           ( xbar01_in_data ),
    .i_port01_in_empty          ( xbar01_in_empty ),

    // Port #02 interface
    .o_port02_out_enq           ( xbar02_out_enq ),
    .o_port02_out_offset        ( xbar02_out_offset ),
    .o_port02_out_eop           ( xbar02_out_eop ),
    .o_port02_out_data          ( xbar02_out_data ),
    .i_port02_out_full          ( xbar02_out_full ),
    .i_port02_out_packets_vc0   ( xbar02_out_packets_vc0 ),
    .i_port02_out_packets_vc1   ( xbar02_out_packets_vc1 ),
    .i_port02_out_packets_vc2   ( xbar02_out_packets_vc2 ),
    .o_port02_in_deq            ( xbar02_in_deq ),
    .o_port02_in_offset         ( xbar02_in_offset ),
    .o_port02_in_eop            ( xbar02_in_eop ),
    .i_port02_in_data           ( xbar02_in_data ),
    .i_port02_in_empty          ( xbar02_in_empty ),

    // Port #03 interface
    .o_port03_out_enq           ( xbar03_out_enq ),
    .o_port03_out_offset        ( xbar03_out_offset ),
    .o_port03_out_eop           ( xbar03_out_eop ),
    .o_port03_out_data          ( xbar03_out_data ),
    .i_port03_out_full          ( xbar03_out_full ),
    .i_port03_out_packets_vc0   ( xbar03_out_packets_vc0 ),
    .i_port03_out_packets_vc1   ( xbar03_out_packets_vc1 ),
    .i_port03_out_packets_vc2   ( xbar03_out_packets_vc2 ),
    .o_port03_in_deq            ( xbar03_in_deq ),
    .o_port03_in_offset         ( xbar03_in_offset ),
    .o_port03_in_eop            ( xbar03_in_eop ),
    .i_port03_in_data           ( xbar03_in_data ),
    .i_port03_in_empty          ( xbar03_in_empty ),

    // Port #04 interface
    .o_port04_out_enq           ( xbar04_out_enq ),
    .o_port04_out_offset        ( xbar04_out_offset ),
    .o_port04_out_eop           ( xbar04_out_eop ),
    .o_port04_out_data          ( xbar04_out_data ),
    .i_port04_out_full          ( xbar04_out_full ),
    .i_port04_out_packets_vc0   ( xbar04_out_packets_vc0 ),
    .i_port04_out_packets_vc1   ( xbar04_out_packets_vc1 ),
    .i_port04_out_packets_vc2   ( xbar04_out_packets_vc2 ),
    .o_port04_in_deq            ( xbar04_in_deq ),
    .o_port04_in_offset         ( xbar04_in_offset ),
    .o_port04_in_eop            ( xbar04_in_eop ),
    .i_port04_in_data           ( xbar04_in_data ),
    .i_port04_in_empty          ( xbar04_in_empty ),

    // Port #05 interface
    .o_port05_out_enq           ( xbar05_out_enq ),
    .o_port05_out_offset        ( xbar05_out_offset ),
    .o_port05_out_eop           ( xbar05_out_eop ),
    .o_port05_out_data          ( xbar05_out_data ),
    .i_port05_out_full          ( xbar05_out_full ),
    .i_port05_out_packets_vc0   ( xbar05_out_packets_vc0 ),
    .i_port05_out_packets_vc1   ( xbar05_out_packets_vc1 ),
    .i_port05_out_packets_vc2   ( xbar05_out_packets_vc2 ),
    .o_port05_in_deq            ( xbar05_in_deq ),
    .o_port05_in_offset         ( xbar05_in_offset ),
    .o_port05_in_eop            ( xbar05_in_eop ),
    .i_port05_in_data           ( xbar05_in_data ),
    .i_port05_in_empty          ( xbar05_in_empty ),

    // Port #06 interface
    .o_port06_out_enq           ( xbar06_out_enq ),
    .o_port06_out_offset        ( xbar06_out_offset ),
    .o_port06_out_eop           ( xbar06_out_eop ),
    .o_port06_out_data          ( xbar06_out_data ),
    .i_port06_out_full          ( xbar06_out_full ),
    .i_port06_out_packets_vc0   ( xbar06_out_packets_vc0 ),
    .i_port06_out_packets_vc1   ( xbar06_out_packets_vc1 ),
    .i_port06_out_packets_vc2   ( xbar06_out_packets_vc2 ),
    .o_port06_in_deq            ( xbar06_in_deq ),
    .o_port06_in_offset         ( xbar06_in_offset ),
    .o_port06_in_eop            ( xbar06_in_eop ),
    .i_port06_in_data           ( xbar06_in_data ),
    .i_port06_in_empty          ( xbar06_in_empty ),

    // Port #07 interface
    .o_port07_out_enq           ( xbar07_out_enq ),
    .o_port07_out_offset        ( xbar07_out_offset ),
    .o_port07_out_eop           ( xbar07_out_eop ),
    .o_port07_out_data          ( xbar07_out_data ),
    .i_port07_out_full          ( xbar07_out_full ),
    .i_port07_out_packets_vc0   ( xbar07_out_packets_vc0 ),
    .i_port07_out_packets_vc1   ( xbar07_out_packets_vc1 ),
    .i_port07_out_packets_vc2   ( xbar07_out_packets_vc2 ),
    .o_port07_in_deq            ( xbar07_in_deq ),
    .o_port07_in_offset         ( xbar07_in_offset ),
    .o_port07_in_eop            ( xbar07_in_eop ),
    .i_port07_in_data           ( xbar07_in_data ),
    .i_port07_in_empty          ( xbar07_in_empty ),

    // Port #16 interface
    .o_port16_out_enq           ( xbar16_out_enq ),
    .o_port16_out_offset        ( xbar16_out_offset ),
    .o_port16_out_eop           ( xbar16_out_eop ),
    .o_port16_out_data          ( xbar16_out_data ),
    .i_port16_out_full          ( xbar16_out_full ),
    .i_port16_out_packets_vc0   ( xbar16_out_packets_vc0 ),
    .i_port16_out_packets_vc1   ( xbar16_out_packets_vc1 ),
    .i_port16_out_packets_vc2   ( xbar16_out_packets_vc2 ),
    .o_port16_in_deq            ( xbar16_in_deq ),
    .o_port16_in_offset         ( xbar16_in_offset ),
    .o_port16_in_eop            ( xbar16_in_eop ),
    .i_port16_in_data           ( xbar16_in_data ),
    .i_port16_in_empty          ( xbar16_in_empty ),

    // Port #17 interface
    .o_port17_out_enq           ( xbar17_out_enq ),
    .o_port17_out_offset        ( xbar17_out_offset ),
    .o_port17_out_eop           ( xbar17_out_eop ),
    .o_port17_out_data          ( xbar17_out_data ),
    .i_port17_out_full          ( xbar17_out_full ),
    .i_port17_out_packets_vc0   ( xbar17_out_packets_vc0 ),
    .i_port17_out_packets_vc1   ( xbar17_out_packets_vc1 ),
    .i_port17_out_packets_vc2   ( xbar17_out_packets_vc2 ),
    .o_port17_in_deq            ( xbar17_in_deq ),
    .o_port17_in_offset         ( xbar17_in_offset ),
    .o_port17_in_eop            ( xbar17_in_eop ),
    .i_port17_in_data           ( xbar17_in_data ),
    .i_port17_in_empty          ( xbar17_in_empty ),

    // Port #18 interface
    .o_port18_out_enq           ( xbar18_out_enq ),
    .o_port18_out_offset        ( xbar18_out_offset ),
    .o_port18_out_eop           ( xbar18_out_eop ),
    .o_port18_out_data          ( xbar18_out_data ),
    .i_port18_out_full          ( xbar18_out_full ),
    .i_port18_out_packets_vc0   ( xbar18_out_packets_vc0 ),
    .i_port18_out_packets_vc1   ( xbar18_out_packets_vc1 ),
    .i_port18_out_packets_vc2   ( xbar18_out_packets_vc2 ),
    .o_port18_in_deq            ( xbar18_in_deq ),
    .o_port18_in_offset         ( xbar18_in_offset ),
    .o_port18_in_eop            ( xbar18_in_eop ),
    .i_port18_in_data           ( xbar18_in_data ),
    .i_port18_in_empty          ( xbar18_in_empty ),

    // Port #19 interface
    .o_port19_out_enq           ( xbar19_out_enq ),
    .o_port19_out_offset        ( xbar19_out_offset ),
    .o_port19_out_eop           ( xbar19_out_eop ),
    .o_port19_out_data          ( xbar19_out_data ),
    .i_port19_out_full          ( xbar19_out_full ),
    .i_port19_out_packets_vc0   ( xbar19_out_packets_vc0 ),
    .i_port19_out_packets_vc1   ( xbar19_out_packets_vc1 ),
    .i_port19_out_packets_vc2   ( xbar19_out_packets_vc2 ),
    .o_port19_in_deq            ( xbar19_in_deq ),
    .o_port19_in_offset         ( xbar19_in_offset ),
    .o_port19_in_eop            ( xbar19_in_eop ),
    .i_port19_in_data           ( xbar19_in_data ),
    .i_port19_in_empty          ( xbar19_in_empty ),

    // Port #20 interface
    .o_port20_out_enq           ( xbar20_out_enq ),
    .o_port20_out_offset        ( xbar20_out_offset ),
    .o_port20_out_eop           ( xbar20_out_eop ),
    .o_port20_out_data          ( xbar20_out_data ),
    .i_port20_out_full          ( xbar20_out_full ),
    .i_port20_out_packets_vc0   ( xbar20_out_packets_vc0 ),
    .i_port20_out_packets_vc1   ( xbar20_out_packets_vc1 ),
    .i_port20_out_packets_vc2   ( xbar20_out_packets_vc2 ),
    .o_port20_in_deq            ( xbar20_in_deq ),
    .o_port20_in_offset         ( xbar20_in_offset ),
    .o_port20_in_eop            ( xbar20_in_eop ),
    .i_port20_in_data           ( xbar20_in_data ),
    .i_port20_in_empty          ( xbar20_in_empty ),

    // Port #21 interface
    .o_port21_out_enq           ( xbar21_out_enq ),
    .o_port21_out_offset        ( xbar21_out_offset ),
    .o_port21_out_eop           ( xbar21_out_eop ),
    .o_port21_out_data          ( xbar21_out_data ),
    .i_port21_out_full          ( xbar21_out_full ),
    .i_port21_out_packets_vc0   ( xbar21_out_packets_vc0 ),
    .i_port21_out_packets_vc1   ( xbar21_out_packets_vc1 ),
    .i_port21_out_packets_vc2   ( xbar21_out_packets_vc2 ),
    .o_port21_in_deq            ( xbar21_in_deq ),
    .o_port21_in_offset         ( xbar21_in_offset ),
    .o_port21_in_eop            ( xbar21_in_eop ),
    .i_port21_in_data           ( xbar21_in_data ),
    .i_port21_in_empty          ( xbar21_in_empty )
  );


  // ==========================================================================
  // DDR Controller
  // ==========================================================================

  // Reserved pins
  assign ddr_a[14:13] = 2'b0;
  assign ddr_cs_n = 1'b0;


  // The Xilinx DDR controller
  xil_ddr_ctl # (
    .C5_SIMULATION          ( tb_mode )
  )
  i0_xil_ddr_ctl (

    // System interface
    .clk_800                ( clk_mcb ),
    .clk_800_180            ( clk_mcb_180 ),
    .i_pll_ce_0             ( mcb_ce_0 ),
    .i_pll_ce_90            ( mcb_ce_90 ),
    .clk_drp                ( clk_drp ),
    .rst_master_assert      ( rst_master_assert ),
    .rst_drp_deassert       ( rst_drp_deassert ),
    .i_pll_locked           ( plls_locked ),
    .o_calib_done           ( ddr_ctl_calib_done ),

    // DDR2 interface
    .io_ddr_dq              ( ddr_dq ),
    .o_ddr_a                ( ddr_a[12:0] ),
    .o_ddr_ba               ( ddr_ba ),
    .o_ddr_ras_n            ( ddr_ras_n ),
    .o_ddr_cas_n            ( ddr_cas_n ),
    .o_ddr_we_n             ( ddr_we_n ),
    .o_ddr_odt              ( ddr_odt ),
    .o_ddr_cke              ( ddr_clke ),
    .o_ddr_dm               ( ddr_ldm ),
    .io_ddr_udqs            ( ddr_udqs ),
    .io_ddr_udqs_n          ( ddr_udqs_n ),
    .io_ddr_rzq             ( ddr_rzq ),
    .io_ddr_zio             ( ddr_zio ),
    .o_ddr_udm              ( ddr_udm ),
    .io_ddr_dqs             ( ddr_ldqs ),
    .io_ddr_dqs_n           ( ddr_ldqs_n ),
    .o_ddr_ck               ( ddr_clk ),
    .o_ddr_ck_n             ( ddr_clk_n ),

    // User port 0
    .i_p0_clk               ( clk_ddr ),
    .i_p0_cmd_en            ( ddr_ctl_p0_cmd_en ),
    .i_p0_cmd_instr         ( ddr_ctl_p0_cmd_instr ),
    .i_p0_cmd_bl            ( ddr_ctl_p0_cmd_bl ),
    .i_p0_cmd_byte_addr     ( ddr_ctl_p0_cmd_byte_addr ),
    .o_p0_cmd_empty         ( ddr_ctl_p0_cmd_empty ),
    .o_p0_cmd_full          ( ddr_ctl_p0_cmd_full ),
    .i_p0_wr_en             ( ddr_ctl_p0_wr_en ),
    .i_p0_wr_mask           ( ddr_ctl_p0_wr_mask ),
    .i_p0_wr_data           ( ddr_ctl_p0_wr_data ),
    .o_p0_wr_almost_full    ( ddr_ctl_p0_wr_almost_full ),
    .i_p0_rd_en             ( ddr_ctl_p0_rd_en ),
    .o_p0_rd_data           ( ddr_ctl_p0_rd_data ),
    .o_p0_rd_empty          ( ddr_ctl_p0_rd_empty ),
    .o_p0_error             ( ddr_ctl_p0_error ),

    // User port 1
    .i_p1_clk               ( clk_ddr ),
    .i_p1_cmd_en            ( ddr_ctl_p1_cmd_en ),
    .i_p1_cmd_instr         ( ddr_ctl_p1_cmd_instr ),
    .i_p1_cmd_bl            ( ddr_ctl_p1_cmd_bl ),
    .i_p1_cmd_byte_addr     ( ddr_ctl_p1_cmd_byte_addr ),
    .o_p1_cmd_empty         ( ddr_ctl_p1_cmd_empty ),
    .o_p1_cmd_full          ( ddr_ctl_p1_cmd_full ),
    .i_p1_wr_en             ( ddr_ctl_p1_wr_en ),
    .i_p1_wr_mask           ( ddr_ctl_p1_wr_mask ),
    .i_p1_wr_data           ( ddr_ctl_p1_wr_data ),
    .o_p1_wr_almost_full    ( ddr_ctl_p1_wr_almost_full ),
    .i_p1_rd_en             ( ddr_ctl_p1_rd_en ),
    .o_p1_rd_data           ( ddr_ctl_p1_rd_data ),
    .o_p1_rd_empty          ( ddr_ctl_p1_rd_empty ),
    .o_p1_error             ( ddr_ctl_p1_error ),

    // User port 2
    .i_p2_clk               ( clk_ddr ),
    .i_p2_cmd_en            ( ddr_ctl_p2_cmd_en ),
    .i_p2_cmd_instr         ( ddr_ctl_p2_cmd_instr ),
    .i_p2_cmd_bl            ( ddr_ctl_p2_cmd_bl ),
    .i_p2_cmd_byte_addr     ( ddr_ctl_p2_cmd_byte_addr ),
    .o_p2_cmd_empty         ( ddr_ctl_p2_cmd_empty ),
    .o_p2_cmd_full          ( ddr_ctl_p2_cmd_full ),
    .i_p2_wr_en             ( ddr_ctl_p2_wr_en ),
    .i_p2_wr_mask           ( ddr_ctl_p2_wr_mask ),
    .i_p2_wr_data           ( ddr_ctl_p2_wr_data ),
    .o_p2_wr_almost_full    ( ddr_ctl_p2_wr_almost_full ),
    .i_p2_rd_en             ( ddr_ctl_p2_rd_en ),
    .o_p2_rd_data           ( ddr_ctl_p2_rd_data ),
    .o_p2_rd_empty          ( ddr_ctl_p2_rd_empty ),
    .o_p2_error             ( ddr_ctl_p2_error ),

    // User port 3
    .i_p3_clk               ( clk_ddr ),
    .i_p3_cmd_en            ( ddr_ctl_p3_cmd_en ),
    .i_p3_cmd_instr         ( ddr_ctl_p3_cmd_instr ),
    .i_p3_cmd_bl            ( ddr_ctl_p3_cmd_bl ),
    .i_p3_cmd_byte_addr     ( ddr_ctl_p3_cmd_byte_addr ),
    .o_p3_cmd_empty         ( ddr_ctl_p3_cmd_empty ),
    .o_p3_cmd_full          ( ddr_ctl_p3_cmd_full ),
    .i_p3_wr_en             ( ddr_ctl_p3_wr_en ),
    .i_p3_wr_mask           ( ddr_ctl_p3_wr_mask ),
    .i_p3_wr_data           ( ddr_ctl_p3_wr_data ),
    .o_p3_wr_almost_full    ( ddr_ctl_p3_wr_almost_full ),
    .i_p3_rd_en             ( ddr_ctl_p3_rd_en ),
    .o_p3_rd_data           ( ddr_ctl_p3_rd_data ),
    .o_p3_rd_empty          ( ddr_ctl_p3_rd_empty ),
    .o_p3_error             ( ddr_ctl_p3_error )
  );

/*
  // ==========================================================================
  // Chipscope
  // ==========================================================================
  wire         scope0_clk;
  (* equivalent_register_removal = "no" *)
  reg  [255:0] scope0_data;
  wire  [35:0] scope0_ctl;
  wire         scope1_clk;
  (* equivalent_register_removal = "no" *)
  reg  [255:0] scope1_data;
  wire  [35:0] scope1_ctl;
  wire         scope2_clk;
  (* equivalent_register_removal = "no" *)
  reg   [71:0] scope2_data;
  wire  [35:0] scope2_ctl;
  wire         scope3_clk;
  (* equivalent_register_removal = "no" *)
  reg   [17:0] scope3_data;
  wire  [35:0] scope3_ctl;
  wire         scope4_clk;
  (* equivalent_register_removal = "no" *)
  reg   [17:0] scope4_data;
  wire  [35:0] scope4_ctl;
  wire         scope5_clk;
  (* equivalent_register_removal = "no" *)
  reg   [17:0] scope5_data;
  wire  [35:0] scope5_ctl;
  wire         scope6_clk;
  (* equivalent_register_removal = "no" *)
  reg   [17:0] scope6_data;
  wire  [35:0] scope6_ctl;


  assign scope0_clk = clk_ddr;
  always @(posedge scope0_clk)
    scope0_data = { 
      // mbs0_sram1_req_adr,       // 255-238
      // mbs0_sram1_req_we,        // 237
      // mbs0_sram1_req_wdata,     // 236-205
      // mbs0_sram1_req_be,        // 204-201
      // mbs0_sram1_req_valid,     // 200
      // mbs0_sram1_resp_rdata,    // 199-168
      // mbs0_sram1_resp_valid,    // 167
      // xbar00_out_enq,           // 166-164
      // xbar00_out_offset,        // 163-156
      // xbar00_out_eop,           // 155
      // xbar00_out_data,          // 154-139
      // xbar00_out_full,          // 138-136
      // xbar00_out_packets_vc0,   // 135-133
      // xbar00_out_packets_vc1,   // 132-130
      // xbar00_out_packets_vc2,   // 129-127
      // xbar00_in_deq,            // 126-124
      // xbar00_in_offset,         // 123-116
      // xbar00_in_eop,            // 115
      // xbar00_in_data,           // 114-99
      // xbar00_in_empty,          // 98-96
      // 96'b0
      ddr_ctl_p0_cmd_en,          // 255
      ddr_ctl_p0_cmd_instr,       // 254-252
      ddr_ctl_p0_cmd_bl,          // 251-246
      ddr_ctl_p0_cmd_byte_addr,   // 245-216
      ddr_ctl_p0_cmd_empty,       // 215
      ddr_ctl_p0_cmd_full,        // 214
      ddr_ctl_p0_wr_en,           // 213
      ddr_ctl_p0_wr_data,         // 212-181
      ddr_ctl_p0_wr_almost_full,  // 180
      ddr_ctl_p0_rd_en,           // 179
      ddr_ctl_p0_rd_data,         // 178-147
      ddr_ctl_p0_rd_empty,        // 146
      ddr_ctl_p0_error,           // 145

      ddr_ctl_p1_cmd_en,          // 144
      ddr_ctl_p1_cmd_instr,       // 143-141
      ddr_ctl_p1_cmd_bl,          // 140-135
      ddr_ctl_p1_cmd_byte_addr,   // 134-105
      ddr_ctl_p1_cmd_empty,       // 104
      ddr_ctl_p1_cmd_full,        // 103
      ddr_ctl_p1_wr_en,           // 102
      ddr_ctl_p1_wr_data,         // 101-70
      ddr_ctl_p1_wr_almost_full,  // 69
      ddr_ctl_p1_rd_en,           // 68
      ddr_ctl_p1_rd_data,         // 67-36
      ddr_ctl_p1_rd_empty,        // 35
      ddr_ctl_p1_error,           // 34

      34'b0
    };
  
  assign scope1_clk = clk_ddr;
  always @(posedge scope1_clk)
    scope1_data = { 
      ddr_ctl_p2_cmd_en,          // 255
      ddr_ctl_p2_cmd_instr,       // 254-252
      ddr_ctl_p2_cmd_bl,          // 251-246
      ddr_ctl_p2_cmd_byte_addr,   // 245-216
      ddr_ctl_p2_cmd_empty,       // 215
      ddr_ctl_p2_cmd_full,        // 214
      ddr_ctl_p2_wr_en,           // 213
      ddr_ctl_p2_wr_data,         // 212-181
      ddr_ctl_p2_wr_almost_full,  // 180
      ddr_ctl_p2_rd_en,           // 179
      ddr_ctl_p2_rd_data,         // 178-147
      ddr_ctl_p2_rd_empty,        // 146
      ddr_ctl_p2_error,           // 145

      ddr_ctl_p3_cmd_en,          // 144
      ddr_ctl_p3_cmd_instr,       // 143-141
      ddr_ctl_p3_cmd_bl,          // 140-135
      ddr_ctl_p3_cmd_byte_addr,   // 134-105
      ddr_ctl_p3_cmd_empty,       // 104
      ddr_ctl_p3_cmd_full,        // 103
      ddr_ctl_p3_wr_en,           // 102
      ddr_ctl_p3_wr_data,         // 101-70
      ddr_ctl_p3_wr_almost_full,  // 69
      ddr_ctl_p3_rd_en,           // 68
      ddr_ctl_p3_rd_data,         // 67-36
      ddr_ctl_p3_rd_empty,        // 35
      ddr_ctl_p3_error,           // 34

      34'b0
    };

  assign scope2_clk = clk_mc;
  always @(posedge scope2_clk)
    scope2_data = { 
      72'b0
    };

  assign scope3_clk = clk_cpu;
  always @(posedge scope3_clk)
    scope3_data = { 
      18'b0
    };

  assign scope4_clk = clk_cpu;
  always @(posedge scope4_clk)
    scope4_data = { 
      18'b0
    };

  assign scope5_clk = clk_cpu;
  always @(posedge scope5_clk)
    scope5_data = { 
      18'b0
    };

  assign scope6_clk = clk_cpu;
  always @(posedge scope6_clk)
    scope6_data = { 
      //plls_locked,          // 17
      //dig_dcms_locked,      // 16
      //ddr_ctl_calib_done,   // 15
      //bctl_boot_done,       // 14
      //rst_plls,             // 13
      //rst_dig_dcms,         // 12
      //rst_mc,               // 11
      //rst_ni,               // 10
      //rst_ddr,              // 9
      //rst_xbar,             // 8
      //rst_master_assert,    // 7
      //rst_drp_deassert,     // 6
      //rst_sram_deassert,    // 5
      //5'b0
      18'b0
    };


  chipscope_ila256 i0_chipscope_ila (
    .CLK                    ( scope0_clk ),
    .TRIG0                  ( scope0_data ),
    .CONTROL                ( scope0_ctl )
  );

  chipscope_ila256 i1_chipscope_ila (
    .CLK                    ( scope1_clk ),
    .TRIG0                  ( scope1_data ),
    .CONTROL                ( scope1_ctl )
  );

  chipscope_ila72 i2_chipscope_ila (
    .CLK                    ( scope2_clk ),
    .TRIG0                  ( scope2_data ),
    .CONTROL                ( scope2_ctl )
  );

  chipscope_ila18 i3_chipscope_ila (
    .CLK                    ( scope3_clk ),
    .TRIG0                  ( scope3_data ),
    .CONTROL                ( scope3_ctl )
  );

  chipscope_ila18 i4_chipscope_ila (
    .CLK                    ( scope4_clk ),
    .TRIG0                  ( scope4_data ),
    .CONTROL                ( scope4_ctl )
  );

  chipscope_ila18 i5_chipscope_ila (
    .CLK                    ( scope5_clk ),
    .TRIG0                  ( scope5_data ),
    .CONTROL                ( scope5_ctl )
  );

  chipscope_ila18 i6_chipscope_ila (
    .CLK                    ( scope6_clk ),
    .TRIG0                  ( scope6_data ),
    .CONTROL                ( scope6_ctl )
  );


  chipscope_icon i0_chipscope_icon (
    .CONTROL0               ( scope0_ctl ),
    .CONTROL1               ( scope1_ctl ),
    .CONTROL2               ( scope2_ctl ),
    .CONTROL3               ( scope3_ctl ),
    .CONTROL4               ( scope4_ctl ),
    .CONTROL5               ( scope5_ctl ),
    .CONTROL6               ( scope6_ctl )
  );
*/
  // ==========================================================================
  // Tied signals
  // ==========================================================================
  assign sram0_dq      = 0;
  assign sram0_dqp     = 0;
  assign sram0_a       = 0;
  assign sram0_adv     = 0;
  assign sram0_bw_n    = 0;
  assign sram0_we_n    = 0;
  assign sram0_clke_n  = 1'b1;
  assign sram0_cs_n    = 1'b1;
  assign sram0_clk     = 1'b0;

  assign sata0_tx_n    = 1'b0;
  assign sata0_tx_p    = 1'b0;
  assign sata1_tx_n    = 1'b0;
  assign sata1_tx_p    = 1'b0;
  assign sata2_tx_n    = 1'b0;
  assign sata2_tx_p    = 1'b0;
  assign sata3_tx_n    = 1'b0;
  assign sata3_tx_p    = 1'b0;
  assign sata4_tx_n    = 1'b0;
  assign sata4_tx_p    = 1'b0;
  assign sata5_tx_n    = 1'b0;
  assign sata5_tx_p    = 1'b0;
  assign sata6_tx_n    = 1'b0;
  assign sata6_tx_p    = 1'b0;
  assign sata7_tx_n    = 1'b0;
  assign sata7_tx_p    = 1'b0;


  // ==========================================================================
  // Extra registers
  // ==========================================================================
  always @(posedge clk_cpu)
    board_id_q <= dip_sw[7:0];
  
endmodule

