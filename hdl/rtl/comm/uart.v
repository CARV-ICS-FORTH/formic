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
// Abstract      : UART top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: uart.v,v $
// CVS revision  : $Revision: 1.4 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// UART
//
module uart(
     input         clk_cpu,
     input         clk_ni,
     input         rst_ni,
     input         clk_xbar,
     input         rst_xbar,
     input         i_ddr_boot_done,
     // UART Interface (clk_cpu)
     input         i_uart_enq,
     input   [7:0] i_uart_enq_data,
     output [10:0] o_uart_tx_words,
     output        o_uart_tx_full,
     input         i_uart_deq,
     output [ 7:0] o_uart_deq_data,
     output [10:0] o_uart_rx_words,
     output        o_uart_rx_empty,
     output        o_uart_byte_rcv,
     // Serial Interface
     input         i_RX,
     output        o_TX);
//
// rst_cpu
//
 rst_sync_simple # (
   .CLOCK_CYCLES ( 2 )
 ) i0_rst_sync_simple (
   .clk          ( clk_cpu ),
   .rst_async    ( rst_ni ),
   .deassert     ( i_ddr_boot_done ),
   .rst          ( rst_cpu )
 );
//
// TX Fifo
//
wire [ 7:0] tx_data;
wire        tx_fifo_empty;
wire        tx_full;
wire        tx_write_en = ~tx_fifo_empty &~tx_full;
//
fifo_align_1024x8 tx_fifo(
    // Write interface
    .clk_wr     ( clk_xbar ),
    .rst_wr     ( rst_xbar ),
    .i_wr_data  ( i_uart_enq_data ),
    .i_wr_en    ( i_uart_enq ),
    .o_full     ( o_uart_tx_full ),
    .o_wr_words ( o_uart_tx_words ),
    // Read interface
    .clk_rd     ( clk_cpu ),
    .rst_rd     ( rst_cpu ),
    .o_rd_data  ( tx_data ),
    .i_rd_en    ( tx_write_en ),
    .o_empty    ( tx_fifo_empty ),
    .o_rd_words ( ));
//
// RX Fifo
//
wire [ 7:0] uart_wr_data;
wire        rx_not_empty;
//
fifo_align_1024x8 rx_fifo(
    // Write interface
    .clk_wr     ( clk_cpu ),
    .rst_wr     ( rst_cpu ),
    .i_wr_data  ( uart_wr_data ),
    .i_wr_en    ( rx_not_empty ),
    .o_full     ( ),
    .o_wr_words ( ),
    // Read interface
    .clk_rd     ( clk_ni ),
    .rst_rd     ( rst_ni ),
    .o_rd_data  ( o_uart_deq_data ),
    .i_rd_en    ( i_uart_deq ),
    .o_empty    ( o_uart_rx_empty ),
    .o_rd_words ( o_uart_rx_words ));
//
// Xilinx UART 
//
//
 uartlite # (
      .C_DATA_BITS        ( 8          ),  //   5 to 8 
      .C_SPLB_CLK_FREQ_HZ ( 10000000   ),  //          
      .C_BAUDRATE         ( 38400      ),  //          
      //.C_BAUDRATE         ( 1000000      ),  //          
      .C_USE_PARITY       ( 0          ),  //   0 to 1 
      .C_ODD_PARITY       ( 0          ),  //   0 to 1 
      .C_FAMILY           ( "spartan6" )   //          
     ) iuartlite (
     .Clk          ( clk_cpu ),
     .Reset        ( rst_cpu ),
     // UART core signals
     .i_rx_read_en       ( rx_not_empty ),
     .o_rx_data          ( uart_wr_data ),
     .o_rx_not_empty     ( rx_not_empty ),
     .o_rx_full          ( rx_full ),
     .o_rx_frame_error   ( rx_frame_error ),
     .o_rx_overrun_error ( rx_overrun_error ),
     .o_rx_parity_error  ( rx_parity_error ),
     .i_tx_write_en      ( tx_write_en ),
     .i_tx_data          ( tx_data ),
     .o_tx_full          ( tx_full ),
     .o_tx_empty         ( tx_empty ),
     // UART signals
     .RX                 ( i_RX ),
     .TX                 ( o_TX ));
//
 assign o_uart_byte_rcv = rx_not_empty;
//
endmodule  

