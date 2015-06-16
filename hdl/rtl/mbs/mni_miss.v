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
// Abstract      : MNI miss handler
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni_miss.v,v $
// CVS revision  : $Revision: 1.6 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module mni_miss (

  // Clocks and resets
  input             clk_ni,
  input             rst_ni,

  // L2C Miss Interface
  input             i_l2c_miss_valid,
  input      [31:0] i_l2c_miss_adr,
  input       [1:0] i_l2c_miss_flags,
  input             i_l2c_miss_wen,
  input       [3:0] i_l2c_miss_ben,
  input      [31:0] i_l2c_miss_wdata,
  output            o_l2c_miss_stall,

  // regif interface
  output            o_regif_valid,
  input             i_regif_stall,
  output     [15:0] o_regif_data,
  input             i_regif_wr_accept,
  input             i_regif_resp_valid,
  input      [15:0] i_regif_resp_data,

  // wrfill interface
  output            o_wrfill_valid,
  input             i_wrfill_stall,
  output     [15:0] o_wrfill_data,

  // out interface
  output            o_out_valid,
  input             i_out_stall,
  output     [15:0] o_out_data
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire  [1:0] l2c_stall_d;
  reg   [1:0] l2c_stall_q;

  wire [15:0] data_d;
  reg  [15:0] data_q;
  wire [31:0] resp_data_d;
  reg  [31:0] resp_data_q;


  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle              = 19'b0000000000000000001,
             RegAdrHigh        = 19'b0000000000000000010,
             RegAdrLow         = 19'b0000000000000000100,
             RegWrDataHigh     = 19'b0000000000000001000,
             RegWrDataLow      = 19'b0000000000000010000,
             RegWrWaitAccept   = 19'b0000000000000100000,
             RegRdDataHigh     = 19'b0000000000001000000,
             RegRdDataLow      = 19'b0000000000010000000,
             FillAdrHigh       = 19'b0000000000100000000,
             FillAdrLow        = 19'b0000000001000000000,
             FillDataHigh      = 19'b0000000010000000000,
             FillDataLow       = 19'b0000000100000000000,
             OutOpcode         = 19'b0000001000000000000,
             OutAdrHigh        = 19'b0000010000000000000,
             OutAdrLow         = 19'b0000100000000000000,
             OutRepHigh        = 19'b0001000000000000000,
             OutRepLow         = 19'b0010000000000000000,
             OutDataHigh       = 19'b0100000000000000000,
             OutDataLow        = 19'b1000000000000000000;

  reg  [18:0] state_d;
  reg  [18:0] state_q;

  // synthesis translate_off
  reg [256:0] MissStateString;
  always @(state_q) begin
    case (state_q)
      Idle            : MissStateString = "Idle";
      RegAdrHigh      : MissStateString = "RegAdrHigh";
      RegAdrLow       : MissStateString = "RegAdrLow";
      RegWrDataHigh   : MissStateString = "RegWrDataHigh";
      RegWrDataLow    : MissStateString = "RegWrDataLow";
      RegWrWaitAccept : MissStateString = "RegWrWaitAccept";
      RegRdDataHigh   : MissStateString = "RegRdDataHigh";
      RegRdDataLow    : MissStateString = "RegRdDataLow";
      FillAdrHigh     : MissStateString = "FillAdrHigh";
      FillAdrLow      : MissStateString = "FillAdrLow";
      FillDataHigh    : MissStateString = "FillDataHigh";
      FillDataLow     : MissStateString = "FillDataLow";
      OutOpcode       : MissStateString = "OutOpcode";
      OutAdrHigh      : MissStateString = "OutAdrHigh";
      OutAdrLow       : MissStateString = "OutAdrLow";
      OutRepHigh      : MissStateString = "OutRepHigh";
      OutRepLow       : MissStateString = "OutRepLow";
      OutDataHigh     : MissStateString = "OutDataHigh";
      OutDataLow      : MissStateString = "OutDataLow";
      default         : MissStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (~i_l2c_miss_valid | ~o_l2c_miss_stall)
            state_d = Idle;
          else if (i_l2c_miss_flags[0]) 
            state_d = RegAdrHigh;
          else
            state_d = OutOpcode;
        end

      // Register interface access states
      RegAdrHigh: begin
          if (i_regif_stall)
            state_d = RegAdrHigh;
          else
            state_d = RegAdrLow;
        end

      RegAdrLow: begin
          if (i_regif_stall)
            state_d = RegAdrLow;
          else if (i_l2c_miss_wen)
            state_d = RegWrDataHigh;
          else
            state_d = RegRdDataHigh;
        end

      RegWrDataHigh: begin
          if (i_regif_stall)
            state_d = RegWrDataHigh;
          else
            state_d = RegWrDataLow;
        end

      RegWrDataLow: begin
          if (i_regif_stall)
            state_d = RegWrDataLow;
          else
            state_d = RegWrWaitAccept;
        end

      RegWrWaitAccept: begin
          if (~i_regif_wr_accept)
            state_d = RegWrWaitAccept;
          else
            state_d = Idle;
        end

      RegRdDataHigh: begin
          if (~i_regif_resp_valid)
            state_d = RegRdDataHigh;
          else
            state_d = RegRdDataLow;
        end

      RegRdDataLow: begin
          if (~i_regif_resp_valid)
            state_d = RegRdDataLow;
          else
            state_d = FillAdrHigh;
        end

      // Write/Fill interface states
      FillAdrHigh: begin
          if (i_wrfill_stall)
            state_d = FillAdrHigh;
          else
            state_d = FillAdrLow;
        end

      FillAdrLow: begin
          if (i_wrfill_stall)
            state_d = FillAdrLow;
          else
            state_d = FillDataHigh;
        end

      FillDataHigh: begin
          if (i_wrfill_stall)
            state_d = FillDataHigh;
          else
            state_d = FillDataLow;
        end

      FillDataLow: begin
          if (i_wrfill_stall)
            state_d = FillDataLow;
          else
            state_d = Idle;
        end

      // Output interface states
      OutOpcode: begin
          if (i_out_stall)
            state_d = OutOpcode;
          else
            state_d = OutAdrHigh;
        end

      OutAdrHigh: begin
          if (i_out_stall)
            state_d = OutAdrHigh;
          else
            state_d = OutAdrLow;
        end

      OutAdrLow: begin
          if (i_out_stall)
            state_d = OutAdrLow;
          else
            state_d = OutRepHigh;
        end

      OutRepHigh: begin
          if (i_out_stall)
            state_d = OutRepHigh;
          else
            state_d = OutRepLow;
        end

      OutRepLow: begin
          if (i_out_stall)
            state_d = OutRepLow;
          else if (i_l2c_miss_wen & ~i_l2c_miss_flags[1])
            state_d = OutDataHigh;
          else
            state_d = Idle;
        end

      OutDataHigh: begin
          if (i_out_stall)
            state_d = OutDataHigh;
          else
            state_d = OutDataLow;
        end

      OutDataLow: begin
          if (i_out_stall)
            state_d = OutDataLow;
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

  // L2C interface
  assign l2c_stall_d = {((state_d == Idle) & 
                         (state_q != Idle) & 
                         (state_q != FillDataLow)) | 
                        ((state_d == FillDataHigh) &
                         (state_q == FillAdrLow)), 
                        l2c_stall_q[1]};

  assign o_l2c_miss_stall = ~ (|l2c_stall_q);


  // Registers interface
  assign data_d = ((state_d == RegAdrHigh) |
                   (state_d == OutOpcode))     ? {1'b0, // High 7 bits are 
                                                        // 7'd32 or 7'd2
                                                  i_l2c_miss_flags[1],
                                                  3'b0,
                                                  ~i_l2c_miss_flags[1],
                                                  1'b0,
                                                  i_l2c_miss_ben, 
                                                  i_l2c_miss_wen,
                                                  i_l2c_miss_adr[19:16]} :
                  ((state_d == OutAdrHigh) |
                   (state_d == OutRepHigh) |
                   (state_d == FillAdrHigh))   ? i_l2c_miss_adr[31:16] :
                  ((state_d == OutAdrLow) |    
                   (state_d == OutRepLow) |    
                   (state_d == RegAdrLow) |    
                   (state_d == FillAdrLow))    ? i_l2c_miss_adr[15:0] :
                  ((state_d == OutDataHigh) |
                   (state_d == RegWrDataHigh)) ? i_l2c_miss_wdata[31:16] :
                  ((state_d == OutDataLow) |
                   (state_d == RegWrDataLow))  ? i_l2c_miss_wdata[15:0] :
                  (state_d == FillDataHigh)    ? resp_data_q[31:16] :
                  (state_d == FillDataLow)     ? resp_data_q[15:0] :
                                                 data_q;

  assign resp_data_d[31:16] = ((state_q == RegRdDataHigh) & 
                               i_regif_resp_valid)         ? i_regif_resp_data :
                                                             resp_data_q[31:16];
  assign resp_data_d[15:0]  = ((state_q == RegRdDataLow) & 
                               i_regif_resp_valid)         ? i_regif_resp_data :
                                                             resp_data_q[15:0];

  
  assign o_regif_valid = ((state_q == RegAdrHigh) | 
                          (state_q == RegAdrLow) |
                          (state_q == RegWrDataHigh) |
                          (state_q == RegWrDataLow));

  assign o_regif_data  = data_q;


  // Write/fill interface
  assign o_wrfill_valid = ((state_q == FillAdrHigh) | 
                           (state_q == FillAdrLow) |
                           (state_q == FillDataHigh) |
                           (state_q == FillDataLow));

  assign o_wrfill_data  = data_q;


  // Output interface
  assign o_out_valid = ((state_q == OutOpcode) | 
                        (state_q == OutAdrHigh) |
                        (state_q == OutAdrLow) |
                        (state_q == OutDataHigh) |
                        (state_q == OutDataLow));

  assign o_out_data  = data_q;


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
    l2c_stall_q         <= #`dh l2c_stall_d;
    data_q              <= #`dh data_d;
    resp_data_q         <= #`dh resp_data_d;
  end

endmodule
