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
// Abstract      : I2C Slave top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: i2c_slave.v,v $
// CVS revision  : $Revision: 1.9 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// Slave
//
module i2c_slave(
   input        Clk,
   input        Reset,
   input        SCL,
   inout        SDA,
/////////////////////////////////
   // I2C Miss Interface (clk_mc)
   output reg        o_i2c_miss_valid,
   output     [ 7:0] o_i2c_miss_adr,
   output     [ 1:0] o_i2c_miss_flags,
   output            o_i2c_miss_wen,
   output     [ 3:0] o_i2c_miss_ben,
   output     [31:0] o_i2c_miss_wdata,
   input             i_l2c_miss_stall,
   // I2C  Fill Interface (clk_mc)
   input             i_i2c_fill_valid,
   input      [31:0] i_i2c_fill_data,
   output reg        o_i2c_fill_stall,
/////////////////////////////////
   //
   input  [ 6:0] i_board_id
);
//
`define BROADCAST_ADR 7'b1111111
//
parameter Idle     = 6'b00_0001,
          ReadAdr  = 6'b00_0010,
          ReadReq  = 6'b00_0100,
          XData    = 6'b00_1000,
          WriteOp  = 6'b01_0000,
          WaitOp   = 6'b10_0000;
//
reg [5:0] SlaveState;
// synthesis translate_off
 reg [256:0] StateString;
 always @(SlaveState) begin
    case (SlaveState)
       Idle     : StateString = "Idle";
       ReadAdr  : StateString = "ReadAdr";
       ReadReq  : StateString = "ReadReq";
       XData    : StateString = "XData";
       WriteOp  : StateString = "WriteOp";
       WaitOp   : StateString = "WaitOp";
       default  : StateString = "ERROR";
    endcase
 end
 // synthesis translate_on

//
reg  [ 7:0] SDA_s;
reg  [ 7:0] SCL_s;
reg  [ 6:0] InReg;
reg  [ 5:0] BitCnt;
reg  [ 7:0] Addr;
reg  [31:0] DataOut;
reg  [ 2:0] ByteCnt;
reg  [47:0] Sreg;
wire       SDA_IN;
//
 always @(posedge Clk) begin
    
    // Metastability filter
    SDA_s[0] <= #`dh SDA_IN;
    SDA_s[1] <= #`dh SDA_s[0];
    SDA_s[2] <= #`dh SDA_s[1];

    // Glitch filter
    SDA_s[3] <= #`dh SDA_s[2];
    SDA_s[4] <= #`dh SDA_s[3];
    SDA_s[5] <= #`dh SDA_s[4];
    SDA_s[6] <= #`dh ( SDA_s[5] &  SDA_s[4] &  SDA_s[3]) ? 1'b1 :
                     (~SDA_s[5] & ~SDA_s[4] & ~SDA_s[3]) ? 1'b0 : SDA_s[6];
    SDA_s[7] <= #`dh SDA_s[6];

    // Metastability filter
    SCL_s[0] <= #`dh SCL;
    SCL_s[1] <= #`dh SCL_s[0];
    SCL_s[2] <= #`dh SCL_s[1];

    // Glitch filter
    SCL_s[3] <= #`dh SCL_s[2];
    SCL_s[4] <= #`dh SCL_s[3];
    SCL_s[5] <= #`dh SCL_s[4];
    SCL_s[6] <= #`dh ( SCL_s[5] &  SCL_s[4] &  SCL_s[3]) ? 1'b1 :
                     (~SCL_s[5] & ~SCL_s[4] & ~SCL_s[3]) ? 1'b0 : SCL_s[6];
    SCL_s[7] <= #`dh SCL_s[6];
 end
//
 wire SDA_cur = SDA_s[6];
 wire SDA_prv = SDA_s[7];
 wire SCL_cur = SCL_s[6];
 wire SCL_prv = SCL_s[7];
//
 wire start_condition = SCL_prv & SCL_cur & SDA_prv &~SDA_cur; // Falling SDA while stable SCL
 wire stop_condition  = SCL_prv & SCL_cur &~SDA_prv & SDA_cur; // Rising SDA while stable SCL
//
// BitCnt
//
 wire BitCntInc = SCL_prv &~SCL_cur;
//
 always @(posedge Clk) begin
    if(Reset | start_condition | stop_condition)
       BitCnt <= #`dh 0;
    else if(BitCntInc)
       BitCnt <= #`dh BitCnt + 1'b1;
 end
