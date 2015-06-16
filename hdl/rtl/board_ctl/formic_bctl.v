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
// Author        : George Kalokerinos
// Abstract      : Formic Board Controller (BCTL) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: formic_bctl.v,v $
// CVS revision  : $Revision: 1.25 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
module formic_bctl (
   // Clocks and resets
   input         clk_xbar,
   input         clk_ddr,
   input         clk_ni,
   input         clk_mc,
   input         clk_cpu,
   input         rst_xbar,
   input         rst_ddr,
   input         rst_ni,
   input         rst_mc,
   // Static configuration
   input  [ 7:0] i_board_id,
   input  [ 3:0] i_dip_sw,
   // Reset Management Interface (asynchronous)
   input         i_ddr_boot_req,
   output        o_ddr_boot_done,
   output        o_rst_soft,
   output        o_rst_hard,
   // LEDs
   output [11:0] o_led,
   // GTP Interface (asynchronous)
   input  [ 7:0] i_gtp_link_up,
   input  [ 7:0] i_gtp_link_error,
   input  [ 7:0] i_gtp_credit_error,
   input  [ 7:0] i_gtp_crc_error,
   // TLB Maintenance Interface (clk_ddr)
   output        o_tlb_enabled,
   output        o_tlb_maint_cmd,
   output        o_tlb_maint_wr_en,
   output [11:0] o_tlb_virt_adr,
   output [ 6:0] o_tlb_phys_adr,
   output        o_tlb_entry_valid,
   input  [ 6:0] i_tlb_phys_adr,
   input         i_tlb_entry_valid,
   input  [ 4:0] i_tlb_drop,
   // DDR controller error monitoring (clk_ddr)
   input         i_ddr_p0_error,
   input         i_ddr_p1_error,
   input         i_ddr_p2_error,
   input         i_ddr_p3_error,
   // I2C Slave Interface (clk_cpu)
   input         i_i2c_miss_valid,
   input  [ 7:0] i_i2c_miss_addr,
   input  [ 1:0] i_i2c_miss_flags,
   input         i_i2c_miss_wen,
   input  [ 3:0] i_i2c_miss_ben,
   input  [31:0] i_i2c_miss_wdata,
   output        o_i2c_miss_stall,
   output        o_i2c_fill_valid,
   output [31:0] o_i2c_fill_data,
   input         i_i2c_fill_stall,
   // UART Interface (clk_xbar for enq, clk_ni for deq)
   output        o_uart_enq,
   output [ 7:0] o_uart_enq_data,
   input  [10:0] i_uart_tx_words,
   input         i_uart_tx_full,
   output        o_uart_deq,
   input  [ 7:0] i_uart_deq_data,
   input  [10:0] i_uart_rx_words,
   input         i_uart_rx_empty,
   input         i_uart_byte_rcv,
   // MBS UART & Timer Interface (clk_cpu)
   output [ 7:0] o_mbs_uart_irq,
   input  [ 7:0] i_mbs_uart_irq_clear,
   output        o_mbs_drift_fw,
   output        o_mbs_drift_bw,
   // MBS Load Status interface (clk_ni)
   input  [ 3:0] i_mbs0_status,
   input  [ 3:0] i_mbs1_status,
   input  [ 3:0] i_mbs2_status,
   input  [ 3:0] i_mbs3_status,
   input  [ 3:0] i_mbs4_status,
   input  [ 3:0] i_mbs5_status,
   input  [ 3:0] i_mbs6_status,
   input  [ 3:0] i_mbs7_status,
    // MBS Trace Interface (clk_ni)
   input         i_mbs0_trc_valid,
   input  [ 7:0] i_mbs0_trc_data,
   input         i_mbs1_trc_valid,
   input  [ 7:0] i_mbs1_trc_data,
   input         i_mbs2_trc_valid,
   input  [ 7:0] i_mbs2_trc_data,
   input         i_mbs3_trc_valid,
   input  [ 7:0] i_mbs3_trc_data,
   input         i_mbs4_trc_valid,
   input  [ 7:0] i_mbs4_trc_data,
   input         i_mbs5_trc_valid,
   input  [ 7:0] i_mbs5_trc_data,
   input         i_mbs6_trc_valid,
   input  [ 7:0] i_mbs6_trc_data,
   input         i_mbs7_trc_valid,
   input  [ 7:0] i_mbs7_trc_data,
   // Crossbar interface (clk_xbar)
   input  [ 2:0] i_xbar_out_enq,
   input  [ 5:0] i_xbar_out_offset,
   input         i_xbar_out_eop,
   input  [15:0] i_xbar_out_data,
   output [ 2:0] o_xbar_out_full,
   output [ 2:0] o_xbar_out_packets_vc0,
   output [ 2:0] o_xbar_out_packets_vc1,
   output [ 2:0] o_xbar_out_packets_vc2,
   input  [ 2:0] i_xbar_in_deq,
   input  [ 5:0] i_xbar_in_offset,
   input         i_xbar_in_eop,
   output [15:0] o_xbar_in_data,
   output [ 2:0] o_xbar_in_empty
);

 // ==========================================================================
 // Wires
 // ==========================================================================
 wire [ 2:0] xbi_out_enq;
 wire [ 5:0] xbi_out_offset;
 wire        xbi_out_eop;
 wire [15:0] xbi_out_data;
 wire [ 2:0] xbi_out_full;
 wire [ 2:0] xbi_in_deq;
 wire [ 5:0] xbi_in_offset;
 wire        xbi_in_eop;
 wire [15:0] xbi_in_data;
 wire [ 2:0] xbi_in_empty;
