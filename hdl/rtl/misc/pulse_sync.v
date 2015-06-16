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
// Abstract      : Asynchronous pulse synchronizer
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: pulse_sync.v,v $
// CVS revision  : $Revision: 1.2 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module pulse_sync (
  
  // Pulse input
  input   clk_in,
  input   rst_in,
  input   i_pulse,

  // Pulse output
  input   clk_out,
  input   rst_out,
  output  o_pulse
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  reg  pulse_in_q;
  wire pulse_in_d;
  reg  toggle_q;
  wire toggle_d;
  
  reg  toggle_sync0_q;
  wire toggle_sync0_d;
  reg  toggle_sync1_q;
  wire toggle_sync1_d;
  reg  toggle_sync2_q;
  wire toggle_sync2_d;
  reg  pulse_out_q;
  wire pulse_out_d;


  // ==========================================================================
  // Logic
  // ==========================================================================
  
  // Input side
  assign pulse_in_d = i_pulse;

  assign toggle_d = (i_pulse & ~pulse_in_q) ? ~toggle_q : toggle_q;

  // Synchronization point (false path)
  assign toggle_sync0_d = toggle_q;
  assign toggle_sync1_d = toggle_sync0_q;
  assign toggle_sync2_d = toggle_sync1_q;

  // Output side
  assign pulse_out_d = toggle_sync2_q ^ toggle_sync1_q;

  
  // ==========================================================================
  // Outputs
  // ==========================================================================
  assign o_pulse = pulse_out_q;
  

  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_in) begin
    if (rst_in) begin
      toggle_q       <= #`dh 0;
      pulse_in_q     <= #`dh 0;
    end
    else begin
      toggle_q       <= #`dh toggle_d;
      pulse_in_q     <= #`dh pulse_in_d;
    end
  end

  always @(posedge clk_out) begin
    if (rst_out) begin
      toggle_sync0_q <= #`dh 0;
      toggle_sync1_q <= #`dh 0;
      toggle_sync2_q <= #`dh 0;
      pulse_out_q    <= #`dh 0;
    end
    else begin
      toggle_sync0_q <= #`dh toggle_sync0_d;
      toggle_sync1_q <= #`dh toggle_sync1_d;
      toggle_sync2_q <= #`dh toggle_sync2_d;
      pulse_out_q    <= #`dh pulse_out_d;
    end
  end
  
endmodule
