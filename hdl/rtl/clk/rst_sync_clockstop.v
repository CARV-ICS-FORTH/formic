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
// Abstract      : Reset synchronizer with clock-stopping capability
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rst_sync_clockstop.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rst_sync_clockstop # (

  parameter DEASSERT_CLOCK_CYCLES = 8,  // Counted on clk
  parameter STOP_CLOCK_CYCLES = 4'd8       // Counted on clk_always_on

) (
  
  // Stable clock, assumed slower than clk
  input     clk_always_on,
  
  // Target reset interface
  input     clk,
  output    clk_en,
  input     rst_async,
  input     deassert,
  output    rst
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  reg  [(DEASSERT_CLOCK_CYCLES-1):0] rst_sync_q;
  reg                                stop_clock_q;
  wire                         [2:0] stop_clock_sync_d;
  reg                          [2:0] stop_clock_sync_q;
  wire                         [3:0] wait_cnt_d;
  reg                          [3:0] wait_cnt_q;
  wire                               clk_enable_d;
  reg                                clk_enable_q;
  wire                               rst_d;
  reg                                rst_q;


  // ==========================================================================
  // Delay from deassertion of reset up to DEASSERT_CLOCK_CYCLES
  // ==========================================================================
  always @(posedge clk or posedge rst_async) begin
    if (rst_async) begin
      rst_sync_q   <= 0;
      stop_clock_q <= 0;
    end
    else begin
      rst_sync_q[(DEASSERT_CLOCK_CYCLES-1)]   <= deassert;
      rst_sync_q[(DEASSERT_CLOCK_CYCLES-2):0] <= 
         rst_sync_q[(DEASSERT_CLOCK_CYCLES-1):1];
      stop_clock_q <= & rst_sync_q;
    end
  end

  assign stop_clock_sync_d[2] = stop_clock_q;
  assign stop_clock_sync_d[1:0] = stop_clock_sync_q[2:1];
  
  
  // ==========================================================================
  // Clock enable FSM
  // ==========================================================================
  localparam ResetActive = 5'b0_0001,
             StopClk     = 5'b0_0010,
             Wait        = 5'b0_0100,
             StartClk    = 5'b0_1000,
             Idle        = 5'b1_0000;

  reg  [4:0] state_d;
  reg  [4:0] state_q;

  // synthesis translate_off
  reg [256:0] StateString;
  always @(state_q) begin
    case (state_q)
      ResetActive : StateString = "ResetActive";
      StopClk     : StateString = "StopClk";
      Wait        : StateString = "Wait";
      StartClk    : StateString = "StartClk";
      Idle        : StateString = "Idle";
      default     : StateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      ResetActive: begin
          if (stop_clock_sync_q[0])
            state_d = StopClk;
          else 
            state_d = ResetActive;
        end

      StopClk: begin
          state_d = Wait;
        end

      Wait: begin
          if (wait_cnt_q == 0)
            state_d = StartClk;
          else 
            state_d = Wait;
        end

      StartClk: begin
          state_d = Idle;
        end

      Idle: begin
          state_d = Idle;
        end

      default:
        begin
          state_d = Idle;
        end
    endcase
  end

  // ==========================================================================
  // Delay from stopping of clk of up to STOP_CLOCK_CYCLES
  // ==========================================================================
  assign wait_cnt_d = (state_q == StopClk) ? STOP_CLOCK_CYCLES :
                      (state_q == Wait) ? wait_cnt_q - 4'b1 :
                      wait_cnt_q;

  // ==========================================================================
  // Clock enable and reset
  // ==========================================================================
  assign clk_enable_d = ~((state_d == StopClk) | 
                          (state_d == Wait) | (state_q == Wait));

  assign rst_d = (state_q == StopClk) ? 1'b0 : rst_q;


  assign clk_en = clk_enable_q;
  assign rst = rst_q;

  // ==========================================================================
  // clk_always_on registers
  // ==========================================================================
  always @(posedge clk_always_on or posedge rst_async) begin
    if (rst_async) begin
      state_q           <= ResetActive;
      stop_clock_sync_q <= 0;
      clk_enable_q      <= 1'b1;
      rst_q             <= 1'b1;
    end
    else begin
      state_q           <= state_d;
      stop_clock_sync_q <= stop_clock_sync_d;
      wait_cnt_q        <= wait_cnt_d;
      clk_enable_q      <= clk_enable_d;
      rst_q             <= rst_d;
    end
  end

endmodule