//
 wire [31:0] boot_data;
 wire [10:0] boot_adr;
 wire [31:0] boot_l2c_wb_adr;
// 
 wire        l2c_wb_space;
 wire        l2c_wb_valid;
 wire [31:0] l2c_wb_adr;
 wire        l2c_wb_ack_valid;
 wire        l2c_wb_ack_fault;
 wire [31:0] l2c_wb_ack_adr;
 wire        l2c_wb_ack_stall;
 wire [31:0] l2c_data;
//
 wire [ 2:0] usr_nin_packets_vc0;
 wire [ 2:0] usr_nin_packets_vc1;
 wire [ 2:0] usr_nin_packets_vc2;
//
 wire [ 2:0] usr_nout_packets_vc0;
 wire [ 2:0] usr_nout_packets_vc1;
 wire [ 2:0] usr_nout_packets_vc2;
//
 wire [25:0] bctl_trc_base;
 wire [25:0] bctl_trc_bound;
 wire        bctl_trc_en;
//
// ==========================================================================
// Crossbar interface FIFO
// ==========================================================================
 xbi i0_xbi (
   .clk_usr                ( clk_ni ),
   .rst_usr                ( rst_ni ),
   .i_usr_nout_enq         ( xbi_out_enq ),
   .i_usr_nout_offset      ( xbi_out_offset ),
   .i_usr_nout_eop         ( xbi_out_eop ),
   .i_usr_nout_data        ( xbi_out_data ),
   .o_usr_nout_full        ( xbi_out_full ),
   .o_usr_nout_packets_vc0 ( usr_nout_packets_vc0 ),
   .o_usr_nout_packets_vc1 ( usr_nout_packets_vc1 ),
   .o_usr_nout_packets_vc2 ( usr_nout_packets_vc2 ),
   .i_usr_nin_deq          ( xbi_in_deq ),
   .i_usr_nin_offset       ( xbi_in_offset ),
   .i_usr_nin_eop          ( xbi_in_eop ),
   .o_usr_nin_data         ( xbi_in_data ),
   .o_usr_nin_empty        ( xbi_in_empty ),
   .o_usr_nin_packets_vc0  ( usr_nin_packets_vc0 ),
   .o_usr_nin_packets_vc1  ( usr_nin_packets_vc1 ),
   .o_usr_nin_packets_vc2  ( usr_nin_packets_vc2 ),
   .clk_xbar               ( clk_xbar ),
   .rst_xbar               ( rst_xbar ),
   .i_xbar_out_enq         ( i_xbar_out_enq ),
   .i_xbar_out_offset      ( i_xbar_out_offset ),
   .i_xbar_out_eop         ( i_xbar_out_eop ),
   .i_xbar_out_data        ( i_xbar_out_data ),
   .o_xbar_out_full        ( o_xbar_out_full ),
   .o_xbar_out_packets_vc0 ( o_xbar_out_packets_vc0 ),
   .o_xbar_out_packets_vc1 ( o_xbar_out_packets_vc1 ),
   .o_xbar_out_packets_vc2 ( o_xbar_out_packets_vc2 ),
   .i_xbar_in_deq          ( i_xbar_in_deq ),
   .i_xbar_in_offset       ( i_xbar_in_offset ),
   .i_xbar_in_eop          ( i_xbar_in_eop ),
   .o_xbar_in_data         ( o_xbar_in_data ),
   .o_xbar_in_empty        ( o_xbar_in_empty )
 );

 
