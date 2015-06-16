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
// Abstract      : 2-cycle pulse holder
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: holder2.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// holder2
//
module holder2(
   input      Clk,
   input      Reset,
   input      i_in,
   output reg o_out);
//
reg dl0, dl1;
//
 always @(posedge Clk) begin
    if(Reset) begin
       dl0   <= #`dh 0;
       dl1   <= #`dh 0;
       o_out <= #`dh 0;
    end
    else begin
       dl0 <= #`dh i_in;
       dl1 <= #`dh dl0;
       if(i_in)     o_out <= #`dh 1;
       else if(dl1) o_out <= #`dh 0;
    end
 end
//
endmodule
