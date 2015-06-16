////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 1999-2008 Easics NV.
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//
// Purpose : synthesizable CRC function
//   * polynomial: (0 2 15 16)
//   * data width: 16
//
// Info : tools@easics.be
//        http://www.easics.com
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module crc16 (
  input      [15:0] i_data,
  input      [15:0] i_crc,
  output reg [15:0] o_crc
);

  reg [15:0] d;
  reg [15:0] c;
  reg [15:0] n;

  // polynomial: (0 2 15 16)
  // data width: 16
  // convention: the first serial bit is D[15]
  always @(*) begin
    d = i_data;
    c = i_crc;

    n[0]  = d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^
            d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0] ^ c[0] ^ c[1] ^ c[2] ^ 
            c[3] ^ c[4] ^ c[5] ^ c[6] ^ c[7] ^ c[8] ^ c[9] ^ c[10] ^ c[11] ^ 
            c[12] ^ c[13] ^ c[15];

    n[1]  = d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^
            d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ c[1] ^ c[2] ^ c[3] ^ c[4] ^ 
            c[5] ^ c[6] ^ c[7] ^ c[8] ^ c[9] ^ c[10] ^ c[11] ^ c[12] ^ 
            c[13] ^ c[14];

    n[2]  = d[14] ^ d[1] ^ d[0] ^ c[0] ^ c[1] ^ c[14];

    n[3]  = d[15] ^ d[2] ^ d[1] ^ c[1] ^ c[2] ^ c[15];

    n[4]  = d[3] ^ d[2] ^ c[2] ^ c[3];

    n[5]  = d[4] ^ d[3] ^ c[3] ^ c[4];

    n[6]  = d[5] ^ d[4] ^ c[4] ^ c[5];

    n[7]  = d[6] ^ d[5] ^ c[5] ^ c[6];

    n[8]  = d[7] ^ d[6] ^ c[6] ^ c[7];

    n[9]  = d[8] ^ d[7] ^ c[7] ^ c[8];

    n[10] = d[9] ^ d[8] ^ c[8] ^ c[9];

    n[11] = d[10] ^ d[9] ^ c[9] ^ c[10];

    n[12] = d[11] ^ d[10] ^ c[10] ^ c[11];

    n[13] = d[12] ^ d[11] ^ c[11] ^ c[12];

    n[14] = d[13] ^ d[12] ^ c[12] ^ c[13];

    n[15] = d[15] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^
            d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0] ^ c[0] ^ c[1] ^ c[2] ^ 
            c[3] ^ c[4] ^ c[5] ^ c[6] ^ c[7] ^ c[8] ^ c[9] ^ c[10] ^ c[11] ^ 
            c[12] ^ c[14] ^ c[15];

    o_crc = n;
  end

endmodule
