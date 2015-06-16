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
// Abstract      : Asynchronous FIFO 8x16
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: fifo_8x16.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

//
// Utilization: distributed memory
//
// Note: clk_wr and clk_rd can be completely asynchronous
//

module fifo_8x16 (

  // Write interface
  input             clk_wr,
  input             rst_wr,
  input      [15:0] i_wr_data,
  input             i_wr_en,
  output            o_full,
  output      [3:0] o_wr_words,

  // Read interface
  input             clk_rd,
  input             rst_rd,
  output reg [15:0] o_rd_data,
  input             i_rd_en,
  output            o_empty,
  output      [3:0] o_rd_words
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire  [2:0] mem_wr_adr;
  wire  [2:0] mem_rd_adr;
  wire        mem_wr_en;
  wire [15:0] mem_rd_data;


  // ==========================================================================
  // Distributed memory
  // ==========================================================================

  assign mem_wr_en = i_wr_en & ~o_full;

  xil_dmem_tp_8x16 i0_xil_dmem_tp_8x16 (

    // Write port
    .clk_wr         ( clk_wr ),
    .i_wr_en        ( mem_wr_en ),
    .i_wr_adr       ( mem_wr_adr ),
    .i_wr_data      ( i_wr_data ),

    // Read port
    .i_rd_adr       ( mem_rd_adr ),
    .o_rd_data      ( mem_rd_data )
  );

  // Xilinx tools have a bug and we work around it here. 
  //
  // Normally, we would use a buffered rd_ptr and read asynchronously from the
  // distributed memory with it. But, if we do so, the tools think that this
  // read port is actually clocked by clk_wr, not clk_rd. So, they complain
  // about paths starting from o_rd_data as if they are clocked by clk_wr.
  // There is no way to say to the tools that this is actually a clk_rd source
  // -- if we false-path it, it will ignore the whole path which is not what we
  // want (we want it to be a valid clk_rd path).
  //
  // So, we use an unbuffered rd_ptr, read asynchronously and then latch the
  // data on clk_rd before we send them out.
  always @(posedge clk_rd) begin
    o_rd_data <= #`dh mem_rd_data;
  end


  // ==========================================================================
  // Asynchronous clocking FIFO pointer
  // ==========================================================================
  fifo_ptr # (
    
    // Paremeters
    .N_log              ( 3 ),
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
