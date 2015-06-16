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
// Abstract      : MNI input packet handler
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni_in.v,v $
// CVS revision  : $Revision: 1.66 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module mni_in (

  // Clock and reset
  input             clk_ni,
  input             rst_ni,

  // Static configuration
  input      [11:0] i_ctl_addr_base,

  // Network In Interface
  output     [ 2:0] o_nin_deq,
  output reg [ 5:0] o_nin_offset,
  output            o_nin_eop,
  input      [15:0] i_nin_data,
  input      [ 2:0] i_nin_empty,
  
  // Network Out XBI levels
  input      [ 2:0] i_nout_packets_vc0,
  input      [ 2:0] i_nout_packets_vc1,

  // Mailbox level
  input      [11:0] i_cmx_mbox_space,
  input             i_cmx_mslot_space,

  // L2C Writeback Acknowledge Interface (clk_mc)
  output            o_l2c_wb_ack_valid,
  output            o_l2c_wb_ack_fault,
  output     [31:0] o_l2c_wb_ack_adr,
  input             i_l2c_wb_ack_stall,

  // wrfill interface
  input             i_wrfill_busy,
  output            o_wrfill_valid,
  output     [15:0] o_wrfill_data,

  // regif interface
  output            o_regif_valid,
  input             i_regif_stall,
  output     [15:0] o_regif_data,
  input             i_regif_resp_valid,
  input      [15:0] i_regif_resp_data,

  // netop_fifo interface
  output     [15:0] o_netop_fifo_wr_data,
  output            o_netop_fifo_wr_en,
  input             i_netop_fifo_full,

  // ack interface
  output            o_ack_valid,
  input             i_ack_stall,
  output     [15:0] o_ack_data,

  // out interface
  output            o_out_valid,
  input             i_out_stall,
  output     [15:0] o_out_data
);

  
  // ==========================================================================
  // Wires
  // ==========================================================================
  wire  [2:0] vc_eligible;

  wire  [2:0] vc_d;
  reg   [2:0] vc_q;

  wire        has_ack_d;
  reg         has_ack_q;
  wire        is_read_d;
  reg         is_read_q;
  wire  [5:0] size_d;
  reg   [5:0] size_q;

  wire  [5:0] offset_cnt_d;
  reg   [5:0] offset_cnt_q;
  wire        offset_cnt_end;

  wire        wrfill_valid_d;
  reg         wrfill_valid_q;

  wire        wback_valid_d;
  reg         wback_valid_q;
  wire [31:0] wback_adr_d;
  reg  [31:0] wback_adr_q;
  wire        wback_fault_d;
  reg         wback_fault_q;

  wire [15:0] tmp0_d;
  reg  [15:0] tmp0_q;
  wire [15:0] tmp1_d;
  reg  [15:0] tmp1_q;

  wire        out_valid_d;
  reg         out_valid_q;

  wire        netop_valid_d;
  reg         netop_valid_q;

  wire        ack_valid_d;
  reg         ack_valid_q;


  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam
       Idle        = 51'b000000000000000000000000000000000000000000000000001,
       Peek0       = 51'b000000000000000000000000000000000000000000000000010,
       Peek2       = 51'b000000000000000000000000000000000000000000000000100,
       WrFill0     = 51'b000000000000000000000000000000000000000000000001000,
       WrFill2     = 51'b000000000000000000000000000000000000000000000010000,
       WrFill3     = 51'b000000000000000000000000000000000000000000000100000,
       WrFillData  = 51'b000000000000000000000000000000000000000000001000000,
       WrFill4     = 51'b000000000000000000000000000000000000000000010000000,
       WrFill5     = 51'b000000000000000000000000000000000000000000100000000,
       WrFill6     = 51'b000000000000000000000000000000000000000001000000000,
       RegWr2      = 51'b000000000000000000000000000000000000000010000000000,
       RegWr3      = 51'b000000000000000000000000000000000000000100000000000,
       RegWrData   = 51'b000000000000000000000000000000000000001000000000000,
       RegWr4      = 51'b000000000000000000000000000000000000010000000000000,
       RegWr5      = 51'b000000000000000000000000000000000000100000000000000,
       RegWr6      = 51'b000000000000000000000000000000000001000000000000000,
       RegWrSize   = 51'b000000000000000000000000000000000010000000000000000,
       RegRd2      = 51'b000000000000000000000000000000000100000000000000000,
       RegRd3      = 51'b000000000000000000000000000000001000000000000000000,
       RegRdGetHi  = 51'b000000000000000000000000000000010000000000000000000,
       RegRdGetLo  = 51'b000000000000000000000000000000100000000000000000000,
       RegRdOpcode = 51'b000000000000000000000000000001000000000000000000000,
       RegRd7      = 51'b000000000000000000000000000010000000000000000000000,
       RegRd8      = 51'b000000000000000000000000000100000000000000000000000,
       RegRd9      = 51'b000000000000000000000000001000000000000000000000000,
       RegRd4      = 51'b000000000000000000000000010000000000000000000000000,
       RegRd5      = 51'b000000000000000000000000100000000000000000000000000,
       RegRd6      = 51'b000000000000000000000001000000000000000000000000000,
       RegRdPutHi  = 51'b000000000000000000000010000000000000000000000000000,
       RegRdPutLo  = 51'b000000000000000000000100000000000000000000000000000,
       WbAck0      = 51'b000000000000000000001000000000000000000000000000000,
       WbAck2      = 51'b000000000000000000010000000000000000000000000000000,
       WbAck3      = 51'b000000000000000000100000000000000000000000000000000,
       NetOp7      = 51'b000000000000000001000000000000000000000000000000000,
       NetOp0      = 51'b000000000000000010000000000000000000000000000000000,
       NetOp10     = 51'b000000000000000100000000000000000000000000000000000,
       NetOp11     = 51'b000000000000001000000000000000000000000000000000000,
       NetOp8      = 51'b000000000000010000000000000000000000000000000000000,
       NetOp9      = 51'b000000000000100000000000000000000000000000000000000,
       NetOp1      = 51'b000000000001000000000000000000000000000000000000000,
       NetOp4      = 51'b000000000010000000000000000000000000000000000000000,
       NetOp5      = 51'b000000000100000000000000000000000000000000000000000,
       NetOp6      = 51'b000000001000000000000000000000000000000000000000000,
       NetOp2      = 51'b000000010000000000000000000000000000000000000000000,
       NetOp3      = 51'b000000100000000000000000000000000000000000000000000,
       NetOpMsg    = 51'b000001000000000000000000000000000000000000000000000,
       NetNack4    = 51'b000010000000000000000000000000000000000000000000000,
       NetNack5    = 51'b000100000000000000000000000000000000000000000000000,
       NetNack6    = 51'b001000000000000000000000000000000000000000000000000,
       NetNackVal  = 51'b010000000000000000000000000000000000000000000000000,
       Eop         = 51'b100000000000000000000000000000000000000000000000000;

  reg  [50:0] state_d;
  reg  [50:0] state_q;

  // synthesis translate_off
  reg [256:0] InStateString;
  always @(state_q) begin
    case (state_q)
      Idle        : InStateString = "Idle";
      Peek0       : InStateString = "Peek0";
      Peek2       : InStateString = "Peek2";
      WrFill0     : InStateString = "WrFill0";
      WrFill2     : InStateString = "WrFill2";
      WrFill3     : InStateString = "WrFill3";
      WrFillData  : InStateString = "WrFillData";
      WrFill4     : InStateString = "WrFill4";
      WrFill5     : InStateString = "WrFill5";
      WrFill6     : InStateString = "WrFill6";
      RegWr2      : InStateString = "RegWr2";
      RegWr3      : InStateString = "RegWr3";
      RegWrData   : InStateString = "RegWrData";
      RegWr4      : InStateString = "RegWr4";
      RegWr5      : InStateString = "RegWr5";
      RegWr6      : InStateString = "RegWr6";
      RegWrSize   : InStateString = "RegWrSize";
      RegRd2      : InStateString = "RegRd2";
      RegRd3      : InStateString = "RegRd3";
      RegRdGetHi  : InStateString = "RegRdGetHi";
      RegRdGetLo  : InStateString = "RegRdGetLo";
      RegRdOpcode : InStateString = "RegRdOpcode";
      RegRd7      : InStateString = "RegRd7";
      RegRd8      : InStateString = "RegRd8";
      RegRd9      : InStateString = "RegRd9";
      RegRd4      : InStateString = "RegRd4";
      RegRd5      : InStateString = "RegRd5";
      RegRd6      : InStateString = "RegRd6";
      RegRdPutHi  : InStateString = "RegRdPutHi";
      RegRdPutLo  : InStateString = "RegRdPutLo";
      WbAck0      : InStateString = "WbAck0";
      WbAck2      : InStateString = "WbAck2";
      WbAck3      : InStateString = "WbAck3";
      NetOp7      : InStateString = "NetOp7";
      NetOp0      : InStateString = "NetOp0";
      NetOp10     : InStateString = "NetOp10";
      NetOp11     : InStateString = "NetOp11";
      NetOp8      : InStateString = "NetOp8";
      NetOp9      : InStateString = "NetOp9";
      NetOp1      : InStateString = "NetOp1";
      NetOp4      : InStateString = "NetOp4";
      NetOp5      : InStateString = "NetOp5";
      NetOp6      : InStateString = "NetOp6";
      NetOp2      : InStateString = "NetOp2";
      NetOp3      : InStateString = "NetOp3";
      NetOpMsg    : InStateString = "NetOpMsg";
      NetNack4    : InStateString = "NetNack4";
      NetNack5    : InStateString = "NetNack5";
      NetNack6    : InStateString = "NetNack6";
      NetNackVal  : InStateString = "NetNackVal";
      Eop         : InStateString = "Eop";
      default     : InStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      // Introductory states, where dispatch destination is found out
      Idle: begin
        if ( |vc_eligible )
          state_d = Peek0;
        else
          state_d = Idle;
        end

      Peek0: begin
          state_d = Peek2;
        end

      Peek2: begin
          if (i_nin_data[15:4] == i_ctl_addr_base) begin
            if (~is_read_q) begin
              if (((i_nin_data[3:0] == 4'hE) &        // Mailbox write access
                   (size_q > i_cmx_mbox_space)) ||
                  ((i_nin_data[3:0] == 4'hF) &        // Mailslot write access
                   ((size_q > 6'd2) || ~i_cmx_mslot_space))) begin
                if (has_ack_q)
                  state_d = NetNack4;
                else
                  state_d = Eop;
              end
              else 
                state_d = RegWr2;
            end
            else
              state_d = RegRd2;
          end
          else if (vc_q[0])
            state_d = WbAck0;
          else if (~is_read_q) 
            state_d = WrFill0;
          else if (i_netop_fifo_full) begin
            if (has_ack_q)
              state_d = NetNack4;
            else
              state_d = Eop;
          end
          else
            state_d = NetOp7;
        end

      // Write/Fill states. Address and data are pushed to Wrfill FIFO.
      //                    If ack is needed, it also pushed to the Wrfill
      //                    FIFO and it'll be done from there.
      WrFill0: begin
          state_d = WrFill2;
        end

      WrFill2: begin
          state_d = WrFill3;
        end

      WrFill3: begin
          state_d = WrFillData;
        end

      WrFillData: begin
          if (~offset_cnt_end)
            state_d = WrFillData;
          else if (has_ack_q)
            state_d = WrFill4;
          else
            state_d = Eop;
        end

      WrFill4: begin
          state_d = WrFill5;
        end

      WrFill5: begin
          state_d = WrFill6;
        end

      WrFill6: begin
          state_d = Eop;
        end

      // Register Write states. First, write is done to Regif. When it's done,
      //                        if ack is needed, we request it from the 
      //                        Ack interface.
      RegWr2: begin
          if (i_regif_stall)
            state_d = RegWr2;
          else
            state_d = RegWr3;
        end

      RegWr3: begin
          if (i_regif_stall)
            state_d = RegWr3;
          else
            state_d = RegWrData;
        end

      RegWrData: begin
          if (i_regif_stall | ~offset_cnt_end)
            state_d = RegWrData;
          else if (has_ack_q)
            state_d = RegWr4;
          else
            state_d = Eop;
        end

      RegWr4: begin
          if (i_ack_stall)
            state_d = RegWr4;
          else
            state_d = RegWr5;
        end

      RegWr5: begin
          if (i_ack_stall)
            state_d = RegWr5;
          else
            state_d = RegWr6;
        end

      RegWr6: begin
          if (i_ack_stall)
            state_d = RegWr6;
          else
            state_d = RegWrSize;
        end

      RegWrSize: begin
          if (i_ack_stall)
            state_d = RegWrSize;
          else
            state_d = Eop;
        end

      // Register Read states. We do to read from Regif and store the 2 words
      //                       result. When it's done, we reply using the Out
      //                       interface. If ack is needed, we also push its
      //                       address to the Out interface.
      RegRd2: begin
          if (i_regif_stall) 
            state_d = RegRd2;
          else
            state_d = RegRd3;
        end
      
      RegRd3: begin
          if (i_regif_stall) 
            state_d = RegRd3;
          else
            state_d = RegRdGetHi;
        end
      
      RegRdGetHi: begin
          if (i_regif_resp_valid) 
            state_d = RegRdGetLo;
          else
            state_d = RegRdGetHi;
        end
      
      RegRdGetLo: begin
          if (i_regif_resp_valid) 
            state_d = RegRdOpcode;
          else
            state_d = RegRdGetLo;
        end
      
      RegRdOpcode: begin
          if (i_out_stall) 
            state_d = RegRdOpcode;
          else
            state_d = RegRd7;
        end
      
      RegRd7: begin
          if (i_out_stall) 
            state_d = RegRd7;
          else
            state_d = RegRd8;
        end
      
      RegRd8: begin
          if (i_out_stall) 
            state_d = RegRd8;
          else
            state_d = RegRd9;
        end
      
      RegRd9: begin
          if (i_out_stall) 
            state_d = RegRd9;
          else if (has_ack_q)
            state_d = RegRd4;
          else
            state_d = RegRdPutHi;
        end
      
      RegRd4: begin
          if (i_out_stall) 
            state_d = RegRd4;
          else
            state_d = RegRd5;
        end
      
      RegRd5: begin
          if (i_out_stall) 
            state_d = RegRd5;
          else
            state_d = RegRd6;
        end
      
      RegRd6: begin
          if (i_out_stall) 
            state_d = RegRd6;
          else
            state_d = RegRdPutHi;
        end
      
      RegRdPutHi: begin
          if (i_out_stall) 
            state_d = RegRdPutHi;
          else
            state_d = RegRdPutLo;
        end
      
      RegRdPutLo: begin
          if (i_out_stall) 
            state_d = RegRdPutLo;
          else
            state_d = Eop;
        end

      // L2C Writeback Ack states. We simply guide the L2C WbAck pins here.
      WbAck0: begin
          state_d = WbAck2;
        end

      WbAck2: begin
          state_d = WbAck3;
        end

      WbAck3: begin
          if (i_l2c_wb_ack_stall)
            state_d = WbAck3;
          else
            state_d = Eop;
        end

      // Net Op FIFO states. We have already checked the FIFO has space,
      //                     so we push 16 words to it (the 4 last Message
      //                     words are garbage).
      NetOp7: begin
          state_d = NetOp0;
        end

      NetOp0: begin
          state_d = NetOp10;
        end

      NetOp10: begin
          state_d = NetOp11;
        end

      NetOp11: begin
          state_d = NetOp8;
        end

      NetOp8: begin
          state_d = NetOp9;
        end

      NetOp9: begin
          state_d = NetOp1;
        end

      NetOp1: begin
          state_d = NetOp4;
        end

      NetOp4: begin
          state_d = NetOp5;
        end

      NetOp5: begin
          state_d = NetOp6;
        end

      NetOp6: begin
          state_d = NetOp2;
        end

      NetOp2: begin
          state_d = NetOp3;
        end

      NetOp3: begin
          state_d = NetOpMsg;
        end

      NetOpMsg: begin
          if (offset_cnt_end)
            state_d = Eop;
          else
            state_d = NetOpMsg;
        end

      // Net Op Nack states. We send an Ack with value = 0.
      NetNack4: begin
          if (i_ack_stall)
            state_d = NetNack4;
          else
            state_d = NetNack5;
        end

      NetNack5: begin
          if (i_ack_stall)
            state_d = NetNack5;
          else
            state_d = NetNack6;
        end

      NetNack6: begin
          if (i_ack_stall)
            state_d = NetNack6;
          else
            state_d = NetNackVal;
        end

      NetNackVal: begin
          if (i_ack_stall)
            state_d = NetNackVal;
          else
            state_d = Eop;
        end

      // End of packet state
      Eop: begin
            state_d = Idle;
        end


      default:
        begin
          state_d = Idle;
        end

    endcase
  end


  // ==========================================================================
  // Introductory logic
  // ==========================================================================
  
  // VC 0 can be always handled
  assign vc_eligible[0] = ~i_nin_empty[0];

  // VC 1 may go to wrfill (e.g. fill) and/or create an ack (e.g. reg write)
  assign vc_eligible[1] = ~i_nin_empty[1] & (i_nout_packets_vc0 > 3'd2) &
                          ~i_wrfill_busy;

  // VC 2 may create a VC 1 response (e.g. if it's a reg read),
  // or it may go to wrfill (if it's a write) or even create a nack 
  // (e.g. netfifo full)
  assign vc_eligible[2] = ~i_nin_empty[2] & (i_nout_packets_vc1 > 3'd2) &
                          ~i_wrfill_busy & (i_nout_packets_vc0 > 3'd2);

  assign vc_d = (state_d != Peek0) ? vc_q :
                (vc_eligible[0])   ? 3'b001 :
                (vc_eligible[1])   ? 3'b010 :
                                     3'b100;

  assign is_read_d = (state_q == Peek0) ? i_nin_data[14] :
                                          is_read_q;

  assign has_ack_d = (state_q == Peek0) ? i_nin_data[9] :
                                          has_ack_q;

  assign size_d    = (state_q == Peek0)  ? i_nin_data[5:0] :
                     (state_q == NetOp7) ? 6'd3 :
                                           size_q;


  // ==========================================================================
  // Network Input interface
  // ==========================================================================
  assign o_nin_deq    =  (vc_q & {3{(state_q != Idle)}}) |
                         (vc_d & {3{(state_d == Peek0)}});

  assign o_nin_eop    =  (state_q == Eop);

  assign offset_cnt_d = (state_q == Idle)           ? 6'd6 :
                        ((state_d == WrFillData) |
                         ((state_d == RegWrData) &
                          ~i_regif_stall) |
                         (state_q == NetOpMsg))     ? offset_cnt_q + 1'b1 :
                                                      offset_cnt_q;

  assign offset_cnt_end = (offset_cnt_q == size_q + 6'd6);

  always @(*) begin
    case (state_d)

      Peek0,
      WrFill0,
      WbAck0,
      NetOp0     : o_nin_offset = 6'd0;

      NetOp1     : o_nin_offset = 6'd1;

      Peek2,
      WrFill2,
      RegWr2,
      RegRd2,
      WbAck2,
      NetOp2     : o_nin_offset = 6'd2;

      WrFill3,
      RegWr3,
      RegRd3,
      WbAck3,
      NetOp3     : o_nin_offset = 6'd3;

      WrFill4,
      RegWr4,
      RegRd4,
      NetOp4,
      NetNack4   : o_nin_offset = 6'd4;

      WrFill5,
      RegWr5,
      RegRd5,
      NetOp5,
      NetNack5   : o_nin_offset = 6'd5;

      WrFill6,
      RegWr6,
      RegRd6,
      NetOp6,
      NetNack6   : o_nin_offset = 6'd6;

      RegRd7,
      NetOp7     : o_nin_offset = 6'd7;

      RegRd8,
      NetOp8     : o_nin_offset = 6'd8;

      RegRd9,
      NetOp9     : o_nin_offset = 6'd9;

      NetOp10    : o_nin_offset = 6'd10;

      NetOp11    : o_nin_offset = 6'd11;

      WrFillData,
      RegWrData  : o_nin_offset = offset_cnt_d;

      default    : o_nin_offset = 6'bx;

    endcase
  end
                          
  
  // ==========================================================================
  // Write/Fill interface
  // ==========================================================================
  assign wrfill_valid_d = (state_d == WrFill0) ? 1'b1 :
                          (state_d == Eop)     ? 1'b0 :
                                                 wrfill_valid_q;

  assign o_wrfill_valid = wrfill_valid_q;

  assign o_wrfill_data = i_nin_data;
                                                 

  // ==========================================================================
  // WbAck interface
  // ==========================================================================
  assign wback_valid_d = (state_q == WbAck3) ? 1'b1 :
                         (state_q == Eop)    ? 1'b0 :
                                               wback_valid_q;

  assign wback_adr_d[31:16] = (state_q == WbAck2) ? i_nin_data :
                                                    wback_adr_q[31:16];
  assign wback_adr_d[15:0]  = (state_q == WbAck3) ? i_nin_data :
                                                    wback_adr_q[15:0];
  
  assign wback_fault_d = (state_q == WbAck0) ? i_nin_data[13] :
                                               wback_fault_q;

  assign o_l2c_wb_ack_valid = wback_valid_q;
  assign o_l2c_wb_ack_adr   = wback_adr_q;
  assign o_l2c_wb_ack_fault = wback_fault_q;

  
  // ==========================================================================
  // Regs interface
  // ==========================================================================
  assign o_regif_valid = (state_q == RegWr2) |
                         (state_q == RegWr3) |
                         (state_q == RegWrData) |
                         (state_q == RegRd2) |
                         (state_q == RegRd3);
  
  assign o_regif_data = ((state_q == RegWr2) |
                         (state_q == RegRd2))  ? { 1'b0, size_q, 
                                                   4'b1111, 
                                                   (state_q == RegWr2),
                                                   i_nin_data[3:0] } 
                                               : i_nin_data;

  // Temporary holding for Regif -> Out register access
  assign tmp0_d = (state_q == RegRdGetHi) ? i_regif_resp_data : tmp0_q;
  assign tmp1_d = (state_q == RegRdGetLo) ? i_regif_resp_data : tmp1_q;


  // ==========================================================================
  // Out interface
  // ==========================================================================
  assign out_valid_d = (state_d == RegRdOpcode) ? 1'b1 :
                       (state_d == Eop)         ? 1'b0 :
                                                 out_valid_q;
  
  assign o_out_data  = (state_q == RegRdOpcode) ? { 7'b0000010, 
                                                    4'b1111,
                                                    1'b1,
                                                    3'b0,
                                                    has_ack_q } :
                       (state_q == RegRdPutHi)  ? tmp0_q :
                       (state_q == RegRdPutLo)  ? tmp1_q :
                                                  i_nin_data;

  assign o_out_valid = out_valid_q;


  // ==========================================================================
  // Network Operation FIFO interface
  // ==========================================================================
  assign netop_valid_d = (state_d == NetOp7) ? 1'b1 :
                         (state_d == Eop)    ? 1'b0 :
                                               netop_valid_q;
  
  assign o_netop_fifo_wr_data = 
                (state_q == NetOp0) ? {i_nin_data[15:6], // don't cares
                                       1'b0,             // I bit -- FIXME
                                       i_nin_data[11],   // W bit
                                       i_nin_data[12],   // C bit
                                       i_nin_data[9],    // A bit
                                       2'b10} :          // DMA opcode
                                      i_nin_data;
                                                       
  assign o_netop_fifo_wr_en = netop_valid_q;


  // ==========================================================================
  // Ack interface
  // ==========================================================================
  assign ack_valid_d = ((state_d == NetNack4) |
                        (state_d == RegWr4))    ? 1'b1 :
                       (state_d == Eop)         ? 1'b0 :
                                                  ack_valid_q;
  
  assign o_ack_data = (state_q == RegWrSize)  ? {9'b0, size_q, 1'b0} :
                      (state_q == NetNackVal) ? 16'b0 :
                                                i_nin_data;
                                                       
  assign o_ack_valid = ack_valid_q;


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_ni) begin
    if (rst_ni) begin
      state_q           <= #`dh Idle;
      vc_q              <= #`dh 0;
      wrfill_valid_q    <= #`dh 0;
      out_valid_q       <= #`dh 0;
      netop_valid_q     <= #`dh 0;
      ack_valid_q       <= #`dh 0;
    end
    else begin
      state_q           <= #`dh state_d;
      vc_q              <= #`dh vc_d;
      wrfill_valid_q    <= #`dh wrfill_valid_d;
      out_valid_q       <= #`dh out_valid_d;
      netop_valid_q     <= #`dh netop_valid_d;
      ack_valid_q       <= #`dh ack_valid_d;
    end
  end

  always @(posedge clk_ni) begin
    has_ack_q           <= #`dh has_ack_d;
    is_read_q           <= #`dh is_read_d;
    size_q              <= #`dh size_d;
    offset_cnt_q        <= #`dh offset_cnt_d;
    wback_valid_q       <= #`dh wback_valid_d;
    wback_adr_q         <= #`dh wback_adr_d;
    wback_fault_q       <= #`dh wback_fault_d;
    tmp0_q              <= #`dh tmp0_d;
    tmp1_q              <= #`dh tmp1_d;
  end


endmodule
