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
// Abstract      : 4xGTP back-end for Formic Spartan-6
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: gtp_quad_back_end.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module gtp_quad_back_end (

    // Physical GTP blocks clocking/reset signals
    input         aref_clk_p,
    input         aref_clk_n,
    input         rst_gtp_phy,
    output        o_ref_clk,
    output        o_ref_clk_locked,
    input         i_gtp_clk_locked,
    input         clk_gtp_2x,
    output        o_gtp_init_done,

    // Back end clock & reset
    input         clk_gtp,
    input         rst_gtp,

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

    // Back end link #0
    input         i_link0_powerdown,
    output        o_link0_up,
    output        o_link0_error,

    input         i_link0_valid,
    input         i_link0_sop,
    input         i_link0_eop,
    input  [15:0] i_link0_data,

    output        o_link0_valid,
    output        o_link0_sop,
    output        o_link0_eop,
    output [15:0] o_link0_data,

    input   [2:0] i_link0_vc_enq,
    input   [2:0] i_link0_vc_deq,
    output  [2:0] o_link0_xoff,

    // Back end link #1
    input         i_link1_powerdown,
    output        o_link1_up,
    output        o_link1_error,

    input         i_link1_valid,
    input         i_link1_sop,
    input         i_link1_eop,
    input  [15:0] i_link1_data,

    output        o_link1_valid,
    output        o_link1_sop,
    output        o_link1_eop,
    output [15:0] o_link1_data,

    input   [2:0] i_link1_vc_enq,
    input   [2:0] i_link1_vc_deq,
    output  [2:0] o_link1_xoff,

    // Back end link #2
    input         i_link2_powerdown,
    output        o_link2_up,
    output        o_link2_error,

    input         i_link2_valid,
    input         i_link2_sop,
    input         i_link2_eop,
    input  [15:0] i_link2_data,

    output        o_link2_valid,
    output        o_link2_sop,
    output        o_link2_eop,
    output [15:0] o_link2_data,

    input   [2:0] i_link2_vc_enq,
    input   [2:0] i_link2_vc_deq,
    output  [2:0] o_link2_xoff,

    // Back end link #3
    input         i_link3_powerdown,
    output        o_link3_up,
    output        o_link3_error,

    input         i_link3_valid,
    input         i_link3_sop,
    input         i_link3_eop,
    input  [15:0] i_link3_data,

    output        o_link3_valid,
    output        o_link3_sop,
    output        o_link3_eop,
    output [15:0] o_link3_data,

    input   [2:0] i_link3_vc_enq,
    input   [2:0] i_link3_vc_deq,
    output  [2:0] o_link3_xoff
);

wire [15:0] rio0_txdata, rio1_txdata, rio2_txdata, rio3_txdata;
wire  [1:0] rio0_txisk , rio1_txisk , rio2_txisk , rio3_txisk ;
wire [15:0] rio0_rxdata, rio1_rxdata, rio2_rxdata, rio3_rxdata;
wire  [1:0] rio0_rxisk , rio1_rxisk , rio2_rxisk , rio3_rxisk ;

wire  [1:0] rio0_los, rio1_los, rio2_los, rio3_los;
wire  [1:0] rio0_dpe, rio1_dpe, rio2_dpe, rio3_dpe;
wire  [1:0] rio0_nit, rio1_nit, rio2_nit, rio3_nit;
wire  [2:0] rio0_bfs, rio1_bfs, rio2_bfs, rio3_bfs;


wire tile0_plllkdet , tile1_plllkdet ;
wire tile0_refclkout, tile1_refclkout;
wire tile_rst = ~i_gtp_clk_locked;

wire rio0_rstdone, rio1_rstdone, rio2_rstdone, rio3_rstdone;
wire rio_clk = clk_gtp;
wire rio_rst = rst_gtp;

assign o_ref_clk = tile0_refclkout;
assign o_ref_clk_locked = tile0_plllkdet & tile1_plllkdet;
assign o_gtp_init_done = rio0_rstdone & rio1_rstdone & rio2_rstdone & rio3_rstdone;


IBUFDS i0_ibufds ( 
  .I    ( aref_clk_p ),
  .IB   ( aref_clk_n ),
  .O    ( aref_clk_buf )
);


