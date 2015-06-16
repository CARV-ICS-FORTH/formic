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
// Abstract      : Glue logic that connects two XBI ports without a crossbar
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbglue.v,v $
// CVS revision  : $Revision: 1.7 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbglue (
  
  // Clock and reset
  input         clk_xbar,
  input         rst_xbar,

  // Source port
  output  [2:0] o_src_deq,
  output  [5:0] o_src_offset,
  output        o_src_eop,
  input  [15:0] i_src_data,
  input   [2:0] i_src_empty,

  // Destination port
  output  [2:0] o_dst_enq,
  output  [5:0] o_dst_offset,
  output        o_dst_eop,
  output [15:0] o_dst_data,
  input   [2:0] i_dst_full,
  input   [2:0] i_dst_packets_vc0,
  input   [2:0] i_dst_packets_vc1,
  input   [2:0] i_dst_packets_vc2
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  reg   [2:0] dst_packets_vc0_q;
  wire  [2:0] dst_packets_vc0_d;
  reg   [2:0] dst_packets_vc1_q;
  wire  [2:0] dst_packets_vc1_d;
  reg   [2:0] dst_packets_vc2_q;
  wire  [2:0] dst_packets_vc2_d;
  
  reg   [2:0] src_empty_q;
  wire  [2:0] src_empty_d;
  reg   [2:0] my_full_q;
  wire  [2:0] my_full_d;
  
  reg   [5:0] deq_cnt_q;
  wire  [5:0] deq_cnt_d;
  reg   [5:0] enq_cnt_q;
  wire  [5:0] enq_cnt_d;
  reg   [5:0] size_q;
  wire  [5:0] size_d;

  wire        vc0_eligible;
  wire        vc1_eligible;
  wire        vc2_eligible;

  wire        first_word;

  reg   [2:0] active_vc_q;
  wire  [2:0] active_vc_d;
 
  reg   [2:0] dst_enq_q;
  wire  [2:0] dst_enq_d;
  reg  [15:0] dst_data_q;
  wire [15:0] dst_data_d;
  reg         dst_eop_q;
  wire        dst_eop_d;
  
  reg   [2:0] src_deq_q;
  wire  [2:0] src_deq_d;
  reg         src_eop_q;
  wire        src_eop_d;
 
  
  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle       = 4'b0001,
             Copy       = 4'b0010,
             Flush0     = 4'b0100,
             Flush1     = 4'b1000;

  reg  [3:0] state_d;
  reg  [3:0] state_q;

  // synthesis translate_off
  reg [256:0] StateString;
  always @(state_q) begin
    case (state_q)
      Idle       : StateString = "Idle";
      Copy       : StateString = "Copy";
      Flush0     : StateString = "Flush0";
      Flush1     : StateString = "Flush1";
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
            state_d = Flush0;
          else
            state_d = Copy;
        end

      Flush0: begin
          if (enq_cnt_d == size_q)
            state_d = Idle;
          else
            state_d = Flush1;
        end

      Flush1: begin
          if (enq_cnt_d == size_q)
            state_d = Idle;
          else
            state_d = Flush1;
        end

      default:
        begin
          state_d = Idle;
        end
    endcase
  end

  
  // ==========================================================================
  // Enqueue-dequeue logic
  // ==========================================================================
  assign src_empty_d = i_src_empty;

  assign dst_packets_vc0_d = i_dst_packets_vc0;
  assign dst_packets_vc1_d = i_dst_packets_vc1;
  assign dst_packets_vc2_d = i_dst_packets_vc2;

  assign my_full_d[0] = (dst_packets_vc0_q < 3'd2);
  assign my_full_d[1] = (dst_packets_vc1_q < 3'd2);
  assign my_full_d[2] = (dst_packets_vc2_q < 3'd2);
  
  assign vc0_eligible = ~src_empty_q[0] & ~my_full_q[0];
  assign vc1_eligible = ~src_empty_q[1] & ~my_full_q[1];
  assign vc2_eligible = ~src_empty_q[2] & ~my_full_q[2];

  assign active_vc_d = (state_q != Idle) ? active_vc_q :
                       (vc0_eligible)    ? 3'b001 :
                       (vc1_eligible)    ? 3'b010 :
                       (vc2_eligible)    ? 3'b100 :
                                           3'b000;

  assign deq_cnt_d = (state_q == Idle) ? 6'b0 :
                                         deq_cnt_q + 1'b1;

  assign first_word = (deq_cnt_q == 6'd3);

  assign size_d = (state_q == Idle)     ? 6'b111111 :
                  ((state_q == Copy) &
                   first_word)          ? i_src_data[5:0] + 6'd6:
                                          size_q;

  assign enq_cnt_d = deq_cnt_q - 6'd3;

  assign dst_enq_d = (state_q == Idle) ? 3'b0 :
                     ((state_q == Copy) & 
                      first_word)      ? active_vc_q : 
                                         dst_enq_q;

  assign dst_data_d = i_src_data;

  assign dst_eop_d = ((state_q == Flush0) | 
                      (state_q == Flush1)) & (state_d == Idle);

  assign src_deq_d = ((state_d == Copy) | 
                      (state_d == Flush0)) ? active_vc_d : 3'b0;

  assign src_eop_d = (state_d == Flush0);


  // ==========================================================================
  // Output signals
  // ==========================================================================
  assign o_src_deq = src_deq_q;

  assign o_src_offset = deq_cnt_q;

  assign o_src_eop = src_eop_q;

  
  assign o_dst_enq = dst_enq_q;
  
  assign o_dst_offset = enq_cnt_q;

  assign o_dst_data = dst_data_q;

  assign o_dst_eop = dst_eop_q;


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_xbar) begin
    if (rst_xbar) begin
      state_q           <= #`dh Idle;
      dst_enq_q         <= #`dh 0;
      dst_eop_q         <= #`dh 0;
      src_deq_q         <= #`dh 0;
      src_eop_q         <= #`dh 0;
    end
    else begin
      state_q           <= #`dh state_d;
      dst_enq_q         <= #`dh dst_enq_d;
      dst_eop_q         <= #`dh dst_eop_d;
      src_deq_q         <= #`dh src_deq_d;
      src_eop_q         <= #`dh src_eop_d;
    end
  end

  always @(posedge clk_xbar) begin
    deq_cnt_q           <= #`dh deq_cnt_d;
    enq_cnt_q           <= #`dh enq_cnt_d;
    size_q              <= #`dh size_d;
    active_vc_q         <= #`dh active_vc_d;
    dst_data_q          <= #`dh dst_data_d;
    my_full_q           <= #`dh my_full_d;
    src_empty_q         <= #`dh src_empty_d;
    dst_packets_vc0_q   <= #`dh dst_packets_vc0_d;
    dst_packets_vc1_q   <= #`dh dst_packets_vc1_d;
    dst_packets_vc2_q   <= #`dh dst_packets_vc2_d;
  end

endmodule
