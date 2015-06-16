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
// Abstract      : 8-KB Boot ROM memory
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: boot_mem.v,v $
// CVS revision  : $Revision: 1.7 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module boot_mem (
  input             clk,
  input      [10:0] i_adr,
  output     [31:0] o_data
);
  
  reg [31:0] mem0 [0:511];
  reg [31:0] mem1 [0:511];
  reg [31:0] mem2 [0:511];
  reg [31:0] mem3 [0:511];
  
  reg [31:0] data0_q;
  reg [31:0] data1_q;
  reg [31:0] data2_q;
  reg [31:0] data3_q;

  reg  [1:0] adr_q;

  always @(posedge clk)
    data0_q <= #`dh mem0[i_adr[8:0]];

  always @(posedge clk)
    data1_q <= #`dh mem1[i_adr[8:0]];

  always @(posedge clk)
    data2_q <= #`dh mem2[i_adr[8:0]];

  always @(posedge clk)
    data3_q <= #`dh mem3[i_adr[8:0]];

  
  always @(posedge clk)
    adr_q <= #`dh i_adr[10:9];

  assign o_data = (adr_q == 2'b00) ? data0_q :
                  (adr_q == 2'b01) ? data1_q :
                  (adr_q == 2'b10) ? data2_q :
                  (adr_q == 2'b11) ? data3_q :
                                     32'bx;

  initial begin
    $readmemh("boot0.hex", mem0);
    $readmemh("boot1.hex", mem1);
    $readmemh("boot2.hex", mem2);
    $readmemh("boot3.hex", mem3);
  end

endmodule