//
 reg AckGen;
 always @(posedge Clk) begin
   if(Reset | start_condition) begin
     AckGen <= #`dh 0;
   end
   else begin
     if (BitCntInc & ((BitCnt== 8) | (BitCnt==17) |
                      (BitCnt==26) | (BitCnt==35) |
                      (BitCnt==44) | (BitCnt==53)))
        AckGen <= #`dh 1'b1;
     else if (BitCntInc)
        AckGen <= #`dh 1'b0;
   end
 end
//
 wire   SDATris  = (SlaveState==WaitOp) | (SlaveState==XData);
 wire   AckDrive = AckGen &~SDATris;
 wire   DtDrive  = (SlaveState==XData) &~AckGen &~Sreg[47]; 
//
// SDA
//
 IOBUF i0_iobuf (
   .IO           ( SDA ),
   .T            ( ~(AckDrive | DtDrive) ),
   .I            ( 1'b0 ),
   .O            ( SDA_IN )
 );
//
 wire SregEn  = ~SCL_prv & SCL_cur &~AckGen & (BitCnt!=6'h37) & (SlaveState!=WaitOp);
 wire SregEnR =  SCL_prv &~SCL_cur &~AckGen & (BitCnt!=6'h37) & (SlaveState!=WaitOp);
 wire SregLd  = i_i2c_fill_valid;
 always @(posedge Clk) begin
    if(Reset | start_condition)
       Sreg <= #`dh 0;
    else if(SregLd)
       Sreg <= #`dh {i_i2c_fill_data,16'b0};
    else if((SlaveState==XData) ? SregEnR : SregEn)
       Sreg <= #`dh {Sreg[46:0],SDA_cur};
 end
//
// FSM
 wire [6:0] board_id = Sreg[7:1];
 wire       read_op  = Sreg[0];
//
 always @(posedge Clk) begin
    if(Reset) SlaveState <= #`dh Idle;
    else begin
       case(SlaveState)
          Idle     : begin
                        if(BitCnt== 9) begin
                            if ((board_id == i_board_id) ||
                                (board_id == `BROADCAST_ADR)) begin
                               if(read_op) 
                                    SlaveState <= #`dh ReadAdr;
                               else SlaveState <= #`dh WriteOp;
                            end
                            else SlaveState <= #`dh WaitOp;
                        end
                        else SlaveState <= #`dh Idle;
                     end
//
          ReadAdr  : begin
                        if((BitCnt==6'h11) & SregEn) 
                             SlaveState <= #`dh ReadReq;
                        else SlaveState <= #`dh ReadAdr;
                     end
//
          ReadReq  : begin
                        if((BitCnt==6'h12) & BitCntInc)
                             SlaveState <= #`dh XData;
                        else SlaveState <= #`dh ReadReq;
                     end
//
          XData    : begin
                        if(stop_condition)
                             SlaveState <= #`dh Idle;
                        else if((BitCnt==6'd54) & BitCntInc)
                             SlaveState <= #`dh WaitOp;
                        else SlaveState <= #`dh XData;
                     end
//
          WriteOp  : begin
                        if(stop_condition)
                             SlaveState <= #`dh Idle;
                        else SlaveState <= #`dh WriteOp;
                     end
//
          WaitOp   : begin
                        if(stop_condition)
                             SlaveState <= #`dh Idle;
                        else SlaveState <= #`dh WaitOp;
                     end
//
          default  : SlaveState <= #`dh Idle;
//
       endcase
    end
 end
//
//
//
 assign o_i2c_miss_adr   = (SlaveState==WriteOp) ? Sreg[39:32] :
                                                   Sreg[7:0];
 assign o_i2c_miss_wdata = Sreg[31: 0];
 assign o_i2c_miss_ben   = (SlaveState==WriteOp) ? 4'hF : 4'h0;
 assign o_i2c_miss_flags = 2'b01;
 assign o_i2c_miss_wen   = (SlaveState==WriteOp) &~Sreg[40];
//
 always @(posedge Clk) begin
   o_i2c_fill_stall <= #`dh ~i_i2c_fill_valid;
 end
//
 wire valid_set = SregEn & (((BitCnt==6'h35) & (SlaveState==WriteOp)) | 
                            ((BitCnt==6'h11) & (SlaveState==ReadAdr)));
                       
 always @(posedge Clk) begin
    if(SlaveState==Idle) 
       o_i2c_miss_valid <= #`dh 0;
    else if(valid_set)
       o_i2c_miss_valid <= #`dh 1;
    else if(~i_l2c_miss_stall | i_i2c_fill_valid) 
       o_i2c_miss_valid <= #`dh 0;
 end
//
endmodule
