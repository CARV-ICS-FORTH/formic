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
// Abstract      : MNI writeback interface
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni_wb.v,v $
// CVS revision  : $Revision: 1.4 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module mni_wb (

  // Clocks and resets
  input             clk_ni,
  input             rst_ni,

  // L2C Writeback Interface,
  output            o_l2c_wb_space,
  input             i_l2c_wb_valid,
  input      [31:0] i_l2c_wb_adr,
  input      [31:0] i_l2c_data,

  // Writeback FIFO interface
  output     [15:0] o_fifo_wr_data,
  output            o_fifo_wr_en,
  input      [15:0] i_fifo_rd_data,
  output            o_fifo_rd_en,

  // out interface
  output            o_out_valid,
  input             i_out_stall,
  output     [15:0] o_out_data
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire [31:0] adr_d;
  reg  [31:0] adr_q;

  wire  [4:0] cnt_d;
  reg   [4:0] cnt_q;
  wire        cnt_end;

  wire        wr_high_d;
  reg         wr_high_q;


  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle        = 6'b000001,
             AdrHigh     = 6'b000010,
             AdrLow      = 6'b000100,
             RepHigh     = 6'b001000,
             RepLow      = 6'b010000,
             Data        = 6'b100000;

  reg  [5:0] state_d;
  reg  [5:0] state_q;

  // synthesis translate_off
  reg [256:0] WbStateString;
  always @(state_q) begin
    case (state_q)
      Idle        : WbStateString = "Idle";
      AdrHigh     : WbStateString = "AdrHigh";
      AdrLow      : WbStateString = "AdrLow";
      RepHigh     : WbStateString = "RepHigh";
      RepLow      : WbStateString = "RepLow";
      Data        : WbStateString = "Data";
      default     : WbStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (i_l2c_wb_valid)
            state_d = AdrHigh;
          else
            state_d = Idle;
        end

      AdrHigh: begin
          if (i_out_stall)
            state_d = AdrHigh;
          else
            state_d = AdrLow;
        end

      AdrLow: begin
          if (i_out_stall)
            state_d = AdrLow;
          else
            state_d = RepHigh;
        end

      RepHigh: begin
          if (i_out_stall)
            state_d = RepHigh;
          else
            state_d = RepLow;
        end

      RepLow: begin
          if (i_out_stall)
            state_d = RepLow;
          else
            state_d = Data;
        end

      Data: begin
          if (i_out_stall | ~cnt_end)
            state_d = Data;
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
  // FIFO control
  // ==========================================================================
  assign wr_high_d = (state_d == Idle) ? 1'b1 :
                     (i_l2c_wb_valid)  ? ~wr_high_q :
                                         wr_high_q;

  assign o_fifo_wr_en   = i_l2c_wb_valid;

  assign o_fifo_wr_data = (wr_high_q) ? i_l2c_data[31:16] :
                                        i_l2c_data[15:0];

  assign o_fifo_rd_en = (state_q == Data) & ~i_out_stall;


  // ==========================================================================
  // Datapath
  // ==========================================================================
  assign adr_d = ((state_q == Idle) & i_l2c_wb_valid) ? i_l2c_wb_adr :
                                                        adr_q;

  assign cnt_d = (state_q == Idle)  ? 5'd0 :
                 (o_fifo_rd_en)     ? cnt_q + 1'b1 :
                                      cnt_q;

  assign cnt_end = (cnt_q == 5'd31);

  assign o_l2c_wb_space = (state_q == Idle);

  assign o_out_valid = ~(state_q == Idle);

  assign o_out_data = ((state_q == AdrHigh) |
                       (state_q == RepHigh))   ? adr_q[31:16] :
                      ((state_q == AdrLow) |
                       (state_q == RepLow))    ? adr_q[15:0] :
                                                 i_fifo_rd_data;

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
    wr_high_q           <= #`dh wr_high_d;
    adr_q               <= #`dh adr_d;
    cnt_q               <= #`dh cnt_d;
  end

endmodule
