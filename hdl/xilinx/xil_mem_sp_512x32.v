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
// Abstract      : Single-port memory 512x32
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xil_mem_sp_512x32.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

// This weird style is mandatory for the BRAM to be inferred by both
// Virtex-5 and Spartan-6 XST backends. Ignore the warning about mem_q
// missing from sensitivity list (XST will abort with an error if it's
// included). 
//
// Unfortunately, this style is not supported for dual-port memories,
// so we have to work around it.

module xil_mem_sp_512x32 (
  input             clk,
  input             i_en,
  input       [3:0] i_wen,
  input       [8:0] i_adr,
  input      [31:0] i_wdata,
  output reg [31:0] o_rdata
);
  
  reg [31:0] mem_q [0:511];
  reg  [7:0] di0;
  reg  [7:0] di1;
  reg  [7:0] di2;
  reg  [7:0] di3;

  always @(i_wen or i_wdata or i_adr) begin

    if (i_wen[0])
      di0 = i_wdata[7:0];
    else
      di0 = mem_q[i_adr][7:0]; 

    if (i_wen[1])
      di1 = i_wdata[15:8];
    else
      di1 = mem_q[i_adr][15:8]; 

    if (i_wen[2])
      di2 = i_wdata[23:16];
    else
      di2 = mem_q[i_adr][23:16]; 

    if (i_wen[3])
      di3 = i_wdata[31:24];
    else
      di3 = mem_q[i_adr][31:24]; 

  end

  always @(posedge clk) begin
    if (i_en) begin

      mem_q[i_adr] <= #`dh {di3, di2, di1, di0};
      o_rdata      <= #`dh mem_q[i_adr];

    end
  end

endmodule
