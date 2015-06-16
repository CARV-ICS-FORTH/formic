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
// Abstract      : Formic board controller trace interface
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: formic_bctl_trace.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// formic_bctl_trace
//
module formic_bctl_trace(
   input             clk_ni,
   input             rst_ni,
   input             clk_mc,
   input             rst_mc,
  // MBS Trace Interface (clk_ni)
   input             i_mbs0_trc_valid,
   input      [ 7:0] i_mbs0_trc_data,
   input             i_mbs1_trc_valid,
   input      [ 7:0] i_mbs1_trc_data,
   input             i_mbs2_trc_valid,
   input      [ 7:0] i_mbs2_trc_data,
   input             i_mbs3_trc_valid,
   input      [ 7:0] i_mbs3_trc_data,
   input             i_mbs4_trc_valid,
   input      [ 7:0] i_mbs4_trc_data,
   input             i_mbs5_trc_valid,
   input      [ 7:0] i_mbs5_trc_data,
   input             i_mbs6_trc_valid,
   input      [ 7:0] i_mbs6_trc_data,
   input             i_mbs7_trc_valid,
   input      [ 7:0] i_mbs7_trc_data,
//
   input      [25:0] i_bctl_trc_base,
   input      [25:0] i_bctl_trc_bound,
   input             i_bctl_trc_en,
//
   input             i_l2c_wb_space,
   output            o_l2c_wb_valid,
   output reg [31:0] o_l2c_wb_adr,
   output     [31:0] o_l2c_data);
//
parameter  FifoEnqIdle = 9'b0_0000_0001,
           FifoEnqSt0  = 9'b0_0000_0010,
           FifoEnqSt1  = 9'b0_0000_0100,
           FifoEnqSt2  = 9'b0_0000_1000,
           FifoEnqSt3  = 9'b0_0001_0000,
           FifoEnqSt4  = 9'b0_0010_0000,
           FifoEnqSt5  = 9'b0_0100_0000,
           FifoEnqSt6  = 9'b0_1000_0000,
           FifoEnqSt7  = 9'b1_0000_0000;
//
reg  [8:0] FifoEnqState;
// synthesis translate_off
 reg [256:0] FifoEnqStateString;
 always @(FifoEnqState) begin
   case (FifoEnqState)
     FifoEnqIdle : FifoEnqStateString = "IdleState";
     FifoEnqSt0  : FifoEnqStateString = "FifoEnqState0";
     FifoEnqSt1  : FifoEnqStateString = "FifoEnqState1";
     FifoEnqSt2  : FifoEnqStateString = "FifoEnqState2";
     FifoEnqSt3  : FifoEnqStateString = "FifoEnqState3";
     FifoEnqSt4  : FifoEnqStateString = "FifoEnqState4";
     FifoEnqSt5  : FifoEnqStateString = "FifoEnqState5";
     FifoEnqSt6  : FifoEnqStateString = "FifoEnqState6";
     FifoEnqSt7  : FifoEnqStateString = "FifoEnqState7";
     default     : FifoEnqStateString = "FifoEnqERROR";
   endcase
 end
// synthesis translate_on
//
parameter  FifoDeqIdle = 2'b01,
           FifoDeq     = 2'b10;
//
 reg  [1:0] FifoDeqState;
//
 reg  [23:0] trc_in_reg;
 wire [ 9:0] out_fifo_wr_words, out_fifo_rd_words;
 wire [ 7:0] trc7_data, trc6_data, trc5_data, trc4_data,
             trc3_data, trc2_data, trc1_data, trc0_data; 
 wire [ 7:0] trc_in_sel;
 wire [ 7:0] trc_deq;
 wire        in_fifo_deq;
 wire        trc_in_reg_ld0, trc_in_reg_ld1, trc_in_reg_ld2;
 wire        out_fifo_deq;
//
 formic_bctl_trace_in ibctl_trace_in0(
     .clk          ( clk_ni ),
     .rst          ( rst_ni ),
     .i_data       ( i_mbs0_trc_data ),
     .i_valid      ( i_mbs0_trc_valid ),
     .i_deq        ( trc_deq[0] ),
     .o_data       ( trc0_data ),
     .o_data_valid ( trc0_valid ),
     .o_drop       ( trc0_drop ));
//
 formic_bctl_trace_in ibctl_trace_in1(
     .clk          ( clk_ni ),
     .rst          ( rst_ni ),
     .i_data       ( i_mbs1_trc_data ),
     .i_valid      ( i_mbs1_trc_valid ),
     .i_deq        ( trc_deq[1] ),
     .o_data       ( trc1_data ),
     .o_data_valid ( trc1_valid ),
     .o_drop       ( trc1_drop ));
//
 formic_bctl_trace_in ibctl_trace_in2(
     .clk          ( clk_ni ),
     .rst          ( rst_ni ),
     .i_data       ( i_mbs2_trc_data ),
     .i_valid      ( i_mbs2_trc_valid ),
     .i_deq        ( trc_deq[2] ),
     .o_data       ( trc2_data ),
     .o_data_valid ( trc2_valid ),
     .o_drop       ( trc2_drop ));
