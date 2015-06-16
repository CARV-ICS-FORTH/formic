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
// Abstract      : Formic board controller trace interface input block
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: formic_bctl_trace_in.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// formic_bctl_trace_in
//
module formic_bctl_trace_in(
   input         clk,
   input         rst,
   input  [ 7:0] i_data,
   input         i_valid,
   input         i_deq,
   output [ 7:0] o_data,
   output        o_data_valid,
   output reg    o_drop);
//
parameter  IdleSt  = 3'b001,
           EnqSt   = 3'b010,
           ErrorSt = 3'b100;
reg  [2:0] State;
// synthesis translate_off
 reg [256:0] StateString;
 always @(State) begin
   case (State)
     IdleSt    : StateString = "IdleState";
     EnqSt     : StateString = "EnqState";
     ErrorSt   : StateString = "ErrorState";
     default   : StateString = "ERROR";
   endcase
 end
// synthesis translate_on
//
//
reg  [2:0] in_cnt;
wire [6:0] wr_words, rd_words;
//
// in_cnt
//
 always @(posedge clk) begin
    if(rst)
       in_cnt <= #`dh 0;
    else if(i_valid)
       in_cnt <= #`dh in_cnt + 3'b1;
 end
 wire in_cnt_end = (in_cnt==3'h7);
//
// FSM
//
 always @(posedge clk) begin
    if(rst) State <= #`dh IdleSt;
    else begin
       case(State)
//
       IdleSt  : begin
                    if(i_valid) begin
                       if(wr_words<7'd8)
                            State <= #`dh ErrorSt;
                       else State <= #`dh EnqSt;
                    end
                    else State <= #`dh IdleSt;
                 end
//
       EnqSt   : begin
                    if(in_cnt_end) 
                         State <= #`dh IdleSt;
                    else State <= #`dh EnqSt;
                 end
//
       ErrorSt : begin
                    if(in_cnt_end)
                         State <= #`dh IdleSt;
                    else State <= #`dh ErrorSt;
                 end
//
       default : State <= #`dh IdleSt;
//
       endcase
    end
 end
//
 wire enq = ((State==IdleSt) & i_valid &~(wr_words<7'd8)) | (State==EnqSt);
//
// fifo 64x8
//
 fifo_align_64x8 fifo(
    // Write interface
    .clk_wr     ( clk ),
    .rst_wr     ( rst ),
    .i_wr_data  ( i_data ),
    .i_wr_en    ( enq ),
    .o_full     ( ),
    .o_wr_words ( wr_words ),
    // Read interface
    .clk_rd     ( clk ),
    .rst_rd     ( rst ),
    .o_rd_data  ( o_data ),
    .i_rd_en    ( i_deq ),
    .o_empty    ( empty ),
    .o_rd_words ( rd_words ));
//
 assign o_data_valid = (rd_words>1);
//
// drop
//
 always @(posedge clk) begin
    if(rst) o_drop <= #`dh 0;
    else begin
       if(State==ErrorSt)
           o_drop <= #`dh 1;
        else if(i_deq)
           o_drop <= #`dh 0;
    end
 end
//
endmodule
