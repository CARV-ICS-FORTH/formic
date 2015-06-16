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
// Abstract      : Mesochronous FIFO 16x32
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: fifo_align_16x32.v,v $
// CVS revision  : $Revision: 1.4 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

//
// Utilization: Distributed RAM
//
// Note: clk_wr and clk_rd are supposed to be mesochronous (their edges
//       are aligned, because they originate from the same PLL).
//

module fifo_align_16x32 (

  // Write interface
  input         clk_wr,
  input         rst_wr,
  input  [31:0] i_wr_data,
  input         i_wr_en,
  output        o_full,

  // Read interface
  input         clk_rd,
  input         rst_rd,
  output [31:0] o_rd_data,
  input         i_rd_en,
  output        o_empty
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  (* ram_style = "distributed" *)
  reg [31:0] mem_q [0:15];
  reg  [3:0] adr_rd_q;

  wire [3:0] mem_wr_adr;
  wire [3:0] mem_rd_adr;
  wire       mem_wr_en;


  // ==========================================================================
  // Two-port memory, distributed, 16x32
  // ==========================================================================

  // Write port
  assign mem_wr_en = i_wr_en & ~o_full;

  always @(posedge clk_wr) begin
    if (mem_wr_en) begin
      mem_q[mem_wr_adr] <= #`dh i_wr_data;
    end
  end

  // Read port
  always @(posedge clk_rd) begin
    adr_rd_q <= #`dh mem_rd_adr;
  end

  assign o_rd_data = mem_q[adr_rd_q];


  // ==========================================================================
  // Aligned clocking FIFO pointer
  // ==========================================================================
  fifo_align_ptr # (
    
    // Paremeters
    .N_log              ( 4 ),
    .RD_PTR_UNBUF       ( 1 ),
    .NEED_WR_WORDS      ( 0 ),
    .NEED_RD_WORDS      ( 0 )

  ) i0_fifo_align_ptr (
    
    // Write side
    .clk_wr             ( clk_wr ),
    .rst_wr             ( rst_wr ),
    .i_wr_advance       ( i_wr_en ),
    .o_wr_full          ( o_full ),
    .o_wr_ptr           ( mem_wr_adr ),
    .o_wr_words         (  ),

    // Read side
    .clk_rd             ( clk_rd ),
    .rst_rd             ( rst_rd ),
    .i_rd_advance       ( i_rd_en ),
    .o_rd_empty         ( o_empty ),
    .o_rd_ptr_nxt       ( mem_rd_adr ),
    .o_rd_words         (  )
  );


endmodule
