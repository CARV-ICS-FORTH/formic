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
// Abstract      : L2C fill interface
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_fill.v,v $
// CVS revision  : $Revision: 1.16 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_fill
//
module l2c_fill(
   input             Clk,
   input             Reset,
//
   input             i_mni_fill_valid,
   input      [ 3:0] i_mni_fill_len,
   input      [31:0] i_mni_fill_adr,
//
   input             i_fill_success,
   input             i_fill_fail,
   input      [ 2:0] i_way,
   output            o_fill_check_req,
   output            o_fill_set_req,
   output reg [31:0] o_fill_adr,
   output     [ 2:0] o_fill_set_way,
//
   input             i_wb_ack_broadcast,
//
   input             i_fill_start,
   input             i_fill_end,
   output     [17:0] o_sram_adr,
//
   output            o_mni_fill_stall,
//
   output            o_fill_direct,
   output            o_fill_broadcast
);
// Tag FSM Parameters
parameter Idle          = 7'b000_0001,
          TagCheck      = 7'b000_0010,
          SRAM          = 7'b000_0100,
          Access        = 7'b000_1000,
          TagSet        = 7'b001_0000,
          WaitWbAck     = 7'b010_0000,
          Direct        = 7'b100_0000;
//
reg  [6:0] FillState;
reg        Sel_dc;
// synthesis translate_off
reg [256:0] FillStateString;
always @(FillState) begin
  case (FillState) 
    Idle      : FillStateString = "Idle";
    TagCheck  : FillStateString = "TagCheck";
    SRAM      : FillStateString = "SRAM";
    Access    : FillStateString = "Access";
    TagSet    : FillStateString = "TagSet";
    WaitWbAck : FillStateString = "WaitWbAck";
    Direct    : FillStateString = "Direct";
    default   : FillStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
// Fill FSM
//
 always @(posedge Clk) begin
    if(Reset) FillState <= #`dh Idle;
    else begin
       case(FillState)
//
       Idle          : begin
                          if(i_mni_fill_valid) begin
                             if(i_mni_fill_len==0)
                                  FillState <= #`dh Direct;
                             else FillState <= #`dh TagCheck;
                          end
                          else FillState <= #`dh Idle;
                       end
//
       TagCheck      : begin
                          if(i_fill_fail)
                               FillState <= #`dh WaitWbAck;
                          else if(i_fill_success)
                               FillState <= #`dh SRAM;
                          else FillState <= #`dh TagCheck;
                       end
//
       WaitWbAck     : begin
                          if(i_wb_ack_broadcast)
                               FillState <= #`dh TagCheck;
                          else FillState <= #`dh WaitWbAck;
                       end
//
       SRAM          : begin
                          if(i_fill_start)
                               FillState <= #`dh Access;
                          else FillState <= #`dh SRAM;
                       end
//
       Access        : begin
                          if(i_fill_end)
                               FillState <= #`dh TagSet;
                          else FillState <= #`dh Access;
                       end
//
       TagSet        : begin
                          if(i_fill_success)
                               FillState <= #`dh Idle;
                          else FillState <= #`dh TagSet;
                       end
//
       Direct        : FillState <= #`dh Idle;
//
       default       : FillState <= #`dh Idle;
//
       endcase
    end
 end
//
 reg [ 2:0] way;
 always @(posedge Clk) begin
    if (FillState==TagCheck) begin
       way     <= #`dh i_way;
    end
 end
//
 always @(posedge Clk) begin
    if (FillState==Idle) o_fill_adr <= #`dh i_mni_fill_adr;
 end
//
 assign o_fill_check_req = (FillState==TagCheck);
 assign o_fill_set_req   = (FillState==TagSet);
 assign o_fill_set_way   = way;
 assign o_sram_adr       = {o_fill_adr[14:6], way, 6'b0};
 assign o_mni_fill_stall = ~(((FillState==SRAM) & i_fill_start) | 
                             (FillState==Access) |
                             (FillState==Direct));
 assign o_fill_direct    = (FillState==Direct);
 assign o_fill_broadcast = (FillState==TagSet) & i_fill_success;
//
endmodule
