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
// Abstract      : Crossbar 22-to-1 pipelined multiplexor
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbar_mux.v,v $
// CVS revision  : $Revision: 1.2 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbar_mux (

  // Clock and reset
  input         clk,
  
  // Data inputs
  input  [15:0] i_data00,   // 000 00
  input  [15:0] i_data01,   // 000 01
  input  [15:0] i_data02,   // 000 10
  input  [15:0] i_data03,   // 000 11

  input  [15:0] i_data04,   // 001 00
  input  [15:0] i_data05,   // 001 01
  input  [15:0] i_data06,   // 001 10
  input  [15:0] i_data07,   // 001 11

  input  [15:0] i_data08,   // 010 00
  input  [15:0] i_data09,   // 010 01
  input  [15:0] i_data10,   // 010 10
  input  [15:0] i_data11,   // 010 11

  input  [15:0] i_data12,   // 011 00
  input  [15:0] i_data13,   // 011 01
  input  [15:0] i_data14,   // 011 10
  input  [15:0] i_data15,   // 011 11

  input  [15:0] i_data16,   // 100 00
  input  [15:0] i_data17,   // 100 01
  input  [15:0] i_data18,   // 100 10
  input  [15:0] i_data19,   // 100 11

  input  [15:0] i_data20,   // 101 00
  input  [15:0] i_data21,   // 101 01

  // Control input
  input   [4:0] i_sel,

  // Output
  output [15:0] o_data
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  reg  [15:0] mux0_0_d;
  reg  [15:0] mux1_0_d;
  reg  [15:0] mux2_0_d;
  reg  [15:0] mux3_0_d;
  reg  [15:0] mux4_0_d;
  reg  [15:0] mux5_0_d;
  wire  [2:0] sel0_d;

  reg  [15:0] mux0_1_d;
  reg  [15:0] mux1_1_d;
  wire        sel1_d;

  reg  [15:0] mux0_2_d;

  // ==========================================================================
  // Registers
  // ==========================================================================
  reg  [15:0] mux0_0_q;
  reg  [15:0] mux1_0_q;
  reg  [15:0] mux2_0_q;
  reg  [15:0] mux3_0_q;
  reg  [15:0] mux4_0_q;
  reg  [15:0] mux5_0_q;
  reg   [2:0] sel0_q;
  
  reg  [15:0] mux0_1_q;
  reg  [15:0] mux1_1_q;
  reg         sel1_q;

  reg  [15:0] mux0_2_q;

  // ==========================================================================
  // Clocked process
  // ==========================================================================
  always @(posedge clk) begin
    mux0_0_q <= #`dh mux0_0_d;
    mux1_0_q <= #`dh mux1_0_d;
    mux2_0_q <= #`dh mux2_0_d;
    mux3_0_q <= #`dh mux3_0_d;
    mux4_0_q <= #`dh mux4_0_d;
    mux5_0_q <= #`dh mux5_0_d;
    sel0_q   <= #`dh sel0_d;
    mux0_1_q <= #`dh mux0_1_d;
    mux1_1_q <= #`dh mux1_1_d;
    sel1_q   <= #`dh sel1_d;
    mux0_2_q <= #`dh mux0_2_d;
  end

  // ==========================================================================
  // First pipeline stage
  // ==========================================================================
  always @(*) begin
    case (i_sel[1:0])
      2'b00   : mux0_0_d = i_data00;
      2'b01   : mux0_0_d = i_data01;
      2'b10   : mux0_0_d = i_data02;
      default : mux0_0_d = i_data03;
    endcase
  end

  always @(*) begin
    case (i_sel[1:0])
      2'b00   : mux1_0_d = i_data04;
      2'b01   : mux1_0_d = i_data05;
      2'b10   : mux1_0_d = i_data06;
      default : mux1_0_d = i_data07;
    endcase
  end

  always @(*) begin
    case (i_sel[1:0])
      2'b00   : mux2_0_d = i_data08;
      2'b01   : mux2_0_d = i_data09;
      2'b10   : mux2_0_d = i_data10;
      default : mux2_0_d = i_data11;
    endcase
  end

  always @(*) begin
    case (i_sel[1:0])
      2'b00   : mux3_0_d = i_data12;
      2'b01   : mux3_0_d = i_data13;
      2'b10   : mux3_0_d = i_data14;
      default : mux3_0_d = i_data15;
    endcase
  end

  always @(*) begin
    case (i_sel[1:0])
      2'b00   : mux4_0_d = i_data16;
      2'b01   : mux4_0_d = i_data17;
      2'b10   : mux4_0_d = i_data18;
      default : mux4_0_d = i_data19;
    endcase
  end

  always @(*) begin
    case (i_sel[0])
      1'b0    : mux5_0_d = i_data20;
      default : mux5_0_d = i_data21;
    endcase
  end

  assign sel0_d = i_sel[4:2];

  // ==========================================================================
  // Second pipeline stage
  // ==========================================================================
  always @(*) begin
    case (sel0_q)
      3'b000  : mux0_1_d = mux0_0_q;
      3'b001  : mux0_1_d = mux1_0_q;
      default : mux0_1_d = mux2_0_q;
    endcase
  end

  always @(*) begin
    case (sel0_q)
      3'b011  : mux1_1_d = mux3_0_q;
      3'b100  : mux1_1_d = mux4_0_q;
      default : mux1_1_d = mux5_0_q;
    endcase
  end

  assign sel1_d = sel0_q[2] | (sel0_q[1] & sel0_q[0]); // 011, 100 or 101

  // ==========================================================================
  // Third pipeline stage
  // ==========================================================================
  always @(*) begin
    case (sel1_q)
      1'b0    : mux0_2_d = mux0_1_q;
      default : mux0_2_d = mux1_1_q;
    endcase
  end

  // ==========================================================================
  // Output
  // ==========================================================================
  assign o_data = mux0_2_q;

endmodule
