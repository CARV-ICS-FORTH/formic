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
// Abstract      : Two-port memory 64x16
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xil_dmem_tp_64x16.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xil_dmem_tp_64x16 (

  // Write interface
  input         clk_wr,
  input  [15:0] i_wr_data,
  input   [5:0] i_wr_adr,
  input         i_wr_en,

  // Read interface
  input   [5:0] i_rd_adr,
  output [15:0] o_rd_data
);


  // ==========================================================================
  // Two-port memory, distributed, 64x16
  // ==========================================================================
  (* ram_style = "distributed" *)
  reg [15:0] mem_q[0:63];


  // Write port
  always @(posedge clk_wr) begin
    if (i_wr_en) begin
      mem_q[i_wr_adr] <= #`dh i_wr_data;
    end
  end

  // Read port
  assign o_rd_data = mem_q[i_rd_adr];


endmodule
