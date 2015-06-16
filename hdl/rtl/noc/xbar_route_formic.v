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
// Abstract      : Crossbar routing function for Formic boards
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbar_route_formic.v,v $
// CVS revision  : $Revision: 1.2 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

// ==========================================================================
// Routing in Formic board crossbars
// ==========================================================================
// 
// Ports  0 -  7 are  MBS blocks
// Ports  8 - 15 are  GTP blocks
// Ports 16 - 20 are  TLB ports
// Port       21 is a BRD port
// 
// Therefore:
//
// Packet Board ID   Packet Node ID      Xbar Ouput Port
// ----------------------------------------------------------------------
//          remote       don't care  ->  route(board ID) [see below]
//          local             0 - 7  ->  0 - 7 (same as node ID)
//          local                12  ->  16 + round-robin cnt (0-4)
//          local                15  ->  21
// 
// GTP links:
//
// GTP0 -> y+1    [xbar port 8]
// GTP1 -> w+1    [xbar port 9]
// GTP2 -> z+1    [xbar port 10]
// GTP3 -> z-1    [xbar port 11]
// GTP4 -> x-1    [xbar port 12]
// GTP5 -> unused [xbar port 13]
// GTP6 -> y-1    [xbar port 14]
// GTP7 -> x+1    [xbar port 15]
//
// Routing function for remote Board IDs (priority-based):
//
//                          (dst X > my X) -> x+1 -> xbar port 15
//                          (dst X < my X) -> x-1 -> xbar port 12
//                  (X same, dst Y > my Y) -> y+1 -> xbar port 8
//                  (X same, dst Y < my Y) -> y-1 -> xbar port 14
//          (X same, Y same, dst Z > my Z) -> z+1 -> xbar port 10
//          (X same, Y same, dst Z < my Z) -> z-1 -> xbar port 11
// (X same, Y same, Z same, dst W != my W) -> w+1 -> xbar port 9

module xbar_route_formic (
  input        clk,
  input        i_diff_w,
  input        i_greater_x,
  input        i_smaller_x,
  input        i_greater_y,
  input        i_smaller_y,
  input        i_greater_z,
  input        i_smaller_z,
  input  [3:0] i_dst_node,
  output [4:0] o_port,
  output       o_mem
);

  reg [4:0] local_port;
  reg       local_mem;
  reg [4:0] port_d;
  reg [4:0] port_q;
  reg       mem_d;
  reg       mem_q;

  always @(*) begin
    if (i_dst_node < 4'd8) begin
      local_port <= {1'b0, i_dst_node};
      local_mem  <= 1'b0;
    end
    else if (i_dst_node == 4'd12) begin
      local_port <= 5'd16;
      local_mem  <= 1'b1;
    end
    else begin
      local_port <= 5'd21;
      local_mem  <= 1'b0;
    end
  end

  always @(*) begin
    if (i_greater_x) begin
      port_d <= 5'd15;
      mem_d  <= 1'b0;
    end
    else if (i_smaller_x) begin
      port_d <= 5'd12;
      mem_d  <= 1'b0;
    end
    else if (i_greater_y) begin
      port_d <= 5'd8;
      mem_d  <= 1'b0;
    end
    else if (i_smaller_y) begin
      port_d <= 5'd14;
      mem_d  <= 1'b0;
    end
    else if (i_greater_z) begin
      port_d <= 5'd10;
      mem_d  <= 1'b0;
    end
    else if (i_smaller_z) begin
      port_d <= 5'd11;
      mem_d  <= 1'b0;
    end
    else if (i_diff_w) begin
      port_d <= 5'd9;
      mem_d  <= 1'b0;
    end
    else begin
      port_d <= local_port;
      mem_d  <= local_mem;
    end
  end


  always @(posedge clk) begin
    port_q <= #`dh port_d;
    mem_q  <= #`dh mem_d;
  end

  assign o_port = port_q;
  assign o_mem  = mem_q;

endmodule
