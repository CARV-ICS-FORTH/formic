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
// Abstract      : L2C write interface
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_write.v,v $
// CVS revision  : $Revision: 1.15 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_write
//
module l2c_write(
   input             Clk,
   input             Reset,
//
   input             i_maintenance_active,
   input      [31:0] i_mni_write_adr,
   input             i_mni_write_valid,
   input             i_mni_write_dirty,
   output            o_mni_write_stall,
   output            o_mni_write_nack,
   output            o_mni_write_done,
//
   input             i_B_flag,
   input             i_hit,
   input             i_retry,
   input             i_miss,
   input      [ 2:0] i_way,
   input      [16:0] i_old_tag,
//
   input             i_start,
   input             i_end,
//
   input             i_wback_broadcast,
   input             i_fill_broadcast,
//
   input             i_writeback_ack,
//
   output            o_write_idle,
   output            o_write_tag_check,
   output            o_write_tag_req,
   output     [31:0] o_write_adr,
   output            o_write_dirty,
   output            o_writeback_req,
   output     [17:0] o_write_sram_adr,
   output reg [16:0] o_old_tag,
//
   input             i_il1_inv_ack,
   input             i_dl1_inv_ack,
   output     [31:0] o_il1_inv_adr,
   output            o_il1_inv_req,
   output     [31:0] o_dl1_inv_adr,
   output            o_dl1_inv_req,
//
   output            o_broadcast);
// Tag FSM Parameters
parameter Idle       = 11'b00000000001,
          TagsCheck  = 11'b00000000010,
          Retry      = 11'b00000000100,
          Writeback  = 11'b00000001000,
          SRAM       = 11'b00000010000,
          Access     = 11'b00000100000,
          TagSet     = 11'b00001000000,
          WaitWbAck  = 11'b00010000000,
          Invalidate = 11'b00100000000,
          Done       = 11'b01000000000,
          Nack       = 11'b10000000000;
//
reg  [10:0] WriteState;
//
// synthesis translate_off
reg [256:0] WriteStateString;
always @(WriteState) begin
  case (WriteState)
    Idle       : WriteStateString = "Idle";
    TagsCheck  : WriteStateString = "TagsCheck";
    Retry      : WriteStateString = "Retry";
    Writeback  : WriteStateString = "Writeback";
    SRAM       : WriteStateString = "SRAM";
    Access     : WriteStateString = "Access";
    TagSet     : WriteStateString = "TagSet";
    WaitWbAck  : WriteStateString = "WaitWbAck";
    Invalidate : WriteStateString = "Invalidate";
    Done       : WriteStateString = "Done";
    Nack       : WriteStateString = "Nack";
    default    : WriteStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
// way
//
 reg [ 2:0] way;
 reg [31:0] write_adr;
 reg        write_dirty;
 wire       way_ld = ((WriteState==TagsCheck) |
                      (WriteState==TagSet)) & (i_hit | i_miss);
//
 always @(posedge Clk) begin
    if(way_ld) begin
       o_old_tag <= #`dh i_old_tag;
       way       <= #`dh i_way;
    end
    if ((WriteState == Idle) & i_mni_write_valid &~i_maintenance_active) begin
       write_adr   <= #`dh i_mni_write_adr;
       write_dirty <= #`dh i_mni_write_dirty;
    end
 end
//
assign o_write_adr   = write_adr;
assign o_write_dirty = write_dirty;
//
// FSM
//
 wire InvalidEnd;
 always @(posedge Clk) begin
    if(Reset) WriteState <= #`dh Idle;
    else begin
       case(WriteState)
//
       Idle       : begin
                       if(i_mni_write_valid &~i_maintenance_active)
                            WriteState <= #`dh TagsCheck;
                       else WriteState <= #`dh Idle;
                    end
//
       TagsCheck  : begin
                       if(i_hit) begin
                          if(i_B_flag)
                               WriteState <= #`dh Writeback;
                          else WriteState <= #`dh SRAM;
                       end 
                       else if(i_miss)
                            WriteState <= #`dh Nack;
                       else if(i_retry)
                            WriteState <= #`dh Retry;
                       else WriteState <= #`dh TagsCheck;
                    end
//
       Retry   : begin
                    if(i_wback_broadcast | i_fill_broadcast)
                         WriteState <= #`dh TagsCheck;
                    else WriteState <= #`dh Retry;
                 end
//
       Writeback  : begin
                       if(i_writeback_ack)
                            WriteState <= #`dh SRAM;
                       else WriteState <= #`dh Writeback;
                    end
//
       SRAM       : begin
                       if(i_start)
                            WriteState <= #`dh Access;
                       else WriteState <= #`dh SRAM;
                    end
//
       Access     : begin
                       if(i_end)
                            WriteState <= #`dh TagSet;
                       else WriteState <= #`dh Access;
                    end
