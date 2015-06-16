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
// Abstract      : MNI write & fill interfaces
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni_wrfill.v,v $
// CVS revision  : $Revision: 1.9 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module mni_wrfill (

  // Clocks and resets
  input             clk_ni,
  input             rst_ni,

  // L2C Write Interface
  output            o_l2c_write_valid,
  output     [31:0] o_l2c_write_adr,
  output            o_l2c_write_dirty,
  input             i_l2c_write_stall,
  input             i_l2c_write_nack,
  input             i_l2c_write_done,

  // L2C Fill Interface
  output            o_l2c_fill_valid,
  output            o_l2c_fill_fault,
  output      [3:0] o_l2c_fill_len,
  output     [31:0] o_l2c_fill_adr,
  input             i_l2c_fill_stall,

  // L2C Common Data Busses
  output     [31:0] o_l2c_data,

  // Write/Fill distributed memory interface
  output     [15:0] o_dmem_wr_data,
  output      [5:0] o_dmem_wr_adr,
  output            o_dmem_wr_en,
  output      [5:0] o_dmem_rd_adr,
  input      [15:0] i_dmem_rd_data,

  // in interface
  output            o_in_busy,
  input             i_in_valid,
  input      [15:0] i_in_data,

  // miss interface
  input             i_miss_valid,
  output            o_miss_stall,
  input      [15:0] i_miss_data,

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
  wire  [5:0] rcv_cnt_d;
  reg   [5:0] rcv_cnt_q;
  wire        rcv_busy_d;
  reg         rcv_busy_q;

  wire        has_ack_d;
  reg         has_ack_q;
  wire        has_w_d;
  reg         has_w_q;
  wire        has_c_d;
  reg         has_c_q;
  wire        fault_d;
  reg         fault_q;
  wire        is_fill_d;
  reg         is_fill_q;
  wire        is_dirty_d;
  reg         is_dirty_q;
  wire        size_cache_line_d;
  reg         size_cache_line_q;
  wire        fill_valid_d;
  reg         fill_valid_q;
  wire        write_valid_d;
  reg         write_valid_q;

  wire        stall;
  
  wire  [5:0] send_cnt_d;
  reg   [5:0] send_cnt_q;
  wire        send_cnt_end;

  wire [31:0] adr_d;
  reg  [31:0] adr_q;
  wire [31:0] data_d;
  reg  [31:0] data_q;



  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle              = 24'b000000000000000000000001,
             FifoOpcode        = 24'b000000000000000000000010,
             FifoCacheAdrHigh  = 24'b000000000000000000000100,
             FifoCacheAdrLow   = 24'b000000000000000000001000,
             FifoCacheInitHigh = 24'b000000000000000000010000,
             FifoCacheInitLow  = 24'b000000000000000000100000,
             FifoCacheData     = 24'b000000000000000001000000,
             FifoWaitRcv       = 24'b000000000000000010000000,
             FifoWaitWriteDone = 24'b000000000000000100000000,
             FifoOutOpcode     = 24'b000000000000001000000000,
             FifoOutAdrHigh    = 24'b000000000000010000000000,
             FifoOutAdrLow     = 24'b000000000000100000000000,
             FifoOutAckNode    = 24'b000000000001000000000000,
             FifoOutAckHigh    = 24'b000000000010000000000000,
             FifoOutAckLow     = 24'b000000000100000000000000,
             FifoOutData       = 24'b000000001000000000000000,
             FifoAckNode       = 24'b000000010000000000000000,
             FifoAckHigh       = 24'b000000100000000000000000,
             FifoAckLow        = 24'b000001000000000000000000,
             MissAdrHigh       = 24'b000010000000000000000000,
             MissAdrLow        = 24'b000100000000000000000000,
             MissDataHigh      = 24'b001000000000000000000000,
             MissDataLow       = 24'b010000000000000000000000,
             ClrBusy           = 24'b100000000000000000000000;

  reg  [23:0] state_d;
  reg  [23:0] state_q;

  // synthesis translate_off
  reg [256:0] WrfillStateString;
  always @(state_q) begin
    case (state_q)
      Idle              : WrfillStateString = "Idle";
      FifoOpcode        : WrfillStateString = "FifoOpcode";
      FifoCacheAdrHigh  : WrfillStateString = "FifoCacheAdrHigh";
      FifoCacheAdrLow   : WrfillStateString = "FifoCacheAdrLow";
      FifoCacheInitHigh : WrfillStateString = "FifoCacheInitHigh";
      FifoCacheInitLow  : WrfillStateString = "FifoCacheInitLow";
      FifoCacheData     : WrfillStateString = "FifoCacheData";
      FifoWaitRcv       : WrfillStateString = "FifoWaitRcv";
      FifoWaitWriteDone : WrfillStateString = "FifoWaitWriteDone";
      FifoOutOpcode     : WrfillStateString = "FifoOutOpcode";
      FifoOutAdrHigh    : WrfillStateString = "FifoOutAdrHigh";
      FifoOutAdrLow     : WrfillStateString = "FifoOutAdrLow";
      FifoOutAckNode    : WrfillStateString = "FifoOutAckNode";
      FifoOutAckHigh    : WrfillStateString = "FifoOutAckHigh";
      FifoOutAckLow     : WrfillStateString = "FifoOutAckLow";
      FifoOutData       : WrfillStateString = "FifoOutData";
      FifoAckNode       : WrfillStateString = "FifoAckNode";
      FifoAckHigh       : WrfillStateString = "FifoAckHigh";
      FifoAckLow        : WrfillStateString = "FifoAckLow";
      MissAdrHigh       : WrfillStateString = "MissAdrHigh";
      MissAdrLow        : WrfillStateString = "MissAdrLow";
      MissDataHigh      : WrfillStateString = "MissDataHigh";
      MissDataLow       : WrfillStateString = "MissDataLow";
      ClrBusy           : WrfillStateString = "ClrBusy";
      default           : WrfillStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (i_miss_valid)
            state_d = MissAdrHigh;
          else if (rcv_busy_q)
            state_d = FifoOpcode;
          else
            state_d = Idle;
        end

      FifoOpcode: begin
          state_d = FifoCacheAdrHigh;
        end

      // FIFO -> Cache states
      FifoCacheAdrHigh: begin
          state_d = FifoCacheAdrLow;
        end

      FifoCacheAdrLow: begin
          state_d = FifoCacheInitHigh;
        end

      FifoCacheInitHigh: begin
          state_d = FifoCacheInitLow;
        end

      FifoCacheInitLow: begin
          if (stall)
            state_d = FifoCacheInitLow;
          else if (~is_fill_q & i_l2c_write_nack)
            state_d = FifoWaitRcv;
          else if (size_cache_line_q)
            state_d = FifoCacheData;
          else if (has_w_q) 
            state_d = FifoOutOpcode;
          else if (has_ack_q)
            state_d = FifoAckNode;
          else
            state_d = ClrBusy;
        end

      FifoCacheData: begin
          if (~send_cnt_end)
            state_d = FifoCacheData;
          else if (has_w_q) 
            state_d = FifoOutOpcode;
          else if (has_ack_q)
            state_d = FifoWaitWriteDone;
          else
            state_d = ClrBusy;
        end

      FifoWaitWriteDone: begin
          if (~i_l2c_write_done) 
            state_d = FifoWaitWriteDone;
          else
            state_d = FifoAckNode;
        end

      FifoWaitRcv: begin
          if (rcv_cnt_q < 6'd35) 
            state_d = FifoWaitRcv;
          else begin
            if (~has_c_q)
              state_d = FifoOutOpcode;
            else if (has_ack_q)
              state_d = FifoAckNode;
            else
              state_d = ClrBusy;
          end
        end

      
      // FIFO -> Out states
      FifoOutOpcode: begin
          if (i_out_stall)
            state_d = FifoOutOpcode;
          else
            state_d = FifoOutAdrHigh;
        end

      FifoOutAdrHigh: begin
          if (i_out_stall)
            state_d = FifoOutAdrHigh;
          else
            state_d = FifoOutAdrLow;
        end

      FifoOutAdrLow: begin
          if (i_out_stall)
            state_d = FifoOutAdrLow;
          else if (has_ack_q)
            state_d = FifoOutAckNode;
          else
            state_d = FifoOutData;
        end

      FifoOutAckNode: begin
          if (i_out_stall)
            state_d = FifoOutAckNode;
          else
            state_d = FifoOutAckHigh;
        end

      FifoOutAckHigh: begin
          if (i_out_stall)
            state_d = FifoOutAckHigh;
          else
            state_d = FifoOutAckLow;
        end

      FifoOutAckLow: begin
          if (i_out_stall)
            state_d = FifoOutAckLow;
          else
            state_d = FifoOutData;
        end

      FifoOutData: begin
          if (i_out_stall | ~send_cnt_end)
            state_d = FifoOutData;
          else
            state_d = ClrBusy;
        end
      
      // FIFO -> Ack states
      FifoAckNode: begin
          if (i_ack_stall)
            state_d = FifoAckNode;
          else
            state_d = FifoAckHigh;
        end

      FifoAckHigh: begin
          if (i_ack_stall)
            state_d = FifoAckHigh;
          else
            state_d = FifoAckLow;
        end

      FifoAckLow: begin
          if (i_ack_stall)
            state_d = FifoAckLow;
          else
            state_d = ClrBusy;
        end

      // Miss states
      MissAdrHigh: begin
          state_d = MissAdrLow;
        end

      MissAdrLow: begin
          state_d = MissDataHigh;
        end

      MissDataHigh: begin
          state_d = MissDataLow;
        end

      MissDataLow: begin
          if (i_l2c_fill_stall)
            state_d = MissDataLow;
          else
            state_d = Idle;
        end

      // Busy bit clearing
      ClrBusy: begin
          state_d = Idle;
        end


      default:
        begin
          state_d = Idle;
        end

    endcase
  end


  // ==========================================================================
  // Distributed memory FIFO
  // ==========================================================================
  assign rcv_cnt_d = (~rcv_busy_d) ? 6'b0 :
                     (i_in_valid)  ? rcv_cnt_q + 1'b1 :
                                     rcv_cnt_q;

  assign rcv_busy_d = (i_in_valid)         ? 1'b1 :
                      (state_q == ClrBusy) ? 1'b0 : // return to Idle from 
                                                    // any FIFO state
                                             rcv_busy_q;

  // Outputs
  assign o_dmem_wr_data = i_in_data;
  assign o_dmem_wr_adr  = rcv_cnt_q;
  assign o_dmem_wr_en   = i_in_valid;

  assign o_dmem_rd_adr = 
    ((state_q == FifoCacheAdrHigh) |
     (state_q == FifoOutAdrHigh))    ? 6'd1 :
    ((state_q == FifoCacheAdrLow) |
     (state_q == FifoOutAdrLow))     ? 6'd2 :
    (state_q == FifoCacheInitHigh)   ? 6'd3 :
    (state_q == FifoCacheInitLow)    ? 6'd4 :
    ((state_q == FifoCacheData) |
     (state_q == FifoOutData))       ? send_cnt_q :
    ((state_q == FifoOutAckNode) |
     (state_q == FifoAckNode))       ? ((size_cache_line_q) ? 6'd35 : 6'd3) :
    ((state_q == FifoOutAckHigh) |
     (state_q == FifoAckHigh))       ? ((size_cache_line_q) ? 6'd36 : 6'd4) :
    ((state_q == FifoOutAckLow) |
     (state_q == FifoAckLow))        ? ((size_cache_line_q) ? 6'd37 : 6'd5) :
                                       6'd0;

  assign o_in_busy = rcv_busy_q;

  
  // ==========================================================================
  // Opcode decoding
  // ==========================================================================
  assign has_ack_d  = (state_q == FifoOpcode)  ? i_dmem_rd_data[9] :
                                                 has_ack_q;

  assign is_fill_d  = (state_q == FifoOpcode)  ? ~i_dmem_rd_data[10] :
                      (state_q == MissAdrHigh) ? 1'b0 :
                                                 is_fill_q;

  assign is_dirty_d = (state_q == FifoOpcode)  ? ~i_dmem_rd_data[12] :
                                                 is_dirty_q;

  assign has_w_d    = (state_q == FifoOpcode)  ? i_dmem_rd_data[11] :
                                                 has_w_q;

  assign has_c_d    = (state_q == FifoOpcode)  ? i_dmem_rd_data[12] :
                                                 has_c_q;
  
  assign fault_d    = (state_q == FifoOpcode)  ? i_dmem_rd_data[13] :
                      (state_q == MissAdrHigh) ? 1'b0 :
                                                 fault_q;
  
  // Expected sizes are 2'b10 (=1 32b word) and 6'b100000 (=16 32b words)
  assign size_cache_line_d = (state_q == FifoOpcode) ? ~(i_dmem_rd_data[1:0] == 
                                                         2'b10) :
                             (state_q == MissAdrHigh) ? 1'b0 :
                                                        size_cache_line_q;


  // ==========================================================================
  // Fill/Write L2C side
  // ==========================================================================
  assign stall = ( is_fill_q & i_l2c_fill_stall) | 
                 (~is_fill_q & i_l2c_write_stall);

  assign send_cnt_d = (state_q == FifoCacheInitLow)   ? 6'd5 :
                      (state_q == FifoOutAdrLow)      ? 6'd3 :
                      ((state_q == FifoCacheData) |
                       (state_q == FifoOutData))      ? send_cnt_q + 1'b1 :
                                                        send_cnt_q;

  assign send_cnt_end = ( size_cache_line_q & (send_cnt_q == 6'd34)) |
                        (~size_cache_line_q & (send_cnt_q == 6'd4));


  assign adr_d[31:16] = (state_q == FifoCacheAdrHigh) ? i_dmem_rd_data : 
                        (state_q == MissAdrHigh)      ? i_miss_data : 
                                                        adr_q[31:16];
  assign adr_d[15:0]  = (state_q == FifoCacheAdrLow)  ? i_dmem_rd_data : 
                        (state_q == MissAdrLow)       ? i_miss_data : 
                                                        adr_q[15:0];
  
  assign data_d[31:16] = ((state_q == FifoCacheInitHigh) |
                          ((state_q == FifoCacheData) &
                           send_cnt_q[0]))                 ? i_dmem_rd_data : 
                        (state_q == MissDataHigh)          ? i_miss_data : 
                                                             data_q[31:16];

  assign data_d[15:0]  = ((state_q == FifoCacheInitLow) |
                          ((state_q == FifoCacheData) &
                          ~send_cnt_q[0]))                 ? i_dmem_rd_data : 
                        (state_q == MissDataLow)           ? i_miss_data : 
                                                             data_q[15:0];

                                                                       
  assign fill_valid_d  = (is_fill_q & (state_q == FifoCacheInitLow)) |
                         (state_q == MissDataLow);

  assign write_valid_d = ~is_fill_q & (state_q == FifoCacheInitLow);


  // Outputs
  assign o_l2c_fill_valid  = fill_valid_q;
  assign o_l2c_fill_adr    = adr_q;
  assign o_l2c_fill_len    = {4{size_cache_line_q}}; // 4'b1111 or 4'b0000
  assign o_l2c_fill_fault  = fault_q;

  assign o_l2c_write_valid = write_valid_q;
  assign o_l2c_write_adr   = adr_q;
  assign o_l2c_write_dirty = is_dirty_q;
  
  assign o_l2c_data        = data_q;


  // ==========================================================================
  // MNI interfaces
  // ==========================================================================

  // miss interface
  assign o_miss_stall = ~((state_q == MissAdrHigh) | 
                          (state_q == MissAdrLow) |
                          (state_q == MissDataHigh) | 
                          ((state_q == MissDataLow) & ~i_l2c_fill_stall));

  // ack interface
  assign o_ack_valid = ((state_q == FifoAckNode) | 
                        (state_q == FifoAckHigh) |
                        (state_q == FifoAckLow));

  assign o_ack_data = i_dmem_rd_data;
  
  // out interface
  assign o_out_valid = ((state_q == FifoOutOpcode) | 
                        (state_q == FifoOutAdrHigh) |
                        (state_q == FifoOutAdrLow) |
                        (state_q == FifoOutAckNode) | 
                        (state_q == FifoOutAckHigh) |
                        (state_q == FifoOutAckLow) |
                        (state_q == FifoOutData));

  assign o_out_data = (state_q == FifoOutOpcode) ? {i_dmem_rd_data[15:2],
                                                    has_ack_q,
                                                    i_dmem_rd_data[0]} :
                                                   i_dmem_rd_data;
                                                   // Only bit 1 is significant
                                                   // during FifoOutOpcode


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_ni) begin
    if (rst_ni) begin
      state_q           <= #`dh Idle;
      rcv_busy_q        <= #`dh 0;
    end
    else begin
      state_q           <= #`dh state_d;
      rcv_busy_q        <= #`dh rcv_busy_d;
    end
  end
  
  always @(posedge clk_ni) begin
    rcv_cnt_q           <= #`dh rcv_cnt_d;
    has_ack_q           <= #`dh has_ack_d;
    has_w_q             <= #`dh has_w_d;
    has_c_q             <= #`dh has_c_d;
    fault_q             <= #`dh fault_d;
    is_fill_q           <= #`dh is_fill_d;
    is_dirty_q          <= #`dh is_dirty_d;
    size_cache_line_q   <= #`dh size_cache_line_d;
    send_cnt_q          <= #`dh send_cnt_d;
    adr_q               <= #`dh adr_d;
    data_q              <= #`dh data_d;
    fill_valid_q        <= #`dh fill_valid_d;
    write_valid_q       <= #`dh write_valid_d;
  end

endmodule
