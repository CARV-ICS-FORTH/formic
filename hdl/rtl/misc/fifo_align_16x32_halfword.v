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
// Abstract      : Mesochronous FIFO 16x32 with half-word write access
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: fifo_align_16x32_halfword.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

//
// Utilization: Distributed RAM
//
// Note: the block supposes that HIGH accesses are done first and LOW
//       second (which also increase the pointer)
//
// Note: clk_wr and clk_rd are supposed to be mesochronous (their edges
//       are aligned, because they originate from the same PLL).
//

module fifo_align_16x32_halfword (

  // Write interface
  input         clk_wr,
  input         rst_wr,
  input  [15:0] i_wr_data,
  input         i_wr_high,
  input         i_wr_low,
  output        o_full,

  // Read interface
  input         clk_rd,
  input         rst_rd,
  output [31:0] o_rd_data,
  input         i_rd_en,
  output        o_empty
);
  
  reg [15:0] tmp;

  always @(posedge clk_wr) begin
    if (i_wr_high)
      tmp <= #`dh i_wr_data;
  end

  fifo_align_16x32 i0_fifo_align_16x32 (
    .clk_wr     ( clk_wr ),
    .rst_wr     ( rst_wr  ),
    .i_wr_data  ( {tmp, i_wr_data} ),
    .i_wr_en    ( i_wr_low ),
    .o_full     ( o_full ),
    .clk_rd     ( clk_rd ),
    .rst_rd     ( rst_rd ),
    .o_rd_data  ( o_rd_data ),
    .i_rd_en    ( i_rd_en ),
    .o_empty    ( o_empty )
  );

endmodule
