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
// Abstract      : 32-bit Crossbar Interface module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbi32.v,v $
// CVS revision  : $Revision: 1.9 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbi32 # (

  parameter NEED_USER_TO_XBAR_VC0 = 1,
  parameter NEED_USER_TO_XBAR_VC1 = 1,
  parameter NEED_USER_TO_XBAR_VC2 = 1,
  parameter NEED_XBAR_TO_USER_VC0 = 1,
  parameter NEED_XBAR_TO_USER_VC1 = 1,
  parameter NEED_XBAR_TO_USER_VC2 = 1

) (
  
  // User port, 32 bits (unbuffered)
  input              clk_usr,
  input              rst_usr,
  input        [2:0] i_usr_nout_enq,
  input        [4:0] i_usr_nout_offset,
  input              i_usr_nout_eop,
  input       [31:0] i_usr_nout_data,
  output       [2:0] o_usr_nout_full,
  input        [2:0] i_usr_nin_deq,
  input        [4:0] i_usr_nin_offset,
  input              i_usr_nin_eop,
  output      [31:0] o_usr_nin_data,
  output       [2:0] o_usr_nin_empty,

  // Crossbar port, 16 bits (buffered, dst board id/node id eager pushing)
  input              clk_xbar,
  input              rst_xbar,
  input        [2:0] i_xbar_out_enq,
  input        [5:0] i_xbar_out_offset,
  input              i_xbar_out_eop,
  input       [15:0] i_xbar_out_data,
  output       [2:0] o_xbar_out_full,
  output       [2:0] o_xbar_out_packets_vc0,
  output       [2:0] o_xbar_out_packets_vc1,
  output       [2:0] o_xbar_out_packets_vc2,
  input        [2:0] i_xbar_in_deq,
  input        [5:0] i_xbar_in_offset,
  input              i_xbar_in_eop,
  output      [15:0] o_xbar_in_data,
  output       [2:0] o_xbar_in_empty
);

  // We choose packet sizes that minimize the multiplication effort.
  // x 'd12 means  x 'b1100,     i.e. two additions
  // x 'd64 means  x 'b1000000,  i.e. one addition
  // x 'd144 means x 'b10010000, i.e. two additions

  localparam VC0_BASE_START  = 10'd0;    // 6 packets x 12 words = 72 words
  localparam VC0_PACKET_SIZE = 10'd12;
  localparam VC1_BASE_START  = 10'd128;  // 6 packets x 64 words = 384 words
  localparam VC1_PACKET_SIZE = 10'd64;
  localparam VC2_BASE_START  = 10'd512;  // 6 packets x 64 words = 384 words
  localparam VC2_PACKET_SIZE = 10'd64;


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire        usr_wr_en;
  wire  [8:0] usr_wr_adr;
  wire  [8:0] usr_rd_adr;

  wire  [9:0] usr_wr_base0;
  wire  [9:0] usr_wr_base1;
  wire  [9:0] usr_wr_base2;

  wire  [9:0] usr_rd_base0;
  wire  [9:0] usr_rd_base1;
  wire  [9:0] usr_rd_base2;

  wire        xbar_wr_en;
  wire  [9:0] xbar_wr_adr;
  wire  [9:0] xbar_rd_base;
  wire  [5:0] xbar_rd_offset;
  wire  [9:0] xbar_rd_adr;
  wire [15:0] mem0_rd_data;

  reg   [2:0] cur_vc_d;
  reg   [2:0] cur_vc_q;
  wire  [2:0] cur_vc_del_d;
  reg   [2:0] cur_vc_del_q;
  wire        eager_valid_d;
  reg         eager_valid_q;

  wire  [9:0] xbar_wr_base0;
  wire  [9:0] xbar_wr_base1;
  wire  [9:0] xbar_wr_base2;

  wire  [9:0] xbar_rd_base0;
  wire  [9:0] xbar_rd_base1;
  wire  [9:0] xbar_rd_base2;
  wire  [9:0] xbar_rd_deq_base;
  wire  [9:0] xbar_rd_eager_base;

  wire  [2:0] xbar_out_enq_d;
  reg   [2:0] xbar_out_enq_q;
  wire  [5:0] xbar_out_offset_d;
  reg   [5:0] xbar_out_offset_q;
  wire        xbar_out_eop_d;
  reg         xbar_out_eop_q;
  wire [15:0] xbar_out_data_d;
  reg  [15:0] xbar_out_data_q;
  wire  [2:0] xbar_in_deq_d;
  reg   [2:0] xbar_in_deq_q;
  wire  [5:0] xbar_in_offset_d;
  reg   [5:0] xbar_in_offset_q;
  wire        xbar_in_eop_d;
  reg         xbar_in_eop_q;
  wire [15:0] xbar_in_data_d;
  reg  [15:0] xbar_in_data_q;
  
  
  // ==========================================================================
  // Pointer synchronization modules
  // ==========================================================================
  
  // User port to crossbar, VC 0 
  generate 
    if (NEED_USER_TO_XBAR_VC0) begin
      xbi_fifo_ptr # (

        .BASE_START     ( VC0_BASE_START ),
        .PACKET_SIZE    ( VC0_PACKET_SIZE ),
        .NEED_RD_WORDS  ( 0 ),
        .NEED_WR_WORDS  ( 0 )

      ) i0_xbi_fifo_ptr (

        .clk_wr         ( clk_usr ),
        .rst_wr         ( rst_usr ),
        .i_wr_advance   ( i_usr_nout_enq[0] & i_usr_nout_eop ),
        .o_wr_full      ( o_usr_nout_full[0] ),
        .o_wr_base      ( usr_wr_base0 ),
        .o_wr_words     ( ),

        .clk_rd         ( clk_xbar ),
        .rst_rd         ( rst_xbar ),
        .i_rd_advance   ( xbar_in_deq_q[0] & xbar_in_eop_q ),
        .o_rd_empty     ( o_xbar_in_empty[0] ),
        .o_rd_base      ( xbar_rd_base0 ),
        .o_rd_words     ( )
      );
    end
    else begin
      assign o_usr_nout_full[0] = 0;
      assign usr_wr_base0 = 0;
      assign o_xbar_in_empty[0] = 1;
      assign xbar_rd_base0 = 0;
    end
  endgenerate

  // User port to crossbar, VC 1 
  generate 
    if (NEED_USER_TO_XBAR_VC1) begin
      xbi_fifo_ptr # (

        .BASE_START     ( VC1_BASE_START ),
        .PACKET_SIZE    ( VC1_PACKET_SIZE ),
        .NEED_RD_WORDS  ( 0 ),
        .NEED_WR_WORDS  ( 0 )

      ) i1_xbi_fifo_ptr (

        .clk_wr         ( clk_usr ),
        .rst_wr         ( rst_usr ),
        .i_wr_advance   ( i_usr_nout_enq[1] & i_usr_nout_eop ),
        .o_wr_full      ( o_usr_nout_full[1] ),
        .o_wr_base      ( usr_wr_base1 ),
        .o_wr_words     ( ),

        .clk_rd         ( clk_xbar ),
        .rst_rd         ( rst_xbar ),
        .i_rd_advance   ( xbar_in_deq_q[1] & xbar_in_eop_q ),
        .o_rd_empty     ( o_xbar_in_empty[1] ),
        .o_rd_base      ( xbar_rd_base1 ),
        .o_rd_words     ( )
      );
    end
    else begin
      assign o_usr_nout_full[1] = 0;
      assign usr_wr_base1 = 0;
      assign o_xbar_in_empty[1] = 1;
      assign xbar_rd_base1 = 0;
    end
  endgenerate

  // User port to crossbar, VC 2 
  generate 
    if (NEED_USER_TO_XBAR_VC2) begin
      xbi_fifo_ptr # (

        .BASE_START     ( VC2_BASE_START ),
        .PACKET_SIZE    ( VC2_PACKET_SIZE ),
        .NEED_RD_WORDS  ( 0 ),
        .NEED_WR_WORDS  ( 0 )

      ) i2_xbi_fifo_ptr (

        .clk_wr         ( clk_usr ),
        .rst_wr         ( rst_usr ),
        .i_wr_advance   ( i_usr_nout_enq[2] & i_usr_nout_eop ),
        .o_wr_full      ( o_usr_nout_full[2] ),
        .o_wr_base      ( usr_wr_base2 ),
        .o_wr_words     ( ),

        .clk_rd         ( clk_xbar ),
        .rst_rd         ( rst_xbar ),
        .i_rd_advance   ( xbar_in_deq_q[2] & xbar_in_eop_q ),
        .o_rd_empty     ( o_xbar_in_empty[2] ),
        .o_rd_base      ( xbar_rd_base2 ),
        .o_rd_words     ( )
      );
    end
    else begin
      assign o_usr_nout_full[2] = 0;
      assign usr_wr_base2 = 0;
      assign o_xbar_in_empty[2] = 1;
      assign xbar_rd_base2 = 0;
    end
  endgenerate

  // Crossbar to user port, VC 0 
  generate 
    if (NEED_XBAR_TO_USER_VC0) begin
      xbi_fifo_ptr # (

        .BASE_START     ( VC0_BASE_START ),
        .PACKET_SIZE    ( VC0_PACKET_SIZE ),
        .NEED_RD_WORDS  ( 0 ),
        .NEED_WR_WORDS  ( 1 )

      ) i3_xbi_fifo_ptr (

        .clk_wr         ( clk_xbar ),
        .rst_wr         ( rst_xbar ),
        .i_wr_advance   ( xbar_out_enq_q[0] & xbar_out_eop_q ),
        .o_wr_full      ( o_xbar_out_full[0] ),
        .o_wr_base      ( xbar_wr_base0 ),
        .o_wr_words     ( o_xbar_out_packets_vc0 ),

        .clk_rd         ( clk_usr ),
        .rst_rd         ( rst_usr ),
        .i_rd_advance   ( i_usr_nin_deq[0] & i_usr_nin_eop ),
        .o_rd_empty     ( o_usr_nin_empty[0] ),
        .o_rd_base      ( usr_rd_base0 ),
        .o_rd_words     ( )
      );
    end
    else begin
      assign o_xbar_out_full[0] = 0;
      assign xbar_wr_base0 = 0;
      assign o_xbar_out_packets_vc0 = 0;
      assign o_usr_nin_empty[0] = 1;
      assign usr_rd_base0 = 0;
    end
  endgenerate

  // Crossbar to user port, VC 1 
  generate 
    if (NEED_XBAR_TO_USER_VC1) begin
      xbi_fifo_ptr # (

        .BASE_START     ( VC1_BASE_START ),
        .PACKET_SIZE    ( VC1_PACKET_SIZE ),
        .NEED_RD_WORDS  ( 0 ),
        .NEED_WR_WORDS  ( 1 )

      ) i4_xbi_fifo_ptr (

        .clk_wr         ( clk_xbar ),
        .rst_wr         ( rst_xbar ),
        .i_wr_advance   ( xbar_out_enq_q[1] & xbar_out_eop_q ),
        .o_wr_full      ( o_xbar_out_full[1] ),
        .o_wr_base      ( xbar_wr_base1 ),
        .o_wr_words     ( o_xbar_out_packets_vc1 ),

        .clk_rd         ( clk_usr ),
        .rst_rd         ( rst_usr ),
        .i_rd_advance   ( i_usr_nin_deq[1] & i_usr_nin_eop ),
        .o_rd_empty     ( o_usr_nin_empty[1] ),
        .o_rd_base      ( usr_rd_base1 ),
        .o_rd_words     ( )
      );
    end
    else begin
      assign o_xbar_out_full[1] = 0;
      assign xbar_wr_base1 = 0;
      assign o_xbar_out_packets_vc1 = 0;
      assign o_usr_nin_empty[1] = 1;
      assign usr_rd_base1 = 0;
    end
  endgenerate

  // Crossbar to user port, VC 2 
  generate 
    if (NEED_XBAR_TO_USER_VC2) begin
      xbi_fifo_ptr # (

        .BASE_START     ( VC2_BASE_START ),
        .PACKET_SIZE    ( VC2_PACKET_SIZE ),
        .NEED_RD_WORDS  ( 0 ),
        .NEED_WR_WORDS  ( 1 )

      ) i5_xbi_fifo_ptr (

        .clk_wr         ( clk_xbar ),
        .rst_wr         ( rst_xbar ),
        .i_wr_advance   ( xbar_out_enq_q[2] & xbar_out_eop_q ),
        .o_wr_full      ( o_xbar_out_full[2] ),
        .o_wr_base      ( xbar_wr_base2 ),
        .o_wr_words     ( o_xbar_out_packets_vc2 ),

        .clk_rd         ( clk_usr ),
        .rst_rd         ( rst_usr ),
        .i_rd_advance   ( i_usr_nin_deq[2] & i_usr_nin_eop ),
        .o_rd_empty     ( o_usr_nin_empty[2] ),
        .o_rd_base      ( usr_rd_base2 ),
        .o_rd_words     ( )
      );
    end
    else begin
      assign o_xbar_out_full[2] = 0;
      assign xbar_wr_base2 = 0;
      assign o_xbar_out_packets_vc2 = 0;
      assign o_usr_nin_empty[2] = 1;
      assign usr_rd_base2 = 0;
    end
  endgenerate


  // ==========================================================================
  // User port memory addresses and write enable (unbuffered)
  // ==========================================================================
  assign usr_wr_adr = i_usr_nout_offset + 
                        ((i_usr_nout_enq[0]) ? usr_wr_base0[9:1] :
                         (i_usr_nout_enq[1]) ? usr_wr_base1[9:1] :
                                               usr_wr_base2[9:1]);
  assign usr_wr_en = | i_usr_nout_enq;


  assign usr_rd_adr = i_usr_nin_offset + 
                         ((i_usr_nin_deq[0]) ? usr_rd_base0[9:1] :
                          (i_usr_nin_deq[1]) ? usr_rd_base1[9:1] :
                                               usr_rd_base2[9:1]);

  // ==========================================================================
  // Crossbar eager pushing of packet destination word
  // ==========================================================================
  always @(*) begin

    cur_vc_d = cur_vc_q;

    if (cur_vc_q == 3'b001) begin
      if (~o_xbar_in_empty[1])
        cur_vc_d = 3'b010;
      else if (~o_xbar_in_empty[2])
        cur_vc_d = 3'b100;
    end

    else if (cur_vc_q == 3'b010) begin
      if (~o_xbar_in_empty[2])
        cur_vc_d = 3'b100;
      else if (~o_xbar_in_empty[0])
        cur_vc_d = 3'b001;
    end

    else if (cur_vc_q == 3'b100) begin
      if (~o_xbar_in_empty[0])
        cur_vc_d = 3'b001;
      else if (~o_xbar_in_empty[1])
        cur_vc_d = 3'b010;
    end
  end

  assign cur_vc_del_d = cur_vc_q;

  assign eager_valid_d = ( ~| xbar_in_deq_q); // & ( ~& o_xbar_in_empty);


  // ==========================================================================
  // Crossbar memory addresses and write enable (buffered)
  // ==========================================================================
  assign xbar_wr_adr = xbar_out_offset_q + 
                                    ((xbar_out_enq_q[0]) ? xbar_wr_base0 :
                                     (xbar_out_enq_q[1]) ? xbar_wr_base1 :
                                                           xbar_wr_base2);
  assign xbar_wr_en = | xbar_out_enq_q;

  assign xbar_rd_offset = (eager_valid_d) ? 6'd1 : xbar_in_offset_q;

  assign xbar_rd_deq_base = 
    ({10{xbar_in_deq_q[0]}} & xbar_rd_base0) |
    ({10{xbar_in_deq_q[1]}} & xbar_rd_base1) |
    ({10{xbar_in_deq_q[2]}} & xbar_rd_base2);

  assign xbar_rd_eager_base = 
    ({10{cur_vc_q[0]}} & xbar_rd_base0) |
    ({10{cur_vc_q[1]}} & xbar_rd_base1) |
    ({10{cur_vc_q[2]}} & xbar_rd_base2);

  assign xbar_rd_base = (eager_valid_d) ? xbar_rd_eager_base : xbar_rd_deq_base;

  assign xbar_rd_adr = xbar_rd_offset + xbar_rd_base;

  assign xbar_in_data_d = (eager_valid_q) ? {1'b0, 
                                             cur_vc_del_q & ~o_xbar_in_empty, 
                                             mem0_rd_data[11:0]} :
                                            mem0_rd_data;

  // ==========================================================================
  // Two-ported BRAMs, assymetric: port0 is 1024 x 16, port1 is 512 x 36 
  //                               (Single BRAM block, 2 KB)
  // ==========================================================================
  
  // From user port to crossbar
  xil_mem_dp_1024x16_512x32 i0_xil_mem_dp_1024x16_512x32 (

    // Write port
    .clk1           ( clk_usr ),
    .i_en1          ( 1'b1 ),
    .i_wen1         ( {4{usr_wr_en}} ),
    .i_adr1         ( usr_wr_adr ),
    .i_wdata1       ( i_usr_nout_data ),
    .o_rdata1       ( ),

    // Read port
    .clk0           ( clk_xbar ),
    .i_en0          ( 1'b1 ),
    .i_wen0         ( 2'b0 ),
    .i_adr0         ( xbar_rd_adr ),
    .i_wdata0       ( 16'b0 ),
    .o_rdata0       ( mem0_rd_data )
  );

  // From crossbar to user port
  xil_mem_dp_1024x16_512x32 i1_xil_mem_dp_1024x16_512x32 (

    // Write port
    .clk0           ( clk_xbar ),
    .i_en0          ( 1'b1 ),
    .i_wen0         ( {2{xbar_wr_en}} ),
    .i_adr0         ( xbar_wr_adr ),
    .i_wdata0       ( xbar_out_data_q ),
    .o_rdata0       ( ),

    // Read port
    .clk1           ( clk_usr ),
    .i_en1          ( 1'b1 ),
    .i_wen1         ( 4'b0 ),
    .i_adr1         ( usr_rd_adr ),
    .i_wdata1       ( 32'b0 ),
    .o_rdata1       ( o_usr_nin_data )
  );

  
  // ==========================================================================
  // Crossbar registers
  // ==========================================================================
  assign xbar_out_enq_d         = i_xbar_out_enq;
  assign xbar_out_offset_d      = i_xbar_out_offset;
  assign xbar_out_eop_d         = i_xbar_out_eop;
  assign xbar_out_data_d        = i_xbar_out_data;
  assign xbar_in_deq_d          = i_xbar_in_deq;
  assign xbar_in_offset_d       = i_xbar_in_offset;
  assign xbar_in_eop_d          = i_xbar_in_eop;

  always @(posedge clk_xbar) begin
    if (rst_xbar) begin
      xbar_out_enq_q        <= #`dh 0;
      xbar_out_eop_q        <= #`dh 0;
      xbar_in_deq_q         <= #`dh 0;
      xbar_in_eop_q         <= #`dh 0;
      cur_vc_q              <= #`dh 3'b001;
    end
    else begin
      xbar_out_enq_q        <= #`dh xbar_out_enq_d;
      xbar_out_eop_q        <= #`dh xbar_out_eop_d;
      xbar_in_deq_q         <= #`dh xbar_in_deq_d;
      xbar_in_eop_q         <= #`dh xbar_in_eop_d;
      cur_vc_q              <= #`dh cur_vc_d;
    end
  end
  
  always @(posedge clk_xbar) begin
    xbar_out_offset_q       <= #`dh xbar_out_offset_d;
    xbar_out_data_q         <= #`dh xbar_out_data_d;
    xbar_in_offset_q        <= #`dh xbar_in_offset_d;
    xbar_in_data_q          <= #`dh xbar_in_data_d;
    cur_vc_del_q            <= #`dh cur_vc_del_d;
    eager_valid_q           <= #`dh eager_valid_d;
  end
  
  assign o_xbar_in_data = xbar_in_data_q;

endmodule
