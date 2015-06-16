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
// Abstract      : Gray-to-binary encoder/decoder
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: gray.v,v $
// CVS revision  : $Revision: 1.2 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

// ============================================================================
// Generic N-bit gray code conversion modules
// ============================================================================

module gray_to_binary # (
  parameter        N = 4
) (
  input      [N-1:0] in,
  output reg [N-1:0] out
);
  integer i;

  always @(in) begin 
    out[N-1] = in[N-1];
    for (i = N-2; i >= 0; i = i - 1)
      out[i] = out[i+1] ^ in[i];
  end

endmodule


module binary_to_gray # (
  parameter        N = 4
) (
  input      [N-1:0] in,
  output reg [N-1:0] out
);
  integer i;

  always @(in) begin
    out[N-1] = in[N-1];
    for (i = N-2; i >= 0; i = i - 1)
      out[i] = in[i+1] ^ in[i];

  end

endmodule


