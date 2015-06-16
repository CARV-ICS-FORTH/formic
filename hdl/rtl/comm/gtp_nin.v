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
// Abstract      : GTP network interface in module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: gtp_nin.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module gtp_nin (
  
  // Clock and reset
  input         clk_gtp,
  input         rst_gtp,

  // XBI input port
  output  [2:0] o_xbi_nin_deq,
  output  [5:0] o_xbi_nin_offset,
  output        o_xbi_nin_eop,
  input  [15:0] i_xbi_nin_data,
  input   [2:0] i_xbi_nin_empty,

  // GTP back end output port
  output        o_gtp_out_valid,
  output        o_gtp_out_sop,
  output        o_gtp_out_eop,
  output [15:0] o_gtp_out_data,
  output  [2:0] o_gtp_out_vc_enq,
  input   [2:0] i_gtp_out_xoff
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  reg   [5:0] deq_cnt_q;
  wire  [5:0] deq_cnt_d;
  reg   [5:0] size_q;
  wire  [5:0] size_d;
  reg         has_ack_q;
  wire        has_ack_d;

  wire        vc0_eligible;
  wire        vc1_eligible;
  wire        vc2_eligible;
  wire  [3:0] priority;

  wire        first_word;
  wire        dont_care;

  reg   [2:0] active_vc_q;
  wire  [2:0] active_vc_d;
 
  reg         valid_q;
  wire        valid_d;
  reg  [15:0] data_q;
  wire [15:0] data_d;
  reg         sop_q;
  wire        sop_d;
  reg         eop_q;
  wire        eop_d;
  
  reg  [15:0] crc_q;
  wire [15:0] crc_d;
  wire [15:0] new_crc;
  reg         crc_en_q;
  wire        crc_en_d;
 
  
  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle       = 4'b0001,
             Copy       = 4'b0010,
             Flush      = 4'b0100,
             CRC        = 4'b1000;

  reg  [3:0] state_d;
  reg  [3:0] state_q;

  // synthesis translate_off
  reg [256:0] StateString;
  always @(state_q) begin
    case (state_q)
      Idle       : StateString = "Idle";
      Copy       : StateString = "Copy";
      Flush      : StateString = "Flush";
      CRC        : StateString = "CRC";
      default    : StateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (vc0_eligible | vc1_eligible | vc2_eligible)
            state_d = Copy;
          else 
            state_d = Idle;
        end

      Copy: begin
          if (deq_cnt_q == size_q)
            state_d = Flush;
          else
            state_d = Copy;
        end

      Flush: begin
          state_d = CRC;
        end

      CRC: begin
          state_d = Idle;
        end

      default: begin
          state_d = Idle;
        end
    endcase
  end

  
  // ==========================================================================
  // Enqueue-dequeue logic
  // ==========================================================================
  assign vc0_eligible = ~i_xbi_nin_empty[0] & ~i_gtp_out_xoff[0];
  assign vc1_eligible = ~i_xbi_nin_empty[1] & ~i_gtp_out_xoff[1];
  assign vc2_eligible = ~i_xbi_nin_empty[2] & ~i_gtp_out_xoff[2];

  RR_prior_enf_combout # (
    .N_log  ( 2 )
  ) i0_RR_prior_enf_combout (
    .In     ( {1'b0, vc2_eligible, vc1_eligible, vc0_eligible} ),
    .Out    ( priority ),
    .ld_en  ( (state_q == Idle) ),
    .Clk    ( clk_gtp ), 
    .Rst    ( rst_gtp )
  );

  assign active_vc_d = (state_q != Idle) ? active_vc_q : priority[2:0];


  assign deq_cnt_d = (state_q == Idle) ? 6'b0 :
                                         deq_cnt_q + 1'b1;

  assign first_word = (deq_cnt_q == 6'd1);
  
  assign dont_care  = ~has_ack_q & (deq_cnt_q >= 6'd5) & (deq_cnt_q <= 6'd7);

  assign size_d = (state_q == Idle)     ? 6'b111111 :
                  ((state_q == Copy) &
                   first_word)          ? i_xbi_nin_data[5:0] + 6'd6:
                                          size_q;

  assign has_ack_d = ((state_q == Copy) &
                      first_word)         ? i_xbi_nin_data[9] :
                                            has_ack_q;

  assign valid_d = (state_q == Idle) ? 1'b0 :
                   ((state_q == Copy) &
                    first_word)      ? 1'b1 :
                                       valid_q;

  assign data_d = (state_q == CRC) ? crc_q : 
                  (dont_care)      ? 16'hFFFF :
                                     i_xbi_nin_data;

  assign sop_d = (state_q == Copy) & first_word;
  assign eop_d = (state_q == CRC);

  crc16 i0_crc16 (
    .i_data     (data_d),
    .i_crc      (crc_q),
    .o_crc      (new_crc)
  );

  assign crc_en_d = (state_q == Copy);

  assign crc_d = (crc_en_q) ? new_crc : 16'b0;


  // ==========================================================================
  // Output signals
  // ==========================================================================
  assign o_xbi_nin_deq = (state_q == Copy) ? active_vc_q : 3'b0;

  assign o_xbi_nin_offset = deq_cnt_q;

  assign o_xbi_nin_eop = (state_q == Copy) & (state_d == Flush);

  
  assign o_gtp_out_valid = valid_q;

  assign o_gtp_out_vc_enq = {3{sop_q}} & active_vc_q;
  
  assign o_gtp_out_data = data_q;

  assign o_gtp_out_sop = sop_q;

  assign o_gtp_out_eop = eop_q;


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_gtp) begin
    if (rst_gtp) begin
      state_q       <= #`dh Idle;
      valid_q       <= #`dh 0;
      sop_q         <= #`dh 0;
      eop_q         <= #`dh 0;
    end
    else begin
      state_q       <= #`dh state_d;
      valid_q       <= #`dh valid_d;
      sop_q         <= #`dh sop_d;
      eop_q         <= #`dh eop_d;
    end
  end

  always @(posedge clk_gtp) begin
    data_q          <= #`dh data_d;
    crc_q           <= #`dh crc_d;
    crc_en_q        <= #`dh crc_en_d;
    deq_cnt_q       <= #`dh deq_cnt_d;
    size_q          <= #`dh size_d;
    has_ack_q       <= #`dh has_ack_d;
    active_vc_q     <= #`dh active_vc_d;
  end

endmodule
