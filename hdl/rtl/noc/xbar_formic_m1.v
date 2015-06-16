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
// Abstract      : Reduced 7-port Crossbar (excludes 7 MBS and 8 GTP ports)
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbar_formic_m1.v,v $
// CVS revision  : $Revision: 1.2 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbar_formic_m1 (
  
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
    .i_data01               ( 16'b0 ),
    .i_data02               ( 16'b0 ),
    .i_data03               ( 16'b0 ),
    .i_data04               ( 16'b0 ),
    .i_data05               ( 16'b0 ),
    .i_data06               ( 16'b0 ),
    .i_data07               ( 16'b0 ),
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

  xbar_mux i16_xbar_mux (
    .clk                    ( clk_xbar ),
    .i_data00               ( arbin00_data ),
    .i_data01               ( 16'b0 ),
    .i_data02               ( 16'b0 ),
    .i_data03               ( 16'b0 ),
    .i_data04               ( 16'b0 ),
    .i_data05               ( 16'b0 ),
    .i_data06               ( 16'b0 ),
    .i_data07               ( 16'b0 ),
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
    .i_data01               ( 16'b0 ),
    .i_data02               ( 16'b0 ),
    .i_data03               ( 16'b0 ),
    .i_data04               ( 16'b0 ),
    .i_data05               ( 16'b0 ),
    .i_data06               ( 16'b0 ),
    .i_data07               ( 16'b0 ),
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
    .i_data01               ( 16'b0 ),
    .i_data02               ( 16'b0 ),
    .i_data03               ( 16'b0 ),
    .i_data04               ( 16'b0 ),
    .i_data05               ( 16'b0 ),
    .i_data06               ( 16'b0 ),
    .i_data07               ( 16'b0 ),
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
    .i_data01               ( 16'b0 ),
    .i_data02               ( 16'b0 ),
    .i_data03               ( 16'b0 ),
    .i_data04               ( 16'b0 ),
    .i_data05               ( 16'b0 ),
    .i_data06               ( 16'b0 ),
    .i_data07               ( 16'b0 ),
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
    .i_data01               ( 16'b0 ),
    .i_data02               ( 16'b0 ),
    .i_data03               ( 16'b0 ),
    .i_data04               ( 16'b0 ),
    .i_data05               ( 16'b0 ),
    .i_data06               ( 16'b0 ),
    .i_data07               ( 16'b0 ),
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
    .i_data01               ( 16'b0 ),
    .i_data02               ( 16'b0 ),
    .i_data03               ( 16'b0 ),
    .i_data04               ( 16'b0 ),
    .i_data05               ( 16'b0 ),
    .i_data06               ( 16'b0 ),
    .i_data07               ( 16'b0 ),
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
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , arbin00_req0[0]};

  assign arbout16_req0 = {
    arbin21_req0[16], arbin20_req0[16], arbin19_req0[16], arbin18_req0[16],
    arbin17_req0[16], arbin16_req0[16], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req0[16]};

  assign arbout17_req0 = {
    arbin21_req0[17], arbin20_req0[17], arbin19_req0[17], arbin18_req0[17],
    arbin17_req0[17], arbin16_req0[17], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req0[17]};

  assign arbout18_req0 = {
    arbin21_req0[18], arbin20_req0[18], arbin19_req0[18], arbin18_req0[18],
    arbin17_req0[18], arbin16_req0[18], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req0[18]};

  assign arbout19_req0 = {
    arbin21_req0[19], arbin20_req0[19], arbin19_req0[19], arbin18_req0[19],
    arbin17_req0[19], arbin16_req0[19], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req0[19]};

  assign arbout20_req0 = {
    arbin21_req0[20], arbin20_req0[20], arbin19_req0[20], arbin18_req0[20],
    arbin17_req0[20], arbin16_req0[20], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req0[20]};

  assign arbout21_req0 = {
    arbin21_req0[21], arbin20_req0[21], arbin19_req0[21], arbin18_req0[21],
    arbin17_req0[21], arbin16_req0[21], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req0[21]};

  assign arbout00_req1 = {
    arbin21_req1[0], arbin20_req1[0], arbin19_req1[0], arbin18_req1[0],
    arbin17_req1[0], arbin16_req1[0], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , arbin00_req1[0]};

  assign arbout16_req1 = {
    arbin21_req1[16], arbin20_req1[16], arbin19_req1[16], arbin18_req1[16],
    arbin17_req1[16], arbin16_req1[16], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req1[16]};

  assign arbout17_req1 = {
    arbin21_req1[17], arbin20_req1[17], arbin19_req1[17], arbin18_req1[17],
    arbin17_req1[17], arbin16_req1[17], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req1[17]};

  assign arbout18_req1 = {
    arbin21_req1[18], arbin20_req1[18], arbin19_req1[18], arbin18_req1[18],
    arbin17_req1[18], arbin16_req1[18], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req1[18]};

  assign arbout19_req1 = {
    arbin21_req1[19], arbin20_req1[19], arbin19_req1[19], arbin18_req1[19],
    arbin17_req1[19], arbin16_req1[19], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req1[19]};

  assign arbout20_req1 = {
    arbin21_req1[20], arbin20_req1[20], arbin19_req1[20], arbin18_req1[20],
    arbin17_req1[20], arbin16_req1[20], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req1[20]};

  assign arbout21_req1 = {
    arbin21_req1[21], arbin20_req1[21], arbin19_req1[21], arbin18_req1[21],
    arbin17_req1[21], arbin16_req1[21], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req1[21]};

  assign arbout00_req2 = {
    arbin21_req2[0], arbin20_req2[0], arbin19_req2[0], arbin18_req2[0],
    arbin17_req2[0], arbin16_req2[0], 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , 1'b0           , 1'b0           , 1'b0           ,
    1'b0           , arbin00_req2[0]};

  assign arbout16_req2 = {
    arbin21_req2[16], arbin20_req2[16], arbin19_req2[16], arbin18_req2[16],
    arbin17_req2[16], arbin16_req2[16], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req2[16]};

  assign arbout17_req2 = {
    arbin21_req2[17], arbin20_req2[17], arbin19_req2[17], arbin18_req2[17],
    arbin17_req2[17], arbin16_req2[17], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req2[17]};

  assign arbout18_req2 = {
    arbin21_req2[18], arbin20_req2[18], arbin19_req2[18], arbin18_req2[18],
    arbin17_req2[18], arbin16_req2[18], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req2[18]};

  assign arbout19_req2 = {
    arbin21_req2[19], arbin20_req2[19], arbin19_req2[19], arbin18_req2[19],
    arbin17_req2[19], arbin16_req2[19], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req2[19]};

  assign arbout20_req2 = {
    arbin21_req2[20], arbin20_req2[20], arbin19_req2[20], arbin18_req2[20],
    arbin17_req2[20], arbin16_req2[20], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req2[20]};

  assign arbout21_req2 = {
    arbin21_req2[21], arbin20_req2[21], arbin19_req2[21], arbin18_req2[21],
    arbin17_req2[21], arbin16_req2[21], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbin00_req2[21]};

  
  // ==========================================================================
  // Grant stiching
  // ==========================================================================
  assign arbin00_gnt0 = {
    arbout21_gnt0[0], arbout20_gnt0[0], arbout19_gnt0[0], arbout18_gnt0[0],
    arbout17_gnt0[0], arbout16_gnt0[0], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbout00_gnt0[0]};

  assign arbin16_gnt0 = {
    arbout21_gnt0[16], arbout20_gnt0[16], arbout19_gnt0[16], arbout18_gnt0[16],
    arbout17_gnt0[16], arbout16_gnt0[16], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt0[16]};

  assign arbin17_gnt0 = {
    arbout21_gnt0[17], arbout20_gnt0[17], arbout19_gnt0[17], arbout18_gnt0[17],
    arbout17_gnt0[17], arbout16_gnt0[17], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt0[17]};

  assign arbin18_gnt0 = {
    arbout21_gnt0[18], arbout20_gnt0[18], arbout19_gnt0[18], arbout18_gnt0[18],
    arbout17_gnt0[18], arbout16_gnt0[18], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt0[18]};

  assign arbin19_gnt0 = {
    arbout21_gnt0[19], arbout20_gnt0[19], arbout19_gnt0[19], arbout18_gnt0[19],
    arbout17_gnt0[19], arbout16_gnt0[19], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt0[19]};

  assign arbin20_gnt0 = {
    arbout21_gnt0[20], arbout20_gnt0[20], arbout19_gnt0[20], arbout18_gnt0[20],
    arbout17_gnt0[20], arbout16_gnt0[20], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt0[20]};

  assign arbin21_gnt0 = {
    arbout21_gnt0[21], arbout20_gnt0[21], arbout19_gnt0[21], arbout18_gnt0[21],
    arbout17_gnt0[21], arbout16_gnt0[21], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt0[21]};

  assign arbin00_gnt1 = {
    arbout21_gnt1[0], arbout20_gnt1[0], arbout19_gnt1[0], arbout18_gnt1[0],
    arbout17_gnt1[0], arbout16_gnt1[0], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbout00_gnt1[0]};

  assign arbin16_gnt1 = {
    arbout21_gnt1[16], arbout20_gnt1[16], arbout19_gnt1[16], arbout18_gnt1[16],
    arbout17_gnt1[16], arbout16_gnt1[16], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt1[16]};

  assign arbin17_gnt1 = {
    arbout21_gnt1[17], arbout20_gnt1[17], arbout19_gnt1[17], arbout18_gnt1[17],
    arbout17_gnt1[17], arbout16_gnt1[17], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt1[17]};

  assign arbin18_gnt1 = {
    arbout21_gnt1[18], arbout20_gnt1[18], arbout19_gnt1[18], arbout18_gnt1[18],
    arbout17_gnt1[18], arbout16_gnt1[18], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt1[18]};

  assign arbin19_gnt1 = {
    arbout21_gnt1[19], arbout20_gnt1[19], arbout19_gnt1[19], arbout18_gnt1[19],
    arbout17_gnt1[19], arbout16_gnt1[19], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt1[19]};

  assign arbin20_gnt1 = {
    arbout21_gnt1[20], arbout20_gnt1[20], arbout19_gnt1[20], arbout18_gnt1[20],
    arbout17_gnt1[20], arbout16_gnt1[20], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt1[20]};

  assign arbin21_gnt1 = {
    arbout21_gnt1[21], arbout20_gnt1[21], arbout19_gnt1[21], arbout18_gnt1[21],
    arbout17_gnt1[21], arbout16_gnt1[21], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt1[21]};

  assign arbin00_gnt2 = {
    arbout21_gnt2[0], arbout20_gnt2[0], arbout19_gnt2[0], arbout18_gnt2[0],
    arbout17_gnt2[0], arbout16_gnt2[0], 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , 1'b0            , 1'b0            , 1'b0            ,
    1'b0            , arbout00_gnt2[0]};

  assign arbin16_gnt2 = {
    arbout21_gnt2[16], arbout20_gnt2[16], arbout19_gnt2[16], arbout18_gnt2[16],
    arbout17_gnt2[16], arbout16_gnt2[16], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt2[16]};

  assign arbin17_gnt2 = {
    arbout21_gnt2[17], arbout20_gnt2[17], arbout19_gnt2[17], arbout18_gnt2[17],
    arbout17_gnt2[17], arbout16_gnt2[17], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt2[17]};

  assign arbin18_gnt2 = {
    arbout21_gnt2[18], arbout20_gnt2[18], arbout19_gnt2[18], arbout18_gnt2[18],
    arbout17_gnt2[18], arbout16_gnt2[18], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt2[18]};

  assign arbin19_gnt2 = {
    arbout21_gnt2[19], arbout20_gnt2[19], arbout19_gnt2[19], arbout18_gnt2[19],
    arbout17_gnt2[19], arbout16_gnt2[19], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt2[19]};

  assign arbin20_gnt2 = {
    arbout21_gnt2[20], arbout20_gnt2[20], arbout19_gnt2[20], arbout18_gnt2[20],
    arbout17_gnt2[20], arbout16_gnt2[20], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt2[20]};

  assign arbin21_gnt2 = {
    arbout21_gnt2[21], arbout20_gnt2[21], arbout19_gnt2[21], arbout18_gnt2[21],
    arbout17_gnt2[21], arbout16_gnt2[21], 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , 1'b0             , 1'b0             , 1'b0             ,
    1'b0             , arbout00_gnt2[21]};


endmodule