// ==========================================================================
// Boot ROM for DDR initialization
// ==========================================================================
 boot_mem i0_boot_mem (
   .clk     ( clk_mc ),
   .i_adr   ( boot_adr ),
   .o_data  ( boot_data ));
//
 boot iboot(
     .clk_mc              ( clk_mc ),
     .rst_mc              ( rst_mc ),
     // Boot Mem Interface
     .i_boot_data         ( boot_data ),
     .o_boot_adr          ( boot_adr ),
     // L2C Writeback Interface (clk_mc)
     .i_l2c_wb_space      ( l2c_wb_space ),
     .o_l2c_wb_valid      ( boot_l2c_wb_valid ),
     .o_l2c_wb_adr        ( boot_l2c_wb_adr ),
     // L2C Writeback Acknowledge Interface (clk_mc)
     .i_l2c_wb_ack_valid  ( l2c_wb_ack_valid ),
     .i_l2c_wb_ack_fault  ( l2c_wb_ack_fault ),
     .i_l2c_wb_ack_adr    ( l2c_wb_ack_adr ),
     .o_l2c_wb_ack_stall  ( l2c_wb_ack_stall ),
     // Reset manager interface
     .i_boot_req          ( i_ddr_boot_req ),
     .o_boot_done         ( o_ddr_boot_done) );
//
// ==========================================================================
//  Trace 
// ==========================================================================
//
wire [31:0] trc_l2c_wb_adr;
wire [31:0] trc_l2c_data;
wire        trc_l2c_wb_valid;
//
formic_bctl_trace ibctl_trace(
     .clk_ni           ( clk_ni ),
     .rst_ni           ( rst_ni ),
     .clk_mc           ( clk_mc ),
     .rst_mc           ( rst_mc ),
    // MBS Trace Interface (clk_ni)
     .i_mbs0_trc_valid ( i_mbs0_trc_valid ),
     .i_mbs0_trc_data  ( i_mbs0_trc_data ),
     .i_mbs1_trc_valid ( i_mbs1_trc_valid ),
     .i_mbs1_trc_data  ( i_mbs1_trc_data ),
     .i_mbs2_trc_valid ( i_mbs2_trc_valid ),
     .i_mbs2_trc_data  ( i_mbs2_trc_data ),
     .i_mbs3_trc_valid ( i_mbs3_trc_valid ),
     .i_mbs3_trc_data  ( i_mbs3_trc_data ),
     .i_mbs4_trc_valid ( i_mbs4_trc_valid ),
     .i_mbs4_trc_data  ( i_mbs4_trc_data ),
     .i_mbs5_trc_valid ( i_mbs5_trc_valid ),
     .i_mbs5_trc_data  ( i_mbs5_trc_data ),
     .i_mbs6_trc_valid ( i_mbs6_trc_valid ),
     .i_mbs6_trc_data  ( i_mbs6_trc_data ),
     .i_mbs7_trc_valid ( i_mbs7_trc_valid ),
     .i_mbs7_trc_data  ( i_mbs7_trc_data ),
  //
     .i_bctl_trc_base  ( bctl_trc_base ),
     .i_bctl_trc_bound ( bctl_trc_bound ),
     .i_bctl_trc_en    ( bctl_trc_en ),
  //
     .i_l2c_wb_space   ( l2c_wb_space ),
     .o_l2c_wb_valid   ( trc_l2c_wb_valid ),
     .o_l2c_wb_adr     ( trc_l2c_wb_adr ),
     .o_l2c_data       ( trc_l2c_data ));