//
       TagSet     : begin
                       if(i_hit)
                            WriteState <= #`dh Invalidate;
                       else if(i_miss)
                            WriteState <= #`dh WaitWbAck;
                       else WriteState <= #`dh TagSet;
                    end

       WaitWbAck  : begin
                        if(i_wback_broadcast)
                             WriteState <= #`dh TagSet;
                        else WriteState <= #`dh WaitWbAck;
                    end
       Invalidate : begin
                        begin 
                           if(InvalidEnd)
                                WriteState <= #`dh Done;
                           else WriteState <= #`dh Invalidate;
                        end
                    end
//
       Done       : WriteState <= #`dh Idle;
//
       Nack       : WriteState <= #`dh Invalidate;
//
       default    : WriteState <= #`dh Idle;
//
       endcase
    end
 end
//
assign o_broadcast = (WriteState==TagSet) & i_hit;
//
//
// iL1 Invalidate
//
 assign o_write_idle      = (WriteState==Idle);
 assign o_write_tag_check = (WriteState==TagsCheck);
 assign o_write_tag_req   = (WriteState==TagsCheck) | (WriteState==TagSet);
 assign o_write_sram_adr  = {write_adr[14:6],way,6'b0};
 assign o_writeback_req   = (WriteState==Writeback);
//
wire goto_invalid = ((WriteState==TagSet) & i_hit) | (WriteState==Nack);
//
// iL1 Invalidate FSM
//
 parameter iL1Idle = 3'b001,
           iL1InvH = 3'b010,
           iL1InvL = 3'b100;
 reg [2:0] InvIL1State;
//
// synthesis translate_off
reg [256:0] InvIL1StateString;
always @(InvIL1State) begin
  case (InvIL1State)
    iL1Idle : InvIL1StateString = "iL1Idle";
    iL1InvH : InvIL1StateString = "iL1InvH";
    iL1InvL : InvIL1StateString = "iL1InvL";
    default : InvIL1StateString = "ERROR";
  endcase
end
// synthesis translate_on
//
 always @(posedge Clk) begin
    if(Reset) InvIL1State <= #`dh iL1Idle;
    else begin
       case(InvIL1State)
//
       iL1Idle  : begin
                     if(goto_invalid)
                          InvIL1State <= #`dh iL1InvH;
                     else InvIL1State <= #`dh iL1Idle;
                  end
//
       iL1InvH  : begin
                     if(i_il1_inv_ack)
                          InvIL1State <= #`dh iL1InvL;
                     else InvIL1State <= #`dh iL1InvH;
                  end
//
       iL1InvL  : begin
                     if(i_il1_inv_ack)
                          InvIL1State <= #`dh iL1Idle;
                     else InvIL1State <= #`dh iL1InvL;
                  end
//
       default  : InvIL1State <= #`dh iL1Idle;
//
       endcase
    end
 end
//
assign o_il1_inv_adr = {write_adr[31:6],(InvIL1State==iL1InvH),5'b0};
assign o_il1_inv_req = (InvIL1State!=iL1Idle);
//
// dL1 Invalidate FSM
//
 parameter dL1Idle = 3'b001,
           dL1InvH = 3'b010,
           dL1InvL = 3'b100;
 reg [2:0] InvDL1State;
//
// synthesis translate_off
reg [256:0] InvDL1StateString;
always @(InvDL1State) begin
  case (InvDL1State)
    dL1Idle : InvDL1StateString = "dL1Idle";
    dL1InvH : InvDL1StateString = "dL1InvH";
    dL1InvL : InvDL1StateString = "dL1InvL";
    default : InvDL1StateString = "ERROR";
  endcase
end
// synthesis translate_on
//
 always @(posedge Clk) begin
    if(Reset) InvDL1State <= #`dh dL1Idle;
    else begin
       case(InvDL1State)
//
       dL1Idle  : begin
                     if(goto_invalid)
                          InvDL1State <= #`dh dL1InvH;
                     else InvDL1State <= #`dh dL1Idle;
                  end
//
       dL1InvH  : begin
                     if(i_dl1_inv_ack)
                          InvDL1State <= #`dh dL1InvL;
                     else InvDL1State <= #`dh dL1InvH;
                  end
//
       dL1InvL  : begin
                     if(i_dl1_inv_ack)
                          InvDL1State <= #`dh dL1Idle;
                     else InvDL1State <= #`dh dL1InvL;
                  end
//
       default  : InvDL1State <= #`dh dL1Idle;
//
       endcase
    end
 end
//
assign o_dl1_inv_adr = {write_adr[31:6],(InvDL1State==dL1InvH),5'b0};
assign o_dl1_inv_req = (InvDL1State!=dL1Idle);
//
assign InvalidEnd = (InvDL1State==dL1Idle) & (InvIL1State==iL1Idle);
//
assign o_mni_write_stall =~((WriteState==Nack) | 
                            ((WriteState==SRAM) & i_start) | 
                            (WriteState==Access));
//
assign o_mni_write_done = (WriteState==Done);
assign o_mni_write_nack = (WriteState==Nack);
//
endmodule
