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
// Abstract      : L2C maintenance operations
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_maintenance.v,v $
// CVS revision  : $Revision: 1.13 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_maintenance
//
module l2c_maintenance(
   input             Clk,
   input             Reset,
//
   input             i_ctl_clear_req,
   input             i_ctl_flush_req,
   input             i_idle,  
   input             i_maintenance_clear_ack,
   input             i_maintenance_flush_dirty,
   input             i_maintenance_flush_clean,
   input      [ 2:0] i_maintenance_hit_way,
   input             i_writeback_ack,
   input             i_wb_ack_broadcast,
   input      [31:0] i_wb_ack_adr,
   input      [16:0] i_old_tag,
//
   output reg [16:0] o_old_tag,
   output     [ 8:0] o_index,
   output            o_writeback_req,
   output            o_maintenance,
   output            o_maintenance_clear,
   output            o_maintenance_req,
   output reg        o_ctl_maint_ack,
   output reg [ 2:0] o_way
);
// Maintenance FSM Parameters
parameter Idle        = 9'b0_0000_0001,
          WaitIdle    = 9'b0_0000_0010,
          ClearOp     = 9'b0_0000_0100,
          ClearCntInc = 9'b0_0000_1000,
          FlushOp     = 9'b0_0001_0000,
          Writeback   = 9'b0_0010_0000,
          WaitWbAck   = 9'b0_0100_0000,
          FlushCntInc = 9'b0_1000_0000,
          Reply       = 9'b1_0000_0000;
//
reg  [8:0] MaintState;
//
// synthesis translate_off
reg [256:0] MaintStateString;
always @(MaintState) begin
  case (MaintState)
    Idle        : MaintStateString = "Idle";
    WaitIdle    : MaintStateString = "WaitIdle";
    ClearOp     : MaintStateString = "ClearOp";
    ClearCntInc : MaintStateString = "ClearCntInc";
    FlushOp     : MaintStateString = "FlushOp";
    Writeback   : MaintStateString = "Writeback";
    WaitWbAck   : MaintStateString = "WaitWbAck";
    FlushCntInc : MaintStateString = "FlushCntInc";
    Reply       : MaintStateString = "Reply";
    default     : MaintStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
// Cnt
//
 reg  [8:0] Cnt;
 wire       CntInc = (MaintState==ClearCntInc) | (MaintState==FlushCntInc);
  always @(posedge Clk) begin
     if(Reset)       Cnt <= #`dh 0;
     else if(CntInc) Cnt <= #`dh Cnt + 9'h1;
  end
 wire CntEnd = (Cnt==9'd511);
//
// old_tag
//
  always @(posedge Clk) begin
     if(MaintState==FlushOp) o_old_tag <= #`dh i_old_tag;
  end
//
// Maintenance FSM
//
 always @(posedge Clk) begin
    if(Reset) MaintState <= #`dh Idle;
    else begin
       case(MaintState)
//
       Idle        : begin
                        if(i_ctl_clear_req | i_ctl_flush_req)
                             MaintState <= #`dh WaitIdle;
                        else MaintState <= #`dh Idle;
                     end
//
       WaitIdle    : begin
                        if(i_idle) begin
                           if(i_ctl_flush_req)
                                MaintState <= #`dh FlushOp;
                           else MaintState <= #`dh ClearOp;
                        end
                        else MaintState <= #`dh WaitIdle;
                     end
//
       ClearOp     : begin
                     if(i_maintenance_clear_ack) begin
                        if(i_ctl_flush_req)
                             MaintState <= #`dh FlushCntInc;
                        else MaintState <= #`dh ClearCntInc;
                     end
                        else MaintState <= #`dh ClearOp;
                     end
//
       ClearCntInc : begin
                        if(CntEnd)
                             MaintState <= #`dh Reply;
                        else MaintState <= #`dh ClearOp;
                     end
//
       FlushOp     : begin
                        if(i_maintenance_flush_dirty)
                             MaintState <= #`dh Writeback;
                        else if(i_maintenance_flush_clean) begin
                           if(i_ctl_clear_req)
                              MaintState <= #`dh ClearOp;
                           else 
                              MaintState <= #`dh FlushCntInc;
                        end
                        else MaintState <= #`dh FlushOp;
                     end
//
       FlushCntInc : begin
                        if(CntEnd)
                             MaintState <= #`dh Reply;
                        else MaintState <= #`dh FlushOp;
                     end
//
       Writeback   : begin
                        if(i_writeback_ack)
                             MaintState <= #`dh WaitWbAck;
                        else MaintState <= #`dh Writeback;
                     end
//
       WaitWbAck   : begin
                        if(i_wb_ack_broadcast && (i_wb_ack_adr[31:6]=={o_old_tag,o_index}))
                             MaintState <= #`dh FlushOp;
                        else MaintState <= #`dh WaitWbAck;
                     end
//
       Reply       : begin
                        if(~i_ctl_clear_req &~i_ctl_flush_req)
                             MaintState <= #`dh Idle;
                        else MaintState <= #`dh Reply;
                     end
//
       default     : MaintState <= #`dh Idle;
//
       endcase
    end
 end
//
  always @(posedge Clk) begin
    if ((MaintState == FlushOp) & (i_maintenance_flush_dirty))
      o_way <= #`dh i_maintenance_hit_way;
  end
//
  always @(posedge Clk) begin
     if(Reset)       
        o_ctl_maint_ack <= #`dh 0;
     else 
	    o_ctl_maint_ack <= #`dh CntEnd & ((MaintState==ClearCntInc) | 
                                          (MaintState==FlushCntInc));
        
  end
//
 assign o_index             = Cnt;
 assign o_writeback_req     = (MaintState==Writeback);
 assign o_maintenance       = (MaintState!=Idle);
 assign o_maintenance_clear = (MaintState==ClearOp);
 assign o_maintenance_req   = (MaintState==ClearOp) | (MaintState==FlushOp);
//
endmodule
