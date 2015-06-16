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
// Abstract      : L2C L1 response handler
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_l1.v,v $
// CVS revision  : $Revision: 1.28 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_l1
//
module l2c_l1(
   input             Clk,
   input             Reset,
   input             i_ctl_en,
   output            o_l2c_idle,
// L1 Cache Interface
   input      [31:0] i_l1_adr,
   input      [ 1:0] i_l1_flags,
   input             i_l1_wen,
   input             i_l1_valid,
   output reg        o_l1_rdata_valid,
   output reg        o_l1_stall,
//
   input             i_maintenance_active,
   input      [31:0] i_fill_adr,
   input             i_fill_start,
   input             i_B_flag,
   input             i_hit,
   input             i_retry,
   input             i_miss,
   input      [ 2:0] i_way,
   input      [16:0] i_old_tag,
   input             i_start,
   input             i_end,
   input             i_wb_ack,
   input             i_direct,
   input             i_fill_broadcast,
   input             i_write_broadcast,
   input             i_miss_ack,
   input             i_wb_ack_broadcast,
   input      [31:0] i_wb_ack_adr,
   input             i_sctl_resp_valid,
   output            o_l2c_replace_fault,
//
   output reg [16:0] o_old_tag,
   output            o_read_hit,
   output            o_write_hit,
   output            o_wb_req,
   output            o_sram_acc,
   output     [17:0] o_sram_adr,
   output            o_tag_req,
   output            o_miss,
   output            o_l2c_replace_data);
//
// FSM Parameters
//
parameter Idle      = 11'b000_0000_0001,
          Tags      = 11'b000_0000_0010,
          Retry     = 11'b000_0000_0100,
          ReadHit   = 11'b000_0000_1000,
          WriteHit  = 11'b000_0001_0000,
          Miss      = 11'b000_0010_0000,
          Writeback = 11'b000_0100_0000,
          Fill      = 11'b000_1000_0000,
          Unlock    = 11'b001_0000_0000,
          Intercept = 11'b010_0000_0000,
          WaitWbAck = 11'b100_0000_0000;
//
reg  [10:0] L1State;
//reg        B_flag;
reg        EndReg;
//
// synthesis translate_off
reg [256:0] L1StateString;
always @(L1State) begin
  case (L1State) 
    Idle      : L1StateString = "Idle";
    Tags      : L1StateString = "Tags";
    Retry     : L1StateString = "Retry";
    ReadHit   : L1StateString = "ReadHit";
    WriteHit  : L1StateString = "WriteHit";
    Miss      : L1StateString = "Miss";
    Writeback : L1StateString = "Writeback";
    Fill      : L1StateString = "Fill";
    Unlock    : L1StateString = "Unlock";
    Intercept : L1StateString = "Intercept";
    WaitWbAck : L1StateString = "WaitWbAck";
    default   : L1StateString = "ERROR";
  endcase
end
// synthesis translate_on
 wire goto_Miss = ~i_l1_flags[1] | i_l1_flags[0] |~i_ctl_en;
 wire fill_adr_match = (i_l1_adr[31:6] == i_fill_adr[31:6]);
 wire goto_Intercept = fill_adr_match & (i_direct | i_fill_start);
 wire WbAckOk = i_wb_ack_broadcast & (i_l1_adr == i_wb_ack_adr);
 wire  ReadCntEndComb;
 //reg   ReadCntEndReg;
 reg   ReadCntMidReg;
//
// way
//
 reg [ 2:0] way;
 wire       way_ld = (L1State==Tags) & (i_hit | i_miss);
//
 always @(posedge Clk) 
    if(way_ld) begin
             way <= #`dh i_way;
       o_old_tag <= #`dh i_old_tag;
    end
//
// L1  FSM
//
 always @(posedge Clk) begin
    if(Reset) L1State <= #`dh Idle;
    else begin
       case(L1State)
//
       Idle      : begin
                      if(i_l1_valid & o_l1_stall &~i_maintenance_active) begin
                         if(goto_Miss)
                              L1State <= #`dh Miss;
                         else L1State <= #`dh Tags;
                      end
                      else L1State <= #`dh Idle;
                   end
//
       Tags      : begin 
                      if(i_hit) begin
                         if(i_l1_wen)
                              L1State <= #`dh WriteHit;
                         else L1State <= #`dh ReadHit;
                      end
                      else if(i_miss) begin
                         if(i_B_flag)
                              L1State <= #`dh Writeback;
                         else
                              L1State <= #`dh Miss;
                      end
                      else if(i_retry) 
                           L1State <= #`dh Retry;
                      else L1State <= #`dh Tags;
                   end
