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
// Abstract      : Mesochronous FIFO 512x16
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: fifo_align_512x16.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

//
// Utilization: Half BRAM
//
// Note: clk_wr and clk_rd are supposed to be mesochronous (their edges
//       are aligned, because they originate from the same PLL).
//

module fifo_align_512x16 (

  // Write interface
  input         clk_wr,
  input         rst_wr,
  input  [15:0] i_wr_data,
  input         i_wr_en,
  output        o_full,
  output  [9:0] o_wr_words,

  // Read interface
  input         clk_rd,
  input         rst_rd,
  output [15:0] o_rd_data,
  input         i_rd_en,
  output        o_empty,
  output  [9:0] o_rd_words
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire [8:0] mem_wr_adr;
  wire [8:0] mem_rd_adr;
  wire       mem_wr_en;


  // ==========================================================================
  // Two-port memory, half BRAM, 512x16
  // ==========================================================================

  assign mem_wr_en = i_wr_en & ~o_full;

  xil_mem_dp_512x16 i0_xil_mem_dp_512x16 (

    // Write port
    .clk0           ( clk_wr ),
    .i_en0          ( 1'b1 ),
    .i_wen0         ( {2{mem_wr_en}} ),
    .i_adr0         ( mem_wr_adr ),
    .i_wdata0       ( i_wr_data ),
    .o_rdata0       ( ),

    // Read port
    .clk1           ( clk_rd ),
    .i_en1          ( 1'b1 ),
    .i_wen1         ( 2'b0 ),
    .i_adr1         ( mem_rd_adr ),
    .i_wdata1       ( 16'b0 ),
    .o_rdata1       ( o_rd_data )
  );


  // ==========================================================================
  // Aligned clocking FIFO pointer
  // ==========================================================================
  fifo_align_ptr # (
    
    // Paremeters
    .N_log              ( 9 ),
    .RD_PTR_UNBUF       ( 1 ),
    .NEED_WR_WORDS      ( 1 ),
    .NEED_RD_WORDS      ( 1 )

  ) i0_fifo_align_ptr (
    
    // Write side
    .clk_wr             ( clk_wr ),
    .rst_wr             ( rst_wr ),
    .i_wr_advance       ( i_wr_en ),
    .o_wr_full          ( o_full ),
    .o_wr_ptr           ( mem_wr_adr ),
    .o_wr_words         ( o_wr_words ),

    // Read side
    .clk_rd             ( clk_rd ),
    .rst_rd             ( rst_rd ),
    .i_rd_advance       ( i_rd_en ),
    .o_rd_empty         ( o_empty ),
    .o_rd_ptr_nxt       ( mem_rd_adr ),
    .o_rd_words         ( o_rd_words )
  );


endmodule
