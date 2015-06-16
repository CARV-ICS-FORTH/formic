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
// Abstract      : Crossbar interface FIFO pointer logic
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbi_fifo_ptr.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbi_fifo_ptr # (
  
  // Parameters
  parameter BASE_START = 10'd0,
  parameter PACKET_SIZE = 10'd144,
  parameter NEED_RD_WORDS = 1,
  parameter NEED_WR_WORDS = 1

) (
  
  // Write side
  input              clk_wr,
  input              rst_wr,
  input              i_wr_advance,
  output             o_wr_full,
  output       [9:0] o_wr_base,
  output       [2:0] o_wr_words,

  // Read side
  input              clk_rd,
  input              rst_rd,
  input              i_rd_advance,
  output             o_rd_empty,
  output       [9:0] o_rd_base,
  output       [2:0] o_rd_words
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire        wr_advance;
  wire        rd_advance;

  wire  [9:0] wr_base_d;
  reg   [9:0] wr_base_q;

  wire  [9:0] rd_base_d;
  reg   [9:0] rd_base_q;

  wire  [2:0] wr_ptr_bin_d;
  reg   [2:0] wr_ptr_bin_q;

  wire  [2:0] rd_ptr_bin_d;
  reg   [2:0] rd_ptr_bin_q;

  wire  [2:0] wr_ptr_gray_d;
  reg   [2:0] wr_ptr_gray_q;
  wire  [2:0] wr_ptr_sync0_d;
  reg   [2:0] wr_ptr_sync0_q;
  wire  [2:0] wr_ptr_sync1_d;
  reg   [2:0] wr_ptr_sync1_q;
  wire  [2:0] wr_ptr_sync1_bin;

  wire  [2:0] rd_ptr_gray_d;
  reg   [2:0] rd_ptr_gray_q;
  wire  [2:0] rd_ptr_sync0_d;
  reg   [2:0] rd_ptr_sync0_q;
  wire  [2:0] rd_ptr_sync1_d;
  reg   [2:0] rd_ptr_sync1_q;
  wire  [2:0] rd_ptr_sync1_bin;

  wire        wr_full_d;
  reg         wr_full_q;
  wire  [2:0] wr_words_d;
  reg   [2:0] wr_words_q;

  wire        rd_empty_d;
  reg         rd_empty_q;
  wire  [2:0] rd_words_d;
  reg   [2:0] rd_words_q;



  // ==========================================================================
  // Write side
  // ==========================================================================
  assign wr_advance = i_wr_advance & ~wr_full_q;

  assign wr_ptr_bin_d = (~wr_advance)            ? wr_ptr_bin_q :
                        (wr_ptr_bin_q == 3'b101) ? 3'b0 : 
                                                   wr_ptr_bin_q + 3'b1;

  binary_to_gray6 i0_binary_to_gray6 (
    .in  (wr_ptr_bin_d), 
    .out (wr_ptr_gray_d)
  );

  assign wr_base_d = BASE_START + (wr_ptr_bin_d * PACKET_SIZE);

  assign rd_ptr_sync0_d = rd_ptr_gray_q;
  assign rd_ptr_sync1_d = rd_ptr_sync0_q;

  assign wr_full_d = (wr_advance | wr_full_q) & 
                     (wr_ptr_gray_d == rd_ptr_sync1_q);

  assign o_wr_full  = wr_full_q;
  assign o_wr_base  = wr_base_q;

  // Write words conditional generation
  generate
    if (NEED_WR_WORDS == 1) begin
      gray6_to_binary i0_gray6_to_binary ( 
        .in  (rd_ptr_sync1_q), 
        .out (rd_ptr_sync1_bin)
      );

      assign wr_words_d = (wr_full_d) ? 3'b0 :
                          (wr_ptr_bin_d >= rd_ptr_sync1_bin) ? 
                                        rd_ptr_sync1_bin - wr_ptr_bin_d - 3'd2 :
                                        rd_ptr_sync1_bin - wr_ptr_bin_d;

      assign o_wr_words = wr_words_q;
    end
    else begin
      assign o_wr_words = 0;
    end
  endgenerate


  // ==========================================================================
  // Read side
  // ==========================================================================
  assign rd_advance = i_rd_advance & ~rd_empty_q;

  assign rd_ptr_bin_d = (~rd_advance)            ? rd_ptr_bin_q :
                        (rd_ptr_bin_q == 3'b101) ? 3'b0 : 
                                                   rd_ptr_bin_q + 3'b1;

  binary_to_gray6 i1_binary_to_gray6 (
    .in  (rd_ptr_bin_d), 
    .out (rd_ptr_gray_d)
  );

  assign rd_base_d = BASE_START + (rd_ptr_bin_d * PACKET_SIZE);

  assign wr_ptr_sync0_d = wr_ptr_gray_q;
  assign wr_ptr_sync1_d = wr_ptr_sync0_q;

  assign rd_empty_d = (rd_advance | rd_empty_q) & 
                      (rd_ptr_gray_d == wr_ptr_sync1_q);

  assign o_rd_empty = rd_empty_q;
  assign o_rd_base  = rd_base_q;

  // Read words conditional generation
  generate
    if (NEED_RD_WORDS == 1) begin
      gray6_to_binary i1_gray6_to_binary ( 
        .in  (wr_ptr_sync1_q), 
        .out (wr_ptr_sync1_bin)
      );

      assign rd_words_d = (rd_empty_d) ? 3'b0 :
                          (rd_ptr_bin_d >= wr_ptr_sync1_bin) ? 
                                    wr_ptr_sync1_bin - rd_ptr_bin_d - 3'd2 :
                                    wr_ptr_sync1_bin - rd_ptr_bin_d;
      
      assign o_rd_words = rd_words_q;
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
  
  always @(posedge clk_wr) begin
    wr_base_q        <= #`dh wr_base_d;
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
  
  always @(posedge clk_rd) begin
    rd_base_q        <= #`dh rd_base_d;
  end

  // Write words conditional generation
  generate
    if (NEED_WR_WORDS == 1) begin
      always @(posedge clk_wr) begin
        if (rst_wr) begin
          wr_words_q     <= #`dh 3'd6;
        end
        else begin
          wr_words_q     <= #`dh wr_words_d;
        end
      end
    end
  endgenerate

  // Read words conditional generation
  generate
    if (NEED_RD_WORDS == 1) begin
      always @(posedge clk_rd) begin
        if (rst_rd) begin
          rd_words_q     <= #`dh 0;
        end
        else begin
          rd_words_q     <= #`dh rd_words_d;
        end
      end
    end
  endgenerate


endmodule
