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
// Abstract      : Reset synchronizer without clock-stopping functionality
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rst_sync_simple.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rst_sync_simple # (

  parameter CLOCK_CYCLES = 8

) (

  input      clk,
  input      rst_async,
  input      deassert,
  output reg rst
);

  reg [(CLOCK_CYCLES-1):0] rst_sync;

  always @(posedge clk or posedge rst_async) begin
    if (rst_async) begin
      rst_sync <= (1 << CLOCK_CYCLES) - 1'b1;
      rst <= 1'b1;
    end
    else begin
      rst_sync[(CLOCK_CYCLES-1)]   <= ~deassert;
      rst_sync[(CLOCK_CYCLES-2):0] <= rst_sync[(CLOCK_CYCLES-1):1];
      rst <= | rst_sync;
    end
  end
  

endmodule
