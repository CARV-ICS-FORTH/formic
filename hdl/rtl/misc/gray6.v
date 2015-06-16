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
// Abstract      : Custom 6-bit gray-like code encoder/decoder
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: gray6.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps


(* ram_style = "distributed" *)
module gray6_to_binary (
  input      [2:0] in,
  output reg [2:0] out
);

  always @(in) begin 
    case (in) 
      3'b000  : out = 3'b000;
      3'b001  : out = 3'b001;
      3'b011  : out = 3'b010;
      3'b010  : out = 3'b011;
      3'b110  : out = 3'b100;
      3'b100  : out = 3'b101;
      default : out = 3'bx;
    endcase
  end

endmodule


(* ram_style = "distributed" *)
module binary_to_gray6 (
  input      [2:0] in,
  output reg [2:0] out
);

  always @(in) begin
    case (in) 
      3'b000  : out = 3'b000;
      3'b001  : out = 3'b001;
      3'b010  : out = 3'b011;
      3'b011  : out = 3'b010;
      3'b100  : out = 3'b110;
      3'b101  : out = 3'b100;
      default : out = 3'bx;
    endcase
  end

endmodule


