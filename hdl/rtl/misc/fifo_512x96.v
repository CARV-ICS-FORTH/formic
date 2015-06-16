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
// Abstract      : Asynchronous FIFO 512x96
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: fifo_512x96.v,v $
// CVS revision  : $Revision: 1.2 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

//
// Utilization: 3 BRAMs
//
// Note: clk_wr and clk_rd can be completely asynchronous
//

module fifo_512x96 (

  // Write interface
  input         clk_wr,
  input         rst_wr,
  input  [95:0] i_wr_data,
  input         i_wr_en,
  output        o_full,
  output  [9:0] o_wr_words,

  // Read interface
  input         clk_rd,
  input         rst_rd,
  output [95:0] o_rd_data,
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
  // 3 two-port memories, 1 BRAM each, 512x32
  // ==========================================================================

  assign mem_wr_en = i_wr_en & ~o_full;

  xil_mem_dp_512x32 i0_xil_mem_dp_512x32 (

    // Write port
    .clk0           ( clk_wr ),
    .i_en0          ( 1'b1 ),
    .i_wen0         ( {4{mem_wr_en}} ),
    .i_adr0         ( mem_wr_adr ),
    .i_wdata0       ( i_wr_data[95:64] ),
    .o_rdata0       ( ),

    // Read port
    .clk1           ( clk_rd ),
    .i_en1          ( 1'b1 ),
    .i_wen1         ( 4'b0 ),
    .i_adr1         ( mem_rd_adr ),
    .i_wdata1       ( 32'b0 ),
    .o_rdata1       ( o_rd_data[95:64] )
  );

  xil_mem_dp_512x32 i1_xil_mem_dp_512x32 (

    // Write port
    .clk0           ( clk_wr ),
    .i_en0          ( 1'b1 ),
    .i_wen0         ( {4{mem_wr_en}} ),
    .i_adr0         ( mem_wr_adr ),
    .i_wdata0       ( i_wr_data[63:32] ),
    .o_rdata0       ( ),

    // Read port
    .clk1           ( clk_rd ),
    .i_en1          ( 1'b1 ),
    .i_wen1         ( 4'b0 ),
    .i_adr1         ( mem_rd_adr ),
    .i_wdata1       ( 32'b0 ),
    .o_rdata1       ( o_rd_data[63:32] )
  );

  xil_mem_dp_512x32 i2_xil_mem_dp_512x32 (

    // Write port
    .clk0           ( clk_wr ),
    .i_en0          ( 1'b1 ),
    .i_wen0         ( {4{mem_wr_en}} ),
    .i_adr0         ( mem_wr_adr ),
    .i_wdata0       ( i_wr_data[31:0] ),
    .o_rdata0       ( ),

    // Read port
    .clk1           ( clk_rd ),
    .i_en1          ( 1'b1 ),
    .i_wen1         ( 4'b0 ),
    .i_adr1         ( mem_rd_adr ),
    .i_wdata1       ( 32'b0 ),
    .o_rdata1       ( o_rd_data[31:0] )
  );


  // ==========================================================================
  // Asynchronous clocking FIFO pointer
  // ==========================================================================
  fifo_ptr # (
    
    // Paremeters
    .N_log              ( 9 ),
    .RD_PTR_UNBUF       ( 1 ),
    .NEED_WR_WORDS      ( 1 ),
    .NEED_RD_WORDS      ( 1 )

  ) i0_fifo_ptr (
    
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