//
 assign l2c_wb_valid = o_ddr_boot_done ? trc_l2c_wb_valid : boot_l2c_wb_valid;
 assign l2c_wb_adr   = o_ddr_boot_done ? trc_l2c_wb_adr   : boot_l2c_wb_adr;
 assign l2c_data     = o_ddr_boot_done ? trc_l2c_data     : boot_data;
//
// ==========================================================================
// MNI
// ==========================================================================
//
 wire [19:0] ctl_reg_adr;
 wire        ctl_reg_valid;
 wire        ctl_reg_wen;
 wire        ctl_reg_from_cpu;
 wire [ 1:0] ctl_reg_ben;
 wire [15:0] ctl_reg_wdata;
 wire [ 2:0] ctl_reg_rlen;
 wire        ctl_reg_stall;
 wire [15:0] ctl_reg_resp_rdata;
 wire        ctl_reg_resp_valid;
//
mni imni(
  // Clocks and resets
  .clk_mc                 ( clk_mc ),
  .rst_mc                 ( rst_mc ),
  .clk_ni                 ( clk_ni ),
  .rst_ni                 ( rst_ni ),

  // Static configuration
  .i_board_id             ( i_board_id ),
  .i_node_id              ( 4'hF ),
  .i_ctl_addr_base        ( 12'hFFF ),

  // CTL Registers Interface (clk_ni)
  .o_ctl_reg_adr          ( ctl_reg_adr ),
  .o_ctl_reg_valid        ( ctl_reg_valid ),
  .o_ctl_reg_wen          ( ctl_reg_wen ),
  .o_ctl_reg_from_cpu     ( ctl_reg_from_cpu ),
  .o_ctl_reg_ben          ( ctl_reg_ben ),
  .o_ctl_reg_wdata        ( ctl_reg_wdata ),
  .o_ctl_reg_rlen         ( ctl_reg_rlen ),
  .i_ctl_reg_stall        ( ctl_reg_stall ),
  .i_ctl_reg_resp_rdata   ( ctl_reg_resp_rdata ),
  .i_ctl_reg_resp_valid   ( ctl_reg_resp_valid ),
  .i_ctl_reg_block        ( 1'b0 ),
  .i_ctl_reg_unblock      ( 1'b0 ),

  // CTL Operation Interface (clk_ni)
  .i_ctl_op_valid         ( 1'b0 ),
  .i_ctl_op_data          ( 16'b0 ),
  .o_ctl_op_stall         ( ),

  // CTL operation FIFO levels
  .o_ctl_cpu_fifo_ops     ( ),
  .o_ctl_net_fifo_ops     ( ),

  // CTL Trace Interface (clk_ni)
  .o_ctl_trace_op_local   ( ),
  .o_ctl_trace_op_remote  ( ),
  .o_ctl_trace_read_hit   ( ),
  .o_ctl_trace_read_miss  ( ),
  .o_ctl_trace_write_hit  ( ),
  .o_ctl_trace_write_miss ( ),
  .o_ctl_trace_vc0_in     ( ),
  .o_ctl_trace_vc0_out    ( ),
  .o_ctl_trace_vc1_in     ( ),
  .o_ctl_trace_vc1_out    ( ),
  .o_ctl_trace_vc2_in     ( ),
  .o_ctl_trace_vc2_out    ( ),

  // CMX interface  (clk_ni)
  .i_cmx_valid            ( 1'b0) ,
  .i_cmx_data             ( 16'b0 ),
  .o_cmx_stall            ( ),
  .i_cmx_mbox_space       ( 12'b0 ),
  .i_cmx_mslot_space      ( 1'b0 ),

  // L2C Writeback Interface (clk_mc)
  .o_l2c_wb_space         ( l2c_wb_space ),
  .i_l2c_wb_valid         ( l2c_wb_valid ),
  .i_l2c_wb_adr           ( l2c_wb_adr ),

  // L2C Writeback Acknowledge Interface (clk_mc)
  .o_l2c_wb_ack_valid     ( l2c_wb_ack_valid ),
  .o_l2c_wb_ack_fault     ( l2c_wb_ack_fault ),
  .o_l2c_wb_ack_adr       ( l2c_wb_ack_adr ),
  .i_l2c_wb_ack_stall     ( l2c_wb_ack_stall ),

  // L2C Miss Interface (clk_mc)
  .i_l2c_miss_valid       ( i_i2c_miss_valid ),
  .i_l2c_miss_adr         ( {12'hFFF, i_i2c_miss_addr[7:5], 1'b0, // block ID
                             9'b0, i_i2c_miss_addr[4:0], 2'b0} ), // reg addr
  .i_l2c_miss_flags       ( i_i2c_miss_flags ),
  .i_l2c_miss_wen         ( i_i2c_miss_wen ),
  .i_l2c_miss_ben         ( i_i2c_miss_ben ),
  .i_l2c_miss_wdata       ( i_i2c_miss_wdata ),
  .o_l2c_miss_stall       ( o_i2c_miss_stall ),

  // L2C Fill Interface (clk_mc)
  .o_l2c_fill_valid       ( o_i2c_fill_valid ),
  .o_l2c_fill_fault       ( ),
  .o_l2c_fill_len         ( ),
  .o_l2c_fill_adr         ( ),
  .i_l2c_fill_stall       ( i_i2c_fill_stall ),

  // L2C Write Interface (clk_mc)
  .o_l2c_write_valid      ( ),
  .o_l2c_write_dirty      ( ),
  .o_l2c_write_adr        ( ),
  .i_l2c_write_stall      ( 1'b1 ),
  .i_l2c_write_nack       ( 1'b0 ),
  .i_l2c_write_done       ( 1'b0 ),

  // L2C Read Interface (clk_mc)
  .o_l2c_read_valid       ( ),
  .o_l2c_read_ignore      ( ),
  .o_l2c_read_adr         ( ),
  .i_l2c_read_stall       ( 1'b1 ),
  .i_l2c_read_nack        ( 1'b0 ),

  // L2C Common Data Busses (clk_mc)
  .o_l2c_data             ( o_i2c_fill_data ),
  .i_l2c_data             ( l2c_data ),

  // Network Out Interface (clk_ni)
  .o_nout_enq             ( xbi_out_enq ),
  .o_nout_offset          ( xbi_out_offset ),
  .o_nout_eop             ( xbi_out_eop ),
  .o_nout_data            ( xbi_out_data ),
  .i_nout_full            ( xbi_out_full ),
  .i_nout_packets_vc0     ( usr_nout_packets_vc0 ),
  .i_nout_packets_vc1     ( usr_nout_packets_vc1 ),
  .i_nout_packets_vc2     ( usr_nout_packets_vc2 ),

  // Network In Interface (clk_ni)
  .o_nin_deq              ( xbi_in_deq ),
  .o_nin_offset           ( xbi_in_offset ),
  .o_nin_eop              ( xbi_in_eop ),
  .i_nin_data             ( xbi_in_data ),
  .i_nin_empty            ( xbi_in_empty ),
  .i_nin_packets_vc0      ( usr_nin_packets_vc0 ),
  .i_nin_packets_vc1      ( usr_nin_packets_vc1 ),
  .i_nin_packets_vc2      ( usr_nin_packets_vc2 ));
//
// rst_cpu
//
 rst_sync_simple # (
   .CLOCK_CYCLES ( 2 )
 ) i0_rst_sync_simple (
   .clk          ( clk_cpu ),
   .rst_async    ( rst_mc ),
   .deassert     ( o_ddr_boot_done ),
   .rst          ( rst_cpu )
 );
//
// CTL
//
 formic_bctl_ctl iformic_bctl_ctl (
// Clocks and Resets
    .clk_cpu              ( clk_cpu ),
    .clk_ni               ( clk_ni ),
    .rst_cpu              ( rst_cpu ),
    .rst_ni               ( rst_ni ),
    .clk_xbar             ( clk_xbar ),
    .rst_xbar             ( rst_xbar ),
    .clk_ddr              ( clk_ddr ),
    .rst_ddr              ( rst_ddr ),
    // LEDs
    .o_led                ( o_led ),
    // Reset Management Interface (assynchronus)
    .o_rst_soft           ( o_rst_soft ),
    .o_rst_hard           ( o_rst_hard ),
    // Static configuration
    .i_board_id           ( i_board_id ),
    .i_dip_sw             ( i_dip_sw ),
    // GTP Interface (assynchronus)
    .i_gtp_link_up        ( i_gtp_link_up ),
    .i_gtp_link_error     ( i_gtp_link_error ),
    .i_gtp_credit_error   ( i_gtp_credit_error ),
    .i_gtp_crc_error      ( i_gtp_crc_error ),
    // MBS Load Status interface (clk_ni)
    .i_mbs0_status        ( i_mbs0_status ),
    .i_mbs1_status        ( i_mbs1_status ),
    .i_mbs2_status        ( i_mbs2_status ),
    .i_mbs3_status        ( i_mbs3_status ),
    .i_mbs4_status        ( i_mbs4_status ),
    .i_mbs5_status        ( i_mbs5_status ),
    .i_mbs6_status        ( i_mbs6_status ),
    .i_mbs7_status        ( i_mbs7_status ),
    // DDR controller error monitoring (clk_ddr)
    .i_ddr_p0_error       ( i_ddr_p0_error ),
    .i_ddr_p1_error       ( i_ddr_p1_error ),
    .i_ddr_p2_error       ( i_ddr_p2_error ),
    .i_ddr_p3_error       ( i_ddr_p3_error ),
    // MNI Registers Access Interface
    .i_mni_reg_adr        ( ctl_reg_adr ),
    .i_mni_reg_valid      ( ctl_reg_valid ),
    .i_mni_reg_wen        ( ctl_reg_wen ),
    .i_mni_reg_from_cpu   ( ctl_reg_from_cpu ),
    .i_mni_reg_ben        ( ctl_reg_ben ),
    .i_mni_reg_wdata      ( ctl_reg_wdata ),
    .i_mni_reg_rlen       ( ctl_reg_rlen ),
    .o_mni_reg_stall      ( ctl_reg_stall ),
    .o_mni_reg_resp_rdata ( ctl_reg_resp_rdata ),
    .o_mni_reg_resp_valid ( ctl_reg_resp_valid ),
    // UART Interface (clk_xbar and clk_ni)
    .o_uart_enq           ( o_uart_enq ),
    .o_uart_enq_data      ( o_uart_enq_data ),
    .i_uart_tx_words      ( i_uart_tx_words ),
    .i_uart_tx_full       ( i_uart_tx_full ),
    .o_uart_deq           ( o_uart_deq ),
    .i_uart_deq_data      ( i_uart_deq_data ),
    .i_uart_rx_words      ( i_uart_rx_words ),
    .i_uart_rx_empty      ( i_uart_rx_empty ),
    .i_uart_byte_rcv      ( i_uart_byte_rcv ),
    // MBS UART & Timer Interface (clk_cpu)
    .o_mbs_uart_irq       ( o_mbs_uart_irq ),
    .i_mbs_uart_irq_clear ( i_mbs_uart_irq_clear ) ,
    .o_mbs_drift_fw       ( o_mbs_drift_fw ),
    .o_mbs_drift_bw       ( o_mbs_drift_bw ),
    // TLB Maintenance Interface (clk_ddr)
    .o_tlb_enabled        ( o_tlb_enabled ),
    .o_tlb_maint_cmd      ( o_tlb_maint_cmd ),
    .o_tlb_maint_wr_en    ( o_tlb_maint_wr_en ),
    .o_tlb_virt_adr       ( o_tlb_virt_adr ),
    .o_tlb_phys_adr       ( o_tlb_phys_adr ),
    .o_tlb_entry_valid    ( o_tlb_entry_valid ),
    .i_tlb_phys_adr       ( i_tlb_phys_adr ),
    .i_tlb_entry_valid    ( i_tlb_entry_valid ),
    .i_tlb_drop           ( i_tlb_drop),
    // Trace Interface
    .o_bctl_trc_base      ( bctl_trc_base ),
    .o_bctl_trc_bound     ( bctl_trc_bound ),
    .o_bctl_trc_en        ( bctl_trc_en ));
//
endmodule
