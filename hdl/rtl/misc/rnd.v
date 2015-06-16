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
// Author        : George Kalokerinos
// Abstract      : 3-bit pseudo-random generator
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rnd.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// rnd
//
module rnd(
    input        Clk,
    input        Reset,
    input        i_shift,
    output [2:0] o_out,
    output [7:0] o_out_termo);
//
 reg  [5:0] s_reg;
 wire       msb = s_reg[1] ^ s_reg[0];
//
 always @(posedge Clk) begin
    if (Reset)
       s_reg <= #`dh 6'b111111;
    else if(i_shift)
       s_reg <= #`dh {msb,s_reg[5:1]};
 end
//
 assign o_out = s_reg[2:0];
//
 reg  [7:0] mask;
 wire [2:0] mask_in = s_reg[2:0];
 always @(mask_in) begin
    case(mask_in)
          0    : mask = 8'b0000_0001;
          1    : mask = 8'b0000_0011;
          2    : mask = 8'b0000_0111;
          3    : mask = 8'b0000_1111;
          4    : mask = 8'b0001_1111;
          5    : mask = 8'b0011_1111;
          6    : mask = 8'b0111_1111;
          7    : mask = 8'b1111_1111;
       default : mask = 8'b1111_1111;
    endcase
 end
//
 assign o_out_termo = mask;
//
endmodule
