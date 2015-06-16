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
// Abstract      : Crossbar output arbiter
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbar_arb_out.v,v $
// CVS revision  : $Revision: 1.11 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbar_arb_out (
  
  // Clock and reset
  input         clk,
  input         rst,

  // Output FIFO interface
  output  [2:0] o_fifo_enq,
  output  [5:0] o_fifo_offset,
  output        o_fifo_eop,
  output [15:0] o_fifo_data,
  input   [2:0] i_fifo_full,
  input   [2:0] i_fifo_packets_vc0,
  input   [2:0] i_fifo_packets_vc1,
  input   [2:0] i_fifo_packets_vc2,

  // Input arbiters interface
  input  [21:0] i_req0,
  input  [21:0] i_req1,
  input  [21:0] i_req2,
  output [21:0] o_gnt0,
  output [21:0] o_gnt1,
  output [21:0] o_gnt2,

  // Switching fabric interface
  output  [4:0] o_mux_sel,
  input  [15:0] i_data
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  wire [21:0] req0_d;
  reg  [21:0] req0_q;
  wire [21:0] req1_d;
  reg  [21:0] req1_q;
  wire [21:0] req2_d;
  reg  [21:0] req2_q;

  wire [21:0] gnt0_d;
  reg  [21:0] gnt0_q;
  wire [21:0] gnt1_d;
  reg  [21:0] gnt1_q;
  wire [21:0] gnt2_d;
  reg  [21:0] gnt2_q;

  wire  [7:0] winner_d;
  reg   [7:0] winner_q;
  reg   [2:0] winner_enc;

  wire        pipe0_winner_found_vc0;
  wire  [7:0] pipe0_winner_vc0;
  wire  [1:0] pipe0_third_vc0;
  wire        pipe0_winner_found_vc1;
  wire  [7:0] pipe0_winner_vc1;
  wire  [1:0] pipe0_third_vc1;
  wire        pipe0_winner_found_vc2;
  wire  [7:0] pipe0_winner_vc2;
  wire  [1:0] pipe0_third_vc2;
  wire  [2:0] pipe0_vc_d;
  reg   [2:0] pipe0_vc_q;

  wire  [7:0] pipe1_req_d;
  reg   [7:0] pipe1_req_q;
  wire  [1:0] pipe1_third_enc;
  wire  [2:0] pipe1_third_dec;
  wire        winner_found;
  wire  [2:0] pipe1_vc_d;
  reg   [2:0] pipe1_vc_q;
  wire  [2:0] pipe1_third_d;
  reg   [2:0] pipe1_third_q;

  wire  [2:0] fifo_enq_d;
  reg   [2:0] fifo_enq_q;
  wire  [5:0] fifo_offset_d;
  reg   [5:0] fifo_offset_q;
  wire        fifo_eop_d;
  reg         fifo_eop_q;
  wire [15:0] fifo_data_d;
  reg  [15:0] fifo_data_q;
  wire  [2:0] fifo_full_d;
  reg   [2:0] fifo_full_q;
  wire  [2:0] fifo_packets0_d;
  reg   [2:0] fifo_packets0_q;
  wire  [2:0] fifo_packets1_d;
  reg   [2:0] fifo_packets1_q;
  wire  [2:0] fifo_packets2_d;
  reg   [2:0] fifo_packets2_q;
  wire  [2:0] my_full_d;
  reg   [2:0] my_full_q;
  wire  [4:0] mux_sel_d;
  reg   [4:0] mux_sel_q;
  wire  [2:0] wait_cnt_d;
  reg   [2:0] wait_cnt_q;
  wire        wait_cnt_end;
  wire        accept;
  wire        packet_almost_finished;
  wire        packet_finished;
  wire        begin_new_packet;
  wire  [5:0] size_d;
  reg   [5:0] size_q;


  // ==========================================================================
  // Scheduling FSM
  // ==========================================================================
  localparam Idle       = 6'b00_0001,
             Grant      = 6'b00_0010,
             WaitAccept = 6'b00_0100,
             Mux        = 6'b00_1000,
             WaitPacket = 6'b01_0000,
             Receive    = 6'b10_0000;

  reg  [5:0] sched_state_d;
  reg  [5:0] sched_state_q;

  // synthesis translate_off
  reg [256:0] SchedStateString;
  always @(sched_state_q) begin
    case (sched_state_q)
      Idle       : SchedStateString = "Idle";
      Grant      : SchedStateString = "Grant";
      WaitAccept : SchedStateString = "WaitAccept";
      Mux        : SchedStateString = "Mux";
      WaitPacket : SchedStateString = "WaitPacket";
      Receive    : SchedStateString = "Receive";
      default    : SchedStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (sched_state_q)

      Idle: begin
          if (winner_found)
            sched_state_d = Grant;
          else 
            sched_state_d = Idle;
        end

      Grant: begin
          sched_state_d = WaitAccept;
        end

      WaitAccept: begin
          if (accept)
            sched_state_d = Mux;
          else if (wait_cnt_end) 
            sched_state_d = Idle;
          else
            sched_state_d = WaitAccept;
        end

      Mux: begin
          sched_state_d = WaitPacket;
        end

      WaitPacket: begin
          if (wait_cnt_end)
            sched_state_d = Receive;
          else
            sched_state_d = WaitPacket;
        end

      Receive: begin
          if (packet_almost_finished)
            sched_state_d = Idle;
          else
            sched_state_d = Receive;
        end

      default:
        begin
          sched_state_d = Idle;
        end
    endcase
  end

  
  // ==========================================================================
  // Packet Receiving FSM
  // ==========================================================================
  localparam // encoding common with scheduler Idle state: Idle = 6'b00_0001,
             First      = 3'b010,
             Rest       = 3'b100;

  reg  [2:0] rcv_state_d;
  reg  [2:0] rcv_state_q;

  // synthesis translate_off
  reg [256:0] RcvStateString;
  always @(rcv_state_q) begin
    case (rcv_state_q)
      Idle       : RcvStateString = "Idle";
      First      : RcvStateString = "First";
      Rest       : RcvStateString = "Rest";
      default    : RcvStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (rcv_state_q)

      Idle: begin
          if (begin_new_packet)
            rcv_state_d = First;
          else 
            rcv_state_d = Idle;
        end

      First: begin
          rcv_state_d = Rest;
        end

      Rest: begin
          if (packet_finished & begin_new_packet)
            rcv_state_d = First;
          else if (packet_finished)
            rcv_state_d = Idle;
          else 
            rcv_state_d = Rest;
        end

      default:
        begin
          rcv_state_d = Idle;
        end
    endcase
  end

  
  // ==========================================================================
  // Req-gnt datapath
  // ==========================================================================
 
  // Input registers
  assign req0_d = i_req0;
  assign req1_d = i_req1;
  assign req2_d = i_req2;

  // First pipeline stage
  xbar_partial_enforcer i0_xbar_partial_enforcer (
    .clk                ( clk ),
    .rst                ( rst ),
    .i_req              ( req0_q ),
    .o_winner_found     ( pipe0_winner_found_vc0 ),
    .o_winner           ( pipe0_winner_vc0 ),
    .o_third            ( pipe0_third_vc0 )
  );

  xbar_partial_enforcer i1_xbar_partial_enforcer (
    .clk                ( clk ),
    .rst                ( rst ),
    .i_req              ( req1_q ),
    .o_winner_found     ( pipe0_winner_found_vc1 ),
    .o_winner           ( pipe0_winner_vc1 ),
    .o_third            ( pipe0_third_vc1 )
  );

  xbar_partial_enforcer i2_xbar_partial_enforcer (
    .clk                ( clk ),
    .rst                ( rst ),
    .i_req              ( req2_q ),
    .o_winner_found     ( pipe0_winner_found_vc2 ),
    .o_winner           ( pipe0_winner_vc2 ),
    .o_third            ( pipe0_third_vc2 )
  );

  assign pipe0_vc_d = (sched_state_q != Idle) ? pipe1_vc_q : 
                                                {pipe0_vc_q[1:0], 
                                                 pipe0_vc_q[2]};

  // Second pipeline stage
  assign winner_found = 
                    (pipe0_winner_found_vc0 & ~my_full_q[0] & pipe0_vc_q[0]) |
                    (pipe0_winner_found_vc1 & ~my_full_q[1] & pipe0_vc_q[1]) |
                    (pipe0_winner_found_vc2 & ~my_full_q[2] & pipe0_vc_q[2]);

  assign pipe1_req_d = (pipe0_winner_vc0 & {8{pipe0_vc_q[0]}}) |
                       (pipe0_winner_vc1 & {8{pipe0_vc_q[1]}}) |
                       (pipe0_winner_vc2 & {8{pipe0_vc_q[2]}});

  assign pipe1_third_enc = (pipe0_third_vc0 & {2{pipe0_vc_q[0]}}) |
                           (pipe0_third_vc1 & {2{pipe0_vc_q[1]}}) |
                           (pipe0_third_vc2 & {2{pipe0_vc_q[2]}});
 
  assign pipe1_third_dec = (pipe1_third_enc == 2'b00) ? 3'b001 :
                           (pipe1_third_enc == 2'b01) ? 3'b010 :
                           (pipe1_third_enc == 2'b10) ? 3'b100 :
                                                        3'bx;

  assign pipe1_third_d = (sched_state_q != Idle) ? pipe1_third_q :
                                                   pipe1_third_dec;

  assign pipe1_vc_d    = (sched_state_q != Idle) ? pipe1_vc_q : 
                                                   pipe0_vc_q;


  // Third pipeline stage
  assign gnt0_d[7:0]   = pipe1_req_q & {8{(pipe1_vc_q[0] & pipe1_third_q[0] & 
                                          (sched_state_q == Grant))}};
  assign gnt0_d[15:8]  = pipe1_req_q & {8{(pipe1_vc_q[0] & pipe1_third_q[1] & 
                                          (sched_state_q == Grant))}};
  assign gnt0_d[21:16] = pipe1_req_q[5:0] & 
                                       {6{(pipe1_vc_q[0] & pipe1_third_q[2] & 
                                          (sched_state_q == Grant))}};

  assign gnt1_d[7:0]   = pipe1_req_q & {8{(pipe1_vc_q[1] & pipe1_third_q[0] & 
                                          (sched_state_q == Grant))}};
  assign gnt1_d[15:8]  = pipe1_req_q & {8{(pipe1_vc_q[1] & pipe1_third_q[1] & 
                                          (sched_state_q == Grant))}};
  assign gnt1_d[21:16] = pipe1_req_q[5:0] & 
                                       {6{(pipe1_vc_q[1] & pipe1_third_q[2] & 
                                          (sched_state_q == Grant))}};

  assign gnt2_d[7:0]   = pipe1_req_q & {8{(pipe1_vc_q[2] & pipe1_third_q[0] & 
                                          (sched_state_q == Grant))}};
  assign gnt2_d[15:8]  = pipe1_req_q & {8{(pipe1_vc_q[2] & pipe1_third_q[1] & 
                                          (sched_state_q == Grant))}};
  assign gnt2_d[21:16] = pipe1_req_q[5:0] & 
                                       {6{(pipe1_vc_q[2] & pipe1_third_q[2] & 
                                          (sched_state_q == Grant))}};



  // ==========================================================================
  // Req-gnt control
  // ==========================================================================
  assign winner_d = (sched_state_q == Grant) ? pipe1_req_q : winner_q;

  assign wait_cnt_d = (sched_state_q == Grant)          ? 3'd6 :
                      (sched_state_q == Mux)            ? 3'd3 :
                      ((sched_state_q == WaitAccept) |
                       (sched_state_q == WaitPacket))   ? wait_cnt_q - 3'b1 : 
                                                          wait_cnt_q;

  assign wait_cnt_end = (wait_cnt_q == 3'b0);
  assign accept = wait_cnt_end & 
                  ( | (pipe1_req_d & winner_q)) & 
                  (pipe1_third_dec == pipe1_third_q);

  always @(winner_q) begin
    (* full_case *)
    case (winner_q)
      8'b00000001 : winner_enc = 3'd0;
      8'b00000010 : winner_enc = 3'd1;
      8'b00000100 : winner_enc = 3'd2;
      8'b00001000 : winner_enc = 3'd3;
      8'b00010000 : winner_enc = 3'd4;
      8'b00100000 : winner_enc = 3'd5;
      8'b01000000 : winner_enc = 3'd6;
      8'b10000000 : winner_enc = 3'd7;
      default     : winner_enc = 3'bx;
    endcase
  end


  // ==========================================================================
  // FIFO and switching fabric control
  // ==========================================================================
  assign mux_sel_d = (sched_state_q == Mux) ? 
                         (({2'b00, winner_enc} & {5{pipe1_third_q[0]}}) |
                          ({2'b01, winner_enc} & {5{pipe1_third_q[1]}}) |
                          ({2'b10, winner_enc} & {5{pipe1_third_q[2]}}))
                                            : mux_sel_q;

  // Max payload size is 32 words. Max header size is 7 words, so max
  // packet is 39 words.
  assign size_d = (rcv_state_q == First) ? (fifo_data_q[5:0] + 6'h6) : size_q;

  assign begin_new_packet = (sched_state_q == WaitPacket) & 
                            (sched_state_d == Receive);

  assign packet_finished = (rcv_state_q == Rest) & (fifo_offset_q == size_q);

  assign packet_almost_finished = (rcv_state_q == Rest) & 
                                        ((size_q < 6'd12) |
                                         (fifo_offset_q >= size_q - 6'd12));

  assign fifo_enq_d = (rcv_state_d == First) ? pipe0_vc_q :
                      (rcv_state_d != Rest)  ? 3'b0 :
                                               fifo_enq_q;

  assign fifo_offset_d = (rcv_state_d == First) ? 6'h0 :
                         (rcv_state_d == Rest)  ? fifo_offset_q + 1'b1 : 
                                                  fifo_offset_q;

  assign fifo_eop_d = (rcv_state_q == Rest) & (fifo_offset_q == size_q - 1'b1);

  assign fifo_data_d = i_data;

  assign fifo_full_d = i_fifo_full;
  assign fifo_packets0_d = i_fifo_packets_vc0;
  assign fifo_packets1_d = i_fifo_packets_vc1;
  assign fifo_packets2_d = i_fifo_packets_vc2;

  assign my_full_d = { fifo_full_q[2] | (fifo_packets2_q < 3'd3),
                       fifo_full_q[1] | (fifo_packets1_q < 3'd3),
                       fifo_full_q[0] | (fifo_packets0_q < 3'd3) };


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk) begin
    if (rst) begin
      sched_state_q     <= #`dh Idle;
      rcv_state_q       <= #`dh Idle;
      req0_q            <= #`dh 0;
      req1_q            <= #`dh 0;
      req2_q            <= #`dh 0;
      gnt0_q            <= #`dh 0;
      gnt1_q            <= #`dh 0;
      gnt2_q            <= #`dh 0;
      fifo_enq_q        <= #`dh 0;
      fifo_full_q       <= #`dh 0;
      wait_cnt_q        <= #`dh 0;
      pipe0_vc_q        <= #`dh 3'b001;
      pipe1_req_q       <= #`dh 0;
      pipe1_vc_q        <= #`dh 0;
      pipe1_third_q     <= #`dh 0;
    end
    else begin
      sched_state_q     <= #`dh sched_state_d;
      rcv_state_q       <= #`dh rcv_state_d;
      req0_q            <= #`dh req0_d;
      req1_q            <= #`dh req1_d;
      req2_q            <= #`dh req2_d;
      gnt0_q            <= #`dh gnt0_d;
      gnt1_q            <= #`dh gnt1_d;
      gnt2_q            <= #`dh gnt2_d;
      fifo_enq_q        <= #`dh fifo_enq_d;
      fifo_full_q       <= #`dh fifo_full_d;
      wait_cnt_q        <= #`dh wait_cnt_d;
      pipe0_vc_q        <= #`dh pipe0_vc_d;
      pipe1_req_q       <= #`dh pipe1_req_d;
      pipe1_vc_q        <= #`dh pipe1_vc_d;
      pipe1_third_q     <= #`dh pipe1_third_d;
    end
  end

  always @(posedge clk) begin
    fifo_offset_q       <= #`dh fifo_offset_d;
    fifo_eop_q          <= #`dh fifo_eop_d;
    fifo_data_q         <= #`dh fifo_data_d;
    fifo_packets0_q     <= #`dh fifo_packets0_d;
    fifo_packets1_q     <= #`dh fifo_packets1_d;
    fifo_packets2_q     <= #`dh fifo_packets2_d;
    my_full_q           <= #`dh my_full_d;
    mux_sel_q           <= #`dh mux_sel_d;
    size_q              <= #`dh size_d;
    winner_q            <= #`dh winner_d;
  end

  // ==========================================================================
  // Outputs
  // ==========================================================================
  assign o_gnt0         = gnt0_q;
  assign o_gnt1         = gnt1_q;
  assign o_gnt2         = gnt2_q;
  assign o_fifo_enq     = fifo_enq_q;
  assign o_fifo_offset  = fifo_offset_q;
  assign o_fifo_eop     = fifo_eop_q;
  assign o_fifo_data    = fifo_data_q;
  assign o_mux_sel      = mux_sel_q;

endmodule