rio_gtps6 rio_tile0(
  .GTPRESET_IN       (rst_gtp_phy),
  .CLKIN_IN          (aref_clk_buf),

  .PLLLKDET_OUT      (tile0_plllkdet),
  .REFCLKOUT_OUT     (tile0_refclkout),

  .POWERDOWN0_IN     (i_link0_powerdown),
  .POWERDOWN1_IN     (i_link1_powerdown),

  .USRCLK_IN         (clk_gtp_2x),
  .USRCLK2_IN        (clk_gtp),
  .INITRST_IN        (tile_rst),

  .RESETDONE0_OUT    (rio0_rstdone),
  .TXDATA0_IN        (rio0_txdata),
  .TXCHARISK0_IN     (rio0_txisk),
  .RXDATA0_OUT       (rio0_rxdata),
  .RXCHARISK0_OUT    (rio0_rxisk),
  .RXLOSSOFSYNC0_OUT (rio0_los),
  .RXDISPERR0_OUT    (rio0_dpe),
  .RXNOTINTABLE0_OUT (rio0_nit),
  .RXBUFSTATUS0_OUT  (rio0_bfs),

  .RESETDONE1_OUT    (rio1_rstdone),
  .TXDATA1_IN        (rio1_txdata),
  .TXCHARISK1_IN     (rio1_txisk),
  .RXDATA1_OUT       (rio1_rxdata),
  .RXCHARISK1_OUT    (rio1_rxisk),
  .RXLOSSOFSYNC1_OUT (rio1_los),
  .RXDISPERR1_OUT    (rio1_dpe),
  .RXNOTINTABLE1_OUT (rio1_nit),
  .RXBUFSTATUS1_OUT  (rio1_bfs),

  .TXN0_OUT          (o_gtp0_tx_n),
  .TXP0_OUT          (o_gtp0_tx_p),
  .RXN0_IN           (i_gtp0_rx_n),
  .RXP0_IN           (i_gtp0_rx_p),

  .TXN1_OUT          (o_gtp1_tx_n),
  .TXP1_OUT          (o_gtp1_tx_p),
  .RXN1_IN           (i_gtp1_rx_n),
  .RXP1_IN           (i_gtp1_rx_p)
);

rio_gtps6 rio_tile1(
  .GTPRESET_IN       (rst_gtp_phy),
  .CLKIN_IN          (aref_clk_buf),

  .PLLLKDET_OUT      (tile1_plllkdet),
  .REFCLKOUT_OUT     (tile1_refclkout),

  .POWERDOWN0_IN     (i_link2_powerdown),
  .POWERDOWN1_IN     (i_link3_powerdown),

  .USRCLK_IN         (clk_gtp_2x),
  .USRCLK2_IN        (clk_gtp),
  .INITRST_IN        (tile_rst),

  .RESETDONE0_OUT    (rio2_rstdone),
  .TXDATA0_IN        (rio2_txdata),
  .TXCHARISK0_IN     (rio2_txisk),
  .RXDATA0_OUT       (rio2_rxdata),
  .RXCHARISK0_OUT    (rio2_rxisk),
  .RXLOSSOFSYNC0_OUT (rio2_los),
  .RXDISPERR0_OUT    (rio2_dpe),
  .RXNOTINTABLE0_OUT (rio2_nit),
  .RXBUFSTATUS0_OUT  (rio2_bfs),

  .RESETDONE1_OUT    (rio3_rstdone),
  .TXDATA1_IN        (rio3_txdata),
  .TXCHARISK1_IN     (rio3_txisk),
  .RXDATA1_OUT       (rio3_rxdata),
  .RXCHARISK1_OUT    (rio3_rxisk),
  .RXLOSSOFSYNC1_OUT (rio3_los),
  .RXDISPERR1_OUT    (rio3_dpe),
  .RXNOTINTABLE1_OUT (rio3_nit),
  .RXBUFSTATUS1_OUT  (rio3_bfs),

  .TXN0_OUT          (o_gtp2_tx_n),
  .TXP0_OUT          (o_gtp2_tx_p),
  .RXN0_IN           (i_gtp2_rx_n),
  .RXP0_IN           (i_gtp2_rx_p),

  .TXN1_OUT          (o_gtp3_tx_n),
  .TXP1_OUT          (o_gtp3_tx_p),
  .RXN1_IN           (i_gtp3_rx_n),
  .RXP1_IN           (i_gtp3_rx_p)
);


