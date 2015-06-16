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
// Abstract      : MNI acknowledgments
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni_ack.v,v $
// CVS revision  : $Revision: 1.6 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module mni_ack (

  // Clock and reset
  input             clk_ni,
  input             rst_ni,

  // Static configuration
  input      [ 7:0] i_board_id,
  input      [ 3:0] i_node_id,
  input      [11:0] i_ctl_addr_base,

  // CMX interface
  input             i_cmx_valid,
  input      [15:0] i_cmx_data,
  output            o_cmx_stall,
  
  // in interface
  input             i_in_valid,
  output            o_in_stall,
  input      [15:0] i_in_data,

  // wrfill interface
  input             i_wrfill_valid,
  output            o_wrfill_stall,
  input      [15:0] i_wrfill_data,

  // regif interface
  output            o_regif_valid,
  input             i_regif_stall,
  output     [15:0] o_regif_data,

  // out interface
  output            o_out_valid,
  input             i_out_stall,
  output     [15:0] o_out_data
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire [15:0] fifo_in_data;
  wire [15:0] fifo_out_data;
  wire        fifo_in_valid;
  wire        fifo_out_valid;
  wire        fifo_in_stall;
  wire        fifo_out_stall;

  wire  [3:0] pr_valid;
  wire        pr_detect;
  wire        serve_in;
  wire        serve_wrfill;
  wire        serve_cmx;
  wire [15:0] inp_data;

  wire        local_node_d;
  reg         local_node_q;
  wire        is_local;
  wire        to_regs_d;
  reg         to_regs_q;
  wire        to_out_d;
  reg         to_out_q;
  wire        regs_first_word_d;
  reg         regs_first_word_q;


  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle       = 7'b0000001,
             Node       = 7'b0000010,
             AdrHigh    = 7'b0000100,
             AdrLow     = 7'b0001000,
             AckZero    = 7'b0010000,
             AckVal     = 7'b0100000,
             Wait       = 7'b1000000;

  reg  [6:0] state_d;
  reg  [6:0] state_q;

  // synthesis translate_off
  reg [256:0] AckStateString;
  always @(state_q) begin
    case (state_q)
      Idle      : AckStateString = "Idle";
      Node      : AckStateString = "Node";
      AdrHigh   : AckStateString = "AdrHigh";
      AdrLow    : AckStateString = "AdrLow";
      AckZero   : AckStateString = "AckZero";
      AckVal    : AckStateString = "AckVal";
      Wait      : AckStateString = "Wait";
      default   : AckStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (pr_detect)
            state_d = Node;
          else
            state_d = Idle;
        end

      Node: begin
          if (fifo_in_stall) 
            state_d = Node;
          else
            state_d = AdrHigh;
        end

      AdrHigh: begin
          if (fifo_in_stall)
            state_d = AdrHigh;
          else
            state_d = AdrLow;
        end

      AdrLow: begin
          if (fifo_in_stall)
            state_d = AdrLow;
          else
            state_d = AckZero;
        end

      AckZero: begin
          if (fifo_in_stall)
            state_d = AckZero;
          else
            state_d = AckVal;
        end

      AckVal: begin
          if (fifo_in_stall)
            state_d = AckVal;
          else
            state_d = Wait;
        end

      Wait: begin
          if ( fifo_out_valid )
            state_d = Wait;
          else
            state_d = Idle;
        end

      default:
        begin
          state_d = Idle;
        end

    endcase
  end


  // ==========================================================================
  // Datapath
  // ==========================================================================
  
  // Interface selection
  LdEnPriorEnf #(
    .N_log       ( 2 )
  ) i0_LdEnPriorEnf (
    .Clk         ( clk_ni ),
    .Reset       ( rst_ni ),
    .LdEn        ( (state_q == Idle) ),
    .In          ( {1'b0, i_in_valid, i_wrfill_valid, i_cmx_valid} ),
    .Out         ( pr_valid ),
    .Mask        ( ),
    .OneDetected ( pr_detect )
  );

  assign serve_in     = pr_valid[2];
  assign serve_wrfill = pr_valid[1];
  assign serve_cmx    = pr_valid[0];

  assign inp_data = (i_in_data     & {16{serve_in}}) |
                    (i_wrfill_data & {16{serve_wrfill}}) |
                    (i_cmx_data    & {16{serve_cmx}});

  // Destination selection
  assign local_node_d = (state_q == Idle) ? ((inp_data[11:4] == i_board_id) &
                                             (inp_data[3:0]  == i_node_id)) :
                                            local_node_q;

  assign is_local = local_node_q & (inp_data[15:4] == i_ctl_addr_base);

  assign to_regs_d = (state_q == AdrHigh) ? is_local : 
                     (state_d == Idle)    ? 1'b0 :
                                            to_regs_q;

  assign to_out_d  = (state_q == AdrHigh) ? ~is_local : 
                     (state_d == Idle)    ? 1'b0 :
                                            to_out_q;

  assign regs_first_word_d = (state_q == Idle) ? 1'b1 :
                             (fifo_out_valid &
                              to_regs_q)       ? 1'b0 :
                                                 regs_first_word_q;

  // 2-elements storage, to break the * -> ack -> {regif,out} critical paths
  align_clk_sync_2 # (
    .N      ( 16 )
  ) i0_align_clk_sync_2 (
    .clk_in  ( clk_ni ),
    .rst_in  ( rst_ni ),
    .i_data  ( fifo_in_data ),
    .i_valid ( fifo_in_valid ),
    .o_stall ( fifo_in_stall ),
    .clk_out ( clk_ni ),
    .rst_out ( rst_ni ),
    .o_data  ( fifo_out_data ),
    .o_valid ( fifo_out_valid ),
    .i_stall ( fifo_out_stall )
  );

  assign fifo_in_data = ((state_q == AdrHigh) &  
                         to_regs_d)             ? { 7'd2, 4'b1111, 1'b1, 
                                                    inp_data[3:0] } :
                        (state_q == AckZero)    ? 16'b0 :
                        ((state_q == AckVal) & 
                         serve_wrfill)          ? 16'd64 :
                                                  inp_data;

  assign fifo_in_valid = (state_q == Node) | 
                         (state_q == AdrHigh) |
                         (state_q == AdrLow) |
                         (state_q == AckZero) |
                         (state_q == AckVal);

  assign fifo_out_stall = (to_regs_q) ? (~regs_first_word_q & i_regif_stall) : 
                          (to_out_q)  ? i_out_stall :
                                        1'b1;


  // Stalls
  assign o_cmx_stall    = ~(serve_cmx &
                            (((state_q == Node)    & ~fifo_in_stall) |
                             ((state_q == AdrHigh) & ~fifo_in_stall) |
                             ((state_q == AdrLow)  & ~fifo_in_stall) |
                             ((state_q == AckVal)  & ~fifo_in_stall)));

  assign o_wrfill_stall = ~(serve_wrfill &
                            (((state_q == Node)    & ~fifo_in_stall) |
                             ((state_q == AdrHigh) & ~fifo_in_stall) |
                             ((state_q == AdrLow)  & ~fifo_in_stall)));


  assign o_in_stall     = ~(serve_in &
                            (((state_q == Node)    & ~fifo_in_stall) |
                             ((state_q == AdrHigh) & ~fifo_in_stall) |
                             ((state_q == AdrLow)  & ~fifo_in_stall) |
                             ((state_q == AckVal)  & ~fifo_in_stall)));

  // regif interface. The first word in the FIFO (brd/node) is not
  //                  given to regif.
  assign o_regif_valid = fifo_out_valid & ~regs_first_word_q & to_regs_q;
  assign o_regif_data  = fifo_out_data;

  // out interface
  assign o_out_valid   = fifo_out_valid & to_out_q;
  assign o_out_data    = fifo_out_data;




  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_ni) begin
    if (rst_ni) begin
      state_q           <= #`dh Idle;
    end
    else begin
      state_q           <= #`dh state_d;
    end
  end

  always @(posedge clk_ni) begin
    local_node_q      <= #`dh local_node_d;
    to_regs_q         <= #`dh to_regs_d;
    to_out_q          <= #`dh to_out_d;
    regs_first_word_q <= #`dh regs_first_word_d;
  end

endmodule
