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
// Abstract      : L2C miss handler
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_miss.v,v $
// CVS revision  : $Revision: 1.11 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_miss
//
module l2c_miss(
   input             Clk,
   input             Reset,
//
   input             i_ctl_en,
   input             i_dl1_miss_req,
   input             i_dl1_wen,
   input      [31:0] i_dl1_miss_adr,
   input      [ 1:0] i_dl1_miss_flags,
   output reg        o_dl1_miss_ack,
//
   input             i_il1_miss_req,
   input      [31:0] i_il1_miss_adr,
   input      [ 1:0] i_il1_miss_flags,
   output reg        o_il1_miss_ack,
//
   input             i_mni_miss_stall,
   output reg [31:0] o_mni_miss_adr,
   output reg [ 1:0] o_mni_miss_flags,
   output            o_mni_miss_valid,
   output reg        o_mni_miss_wen,
   output            o_dl2_sel
);
// Tag FSM Parameters
parameter Idle   = 3'b001,
          Miss   = 3'b010,
          Unlock = 3'b100;
//
reg  [2:0] MissState;
reg        Sel_dc;
//
// synthesis translate_off
reg [256:0] MissStateString;
always @(MissState) begin
  case (MissState) 
    Idle    : MissStateString = "Idle";
    Miss    : MissStateString = "Miss";
    Unlock  : MissStateString = "Unlock";
    default : MissStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
// FSM
//
 always @(posedge Clk) begin
    if(Reset) MissState <= #`dh Idle;
    else begin
       case(MissState)
//
       Idle    : begin
                    if(i_dl1_miss_req | i_il1_miss_req)
                         MissState <= #`dh Miss;
                    else MissState <= #`dh Idle;
                 end
//
       Miss    : begin
                    if(i_mni_miss_stall)
                         MissState <= #`dh Miss;
                    else MissState <= #`dh Unlock;
                 end
//
       Unlock  : MissState <= #`dh Idle;
//
       default : MissState <= #`dh Idle;
//
       endcase
    end
 end
//
//
//
 wire dl1_ld = (MissState==Idle) & i_dl1_miss_req;
 wire il1_ld = (MissState==Idle) & i_il1_miss_req &~i_dl1_miss_req;
//
 always @(posedge Clk) begin
    if(Reset) begin
       Sel_dc         <= #`dh 0;
       o_dl1_miss_ack <= #`dh 0;
       o_il1_miss_ack <= #`dh 0;
       o_mni_miss_wen <= #`dh 0;
    end
    else begin
       if(dl1_ld)  begin
          o_mni_miss_wen   <= #`dh i_dl1_wen & (~i_ctl_en | i_dl1_miss_flags[0] | ~i_dl1_miss_flags[1]);
          Sel_dc           <= #`dh 1;
       end
       if(il1_ld)  begin      
          o_mni_miss_wen   <= #`dh 0;
          Sel_dc           <= #`dh 0;
       end
       o_dl1_miss_ack <= #`dh (MissState==Miss) &~i_mni_miss_stall & Sel_dc;
       o_il1_miss_ack <= #`dh (MissState==Miss) &~i_mni_miss_stall &~Sel_dc;
    end
 end
//
 always @(posedge Clk) begin
    if(dl1_ld)  begin
       o_mni_miss_flags <= #`dh {(i_dl1_miss_flags[1] & i_ctl_en),
                                 i_dl1_miss_flags[0]};
       
       if (~i_dl1_miss_flags[1] | ~i_ctl_en | i_dl1_miss_flags[0])
         o_mni_miss_adr   <= #`dh {i_dl1_miss_adr[31:2], 2'b0};
       else
         o_mni_miss_adr   <= #`dh {i_dl1_miss_adr[31:6], 6'b0};
    end
    if(il1_ld)  begin      
       o_mni_miss_flags <= #`dh {(i_il1_miss_flags[1] & i_ctl_en),
                                 i_il1_miss_flags[0]};
       
       if (~i_il1_miss_flags[1] | ~i_ctl_en | i_il1_miss_flags[0])
         o_mni_miss_adr   <= #`dh {i_il1_miss_adr[31:2], 2'b0};
       else
         o_mni_miss_adr   <= #`dh {i_il1_miss_adr[31:6], 6'b0};
    end
 end
//
 assign o_mni_miss_valid = (MissState==Miss);
 assign o_dl2_sel        = Sel_dc;
//
endmodule