//
       Retry : begin
                    if(i_wb_ack_broadcast | i_fill_broadcast | i_write_broadcast)
                         L1State <= #`dh Tags;
                    else L1State <= #`dh Retry;
                 end
//
       WriteHit  : begin
                      if(i_start)
                           L1State <= #`dh Idle;
                      else L1State <= #`dh WriteHit;
                   end
//
       ReadHit   : begin
                      if(EndReg)
                           L1State <= #`dh Idle;
                      else L1State <= #`dh ReadHit;
                   end
//
       Writeback : begin
                      if(i_wb_ack)
                           L1State <= #`dh Miss;
                      else L1State <= #`dh Writeback;
                   end
//
       Fill      : begin
                      if(goto_Intercept) begin
                         if(i_direct)
                              L1State <= #`dh Unlock;
                         else L1State <= #`dh Intercept;
                      end
                      else L1State <= #`dh Fill;
                   end
//
       Unlock    : begin
                      L1State <= #`dh Idle;
                   end
//
       Miss      : begin
                      if(i_miss_ack) begin
                         if(i_l1_flags[0] & i_l1_wen)
                              L1State <= #`dh Unlock;
                         else if((~i_l1_flags[1] | ~i_ctl_en) & i_l1_wen)
                              L1State <= #`dh WaitWbAck;
                         else
                              L1State <= #`dh Fill;
                      end
                      else L1State <= #`dh Miss;
                   end
//
       Intercept : begin
                      if(ReadCntEndComb)
                           L1State <= #`dh Unlock;
                      else L1State <= #`dh Intercept;
                   end
//
       WaitWbAck : begin
                      if(WbAckOk)
                           L1State <= #`dh Unlock;
                      else L1State <= #`dh WaitWbAck;
                   end
//
       default   : L1State <= #`dh Idle;
//
       endcase
    end
 end
//
// ReadCnt
//
 reg [3:0] ReadCnt;
 wire      ReadCntClr = (L1State==Fill) & ~goto_Intercept;
 wire      ReadCntInc = ((L1State==Fill) & goto_Intercept) | (L1State==Intercept);
 wire      ReadCntMatch = (ReadCnt==i_l1_adr[5:2]);
//
 always @(posedge Clk) begin
    if(Reset) ReadCnt <= #`dh 4'h0;
    else begin
       if(ReadCntClr)
          ReadCnt <= #`dh 4'h0;
       else if(ReadCntInc)
          ReadCnt <= #`dh ReadCnt + 4'h1; 
    end
 end
//
 assign o_wb_req        = (L1State==Writeback);
 assign o_miss          = (L1State==Miss);
 assign o_l2c_idle      = (L1State==Idle) | (L1State==Miss);
 assign o_tag_req       = (L1State==Tags);
 assign o_write_hit     = (L1State==WriteHit);
 assign o_read_hit      = (L1State==ReadHit);

//
 always @(posedge Clk) begin
    if(Reset) begin
         o_l1_stall <= #`dh 1;
         EndReg <= #`dh 0;
    end
    else begin
         o_l1_stall <= #`dh~(((L1State==WriteHit) & i_start) |
                             ((L1State==ReadHit) & i_end) | 
                             (L1State==Unlock));
         EndReg <= #`dh i_end;
    end
 end
//
 assign ReadCntEndComb = (ReadCnt==4'd15);
 always @(posedge Clk) begin
    if(Reset)
         o_l1_rdata_valid <= #`dh 0;
    else begin
       if (~i_l1_wen &&
          (((L1State==Fill) & i_direct & fill_adr_match) ||
           (~i_l1_adr[5] & (L1State==Fill) & goto_Intercept) ||
           ( i_l1_adr[5] & (L1State==Intercept) & ReadCntMidReg) ||
           i_start))
         o_l1_rdata_valid <= #`dh 1;
       else if ((L1State==Unlock) |  
               (~i_l1_adr[5] & (L1State==Intercept) & ReadCntMidReg) |
               //((L1State==Intercept) & ReadCntEndReg) |
               (L1State==Idle) |
               EndReg)
         o_l1_rdata_valid <= #`dh 0;
    end
 end
 always @(posedge Clk) begin
	ReadCntMidReg <= #`dh (ReadCnt==4'd7);
    //ReadCntEndReg <= ReadCntEndComb;
 end
//
assign o_l2c_replace_data = i_l1_wen & ReadCntInc & ReadCntMatch;
assign o_l2c_replace_fault = (L1State==WaitWbAck) & WbAckOk;
assign o_sram_adr = {i_l1_adr[14:6],way,i_l1_adr[5:0]};
//
 assign o_sram_acc = (L1State==ReadHit);
//
endmodule