rio_link rio0(
  .clk                      (rio_clk),
  .rst                      (rio_rst),

  .i_tx_valid               (i_link0_valid),
  .i_tx_sop                 (i_link0_sop),
  .i_tx_eop                 (i_link0_eop),
  .i_tx_data                (i_link0_data),
  .o_tx_rdy                 (),

  .o_rx_valid               (o_link0_valid),
  .o_rx_sop                 (o_link0_sop),
  .o_rx_eop                 (o_link0_eop),
  .o_rx_data                (o_link0_data),

  .o_link_up                (o_link0_up),
  .o_link_error             (o_link0_error),

  .o_link_xoff              (o_link0_xoff),
  .i_link_enq               (i_link0_vc_enq),
  .i_link_deq               (i_link0_vc_deq),

  .o_rio_tx_data            (rio0_txdata),
  .o_rio_tx_isk             (rio0_txisk),
  .i_rio_rx_data            (rio0_rxdata),
  .i_rio_rx_isk             (rio0_rxisk),
  .i_rio_loss_of_sync       (rio0_los),
  .i_rio_rx_disp_err        (rio0_dpe),
  .i_rio_rx_not_in_table    (rio0_nit),
  .i_rio_rx_buf_status      (rio0_bfs)
);

rio_link rio1(
  .clk                      (rio_clk),
  .rst                      (rio_rst),

  .i_tx_valid               (i_link1_valid),
  .i_tx_sop                 (i_link1_sop),
  .i_tx_eop                 (i_link1_eop),
  .i_tx_data                (i_link1_data),
  .o_tx_rdy                 (),

  .o_rx_valid               (o_link1_valid),
  .o_rx_sop                 (o_link1_sop),
  .o_rx_eop                 (o_link1_eop),
  .o_rx_data                (o_link1_data),

  .o_link_up                (o_link1_up),
  .o_link_error             (o_link1_error),

  .o_link_xoff              (o_link1_xoff),
  .i_link_enq               (i_link1_vc_enq),
  .i_link_deq               (i_link1_vc_deq),

  .o_rio_tx_data            (rio1_txdata),
  .o_rio_tx_isk             (rio1_txisk),
  .i_rio_rx_data            (rio1_rxdata),
  .i_rio_rx_isk             (rio1_rxisk),
  .i_rio_loss_of_sync       (rio1_los),
  .i_rio_rx_disp_err        (rio1_dpe),
  .i_rio_rx_not_in_table    (rio1_nit),
  .i_rio_rx_buf_status      (rio1_bfs)
);

rio_link rio2(
  .clk                      (rio_clk),
  .rst                      (rio_rst),

  .i_tx_valid               (i_link2_valid),
  .i_tx_sop                 (i_link2_sop),
  .i_tx_eop                 (i_link2_eop),
  .i_tx_data                (i_link2_data),
  .o_tx_rdy                 (),

  .o_rx_valid               (o_link2_valid),
  .o_rx_sop                 (o_link2_sop),
  .o_rx_eop                 (o_link2_eop),
  .o_rx_data                (o_link2_data),

  .o_link_up                (o_link2_up),
  .o_link_error             (o_link2_error),

  .o_link_xoff              (o_link2_xoff),
  .i_link_enq               (i_link2_vc_enq),
  .i_link_deq               (i_link2_vc_deq),

  .o_rio_tx_data            (rio2_txdata),
  .o_rio_tx_isk             (rio2_txisk),
  .i_rio_rx_data            (rio2_rxdata),
  .i_rio_rx_isk             (rio2_rxisk),
  .i_rio_loss_of_sync       (rio2_los),
  .i_rio_rx_disp_err        (rio2_dpe),
  .i_rio_rx_not_in_table    (rio2_nit),
  .i_rio_rx_buf_status      (rio2_bfs)
);

rio_link rio3(
  .clk                      (rio_clk),
  .rst                      (rio_rst),

  .i_tx_valid               (i_link3_valid),
  .i_tx_sop                 (i_link3_sop),
  .i_tx_eop                 (i_link3_eop),
  .i_tx_data                (i_link3_data),
  .o_tx_rdy                 (),

  .o_rx_valid               (o_link3_valid),
  .o_rx_sop                 (o_link3_sop),
  .o_rx_eop                 (o_link3_eop),
  .o_rx_data                (o_link3_data),

  .o_link_up                (o_link3_up),
  .o_link_error             (o_link3_error),

  .o_link_xoff              (o_link3_xoff),
  .i_link_enq               (i_link3_vc_enq),
  .i_link_deq               (i_link3_vc_deq),

  .o_rio_tx_data            (rio3_txdata),
  .o_rio_tx_isk             (rio3_txisk),
  .i_rio_rx_data            (rio3_rxdata),
  .i_rio_rx_isk             (rio3_rxisk),
  .i_rio_loss_of_sync       (rio3_los),
  .i_rio_rx_disp_err        (rio3_dpe),
  .i_rio_rx_not_in_table    (rio3_nit),
  .i_rio_rx_buf_status      (rio3_bfs)
);


endmodule
