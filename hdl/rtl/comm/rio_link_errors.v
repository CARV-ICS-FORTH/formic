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
// Abstract      : GTP error module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rio_link_errors.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rio_link_errors(
  // CLK, RST
  input clk,
  input rst,

  // ROCKET IO UP and ERRORS
  input i_rx_up,
  input i_rx_error,

  // USER LINK IF
  output reg o_link_up,
  output reg o_link_error
);

reg [19:0] rx_error_cnt;
reg rx_up0;
always @(posedge clk) begin
  if ( rst ) begin
	rx_up0 <= #`dh 0;
	rx_error_cnt <= #`dh 0;
	o_link_error <= #`dh 0;
	o_link_up <= #`dh 0;
  end
  else begin
	rx_up0 <= #`dh i_rx_up;

	if ( ~rx_up0 & i_rx_up ) begin
	  rx_error_cnt <= #`dh 0;
	end
	else if ( i_rx_error ) begin
	  rx_error_cnt <= #`dh rx_error_cnt + 1'b1;
	end

	o_link_error <= #`dh (rx_error_cnt != 0);
	o_link_up <= #`dh i_rx_up;
  end
end

endmodule