//
 formic_bctl_trace_in ibctl_trace_in3(
     .clk          ( clk_ni ),
     .rst          ( rst_ni ),
     .i_data       ( i_mbs3_trc_data ),
     .i_valid      ( i_mbs3_trc_valid ),
     .i_deq        ( trc_deq[3] ),
     .o_data       ( trc3_data ),
     .o_data_valid ( trc3_valid ),
     .o_drop       ( trc3_drop ));
//
 formic_bctl_trace_in ibctl_trace_in4(
     .clk          ( clk_ni ),
     .rst          ( rst_ni ),
     .i_data       ( i_mbs4_trc_data ),
     .i_valid      ( i_mbs4_trc_valid ),
     .i_deq        ( trc_deq[4] ),
     .o_data       ( trc4_data ),
     .o_data_valid ( trc4_valid ),
     .o_drop       ( trc4_drop ));
//
 formic_bctl_trace_in ibctl_trace_in5(
     .clk          ( clk_ni ),
     .rst          ( rst_ni ),
     .i_data       ( i_mbs5_trc_data ),
     .i_valid      ( i_mbs5_trc_valid ),
     .i_deq        ( trc_deq[5] ),
     .o_data       ( trc5_data ),
     .o_data_valid ( trc5_valid ),
     .o_drop       ( trc5_drop ));
//
 formic_bctl_trace_in ibctl_trace_in6(
     .clk          ( clk_ni ),
     .rst          ( rst_ni ),
     .i_data       ( i_mbs6_trc_data ),
     .i_valid      ( i_mbs6_trc_valid ),
     .i_deq        ( trc_deq[6] ),
     .o_data       ( trc6_data ),
     .o_data_valid ( trc6_valid ),
     .o_drop       ( trc6_drop ));
//
 formic_bctl_trace_in ibctl_trace_in7(
     .clk          ( clk_ni ),
     .rst          ( rst_ni ),
     .i_data       ( i_mbs7_trc_data ),
     .i_valid      ( i_mbs7_trc_valid ),
     .i_deq        ( trc_deq[7] ),
     .o_data       ( trc7_data ),
     .o_data_valid ( trc7_valid ),
     .o_drop       ( trc7_drop ));
//
 wire [7:0] prior_in = {trc7_valid ,trc6_valid ,trc5_valid ,trc4_valid ,
                        trc3_valid ,trc2_valid ,trc1_valid ,trc0_valid };
 assign     trc_deq  = trc_in_sel &{8{in_fifo_deq}};
//
 wire       rr_ld_en =  (FifoEnqState==FifoEnqIdle) | (FifoEnqState==FifoEnqSt7);
//
 RR_prior_enf iRR_prior(prior_in, trc_in_sel, rr_ld_en, clk_ni,~rst_ni);
 defparam iRR_prior.N_log = 3;
//
 wire [7:0] trc_in_mux = trc7_data & {8{trc_in_sel[7]}} |
                         trc6_data & {8{trc_in_sel[6]}} |
                         trc5_data & {8{trc_in_sel[5]}} |
                         trc4_data & {8{trc_in_sel[4]}} |
                         trc3_data & {8{trc_in_sel[3]}} |
                         trc2_data & {8{trc_in_sel[2]}} |
                         trc1_data & {8{trc_in_sel[1]}} |
                         trc0_data & {8{trc_in_sel[0]}};
//
 assign trc_in_reg_ld0 = (FifoEnqState==FifoEnqSt0) | (FifoEnqState==FifoEnqSt4);
 assign trc_in_reg_ld1 = (FifoEnqState==FifoEnqSt1) | (FifoEnqState==FifoEnqSt5);
 assign trc_in_reg_ld2 = (FifoEnqState==FifoEnqSt2) | (FifoEnqState==FifoEnqSt6);
//
 always @(posedge clk_ni) begin
    if(trc_in_reg_ld2) trc_in_reg[ 7: 0] <= #`dh trc_in_mux;
    if(trc_in_reg_ld1) trc_in_reg[15: 8] <= #`dh trc_in_mux;
    if(trc_in_reg_ld0) trc_in_reg[23:16] <= #`dh trc_in_mux;
 end
//
// Fifo Enq FSM
//
 wire enq_start = (|prior_in) & (out_fifo_wr_words>3);
 always @(posedge clk_ni) begin
    if(rst_ni) FifoEnqState <= #`dh FifoEnqIdle;
    else begin
       case(FifoEnqState)
//
       FifoEnqIdle : begin
                        if(enq_start)
                             FifoEnqState <= #`dh FifoEnqSt0;
                        else FifoEnqState <= #`dh FifoEnqIdle;
                     end
//
       FifoEnqSt0  : FifoEnqState <= #`dh FifoEnqSt1;
//
       FifoEnqSt1  : FifoEnqState <= #`dh FifoEnqSt2;
