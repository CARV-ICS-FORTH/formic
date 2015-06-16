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
// Author        : George Kalokerinos
// Abstract      : L2C read interface
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_read.v,v $
// CVS revision  : $Revision: 1.10 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_read
//
module l2c_read(
   input             Clk,
   input             Reset,
//
   input             i_maintenance_active,
   input      [31:0] i_mni_read_adr,
   input             i_mni_read_valid,
   input             i_hit,
   input             i_retry,
   input             i_wb_ack_broadcast,
   input             i_fill_broadcast,
   input             i_write_broadcast,
   input             i_miss,
   input      [ 2:0] i_way,
   input             i_start,
   input             i_end,
   output            o_read_idle,
   output            o_tag_req,
   output     [17:0] o_sram_adr,
   output            o_mni_read_stall,
   output            o_mni_read_nack);
// Tag FSM Parameters
parameter Idle      = 7'b000_0001,
          Tags      = 7'b000_0010,
          Retry     = 7'b000_0100,
          SRAM      = 7'b000_1000,
          Access    = 7'b001_0000,
          Unlock    = 7'b010_0000,
          Nack      = 7'b100_0000;
//
reg  [6:0] ReadState;
//
// synthesis translate_off
reg [256:0] ReadStateString;
always @(ReadState) begin
  case (ReadState)
    Idle      : ReadStateString = "Idle";
    Tags      : ReadStateString = "Tags";
    Retry     : ReadStateString = "Retry";
    SRAM      : ReadStateString = "SRAM";
    Access    : ReadStateString = "Access";
    Unlock    : ReadStateString = "Unlock";
    Nack      : ReadStateString = "Nack";
    default   : ReadStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
// way
//
 reg [ 2:0] way;
 wire       way_ld = (ReadState==Tags) & (i_hit | i_miss);
//
 always @(posedge Clk)
    if(way_ld) way <= #`dh i_way;
//
// FSM
//
 always @(posedge Clk) begin
    if(Reset) ReadState <= #`dh Idle;
    else begin
       case(ReadState)
//
       Idle    : begin
                    if(i_mni_read_valid &~i_maintenance_active)
                         ReadState <= #`dh Tags;
                    else ReadState <= #`dh Idle;
                 end
//
       Tags    : begin
                    if(i_hit)
                         ReadState <= #`dh SRAM;
                    else if(i_miss)
                         ReadState <= #`dh Nack;
                    else if(i_retry)
                         ReadState <= #`dh Retry;
                    else ReadState <= #`dh Tags;
                 end
//
       Retry   : begin
                    if(i_wb_ack_broadcast | i_fill_broadcast | i_write_broadcast)
                         ReadState <= #`dh Tags;
                    else ReadState <= #`dh Retry;
                 end
//
       SRAM    : begin
                    if(i_start)
                         ReadState <= #`dh Access;
                    else ReadState <= #`dh SRAM;
                 end
//
       Access  : begin
                    if(i_end)
                         ReadState <= #`dh Unlock;
                    else ReadState <= #`dh Access;
                 end
//
       Unlock  : ReadState <= #`dh Idle;
//
       Nack    : ReadState <= #`dh Idle;
//
       default : ReadState <= #`dh Idle;
//
       endcase
    end
 end
//
 assign o_sram_adr       = {i_mni_read_adr[14:6],way,6'b0};
 assign o_tag_req        = (ReadState==Tags);
 assign o_mni_read_stall =~((ReadState==Nack) |
                            (ReadState==Access) |
                            (ReadState==Unlock));
 assign o_mni_read_nack  = (ReadState==Nack);
 assign o_read_idle      = (ReadState==Idle);
//
endmodule
