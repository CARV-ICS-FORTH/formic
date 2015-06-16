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
// Abstract      : Reduced 14-port Crossbar top-level module (excludes the
//                 8 GTP ports)
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbar_formic_m8.v,v $
// CVS revision  : $Revision: 1.2 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbar_formic_m8 (
  
  // Clock and reset
  input         clk_xbar,
  input         rst_xbar,

  // Static configuration
  input   [7:0] i_board_id,

  // Port #00 interface
  output  [2:0] o_port00_out_enq,
  output  [5:0] o_port00_out_offset,
  output        o_port00_out_eop,
  output [15:0] o_port00_out_data,
  input   [2:0] i_port00_out_full,
  input   [2:0] i_port00_out_packets_vc0,
  input   [2:0] i_port00_out_packets_vc1,
  input   [2:0] i_port00_out_packets_vc2,
  output  [2:0] o_port00_in_deq,
  output  [5:0] o_port00_in_offset,
  output        o_port00_in_eop,
  input  [15:0] i_port00_in_data,
  input   [2:0] i_port00_in_empty,

  // Port #01 interface
  output  [2:0] o_port01_out_enq,
  output  [5:0] o_port01_out_offset,
  output        o_port01_out_eop,
  output [15:0] o_port01_out_data,
  input   [2:0] i_port01_out_full,
  input   [2:0] i_port01_out_packets_vc0,
  input   [2:0] i_port01_out_packets_vc1,
  input   [2:0] i_port01_out_packets_vc2,
  output  [2:0] o_port01_in_deq,
  output  [5:0] o_port01_in_offset,
  output        o_port01_in_eop,
  input  [15:0] i_port01_in_data,
  input   [2:0] i_port01_in_empty,

  // Port #02 interface
  output  [2:0] o_port02_out_enq,
  output  [5:0] o_port02_out_offset,
  output        o_port02_out_eop,
  output [15:0] o_port02_out_data,
  input   [2:0] i_port02_out_full,
  input   [2:0] i_port02_out_packets_vc0,
  input   [2:0] i_port02_out_packets_vc1,
  input   [2:0] i_port02_out_packets_vc2,
  output  [2:0] o_port02_in_deq,
  output  [5:0] o_port02_in_offset,
  output        o_port02_in_eop,
  input  [15:0] i_port02_in_data,
  input   [2:0] i_port02_in_empty,

  // Port #03 interface
  output  [2:0] o_port03_out_enq,
  output  [5:0] o_port03_out_offset,
  output        o_port03_out_eop,
  output [15:0] o_port03_out_data,
  input   [2:0] i_port03_out_full,
  input   [2:0] i_port03_out_packets_vc0,
  input   [2:0] i_port03_out_packets_vc1,
  input   [2:0] i_port03_out_packets_vc2,
  output  [2:0] o_port03_in_deq,
  output  [5:0] o_port03_in_offset,
  output        o_port03_in_eop,
  input  [15:0] i_port03_in_data,
  input   [2:0] i_port03_in_empty,

  // Port #04 interface
  output  [2:0] o_port04_out_enq,
  output  [5:0] o_port04_out_offset,
  output        o_port04_out_eop,
  output [15:0] o_port04_out_data,
  input   [2:0] i_port04_out_full,
  input   [2:0] i_port04_out_packets_vc0,
  input   [2:0] i_port04_out_packets_vc1,
  input   [2:0] i_port04_out_packets_vc2,
  output  [2:0] o_port04_in_deq,
  output  [5:0] o_port04_in_offset,
  output        o_port04_in_eop,
  input  [15:0] i_port04_in_data,
  input   [2:0] i_port04_in_empty,

  // Port #05 interface
  output  [2:0] o_port05_out_enq,
  output  [5:0] o_port05_out_offset,
  output        o_port05_out_eop,
  output [15:0] o_port05_out_data,
  input   [2:0] i_port05_out_full,
  input   [2:0] i_port05_out_packets_vc0,
  input   [2:0] i_port05_out_packets_vc1,
  input   [2:0] i_port05_out_packets_vc2,
  output  [2:0] o_port05_in_deq,
  output  [5:0] o_port05_in_offset,
  output        o_port05_in_eop,
  input  [15:0] i_port05_in_data,
  input   [2:0] i_port05_in_empty,

  // Port #06 interface
  output  [2:0] o_port06_out_enq,
  output  [5:0] o_port06_out_offset,
  output        o_port06_out_eop,
  output [15:0] o_port06_out_data,
  input   [2:0] i_port06_out_full,
  input   [2:0] i_port06_out_packets_vc0,
  input   [2:0] i_port06_out_packets_vc1,
  input   [2:0] i_port06_out_packets_vc2,
  output  [2:0] o_port06_in_deq,
  output  [5:0] o_port06_in_offset,
  output        o_port06_in_eop,
  input  [15:0] i_port06_in_data,
  input   [2:0] i_port06_in_empty,

  // Port #07 interface
  output  [2:0] o_port07_out_enq,
  output  [5:0] o_port07_out_offset,
  output        o_port07_out_eop,
  output [15:0] o_port07_out_data,
  input   [2:0] i_port07_out_full,
  input   [2:0] i_port07_out_packets_vc0,
  input   [2:0] i_port07_out_packets_vc1,
  input   [2:0] i_port07_out_packets_vc2,
  output  [2:0] o_port07_in_deq,
  output  [5:0] o_port07_in_offset,
  output        o_port07_in_eop,
  input  [15:0] i_port07_in_data,
  input   [2:0] i_port07_in_empty,

  // Port #16 interface
  output  [2:0] o_port16_out_enq,
  output  [5:0] o_port16_out_offset,
  output        o_port16_out_eop,
  output [15:0] o_port16_out_data,
  input   [2:0] i_port16_out_full,
  input   [2:0] i_port16_out_packets_vc0,
  input   [2:0] i_port16_out_packets_vc1,
  input   [2:0] i_port16_out_packets_vc2,
  output  [2:0] o_port16_in_deq,
  output  [5:0] o_port16_in_offset,
  output        o_port16_in_eop,
  input  [15:0] i_port16_in_data,
  input   [2:0] i_port16_in_empty,

  // Port #17 interface
  output  [2:0] o_port17_out_enq,
  output  [5:0] o_port17_out_offset,
  output        o_port17_out_eop,
  output [15:0] o_port17_out_data,
  input   [2:0] i_port17_out_full,
  input   [2:0] i_port17_out_packets_vc0,
  input   [2:0] i_port17_out_packets_vc1,
  input   [2:0] i_port17_out_packets_vc2,
  output  [2:0] o_port17_in_deq,
  output  [5:0] o_port17_in_offset,
  output        o_port17_in_eop,
  input  [15:0] i_port17_in_data,
  input   [2:0] i_port17_in_empty,

  // Port #18 interface
  output  [2:0] o_port18_out_enq,
  output  [5:0] o_port18_out_offset,
  output        o_port18_out_eop,
  output [15:0] o_port18_out_data,
  input   [2:0] i_port18_out_full,
  input   [2:0] i_port18_out_packets_vc0,
  input   [2:0] i_port18_out_packets_vc1,
  input   [2:0] i_port18_out_packets_vc2,
  output  [2:0] o_port18_in_deq,
  output  [5:0] o_port18_in_offset,
  output        o_port18_in_eop,
  input  [15:0] i_port18_in_data,
  input   [2:0] i_port18_in_empty,

  // Port #19 interface
  output  [2:0] o_port19_out_enq,
  output  [5:0] o_port19_out_offset,
  output        o_port19_out_eop,
  output [15:0] o_port19_out_data,
  input   [2:0] i_port19_out_full,
  input   [2:0] i_port19_out_packets_vc0,
  input   [2:0] i_port19_out_packets_vc1,
  input   [2:0] i_port19_out_packets_vc2,
  output  [2:0] o_port19_in_deq,
  output  [5:0] o_port19_in_offset,
  output        o_port19_in_eop,
  input  [15:0] i_port19_in_data,
  input   [2:0] i_port19_in_empty,

  // Port #20 interface
  output  [2:0] o_port20_out_enq,
  output  [5:0] o_port20_out_offset,
  output        o_port20_out_eop,
  output [15:0] o_port20_out_data,
  input   [2:0] i_port20_out_full,
  input   [2:0] i_port20_out_packets_vc0,
  input   [2:0] i_port20_out_packets_vc1,
  input   [2:0] i_port20_out_packets_vc2,
  output  [2:0] o_port20_in_deq,
  output  [5:0] o_port20_in_offset,
  output        o_port20_in_eop,
  input  [15:0] i_port20_in_data,
  input   [2:0] i_port20_in_empty,

  // Port #21 interface
  output  [2:0] o_port21_out_enq,
  output  [5:0] o_port21_out_offset,
  output        o_port21_out_eop,
  output [15:0] o_port21_out_data,
  input   [2:0] i_port21_out_full,
  input   [2:0] i_port21_out_packets_vc0,
  input   [2:0] i_port21_out_packets_vc1,
  input   [2:0] i_port21_out_packets_vc2,
  output  [2:0] o_port21_in_deq,
  output  [5:0] o_port21_in_offset,
  output        o_port21_in_eop,
  input  [15:0] i_port21_in_data,
  input   [2:0] i_port21_in_empty
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  wire [21:0] arbin00_req0;
  wire [21:0] arbin00_req1;
  wire [21:0] arbin00_req2;
  wire [21:0] arbin00_gnt0;
  wire [21:0] arbin00_gnt1;
  wire [21:0] arbin00_gnt2;
  wire [15:0] arbin00_data;

  wire [21:0] arbin01_req0;
  wire [21:0] arbin01_req1;
  wire [21:0] arbin01_req2;
  wire [21:0] arbin01_gnt0;
  wire [21:0] arbin01_gnt1;
  wire [21:0] arbin01_gnt2;
  wire [15:0] arbin01_data;

  wire [21:0] arbin02_req0;
  wire [21:0] arbin02_req1;
  wire [21:0] arbin02_req2;
  wire [21:0] arbin02_gnt0;
  wire [21:0] arbin02_gnt1;
  wire [21:0] arbin02_gnt2;
  wire [15:0] arbin02_data;

  wire [21:0] arbin03_req0;
  wire [21:0] arbin03_req1;
  wire [21:0] arbin03_req2;
  wire [21:0] arbin03_gnt0;
  wire [21:0] arbin03_gnt1;
  wire [21:0] arbin03_gnt2;
  wire [15:0] arbin03_data;

  wire [21:0] arbin04_req0;
  wire [21:0] arbin04_req1;
  wire [21:0] arbin04_req2;
  wire [21:0] arbin04_gnt0;
  wire [21:0] arbin04_gnt1;
  wire [21:0] arbin04_gnt2;
  wire [15:0] arbin04_data;

  wire [21:0] arbin05_req0;
  wire [21:0] arbin05_req1;
  wire [21:0] arbin05_req2;
  wire [21:0] arbin05_gnt0;
  wire [21:0] arbin05_gnt1;
  wire [21:0] arbin05_gnt2;
  wire [15:0] arbin05_data;

  wire [21:0] arbin06_req0;
  wire [21:0] arbin06_req1;
  wire [21:0] arbin06_req2;
  wire [21:0] arbin06_gnt0;
  wire [21:0] arbin06_gnt1;
  wire [21:0] arbin06_gnt2;
  wire [15:0] arbin06_data;

  wire [21:0] arbin07_req0;
  wire [21:0] arbin07_req1;
  wire [21:0] arbin07_req2;
  wire [21:0] arbin07_gnt0;
  wire [21:0] arbin07_gnt1;
  wire [21:0] arbin07_gnt2;
  wire [15:0] arbin07_data;

  wire [21:0] arbin16_req0;
  wire [21:0] arbin16_req1;
  wire [21:0] arbin16_req2;
  wire [21:0] arbin16_gnt0;
  wire [21:0] arbin16_gnt1;
  wire [21:0] arbin16_gnt2;
  wire [15:0] arbin16_data;

  wire [21:0] arbin17_req0;
  wire [21:0] arbin17_req1;
  wire [21:0] arbin17_req2;
  wire [21:0] arbin17_gnt0;
  wire [21:0] arbin17_gnt1;
  wire [21:0] arbin17_gnt2;
  wire [15:0] arbin17_data;

  wire [21:0] arbin18_req0;
  wire [21:0] arbin18_req1;
  wire [21:0] arbin18_req2;
  wire [21:0] arbin18_gnt0;
  wire [21:0] arbin18_gnt1;
  wire [21:0] arbin18_gnt2;
  wire [15:0] arbin18_data;

  wire [21:0] arbin19_req0;
  wire [21:0] arbin19_req1;
  wire [21:0] arbin19_req2;
  wire [21:0] arbin19_gnt0;
  wire [21:0] arbin19_gnt1;
  wire [21:0] arbin19_gnt2;
  wire [15:0] arbin19_data;

  wire [21:0] arbin20_req0;
  wire [21:0] arbin20_req1;
  wire [21:0] arbin20_req2;
  wire [21:0] arbin20_gnt0;
  wire [21:0] arbin20_gnt1;
  wire [21:0] arbin20_gnt2;
  wire [15:0] arbin20_data;

  wire [21:0] arbin21_req0;
  wire [21:0] arbin21_req1;
  wire [21:0] arbin21_req2;
  wire [21:0] arbin21_gnt0;
  wire [21:0] arbin21_gnt1;
  wire [21:0] arbin21_gnt2;
  wire [15:0] arbin21_data;


  wire [21:0] arbout00_req0;
  wire [21:0] arbout00_req1;
  wire [21:0] arbout00_req2;
  wire [21:0] arbout00_gnt0;
  wire [21:0] arbout00_gnt1;
  wire [21:0] arbout00_gnt2;
  wire  [4:0] arbout00_mux_sel;
  wire [15:0] arbout00_data;

  wire [21:0] arbout01_req0;
  wire [21:0] arbout01_req1;
  wire [21:0] arbout01_req2;
  wire [21:0] arbout01_gnt0;
  wire [21:0] arbout01_gnt1;
  wire [21:0] arbout01_gnt2;
  wire  [4:0] arbout01_mux_sel;
  wire [15:0] arbout01_data;

  wire [21:0] arbout02_req0;
  wire [21:0] arbout02_req1;
  wire [21:0] arbout02_req2;
  wire [21:0] arbout02_gnt0;
  wire [21:0] arbout02_gnt1;
  wire [21:0] arbout02_gnt2;
  wire  [4:0] arbout02_mux_sel;
  wire [15:0] arbout02_data;

  wire [21:0] arbout03_req0;
  wire [21:0] arbout03_req1;
  wire [21:0] arbout03_req2;
  wire [21:0] arbout03_gnt0;
  wire [21:0] arbout03_gnt1;
  wire [21:0] arbout03_gnt2;
  wire  [4:0] arbout03_mux_sel;
  wire [15:0] arbout03_data;

  wire [21:0] arbout04_req0;
  wire [21:0] arbout04_req1;
  wire [21:0] arbout04_req2;
  wire [21:0] arbout04_gnt0;
  wire [21:0] arbout04_gnt1;
  wire [21:0] arbout04_gnt2;
  wire  [4:0] arbout04_mux_sel;
  wire [15:0] arbout04_data;

  wire [21:0] arbout05_req0;
  wire [21:0] arbout05_req1;
  wire [21:0] arbout05_req2;
  wire [21:0] arbout05_gnt0;
  wire [21:0] arbout05_gnt1;
  wire [21:0] arbout05_gnt2;
  wire  [4:0] arbout05_mux_sel;
  wire [15:0] arbout05_data;

  wire [21:0] arbout06_req0;
  wire [21:0] arbout06_req1;
  wire [21:0] arbout06_req2;
  wire [21:0] arbout06_gnt0;
  wire [21:0] arbout06_gnt1;
  wire [21:0] arbout06_gnt2;
  wire  [4:0] arbout06_mux_sel;
  wire [15:0] arbout06_data;

  wire [21:0] arbout07_req0;
  wire [21:0] arbout07_req1;
  wire [21:0] arbout07_req2;
  wire [21:0] arbout07_gnt0;
  wire [21:0] arbout07_gnt1;
  wire [21:0] arbout07_gnt2;
  wire  [4:0] arbout07_mux_sel;
  wire [15:0] arbout07_data;

  wire [21:0] arbout16_req0;
  wire [21:0] arbout16_req1;
  wire [21:0] arbout16_req2;
  wire [21:0] arbout16_gnt0;
  wire [21:0] arbout16_gnt1;
  wire [21:0] arbout16_gnt2;
  wire  [4:0] arbout16_mux_sel;
  wire [15:0] arbout16_data;

  wire [21:0] arbout17_req0;
  wire [21:0] arbout17_req1;
  wire [21:0] arbout17_req2;
  wire [21:0] arbout17_gnt0;
  wire [21:0] arbout17_gnt1;
  wire [21:0] arbout17_gnt2;
  wire  [4:0] arbout17_mux_sel;
  wire [15:0] arbout17_data;

  wire [21:0] arbout18_req0;
  wire [21:0] arbout18_req1;
  wire [21:0] arbout18_req2;
  wire [21:0] arbout18_gnt0;
  wire [21:0] arbout18_gnt1;
  wire [21:0] arbout18_gnt2;
  wire  [4:0] arbout18_mux_sel;
  wire [15:0] arbout18_data;

  wire [21:0] arbout19_req0;
  wire [21:0] arbout19_req1;
  wire [21:0] arbout19_req2;
  wire [21:0] arbout19_gnt0;
  wire [21:0] arbout19_gnt1;
  wire [21:0] arbout19_gnt2;
  wire  [4:0] arbout19_mux_sel;
  wire [15:0] arbout19_data;

  wire [21:0] arbout20_req0;
  wire [21:0] arbout20_req1;
  wire [21:0] arbout20_req2;
  wire [21:0] arbout20_gnt0;
  wire [21:0] arbout20_gnt1;
  wire [21:0] arbout20_gnt2;
  wire  [4:0] arbout20_mux_sel;
  wire [15:0] arbout20_data;

  wire [21:0] arbout21_req0;
  wire [21:0] arbout21_req1;
  wire [21:0] arbout21_req2;
  wire [21:0] arbout21_gnt0;
  wire [21:0] arbout21_gnt1;
  wire [21:0] arbout21_gnt2;
  wire  [4:0] arbout21_mux_sel;
  wire [15:0] arbout21_data;


  // ==========================================================================
  // Input Arbiters
  // ==========================================================================
  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i00_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port00_in_deq ), 
    .o_fifo_offset          ( o_port00_in_offset ),
    .o_fifo_eop             ( o_port00_in_eop ), 
    .i_fifo_data            ( i_port00_in_data ),
    .i_fifo_empty           ( i_port00_in_empty ),
    .o_req0                 ( arbin00_req0 ),
    .o_req1                 ( arbin00_req1 ),
    .o_req2                 ( arbin00_req2 ),
    .i_gnt0                 ( arbin00_gnt0 ),
    .i_gnt1                 ( arbin00_gnt1 ),
    .i_gnt2                 ( arbin00_gnt2 ),
    .o_data                 ( arbin00_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i01_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port01_in_deq ), 
    .o_fifo_offset          ( o_port01_in_offset ),
    .o_fifo_eop             ( o_port01_in_eop ), 
    .i_fifo_data            ( i_port01_in_data ),
    .i_fifo_empty           ( i_port01_in_empty ),
    .o_req0                 ( arbin01_req0 ),
    .o_req1                 ( arbin01_req1 ),
    .o_req2                 ( arbin01_req2 ),
    .i_gnt0                 ( arbin01_gnt0 ),
    .i_gnt1                 ( arbin01_gnt1 ),
    .i_gnt2                 ( arbin01_gnt2 ),
    .o_data                 ( arbin01_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i02_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port02_in_deq ), 
    .o_fifo_offset          ( o_port02_in_offset ),
    .o_fifo_eop             ( o_port02_in_eop ), 
    .i_fifo_data            ( i_port02_in_data ),
    .i_fifo_empty           ( i_port02_in_empty ),
    .o_req0                 ( arbin02_req0 ),
    .o_req1                 ( arbin02_req1 ),
    .o_req2                 ( arbin02_req2 ),
    .i_gnt0                 ( arbin02_gnt0 ),
    .i_gnt1                 ( arbin02_gnt1 ),
    .i_gnt2                 ( arbin02_gnt2 ),
    .o_data                 ( arbin02_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i03_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port03_in_deq ), 
    .o_fifo_offset          ( o_port03_in_offset ),
    .o_fifo_eop             ( o_port03_in_eop ), 
    .i_fifo_data            ( i_port03_in_data ),
    .i_fifo_empty           ( i_port03_in_empty ),
    .o_req0                 ( arbin03_req0 ),
    .o_req1                 ( arbin03_req1 ),
    .o_req2                 ( arbin03_req2 ),
    .i_gnt0                 ( arbin03_gnt0 ),
    .i_gnt1                 ( arbin03_gnt1 ),
    .i_gnt2                 ( arbin03_gnt2 ),
    .o_data                 ( arbin03_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i04_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port04_in_deq ), 
    .o_fifo_offset          ( o_port04_in_offset ),
    .o_fifo_eop             ( o_port04_in_eop ), 
    .i_fifo_data            ( i_port04_in_data ),
    .i_fifo_empty           ( i_port04_in_empty ),
    .o_req0                 ( arbin04_req0 ),
    .o_req1                 ( arbin04_req1 ),
    .o_req2                 ( arbin04_req2 ),
    .i_gnt0                 ( arbin04_gnt0 ),
    .i_gnt1                 ( arbin04_gnt1 ),
    .i_gnt2                 ( arbin04_gnt2 ),
    .o_data                 ( arbin04_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i05_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port05_in_deq ), 
    .o_fifo_offset          ( o_port05_in_offset ),
    .o_fifo_eop             ( o_port05_in_eop ), 
    .i_fifo_data            ( i_port05_in_data ),
    .i_fifo_empty           ( i_port05_in_empty ),
    .o_req0                 ( arbin05_req0 ),
    .o_req1                 ( arbin05_req1 ),
    .o_req2                 ( arbin05_req2 ),
    .i_gnt0                 ( arbin05_gnt0 ),
    .i_gnt1                 ( arbin05_gnt1 ),
    .i_gnt2                 ( arbin05_gnt2 ),
    .o_data                 ( arbin05_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i06_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port06_in_deq ), 
    .o_fifo_offset          ( o_port06_in_offset ),
    .o_fifo_eop             ( o_port06_in_eop ), 
    .i_fifo_data            ( i_port06_in_data ),
    .i_fifo_empty           ( i_port06_in_empty ),
    .o_req0                 ( arbin06_req0 ),
    .o_req1                 ( arbin06_req1 ),
    .o_req2                 ( arbin06_req2 ),
    .i_gnt0                 ( arbin06_gnt0 ),
    .i_gnt1                 ( arbin06_gnt1 ),
    .i_gnt2                 ( arbin06_gnt2 ),
    .o_data                 ( arbin06_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i07_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port07_in_deq ), 
    .o_fifo_offset          ( o_port07_in_offset ),
    .o_fifo_eop             ( o_port07_in_eop ), 
    .i_fifo_data            ( i_port07_in_data ),
    .i_fifo_empty           ( i_port07_in_empty ),
    .o_req0                 ( arbin07_req0 ),
    .o_req1                 ( arbin07_req1 ),
    .o_req2                 ( arbin07_req2 ),
    .i_gnt0                 ( arbin07_gnt0 ),
    .i_gnt1                 ( arbin07_gnt1 ),
    .i_gnt2                 ( arbin07_gnt2 ),
    .o_data                 ( arbin07_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i16_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port16_in_deq ), 
    .o_fifo_offset          ( o_port16_in_offset ),
    .o_fifo_eop             ( o_port16_in_eop ), 
    .i_fifo_data            ( i_port16_in_data ),
    .i_fifo_empty           ( i_port16_in_empty ),
    .o_req0                 ( arbin16_req0 ),
    .o_req1                 ( arbin16_req1 ),
    .o_req2                 ( arbin16_req2 ),
    .i_gnt0                 ( arbin16_gnt0 ),
    .i_gnt1                 ( arbin16_gnt1 ),
    .i_gnt2                 ( arbin16_gnt2 ),
    .o_data                 ( arbin16_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i17_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port17_in_deq ), 
    .o_fifo_offset          ( o_port17_in_offset ),
    .o_fifo_eop             ( o_port17_in_eop ), 
    .i_fifo_data            ( i_port17_in_data ),
    .i_fifo_empty           ( i_port17_in_empty ),
    .o_req0                 ( arbin17_req0 ),
    .o_req1                 ( arbin17_req1 ),
    .o_req2                 ( arbin17_req2 ),
    .i_gnt0                 ( arbin17_gnt0 ),
    .i_gnt1                 ( arbin17_gnt1 ),
    .i_gnt2                 ( arbin17_gnt2 ),
    .o_data                 ( arbin17_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i18_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port18_in_deq ), 
    .o_fifo_offset          ( o_port18_in_offset ),
    .o_fifo_eop             ( o_port18_in_eop ), 
    .i_fifo_data            ( i_port18_in_data ),
    .i_fifo_empty           ( i_port18_in_empty ),
    .o_req0                 ( arbin18_req0 ),
    .o_req1                 ( arbin18_req1 ),
    .o_req2                 ( arbin18_req2 ),
    .i_gnt0                 ( arbin18_gnt0 ),
    .i_gnt1                 ( arbin18_gnt1 ),
    .i_gnt2                 ( arbin18_gnt2 ),
    .o_data                 ( arbin18_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i19_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port19_in_deq ), 
    .o_fifo_offset          ( o_port19_in_offset ),
    .o_fifo_eop             ( o_port19_in_eop ), 
    .i_fifo_data            ( i_port19_in_data ),
    .i_fifo_empty           ( i_port19_in_empty ),
    .o_req0                 ( arbin19_req0 ),
    .o_req1                 ( arbin19_req1 ),
    .o_req2                 ( arbin19_req2 ),
    .i_gnt0                 ( arbin19_gnt0 ),
    .i_gnt1                 ( arbin19_gnt1 ),
    .i_gnt2                 ( arbin19_gnt2 ),
    .o_data                 ( arbin19_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i20_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port20_in_deq ), 
    .o_fifo_offset          ( o_port20_in_offset ),
    .o_fifo_eop             ( o_port20_in_eop ), 
    .i_fifo_data            ( i_port20_in_data ),
    .i_fifo_empty           ( i_port20_in_empty ),
    .o_req0                 ( arbin20_req0 ),
    .o_req1                 ( arbin20_req1 ),
    .o_req2                 ( arbin20_req2 ),
    .i_gnt0                 ( arbin20_gnt0 ),
    .i_gnt1                 ( arbin20_gnt1 ),
    .i_gnt2                 ( arbin20_gnt2 ),
    .o_data                 ( arbin20_data )
  );

  xbar_arb_in # (
    .ARM_MODE               ( 0 )
  ) i21_xbar_arb_in (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .i_board_id             ( i_board_id ),
    .o_fifo_deq             ( o_port21_in_deq ), 
    .o_fifo_offset          ( o_port21_in_offset ),
    .o_fifo_eop             ( o_port21_in_eop ), 
    .i_fifo_data            ( i_port21_in_data ),
    .i_fifo_empty           ( i_port21_in_empty ),
    .o_req0                 ( arbin21_req0 ),
    .o_req1                 ( arbin21_req1 ),
    .o_req2                 ( arbin21_req2 ),
    .i_gnt0                 ( arbin21_gnt0 ),
    .i_gnt1                 ( arbin21_gnt1 ),
    .i_gnt2                 ( arbin21_gnt2 ),
    .o_data                 ( arbin21_data )
  );

  
  // ==========================================================================
  // Output Arbiters
  // ==========================================================================
  xbar_arb_out i00_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port00_out_enq ),
    .o_fifo_offset          ( o_port00_out_offset ),
    .o_fifo_eop             ( o_port00_out_eop ),
    .o_fifo_data            ( o_port00_out_data ),
    .i_fifo_full            ( i_port00_out_full ),
    .i_fifo_packets_vc0     ( i_port00_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port00_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port00_out_packets_vc2 ),
    .i_req0                 ( arbout00_req0 ),
    .i_req1                 ( arbout00_req1 ),
    .i_req2                 ( arbout00_req2 ),
    .o_gnt0                 ( arbout00_gnt0 ),
    .o_gnt1                 ( arbout00_gnt1 ),
    .o_gnt2                 ( arbout00_gnt2 ),
    .o_mux_sel              ( arbout00_mux_sel ),
    .i_data                 ( arbout00_data )
  );

  xbar_arb_out i01_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port01_out_enq ),
    .o_fifo_offset          ( o_port01_out_offset ),
    .o_fifo_eop             ( o_port01_out_eop ),
    .o_fifo_data            ( o_port01_out_data ),
    .i_fifo_full            ( i_port01_out_full ),
    .i_fifo_packets_vc0     ( i_port01_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port01_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port01_out_packets_vc2 ),
    .i_req0                 ( arbout01_req0 ),
    .i_req1                 ( arbout01_req1 ),
    .i_req2                 ( arbout01_req2 ),
    .o_gnt0                 ( arbout01_gnt0 ),
    .o_gnt1                 ( arbout01_gnt1 ),
    .o_gnt2                 ( arbout01_gnt2 ),
    .o_mux_sel              ( arbout01_mux_sel ),
    .i_data                 ( arbout01_data )
  );

  xbar_arb_out i02_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port02_out_enq ),
    .o_fifo_offset          ( o_port02_out_offset ),
    .o_fifo_eop             ( o_port02_out_eop ),
    .o_fifo_data            ( o_port02_out_data ),
    .i_fifo_full            ( i_port02_out_full ),
    .i_fifo_packets_vc0     ( i_port02_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port02_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port02_out_packets_vc2 ),
    .i_req0                 ( arbout02_req0 ),
    .i_req1                 ( arbout02_req1 ),
    .i_req2                 ( arbout02_req2 ),
    .o_gnt0                 ( arbout02_gnt0 ),
    .o_gnt1                 ( arbout02_gnt1 ),
    .o_gnt2                 ( arbout02_gnt2 ),
    .o_mux_sel              ( arbout02_mux_sel ),
    .i_data                 ( arbout02_data )
  );

  xbar_arb_out i03_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port03_out_enq ),
    .o_fifo_offset          ( o_port03_out_offset ),
    .o_fifo_eop             ( o_port03_out_eop ),
    .o_fifo_data            ( o_port03_out_data ),
    .i_fifo_full            ( i_port03_out_full ),
    .i_fifo_packets_vc0     ( i_port03_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port03_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port03_out_packets_vc2 ),
    .i_req0                 ( arbout03_req0 ),
    .i_req1                 ( arbout03_req1 ),
    .i_req2                 ( arbout03_req2 ),
    .o_gnt0                 ( arbout03_gnt0 ),
    .o_gnt1                 ( arbout03_gnt1 ),
    .o_gnt2                 ( arbout03_gnt2 ),
    .o_mux_sel              ( arbout03_mux_sel ),
    .i_data                 ( arbout03_data )
  );

  xbar_arb_out i04_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port04_out_enq ),
    .o_fifo_offset          ( o_port04_out_offset ),
    .o_fifo_eop             ( o_port04_out_eop ),
    .o_fifo_data            ( o_port04_out_data ),
    .i_fifo_full            ( i_port04_out_full ),
    .i_fifo_packets_vc0     ( i_port04_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port04_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port04_out_packets_vc2 ),
    .i_req0                 ( arbout04_req0 ),
    .i_req1                 ( arbout04_req1 ),
    .i_req2                 ( arbout04_req2 ),
    .o_gnt0                 ( arbout04_gnt0 ),
    .o_gnt1                 ( arbout04_gnt1 ),
    .o_gnt2                 ( arbout04_gnt2 ),
    .o_mux_sel              ( arbout04_mux_sel ),
    .i_data                 ( arbout04_data )
  );

  xbar_arb_out i05_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port05_out_enq ),
    .o_fifo_offset          ( o_port05_out_offset ),
    .o_fifo_eop             ( o_port05_out_eop ),
    .o_fifo_data            ( o_port05_out_data ),
    .i_fifo_full            ( i_port05_out_full ),
    .i_fifo_packets_vc0     ( i_port05_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port05_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port05_out_packets_vc2 ),
    .i_req0                 ( arbout05_req0 ),
    .i_req1                 ( arbout05_req1 ),
    .i_req2                 ( arbout05_req2 ),
    .o_gnt0                 ( arbout05_gnt0 ),
    .o_gnt1                 ( arbout05_gnt1 ),
    .o_gnt2                 ( arbout05_gnt2 ),
    .o_mux_sel              ( arbout05_mux_sel ),
    .i_data                 ( arbout05_data )
  );

  xbar_arb_out i06_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port06_out_enq ),
    .o_fifo_offset          ( o_port06_out_offset ),
    .o_fifo_eop             ( o_port06_out_eop ),
    .o_fifo_data            ( o_port06_out_data ),
    .i_fifo_full            ( i_port06_out_full ),
    .i_fifo_packets_vc0     ( i_port06_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port06_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port06_out_packets_vc2 ),
    .i_req0                 ( arbout06_req0 ),
    .i_req1                 ( arbout06_req1 ),
    .i_req2                 ( arbout06_req2 ),
    .o_gnt0                 ( arbout06_gnt0 ),
    .o_gnt1                 ( arbout06_gnt1 ),
    .o_gnt2                 ( arbout06_gnt2 ),
    .o_mux_sel              ( arbout06_mux_sel ),
    .i_data                 ( arbout06_data )
  );

  xbar_arb_out i07_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port07_out_enq ),
    .o_fifo_offset          ( o_port07_out_offset ),
    .o_fifo_eop             ( o_port07_out_eop ),
    .o_fifo_data            ( o_port07_out_data ),
    .i_fifo_full            ( i_port07_out_full ),
    .i_fifo_packets_vc0     ( i_port07_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port07_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port07_out_packets_vc2 ),
    .i_req0                 ( arbout07_req0 ),
    .i_req1                 ( arbout07_req1 ),
    .i_req2                 ( arbout07_req2 ),
    .o_gnt0                 ( arbout07_gnt0 ),
    .o_gnt1                 ( arbout07_gnt1 ),
    .o_gnt2                 ( arbout07_gnt2 ),
    .o_mux_sel              ( arbout07_mux_sel ),
    .i_data                 ( arbout07_data )
  );

  xbar_arb_out i16_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port16_out_enq ),
    .o_fifo_offset          ( o_port16_out_offset ),
    .o_fifo_eop             ( o_port16_out_eop ),
    .o_fifo_data            ( o_port16_out_data ),
    .i_fifo_full            ( i_port16_out_full ),
    .i_fifo_packets_vc0     ( i_port16_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port16_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port16_out_packets_vc2 ),
    .i_req0                 ( arbout16_req0 ),
    .i_req1                 ( arbout16_req1 ),
    .i_req2                 ( arbout16_req2 ),
    .o_gnt0                 ( arbout16_gnt0 ),
    .o_gnt1                 ( arbout16_gnt1 ),
    .o_gnt2                 ( arbout16_gnt2 ),
    .o_mux_sel              ( arbout16_mux_sel ),
    .i_data                 ( arbout16_data )
  );

  xbar_arb_out i17_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port17_out_enq ),
    .o_fifo_offset          ( o_port17_out_offset ),
    .o_fifo_eop             ( o_port17_out_eop ),
    .o_fifo_data            ( o_port17_out_data ),
    .i_fifo_full            ( i_port17_out_full ),
    .i_fifo_packets_vc0     ( i_port17_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port17_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port17_out_packets_vc2 ),
    .i_req0                 ( arbout17_req0 ),
    .i_req1                 ( arbout17_req1 ),
    .i_req2                 ( arbout17_req2 ),
    .o_gnt0                 ( arbout17_gnt0 ),
    .o_gnt1                 ( arbout17_gnt1 ),
    .o_gnt2                 ( arbout17_gnt2 ),
    .o_mux_sel              ( arbout17_mux_sel ),
    .i_data                 ( arbout17_data )
  );

  xbar_arb_out i18_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port18_out_enq ),
    .o_fifo_offset          ( o_port18_out_offset ),
    .o_fifo_eop             ( o_port18_out_eop ),
    .o_fifo_data            ( o_port18_out_data ),
    .i_fifo_full            ( i_port18_out_full ),
    .i_fifo_packets_vc0     ( i_port18_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port18_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port18_out_packets_vc2 ),
    .i_req0                 ( arbout18_req0 ),
    .i_req1                 ( arbout18_req1 ),
    .i_req2                 ( arbout18_req2 ),
    .o_gnt0                 ( arbout18_gnt0 ),
    .o_gnt1                 ( arbout18_gnt1 ),
    .o_gnt2                 ( arbout18_gnt2 ),
    .o_mux_sel              ( arbout18_mux_sel ),
    .i_data                 ( arbout18_data )
  );

  xbar_arb_out i19_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port19_out_enq ),
    .o_fifo_offset          ( o_port19_out_offset ),
    .o_fifo_eop             ( o_port19_out_eop ),
    .o_fifo_data            ( o_port19_out_data ),
    .i_fifo_full            ( i_port19_out_full ),
    .i_fifo_packets_vc0     ( i_port19_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port19_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port19_out_packets_vc2 ),
    .i_req0                 ( arbout19_req0 ),
    .i_req1                 ( arbout19_req1 ),
    .i_req2                 ( arbout19_req2 ),
    .o_gnt0                 ( arbout19_gnt0 ),
    .o_gnt1                 ( arbout19_gnt1 ),
    .o_gnt2                 ( arbout19_gnt2 ),
    .o_mux_sel              ( arbout19_mux_sel ),
    .i_data                 ( arbout19_data )
  );

  xbar_arb_out i20_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port20_out_enq ),
    .o_fifo_offset          ( o_port20_out_offset ),
    .o_fifo_eop             ( o_port20_out_eop ),
    .o_fifo_data            ( o_port20_out_data ),
    .i_fifo_full            ( i_port20_out_full ),
    .i_fifo_packets_vc0     ( i_port20_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port20_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port20_out_packets_vc2 ),
    .i_req0                 ( arbout20_req0 ),
    .i_req1                 ( arbout20_req1 ),
    .i_req2                 ( arbout20_req2 ),
    .o_gnt0                 ( arbout20_gnt0 ),
    .o_gnt1                 ( arbout20_gnt1 ),
    .o_gnt2                 ( arbout20_gnt2 ),
    .o_mux_sel              ( arbout20_mux_sel ),
    .i_data                 ( arbout20_data )
  );

  xbar_arb_out i21_xbar_arb_out (
    .clk                    ( clk_xbar ),
    .rst                    ( rst_xbar ),
    .o_fifo_enq             ( o_port21_out_enq ),
    .o_fifo_offset          ( o_port21_out_offset ),
    .o_fifo_eop             ( o_port21_out_eop ),
    .o_fifo_data            ( o_port21_out_data ),
    .i_fifo_full            ( i_port21_out_full ),
    .i_fifo_packets_vc0     ( i_port21_out_packets_vc0 ),
    .i_fifo_packets_vc1     ( i_port21_out_packets_vc1 ),
    .i_fifo_packets_vc2     ( i_port21_out_packets_vc2 ),
    .i_req0                 ( arbout21_req0 ),
    .i_req1                 ( arbout21_req1 ),
    .i_req2                 ( arbout21_req2 ),
    .o_gnt0                 ( arbout21_gnt0 ),
    .o_gnt1                 ( arbout21_gnt1 ),
    .o_gnt2                 ( arbout21_gnt2 ),
    .o_mux_sel              ( arbout21_mux_sel ),
    .i_data                 ( arbout21_data )
  );



  // ==========================================================================
  // Switching fabric: Data muxes
  // ==========================================================================
  xbar_mux i00_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout00_mux_sel ),
    .o_data                 ( arbout00_data )
  );

  xbar_mux i01_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout01_mux_sel ),
    .o_data                 ( arbout01_data )
  );

  xbar_mux i02_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout02_mux_sel ),
    .o_data                 ( arbout02_data )
  );

  xbar_mux i03_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout03_mux_sel ),
    .o_data                 ( arbout03_data )
  );

  xbar_mux i04_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout04_mux_sel ),
    .o_data                 ( arbout04_data )
  );

  xbar_mux i05_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout05_mux_sel ),
    .o_data                 ( arbout05_data )
  );

  xbar_mux i06_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout06_mux_sel ),
    .o_data                 ( arbout06_data )
  );

  xbar_mux i07_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout07_mux_sel ),
    .o_data                 ( arbout07_data )
  );

  xbar_mux i16_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout16_mux_sel ),
    .o_data                 ( arbout16_data )
  );

  xbar_mux i17_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout17_mux_sel ),
    .o_data                 ( arbout17_data )
  );

  xbar_mux i18_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout18_mux_sel ),
    .o_data                 ( arbout18_data )
  );

  xbar_mux i19_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout19_mux_sel ),
    .o_data                 ( arbout19_data )
  );

  xbar_mux i20_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout20_mux_sel ),
    .o_data                 ( arbout20_data )
  );

  xbar_mux i21_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( arbin01_data ),
    .i_data02               ( arbin02_data ),
    .i_data03               ( arbin03_data ),
    .i_data04               ( arbin04_data ),
    .i_data05               ( arbin05_data ),
    .i_data06               ( arbin06_data ),
    .i_data07               ( arbin07_data ),
    .i_data08               ( 16'b0 ),
    .i_data09               ( 16'b0 ),
    .i_data10               ( 16'b0 ),
    .i_data11               ( 16'b0 ),
    .i_data12               ( 16'b0 ),
    .i_data13               ( 16'b0 ),
    .i_data14               ( 16'b0 ),
    .i_data15               ( 16'b0 ),
    .i_data16               ( arbin16_data ),
    .i_data17               ( arbin17_data ),
    .i_data18               ( arbin18_data ),
    .i_data19               ( arbin19_data ),
    .i_data20               ( arbin20_data ),
    .i_data21               ( arbin21_data ),
    .i_sel                  ( arbout21_mux_sel ),
    .o_data                 ( arbout21_data )
  );

  
  // ==========================================================================
  // Request stiching
  // ==========================================================================
  assign arbout00_req0 = {
    arbin21_req0[0], arbin20_req0[0], arbin19_req0[0], arbin18_req0[0],
    arbin17_req0[0], arbin16_req0[0], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req0[0], arbin06_req0[0],
    arbin05_req0[0], arbin04_req0[0], arbin03_req0[0], arbin02_req0[0],
    arbin01_req0[0], arbin00_req0[0]};

  assign arbout01_req0 = {
    arbin21_req0[1], arbin20_req0[1], arbin19_req0[1], arbin18_req0[1],
    arbin17_req0[1], arbin16_req0[1], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req0[1], arbin06_req0[1],
    arbin05_req0[1], arbin04_req0[1], arbin03_req0[1], arbin02_req0[1],
    arbin01_req0[1], arbin00_req0[1]};

  assign arbout02_req0 = {
    arbin21_req0[2], arbin20_req0[2], arbin19_req0[2], arbin18_req0[2],
    arbin17_req0[2], arbin16_req0[2], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req0[2], arbin06_req0[2],
    arbin05_req0[2], arbin04_req0[2], arbin03_req0[2], arbin02_req0[2],
    arbin01_req0[2], arbin00_req0[2]};

  assign arbout03_req0 = {
    arbin21_req0[3], arbin20_req0[3], arbin19_req0[3], arbin18_req0[3],
    arbin17_req0[3], arbin16_req0[3], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req0[3], arbin06_req0[3],
    arbin05_req0[3], arbin04_req0[3], arbin03_req0[3], arbin02_req0[3],
    arbin01_req0[3], arbin00_req0[3]};

  assign arbout04_req0 = {
    arbin21_req0[4], arbin20_req0[4], arbin19_req0[4], arbin18_req0[4],
    arbin17_req0[4], arbin16_req0[4], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req0[4], arbin06_req0[4],
    arbin05_req0[4], arbin04_req0[4], arbin03_req0[4], arbin02_req0[4],
    arbin01_req0[4], arbin00_req0[4]};

  assign arbout05_req0 = {
    arbin21_req0[5], arbin20_req0[5], arbin19_req0[5], arbin18_req0[5],
    arbin17_req0[5], arbin16_req0[5], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req0[5], arbin06_req0[5],
    arbin05_req0[5], arbin04_req0[5], arbin03_req0[5], arbin02_req0[5],
    arbin01_req0[5], arbin00_req0[5]};

  assign arbout06_req0 = {
    arbin21_req0[6], arbin20_req0[6], arbin19_req0[6], arbin18_req0[6],
    arbin17_req0[6], arbin16_req0[6], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req0[6], arbin06_req0[6],
    arbin05_req0[6], arbin04_req0[6], arbin03_req0[6], arbin02_req0[6],
    arbin01_req0[6], arbin00_req0[6]};

  assign arbout07_req0 = {
    arbin21_req0[7], arbin20_req0[7], arbin19_req0[7], arbin18_req0[7],
    arbin17_req0[7], arbin16_req0[7], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req0[7], arbin06_req0[7],
    arbin05_req0[7], arbin04_req0[7], arbin03_req0[7], arbin02_req0[7],
    arbin01_req0[7], arbin00_req0[7]};

  assign arbout16_req0 = {
    arbin21_req0[16], arbin20_req0[16], arbin19_req0[16], arbin18_req0[16],
    arbin17_req0[16], arbin16_req0[16], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req0[16], arbin06_req0[16],
    arbin05_req0[16], arbin04_req0[16], arbin03_req0[16], arbin02_req0[16],
    arbin01_req0[16], arbin00_req0[16]};

  assign arbout17_req0 = {
    arbin21_req0[17], arbin20_req0[17], arbin19_req0[17], arbin18_req0[17],
    arbin17_req0[17], arbin16_req0[17], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req0[17], arbin06_req0[17],
    arbin05_req0[17], arbin04_req0[17], arbin03_req0[17], arbin02_req0[17],
    arbin01_req0[17], arbin00_req0[17]};

  assign arbout18_req0 = {
    arbin21_req0[18], arbin20_req0[18], arbin19_req0[18], arbin18_req0[18],
    arbin17_req0[18], arbin16_req0[18], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req0[18], arbin06_req0[18],
    arbin05_req0[18], arbin04_req0[18], arbin03_req0[18], arbin02_req0[18],
    arbin01_req0[18], arbin00_req0[18]};

  assign arbout19_req0 = {
    arbin21_req0[19], arbin20_req0[19], arbin19_req0[19], arbin18_req0[19],
    arbin17_req0[19], arbin16_req0[19], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req0[19], arbin06_req0[19],
    arbin05_req0[19], arbin04_req0[19], arbin03_req0[19], arbin02_req0[19],
    arbin01_req0[19], arbin00_req0[19]};

  assign arbout20_req0 = {
    arbin21_req0[20], arbin20_req0[20], arbin19_req0[20], arbin18_req0[20],
    arbin17_req0[20], arbin16_req0[20], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req0[20], arbin06_req0[20],
    arbin05_req0[20], arbin04_req0[20], arbin03_req0[20], arbin02_req0[20],
    arbin01_req0[20], arbin00_req0[20]};

  assign arbout21_req0 = {
    arbin21_req0[21], arbin20_req0[21], arbin19_req0[21], arbin18_req0[21],
    arbin17_req0[21], arbin16_req0[21], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req0[21], arbin06_req0[21],
    arbin05_req0[21], arbin04_req0[21], arbin03_req0[21], arbin02_req0[21],
    arbin01_req0[21], arbin00_req0[21]};

  assign arbout00_req1 = {
    arbin21_req1[0], arbin20_req1[0], arbin19_req1[0], arbin18_req1[0],
    arbin17_req1[0], arbin16_req1[0], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req1[0], arbin06_req1[0],
    arbin05_req1[0], arbin04_req1[0], arbin03_req1[0], arbin02_req1[0],
    arbin01_req1[0], arbin00_req1[0]};

  assign arbout01_req1 = {
    arbin21_req1[1], arbin20_req1[1], arbin19_req1[1], arbin18_req1[1],
    arbin17_req1[1], arbin16_req1[1], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req1[1], arbin06_req1[1],
    arbin05_req1[1], arbin04_req1[1], arbin03_req1[1], arbin02_req1[1],
    arbin01_req1[1], arbin00_req1[1]};

  assign arbout02_req1 = {
    arbin21_req1[2], arbin20_req1[2], arbin19_req1[2], arbin18_req1[2],
    arbin17_req1[2], arbin16_req1[2], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req1[2], arbin06_req1[2],
    arbin05_req1[2], arbin04_req1[2], arbin03_req1[2], arbin02_req1[2],
    arbin01_req1[2], arbin00_req1[2]};

  assign arbout03_req1 = {
    arbin21_req1[3], arbin20_req1[3], arbin19_req1[3], arbin18_req1[3],
    arbin17_req1[3], arbin16_req1[3], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req1[3], arbin06_req1[3],
    arbin05_req1[3], arbin04_req1[3], arbin03_req1[3], arbin02_req1[3],
    arbin01_req1[3], arbin00_req1[3]};

  assign arbout04_req1 = {
    arbin21_req1[4], arbin20_req1[4], arbin19_req1[4], arbin18_req1[4],
    arbin17_req1[4], arbin16_req1[4], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req1[4], arbin06_req1[4],
    arbin05_req1[4], arbin04_req1[4], arbin03_req1[4], arbin02_req1[4],
    arbin01_req1[4], arbin00_req1[4]};

  assign arbout05_req1 = {
    arbin21_req1[5], arbin20_req1[5], arbin19_req1[5], arbin18_req1[5],
    arbin17_req1[5], arbin16_req1[5], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req1[5], arbin06_req1[5],
    arbin05_req1[5], arbin04_req1[5], arbin03_req1[5], arbin02_req1[5],
    arbin01_req1[5], arbin00_req1[5]};

  assign arbout06_req1 = {
    arbin21_req1[6], arbin20_req1[6], arbin19_req1[6], arbin18_req1[6],
    arbin17_req1[6], arbin16_req1[6], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req1[6], arbin06_req1[6],
    arbin05_req1[6], arbin04_req1[6], arbin03_req1[6], arbin02_req1[6],
    arbin01_req1[6], arbin00_req1[6]};

  assign arbout07_req1 = {
    arbin21_req1[7], arbin20_req1[7], arbin19_req1[7], arbin18_req1[7],
    arbin17_req1[7], arbin16_req1[7], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req1[7], arbin06_req1[7],
    arbin05_req1[7], arbin04_req1[7], arbin03_req1[7], arbin02_req1[7],
    arbin01_req1[7], arbin00_req1[7]};

  assign arbout16_req1 = {
    arbin21_req1[16], arbin20_req1[16], arbin19_req1[16], arbin18_req1[16],
    arbin17_req1[16], arbin16_req1[16], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req1[16], arbin06_req1[16],
    arbin05_req1[16], arbin04_req1[16], arbin03_req1[16], arbin02_req1[16],
    arbin01_req1[16], arbin00_req1[16]};

  assign arbout17_req1 = {
    arbin21_req1[17], arbin20_req1[17], arbin19_req1[17], arbin18_req1[17],
    arbin17_req1[17], arbin16_req1[17], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req1[17], arbin06_req1[17],
    arbin05_req1[17], arbin04_req1[17], arbin03_req1[17], arbin02_req1[17],
    arbin01_req1[17], arbin00_req1[17]};

  assign arbout18_req1 = {
    arbin21_req1[18], arbin20_req1[18], arbin19_req1[18], arbin18_req1[18],
    arbin17_req1[18], arbin16_req1[18], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req1[18], arbin06_req1[18],
    arbin05_req1[18], arbin04_req1[18], arbin03_req1[18], arbin02_req1[18],
    arbin01_req1[18], arbin00_req1[18]};

  assign arbout19_req1 = {
    arbin21_req1[19], arbin20_req1[19], arbin19_req1[19], arbin18_req1[19],
    arbin17_req1[19], arbin16_req1[19], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req1[19], arbin06_req1[19],
    arbin05_req1[19], arbin04_req1[19], arbin03_req1[19], arbin02_req1[19],
    arbin01_req1[19], arbin00_req1[19]};

  assign arbout20_req1 = {
    arbin21_req1[20], arbin20_req1[20], arbin19_req1[20], arbin18_req1[20],
    arbin17_req1[20], arbin16_req1[20], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req1[20], arbin06_req1[20],
    arbin05_req1[20], arbin04_req1[20], arbin03_req1[20], arbin02_req1[20],
    arbin01_req1[20], arbin00_req1[20]};

  assign arbout21_req1 = {
    arbin21_req1[21], arbin20_req1[21], arbin19_req1[21], arbin18_req1[21],
    arbin17_req1[21], arbin16_req1[21], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req1[21], arbin06_req1[21],
    arbin05_req1[21], arbin04_req1[21], arbin03_req1[21], arbin02_req1[21],
    arbin01_req1[21], arbin00_req1[21]};

  assign arbout00_req2 = {
    arbin21_req2[0], arbin20_req2[0], arbin19_req2[0], arbin18_req2[0],
    arbin17_req2[0], arbin16_req2[0], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req2[0], arbin06_req2[0],
    arbin05_req2[0], arbin04_req2[0], arbin03_req2[0], arbin02_req2[0],
    arbin01_req2[0], arbin00_req2[0]};

  assign arbout01_req2 = {
    arbin21_req2[1], arbin20_req2[1], arbin19_req2[1], arbin18_req2[1],
    arbin17_req2[1], arbin16_req2[1], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req2[1], arbin06_req2[1],
    arbin05_req2[1], arbin04_req2[1], arbin03_req2[1], arbin02_req2[1],
    arbin01_req2[1], arbin00_req2[1]};

  assign arbout02_req2 = {
    arbin21_req2[2], arbin20_req2[2], arbin19_req2[2], arbin18_req2[2],
    arbin17_req2[2], arbin16_req2[2], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req2[2], arbin06_req2[2],
    arbin05_req2[2], arbin04_req2[2], arbin03_req2[2], arbin02_req2[2],
    arbin01_req2[2], arbin00_req2[2]};

  assign arbout03_req2 = {
    arbin21_req2[3], arbin20_req2[3], arbin19_req2[3], arbin18_req2[3],
    arbin17_req2[3], arbin16_req2[3], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req2[3], arbin06_req2[3],
    arbin05_req2[3], arbin04_req2[3], arbin03_req2[3], arbin02_req2[3],
    arbin01_req2[3], arbin00_req2[3]};

  assign arbout04_req2 = {
    arbin21_req2[4], arbin20_req2[4], arbin19_req2[4], arbin18_req2[4],
    arbin17_req2[4], arbin16_req2[4], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req2[4], arbin06_req2[4],
    arbin05_req2[4], arbin04_req2[4], arbin03_req2[4], arbin02_req2[4],
    arbin01_req2[4], arbin00_req2[4]};

  assign arbout05_req2 = {
    arbin21_req2[5], arbin20_req2[5], arbin19_req2[5], arbin18_req2[5],
    arbin17_req2[5], arbin16_req2[5], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req2[5], arbin06_req2[5],
    arbin05_req2[5], arbin04_req2[5], arbin03_req2[5], arbin02_req2[5],
    arbin01_req2[5], arbin00_req2[5]};

  assign arbout06_req2 = {
    arbin21_req2[6], arbin20_req2[6], arbin19_req2[6], arbin18_req2[6],
    arbin17_req2[6], arbin16_req2[6], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req2[6], arbin06_req2[6],
    arbin05_req2[6], arbin04_req2[6], arbin03_req2[6], arbin02_req2[6],
    arbin01_req2[6], arbin00_req2[6]};

  assign arbout07_req2 = {
    arbin21_req2[7], arbin20_req2[7], arbin19_req2[7], arbin18_req2[7],
    arbin17_req2[7], arbin16_req2[7], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , arbin07_req2[7], arbin06_req2[7],
    arbin05_req2[7], arbin04_req2[7], arbin03_req2[7], arbin02_req2[7],
    arbin01_req2[7], arbin00_req2[7]};

  assign arbout16_req2 = {
    arbin21_req2[16], arbin20_req2[16], arbin19_req2[16], arbin18_req2[16],
    arbin17_req2[16], arbin16_req2[16], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req2[16], arbin06_req2[16],
    arbin05_req2[16], arbin04_req2[16], arbin03_req2[16], arbin02_req2[16],
    arbin01_req2[16], arbin00_req2[16]};

  assign arbout17_req2 = {
    arbin21_req2[17], arbin20_req2[17], arbin19_req2[17], arbin18_req2[17],
    arbin17_req2[17], arbin16_req2[17], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req2[17], arbin06_req2[17],
    arbin05_req2[17], arbin04_req2[17], arbin03_req2[17], arbin02_req2[17],
    arbin01_req2[17], arbin00_req2[17]};

  assign arbout18_req2 = {
    arbin21_req2[18], arbin20_req2[18], arbin19_req2[18], arbin18_req2[18],
    arbin17_req2[18], arbin16_req2[18], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req2[18], arbin06_req2[18],
    arbin05_req2[18], arbin04_req2[18], arbin03_req2[18], arbin02_req2[18],
    arbin01_req2[18], arbin00_req2[18]};

  assign arbout19_req2 = {
    arbin21_req2[19], arbin20_req2[19], arbin19_req2[19], arbin18_req2[19],
    arbin17_req2[19], arbin16_req2[19], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req2[19], arbin06_req2[19],
    arbin05_req2[19], arbin04_req2[19], arbin03_req2[19], arbin02_req2[19],
    arbin01_req2[19], arbin00_req2[19]};

  assign arbout20_req2 = {
    arbin21_req2[20], arbin20_req2[20], arbin19_req2[20], arbin18_req2[20],
    arbin17_req2[20], arbin16_req2[20], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req2[20], arbin06_req2[20],
    arbin05_req2[20], arbin04_req2[20], arbin03_req2[20], arbin02_req2[20],
    arbin01_req2[20], arbin00_req2[20]};

  assign arbout21_req2 = {
    arbin21_req2[21], arbin20_req2[21], arbin19_req2[21], arbin18_req2[21],
    arbin17_req2[21], arbin16_req2[21], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbin07_req2[21], arbin06_req2[21],
    arbin05_req2[21], arbin04_req2[21], arbin03_req2[21], arbin02_req2[21],
    arbin01_req2[21], arbin00_req2[21]};

  
  // ==========================================================================
  // Grant stiching
  // ==========================================================================
  assign arbin00_gnt0 = {
    arbout21_gnt0[0], arbout20_gnt0[0], arbout19_gnt0[0], arbout18_gnt0[0],
    arbout17_gnt0[0], arbout16_gnt0[0], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt0[0], arbout06_gnt0[0],
    arbout05_gnt0[0], arbout04_gnt0[0], arbout03_gnt0[0], arbout02_gnt0[0],
    arbout01_gnt0[0], arbout00_gnt0[0]};

  assign arbin01_gnt0 = {
    arbout21_gnt0[1], arbout20_gnt0[1], arbout19_gnt0[1], arbout18_gnt0[1],
    arbout17_gnt0[1], arbout16_gnt0[1], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt0[1], arbout06_gnt0[1],
    arbout05_gnt0[1], arbout04_gnt0[1], arbout03_gnt0[1], arbout02_gnt0[1],
    arbout01_gnt0[1], arbout00_gnt0[1]};

  assign arbin02_gnt0 = {
    arbout21_gnt0[2], arbout20_gnt0[2], arbout19_gnt0[2], arbout18_gnt0[2],
    arbout17_gnt0[2], arbout16_gnt0[2], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt0[2], arbout06_gnt0[2],
    arbout05_gnt0[2], arbout04_gnt0[2], arbout03_gnt0[2], arbout02_gnt0[2],
    arbout01_gnt0[2], arbout00_gnt0[2]};

  assign arbin03_gnt0 = {
    arbout21_gnt0[3], arbout20_gnt0[3], arbout19_gnt0[3], arbout18_gnt0[3],
    arbout17_gnt0[3], arbout16_gnt0[3], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt0[3], arbout06_gnt0[3],
    arbout05_gnt0[3], arbout04_gnt0[3], arbout03_gnt0[3], arbout02_gnt0[3],
    arbout01_gnt0[3], arbout00_gnt0[3]};

  assign arbin04_gnt0 = {
    arbout21_gnt0[4], arbout20_gnt0[4], arbout19_gnt0[4], arbout18_gnt0[4],
    arbout17_gnt0[4], arbout16_gnt0[4], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt0[4], arbout06_gnt0[4],
    arbout05_gnt0[4], arbout04_gnt0[4], arbout03_gnt0[4], arbout02_gnt0[4],
    arbout01_gnt0[4], arbout00_gnt0[4]};

  assign arbin05_gnt0 = {
    arbout21_gnt0[5], arbout20_gnt0[5], arbout19_gnt0[5], arbout18_gnt0[5],
    arbout17_gnt0[5], arbout16_gnt0[5], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt0[5], arbout06_gnt0[5],
    arbout05_gnt0[5], arbout04_gnt0[5], arbout03_gnt0[5], arbout02_gnt0[5],
    arbout01_gnt0[5], arbout00_gnt0[5]};

  assign arbin06_gnt0 = {
    arbout21_gnt0[6], arbout20_gnt0[6], arbout19_gnt0[6], arbout18_gnt0[6],
    arbout17_gnt0[6], arbout16_gnt0[6], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt0[6], arbout06_gnt0[6],
    arbout05_gnt0[6], arbout04_gnt0[6], arbout03_gnt0[6], arbout02_gnt0[6],
    arbout01_gnt0[6], arbout00_gnt0[6]};

  assign arbin07_gnt0 = {
    arbout21_gnt0[7], arbout20_gnt0[7], arbout19_gnt0[7], arbout18_gnt0[7],
    arbout17_gnt0[7], arbout16_gnt0[7], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt0[7], arbout06_gnt0[7],
    arbout05_gnt0[7], arbout04_gnt0[7], arbout03_gnt0[7], arbout02_gnt0[7],
    arbout01_gnt0[7], arbout00_gnt0[7]};

  assign arbin16_gnt0 = {
    arbout21_gnt0[16], arbout20_gnt0[16], arbout19_gnt0[16], arbout18_gnt0[16],
    arbout17_gnt0[16], arbout16_gnt0[16], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt0[16], arbout06_gnt0[16],
    arbout05_gnt0[16], arbout04_gnt0[16], arbout03_gnt0[16], arbout02_gnt0[16],
    arbout01_gnt0[16], arbout00_gnt0[16]};

  assign arbin17_gnt0 = {
    arbout21_gnt0[17], arbout20_gnt0[17], arbout19_gnt0[17], arbout18_gnt0[17],
    arbout17_gnt0[17], arbout16_gnt0[17], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt0[17], arbout06_gnt0[17],
    arbout05_gnt0[17], arbout04_gnt0[17], arbout03_gnt0[17], arbout02_gnt0[17],
    arbout01_gnt0[17], arbout00_gnt0[17]};

  assign arbin18_gnt0 = {
    arbout21_gnt0[18], arbout20_gnt0[18], arbout19_gnt0[18], arbout18_gnt0[18],
    arbout17_gnt0[18], arbout16_gnt0[18], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt0[18], arbout06_gnt0[18],
    arbout05_gnt0[18], arbout04_gnt0[18], arbout03_gnt0[18], arbout02_gnt0[18],
    arbout01_gnt0[18], arbout00_gnt0[18]};

  assign arbin19_gnt0 = {
    arbout21_gnt0[19], arbout20_gnt0[19], arbout19_gnt0[19], arbout18_gnt0[19],
    arbout17_gnt0[19], arbout16_gnt0[19], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt0[19], arbout06_gnt0[19],
    arbout05_gnt0[19], arbout04_gnt0[19], arbout03_gnt0[19], arbout02_gnt0[19],
    arbout01_gnt0[19], arbout00_gnt0[19]};

  assign arbin20_gnt0 = {
    arbout21_gnt0[20], arbout20_gnt0[20], arbout19_gnt0[20], arbout18_gnt0[20],
    arbout17_gnt0[20], arbout16_gnt0[20], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt0[20], arbout06_gnt0[20],
    arbout05_gnt0[20], arbout04_gnt0[20], arbout03_gnt0[20], arbout02_gnt0[20],
    arbout01_gnt0[20], arbout00_gnt0[20]};

  assign arbin21_gnt0 = {
    arbout21_gnt0[21], arbout20_gnt0[21], arbout19_gnt0[21], arbout18_gnt0[21],
    arbout17_gnt0[21], arbout16_gnt0[21], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt0[21], arbout06_gnt0[21],
    arbout05_gnt0[21], arbout04_gnt0[21], arbout03_gnt0[21], arbout02_gnt0[21],
    arbout01_gnt0[21], arbout00_gnt0[21]};

  assign arbin00_gnt1 = {
    arbout21_gnt1[0], arbout20_gnt1[0], arbout19_gnt1[0], arbout18_gnt1[0],
    arbout17_gnt1[0], arbout16_gnt1[0], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt1[0], arbout06_gnt1[0],
    arbout05_gnt1[0], arbout04_gnt1[0], arbout03_gnt1[0], arbout02_gnt1[0],
    arbout01_gnt1[0], arbout00_gnt1[0]};

  assign arbin01_gnt1 = {
    arbout21_gnt1[1], arbout20_gnt1[1], arbout19_gnt1[1], arbout18_gnt1[1],
    arbout17_gnt1[1], arbout16_gnt1[1], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt1[1], arbout06_gnt1[1],
    arbout05_gnt1[1], arbout04_gnt1[1], arbout03_gnt1[1], arbout02_gnt1[1],
    arbout01_gnt1[1], arbout00_gnt1[1]};

  assign arbin02_gnt1 = {
    arbout21_gnt1[2], arbout20_gnt1[2], arbout19_gnt1[2], arbout18_gnt1[2],
    arbout17_gnt1[2], arbout16_gnt1[2], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt1[2], arbout06_gnt1[2],
    arbout05_gnt1[2], arbout04_gnt1[2], arbout03_gnt1[2], arbout02_gnt1[2],
    arbout01_gnt1[2], arbout00_gnt1[2]};

  assign arbin03_gnt1 = {
    arbout21_gnt1[3], arbout20_gnt1[3], arbout19_gnt1[3], arbout18_gnt1[3],
    arbout17_gnt1[3], arbout16_gnt1[3], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt1[3], arbout06_gnt1[3],
    arbout05_gnt1[3], arbout04_gnt1[3], arbout03_gnt1[3], arbout02_gnt1[3],
    arbout01_gnt1[3], arbout00_gnt1[3]};

  assign arbin04_gnt1 = {
    arbout21_gnt1[4], arbout20_gnt1[4], arbout19_gnt1[4], arbout18_gnt1[4],
    arbout17_gnt1[4], arbout16_gnt1[4], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt1[4], arbout06_gnt1[4],
    arbout05_gnt1[4], arbout04_gnt1[4], arbout03_gnt1[4], arbout02_gnt1[4],
    arbout01_gnt1[4], arbout00_gnt1[4]};

  assign arbin05_gnt1 = {
    arbout21_gnt1[5], arbout20_gnt1[5], arbout19_gnt1[5], arbout18_gnt1[5],
    arbout17_gnt1[5], arbout16_gnt1[5], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt1[5], arbout06_gnt1[5],
    arbout05_gnt1[5], arbout04_gnt1[5], arbout03_gnt1[5], arbout02_gnt1[5],
    arbout01_gnt1[5], arbout00_gnt1[5]};

  assign arbin06_gnt1 = {
    arbout21_gnt1[6], arbout20_gnt1[6], arbout19_gnt1[6], arbout18_gnt1[6],
    arbout17_gnt1[6], arbout16_gnt1[6], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt1[6], arbout06_gnt1[6],
    arbout05_gnt1[6], arbout04_gnt1[6], arbout03_gnt1[6], arbout02_gnt1[6],
    arbout01_gnt1[6], arbout00_gnt1[6]};

  assign arbin07_gnt1 = {
    arbout21_gnt1[7], arbout20_gnt1[7], arbout19_gnt1[7], arbout18_gnt1[7],
    arbout17_gnt1[7], arbout16_gnt1[7], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt1[7], arbout06_gnt1[7],
    arbout05_gnt1[7], arbout04_gnt1[7], arbout03_gnt1[7], arbout02_gnt1[7],
    arbout01_gnt1[7], arbout00_gnt1[7]};

  assign arbin16_gnt1 = {
    arbout21_gnt1[16], arbout20_gnt1[16], arbout19_gnt1[16], arbout18_gnt1[16],
    arbout17_gnt1[16], arbout16_gnt1[16], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt1[16], arbout06_gnt1[16],
    arbout05_gnt1[16], arbout04_gnt1[16], arbout03_gnt1[16], arbout02_gnt1[16],
    arbout01_gnt1[16], arbout00_gnt1[16]};

  assign arbin17_gnt1 = {
    arbout21_gnt1[17], arbout20_gnt1[17], arbout19_gnt1[17], arbout18_gnt1[17],
    arbout17_gnt1[17], arbout16_gnt1[17], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt1[17], arbout06_gnt1[17],
    arbout05_gnt1[17], arbout04_gnt1[17], arbout03_gnt1[17], arbout02_gnt1[17],
    arbout01_gnt1[17], arbout00_gnt1[17]};

  assign arbin18_gnt1 = {
    arbout21_gnt1[18], arbout20_gnt1[18], arbout19_gnt1[18], arbout18_gnt1[18],
    arbout17_gnt1[18], arbout16_gnt1[18], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt1[18], arbout06_gnt1[18],
    arbout05_gnt1[18], arbout04_gnt1[18], arbout03_gnt1[18], arbout02_gnt1[18],
    arbout01_gnt1[18], arbout00_gnt1[18]};

  assign arbin19_gnt1 = {
    arbout21_gnt1[19], arbout20_gnt1[19], arbout19_gnt1[19], arbout18_gnt1[19],
    arbout17_gnt1[19], arbout16_gnt1[19], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt1[19], arbout06_gnt1[19],
    arbout05_gnt1[19], arbout04_gnt1[19], arbout03_gnt1[19], arbout02_gnt1[19],
    arbout01_gnt1[19], arbout00_gnt1[19]};

  assign arbin20_gnt1 = {
    arbout21_gnt1[20], arbout20_gnt1[20], arbout19_gnt1[20], arbout18_gnt1[20],
    arbout17_gnt1[20], arbout16_gnt1[20], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt1[20], arbout06_gnt1[20],
    arbout05_gnt1[20], arbout04_gnt1[20], arbout03_gnt1[20], arbout02_gnt1[20],
    arbout01_gnt1[20], arbout00_gnt1[20]};

  assign arbin21_gnt1 = {
    arbout21_gnt1[21], arbout20_gnt1[21], arbout19_gnt1[21], arbout18_gnt1[21],
    arbout17_gnt1[21], arbout16_gnt1[21], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt1[21], arbout06_gnt1[21],
    arbout05_gnt1[21], arbout04_gnt1[21], arbout03_gnt1[21], arbout02_gnt1[21],
    arbout01_gnt1[21], arbout00_gnt1[21]};

  assign arbin00_gnt2 = {
    arbout21_gnt2[0], arbout20_gnt2[0], arbout19_gnt2[0], arbout18_gnt2[0],
    arbout17_gnt2[0], arbout16_gnt2[0], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt2[0], arbout06_gnt2[0],
    arbout05_gnt2[0], arbout04_gnt2[0], arbout03_gnt2[0], arbout02_gnt2[0],
    arbout01_gnt2[0], arbout00_gnt2[0]};

  assign arbin01_gnt2 = {
    arbout21_gnt2[1], arbout20_gnt2[1], arbout19_gnt2[1], arbout18_gnt2[1],
    arbout17_gnt2[1], arbout16_gnt2[1], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt2[1], arbout06_gnt2[1],
    arbout05_gnt2[1], arbout04_gnt2[1], arbout03_gnt2[1], arbout02_gnt2[1],
    arbout01_gnt2[1], arbout00_gnt2[1]};

  assign arbin02_gnt2 = {
    arbout21_gnt2[2], arbout20_gnt2[2], arbout19_gnt2[2], arbout18_gnt2[2],
    arbout17_gnt2[2], arbout16_gnt2[2], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt2[2], arbout06_gnt2[2],
    arbout05_gnt2[2], arbout04_gnt2[2], arbout03_gnt2[2], arbout02_gnt2[2],
    arbout01_gnt2[2], arbout00_gnt2[2]};

  assign arbin03_gnt2 = {
    arbout21_gnt2[3], arbout20_gnt2[3], arbout19_gnt2[3], arbout18_gnt2[3],
    arbout17_gnt2[3], arbout16_gnt2[3], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt2[3], arbout06_gnt2[3],
    arbout05_gnt2[3], arbout04_gnt2[3], arbout03_gnt2[3], arbout02_gnt2[3],
    arbout01_gnt2[3], arbout00_gnt2[3]};

  assign arbin04_gnt2 = {
    arbout21_gnt2[4], arbout20_gnt2[4], arbout19_gnt2[4], arbout18_gnt2[4],
    arbout17_gnt2[4], arbout16_gnt2[4], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt2[4], arbout06_gnt2[4],
    arbout05_gnt2[4], arbout04_gnt2[4], arbout03_gnt2[4], arbout02_gnt2[4],
    arbout01_gnt2[4], arbout00_gnt2[4]};

  assign arbin05_gnt2 = {
    arbout21_gnt2[5], arbout20_gnt2[5], arbout19_gnt2[5], arbout18_gnt2[5],
    arbout17_gnt2[5], arbout16_gnt2[5], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt2[5], arbout06_gnt2[5],
    arbout05_gnt2[5], arbout04_gnt2[5], arbout03_gnt2[5], arbout02_gnt2[5],
    arbout01_gnt2[5], arbout00_gnt2[5]};

  assign arbin06_gnt2 = {
    arbout21_gnt2[6], arbout20_gnt2[6], arbout19_gnt2[6], arbout18_gnt2[6],
    arbout17_gnt2[6], arbout16_gnt2[6], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt2[6], arbout06_gnt2[6],
    arbout05_gnt2[6], arbout04_gnt2[6], arbout03_gnt2[6], arbout02_gnt2[6],
    arbout01_gnt2[6], arbout00_gnt2[6]};

  assign arbin07_gnt2 = {
    arbout21_gnt2[7], arbout20_gnt2[7], arbout19_gnt2[7], arbout18_gnt2[7],
    arbout17_gnt2[7], arbout16_gnt2[7], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , arbout07_gnt2[7], arbout06_gnt2[7],
    arbout05_gnt2[7], arbout04_gnt2[7], arbout03_gnt2[7], arbout02_gnt2[7],
    arbout01_gnt2[7], arbout00_gnt2[7]};

  assign arbin16_gnt2 = {
    arbout21_gnt2[16], arbout20_gnt2[16], arbout19_gnt2[16], arbout18_gnt2[16],
    arbout17_gnt2[16], arbout16_gnt2[16], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt2[16], arbout06_gnt2[16],
    arbout05_gnt2[16], arbout04_gnt2[16], arbout03_gnt2[16], arbout02_gnt2[16],
    arbout01_gnt2[16], arbout00_gnt2[16]};

  assign arbin17_gnt2 = {
    arbout21_gnt2[17], arbout20_gnt2[17], arbout19_gnt2[17], arbout18_gnt2[17],
    arbout17_gnt2[17], arbout16_gnt2[17], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt2[17], arbout06_gnt2[17],
    arbout05_gnt2[17], arbout04_gnt2[17], arbout03_gnt2[17], arbout02_gnt2[17],
    arbout01_gnt2[17], arbout00_gnt2[17]};

  assign arbin18_gnt2 = {
    arbout21_gnt2[18], arbout20_gnt2[18], arbout19_gnt2[18], arbout18_gnt2[18],
    arbout17_gnt2[18], arbout16_gnt2[18], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt2[18], arbout06_gnt2[18],
    arbout05_gnt2[18], arbout04_gnt2[18], arbout03_gnt2[18], arbout02_gnt2[18],
    arbout01_gnt2[18], arbout00_gnt2[18]};

  assign arbin19_gnt2 = {
    arbout21_gnt2[19], arbout20_gnt2[19], arbout19_gnt2[19], arbout18_gnt2[19],
    arbout17_gnt2[19], arbout16_gnt2[19], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt2[19], arbout06_gnt2[19],
    arbout05_gnt2[19], arbout04_gnt2[19], arbout03_gnt2[19], arbout02_gnt2[19],
    arbout01_gnt2[19], arbout00_gnt2[19]};

  assign arbin20_gnt2 = {
    arbout21_gnt2[20], arbout20_gnt2[20], arbout19_gnt2[20], arbout18_gnt2[20],
    arbout17_gnt2[20], arbout16_gnt2[20], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt2[20], arbout06_gnt2[20],
    arbout05_gnt2[20], arbout04_gnt2[20], arbout03_gnt2[20], arbout02_gnt2[20],
    arbout01_gnt2[20], arbout00_gnt2[20]};

  assign arbin21_gnt2 = {
    arbout21_gnt2[21], arbout20_gnt2[21], arbout19_gnt2[21], arbout18_gnt2[21],
    arbout17_gnt2[21], arbout16_gnt2[21], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , arbout07_gnt2[21], arbout06_gnt2[21],
    arbout05_gnt2[21], arbout04_gnt2[21], arbout03_gnt2[21], arbout02_gnt2[21],
    arbout01_gnt2[21], arbout00_gnt2[21]};


endmodule
