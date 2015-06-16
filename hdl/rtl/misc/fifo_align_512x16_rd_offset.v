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
// Abstract      : Mesochronous FIFO 512x16 with read port offset
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: fifo_align_512x16_rd_offset.v,v $
// CVS revision  : $Revision: 1.3 $
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

module fifo_align_512x16_rd_offset (

  // Write interface (linear per-word enqueue)
  input         clk_wr,
  input         rst_wr,
  input  [15:0] i_wr_data,
  input         i_wr_en,
  output        o_full,
  output  [5:0] o_wr_packets,

  // Read interface (16-words packet-based dequeue, random in-packet offset)
  input         clk_rd,
  input         rst_rd,
  output [15:0] o_rd_data,
  input   [3:0] i_rd_offset,
  input         i_rd_eop,
  output        o_empty
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire [4:0] mem_wr_packet_adr;
  reg  [3:0] mem_wr_offset;
  wire [4:0] mem_rd_packet_adr;
  wire       mem_wr_en;
  wire       wr_eop;


  // ==========================================================================
  // Linear write offset
  // ==========================================================================
  assign mem_wr_en = i_wr_en & ~o_full;
  
  assign wr_eop = mem_wr_en & (mem_wr_offset == 4'd15);

  always @(posedge clk_wr) begin
    if (rst_wr) begin
      mem_wr_offset <= #`dh 0;
    end
    else begin
      if (mem_wr_en) 
        mem_wr_offset <= #`dh mem_wr_offset + 1'b1;
    end
  end


  // ==========================================================================
  // Two-port memory, half BRAM, 512x16
  // ==========================================================================

  xil_mem_dp_512x16 i0_xil_mem_dp_512x16 (

    // Write port
    .clk0           ( clk_wr ),
    .i_en0          ( 1'b1 ),
    .i_wen0         ( {2{mem_wr_en}} ),
    .i_adr0         ( {mem_wr_packet_adr, mem_wr_offset} ),
    .i_wdata0       ( i_wr_data ),
    .o_rdata0       ( ),

    // Read port
    .clk1           ( clk_rd ),
    .i_en1          ( 1'b1 ),
    .i_wen1         ( 2'b0 ),
    .i_adr1         ( {mem_rd_packet_adr, i_rd_offset} ),
    .i_wdata1       ( 16'b0 ),
    .o_rdata1       ( o_rd_data )
  );


  // ==========================================================================
  // Aligned clocking FIFO pointer
  // ==========================================================================
  fifo_align_ptr # (
    
    // Paremeters
    .N_log              ( 5 ),
    .RD_PTR_UNBUF       ( 0 ),
    .NEED_WR_WORDS      ( 1 ),
    .NEED_RD_WORDS      ( 0 )

  ) i0_fifo_align_ptr (
    
    // Write side
    .clk_wr             ( clk_wr ),
    .rst_wr             ( rst_wr ),
    .i_wr_advance       ( wr_eop ),
    .o_wr_full          ( o_full ),
    .o_wr_ptr           ( mem_wr_packet_adr ),
    .o_wr_words         ( o_wr_packets ),

    // Read side
    .clk_rd             ( clk_rd ),
    .rst_rd             ( rst_rd ),
    .i_rd_advance       ( i_rd_eop ),
    .o_rd_empty         ( o_empty ),
    .o_rd_ptr_nxt       ( mem_rd_packet_adr ),
    .o_rd_words         ( )
  );


endmodule
