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
// Abstract      : MNI output packet generator
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni_out.v,v $
// CVS revision  : $Revision: 1.39 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module mni_out (

  // Clock and reset
  input             clk_ni,
  input             rst_ni,

  // Static configuration
  input       [7:0] i_board_id,
  input       [3:0] i_node_id,

  // Network Out Interface
  output      [2:0] o_nout_enq,
  output      [5:0] o_nout_offset,
  output            o_nout_eop,
  output     [15:0] o_nout_data,
  input       [2:0] i_nout_full,

  // dma interface
  input       [1:0] i_dma_req,
  output            o_dma_ack,
  input       [5:0] i_dma_offset,
  input       [2:0] i_dma_enq,
  input      [15:0] i_dma_data,
  input             i_dma_eop,

  // miss interface
  input             i_miss_valid,
  output            o_miss_stall,
  input      [15:0] i_miss_data,

  // wrfill interface
  input             i_wrfill_valid,
  output            o_wrfill_stall,
  input      [15:0] i_wrfill_data,

  // wb interface
  input             i_wb_valid,
  output            o_wb_stall,
  input      [15:0] i_wb_data,

  // in interface
  input             i_in_valid,
  output            o_in_stall,
  input      [15:0] i_in_data,

  // ack interface
  input             i_ack_valid,
  output            o_ack_stall,
  input      [15:0] i_ack_data
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  wire  [7:0] pr_valid;
  wire        pr_detect;
  wire        serve_dma;
  wire        serve_miss;
  wire        serve_wrfill;
  wire        serve_wb;
  wire        serve_in;
  wire        serve_ack;
  wire [15:0] inp_data;

  wire        has_ack_d;
  reg         has_ack_q;
  wire        size_cache_line_d;
  reg         size_cache_line_q;
  wire  [2:0] vc_d;
  reg   [2:0] vc_q;
  wire        payload_finished;
  wire        wr_dst_adr_low_d;
  reg         wr_dst_adr_low_q;

  wire  [2:0] out_enq_d;
  reg   [2:0] out_enq_q;
  wire  [2:0] out_offset_inc;
  wire  [5:0] out_offset_d;
  reg   [5:0] out_offset_q;
  wire        out_eop_d;
  reg         out_eop_q;
  wire [15:0] out_data_d;
  reg  [15:0] out_data_q;


  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle            = 20'b00000000000000000001,
             ServeDMA        = 20'b00000000000000000010,
             WrOpcode        = 20'b00000000000000000100,
             WrDstNode       = 20'b00000000000000001000,
             WrDstAdrHigh    = 20'b00000000000000010000,
             WrDstAdrLow     = 20'b00000000000000100000,
             WrAckNode       = 20'b00000000000001000000,
             WrAckAdrHigh    = 20'b00000000000010000000,
             WrAckAdrLow     = 20'b00000000000100000000,
             WrPayload       = 20'b00000000001000000000,
             RdOpcode        = 20'b00000000010000000000,
             RdDstNode       = 20'b00000000100000000000,
             RdDstAdrHigh    = 20'b00000001000000000000,
             RdDstAdrLow     = 20'b00000010000000000000,
             RdSrcNode       = 20'b00000100000000000000,
             RdSrcAdrHigh    = 20'b00001000000000000000,
             RdSrcAdrLow     = 20'b00010000000000000000,
             RdSizeHigh      = 20'b00100000000000000000,
             RdSizeLow       = 20'b01000000000000000000,
             Eop             = 20'b10000000000000000000;
            
  reg  [19:0] state_d;
  reg  [19:0] state_q;

  // synthesis translate_off
  reg [256:0] OutStateString;
  always @(state_q) begin
    case (state_q)
      Idle          : OutStateString = "Idle";
      ServeDMA      : OutStateString = "ServeDMA";
      WrOpcode      : OutStateString = "WrOpcode";
      WrDstNode     : OutStateString = "WrDstNode";
      WrDstAdrHigh  : OutStateString = "WrDstAdrHigh";
      WrDstAdrLow   : OutStateString = "WrDstAdrLow";
      WrAckNode     : OutStateString = "WrAckNode";
      WrAckAdrHigh  : OutStateString = "WrAckAdrHigh";
      WrAckAdrLow   : OutStateString = "WrAckAdrLow";
      WrPayload     : OutStateString = "WrPayload";
      RdOpcode      : OutStateString = "RdOpcode";
      RdDstNode     : OutStateString = "RdDstNode";
      RdDstAdrHigh  : OutStateString = "RdDstAdrHigh";
      RdDstAdrLow   : OutStateString = "RdDstAdrLow";
      RdSrcNode     : OutStateString = "RdSrcNode";
      RdSrcAdrHigh  : OutStateString = "RdSrcAdrHigh";
      RdSrcAdrLow   : OutStateString = "RdSrcAdrLow";
      RdSizeHigh    : OutStateString = "RdSizeHigh";
      RdSizeLow     : OutStateString = "RdSizeLow";
      Eop           : OutStateString = "Eop";
      default       : OutStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (~pr_detect)
            state_d = Idle;
          else if (serve_dma)
            state_d = ServeDMA;
          else if (serve_miss & ~inp_data[4])
            state_d = RdOpcode;
          else
            state_d = WrOpcode;
        end

      ServeDMA: begin
          if (i_dma_eop)
            state_d = Eop;
          else
            state_d = ServeDMA;
        end

      // Write packet states
      WrOpcode: begin
          state_d = WrDstNode;
        end

      WrDstNode: begin
          state_d = WrDstAdrHigh;
        end

      WrDstAdrHigh: begin
          state_d = WrDstAdrLow;
        end

      WrDstAdrLow: begin
          if (has_ack_q) 
            state_d = WrAckNode;
          else
            state_d = WrPayload;
        end

      WrAckNode: begin
          state_d = WrAckAdrHigh;
        end

      WrAckAdrHigh: begin
          state_d = WrAckAdrLow;
        end

      WrAckAdrLow: begin
          state_d = WrPayload;
        end

      WrPayload: begin
          if (payload_finished)
            state_d = Eop;
          else
            state_d = WrPayload;
        end

      // Read packet states
      RdOpcode: begin
          state_d = RdDstNode;
        end

      RdDstNode: begin
          state_d = RdDstAdrHigh;
        end

      RdDstAdrHigh: begin
          state_d = RdDstAdrLow;
        end

      RdDstAdrLow: begin
          state_d = RdSrcNode;
        end

      RdSrcNode: begin
          state_d = RdSrcAdrHigh;
        end

      RdSrcAdrHigh: begin
          state_d = RdSrcAdrLow;
        end

      RdSrcAdrLow: begin
          state_d = RdSizeHigh;
        end

      RdSizeHigh: begin
          state_d = RdSizeLow;
        end

      RdSizeLow: begin
          state_d = Eop;
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
    .N_log       ( 3 )
  ) i0_LdEnPriorEnf (
    .Clk         ( clk_ni ),
    .Reset       ( rst_ni ),
    .LdEn        ( (state_q == Idle) ),
    .In          ( {
                     2'b0,
                     (i_dma_req[0]   & ~i_nout_full[1]) |
                     (i_dma_req[1]   & ~i_nout_full[2]),
                     (i_miss_valid & (( i_miss_data[4] & ~i_nout_full[1]) |
                                      (~i_miss_data[4] & ~i_nout_full[2]))),
                     (i_wrfill_valid & ~i_nout_full[1]),
                     (i_wb_valid     & ~i_nout_full[1]),
                     (i_in_valid     & ~i_nout_full[1]),
                     (i_ack_valid    & ~i_nout_full[0])
                    } ),
    .Out         ( pr_valid ),
    .Mask        ( ),
    .OneDetected ( pr_detect )
  );

  assign serve_dma    = pr_valid[5];
  assign serve_miss   = pr_valid[4];
  assign serve_wrfill = pr_valid[3];
  assign serve_wb     = pr_valid[2];
  assign serve_in     = pr_valid[1];
  assign serve_ack    = pr_valid[0];

  assign inp_data = (i_dma_data    & {16{serve_dma}}) |
                    (i_miss_data   & {16{serve_miss}}) |
                    (i_wrfill_data & {16{serve_wrfill}}) |
                    (i_wb_data     & {16{serve_wb}}) |
                    (i_in_data     & {16{serve_in}}) |
                    (i_ack_data    & {16{serve_ack}});

  // Standard fields
  assign vc_d = (state_q != Idle)     ? vc_q :
                (state_d == RdOpcode) ? 3'b100 :
                (serve_ack)           ? 3'b001 :
                                        3'b010;

  assign has_ack_d = (state_q != Idle)                ? has_ack_q :
                     ((serve_in & inp_data[0]) |
                      (serve_wb) |
                      (serve_wrfill & inp_data[1]) |
                      (serve_miss & inp_data[4]))     ? 1'b1 :
                                                        1'b0;

  assign size_cache_line_d = (state_q != Idle)             ? size_cache_line_q :
                             ((serve_wb) |
                              (serve_wrfill) |
                              (serve_miss & ~inp_data[4] & 
                               inp_data[14]))              ? 1'b1 :
                                                             1'b0;

  // Output offset & controls
  assign wr_dst_adr_low_d = (state_q == WrDstAdrLow);

  assign out_offset_inc = (((state_q == WrPayload) &
                            wr_dst_adr_low_q) |
                           (state_q == RdSrcNode)) ? 3'd4 : 3'd1;

  assign out_offset_d = (serve_dma)               ? i_dma_offset :
                        ((state_q == Idle) |
                         (state_q == WrOpcode) |
                         (state_q == RdOpcode))   ? 6'd0 :
                                                    out_offset_q + 
                                                    out_offset_inc;
  
  assign payload_finished = (size_cache_line_q) ? (out_offset_q == 6'd37) :
                                                  (out_offset_q == 6'd7);

  assign out_enq_d = (serve_dma)               ? i_dma_enq : 
                     ((state_q == WrOpcode) |
                      (state_q == RdOpcode))   ? vc_q :
                     ((state_q == Idle) |
                      (state_q == Eop))        ? 3'b000 :
                                                 out_enq_q;

  assign out_eop_d = (state_d == Eop);


  // Output data
  assign out_data_d = 

    (state_q == WrOpcode)    ? { 2'b00,       // RFU, Write packet
                                 3'b0,        // TLB error, C bit, W bit
                                 ~serve_miss, // Miss/fill bit
                                 has_ack_q,   // Ack bit
                                 1'b0,        // Ignore dirty on src
                                 vc_q[2],     
                                 vc_q[1],
                                 size_cache_line_q, // Size: 8'd32 or 8'd2 words
                                 3'b0,
                                 ~size_cache_line_q,
                                 1'b0} :

    (((state_q == WrDstNode) &
      (serve_miss |
       serve_wb |
       serve_wrfill)) |  
     (state_q == RdDstNode)) ? { inp_data[8:5],  // Byte enables (wr miss only)
                                 i_board_id,
                                 4'hC } :

    (state_q == RdOpcode)    ? { 2'b01,       // RFU, Read packet
                                 3'b0,        // TLB error, C bit, W bit
                                 ~serve_miss, // Miss/fill bit
                                 has_ack_q,   // Ack bit
                                 1'b0,        // Ignore dirty on src
                                 vc_q[2],     
                                 vc_q[1],
                                 6'd5} :      // Rd payload size always 5 words

    ((state_q == RdSrcNode) |
     ((state_q == WrAckNode) &
      (serve_miss |
       serve_wb)))           ? { 4'b0,
                                 i_board_id,
                                 i_node_id } :

    (state_q == RdSizeHigh)  ? 16'b0 :

    (state_q == RdSizeLow)   ? { 9'b0,        // Size = 16'd64 or 16'd4 bytes
                                 size_cache_line_q,
                                 3'b0,
                                 ~size_cache_line_q,
                                 2'b0} :

                               // Default case, covers for all missing above
                               inp_data;


  // Outputs 
  assign o_nout_enq     = out_enq_q;
  assign o_nout_offset  = out_offset_q;
  assign o_nout_eop     = out_eop_q;
  assign o_nout_data    = out_data_q;
  
  assign o_dma_ack = (state_q == Idle) & (state_d == ServeDMA);

  // Interface advance signals
  assign o_miss_stall   = ~(serve_miss & (
                            (state_q == WrDstNode) |
                            (state_q == WrDstAdrHigh) |
                            (state_q == WrDstAdrLow) |
                            (state_q == WrAckAdrHigh) |
                            (state_q == WrAckAdrLow) |
                            (state_q == WrPayload) |
                            (state_q == RdOpcode) |
                            (state_q == RdDstAdrHigh) |
                            (state_q == RdDstAdrLow) |
                            (state_q == RdSrcAdrHigh) |
                            (state_q == RdSrcAdrLow)
                           ));

  assign o_wrfill_stall = ~(serve_wrfill & (
                            (state_q == WrOpcode) |
                            (state_q == WrDstAdrHigh) |
                            (state_q == WrDstAdrLow) |
                            (state_q == WrAckNode) |
                            (state_q == WrAckAdrHigh) |
                            (state_q == WrAckAdrLow) |
                            (state_q == WrPayload)
                           ));


  assign o_wb_stall     = ~(serve_wb & (
                            (state_q == WrDstAdrHigh) |
                            (state_q == WrDstAdrLow) |
                            (state_q == WrAckAdrHigh) |
                            (state_q == WrAckAdrLow) |
                            (state_q == WrPayload)
                           ));

  assign o_in_stall     = ~(serve_in & (
                            (state_q == WrOpcode) |
                            (state_q == WrDstNode) |
                            (state_q == WrDstAdrHigh) |
                            (state_q == WrDstAdrLow) |
                            (state_q == WrAckNode) |
                            (state_q == WrAckAdrHigh) |
                            (state_q == WrAckAdrLow) |
                            (state_q == WrPayload)
                           ));

  assign o_ack_stall    = ~(serve_ack & (
                            (state_q == WrDstNode) |
                            (state_q == WrDstAdrHigh) |
                            (state_q == WrDstAdrLow) |
                            (state_q == WrPayload)
                           ));


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_ni) begin
    if (rst_ni) begin
      state_q           <= #`dh Idle;
      out_enq_q         <= #`dh 0;
      out_eop_q         <= #`dh 0;
    end
    else begin
      state_q           <= #`dh state_d;
      out_enq_q         <= #`dh out_enq_d;
      out_eop_q         <= #`dh out_eop_d;
    end
  end

  always @(posedge clk_ni) begin
    vc_q                <= #`dh vc_d;
    has_ack_q           <= #`dh has_ack_d;
    size_cache_line_q   <= #`dh size_cache_line_d;
    out_offset_q        <= #`dh out_offset_d;
    out_data_q          <= #`dh out_data_d;
    wr_dst_adr_low_q    <= #`dh wr_dst_adr_low_d;
  end

endmodule
