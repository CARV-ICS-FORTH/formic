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
// Abstract      : Global timer implementation
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: GlobalTimer.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// GlobalTimer
//
module GlobalTimer(
   input             Clk,
   input             Reset,
   input      [31:0] i_in,
   input             i_write,
   output reg [31:0] o_out,
   output            o_drift_fw,
   output            o_drift_bw);
//
 parameter Idle      = 3'b001,
           Forword   = 3'b010,
           BackWord  = 3'b100;
//
 reg [2:0] State;
//
//
//
 reg  [15:0] DriftCnt;
 wire [30:0] Val       = i_in[29:0] - o_out[29:0];
 wire        CaseEqual = (o_out[31:30]==i_in[31:30]); 
 wire        CaseP1    = (o_out[31:30]==(i_in[31:30]+1));
 wire        CaseM1    = (o_out[31:30]==(i_in[31:30]-1));
 wire        neg       = CaseP1 | CaseM1 | (CaseEqual & Val[30]);
 wire [29:0] tmpVal    = neg ? (~Val[29:0] + 30'h1) : Val[29:0];
//
// o_out  Current Timer Value
// 
 wire inc  = (State==Idle);
 wire inc2 = (State==Forword);
//
 always @(posedge Clk) begin
    if(Reset) o_out <= #`dh 0;
    else begin
       if(inc)
          o_out <= #`dh o_out + 32'h1;
       else if(inc2)
          o_out <= #`dh o_out + 32'h2;
    end
 end
//
// DriftCnt
//
 always @(posedge Clk) begin
    if(Reset) DriftCnt <= #`dh 0;
    else begin
       if(i_write) begin
          DriftCnt <= #`dh tmpVal[15:0];
       end
       else if(State!=Idle)
          DriftCnt <= #`dh DriftCnt - 16'h1;
    end
 end   
//
 wire DriftCntEnd = (DriftCnt==0);
//
 always @(posedge Clk) begin
    if(Reset) State <= #`dh Idle;
    else begin
       case(State)
//
       Idle     : begin
                     if(i_write) begin
                        if((CaseEqual &~Val[30]) | CaseM1)
                             State <= #`dh Forword;
                        else if((CaseEqual & Val[30]) | CaseP1)
                             State <= #`dh BackWord;
                        else State <= #`dh Idle;
                     end
                     else State <= #`dh Idle;
                  end
//
       Forword  : begin
                     if(DriftCntEnd)
                          State <= #`dh Idle;
                     else State <= #`dh Forword;
                  end
//
       BackWord : begin
                     if(DriftCntEnd)
                          State <= #`dh Idle;
                     else State <= #`dh BackWord;
                  end
//
       default  : State <= #`dh Idle;
//
       endcase
    end
 end
//
 assign o_drift_fw = (State==BackWord);
 assign o_drift_bw = (State==Forword);
//
endmodule
