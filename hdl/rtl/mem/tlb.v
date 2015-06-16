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
// Abstract      : TLB top-level module. Connects 5 crossbar ports to the
//                 4 DRAM controller ports and does the virtual-to-physical
//                 translation.
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: tlb.v,v $
// CVS revision  : $Revision: 1.18 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module tlb (

  // Clocks and resets
  input         clk_cpu,
  input         clk_ni,
  input         clk_ddr,
  input         clk_xbar,
  input         rst_ni,
  input         rst_ddr,
  input         rst_xbar,

  // Board control TLB maintenance interface (clk_ni)
  input         i_bctl_tlb_enabled,
  input         i_bctl_maint_cmd,
  input         i_bctl_maint_wr_en,
  input  [11:0] i_bctl_virt_adr,
  input   [6:0] i_bctl_phys_adr,
  input         i_bctl_entry_valid,
  output  [6:0] o_bctl_phys_adr,
  output        o_bctl_entry_valid,
  output  [4:0] o_bctl_drop,

  // Crossbar interface #0 (clk_xbar)
  input   [2:0] i_xbar0_out_enq,
  input   [5:0] i_xbar0_out_offset,
  input         i_xbar0_out_eop,
  input  [15:0] i_xbar0_out_data,
  output  [2:0] o_xbar0_out_full,
  output  [2:0] o_xbar0_out_packets_vc0,
  output  [2:0] o_xbar0_out_packets_vc1,
  output  [2:0] o_xbar0_out_packets_vc2,
  input   [2:0] i_xbar0_in_deq,
  input   [5:0] i_xbar0_in_offset,
  input         i_xbar0_in_eop,
  output [15:0] o_xbar0_in_data,
  output  [2:0] o_xbar0_in_empty,

  // Crossbar interface #1 (clk_xbar)
  input   [2:0] i_xbar1_out_enq,
  input   [5:0] i_xbar1_out_offset,
  input         i_xbar1_out_eop,
  input  [15:0] i_xbar1_out_data,
  output  [2:0] o_xbar1_out_full,
  output  [2:0] o_xbar1_out_packets_vc0,
  output  [2:0] o_xbar1_out_packets_vc1,
  output  [2:0] o_xbar1_out_packets_vc2,
  input   [2:0] i_xbar1_in_deq,
  input   [5:0] i_xbar1_in_offset,
  input         i_xbar1_in_eop,
  output [15:0] o_xbar1_in_data,
  output  [2:0] o_xbar1_in_empty,

  // Crossbar interface #2 (clk_xbar)
  input   [2:0] i_xbar2_out_enq,
  input   [5:0] i_xbar2_out_offset,
  input         i_xbar2_out_eop,
  input  [15:0] i_xbar2_out_data,
  output  [2:0] o_xbar2_out_full,
  output  [2:0] o_xbar2_out_packets_vc0,
  output  [2:0] o_xbar2_out_packets_vc1,
  output  [2:0] o_xbar2_out_packets_vc2,
  input   [2:0] i_xbar2_in_deq,
  input   [5:0] i_xbar2_in_offset,
  input         i_xbar2_in_eop,
  output [15:0] o_xbar2_in_data,
  output  [2:0] o_xbar2_in_empty,

  // Crossbar interface #3 (clk_xbar)
  input   [2:0] i_xbar3_out_enq,
  input   [5:0] i_xbar3_out_offset,
  input         i_xbar3_out_eop,
  input  [15:0] i_xbar3_out_data,
  output  [2:0] o_xbar3_out_full,
  output  [2:0] o_xbar3_out_packets_vc0,
  output  [2:0] o_xbar3_out_packets_vc1,
  output  [2:0] o_xbar3_out_packets_vc2,
  input   [2:0] i_xbar3_in_deq,
  input   [5:0] i_xbar3_in_offset,
  input         i_xbar3_in_eop,
  output [15:0] o_xbar3_in_data,
  output  [2:0] o_xbar3_in_empty,

  // Crossbar interface #4 (clk_xbar)
  input   [2:0] i_xbar4_out_enq,
  input   [5:0] i_xbar4_out_offset,
  input         i_xbar4_out_eop,
  input  [15:0] i_xbar4_out_data,
  output  [2:0] o_xbar4_out_full,
  output  [2:0] o_xbar4_out_packets_vc0,
  output  [2:0] o_xbar4_out_packets_vc1,
  output  [2:0] o_xbar4_out_packets_vc2,
  input   [2:0] i_xbar4_in_deq,
  input   [5:0] i_xbar4_in_offset,
  input         i_xbar4_in_eop,
  output [15:0] o_xbar4_in_data,
  output  [2:0] o_xbar4_in_empty,

  // DDR controller port #0 (clk_ddr)
  output        o_ddr0_cmd_en,
  output  [2:0] o_ddr0_cmd_instr,
  output  [5:0] o_ddr0_cmd_bl,
  output [29:0] o_ddr0_cmd_byte_addr,
  input         i_ddr0_cmd_empty,
  input         i_ddr0_cmd_full,
  output        o_ddr0_wr_en,
  output [31:0] o_ddr0_wr_data,
  output  [3:0] o_ddr0_wr_mask,
  input         i_ddr0_wr_almost_full,
  output        o_ddr0_rd_en,
  input  [31:0] i_ddr0_rd_data,
  input         i_ddr0_rd_empty,

  // DDR controller port #1 (clk_ddr)
  output        o_ddr1_cmd_en,
  output  [2:0] o_ddr1_cmd_instr,
  output  [5:0] o_ddr1_cmd_bl,
  output [29:0] o_ddr1_cmd_byte_addr,
  input         i_ddr1_cmd_empty,
  input         i_ddr1_cmd_full,
  output        o_ddr1_wr_en,
  output [31:0] o_ddr1_wr_data,
  output  [3:0] o_ddr1_wr_mask,
  input         i_ddr1_wr_almost_full,
  output        o_ddr1_rd_en,
  input  [31:0] i_ddr1_rd_data,
  input         i_ddr1_rd_empty,

  // DDR controller port #2 (clk_ddr)
  output        o_ddr2_cmd_en,
  output  [2:0] o_ddr2_cmd_instr,
  output  [5:0] o_ddr2_cmd_bl,
  output [29:0] o_ddr2_cmd_byte_addr,
  input         i_ddr2_cmd_empty,
  input         i_ddr2_cmd_full,
  output        o_ddr2_wr_en,
  output [31:0] o_ddr2_wr_data,
  output  [3:0] o_ddr2_wr_mask,
  input         i_ddr2_wr_almost_full,
  output        o_ddr2_rd_en,
  input  [31:0] i_ddr2_rd_data,
  input         i_ddr2_rd_empty,

  // DDR controller port #3 (clk_ddr)
  output        o_ddr3_cmd_en,
  output  [2:0] o_ddr3_cmd_instr,
  output  [5:0] o_ddr3_cmd_bl,
  output [29:0] o_ddr3_cmd_byte_addr,
  input         i_ddr3_cmd_empty,
  input         i_ddr3_cmd_full,
  output        o_ddr3_wr_en,
  output [31:0] o_ddr3_wr_data,
  output  [3:0] o_ddr3_wr_mask,
  input         i_ddr3_wr_almost_full,
  output        o_ddr3_rd_en,
  input  [31:0] i_ddr3_rd_data,
  input         i_ddr3_rd_empty
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire  [2:0] xbi0_out_enq;
  wire  [4:0] xbi0_out_offset;
  wire        xbi0_out_eop;
  wire [31:0] xbi0_out_data;
  wire  [2:0] xbi0_out_full;
  wire  [2:0] xbi0_in_deq;
  wire  [4:0] xbi0_in_offset;
  wire        xbi0_in_eop;
  wire [31:0] xbi0_in_data;
  wire  [2:0] xbi0_in_empty;

  wire  [2:0] xbi1_out_enq;
  wire  [4:0] xbi1_out_offset;
  wire        xbi1_out_eop;
  wire [31:0] xbi1_out_data;
  wire  [2:0] xbi1_out_full;
  wire  [2:0] xbi1_in_deq;
  wire  [4:0] xbi1_in_offset;
  wire        xbi1_in_eop;
  wire [31:0] xbi1_in_data;
  wire  [2:0] xbi1_in_empty;

  wire  [2:0] xbi2_out_enq;
  wire  [4:0] xbi2_out_offset;
  wire        xbi2_out_eop;
  wire [31:0] xbi2_out_data;
  wire  [2:0] xbi2_out_full;
  wire  [2:0] xbi2_in_deq;
  wire  [4:0] xbi2_in_offset;
  wire        xbi2_in_eop;
  wire [31:0] xbi2_in_data;
  wire  [2:0] xbi2_in_empty;

  wire  [2:0] xbi3_out_enq;
  wire  [4:0] xbi3_out_offset;
  wire        xbi3_out_eop;
  wire [31:0] xbi3_out_data;
  wire  [2:0] xbi3_out_full;
  wire  [2:0] xbi3_in_deq;
  wire  [4:0] xbi3_in_offset;
  wire        xbi3_in_eop;
  wire [31:0] xbi3_in_data;
  wire  [2:0] xbi3_in_empty;

  wire  [2:0] xbi4_out_enq;
  wire  [4:0] xbi4_out_offset;
  wire        xbi4_out_eop;
  wire [31:0] xbi4_out_data;
  wire  [2:0] xbi4_out_full;
  wire  [2:0] xbi4_in_deq;
  wire  [4:0] xbi4_in_offset;
  wire        xbi4_in_eop;
  wire [31:0] xbi4_in_data;
  wire  [2:0] xbi4_in_empty;

  wire        ni0_drop;
  wire        ni0_req;
  wire        ni0_gnt_d;
  reg         ni0_gnt_q;
  wire        ni0_done;
  wire [11:0] ni0_virt_adr;
  wire        ni0_ddr_cmd_en;
  wire  [2:0] ni0_ddr_cmd_instr;
  wire  [5:0] ni0_ddr_cmd_bl;
  wire [29:0] ni0_ddr_cmd_byte_addr;
  wire        ni0_ddr_cmd_empty;
  wire        ni0_ddr_cmd_full;
  wire        ni0_ddr_wr_en;
  wire [31:0] ni0_ddr_wr_data;
  wire  [3:0] ni0_ddr_wr_mask;
  wire        ni0_ddr_wr_almost_full;
  wire        ni0_ddr_rd_en;
  wire [31:0] ni0_ddr_rd_data;
  wire        ni0_ddr_rd_empty;

  wire        ni1_drop;
  wire        ni1_req;
  wire        ni1_gnt_d;
  reg         ni1_gnt_q;
  wire        ni1_done;
  wire [11:0] ni1_virt_adr;
  wire        ni1_ddr_cmd_en;
  wire  [2:0] ni1_ddr_cmd_instr;
  wire  [5:0] ni1_ddr_cmd_bl;
  wire [29:0] ni1_ddr_cmd_byte_addr;
  wire        ni1_ddr_cmd_empty;
  wire        ni1_ddr_cmd_full;
  wire        ni1_ddr_wr_en;
  wire [31:0] ni1_ddr_wr_data;
  wire  [3:0] ni1_ddr_wr_mask;
  wire        ni1_ddr_wr_almost_full;
  wire        ni1_ddr_rd_en;
  wire [31:0] ni1_ddr_rd_data;
  wire        ni1_ddr_rd_empty;

  wire        ni2_drop;
  wire        ni2_req;
  wire        ni2_gnt_d;
  reg         ni2_gnt_q;
  wire        ni2_done;
  wire [11:0] ni2_virt_adr;
  wire        ni2_ddr_cmd_en;
  wire  [2:0] ni2_ddr_cmd_instr;
  wire  [5:0] ni2_ddr_cmd_bl;
  wire [29:0] ni2_ddr_cmd_byte_addr;
  wire        ni2_ddr_cmd_empty;
  wire        ni2_ddr_cmd_full;
  wire        ni2_ddr_wr_en;
  wire [31:0] ni2_ddr_wr_data;
  wire  [3:0] ni2_ddr_wr_mask;
  wire        ni2_ddr_wr_almost_full;
  wire        ni2_ddr_rd_en;
  wire [31:0] ni2_ddr_rd_data;
  wire        ni2_ddr_rd_empty;

  wire        ni3_drop;
  wire        ni3_req;
  wire        ni3_gnt_d;
  reg         ni3_gnt_q;
  wire        ni3_done;
  wire [11:0] ni3_virt_adr;
  wire        ni3_ddr_cmd_en;
  wire  [2:0] ni3_ddr_cmd_instr;
  wire  [5:0] ni3_ddr_cmd_bl;
  wire [29:0] ni3_ddr_cmd_byte_addr;
  wire        ni3_ddr_cmd_empty;
  wire        ni3_ddr_cmd_full;
  wire        ni3_ddr_wr_en;
  wire [31:0] ni3_ddr_wr_data;
  wire  [3:0] ni3_ddr_wr_mask;
  wire        ni3_ddr_wr_almost_full;
  wire        ni3_ddr_rd_en;
  wire [31:0] ni3_ddr_rd_data;
  wire        ni3_ddr_rd_empty;

  wire        ni4_drop;
  wire        ni4_req;
  wire        ni4_gnt_d;
  reg         ni4_gnt_q;
  wire        ni4_done;
  wire [11:0] ni4_virt_adr;
  wire        ni4_ddr_cmd_en;
  wire  [2:0] ni4_ddr_cmd_instr;
  wire  [5:0] ni4_ddr_cmd_bl;
  wire [29:0] ni4_ddr_cmd_byte_addr;
  wire        ni4_ddr_cmd_empty;
  wire        ni4_ddr_cmd_full;
  wire        ni4_ddr_wr_en;
  wire [31:0] ni4_ddr_wr_data;
  wire  [3:0] ni4_ddr_wr_mask;
  wire        ni4_ddr_wr_almost_full;
  wire        ni4_ddr_rd_en;
  wire [31:0] ni4_ddr_rd_data;
  wire        ni4_ddr_rd_empty;

  wire        tlb_wr_en;
  wire  [6:0] tlb_wr_phys_adr;
  wire [11:0] tlb_wr_virt_adr;
  wire        tlb_wr_entry_valid;

  wire  [6:0] tlb_rd_phys_adr;
  wire [11:0] tlb_rd_virt_adr_d;
  reg  [11:0] tlb_rd_virt_adr_q;
  wire        tlb_rd_entry_valid;

  wire  [7:0] bram0_rdata;
  wire  [7:0] bram1_rdata;

  wire        bctl_tlb_enabled_d;
  reg         bctl_tlb_enabled_q;
  reg         bctl_tlb_enabled_sync0_q;
  reg         bctl_tlb_enabled_sync1_q;
  wire        bctl_maint_cmd_d;
  reg         bctl_maint_cmd_q;
  reg         bctl_maint_wr_en_q;
  wire        bctl_maint_wr_en_d;
  wire [11:0] bctl_virt_adr_d;
  reg  [11:0] bctl_virt_adr_q;
  wire  [6:0] bctl_phys_adr_d;
  reg   [6:0] bctl_phys_adr_q;
  wire        bctl_entry_valid_d;
  reg         bctl_entry_valid_q;
  wire  [4:0] bctl_drop_d;
  reg   [4:0] bctl_drop_q;

  wire  [7:0] req_priority;
  wire  [3:0] free_mask_d;
  reg   [3:0] free_mask_q;
  wire  [3:0] free_priority;

  wire        match_found;

  wire  [3:0] ni0_dst_d;
  reg   [3:0] ni0_dst_q;
  wire  [3:0] ni1_dst_d;
  reg   [3:0] ni1_dst_q;
  wire  [3:0] ni2_dst_d;
  reg   [3:0] ni2_dst_q;
  wire  [3:0] ni3_dst_d;
  reg   [3:0] ni3_dst_q;
  wire  [3:0] ni4_dst_d;
  reg   [3:0] ni4_dst_q;

  wire        ni0_active_d;
  reg         ni0_active_q;
  wire        ni1_active_d;
  reg         ni1_active_q;
  wire        ni2_active_d;
  reg         ni2_active_q;
  wire        ni3_active_d;
  reg         ni3_active_q;
  wire        ni4_active_d;
  reg         ni4_active_q;

  wire  [4:0] ddr0_src_d;
  reg   [4:0] ddr0_src_q;
  wire  [4:0] ddr1_src_d;
  reg   [4:0] ddr1_src_q;
  wire  [4:0] ddr2_src_d;
  reg   [4:0] ddr2_src_q;
  wire  [4:0] ddr3_src_d;
  reg   [4:0] ddr3_src_q;
  
  wire        ddr0_done;
  wire        ddr1_done;
  wire        ddr2_done;
  wire        ddr3_done;

  wire        rst_cpu;
  reg  [15:0] timestamp_cpu_q;
  reg  [15:0] timestamp_ddr_q;

  wire [15:0] timestamp0_vc1;
  wire        timestamp0_vc1_deq;
  wire        timestamp0_vc1_empty;
  wire [15:0] timestamp0_vc2;
  wire        timestamp0_vc2_deq;
  wire        timestamp0_vc2_empty;
  wire [15:0] timestamp1_vc1;
  wire        timestamp1_vc1_deq;
  wire        timestamp1_vc1_empty;
  wire [15:0] timestamp1_vc2;
  wire        timestamp1_vc2_deq;
  wire        timestamp1_vc2_empty;
  wire [15:0] timestamp2_vc1;
  wire        timestamp2_vc1_deq;
  wire        timestamp2_vc1_empty;
  wire [15:0] timestamp2_vc2;
  wire        timestamp2_vc2_deq;
  wire        timestamp2_vc2_empty;
  wire [15:0] timestamp3_vc1;
  wire        timestamp3_vc1_deq;
  wire        timestamp3_vc1_empty;
  wire [15:0] timestamp3_vc2;
  wire        timestamp3_vc2_deq;
  wire        timestamp3_vc2_empty;
  wire [15:0] timestamp4_vc1;
  wire        timestamp4_vc1_deq;
  wire        timestamp4_vc1_empty;
  wire [15:0] timestamp4_vc2;
  wire        timestamp4_vc2_deq;
  wire        timestamp4_vc2_empty;



  // ==========================================================================
  // Crossbar interface FIFOs
  // ==========================================================================
  xbi32 # (
    .NEED_USER_TO_XBAR_VC0  ( 1 ),
    .NEED_USER_TO_XBAR_VC1  ( 1 ),
    .NEED_USER_TO_XBAR_VC2  ( 0 ),
    .NEED_XBAR_TO_USER_VC0  ( 0 ),
    .NEED_XBAR_TO_USER_VC1  ( 1 ),
    .NEED_XBAR_TO_USER_VC2  ( 1 )
  ) i0_xbi32 (
    .clk_usr                ( clk_ddr ),
    .rst_usr                ( rst_ddr ),
    .i_usr_nout_enq         ( xbi0_out_enq ),
    .i_usr_nout_offset      ( xbi0_out_offset ),
    .i_usr_nout_eop         ( xbi0_out_eop ),
    .i_usr_nout_data        ( xbi0_out_data ),
    .o_usr_nout_full        ( xbi0_out_full ),
    .i_usr_nin_deq          ( xbi0_in_deq ),
    .i_usr_nin_offset       ( xbi0_in_offset ),
    .i_usr_nin_eop          ( xbi0_in_eop ),
    .o_usr_nin_data         ( xbi0_in_data ),
    .o_usr_nin_empty        ( xbi0_in_empty ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_out_enq         ( i_xbar0_out_enq ),
    .i_xbar_out_offset      ( i_xbar0_out_offset ),
    .i_xbar_out_eop         ( i_xbar0_out_eop ),
    .i_xbar_out_data        ( i_xbar0_out_data ),
    .o_xbar_out_full        ( o_xbar0_out_full ),
    .o_xbar_out_packets_vc0 ( o_xbar0_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( o_xbar0_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( o_xbar0_out_packets_vc2 ),
    .i_xbar_in_deq          ( i_xbar0_in_deq ),
    .i_xbar_in_offset       ( i_xbar0_in_offset ),
    .i_xbar_in_eop          ( i_xbar0_in_eop ),
    .o_xbar_in_data         ( o_xbar0_in_data ),
    .o_xbar_in_empty        ( o_xbar0_in_empty )
  );

  xbi32 # (
    .NEED_USER_TO_XBAR_VC0  ( 1 ),
    .NEED_USER_TO_XBAR_VC1  ( 1 ),
    .NEED_USER_TO_XBAR_VC2  ( 0 ),
    .NEED_XBAR_TO_USER_VC0  ( 0 ),
    .NEED_XBAR_TO_USER_VC1  ( 1 ),
    .NEED_XBAR_TO_USER_VC2  ( 1 )
  ) i1_xbi32 (
    .clk_usr                ( clk_ddr ),
    .rst_usr                ( rst_ddr ),
    .i_usr_nout_enq         ( xbi1_out_enq ),
    .i_usr_nout_offset      ( xbi1_out_offset ),
    .i_usr_nout_eop         ( xbi1_out_eop ),
    .i_usr_nout_data        ( xbi1_out_data ),
    .o_usr_nout_full        ( xbi1_out_full ),
    .i_usr_nin_deq          ( xbi1_in_deq ),
    .i_usr_nin_offset       ( xbi1_in_offset ),
    .i_usr_nin_eop          ( xbi1_in_eop ),
    .o_usr_nin_data         ( xbi1_in_data ),
    .o_usr_nin_empty        ( xbi1_in_empty ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_out_enq         ( i_xbar1_out_enq ),
    .i_xbar_out_offset      ( i_xbar1_out_offset ),
    .i_xbar_out_eop         ( i_xbar1_out_eop ),
    .i_xbar_out_data        ( i_xbar1_out_data ),
    .o_xbar_out_full        ( o_xbar1_out_full ),
    .o_xbar_out_packets_vc0 ( o_xbar1_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( o_xbar1_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( o_xbar1_out_packets_vc2 ),
    .i_xbar_in_deq          ( i_xbar1_in_deq ),
    .i_xbar_in_offset       ( i_xbar1_in_offset ),
    .i_xbar_in_eop          ( i_xbar1_in_eop ),
    .o_xbar_in_data         ( o_xbar1_in_data ),
    .o_xbar_in_empty        ( o_xbar1_in_empty )
  );

  xbi32 # (
    .NEED_USER_TO_XBAR_VC0  ( 1 ),
    .NEED_USER_TO_XBAR_VC1  ( 1 ),
    .NEED_USER_TO_XBAR_VC2  ( 0 ),
    .NEED_XBAR_TO_USER_VC0  ( 0 ),
    .NEED_XBAR_TO_USER_VC1  ( 1 ),
    .NEED_XBAR_TO_USER_VC2  ( 1 )
  ) i2_xbi32 (
    .clk_usr                ( clk_ddr ),
    .rst_usr                ( rst_ddr ),
    .i_usr_nout_enq         ( xbi2_out_enq ),
    .i_usr_nout_offset      ( xbi2_out_offset ),
    .i_usr_nout_eop         ( xbi2_out_eop ),
    .i_usr_nout_data        ( xbi2_out_data ),
    .o_usr_nout_full        ( xbi2_out_full ),
    .i_usr_nin_deq          ( xbi2_in_deq ),
    .i_usr_nin_offset       ( xbi2_in_offset ),
    .i_usr_nin_eop          ( xbi2_in_eop ),
    .o_usr_nin_data         ( xbi2_in_data ),
    .o_usr_nin_empty        ( xbi2_in_empty ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_out_enq         ( i_xbar2_out_enq ),
    .i_xbar_out_offset      ( i_xbar2_out_offset ),
    .i_xbar_out_eop         ( i_xbar2_out_eop ),
    .i_xbar_out_data        ( i_xbar2_out_data ),
    .o_xbar_out_full        ( o_xbar2_out_full ),
    .o_xbar_out_packets_vc0 ( o_xbar2_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( o_xbar2_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( o_xbar2_out_packets_vc2 ),
    .i_xbar_in_deq          ( i_xbar2_in_deq ),
    .i_xbar_in_offset       ( i_xbar2_in_offset ),
    .i_xbar_in_eop          ( i_xbar2_in_eop ),
    .o_xbar_in_data         ( o_xbar2_in_data ),
    .o_xbar_in_empty        ( o_xbar2_in_empty )
  );

  xbi32 # (
    .NEED_USER_TO_XBAR_VC0  ( 1 ),
    .NEED_USER_TO_XBAR_VC1  ( 1 ),
    .NEED_USER_TO_XBAR_VC2  ( 0 ),
    .NEED_XBAR_TO_USER_VC0  ( 0 ),
    .NEED_XBAR_TO_USER_VC1  ( 1 ),
    .NEED_XBAR_TO_USER_VC2  ( 1 )
  ) i3_xbi32 (
    .clk_usr                ( clk_ddr ),
    .rst_usr                ( rst_ddr ),
    .i_usr_nout_enq         ( xbi3_out_enq ),
    .i_usr_nout_offset      ( xbi3_out_offset ),
    .i_usr_nout_eop         ( xbi3_out_eop ),
    .i_usr_nout_data        ( xbi3_out_data ),
    .o_usr_nout_full        ( xbi3_out_full ),
    .i_usr_nin_deq          ( xbi3_in_deq ),
    .i_usr_nin_offset       ( xbi3_in_offset ),
    .i_usr_nin_eop          ( xbi3_in_eop ),
    .o_usr_nin_data         ( xbi3_in_data ),
    .o_usr_nin_empty        ( xbi3_in_empty ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_out_enq         ( i_xbar3_out_enq ),
    .i_xbar_out_offset      ( i_xbar3_out_offset ),
    .i_xbar_out_eop         ( i_xbar3_out_eop ),
    .i_xbar_out_data        ( i_xbar3_out_data ),
    .o_xbar_out_full        ( o_xbar3_out_full ),
    .o_xbar_out_packets_vc0 ( o_xbar3_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( o_xbar3_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( o_xbar3_out_packets_vc2 ),
    .i_xbar_in_deq          ( i_xbar3_in_deq ),
    .i_xbar_in_offset       ( i_xbar3_in_offset ),
    .i_xbar_in_eop          ( i_xbar3_in_eop ),
    .o_xbar_in_data         ( o_xbar3_in_data ),
    .o_xbar_in_empty        ( o_xbar3_in_empty )
  );

  xbi32 # (
    .NEED_USER_TO_XBAR_VC0  ( 1 ),
    .NEED_USER_TO_XBAR_VC1  ( 1 ),
    .NEED_USER_TO_XBAR_VC2  ( 0 ),
    .NEED_XBAR_TO_USER_VC0  ( 0 ),
    .NEED_XBAR_TO_USER_VC1  ( 1 ),
    .NEED_XBAR_TO_USER_VC2  ( 1 )
  ) i4_xbi32 (
    .clk_usr                ( clk_ddr ),
    .rst_usr                ( rst_ddr ),
    .i_usr_nout_enq         ( xbi4_out_enq ),
    .i_usr_nout_offset      ( xbi4_out_offset ),
    .i_usr_nout_eop         ( xbi4_out_eop ),
    .i_usr_nout_data        ( xbi4_out_data ),
    .o_usr_nout_full        ( xbi4_out_full ),
    .i_usr_nin_deq          ( xbi4_in_deq ),
    .i_usr_nin_offset       ( xbi4_in_offset ),
    .i_usr_nin_eop          ( xbi4_in_eop ),
    .o_usr_nin_data         ( xbi4_in_data ),
    .o_usr_nin_empty        ( xbi4_in_empty ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_out_enq         ( i_xbar4_out_enq ),
    .i_xbar_out_offset      ( i_xbar4_out_offset ),
    .i_xbar_out_eop         ( i_xbar4_out_eop ),
    .i_xbar_out_data        ( i_xbar4_out_data ),
    .o_xbar_out_full        ( o_xbar4_out_full ),
    .o_xbar_out_packets_vc0 ( o_xbar4_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( o_xbar4_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( o_xbar4_out_packets_vc2 ),
    .i_xbar_in_deq          ( i_xbar4_in_deq ),
    .i_xbar_in_offset       ( i_xbar4_in_offset ),
    .i_xbar_in_eop          ( i_xbar4_in_eop ),
    .o_xbar_in_data         ( o_xbar4_in_data ),
    .o_xbar_in_empty        ( o_xbar4_in_empty )
  );
 

  // ==========================================================================
  // Input packet timestamping
  // ==========================================================================

  // Clock domains usage note:
  //
  // The beauty is that clk_cpu (10 MHz) is aligned to both clk_ddr (100 MHz)
  // and clk_xbar (160 MHz).
  //
  // So, we can safely enqueue the clk_cpu counter value using clk_xbar
  // write logic to the FIFO, dequeue it from the clk_ddr read logic side,
  // and still be able to compare it with the current clk_cpu value. A small
  // problem is that the 2nd PLL actually uses clk_drp (not clk_ddr) for phase
  // alignment (same clock, different BUFGMUX that doesn't switch off), so
  // clk_ddr and clk_cpu have a constant, significant phase (like 2-3 ns). To
  // fix that, we just copy the current timestamp to a clk_ddr register instead
  // of using it directly on a path.
  //
  // However, clk_xbar and clk_ddr are not aligned (well, they are, but
  // the least common multiple leads to 2.5 ns edges, which is too short),
  // so we still must use a gray-based async clock FIFO.

  rst_sync_simple # (
    .CLOCK_CYCLES ( 2 )
  ) i0_rst_sync_simple (
    .clk          ( clk_cpu ),
    .rst_async    ( rst_ni ),
    .deassert     ( 1'b1 ),
    .rst          ( rst_cpu )
  );

  always @(posedge clk_cpu) begin
    if (rst_cpu) 
      timestamp_cpu_q <= #`dh 0;
    else
      timestamp_cpu_q <= #`dh timestamp_cpu_q + 1'b1;
  end
  always @(posedge clk_ddr) begin
    timestamp_ddr_q <= #`dh timestamp_cpu_q;
  end

  fifo_8x16 i01_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar0_out_enq[1] & i_xbar0_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp0_vc1 ),
    .i_rd_en                ( timestamp0_vc1_deq ),
    .o_empty                ( timestamp0_vc1_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i02_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar0_out_enq[2] & i_xbar0_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp0_vc2 ),
    .i_rd_en                ( timestamp0_vc2_deq ),
    .o_empty                ( timestamp0_vc2_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i11_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar1_out_enq[1] & i_xbar1_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp1_vc1 ),
    .i_rd_en                ( timestamp1_vc1_deq ),
    .o_empty                ( timestamp1_vc1_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i12_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar1_out_enq[2] & i_xbar1_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp1_vc2 ),
    .i_rd_en                ( timestamp1_vc2_deq ),
    .o_empty                ( timestamp1_vc2_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i21_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar2_out_enq[1] & i_xbar2_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp2_vc1 ),
    .i_rd_en                ( timestamp2_vc1_deq ),
    .o_empty                ( timestamp2_vc1_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i22_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar2_out_enq[2] & i_xbar2_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp2_vc2 ),
    .i_rd_en                ( timestamp2_vc2_deq ),
    .o_empty                ( timestamp2_vc2_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i31_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar3_out_enq[1] & i_xbar3_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp3_vc1 ),
    .i_rd_en                ( timestamp3_vc1_deq ),
    .o_empty                ( timestamp3_vc1_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i32_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar3_out_enq[2] & i_xbar3_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp3_vc2 ),
    .i_rd_en                ( timestamp3_vc2_deq ),
    .o_empty                ( timestamp3_vc2_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i41_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar4_out_enq[1] & i_xbar4_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp4_vc1 ),
    .i_rd_en                ( timestamp4_vc1_deq ),
    .o_empty                ( timestamp4_vc1_empty ),
    .o_rd_words             (  )
  );

  fifo_8x16 i42_fifo_8x16(
    .clk_wr                 ( clk_xbar ),
    .rst_wr                 ( rst_xbar ),
    .i_wr_data              ( timestamp_cpu_q ),
    .i_wr_en                ( i_xbar4_out_enq[2] & i_xbar4_out_eop ),
    .o_full                 (  ),
    .o_wr_words             (  ),
    .clk_rd                 ( clk_ddr ),
    .rst_rd                 ( rst_ddr ),
    .o_rd_data              ( timestamp4_vc2 ),
    .i_rd_en                ( timestamp4_vc2_deq ),
    .o_empty                ( timestamp4_vc2_empty ),
    .o_rd_words             (  )
  );


  
  // ==========================================================================
  // TLB Network interface blocks
  // ==========================================================================
  tlb_ni i0_tlb_ni (
    .clk                    ( clk_ddr ),
    .rst                    ( rst_ddr ),
    .o_bctl_drop            ( ni0_drop ),
    .o_arb_req              ( ni0_req ),
    .i_arb_gnt              ( ni0_gnt_q ),
    .o_arb_done             ( ni0_done ),
    .o_tlb_virt_adr         ( ni0_virt_adr ),
    .i_tlb_phys_adr         ( tlb_rd_phys_adr ),
    .i_tlb_entry_valid      ( tlb_rd_entry_valid ),
    .i_timestamp_current    ( timestamp_ddr_q ),
    .i_timestamp_vc1        ( timestamp0_vc1 ),
    .i_timestamp_vc1_empty  ( timestamp0_vc1_empty ),
    .o_timestamp_vc1_deq    ( timestamp0_vc1_deq ),
    .i_timestamp_vc2        ( timestamp0_vc2 ),
    .i_timestamp_vc2_empty  ( timestamp0_vc2_empty ),
    .o_timestamp_vc2_deq    ( timestamp0_vc2_deq ),
    .o_xbi_in_deq           ( xbi0_in_deq ),
    .o_xbi_in_offset        ( xbi0_in_offset ),
    .o_xbi_in_eop           ( xbi0_in_eop ),
    .i_xbi_in_data          ( xbi0_in_data ),
    .i_xbi_in_empty         ( xbi0_in_empty ),
    .o_xbi_out_enq          ( xbi0_out_enq ),
    .o_xbi_out_offset       ( xbi0_out_offset ),
    .o_xbi_out_eop          ( xbi0_out_eop ),
    .o_xbi_out_data         ( xbi0_out_data ),
    .i_xbi_out_full         ( xbi0_out_full ),
    .o_ddr_cmd_en           ( ni0_ddr_cmd_en ),
    .o_ddr_cmd_instr        ( ni0_ddr_cmd_instr ),
    .o_ddr_cmd_bl           ( ni0_ddr_cmd_bl ),
    .o_ddr_cmd_byte_addr    ( ni0_ddr_cmd_byte_addr ),
    .i_ddr_cmd_full         ( ni0_ddr_cmd_full ),
    .i_ddr_cmd_empty        ( ni0_ddr_cmd_empty ),
    .o_ddr_wr_en            ( ni0_ddr_wr_en ),
    .o_ddr_wr_data          ( ni0_ddr_wr_data ),
    .o_ddr_wr_mask          ( ni0_ddr_wr_mask ),
    .i_ddr_wr_almost_full   ( ni0_ddr_wr_almost_full ),
    .o_ddr_rd_en            ( ni0_ddr_rd_en ),
    .i_ddr_rd_data          ( ni0_ddr_rd_data ),
    .i_ddr_rd_empty         ( ni0_ddr_rd_empty )
  );

  tlb_ni i1_tlb_ni (
    .clk                    ( clk_ddr ),
    .rst                    ( rst_ddr ),
    .o_bctl_drop            ( ni1_drop ),
    .o_arb_req              ( ni1_req ),
    .i_arb_gnt              ( ni1_gnt_q ),
    .o_arb_done             ( ni1_done ),
    .o_tlb_virt_adr         ( ni1_virt_adr ),
    .i_tlb_phys_adr         ( tlb_rd_phys_adr ),
    .i_tlb_entry_valid      ( tlb_rd_entry_valid ),
    .i_timestamp_current    ( timestamp_ddr_q ),
    .i_timestamp_vc1        ( timestamp1_vc1 ),
    .i_timestamp_vc1_empty  ( timestamp1_vc1_empty ),
    .o_timestamp_vc1_deq    ( timestamp1_vc1_deq ),
    .i_timestamp_vc2        ( timestamp1_vc2 ),
    .i_timestamp_vc2_empty  ( timestamp1_vc2_empty ),
    .o_timestamp_vc2_deq    ( timestamp1_vc2_deq ),
    .o_xbi_in_deq           ( xbi1_in_deq ),
    .o_xbi_in_offset        ( xbi1_in_offset ),
    .o_xbi_in_eop           ( xbi1_in_eop ),
    .i_xbi_in_data          ( xbi1_in_data ),
    .i_xbi_in_empty         ( xbi1_in_empty ),
    .o_xbi_out_enq          ( xbi1_out_enq ),
    .o_xbi_out_offset       ( xbi1_out_offset ),
    .o_xbi_out_eop          ( xbi1_out_eop ),
    .o_xbi_out_data         ( xbi1_out_data ),
    .i_xbi_out_full         ( xbi1_out_full ),
    .o_ddr_cmd_en           ( ni1_ddr_cmd_en ),
    .o_ddr_cmd_instr        ( ni1_ddr_cmd_instr ),
    .o_ddr_cmd_bl           ( ni1_ddr_cmd_bl ),
    .o_ddr_cmd_byte_addr    ( ni1_ddr_cmd_byte_addr ),
    .i_ddr_cmd_full         ( ni1_ddr_cmd_full ),
    .i_ddr_cmd_empty        ( ni1_ddr_cmd_empty ),
    .o_ddr_wr_en            ( ni1_ddr_wr_en ),
    .o_ddr_wr_data          ( ni1_ddr_wr_data ),
    .o_ddr_wr_mask          ( ni1_ddr_wr_mask ),
    .i_ddr_wr_almost_full   ( ni1_ddr_wr_almost_full ),
    .o_ddr_rd_en            ( ni1_ddr_rd_en ),
    .i_ddr_rd_data          ( ni1_ddr_rd_data ),
    .i_ddr_rd_empty         ( ni1_ddr_rd_empty )
  );

  tlb_ni i2_tlb_ni (
    .clk                    ( clk_ddr ),
    .rst                    ( rst_ddr ),
    .o_bctl_drop            ( ni2_drop ),
    .o_arb_req              ( ni2_req ),
    .i_arb_gnt              ( ni2_gnt_q ),
    .o_arb_done             ( ni2_done ),
    .o_tlb_virt_adr         ( ni2_virt_adr ),
    .i_tlb_phys_adr         ( tlb_rd_phys_adr ),
    .i_tlb_entry_valid      ( tlb_rd_entry_valid ),
    .i_timestamp_current    ( timestamp_ddr_q ),
    .i_timestamp_vc1        ( timestamp2_vc1 ),
    .i_timestamp_vc1_empty  ( timestamp2_vc1_empty ),
    .o_timestamp_vc1_deq    ( timestamp2_vc1_deq ),
    .i_timestamp_vc2        ( timestamp2_vc2 ),
    .i_timestamp_vc2_empty  ( timestamp2_vc2_empty ),
    .o_timestamp_vc2_deq    ( timestamp2_vc2_deq ),
    .o_xbi_in_deq           ( xbi2_in_deq ),
    .o_xbi_in_offset        ( xbi2_in_offset ),
    .o_xbi_in_eop           ( xbi2_in_eop ),
    .i_xbi_in_data          ( xbi2_in_data ),
    .i_xbi_in_empty         ( xbi2_in_empty ),
    .o_xbi_out_enq          ( xbi2_out_enq ),
    .o_xbi_out_offset       ( xbi2_out_offset ),
    .o_xbi_out_eop          ( xbi2_out_eop ),
    .o_xbi_out_data         ( xbi2_out_data ),
    .i_xbi_out_full         ( xbi2_out_full ),
    .o_ddr_cmd_en           ( ni2_ddr_cmd_en ),
    .o_ddr_cmd_instr        ( ni2_ddr_cmd_instr ),
    .o_ddr_cmd_bl           ( ni2_ddr_cmd_bl ),
    .o_ddr_cmd_byte_addr    ( ni2_ddr_cmd_byte_addr ),
    .i_ddr_cmd_full         ( ni2_ddr_cmd_full ),
    .i_ddr_cmd_empty        ( ni2_ddr_cmd_empty ),
    .o_ddr_wr_en            ( ni2_ddr_wr_en ),
    .o_ddr_wr_data          ( ni2_ddr_wr_data ),
    .o_ddr_wr_mask          ( ni2_ddr_wr_mask ),
    .i_ddr_wr_almost_full   ( ni2_ddr_wr_almost_full ),
    .o_ddr_rd_en            ( ni2_ddr_rd_en ),
    .i_ddr_rd_data          ( ni2_ddr_rd_data ),
    .i_ddr_rd_empty         ( ni2_ddr_rd_empty )
  );

  tlb_ni i3_tlb_ni (
    .clk                    ( clk_ddr ),
    .rst                    ( rst_ddr ),
    .o_bctl_drop            ( ni3_drop ),
    .o_arb_req              ( ni3_req ),
    .i_arb_gnt              ( ni3_gnt_q ),
    .o_arb_done             ( ni3_done ),
    .o_tlb_virt_adr         ( ni3_virt_adr ),
    .i_tlb_phys_adr         ( tlb_rd_phys_adr ),
    .i_tlb_entry_valid      ( tlb_rd_entry_valid ),
    .i_timestamp_current    ( timestamp_ddr_q ),
    .i_timestamp_vc1        ( timestamp3_vc1 ),
    .i_timestamp_vc1_empty  ( timestamp3_vc1_empty ),
    .o_timestamp_vc1_deq    ( timestamp3_vc1_deq ),
    .i_timestamp_vc2        ( timestamp3_vc2 ),
    .i_timestamp_vc2_empty  ( timestamp3_vc2_empty ),
    .o_timestamp_vc2_deq    ( timestamp3_vc2_deq ),
    .o_xbi_in_deq           ( xbi3_in_deq ),
    .o_xbi_in_offset        ( xbi3_in_offset ),
    .o_xbi_in_eop           ( xbi3_in_eop ),
    .i_xbi_in_data          ( xbi3_in_data ),
    .i_xbi_in_empty         ( xbi3_in_empty ),
    .o_xbi_out_enq          ( xbi3_out_enq ),
    .o_xbi_out_offset       ( xbi3_out_offset ),
    .o_xbi_out_eop          ( xbi3_out_eop ),
    .o_xbi_out_data         ( xbi3_out_data ),
    .i_xbi_out_full         ( xbi3_out_full ),
    .o_ddr_cmd_en           ( ni3_ddr_cmd_en ),
    .o_ddr_cmd_instr        ( ni3_ddr_cmd_instr ),
    .o_ddr_cmd_bl           ( ni3_ddr_cmd_bl ),
    .o_ddr_cmd_byte_addr    ( ni3_ddr_cmd_byte_addr ),
    .i_ddr_cmd_full         ( ni3_ddr_cmd_full ),
    .i_ddr_cmd_empty        ( ni3_ddr_cmd_empty ),
    .o_ddr_wr_en            ( ni3_ddr_wr_en ),
    .o_ddr_wr_data          ( ni3_ddr_wr_data ),
    .o_ddr_wr_mask          ( ni3_ddr_wr_mask ),
    .i_ddr_wr_almost_full   ( ni3_ddr_wr_almost_full ),
    .o_ddr_rd_en            ( ni3_ddr_rd_en ),
    .i_ddr_rd_data          ( ni3_ddr_rd_data ),
    .i_ddr_rd_empty         ( ni3_ddr_rd_empty )
  );

  tlb_ni i4_tlb_ni (
    .clk                    ( clk_ddr ),
    .rst                    ( rst_ddr ),
    .o_bctl_drop            ( ni4_drop ),
    .o_arb_req              ( ni4_req ),
    .i_arb_gnt              ( ni4_gnt_q ),
    .o_arb_done             ( ni4_done ),
    .o_tlb_virt_adr         ( ni4_virt_adr ),
    .i_tlb_phys_adr         ( tlb_rd_phys_adr ),
    .i_tlb_entry_valid      ( tlb_rd_entry_valid ),
    .i_timestamp_current    ( timestamp_ddr_q ),
    .i_timestamp_vc1        ( timestamp4_vc1 ),
    .i_timestamp_vc1_empty  ( timestamp4_vc1_empty ),
    .o_timestamp_vc1_deq    ( timestamp4_vc1_deq ),
    .i_timestamp_vc2        ( timestamp4_vc2 ),
    .i_timestamp_vc2_empty  ( timestamp4_vc2_empty ),
    .o_timestamp_vc2_deq    ( timestamp4_vc2_deq ),
    .o_xbi_in_deq           ( xbi4_in_deq ),
    .o_xbi_in_offset        ( xbi4_in_offset ),
    .o_xbi_in_eop           ( xbi4_in_eop ),
    .i_xbi_in_data          ( xbi4_in_data ),
    .i_xbi_in_empty         ( xbi4_in_empty ),
    .o_xbi_out_enq          ( xbi4_out_enq ),
    .o_xbi_out_offset       ( xbi4_out_offset ),
    .o_xbi_out_eop          ( xbi4_out_eop ),
    .o_xbi_out_data         ( xbi4_out_data ),
    .i_xbi_out_full         ( xbi4_out_full ),
    .o_ddr_cmd_en           ( ni4_ddr_cmd_en ),
    .o_ddr_cmd_instr        ( ni4_ddr_cmd_instr ),
    .o_ddr_cmd_bl           ( ni4_ddr_cmd_bl ),
    .o_ddr_cmd_byte_addr    ( ni4_ddr_cmd_byte_addr ),
    .i_ddr_cmd_full         ( ni4_ddr_cmd_full ),
    .i_ddr_cmd_empty        ( ni4_ddr_cmd_empty ),
    .o_ddr_wr_en            ( ni4_ddr_wr_en ),
    .o_ddr_wr_data          ( ni4_ddr_wr_data ),
    .o_ddr_wr_mask          ( ni4_ddr_wr_mask ),
    .i_ddr_wr_almost_full   ( ni4_ddr_wr_almost_full ),
    .o_ddr_rd_en            ( ni4_ddr_rd_en ),
    .i_ddr_rd_data          ( ni4_ddr_rd_data ),
    .i_ddr_rd_empty         ( ni4_ddr_rd_empty )
  );

  wire [7:0] tlb_rd_data0, tlb_rd_data1; 
  reg  [7:0] tlb_rd_data;
  // ==========================================================================
  // TLB BRAM blocks ?????
  // ==========================================================================
  xil_mem_dp_2048x8 i0_xil_mem_dp_2048x8 (
    .clk0       ( clk_ni ),
    .i_en0      ( 1'b1 ),
    .i_wen0     ( (tlb_wr_en & ~tlb_wr_virt_adr[11]) ),
    .i_adr0     ( tlb_wr_virt_adr[10:0] ),
    .i_wdata0   ( {tlb_wr_entry_valid, tlb_wr_phys_adr} ),
    .o_rdata0   ( tlb_rd_data0 ),
    .clk1       ( clk_ddr ),
    .i_en1      ( 1'b1 ),
    .i_wen1     ( 1'b0 ),
    .i_adr1     ( tlb_rd_virt_adr_d[10:0] ),
    .i_wdata1   ( 8'b0 ),
    .o_rdata1   ( bram0_rdata )
  );

  xil_mem_dp_2048x8 i1_xil_mem_dp_2048x8 (
    .clk0       ( clk_ni ),
    .i_en0      ( 1'b1 ),
    .i_wen0     ( (tlb_wr_en & tlb_wr_virt_adr[11]) ),
    .i_adr0     ( tlb_wr_virt_adr[10:0] ),
    .i_wdata0   ( {tlb_wr_entry_valid, tlb_wr_phys_adr} ),
    .o_rdata0   ( tlb_rd_data1),
    .clk1       ( clk_ddr ),
    .i_en1      ( 1'b1 ),
    .i_wen1     ( 1'b0 ),
    .i_adr1     ( tlb_rd_virt_adr_d[10:0] ),
    .i_wdata1   ( 8'b0 ),
    .o_rdata1   ( bram1_rdata )
  );
//
 assign o_bctl_phys_adr    = tlb_rd_data[6:0];
 assign o_bctl_entry_valid = tlb_rd_data[7];
//
  assign tlb_rd_phys_adr = (~bctl_tlb_enabled_sync1_q) ? tlb_rd_virt_adr_q[6:0] :
                           (~tlb_rd_virt_adr_q[11]) ? bram0_rdata[6:0] :
                                                      bram1_rdata[6:0];

  assign tlb_rd_entry_valid = (~bctl_tlb_enabled_sync1_q) ? 1'b1 :
                              (~tlb_rd_virt_adr_q[11]) ? bram0_rdata[7] :
                                                         bram1_rdata[7];

  assign tlb_rd_virt_adr_d = (ni0_virt_adr & {12{ni0_gnt_q}}) |
                             (ni1_virt_adr & {12{ni1_gnt_q}}) |
                             (ni2_virt_adr & {12{ni2_gnt_q}}) |
                             (ni3_virt_adr & {12{ni3_gnt_q}}) |
                             (ni4_virt_adr & {12{ni4_gnt_q}});


  // ==========================================================================
  // Arbitration
  // ==========================================================================
  RR_prior_enf_combout # (
    .N_log      ( 3 )
  ) i0_RR_prior_enf_combout (
    .Clk        ( clk_ddr ),
    .Rst        ( rst_ddr ),
    .In         ( {3'b000, (ni4_req & ~ni4_active_q), 
                           (ni3_req & ~ni3_active_q), 
                           (ni2_req & ~ni2_active_q), 
                           (ni1_req & ~ni1_active_q), 
                           (ni0_req & ~ni0_active_q)} ),
    .Out        ( req_priority ),
    .ld_en      ( match_found )
  );

  RR_prior_enf_combout # (
    .N_log      ( 2 )
  ) i1_RR_prior_enf_combout (
    .Clk        ( clk_ddr ),
    .Rst        ( rst_ddr ),
    .In         ( free_mask_q ),
    .Out        ( free_priority ),
    .ld_en      ( match_found )
  );

  assign match_found = (req_priority[4:0] != 0) & (free_priority != 0);


  assign ni0_dst_d = (req_priority[0] & match_found) ? free_priority : 
                                                       ni0_dst_q;
  assign ni1_dst_d = (req_priority[1] & match_found) ? free_priority : 
                                                       ni1_dst_q;
  assign ni2_dst_d = (req_priority[2] & match_found) ? free_priority : 
                                                       ni2_dst_q;
  assign ni3_dst_d = (req_priority[3] & match_found) ? free_priority : 
                                                       ni3_dst_q;
  assign ni4_dst_d = (req_priority[4] & match_found) ? free_priority : 
                                                       ni4_dst_q;

  assign ni0_active_d = (req_priority[0] & match_found) ? 1'b1 : 
                        (ni0_done)                      ? 1'b0 :
                                                          ni0_active_q;
  assign ni1_active_d = (req_priority[1] & match_found) ? 1'b1 : 
                        (ni1_done)                      ? 1'b0 :
                                                          ni1_active_q;
  assign ni2_active_d = (req_priority[2] & match_found) ? 1'b1 : 
                        (ni2_done)                      ? 1'b0 :
                                                          ni2_active_q;
  assign ni3_active_d = (req_priority[3] & match_found) ? 1'b1 : 
                        (ni3_done)                      ? 1'b0 :
                                                          ni3_active_q;
  assign ni4_active_d = (req_priority[4] & match_found) ? 1'b1 : 
                        (ni4_done)                      ? 1'b0 :
                                                          ni4_active_q;

  assign free_mask_d[0] = (free_priority[0] & match_found) ? 1'b0 :
                          (ddr0_done)                      ? 1'b1 :
                                                             free_mask_q[0];
  assign free_mask_d[1] = (free_priority[1] & match_found) ? 1'b0 :
                          (ddr1_done)                      ? 1'b1 :
                                                             free_mask_q[1];
  assign free_mask_d[2] = (free_priority[2] & match_found) ? 1'b0 :
                          (ddr2_done)                      ? 1'b1 :
                                                             free_mask_q[2];
  assign free_mask_d[3] = (free_priority[3] & match_found) ? 1'b0 :
                          (ddr3_done)                      ? 1'b1 :
                                                             free_mask_q[3];

  assign ddr0_src_d = (free_priority[0] & match_found) ? req_priority[4:0] :
                      (ddr0_done)                      ? 5'b0 :
                                                         ddr0_src_q;
  assign ddr1_src_d = (free_priority[1] & match_found) ? req_priority[4:0] :
                      (ddr1_done)                      ? 5'b0 :
                                                         ddr1_src_q;
  assign ddr2_src_d = (free_priority[2] & match_found) ? req_priority[4:0] :
                      (ddr2_done)                      ? 5'b0 :
                                                         ddr2_src_q;
  assign ddr3_src_d = (free_priority[3] & match_found) ? req_priority[4:0] :
                      (ddr3_done)                      ? 5'b0 :
                                                         ddr3_src_q;
  
  assign ddr0_done = (ni0_done & ddr0_src_q[0]) |
                     (ni1_done & ddr0_src_q[1]) |
                     (ni2_done & ddr0_src_q[2]) |
                     (ni3_done & ddr0_src_q[3]) |
                     (ni4_done & ddr0_src_q[4]);

  assign ddr1_done = (ni0_done & ddr1_src_q[0]) |
                     (ni1_done & ddr1_src_q[1]) |
                     (ni2_done & ddr1_src_q[2]) |
                     (ni3_done & ddr1_src_q[3]) |
                     (ni4_done & ddr1_src_q[4]);

  assign ddr2_done = (ni0_done & ddr2_src_q[0]) |
                     (ni1_done & ddr2_src_q[1]) |
                     (ni2_done & ddr2_src_q[2]) |
                     (ni3_done & ddr2_src_q[3]) |
                     (ni4_done & ddr2_src_q[4]);

  assign ddr3_done = (ni0_done & ddr3_src_q[0]) |
                     (ni1_done & ddr3_src_q[1]) |
                     (ni2_done & ddr3_src_q[2]) |
                     (ni3_done & ddr3_src_q[3]) |
                     (ni4_done & ddr3_src_q[4]);


  assign ni0_gnt_d = ni0_active_d & ~ni0_active_q;
  assign ni1_gnt_d = ni1_active_d & ~ni1_active_q;
  assign ni2_gnt_d = ni2_active_d & ~ni2_active_q;
  assign ni3_gnt_d = ni3_active_d & ~ni3_active_q;
  assign ni4_gnt_d = ni4_active_d & ~ni4_active_q;

  
  // ==========================================================================
  // Multiplexers (XBI -> DDR)
  // ==========================================================================

  assign o_ddr0_cmd_en = (ni0_ddr_cmd_en & ddr0_src_q[0]) |
                         (ni1_ddr_cmd_en & ddr0_src_q[1]) |
                         (ni2_ddr_cmd_en & ddr0_src_q[2]) |
                         (ni3_ddr_cmd_en & ddr0_src_q[3]) |
                         (ni4_ddr_cmd_en & ddr0_src_q[4]);

  assign o_ddr1_cmd_en = (ni0_ddr_cmd_en & ddr1_src_q[0]) |
                         (ni1_ddr_cmd_en & ddr1_src_q[1]) |
                         (ni2_ddr_cmd_en & ddr1_src_q[2]) |
                         (ni3_ddr_cmd_en & ddr1_src_q[3]) |
                         (ni4_ddr_cmd_en & ddr1_src_q[4]);

  assign o_ddr2_cmd_en = (ni0_ddr_cmd_en & ddr2_src_q[0]) |
                         (ni1_ddr_cmd_en & ddr2_src_q[1]) |
                         (ni2_ddr_cmd_en & ddr2_src_q[2]) |
                         (ni3_ddr_cmd_en & ddr2_src_q[3]) |
                         (ni4_ddr_cmd_en & ddr2_src_q[4]);

  assign o_ddr3_cmd_en = (ni0_ddr_cmd_en & ddr3_src_q[0]) |
                         (ni1_ddr_cmd_en & ddr3_src_q[1]) |
                         (ni2_ddr_cmd_en & ddr3_src_q[2]) |
                         (ni3_ddr_cmd_en & ddr3_src_q[3]) |
                         (ni4_ddr_cmd_en & ddr3_src_q[4]);


  assign o_ddr0_cmd_instr = (ni0_ddr_cmd_instr & {3{ddr0_src_q[0]}}) |
                            (ni1_ddr_cmd_instr & {3{ddr0_src_q[1]}}) |
                            (ni2_ddr_cmd_instr & {3{ddr0_src_q[2]}}) |
                            (ni3_ddr_cmd_instr & {3{ddr0_src_q[3]}}) |
                            (ni4_ddr_cmd_instr & {3{ddr0_src_q[4]}});

  assign o_ddr1_cmd_instr = (ni0_ddr_cmd_instr & {3{ddr1_src_q[0]}}) |
                            (ni1_ddr_cmd_instr & {3{ddr1_src_q[1]}}) |
                            (ni2_ddr_cmd_instr & {3{ddr1_src_q[2]}}) |
                            (ni3_ddr_cmd_instr & {3{ddr1_src_q[3]}}) |
                            (ni4_ddr_cmd_instr & {3{ddr1_src_q[4]}});

  assign o_ddr2_cmd_instr = (ni0_ddr_cmd_instr & {3{ddr2_src_q[0]}}) |
                            (ni1_ddr_cmd_instr & {3{ddr2_src_q[1]}}) |
                            (ni2_ddr_cmd_instr & {3{ddr2_src_q[2]}}) |
                            (ni3_ddr_cmd_instr & {3{ddr2_src_q[3]}}) |
                            (ni4_ddr_cmd_instr & {3{ddr2_src_q[4]}});

  assign o_ddr3_cmd_instr = (ni0_ddr_cmd_instr & {3{ddr3_src_q[0]}}) |
                            (ni1_ddr_cmd_instr & {3{ddr3_src_q[1]}}) |
                            (ni2_ddr_cmd_instr & {3{ddr3_src_q[2]}}) |
                            (ni3_ddr_cmd_instr & {3{ddr3_src_q[3]}}) |
                            (ni4_ddr_cmd_instr & {3{ddr3_src_q[4]}});


  assign o_ddr0_cmd_bl = (ni0_ddr_cmd_bl & {6{ddr0_src_q[0]}}) |
                         (ni1_ddr_cmd_bl & {6{ddr0_src_q[1]}}) |
                         (ni2_ddr_cmd_bl & {6{ddr0_src_q[2]}}) |
                         (ni3_ddr_cmd_bl & {6{ddr0_src_q[3]}}) |
                         (ni4_ddr_cmd_bl & {6{ddr0_src_q[4]}});

  assign o_ddr1_cmd_bl = (ni0_ddr_cmd_bl & {6{ddr1_src_q[0]}}) |
                         (ni1_ddr_cmd_bl & {6{ddr1_src_q[1]}}) |
                         (ni2_ddr_cmd_bl & {6{ddr1_src_q[2]}}) |
                         (ni3_ddr_cmd_bl & {6{ddr1_src_q[3]}}) |
                         (ni4_ddr_cmd_bl & {6{ddr1_src_q[4]}});

  assign o_ddr2_cmd_bl = (ni0_ddr_cmd_bl & {6{ddr2_src_q[0]}}) |
                         (ni1_ddr_cmd_bl & {6{ddr2_src_q[1]}}) |
                         (ni2_ddr_cmd_bl & {6{ddr2_src_q[2]}}) |
                         (ni3_ddr_cmd_bl & {6{ddr2_src_q[3]}}) |
                         (ni4_ddr_cmd_bl & {6{ddr2_src_q[4]}});

  assign o_ddr3_cmd_bl = (ni0_ddr_cmd_bl & {6{ddr3_src_q[0]}}) |
                         (ni1_ddr_cmd_bl & {6{ddr3_src_q[1]}}) |
                         (ni2_ddr_cmd_bl & {6{ddr3_src_q[2]}}) |
                         (ni3_ddr_cmd_bl & {6{ddr3_src_q[3]}}) |
                         (ni4_ddr_cmd_bl & {6{ddr3_src_q[4]}});


  assign o_ddr0_cmd_byte_addr = (ni0_ddr_cmd_byte_addr & {30{ddr0_src_q[0]}}) |
                                (ni1_ddr_cmd_byte_addr & {30{ddr0_src_q[1]}}) |
                                (ni2_ddr_cmd_byte_addr & {30{ddr0_src_q[2]}}) |
                                (ni3_ddr_cmd_byte_addr & {30{ddr0_src_q[3]}}) |
                                (ni4_ddr_cmd_byte_addr & {30{ddr0_src_q[4]}});

  assign o_ddr1_cmd_byte_addr = (ni0_ddr_cmd_byte_addr & {30{ddr1_src_q[0]}}) |
                                (ni1_ddr_cmd_byte_addr & {30{ddr1_src_q[1]}}) |
                                (ni2_ddr_cmd_byte_addr & {30{ddr1_src_q[2]}}) |
                                (ni3_ddr_cmd_byte_addr & {30{ddr1_src_q[3]}}) |
                                (ni4_ddr_cmd_byte_addr & {30{ddr1_src_q[4]}});

  assign o_ddr2_cmd_byte_addr = (ni0_ddr_cmd_byte_addr & {30{ddr2_src_q[0]}}) |
                                (ni1_ddr_cmd_byte_addr & {30{ddr2_src_q[1]}}) |
                                (ni2_ddr_cmd_byte_addr & {30{ddr2_src_q[2]}}) |
                                (ni3_ddr_cmd_byte_addr & {30{ddr2_src_q[3]}}) |
                                (ni4_ddr_cmd_byte_addr & {30{ddr2_src_q[4]}});

  assign o_ddr3_cmd_byte_addr = (ni0_ddr_cmd_byte_addr & {30{ddr3_src_q[0]}}) |
                                (ni1_ddr_cmd_byte_addr & {30{ddr3_src_q[1]}}) |
                                (ni2_ddr_cmd_byte_addr & {30{ddr3_src_q[2]}}) |
                                (ni3_ddr_cmd_byte_addr & {30{ddr3_src_q[3]}}) |
                                (ni4_ddr_cmd_byte_addr & {30{ddr3_src_q[4]}});


  assign o_ddr0_wr_en = (ni0_ddr_wr_en & ddr0_src_q[0]) |
                        (ni1_ddr_wr_en & ddr0_src_q[1]) |
                        (ni2_ddr_wr_en & ddr0_src_q[2]) |
                        (ni3_ddr_wr_en & ddr0_src_q[3]) |
                        (ni4_ddr_wr_en & ddr0_src_q[4]);

  assign o_ddr1_wr_en = (ni0_ddr_wr_en & ddr1_src_q[0]) |
                        (ni1_ddr_wr_en & ddr1_src_q[1]) |
                        (ni2_ddr_wr_en & ddr1_src_q[2]) |
                        (ni3_ddr_wr_en & ddr1_src_q[3]) |
                        (ni4_ddr_wr_en & ddr1_src_q[4]);

  assign o_ddr2_wr_en = (ni0_ddr_wr_en & ddr2_src_q[0]) |
                        (ni1_ddr_wr_en & ddr2_src_q[1]) |
                        (ni2_ddr_wr_en & ddr2_src_q[2]) |
                        (ni3_ddr_wr_en & ddr2_src_q[3]) |
                        (ni4_ddr_wr_en & ddr2_src_q[4]);

  assign o_ddr3_wr_en = (ni0_ddr_wr_en & ddr3_src_q[0]) |
                        (ni1_ddr_wr_en & ddr3_src_q[1]) |
                        (ni2_ddr_wr_en & ddr3_src_q[2]) |
                        (ni3_ddr_wr_en & ddr3_src_q[3]) |
                        (ni4_ddr_wr_en & ddr3_src_q[4]);


  assign o_ddr0_wr_data = (ni0_ddr_wr_data & {32{ddr0_src_q[0]}}) |
                          (ni1_ddr_wr_data & {32{ddr0_src_q[1]}}) |
                          (ni2_ddr_wr_data & {32{ddr0_src_q[2]}}) |
                          (ni3_ddr_wr_data & {32{ddr0_src_q[3]}}) |
                          (ni4_ddr_wr_data & {32{ddr0_src_q[4]}});

  assign o_ddr1_wr_data = (ni0_ddr_wr_data & {32{ddr1_src_q[0]}}) |
                          (ni1_ddr_wr_data & {32{ddr1_src_q[1]}}) |
                          (ni2_ddr_wr_data & {32{ddr1_src_q[2]}}) |
                          (ni3_ddr_wr_data & {32{ddr1_src_q[3]}}) |
                          (ni4_ddr_wr_data & {32{ddr1_src_q[4]}});

  assign o_ddr2_wr_data = (ni0_ddr_wr_data & {32{ddr2_src_q[0]}}) |
                          (ni1_ddr_wr_data & {32{ddr2_src_q[1]}}) |
                          (ni2_ddr_wr_data & {32{ddr2_src_q[2]}}) |
                          (ni3_ddr_wr_data & {32{ddr2_src_q[3]}}) |
                          (ni4_ddr_wr_data & {32{ddr2_src_q[4]}});

  assign o_ddr3_wr_data = (ni0_ddr_wr_data & {32{ddr3_src_q[0]}}) |
                          (ni1_ddr_wr_data & {32{ddr3_src_q[1]}}) |
                          (ni2_ddr_wr_data & {32{ddr3_src_q[2]}}) |
                          (ni3_ddr_wr_data & {32{ddr3_src_q[3]}}) |
                          (ni4_ddr_wr_data & {32{ddr3_src_q[4]}});


  assign o_ddr0_wr_mask = (ni0_ddr_wr_mask & {4{ddr0_src_q[0]}}) |
                          (ni1_ddr_wr_mask & {4{ddr0_src_q[1]}}) |
                          (ni2_ddr_wr_mask & {4{ddr0_src_q[2]}}) |
                          (ni3_ddr_wr_mask & {4{ddr0_src_q[3]}}) |
                          (ni4_ddr_wr_mask & {4{ddr0_src_q[4]}});

  assign o_ddr1_wr_mask = (ni0_ddr_wr_mask & {4{ddr1_src_q[0]}}) |
                          (ni1_ddr_wr_mask & {4{ddr1_src_q[1]}}) |
                          (ni2_ddr_wr_mask & {4{ddr1_src_q[2]}}) |
                          (ni3_ddr_wr_mask & {4{ddr1_src_q[3]}}) |
                          (ni4_ddr_wr_mask & {4{ddr1_src_q[4]}});

  assign o_ddr2_wr_mask = (ni0_ddr_wr_mask & {4{ddr2_src_q[0]}}) |
                          (ni1_ddr_wr_mask & {4{ddr2_src_q[1]}}) |
                          (ni2_ddr_wr_mask & {4{ddr2_src_q[2]}}) |
                          (ni3_ddr_wr_mask & {4{ddr2_src_q[3]}}) |
                          (ni4_ddr_wr_mask & {4{ddr2_src_q[4]}});

  assign o_ddr3_wr_mask = (ni0_ddr_wr_mask & {4{ddr3_src_q[0]}}) |
                          (ni1_ddr_wr_mask & {4{ddr3_src_q[1]}}) |
                          (ni2_ddr_wr_mask & {4{ddr3_src_q[2]}}) |
                          (ni3_ddr_wr_mask & {4{ddr3_src_q[3]}}) |
                          (ni4_ddr_wr_mask & {4{ddr3_src_q[4]}});


  assign o_ddr0_rd_en = (ni0_ddr_rd_en & ddr0_src_q[0]) |
                        (ni1_ddr_rd_en & ddr0_src_q[1]) |
                        (ni2_ddr_rd_en & ddr0_src_q[2]) |
                        (ni3_ddr_rd_en & ddr0_src_q[3]) |
                        (ni4_ddr_rd_en & ddr0_src_q[4]);

  assign o_ddr1_rd_en = (ni0_ddr_rd_en & ddr1_src_q[0]) |
                        (ni1_ddr_rd_en & ddr1_src_q[1]) |
                        (ni2_ddr_rd_en & ddr1_src_q[2]) |
                        (ni3_ddr_rd_en & ddr1_src_q[3]) |
                        (ni4_ddr_rd_en & ddr1_src_q[4]);

  assign o_ddr2_rd_en = (ni0_ddr_rd_en & ddr2_src_q[0]) |
                        (ni1_ddr_rd_en & ddr2_src_q[1]) |
                        (ni2_ddr_rd_en & ddr2_src_q[2]) |
                        (ni3_ddr_rd_en & ddr2_src_q[3]) |
                        (ni4_ddr_rd_en & ddr2_src_q[4]);

  assign o_ddr3_rd_en = (ni0_ddr_rd_en & ddr3_src_q[0]) |
                        (ni1_ddr_rd_en & ddr3_src_q[1]) |
                        (ni2_ddr_rd_en & ddr3_src_q[2]) |
                        (ni3_ddr_rd_en & ddr3_src_q[3]) |
                        (ni4_ddr_rd_en & ddr3_src_q[4]);


  // ==========================================================================
  // Multiplexers (DDR -> XBI)
  // ==========================================================================
  assign ni0_ddr_cmd_empty = (i_ddr0_cmd_empty & ni0_dst_q[0]) |
                             (i_ddr1_cmd_empty & ni0_dst_q[1]) |
                             (i_ddr2_cmd_empty & ni0_dst_q[2]) |
                             (i_ddr3_cmd_empty & ni0_dst_q[3]);

  assign ni1_ddr_cmd_empty = (i_ddr0_cmd_empty & ni1_dst_q[0]) |
                             (i_ddr1_cmd_empty & ni1_dst_q[1]) |
                             (i_ddr2_cmd_empty & ni1_dst_q[2]) |
                             (i_ddr3_cmd_empty & ni1_dst_q[3]);

  assign ni2_ddr_cmd_empty = (i_ddr0_cmd_empty & ni2_dst_q[0]) |
                             (i_ddr1_cmd_empty & ni2_dst_q[1]) |
                             (i_ddr2_cmd_empty & ni2_dst_q[2]) |
                             (i_ddr3_cmd_empty & ni2_dst_q[3]);

  assign ni3_ddr_cmd_empty = (i_ddr0_cmd_empty & ni3_dst_q[0]) |
                             (i_ddr1_cmd_empty & ni3_dst_q[1]) |
                             (i_ddr2_cmd_empty & ni3_dst_q[2]) |
                             (i_ddr3_cmd_empty & ni3_dst_q[3]);

  assign ni4_ddr_cmd_empty = (i_ddr0_cmd_empty & ni4_dst_q[0]) |
                             (i_ddr1_cmd_empty & ni4_dst_q[1]) |
                             (i_ddr2_cmd_empty & ni4_dst_q[2]) |
                             (i_ddr3_cmd_empty & ni4_dst_q[3]);


  assign ni0_ddr_cmd_full = (i_ddr0_cmd_full & ni0_dst_q[0]) |
                            (i_ddr1_cmd_full & ni0_dst_q[1]) |
                            (i_ddr2_cmd_full & ni0_dst_q[2]) |
                            (i_ddr3_cmd_full & ni0_dst_q[3]);

  assign ni1_ddr_cmd_full = (i_ddr0_cmd_full & ni1_dst_q[0]) |
                            (i_ddr1_cmd_full & ni1_dst_q[1]) |
                            (i_ddr2_cmd_full & ni1_dst_q[2]) |
                            (i_ddr3_cmd_full & ni1_dst_q[3]);

  assign ni2_ddr_cmd_full = (i_ddr0_cmd_full & ni2_dst_q[0]) |
                            (i_ddr1_cmd_full & ni2_dst_q[1]) |
                            (i_ddr2_cmd_full & ni2_dst_q[2]) |
                            (i_ddr3_cmd_full & ni2_dst_q[3]);

  assign ni3_ddr_cmd_full = (i_ddr0_cmd_full & ni3_dst_q[0]) |
                            (i_ddr1_cmd_full & ni3_dst_q[1]) |
                            (i_ddr2_cmd_full & ni3_dst_q[2]) |
                            (i_ddr3_cmd_full & ni3_dst_q[3]);

  assign ni4_ddr_cmd_full = (i_ddr0_cmd_full & ni4_dst_q[0]) |
                            (i_ddr1_cmd_full & ni4_dst_q[1]) |
                            (i_ddr2_cmd_full & ni4_dst_q[2]) |
                            (i_ddr3_cmd_full & ni4_dst_q[3]);


  assign ni0_ddr_wr_almost_full = (i_ddr0_wr_almost_full & ni0_dst_q[0]) |
                                  (i_ddr1_wr_almost_full & ni0_dst_q[1]) |
                                  (i_ddr2_wr_almost_full & ni0_dst_q[2]) |
                                  (i_ddr3_wr_almost_full & ni0_dst_q[3]);

  assign ni1_ddr_wr_almost_full = (i_ddr0_wr_almost_full & ni1_dst_q[0]) |
                                  (i_ddr1_wr_almost_full & ni1_dst_q[1]) |
                                  (i_ddr2_wr_almost_full & ni1_dst_q[2]) |
                                  (i_ddr3_wr_almost_full & ni1_dst_q[3]);

  assign ni2_ddr_wr_almost_full = (i_ddr0_wr_almost_full & ni2_dst_q[0]) |
                                  (i_ddr1_wr_almost_full & ni2_dst_q[1]) |
                                  (i_ddr2_wr_almost_full & ni2_dst_q[2]) |
                                  (i_ddr3_wr_almost_full & ni2_dst_q[3]);

  assign ni3_ddr_wr_almost_full = (i_ddr0_wr_almost_full & ni3_dst_q[0]) |
                                  (i_ddr1_wr_almost_full & ni3_dst_q[1]) |
                                  (i_ddr2_wr_almost_full & ni3_dst_q[2]) |
                                  (i_ddr3_wr_almost_full & ni3_dst_q[3]);

  assign ni4_ddr_wr_almost_full = (i_ddr0_wr_almost_full & ni4_dst_q[0]) |
                                  (i_ddr1_wr_almost_full & ni4_dst_q[1]) |
                                  (i_ddr2_wr_almost_full & ni4_dst_q[2]) |
                                  (i_ddr3_wr_almost_full & ni4_dst_q[3]);


  assign ni0_ddr_rd_data = (i_ddr0_rd_data & {32{ni0_dst_q[0]}}) |
                           (i_ddr1_rd_data & {32{ni0_dst_q[1]}}) |
                           (i_ddr2_rd_data & {32{ni0_dst_q[2]}}) |
                           (i_ddr3_rd_data & {32{ni0_dst_q[3]}});

  assign ni1_ddr_rd_data = (i_ddr0_rd_data & {32{ni1_dst_q[0]}}) |
                           (i_ddr1_rd_data & {32{ni1_dst_q[1]}}) |
                           (i_ddr2_rd_data & {32{ni1_dst_q[2]}}) |
                           (i_ddr3_rd_data & {32{ni1_dst_q[3]}});

  assign ni2_ddr_rd_data = (i_ddr0_rd_data & {32{ni2_dst_q[0]}}) |
                           (i_ddr1_rd_data & {32{ni2_dst_q[1]}}) |
                           (i_ddr2_rd_data & {32{ni2_dst_q[2]}}) |
                           (i_ddr3_rd_data & {32{ni2_dst_q[3]}});

  assign ni3_ddr_rd_data = (i_ddr0_rd_data & {32{ni3_dst_q[0]}}) |
                           (i_ddr1_rd_data & {32{ni3_dst_q[1]}}) |
                           (i_ddr2_rd_data & {32{ni3_dst_q[2]}}) |
                           (i_ddr3_rd_data & {32{ni3_dst_q[3]}});

  assign ni4_ddr_rd_data = (i_ddr0_rd_data & {32{ni4_dst_q[0]}}) |
                           (i_ddr1_rd_data & {32{ni4_dst_q[1]}}) |
                           (i_ddr2_rd_data & {32{ni4_dst_q[2]}}) |
                           (i_ddr3_rd_data & {32{ni4_dst_q[3]}});


  assign ni0_ddr_rd_empty = (i_ddr0_rd_empty & ni0_dst_q[0]) |
                            (i_ddr1_rd_empty & ni0_dst_q[1]) |
                            (i_ddr2_rd_empty & ni0_dst_q[2]) |
                            (i_ddr3_rd_empty & ni0_dst_q[3]);

  assign ni1_ddr_rd_empty = (i_ddr0_rd_empty & ni1_dst_q[0]) |
                            (i_ddr1_rd_empty & ni1_dst_q[1]) |
                            (i_ddr2_rd_empty & ni1_dst_q[2]) |
                            (i_ddr3_rd_empty & ni1_dst_q[3]);

  assign ni2_ddr_rd_empty = (i_ddr0_rd_empty & ni2_dst_q[0]) |
                            (i_ddr1_rd_empty & ni2_dst_q[1]) |
                            (i_ddr2_rd_empty & ni2_dst_q[2]) |
                            (i_ddr3_rd_empty & ni2_dst_q[3]);

  assign ni3_ddr_rd_empty = (i_ddr0_rd_empty & ni3_dst_q[0]) |
                            (i_ddr1_rd_empty & ni3_dst_q[1]) |
                            (i_ddr2_rd_empty & ni3_dst_q[2]) |
                            (i_ddr3_rd_empty & ni3_dst_q[3]);

  assign ni4_ddr_rd_empty = (i_ddr0_rd_empty & ni4_dst_q[0]) |
                            (i_ddr1_rd_empty & ni4_dst_q[1]) |
                            (i_ddr2_rd_empty & ni4_dst_q[2]) |
                            (i_ddr3_rd_empty & ni4_dst_q[3]);


  // ==========================================================================
  // Board Controller maintenance interface
  // ==========================================================================
  assign bctl_tlb_enabled_d = i_bctl_tlb_enabled;
  assign bctl_maint_cmd_d   = i_bctl_maint_cmd;
  assign bctl_maint_wr_en_d = i_bctl_maint_wr_en;
  assign bctl_virt_adr_d    = i_bctl_virt_adr;
  assign bctl_phys_adr_d    = i_bctl_phys_adr;
  assign bctl_entry_valid_d = i_bctl_entry_valid;
  assign bctl_drop_d        = {ni4_drop, ni3_drop, ni2_drop, 
                               ni1_drop, ni0_drop};

  assign tlb_wr_en          = bctl_maint_cmd_q & bctl_maint_wr_en_q;
  assign tlb_wr_phys_adr    = bctl_phys_adr_q;
  assign tlb_wr_virt_adr    = bctl_virt_adr_q;
  assign tlb_wr_entry_valid = bctl_entry_valid_q;
  assign o_bctl_drop        = bctl_drop_q;


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_ni) begin
     if(rst_ni)begin
        bctl_tlb_enabled_q <= #`dh 0;
        bctl_maint_cmd_q   <= #`dh 1'b0;
        bctl_maint_wr_en_q <= #`dh 1'b0;
     end
     else begin
        bctl_tlb_enabled_q <= #`dh bctl_tlb_enabled_d;
        bctl_maint_cmd_q   <= #`dh bctl_maint_cmd_d;
        bctl_maint_wr_en_q <= #`dh bctl_maint_wr_en_d;
     end
  end
  
  always @(posedge clk_ni) begin
      bctl_phys_adr_q      <= #`dh bctl_phys_adr_d;
      bctl_virt_adr_q      <= #`dh bctl_virt_adr_d;
      bctl_entry_valid_q   <= #`dh bctl_entry_valid_d;
      tlb_rd_data          <= #`dh tlb_wr_virt_adr[11] ? tlb_rd_data1 : 
                                                         tlb_rd_data0;
  end


  always @(posedge clk_ddr) begin
    if (rst_ddr) begin
      bctl_drop_q             <= #`dh 0;
      free_mask_q             <= #`dh 4'b1111;
      ni0_active_q            <= #`dh 0;
      ni1_active_q            <= #`dh 0;
      ni2_active_q            <= #`dh 0;
      ni3_active_q            <= #`dh 0;
      ni4_active_q            <= #`dh 0;
      ni0_dst_q               <= #`dh 0;
      ni1_dst_q               <= #`dh 0;
      ni2_dst_q               <= #`dh 0;
      ni3_dst_q               <= #`dh 0;
      ni4_dst_q               <= #`dh 0;
      ddr0_src_q              <= #`dh 0;
      ddr1_src_q              <= #`dh 0;
      ddr2_src_q              <= #`dh 0;
      ddr3_src_q              <= #`dh 0;
    end
    else begin
      bctl_drop_q              <= #`dh bctl_drop_d;
      free_mask_q              <= #`dh free_mask_d;
      ni0_active_q             <= #`dh ni0_active_d;
      ni1_active_q             <= #`dh ni1_active_d;
      ni2_active_q             <= #`dh ni2_active_d;
      ni3_active_q             <= #`dh ni3_active_d;
      ni4_active_q             <= #`dh ni4_active_d;
      ni0_dst_q                <= #`dh ni0_dst_d;
      ni1_dst_q                <= #`dh ni1_dst_d;
      ni2_dst_q                <= #`dh ni2_dst_d;
      ni3_dst_q                <= #`dh ni3_dst_d;
      ni4_dst_q                <= #`dh ni4_dst_d;
      ddr0_src_q               <= #`dh ddr0_src_d;
      ddr1_src_q               <= #`dh ddr1_src_d;
      ddr2_src_q               <= #`dh ddr2_src_d;
      ddr3_src_q               <= #`dh ddr3_src_d;
    end
  end
  
  always @(posedge clk_ddr) begin
    bctl_tlb_enabled_sync0_q   <= #`dh bctl_tlb_enabled_q;
    bctl_tlb_enabled_sync1_q   <= #`dh bctl_tlb_enabled_sync0_q;
    tlb_rd_virt_adr_q          <= #`dh tlb_rd_virt_adr_d;
    ni0_gnt_q                  <= #`dh ni0_gnt_d;
    ni1_gnt_q                  <= #`dh ni1_gnt_d;
    ni2_gnt_q                  <= #`dh ni2_gnt_d;
    ni3_gnt_q                  <= #`dh ni3_gnt_d;
    ni4_gnt_q                  <= #`dh ni4_gnt_d;
  end

endmodule
