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
// Abstract      : FIFO pointer module for asynchronous clocking (with gray
//                 counters)
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: fifo_ptr.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module fifo_ptr # (
  
  // Paremeters
  parameter N_log         = 8, // Pointer bits; #words will have one bit more
  parameter RD_PTR_UNBUF  = 1, // If 1, rd_ptr_d will be given (not rd_ptr_q)
  parameter NEED_WR_WORDS = 1, // If 1, o_wr_words logic will be present
  parameter NEED_RD_WORDS = 1  // If 1, o_rd_words logic will be present

) (
  
  // Write side
  input              clk_wr,
  input              rst_wr,
  input              i_wr_advance,
  output             o_wr_full,
  output [N_log-1:0] o_wr_ptr,
  output   [N_log:0] o_wr_words,

  // Read side
  input              clk_rd,
  input              rst_rd,
  input              i_rd_advance,
  output             o_rd_empty,
  output [N_log-1:0] o_rd_ptr_nxt,
  output   [N_log:0] o_rd_words
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire              wr_advance;
  wire              rd_advance;

  wire  [N_log-1:0] wr_ptr_bin_d;
  reg   [N_log-1:0] wr_ptr_bin_q;

  wire  [N_log-1:0] rd_ptr_bin_d;
  reg   [N_log-1:0] rd_ptr_bin_q;

  wire  [N_log-1:0] wr_ptr_gray_d;
  reg   [N_log-1:0] wr_ptr_gray_q;
  wire  [N_log-1:0] wr_ptr_sync0_d;
  reg   [N_log-1:0] wr_ptr_sync0_q;
  wire  [N_log-1:0] wr_ptr_sync1_d;
  reg   [N_log-1:0] wr_ptr_sync1_q;
  wire              wr_match;

  wire  [N_log-1:0] rd_ptr_gray_d;
  reg   [N_log-1:0] rd_ptr_gray_q;
  wire  [N_log-1:0] rd_ptr_sync0_d;
  reg   [N_log-1:0] rd_ptr_sync0_q;
  wire  [N_log-1:0] rd_ptr_sync1_d;
  reg   [N_log-1:0] rd_ptr_sync1_q;
  wire              rd_match;

  wire              rd_empty_d;
  reg               rd_empty_q;
  wire              wr_full_d;
  reg               wr_full_q;


  // ==========================================================================
  // Write side
  // ==========================================================================
  assign wr_advance = i_wr_advance & ~wr_full_q;

  assign wr_ptr_bin_d = (~wr_advance) ? wr_ptr_bin_q :
                                        wr_ptr_bin_q + 1'b1;

  binary_to_gray # (
    .N   (N_log)
  ) i0_binary_to_gray (
    .in  (wr_ptr_bin_d), 
    .out (wr_ptr_gray_d)
  );

  assign rd_ptr_sync0_d = rd_ptr_gray_q;
  assign rd_ptr_sync1_d = rd_ptr_sync0_q;

  assign wr_match = (wr_ptr_gray_d == rd_ptr_sync1_q);
  assign wr_full_d = (wr_advance | wr_full_q) & wr_match;
  
  assign o_wr_ptr  = wr_ptr_bin_q;
  assign o_wr_full = wr_full_q;


  generate
    if (NEED_WR_WORDS == 1) begin

  wire  [N_log:0]   wr_words_d;
  reg   [N_log:0]   wr_words_q;
  wire  [N_log-1:0] rd_ptr_sync1_bin;

  gray_to_binary # (
    .N   (N_log)
  ) i0_gray_to_binary ( 
    .in  (rd_ptr_sync1_q), 
    .out (rd_ptr_sync1_bin)
  );

  assign wr_words_d = { (wr_match & ~wr_full_d), 
                        (rd_ptr_sync1_bin - wr_ptr_bin_d) };
  assign o_wr_words = wr_words_q;

  always @(posedge clk_wr) 
    wr_words_q     <= #`dh wr_words_d;

    end
    else begin

  assign o_wr_words = 0;

    end
  endgenerate


  // ==========================================================================
  // Read side
  // ==========================================================================
  assign rd_advance = i_rd_advance & ~rd_empty_q;

  assign rd_ptr_bin_d = (~rd_advance) ? rd_ptr_bin_q :
                                        rd_ptr_bin_q + 1'b1;

  binary_to_gray # (
    .N   (N_log)
  ) i1_binary_to_gray (
    .in  (rd_ptr_bin_d), 
    .out (rd_ptr_gray_d)
  );

  assign wr_ptr_sync0_d = wr_ptr_gray_q;
  assign wr_ptr_sync1_d = wr_ptr_sync0_q;

  assign rd_match   = (rd_ptr_gray_d == wr_ptr_sync1_q);
  assign rd_empty_d = (rd_advance | rd_empty_q) & rd_match;
  
  assign o_rd_ptr_nxt = (RD_PTR_UNBUF == 1) ? rd_ptr_bin_d : rd_ptr_bin_q;
  assign o_rd_empty   = rd_empty_q;


  generate
    if (NEED_RD_WORDS == 1) begin

  wire  [N_log:0]   rd_words_d;
  reg   [N_log:0]   rd_words_q;
  wire  [N_log-1:0] wr_ptr_sync1_bin;

  gray_to_binary # (
    .N   (N_log)
  ) i1_gray_to_binary ( 
    .in  (wr_ptr_sync1_q), 
    .out (wr_ptr_sync1_bin)
  );


  assign rd_words_d = { (rd_match & ~rd_empty_d), 
                        (wr_ptr_sync1_bin - rd_ptr_bin_d) };
  assign o_rd_words = rd_words_q;


  always @(posedge clk_rd) 
    rd_words_q     <= #`dh rd_words_d;

    end
    else begin

  assign o_rd_words = 0;

    end
  endgenerate


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_wr) begin
    if (rst_wr) begin
      wr_ptr_gray_q  <= #`dh 0;
      wr_ptr_bin_q   <= #`dh 0;
      rd_ptr_sync0_q <= #`dh 0;
      rd_ptr_sync1_q <= #`dh 0;
      wr_full_q      <= #`dh 0;
    end
    else begin
      wr_ptr_gray_q  <= #`dh wr_ptr_gray_d;
      wr_ptr_bin_q   <= #`dh wr_ptr_bin_d;
      rd_ptr_sync0_q <= #`dh rd_ptr_sync0_d;
      rd_ptr_sync1_q <= #`dh rd_ptr_sync1_d;
      wr_full_q      <= #`dh wr_full_d;
    end
  end

  always @(posedge clk_rd) begin
    if (rst_rd) begin
      rd_ptr_gray_q  <= #`dh 0;
      rd_ptr_bin_q   <= #`dh 0;
      wr_ptr_sync0_q <= #`dh 0;
      wr_ptr_sync1_q <= #`dh 0;
      rd_empty_q     <= #`dh 1'b1;
    end
    else begin
      rd_ptr_gray_q  <= #`dh rd_ptr_gray_d;
      rd_ptr_bin_q   <= #`dh rd_ptr_bin_d;
      wr_ptr_sync0_q <= #`dh wr_ptr_sync0_d;
      wr_ptr_sync1_q <= #`dh wr_ptr_sync1_d;
      rd_empty_q     <= #`dh rd_empty_d;
    end
  end 

endmodule
