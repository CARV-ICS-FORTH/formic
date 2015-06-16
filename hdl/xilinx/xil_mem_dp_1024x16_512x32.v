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
// Abstract      : Dual-port memory 1024x16 (1st port) -- 512x32 (2nd port)
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xil_mem_dp_1024x16_512x32.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xil_mem_dp_1024x16_512x32 (
  
  // Narrow port
  input             clk0,
  input             i_en0,
  input       [1:0] i_wen0,
  input       [9:0] i_adr0,
  input      [15:0] i_wdata0,
  output     [15:0] o_rdata0,
  
  // Wide port
  input             clk1,
  input             i_en1,
  input       [3:0] i_wen1,
  input       [8:0] i_adr1,
  input      [31:0] i_wdata1,
  output     [31:0] o_rdata1
);

  wire  [3:0] wen0;
  wire  [9:0] adr0_d;
  reg   [9:0] adr0_q;
  wire [31:0] wdata0;
  wire [31:0] rdata0;

  // Low-address 16-b word is written to High part (left) of 32-bit word
  assign wen0 = { ~i_adr0[0] & i_wen0[1],
                  ~i_adr0[0] & i_wen0[0],
                   i_adr0[0] & i_wen0[1],
                   i_adr0[0] & i_wen0[0]};

  assign adr0_d = i_adr0;

  assign wdata0 = {i_wdata0, i_wdata0};

  assign o_rdata0 = (adr0_q[0]) ? rdata0[15:0] : rdata0[31:16];


  always @(posedge clk0) adr0_q <= adr0_d;

  
  xil_mem_dp_512x32 i0_xil_mem_dp_512x32 (

    .clk0       ( clk0 ),
    .i_en0      ( i_en0 ),
    .i_wen0     ( wen0 ),
    .i_adr0     ( adr0_d[9:1] ),
    .i_wdata0   ( wdata0 ),
    .o_rdata0   ( rdata0 ),

    .clk1       ( clk1 ),
    .i_en1      ( i_en1),
    .i_wen1     ( i_wen1),
    .i_adr1     ( i_adr1 ),
    .i_wdata1   ( i_wdata1 ),
    .o_rdata1   ( o_rdata1 )
  );
  

endmodule
