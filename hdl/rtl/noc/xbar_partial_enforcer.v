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
// Abstract      : Crossbar priority enforcer of 22 requests in 3 segments
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbar_partial_enforcer.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbar_partial_enforcer (
  
  // Clock and reset
  input         clk,
  input         rst,

  // Requests to be prioritized
  input  [21:0] i_req,

  // Prioritized outputs (in 1/3 segments)
  output        o_winner_found,
  output  [7:0] o_winner,
  output  [1:0] o_third
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  wire  [1:0] third_d;
  reg   [1:0] third_q;
  wire  [7:0] third_mux;
  wire  [7:0] masked;
  wire  [7:0] winner_d;
  reg   [7:0] winner_q;
  wire        winner_found_d;
  reg         winner_found_q;
  wire  [7:0] mask_d;
  reg   [7:0] mask_q;


  // ==========================================================================
  // Logic
  // ==========================================================================
  assign third_mux =         i_req[7:0]    & {8{(third_q == 2'b00)}} |
                             i_req[15:8]   & {8{(third_q == 2'b01)}} |
                     {2'b00, i_req[21:16]} & {8{(third_q == 2'b10)}};

  assign masked = third_mux & mask_q;
  
  assign winner_d = (masked[0]) ? 8'b00000001 :
                    (masked[1]) ? 8'b00000010 :
                    (masked[2]) ? 8'b00000100 :
                    (masked[3]) ? 8'b00001000 :
                    (masked[4]) ? 8'b00010000 :
                    (masked[5]) ? 8'b00100000 :
                    (masked[6]) ? 8'b01000000 :
                    (masked[7]) ? 8'b10000000 :
                                  8'b00000000;
  
  assign mask_d =   (masked[0]) ? 8'b11111111 :
                    (masked[1]) ? 8'b11111110 :
                    (masked[2]) ? 8'b11111100 :
                    (masked[3]) ? 8'b11111000 :
                    (masked[4]) ? 8'b11110000 :
                    (masked[5]) ? 8'b11100000 :
                    (masked[6]) ? 8'b11000000 :
                    (masked[7]) ? 8'b10000000 :
                                  8'b11111111;  

  assign winner_found_d = | masked;

  assign third_d = (winner_found_d) ? third_q :
                   (third_q == 2'b10) ? 2'b00 :
                                        (third_q + 1'b1);



  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk) begin
    if (rst) begin
      third_q           <= #`dh 2'b00;
      winner_found_q    <= #`dh 0;
      mask_q            <= #`dh 8'b11111111;
    end
    else begin
      third_q           <= #`dh third_d;
      winner_found_q    <= #`dh winner_found_d;
      mask_q            <= #`dh mask_d;
    end
  end
  
  always @(posedge clk) begin
    winner_q            <= #`dh winner_d;
  end


  // ==========================================================================
  // Outputs
  // ==========================================================================
  assign o_winner_found = winner_found_q;
  assign o_winner       = winner_q;
  assign o_third        = third_q;

endmodule


