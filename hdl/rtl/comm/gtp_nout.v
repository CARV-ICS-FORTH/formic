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
// Abstract      : GTP Network interface output
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: gtp_nout.v,v $
// CVS revision  : $Revision: 1.4 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module gtp_nout (
  
  // Clock and reset
  input         clk_gtp,
  input         rst_gtp,
  input         clk_xbar,
  input         rst_xbar,

  // GTP back end input port (clk_gtp)
  input         i_gtp_in_valid,
  input         i_gtp_in_sop,
  input         i_gtp_in_eop,
  input  [15:0] i_gtp_in_data,
  output  [2:0] o_gtp_in_vc_deq,

  // XBI output port (clk_gtp)
  output  [2:0] o_xbi_nout_enq,
  output  [5:0] o_xbi_nout_offset,
  output        o_xbi_nout_eop,
  output [15:0] o_xbi_nout_data,
  input   [2:0] i_xbi_nout_full,
  
  // Respective crossbar-side XBI port monitoring (clk_xbar)
  input   [2:0] i_xbar_in_deq,
  input         i_xbar_in_eop,

  // Monitoring interface (clk_gtp)
  output        o_error_crc,
  output        o_error_credit
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  reg   [5:0] offset_q;
  wire  [5:0] offset_d;

  reg  [15:0] data_q;
  wire [15:0] data_d;
  reg  [15:0] crc_q;
  wire [15:0] crc_d;
  wire [15:0] old_crc;
  wire [15:0] new_crc;

  reg   [2:0] enq_q;
  wire  [2:0] enq_d;
  wire  [2:0] vc_dec;
  wire        vc_not_full;

  reg         eop_q;
  wire        eop_d;
  reg         crc_error_q;
  wire        crc_error_d;
  wire        crc_ok;

  wire  [2:0] xbar_credit;

  reg         credit_error_q;
  wire        credit_error_d;

  reg         vc_deq_defer_q;
  wire        vc_deq_defer_d;
  reg   [2:0] vc_deq_defer_val_q;
  wire  [2:0] vc_deq_defer_val_d;
  reg   [2:0] vc_deq_q;
  wire  [2:0] vc_deq_d;


  // ==========================================================================
  // Enqueue logic
  // ==========================================================================
  assign offset_d = (i_gtp_in_valid & i_gtp_in_sop) ? 6'd0 :
                    (i_gtp_in_valid)                ? offset_q + 1'b1 :
                                                      offset_q;

  assign data_d = (i_gtp_in_valid) ? i_gtp_in_data : data_q;

  crc16 i0_crc16 (
    .i_data     ( i_gtp_in_data ),
    .i_crc      ( old_crc ),
    .o_crc      ( new_crc )
  );

  assign old_crc = (i_gtp_in_valid & i_gtp_in_sop) ? 16'b0 : crc_q;
  assign crc_d   = (i_gtp_in_valid) ? new_crc : crc_q;

  assign vc_dec = (i_gtp_in_data[7:6] == 2'b00) ? 3'b001 :
                  (i_gtp_in_data[7:6] == 2'b01) ? 3'b010 :
                  (i_gtp_in_data[7:6] == 2'b10) ? 3'b100 :
                                                  3'b000;

  assign vc_not_full = | (vc_dec & ~i_xbi_nout_full);

  assign enq_d = (i_gtp_in_valid & i_gtp_in_sop &  vc_not_full) ? vc_dec :
                 (i_gtp_in_valid & i_gtp_in_sop & ~vc_not_full) ? 3'b0 :
                 (eop_q | crc_error_q)                          ? 3'b0 :
                                                                  enq_q;

  assign crc_ok = (crc_q == i_gtp_in_data);

  assign eop_d = i_gtp_in_valid & i_gtp_in_eop & crc_ok;

  assign crc_error_d = i_gtp_in_valid & i_gtp_in_eop & ~crc_ok;
  
  assign credit_error_d = i_gtp_in_valid & i_gtp_in_sop & ~vc_not_full;


  // ==========================================================================
  // Credit logic
  // ==========================================================================
  pulse_sync i0_pulse_sync (
    .clk_in     ( clk_xbar ),
    .rst_in     ( rst_xbar ),
    .i_pulse    ( i_xbar_in_deq[0] & i_xbar_in_eop ),
    .clk_out    ( clk_gtp ),
    .rst_out    ( rst_gtp ),
    .o_pulse    ( xbar_credit[0] )
  );

  pulse_sync i1_pulse_sync (
    .clk_in     ( clk_xbar ),
    .rst_in     ( rst_xbar ),
    .i_pulse    ( i_xbar_in_deq[1] & i_xbar_in_eop ),
    .clk_out    ( clk_gtp ),
    .rst_out    ( rst_gtp ),
    .o_pulse    ( xbar_credit[1] )
  );

  pulse_sync i2_pulse_sync (
    .clk_in     ( clk_xbar ),
    .rst_in     ( rst_xbar ),
    .i_pulse    ( i_xbar_in_deq[2] & i_xbar_in_eop ),
    .clk_out    ( clk_gtp ),
    .rst_out    ( rst_gtp ),
    .o_pulse    ( xbar_credit[2] )
  );

  assign vc_deq_defer_d = crc_error_q;

  assign vc_deq_defer_val_d = xbar_credit;


  assign vc_deq_d = (crc_error_q)    ? enq_q :
                    (vc_deq_defer_q) ? vc_deq_defer_val_q : 
                                       xbar_credit;


  // ==========================================================================
  // Output signals
  // ==========================================================================
  assign o_xbi_nout_enq = enq_q;
  
  assign o_xbi_nout_eop = eop_q;

  assign o_xbi_nout_offset = offset_q;

  assign o_xbi_nout_data = data_q;


  assign o_gtp_in_vc_deq = vc_deq_q;

  
  assign o_error_crc = crc_error_q;
  
  assign o_error_credit = credit_error_q;


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_gtp) begin
    if (rst_gtp) begin
      enq_q              <= #`dh 0;
      eop_q              <= #`dh 0;
      crc_error_q        <= #`dh 0;
      credit_error_q     <= #`dh 0;
      vc_deq_defer_q     <= #`dh 0;
      vc_deq_q           <= #`dh 0;
    end
    else begin
      enq_q              <= #`dh enq_d;
      eop_q              <= #`dh eop_d;
      crc_error_q        <= #`dh crc_error_d;
      credit_error_q     <= #`dh credit_error_d;
      vc_deq_defer_q     <= #`dh vc_deq_defer_d;
      vc_deq_q           <= #`dh vc_deq_d;
    end
  end
  
  always @(posedge clk_gtp) begin
    offset_q             <= #`dh offset_d;
    data_q               <= #`dh data_d;
    crc_q                <= #`dh crc_d;
    vc_deq_defer_val_q   <= #`dh vc_deq_defer_val_d;
  end


endmodule
