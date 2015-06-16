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
// Author        : Vassilis Papaefstathiou
// Abstract      : GTP receive alignment
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rio_link_rx_align.v,v $
// CVS revision  : $Revision: 1.2 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================


`timescale 1ns/1ps

module rio_link_rx_align ( 
  clk,
  rst,
  i_rio_rx_data,
  i_rio_rx_isk,

  o_rio_rx_data,
  o_rio_rx_isk
);

input clk;
input rst;

input [15:0] i_rio_rx_data;
input [1:0] i_rio_rx_isk;

output [15:0] o_rio_rx_data;
output [1:0] o_rio_rx_isk;



parameter RIO_COMMA_CHAR = 8'hbc;	// COMMA = K28.5

// detect comma misalignment
wire rio_aligned_comma = i_rio_rx_isk[0] & (i_rio_rx_data[7:0] == RIO_COMMA_CHAR);
wire rio_misaligned_comma = i_rio_rx_isk[1] & (i_rio_rx_data[15:8] == RIO_COMMA_CHAR);

reg [7:0] rio_data_pipe;
reg rio_isk_pipe;
reg rio_swap;
always @(posedge clk) begin
  if ( rst ) begin
    rio_data_pipe <= #`dh RIO_COMMA_CHAR;
    rio_isk_pipe <= #`dh 1;

    rio_swap <= #`dh 0;
  end
  else begin
    rio_data_pipe <= #`dh i_rio_rx_data[15:8];
    rio_isk_pipe <= #`dh i_rio_rx_isk[1];

    if ( rio_misaligned_comma ) begin
      rio_swap <= #`dh 1;
    end
    else if ( rio_aligned_comma ) begin
      rio_swap <= #`dh 0;
    end
  end
end

// swapping delayed data
wire [15:0] rio_rx_data_int = ( rio_swap ) ? {i_rio_rx_data[7:0],rio_data_pipe} : i_rio_rx_data;
wire [1:0]  rio_rx_isk_int  = ( rio_swap ) ? {i_rio_rx_isk[0],rio_isk_pipe}     : i_rio_rx_isk;

// Registered outputs
reg [15:0] o_rio_rx_data;
reg [1:0] o_rio_rx_isk;
always @(posedge clk) begin
  if ( rst ) begin
    o_rio_rx_data <= #`dh 0;
    o_rio_rx_isk <= #`dh 2'b11;
  end
  else begin
    o_rio_rx_data <= #`dh rio_rx_data_int;
    o_rio_rx_isk <= #`dh rio_rx_isk_int;
  end
end


endmodule