//
       FifoEnqSt2  : FifoEnqState <= #`dh FifoEnqSt3;
//
       FifoEnqSt3  : FifoEnqState <= #`dh FifoEnqSt4;
//
       FifoEnqSt4  : FifoEnqState <= #`dh FifoEnqSt5;
//
       FifoEnqSt5  : FifoEnqState <= #`dh FifoEnqSt6;
//
       FifoEnqSt6  : FifoEnqState <= #`dh FifoEnqSt7;
//
       FifoEnqSt7  : begin
                        if(enq_start)
                             FifoEnqState <= #`dh FifoEnqSt1;
                        else FifoEnqState <= #`dh FifoEnqIdle;
                     end
//
       default     : FifoEnqState <= #`dh FifoEnqIdle;
//
       endcase
    end
 end
//
 assign in_fifo_deq = (FifoEnqState!=FifoEnqIdle);
//
 wire [2:0] enc_out;
 encoder ienc(enc_out, trc_in_sel);
 defparam ienc.N_log = 3;
//
 wire drop = trc7_drop & trc_in_sel[7] |
             trc6_drop & trc_in_sel[6] |
             trc5_drop & trc_in_sel[5] |
             trc4_drop & trc_in_sel[4] |
             trc3_drop & trc_in_sel[3] |
             trc2_drop & trc_in_sel[2] |
             trc1_drop & trc_in_sel[1] |
             trc0_drop & trc_in_sel[0];
// 
 wire [31:0] fifo_id =  {drop,27'b0,enc_out};
//
 wire [31:0] out_fifo_wr_data = (FifoEnqState==FifoEnqSt0) ? 
                                    fifo_id : {trc_in_reg,trc_in_mux};
//
 wire        out_fifo_enq = (FifoEnqState==FifoEnqSt0) |
                            (FifoEnqState==FifoEnqSt3) |
                            (FifoEnqState==FifoEnqSt7);
//
// Out Fifo
//
fifo_align_512x32 out_fifo(
  // Write interface
  .clk_wr      ( clk_ni ),
  .rst_wr      ( rst_ni ),
  .i_wr_data   ( out_fifo_wr_data ),
  .i_wr_en     ( out_fifo_enq ),
  .o_full      ( out_fifo_full ),
  .o_wr_words  ( out_fifo_wr_words ),
  // Read interface
  .clk_rd      ( clk_mc ),
  .rst_rd      ( rst_mc ),
  .o_rd_data   ( o_l2c_data ),
  .i_rd_en     ( out_fifo_deq ),
  .o_empty     ( out_fifo_empty ),
  .o_rd_words  ( out_fifo_rd_words ));
//
// Fifo Deq enable
//
 reg FifoDeqEn;
 reg bctl_trc_en_reg;
 always @(posedge clk_mc) bctl_trc_en_reg <= #`dh i_bctl_trc_en;
//
 wire bctl_trc_base_ld = i_bctl_trc_en &~bctl_trc_en_reg;
//
 always @(posedge clk_mc) begin
    if(rst_mc)
       FifoDeqEn <= #`dh 0;
    else begin
       if(bctl_trc_base_ld)
            FifoDeqEn <= #`dh 1;
       else if(o_l2c_wb_adr[31:6] == i_bctl_trc_bound)
            FifoDeqEn <= #`dh 0;
    end
 end
//
// deq_cnt
//
 reg [3:0] deq_cnt;
//
 always @(posedge clk_mc) begin
    if(rst_mc)
       deq_cnt <= #`dh 0;
    else if(out_fifo_deq)
       deq_cnt <= #`dh deq_cnt + 1'b1;
 end
//
 wire deq_cnt_end = (deq_cnt==15);
//
// Fifo Dequeue FSM 
//
 always @(posedge clk_mc) begin
    if(rst_mc) FifoDeqState <= #`dh FifoDeqIdle;
    else begin
       case(FifoDeqState)
//
       FifoDeqIdle : begin
                        if(i_l2c_wb_space & (out_fifo_rd_words>15) & FifoDeqEn)
                             FifoDeqState <= #`dh FifoDeq;
                        else FifoDeqState <= #`dh FifoDeqIdle;
                     end
//
       FifoDeq     : begin
                        if(deq_cnt_end)
                             FifoDeqState <= #`dh FifoDeqIdle;
                        else FifoDeqState <= #`dh FifoDeq;
                     end
//
       default     : FifoDeqState <= #`dh FifoDeqIdle;
//
       endcase
//
    end
 end
//
 assign out_fifo_deq = (FifoDeqState==FifoDeq);
// 
// wb if 
//
 assign o_l2c_wb_valid = out_fifo_deq;
//
 always @(posedge clk_mc)  begin
    if(bctl_trc_base_ld)
       o_l2c_wb_adr <= #`dh {i_bctl_trc_base, 6'b0};
    else if(deq_cnt_end) 
       o_l2c_wb_adr <= #`dh o_l2c_wb_adr + 32'd64;
 end
//
endmodule
