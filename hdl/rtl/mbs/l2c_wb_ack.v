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
// Abstract      : L2C writeback acknowledges
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_wb_ack.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_wb_ack
//
module l2c_wb_ack(
   input             Clk,
   input             Reset,
//
   input             i_mni_wb_ack_valid,
   input             i_tag_ack,
   output            o_tag_req,
   output            o_mni_wb_ack_stall,
   output            o_broadcast
);
// Tag FSM Parameters
parameter Idle      = 3'b001,
          Tag       = 3'b010,
          Broadcast = 3'b100;
//
reg  [2:0] WbAckState;
//
// synthesis translate_off
reg [256:0] WbAckStateString;
always @(WbAckState) begin
  case (WbAckState)
    Idle      : WbAckStateString = "Idle";
    Tag       : WbAckStateString = "Tag";
    Broadcast : WbAckStateString = "Broadcast";
    default   : WbAckStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
// FSM
//
 always @(posedge Clk) begin
    if(Reset) WbAckState <= #`dh Idle;
    else begin
       case(WbAckState)
//
       Idle      : begin
                       if(i_mni_wb_ack_valid)
                            WbAckState <= #`dh Tag;
                       else WbAckState <= #`dh Idle;
                    end
//
       Tag       : begin
                       if(i_tag_ack)
                            WbAckState <= #`dh Broadcast;
                       else WbAckState <= #`dh Tag;
                    end
//
       Broadcast : WbAckState <= #`dh Idle;
//
       default   : WbAckState <= #`dh Idle;
//
       endcase
    end
 end
//
//
 assign o_tag_req          = (WbAckState==Tag);
 assign o_mni_wb_ack_stall =~(WbAckState==Broadcast);
 assign o_broadcast        = (WbAckState==Broadcast);
//
endmodule
