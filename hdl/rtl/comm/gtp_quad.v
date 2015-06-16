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
// Abstract      : 4xGTP top-level module for Formic Spartan-6
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: gtp_quad.v,v $
// CVS revision  : $Revision: 1.8 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module gtp_quad (

  // Front end clocks and resets
  input         clk_gtp,
  input         clk_xbar,
  input         rst_xbar,
  input         rst_master_assert,
  input         rst_gtp_deassert,

  // Back end physical GTP blocks clocking/reset signals
  input         aref_clk_p,
  input         aref_clk_n,
  input         rst_gtp_phy,
  output        o_ref_clk,
  output        o_ref_clk_locked,
  input         i_gtp_clk_locked,
  input         clk_gtp_2x,
  output        o_gtp_init_done,

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

  // Physical RX/TX pairs
  input         i_gtp0_rx_p,
  input         i_gtp0_rx_n,
  output        o_gtp0_tx_p,
  output        o_gtp0_tx_n,
  input         i_gtp1_rx_p,
  input         i_gtp1_rx_n,
  output        o_gtp1_tx_p,
  output        o_gtp1_tx_n,
  input         i_gtp2_rx_p,
  input         i_gtp2_rx_n,
  output        o_gtp2_tx_p,
  output        o_gtp2_tx_n,
  input         i_gtp3_rx_p,
  input         i_gtp3_rx_n,
  output        o_gtp3_tx_p,
  output        o_gtp3_tx_n,

  // Status bits
  output reg [3:0] o_link_up,
  output reg [3:0] o_link_error,
  output reg [3:0] o_credit_error,
  output reg [3:0] o_crc_error
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire  [2:0] xbi0_out_enq;
  wire  [5:0] xbi0_out_offset;
  wire        xbi0_out_eop;
  wire [15:0] xbi0_out_data;
  wire  [2:0] xbi0_out_full;
  wire  [2:0] xbi0_in_deq;
  wire  [5:0] xbi0_in_offset;
  wire        xbi0_in_eop;
  wire [15:0] xbi0_in_data;
  wire  [2:0] xbi0_in_empty;

  wire  [2:0] xbi1_out_enq;
  wire  [5:0] xbi1_out_offset;
  wire        xbi1_out_eop;
  wire [15:0] xbi1_out_data;
  wire  [2:0] xbi1_out_full;
  wire  [2:0] xbi1_in_deq;
  wire  [5:0] xbi1_in_offset;
  wire        xbi1_in_eop;
  wire [15:0] xbi1_in_data;
  wire  [2:0] xbi1_in_empty;

  wire  [2:0] xbi2_out_enq;
  wire  [5:0] xbi2_out_offset;
  wire        xbi2_out_eop;
  wire [15:0] xbi2_out_data;
  wire  [2:0] xbi2_out_full;
  wire  [2:0] xbi2_in_deq;
  wire  [5:0] xbi2_in_offset;
  wire        xbi2_in_eop;
  wire [15:0] xbi2_in_data;
  wire  [2:0] xbi2_in_empty;

  wire  [2:0] xbi3_out_enq;
  wire  [5:0] xbi3_out_offset;
  wire        xbi3_out_eop;
  wire [15:0] xbi3_out_data;
  wire  [2:0] xbi3_out_full;
  wire  [2:0] xbi3_in_deq;
  wire  [5:0] xbi3_in_offset;
  wire        xbi3_in_eop;
  wire [15:0] xbi3_in_data;
  wire  [2:0] xbi3_in_empty;

  wire        link0_up;
  wire        link0_error;
  wire        link0_out_valid;
  wire        link0_out_sop;
  wire        link0_out_eop;
  wire [15:0] link0_out_data;
  wire  [2:0] link0_out_vc_enq;
  wire  [2:0] link0_out_xoff;
  wire        link0_in_valid;
  wire        link0_in_sop;
  wire        link0_in_eop;
  wire [15:0] link0_in_data;
  wire  [2:0] link0_in_vc_deq;

  wire        link1_up;
  wire        link1_error;
  wire        link1_out_valid;
  wire        link1_out_sop;
  wire        link1_out_eop;
  wire [15:0] link1_out_data;
  wire  [2:0] link1_out_vc_enq;
  wire  [2:0] link1_out_xoff;
  wire        link1_in_valid;
  wire        link1_in_sop;
  wire        link1_in_eop;
  wire [15:0] link1_in_data;
  wire  [2:0] link1_in_vc_deq;

  wire        link2_up;
  wire        link2_error;
  wire        link2_out_valid;
  wire        link2_out_sop;
  wire        link2_out_eop;
  wire [15:0] link2_out_data;
  wire  [2:0] link2_out_vc_enq;
  wire  [2:0] link2_out_xoff;
  wire        link2_in_valid;
  wire        link2_in_sop;
  wire        link2_in_eop;
  wire [15:0] link2_in_data;
  wire  [2:0] link2_in_vc_deq;

  wire        link3_up;
  wire        link3_error;
  wire        link3_out_valid;
  wire        link3_out_sop;
  wire        link3_out_eop;
  wire [15:0] link3_out_data;
  wire  [2:0] link3_out_vc_enq;
  wire  [2:0] link3_out_xoff;
  wire        link3_in_valid;
  wire        link3_in_sop;
  wire        link3_in_eop;
  wire [15:0] link3_in_data;
  wire  [2:0] link3_in_vc_deq;

  
  // ==========================================================================
  // Reset generation
  // ==========================================================================
  rst_sync_simple # (
    .CLOCK_CYCLES       ( 4 )
  ) i0_rst_sync_simple (
    .clk                ( clk_gtp ),
    .rst_async          ( rst_master_assert ),
    .deassert           ( rst_gtp_deassert ),
    .rst                ( rst_gtp )
  );


  // ==========================================================================
  // Quad GTP back end (2 x dual GTP banks, all located on same FPGA side)
  // ==========================================================================
  gtp_quad_back_end i0_gtp_quad_back_end (
    .aref_clk_p             ( aref_clk_p ),
    .aref_clk_n             ( aref_clk_n ),
    .rst_gtp_phy            ( rst_gtp_phy ),
    .o_ref_clk              ( o_ref_clk ),
    .o_ref_clk_locked       ( o_ref_clk_locked ),
    .i_gtp_clk_locked       ( i_gtp_clk_locked ),
    .clk_gtp_2x             ( clk_gtp_2x ),
    .o_gtp_init_done        ( o_gtp_init_done ),
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .i_gtp0_rx_p            ( i_gtp0_rx_p ),
    .i_gtp0_rx_n            ( i_gtp0_rx_n ),
    .o_gtp0_tx_p            ( o_gtp0_tx_p ),
    .o_gtp0_tx_n            ( o_gtp0_tx_n ),
    .i_gtp1_rx_p            ( i_gtp1_rx_p ),
    .i_gtp1_rx_n            ( i_gtp1_rx_n ),
    .o_gtp1_tx_p            ( o_gtp1_tx_p ),
    .o_gtp1_tx_n            ( o_gtp1_tx_n ),
    .i_gtp2_rx_p            ( i_gtp2_rx_p ),
    .i_gtp2_rx_n            ( i_gtp2_rx_n ),
    .o_gtp2_tx_p            ( o_gtp2_tx_p ),
    .o_gtp2_tx_n            ( o_gtp2_tx_n ),
    .i_gtp3_rx_p            ( i_gtp3_rx_p ),
    .i_gtp3_rx_n            ( i_gtp3_rx_n ),
    .o_gtp3_tx_p            ( o_gtp3_tx_p ),
    .o_gtp3_tx_n            ( o_gtp3_tx_n ),
    .o_link0_up             ( link0_up ),
    .o_link0_error          ( link0_error ),
    .i_link0_powerdown      ( 1'b0 ),
    .i_link0_valid          ( link0_out_valid ),
    .i_link0_sop            ( link0_out_sop ),
    .i_link0_eop            ( link0_out_eop ),
    .i_link0_data           ( link0_out_data ),
    .i_link0_vc_enq         ( link0_out_vc_enq ),
    .o_link0_xoff           ( link0_out_xoff ),
    .o_link0_valid          ( link0_in_valid ),
    .o_link0_sop            ( link0_in_sop ),
    .o_link0_eop            ( link0_in_eop ),
    .o_link0_data           ( link0_in_data ),
    .i_link0_vc_deq         ( link0_in_vc_deq ),
    .i_link1_powerdown      ( 1'b0 ),
    .o_link1_up             ( link1_up ),
    .o_link1_error          ( link1_error ),
    .i_link1_valid          ( link1_out_valid ),
    .i_link1_sop            ( link1_out_sop ),
    .i_link1_eop            ( link1_out_eop ),
    .i_link1_data           ( link1_out_data ),
    .i_link1_vc_enq         ( link1_out_vc_enq ),
    .o_link1_xoff           ( link1_out_xoff ),
    .o_link1_valid          ( link1_in_valid ),
    .o_link1_sop            ( link1_in_sop ),
    .o_link1_eop            ( link1_in_eop ),
    .o_link1_data           ( link1_in_data ),
    .i_link1_vc_deq         ( link1_in_vc_deq ),
    .i_link2_powerdown      ( 1'b0 ),
    .o_link2_up             ( link2_up ),
    .o_link2_error          ( link2_error ),
    .i_link2_valid          ( link2_out_valid ),
    .i_link2_sop            ( link2_out_sop ),
    .i_link2_eop            ( link2_out_eop ),
    .i_link2_data           ( link2_out_data ),
    .i_link2_vc_enq         ( link2_out_vc_enq ),
    .o_link2_xoff           ( link2_out_xoff ),
    .o_link2_valid          ( link2_in_valid ),
    .o_link2_sop            ( link2_in_sop ),
    .o_link2_eop            ( link2_in_eop ),
    .o_link2_data           ( link2_in_data ),
    .i_link2_vc_deq         ( link2_in_vc_deq ),
    .i_link3_powerdown      ( 1'b0 ),
    .o_link3_up             ( link3_up ),
    .o_link3_error          ( link3_error ),
    .i_link3_valid          ( link3_out_valid ),
    .i_link3_sop            ( link3_out_sop ),
    .i_link3_eop            ( link3_out_eop ),
    .i_link3_data           ( link3_out_data ),
    .i_link3_vc_enq         ( link3_out_vc_enq ),
    .o_link3_xoff           ( link3_out_xoff ),
    .o_link3_valid          ( link3_in_valid ),
    .o_link3_sop            ( link3_in_sop ),
    .o_link3_eop            ( link3_in_eop ),
    .o_link3_data           ( link3_in_data ),
    .i_link3_vc_deq         ( link3_in_vc_deq )
  );


  // ==========================================================================
  // Crossbar interface FIFOs
  // ==========================================================================
  xbi i0_xbi (
    .clk_usr                ( clk_gtp ),
    .rst_usr                ( rst_gtp ),
    .i_usr_nout_enq         ( xbi0_out_enq ),
    .i_usr_nout_offset      ( xbi0_out_offset ),
    .i_usr_nout_eop         ( xbi0_out_eop ),
    .i_usr_nout_data        ( xbi0_out_data ),
    .o_usr_nout_full        ( xbi0_out_full ),
    .o_usr_nout_packets_vc0 ( ),
    .o_usr_nout_packets_vc1 ( ),
    .o_usr_nout_packets_vc2 ( ),
    .i_usr_nin_deq          ( xbi0_in_deq ),
    .i_usr_nin_offset       ( xbi0_in_offset ),
    .i_usr_nin_eop          ( xbi0_in_eop ),
    .o_usr_nin_data         ( xbi0_in_data ),
    .o_usr_nin_empty        ( xbi0_in_empty ),
    .o_usr_nin_packets_vc0  ( ),
    .o_usr_nin_packets_vc1  ( ),
    .o_usr_nin_packets_vc2  ( ),
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

  xbi i1_xbi (
    .clk_usr                ( clk_gtp ),
    .rst_usr                ( rst_gtp ),
    .i_usr_nout_enq         ( xbi1_out_enq ),
    .i_usr_nout_offset      ( xbi1_out_offset ),
    .i_usr_nout_eop         ( xbi1_out_eop ),
    .i_usr_nout_data        ( xbi1_out_data ),
    .o_usr_nout_full        ( xbi1_out_full ),
    .o_usr_nout_packets_vc0 ( ),
    .o_usr_nout_packets_vc1 ( ),
    .o_usr_nout_packets_vc2 ( ),
    .i_usr_nin_deq          ( xbi1_in_deq ),
    .i_usr_nin_offset       ( xbi1_in_offset ),
    .i_usr_nin_eop          ( xbi1_in_eop ),
    .o_usr_nin_data         ( xbi1_in_data ),
    .o_usr_nin_empty        ( xbi1_in_empty ),
    .o_usr_nin_packets_vc0  ( ),
    .o_usr_nin_packets_vc1  ( ),
    .o_usr_nin_packets_vc2  ( ),
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

  xbi i2_xbi (
    .clk_usr                ( clk_gtp ),
    .rst_usr                ( rst_gtp ),
    .i_usr_nout_enq         ( xbi2_out_enq ),
    .i_usr_nout_offset      ( xbi2_out_offset ),
    .i_usr_nout_eop         ( xbi2_out_eop ),
    .i_usr_nout_data        ( xbi2_out_data ),
    .o_usr_nout_full        ( xbi2_out_full ),
    .o_usr_nout_packets_vc0 ( ),
    .o_usr_nout_packets_vc1 ( ),
    .o_usr_nout_packets_vc2 ( ),
    .i_usr_nin_deq          ( xbi2_in_deq ),
    .i_usr_nin_offset       ( xbi2_in_offset ),
    .i_usr_nin_eop          ( xbi2_in_eop ),
    .o_usr_nin_data         ( xbi2_in_data ),
    .o_usr_nin_empty        ( xbi2_in_empty ),
    .o_usr_nin_packets_vc0  ( ),
    .o_usr_nin_packets_vc1  ( ),
    .o_usr_nin_packets_vc2  ( ),
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

  xbi i3_xbi (
    .clk_usr                ( clk_gtp ),
    .rst_usr                ( rst_gtp ),
    .i_usr_nout_enq         ( xbi3_out_enq ),
    .i_usr_nout_offset      ( xbi3_out_offset ),
    .i_usr_nout_eop         ( xbi3_out_eop ),
    .i_usr_nout_data        ( xbi3_out_data ),
    .o_usr_nout_full        ( xbi3_out_full ),
    .o_usr_nout_packets_vc0 ( ),
    .o_usr_nout_packets_vc1 ( ),
    .o_usr_nout_packets_vc2 ( ),
    .i_usr_nin_deq          ( xbi3_in_deq ),
    .i_usr_nin_offset       ( xbi3_in_offset ),
    .i_usr_nin_eop          ( xbi3_in_eop ),
    .o_usr_nin_data         ( xbi3_in_data ),
    .o_usr_nin_empty        ( xbi3_in_empty ),
    .o_usr_nin_packets_vc0  ( ),
    .o_usr_nin_packets_vc1  ( ),
    .o_usr_nin_packets_vc2  ( ),
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


  // ==========================================================================
  // XBI -> GTP network interfaces
  // ==========================================================================
  gtp_nin i0_gtp_nin (
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .o_xbi_nin_deq          ( xbi0_in_deq ),
    .o_xbi_nin_offset       ( xbi0_in_offset ),
    .o_xbi_nin_eop          ( xbi0_in_eop ),
    .i_xbi_nin_data         ( xbi0_in_data ),
    .i_xbi_nin_empty        ( xbi0_in_empty ),
    .o_gtp_out_valid        ( link0_out_valid ),
    .o_gtp_out_sop          ( link0_out_sop ),
    .o_gtp_out_eop          ( link0_out_eop ),
    .o_gtp_out_data         ( link0_out_data ),
    .o_gtp_out_vc_enq       ( link0_out_vc_enq ),
    .i_gtp_out_xoff         ( link0_out_xoff )
  );

  gtp_nin i1_gtp_nin (
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .o_xbi_nin_deq          ( xbi1_in_deq ),
    .o_xbi_nin_offset       ( xbi1_in_offset ),
    .o_xbi_nin_eop          ( xbi1_in_eop ),
    .i_xbi_nin_data         ( xbi1_in_data ),
    .i_xbi_nin_empty        ( xbi1_in_empty ),
    .o_gtp_out_valid        ( link1_out_valid ),
    .o_gtp_out_sop          ( link1_out_sop ),
    .o_gtp_out_eop          ( link1_out_eop ),
    .o_gtp_out_data         ( link1_out_data ),
    .o_gtp_out_vc_enq       ( link1_out_vc_enq ),
    .i_gtp_out_xoff         ( link1_out_xoff )
  );

  gtp_nin i2_gtp_nin (
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .o_xbi_nin_deq          ( xbi2_in_deq ),
    .o_xbi_nin_offset       ( xbi2_in_offset ),
    .o_xbi_nin_eop          ( xbi2_in_eop ),
    .i_xbi_nin_data         ( xbi2_in_data ),
    .i_xbi_nin_empty        ( xbi2_in_empty ),
    .o_gtp_out_valid        ( link2_out_valid ),
    .o_gtp_out_sop          ( link2_out_sop ),
    .o_gtp_out_eop          ( link2_out_eop ),
    .o_gtp_out_data         ( link2_out_data ),
    .o_gtp_out_vc_enq       ( link2_out_vc_enq ),
    .i_gtp_out_xoff         ( link2_out_xoff )
  );

  gtp_nin i3_gtp_nin (
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .o_xbi_nin_deq          ( xbi3_in_deq ),
    .o_xbi_nin_offset       ( xbi3_in_offset ),
    .o_xbi_nin_eop          ( xbi3_in_eop ),
    .i_xbi_nin_data         ( xbi3_in_data ),
    .i_xbi_nin_empty        ( xbi3_in_empty ),
    .o_gtp_out_valid        ( link3_out_valid ),
    .o_gtp_out_sop          ( link3_out_sop ),
    .o_gtp_out_eop          ( link3_out_eop ),
    .o_gtp_out_data         ( link3_out_data ),
    .o_gtp_out_vc_enq       ( link3_out_vc_enq ),
    .i_gtp_out_xoff         ( link3_out_xoff )
  );

  
  // ==========================================================================
  // GTP -> XBI network interfaces
  // ==========================================================================
  gtp_nout i0_gtp_nout (
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_in_deq          ( i_xbar0_in_deq ),
    .i_xbar_in_eop          ( i_xbar0_in_eop ),
    .i_gtp_in_valid         ( link0_in_valid ),
    .i_gtp_in_sop           ( link0_in_sop ),
    .i_gtp_in_eop           ( link0_in_eop ),
    .i_gtp_in_data          ( link0_in_data ),
    .o_gtp_in_vc_deq        ( link0_in_vc_deq ),
    .o_xbi_nout_enq         ( xbi0_out_enq ),
    .o_xbi_nout_offset      ( xbi0_out_offset ),
    .o_xbi_nout_eop         ( xbi0_out_eop ),
    .o_xbi_nout_data        ( xbi0_out_data ),
    .i_xbi_nout_full        ( xbi0_out_full ),
    .o_error_crc            ( link0_crc_error ),
    .o_error_credit         ( link0_credit_error )
  );

  gtp_nout i1_gtp_nout (
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_in_deq          ( i_xbar1_in_deq ),
    .i_xbar_in_eop          ( i_xbar1_in_eop ),
    .i_gtp_in_valid         ( link1_in_valid ),
    .i_gtp_in_sop           ( link1_in_sop ),
    .i_gtp_in_eop           ( link1_in_eop ),
    .i_gtp_in_data          ( link1_in_data ),
    .o_gtp_in_vc_deq        ( link1_in_vc_deq ),
    .o_xbi_nout_enq         ( xbi1_out_enq ),
    .o_xbi_nout_offset      ( xbi1_out_offset ),
    .o_xbi_nout_eop         ( xbi1_out_eop ),
    .o_xbi_nout_data        ( xbi1_out_data ),
    .i_xbi_nout_full        ( xbi1_out_full ),
    .o_error_crc            ( link1_crc_error ),
    .o_error_credit         ( link1_credit_error )
  );

  gtp_nout i2_gtp_nout (
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_in_deq          ( i_xbar2_in_deq ),
    .i_xbar_in_eop          ( i_xbar2_in_eop ),
    .i_gtp_in_valid         ( link2_in_valid ),
    .i_gtp_in_sop           ( link2_in_sop ),
    .i_gtp_in_eop           ( link2_in_eop ),
    .i_gtp_in_data          ( link2_in_data ),
    .o_gtp_in_vc_deq        ( link2_in_vc_deq ),
    .o_xbi_nout_enq         ( xbi2_out_enq ),
    .o_xbi_nout_offset      ( xbi2_out_offset ),
    .o_xbi_nout_eop         ( xbi2_out_eop ),
    .o_xbi_nout_data        ( xbi2_out_data ),
    .i_xbi_nout_full        ( xbi2_out_full ),
    .o_error_crc            ( link2_crc_error ),
    .o_error_credit         ( link2_credit_error )
  );

  gtp_nout i3_gtp_nout (
    .clk_gtp                ( clk_gtp ),
    .rst_gtp                ( rst_gtp ),
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_in_deq          ( i_xbar3_in_deq ),
    .i_xbar_in_eop          ( i_xbar3_in_eop ),
    .i_gtp_in_valid         ( link3_in_valid ),
    .i_gtp_in_sop           ( link3_in_sop ),
    .i_gtp_in_eop           ( link3_in_eop ),
    .i_gtp_in_data          ( link3_in_data ),
    .o_gtp_in_vc_deq        ( link3_in_vc_deq ),
    .o_xbi_nout_enq         ( xbi3_out_enq ),
    .o_xbi_nout_offset      ( xbi3_out_offset ),
    .o_xbi_nout_eop         ( xbi3_out_eop ),
    .o_xbi_nout_data        ( xbi3_out_data ),
    .i_xbi_nout_full        ( xbi3_out_full ),
    .o_error_crc            ( link3_crc_error ),
    .o_error_credit         ( link3_credit_error )
  );

  always @(posedge clk_gtp) begin
    o_link_up       <= {link3_up, link2_up, link1_up, link0_up};
    o_link_error    <= {link3_error, link2_error, link1_error, link0_error};
    o_credit_error  <= {link3_credit_error, link2_credit_error, 
                        link1_credit_error, link0_credit_error};
    o_crc_error     <= {link3_crc_error, link2_crc_error, 
                        link1_crc_error, link0_crc_error};
  end

endmodule



