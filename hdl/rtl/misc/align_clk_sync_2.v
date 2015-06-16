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
// Abstract      : 2-word mesochronous FIFO
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: align_clk_sync_2.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// align_clk_sync
//
module align_clk_sync_2 #
(
  // fsm type parameter
  parameter N = 32
) (
  // Input side
  input           clk_in,
  input           rst_in,
  input   [N-1:0] i_data,
  input           i_valid,
  output          o_stall,
  // Output side
  input           clk_out,
  input           rst_out,
  output  [N-1:0] o_data,
  output          o_valid,
  input           i_stall
);

  // ==========================================================================
  // Input side logic (clk_in)
  // ==========================================================================
  reg [N-1:0] data0_q;
  reg [N-1:0] data1_q;
  reg   [1:0] head_q;

  wire latch_input = i_valid & ~o_stall;

  always @(posedge clk_in) begin
    if (rst_in) begin
      head_q <= #`dh 0;
    end
    else begin
      if (latch_input) begin
        head_q <= #`dh head_q + 2'b1;
      end
    end
  end

  always @(posedge clk_in) begin
    if (latch_input) begin
      data0_q <= #`dh (head_q[0]) ? i_data  : data0_q;
      data1_q <= #`dh (head_q[0]) ? data1_q : i_data;
    end
  end

  // ==========================================================================
  // Output side logic (clk_out)
  // ==========================================================================
  reg [1:0] tail_q;

  wire consume_output = o_valid & ~i_stall;

  always @(posedge clk_out) begin
    if (rst_out) begin
      tail_q <= #`dh 0;
    end
    else begin
      if (consume_output) begin
        tail_q <= #`dh tail_q + 2'b1;
      end
    end
  end

  // ==========================================================================
  // Pointer comparison
  // ==========================================================================
  wire empty = (head_q[0] ~^ tail_q[0]) & (head_q[1] ~^ tail_q[1]);
  wire full  = (head_q[0] ~^ tail_q[0]) & (head_q[1]  ^ tail_q[1]);
  
  // ==========================================================================
  // Module outputs (1 LUT delay from registers)
  // ==========================================================================
  assign o_data = (tail_q[0]) ? data0_q : data1_q;
  assign o_stall = full;
  assign o_valid = ~empty;

endmodule
