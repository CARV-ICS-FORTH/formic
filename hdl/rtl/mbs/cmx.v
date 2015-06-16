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
// Abstract      : Counter and Mailbox (CMX) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: cmx.v,v $
// CVS revision  : $Revision: 1.42 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
`define MBOX_WRITE      4'b1000
`define MBOX_READ       4'b1001
`define MBOX_DEPTH_READ 4'b1011
`define SLOT_WRITE      4'b1100
`define SLOT_READ       4'b1101
`define SLOT_DEPTH_READ 4'b1111
`define COUNTER_WRITE   4'b0000
`define COUNTER_READ    4'b0001
`define COUNTER_INCR    4'b0010
//
// cmx
//
module cmx(
   input         clk_ni,
   input         rst_ni,
// CTL Interface
   input             i_cpu_interrupt,
   input             i_ctl_valid,
   input      [ 3:0] i_ctl_opcode, 
   input      [ 2:0] i_ctl_rd_len,
   input      [ 9:0] i_ctl_cnt_adr,
   input      [15:0] i_ctl_wdata,
   output            o_ctl_block_aborted,
   output reg        o_ctl_stall,
   output     [15:0] o_ctl_resp_rdata,
   output reg        o_ctl_resp_valid,
   output reg        o_ctl_resp_block,
   output reg        o_ctl_resp_unblock,
   output reg        o_ctl_int_mbox,
   output            o_ctl_int_cnt,
   output     [ 5:0] o_ctl_int_cnt_adr,
// MNI Notification Interface
   output            o_mni_valid,
   output     [15:0] o_mni_data,
   input             i_mni_stall,
// MNI mailbox occupancy
   output     [11:0] o_mni_mbox_space,
   output            o_mni_mslot_space);
//
parameter  CtlIdle    = 24'b0000_0000_0000_0000_0000_0001,
           CntRead    = 24'b0000_0000_0000_0000_0000_0010,
           CntIncr0   = 24'b0000_0000_0000_0000_0000_0100,
           CntIncr1   = 24'b0000_0000_0000_0000_0000_1000,
           CntIncr2   = 24'b0000_0000_0000_0000_0001_0000,
           CntIncr3   = 24'b0000_0000_0000_0000_0010_0000,
           MboxRead0  = 24'b0000_0000_0000_0000_0100_0000,
           MboxRead1  = 24'b0000_0000_0000_0000_1000_0000,
           MboxURead0 = 24'b0000_0000_0000_0001_0000_0000,
           MboxURead1 = 24'b0000_0000_0000_0010_0000_0000,
           MboxDepth0 = 24'b0000_0000_0000_0100_0000_0000,
           MboxDepth1 = 24'b0000_0000_0000_1000_0000_0000,
           MboxDepth2 = 24'b0000_0000_0001_0000_0000_0000,
           SlotRead0  = 24'b0000_0000_0010_0000_0000_0000,
           SlotRead1  = 24'b0000_0000_0100_0000_0000_0000,
           SlotURead0 = 24'b0000_0000_1000_0000_0000_0000,
           SlotURead1 = 24'b0000_0001_0000_0000_0000_0000,
           SlotDepth0 = 24'b0000_0010_0000_0000_0000_0000,
           SlotDepth1 = 24'b0000_0100_0000_0000_0000_0000,
           SlotDepth2 = 24'b0000_1000_0000_0000_0000_0000,
           IRQServ0   = 24'b0001_0000_0000_0000_0000_0000,
           IRQServ1   = 24'b0010_0000_0000_0000_0000_0000,
           IRQServ2   = 24'b0100_0000_0000_0000_0000_0000,
           IRQServ3   = 24'b1000_0000_0000_0000_0000_0000;
//
 reg  [23:0] CtlState;
// synthesis translate_off
 reg [256:0] CtlStateString;
 always @(CtlState) begin
   case (CtlState)
     CtlIdle    : CtlStateString = "CtlIdle";
     CntRead    : CtlStateString = "CntRead";
     CntIncr0   : CtlStateString = "CntIncr0";
     CntIncr1   : CtlStateString = "CntIncr1";
     CntIncr2   : CtlStateString = "CntIncr2";
     CntIncr3   : CtlStateString = "CntIncr3";
     MboxRead0  : CtlStateString = "MboxRead0";
     MboxRead1  : CtlStateString = "MboxRead1";
     MboxURead0 : CtlStateString = "MboxURead0";
     MboxURead1 : CtlStateString = "MboxURead1";
     MboxDepth0 : CtlStateString = "MboxDepth0";
     MboxDepth1 : CtlStateString = "MboxDepth1";
     MboxDepth2 : CtlStateString = "MboxDepth2";
     IRQServ0   : CtlStateString = "IRQServ0";
     SlotRead0  : CtlStateString = "SlotRead0";
     SlotRead1  : CtlStateString = "SlotRead1";
     SlotURead0 : CtlStateString = "SlotURead0";
     SlotURead1 : CtlStateString = "SlotURead1";
     SlotDepth0 : CtlStateString = "SlotDepth0";
     SlotDepth1 : CtlStateString = "SlotDepth1";
     SlotDepth2 : CtlStateString = "SlotDepth2";
     IRQServ1   : CtlStateString = "IRQServ1";
     IRQServ2   : CtlStateString = "IRQServ2";
     IRQServ3   : CtlStateString = "IRQServ3";
     default    : CtlStateString = "ERROR";
   endcase
 end
// synthesis translate_on
//
parameter  MniIdle   = 11'b000_0000_0001,
           MniRead0  = 11'b000_0000_0010,
           MniSend00 = 11'b000_0000_0100,
           MniSend01 = 11'b000_0000_1000,
           MniSend02 = 11'b000_0001_0000,
           MniSend03 = 11'b000_0010_0000,
           MniRead1  = 11'b000_0100_0000,
           MniSend10 = 11'b000_1000_0000,
           MniSend11 = 11'b001_0000_0000,
           MniSend12 = 11'b010_0000_0000,
           MniSend13 = 11'b100_0000_0000;
//
 reg  [10:0] MniState;
 reg  [10:0] nxt_MniState;
// synthesis translate_off
 reg [256:0] MniStateString;
 always @(MniState) begin
   case (MniState)
     MniIdle   : MniStateString = "MniIdle";
     MniRead0  : MniStateString = "MniRead0";
     MniSend00 : MniStateString = "MniSend00";
     MniSend01 : MniStateString = "MniSend01";
     MniSend02 : MniStateString = "MniSend02";
     MniSend03 : MniStateString = "MniSend03";
     MniRead1  : MniStateString = "MniRead1";
     MniSend10 : MniStateString = "MniSend10";
     MniSend11 : MniStateString = "MniSend11";
     MniSend12 : MniStateString = "MniSend12";
     MniSend13 : MniStateString = "MniSend13";
     default   : MniStateString = "ERROR";
   endcase
 end
// synthesis translate_on
//
 reg  [ 2:0] ReadCnt;
 reg  [ 2:0] RdOffset;
 reg  [ 9:0] AddrReg;
 reg  [15:0] DataReg;
 reg  [15:0] CntH;
 reg  [15:0] CntL;
 reg         Carry;
//
 reg  [31:0] slot_reg;
 reg         slot_valid;
//
 wire [15:0] cnt_mem_rdata0;
 wire [15:0] resp_data;
 wire [ 9:0] cnt_mem_addr1;
 wire [15:0] rdata1;
 wire [15:0] CntIncH;
 wire [16:0] CntIncL;
 wire        mbox_enq;
 wire        mbox_deq;
 wire        mbox_full;
 wire        mbox_empty;
 wire [10:0] mbox_wr_ptr;
 wire [10:0] mbox_rd_ptr;
 wire [11:0] mbox_wr_words;
 wire [11:0] mbox_rd_words;
 wire        mb_write_req;
 wire        sl_write_req;
 wire        mb_read_req;
 wire        sl_read_req;
 wire        mb_data_avail;
 wire        mb_depth_req;
 wire        sl_depth_req;
 wire        pend_mb_read_dt_av;
 wire        pend_sl_read_dt_av;
 wire        cnt_op;
 wire        cnt_write_req;
 wire        cnt_read_op ;
 wire        cnt_incr_req;
 wire        cnt_zero;
 wire        cnt_error;
 wire        no_increment;
 wire        mni_wait;
 wire        mni_stall;
 reg         MniStart;
//
// Cnt Zero
//
 reg cnt_L_zero;
 always @(posedge clk_ni) begin
    if(rst_ni) 
       cnt_L_zero <= #`dh 0;
    else if(CtlState==CntIncr2)
       cnt_L_zero <= #`dh (cnt_mem_rdata0==16'b0);
 end
//
 assign no_increment = (DataReg==0);
//
 assign cnt_zero  = cnt_L_zero & (CntIncH==0) & (CtlState==CntIncr3);
 assign cnt_error = no_increment & (CtlState==CntIncr3);
//
// Counter Inc Carry
//
 always @(posedge clk_ni) begin
    if(rst_ni) 
       Carry <= #`dh 1'b0;
    else if(CtlState==CntIncr1)
       Carry <= #`dh CntIncL[16];
 end
//
 always @(posedge clk_ni)
    if(CtlState==CntIncr0) DataReg <= #`dh i_ctl_wdata; 
//
 wire   Valid   = rdata1[12];
//
reg pend_mb_read_req;
reg pend_ms_read_req;
//
// CTL FSM
//
 assign cnt_op             = i_ctl_valid & (i_ctl_opcode[3:2]==2'b00);
 assign cnt_write_req      = i_ctl_valid & (i_ctl_opcode == `COUNTER_WRITE);
 assign cnt_read_req       = i_ctl_valid & (i_ctl_opcode == `COUNTER_READ);
 assign cnt_incr_req       = i_ctl_valid & (i_ctl_opcode == `COUNTER_INCR);
 assign mb_write_req       = i_ctl_valid & (i_ctl_opcode == `MBOX_WRITE);
 assign sl_write_req       = i_ctl_valid & (i_ctl_opcode == `SLOT_WRITE);
 assign mb_read_req        = i_ctl_valid & (i_ctl_opcode == `MBOX_READ);
 assign sl_read_req        = i_ctl_valid & (i_ctl_opcode == `SLOT_READ);
 assign mb_depth_req       = i_ctl_valid & (i_ctl_opcode == `MBOX_DEPTH_READ);
 assign sl_depth_req       = i_ctl_valid & (i_ctl_opcode == `SLOT_DEPTH_READ);
 assign mb_data_avail      = (mbox_rd_words >= 10'd2);
 assign sl_data_avail      = slot_valid;
 assign pend_mb_read_dt_av = pend_mb_read_req & mb_data_avail &~mb_write_req;
 assign pend_sl_read_dt_av = pend_ms_read_req & sl_data_avail &~sl_write_req;
 assign ReadCntEnd         = (ReadCnt==0);
 assign cnt_read_op        = (CtlState==CntRead);
 assign mni_wait           = (MniState!=MniIdle);
//
 always @(posedge clk_ni) begin
    if(rst_ni) CtlState <= #`dh CtlIdle;
    else begin
       case(CtlState)
//
       CtlIdle    : begin
                       if(cnt_incr_req & (MniState==MniIdle))
                          CtlState <= #`dh CntIncr0;
                       else if(cnt_read_req)
                          CtlState <= #`dh CntRead;
                       else if(mb_depth_req)
                          CtlState <= #`dh MboxDepth0;
                       else if(sl_depth_req)
                            CtlState <= #`dh SlotDepth0;
                       else if(pend_mb_read_dt_av)
                          CtlState <= #`dh MboxURead0;
                       else if(pend_sl_read_dt_av)
                            CtlState <= #`dh SlotURead0;
                       else if((pend_mb_read_req|pend_ms_read_req) & i_cpu_interrupt)
                          CtlState <= #`dh IRQServ0;
                       else if(mb_read_req) begin
                          if(mb_data_avail)
                               CtlState <= #`dh MboxRead0;
                          else CtlState <= #`dh MboxRead1;
                       end 
                       else if(sl_read_req) begin
                          if(slot_valid)
                               CtlState <= #`dh SlotRead0;
                          else CtlState <= #`dh SlotRead1;
                       end
                       else CtlState <= #`dh CtlIdle;
                    end
//
       CntRead    : begin
                       if(ReadCntEnd)
                            CtlState <= #`dh CtlIdle;
                       else CtlState <= #`dh CntRead;
                    end
//
       MboxRead0  : CtlState <= #`dh MboxRead1;
//
       MboxRead1  : CtlState <= #`dh CtlIdle;
//
       MboxURead0 : CtlState <= #`dh MboxURead1;
//
       MboxURead1 : CtlState <= #`dh CtlIdle;
//
       MboxDepth0 : CtlState <= #`dh MboxDepth1;
//
       MboxDepth1 : CtlState <= #`dh MboxDepth2;
//
       MboxDepth2 : CtlState <= #`dh CtlIdle;
//
       SlotRead0  : CtlState <= #`dh SlotRead1;
//
       SlotRead1  : CtlState <= #`dh CtlIdle;
//
       SlotURead0 : CtlState <= #`dh SlotURead1;
//
       SlotURead1 : CtlState <= #`dh CtlIdle;
//
       SlotDepth0 : CtlState <= #`dh SlotDepth1;
//
       SlotDepth1 : CtlState <= #`dh SlotDepth2;
//
       SlotDepth2 : CtlState <= #`dh CtlIdle;
//
       CntIncr0   : CtlState <= #`dh CntIncr1;
//
       CntIncr1   : CtlState <= #`dh CntIncr2;
//
       CntIncr2   : begin
                       if(mni_wait)
                            CtlState <= #`dh CntIncr2;
                       else CtlState <= #`dh CntIncr3;
                    end
//
       CntIncr3   : CtlState <= #`dh CtlIdle;
//
       IRQServ0   : CtlState <= #`dh IRQServ1;
//
       IRQServ1   : CtlState <= #`dh IRQServ2;
//
       IRQServ2   : CtlState <= #`dh IRQServ3;
//
       IRQServ3   : CtlState <= #`dh CtlIdle;
//
       default    : CtlState <= #`dh CtlIdle;
//
       endcase
    end
 end
//
 wire RegLd = (CtlState==CtlIdle);
 always @(posedge clk_ni) begin
    if(RegLd) AddrReg <= #`dh i_ctl_cnt_adr;
 end
//
// ReadPortAddr
// 
 reg  [ 6:0] ReadPortAddr;
 wire [ 2:0] ReadPortAddrOffset =
              (nxt_MniState==MniRead0)   ? 3'h6 : // V0
              (nxt_MniState==MniSend00)  ? 3'h6 : // board/node 0
              (nxt_MniState==MniSend01)  ? 3'h3 : // adr0 high
              (nxt_MniState==MniSend02)  ? 3'h2 : // adr0 low
              (nxt_MniState==MniRead1)   ? 3'h7 : // V1
              (nxt_MniState==MniSend10)  ? 3'h7 : // board/node 1
              (nxt_MniState==MniSend11)  ? 3'h5 : // adr1 high
              (nxt_MniState==MniSend12)  ? 3'h4 : // adr1 low
                                           3'bx;
//
 always @(posedge clk_ni)  begin
    if(rst_ni)                    ReadPortAddr <= #`dh 0;
    else if(cnt_zero | cnt_error) ReadPortAddr <= #`dh AddrReg[9:3];
 end
 assign cnt_mem_addr1 = {ReadPortAddr,ReadPortAddrOffset};
//
// ReadCnt
//
 wire ReadCntLd  = (CtlState==CtlIdle) & cnt_read_req;
 wire ReadCntDec = (CtlState==CntRead);
 always @(posedge clk_ni) begin
    if(rst_ni)          ReadCnt <= #`dh 0;
    else if(ReadCntLd)  ReadCnt <= #`dh i_ctl_rd_len;
    else if(ReadCntDec) ReadCnt <= #`dh ReadCnt - 3'b1;
 end
//
// Counter Read Offset
//
 wire RdOffsetClr = (CtlState==CtlIdle) & cnt_read_req;
 wire RdOffsetInc = (CtlState==CntRead);
 always @(posedge clk_ni) begin
    if(RdOffsetClr)      RdOffset <= #`dh 3'b0;
    else if(RdOffsetInc) RdOffset <= #`dh RdOffset + 3'b1;
 end
//
// Pending Read Req
//
 wire pend_mb_read_req_set = (CtlState==CtlIdle) & mb_read_req &~mb_data_avail;
//
 wire pend_mb_read_req_clr = (CtlState==MboxURead0) | (CtlState==IRQServ0);
 always @(posedge clk_ni) begin
    if(rst_ni) pend_mb_read_req <= #`dh 0;
    else begin
       if(pend_mb_read_req_set)
          pend_mb_read_req <= #`dh 1;
       else if(pend_mb_read_req_clr)
          pend_mb_read_req <= #`dh 0;
    end
 end
//
 wire pend_ms_read_req_set = (CtlState==CtlIdle) & sl_read_req &~sl_data_avail;
//
 wire pend_ms_read_req_clr = (CtlState==SlotURead0) | (CtlState==IRQServ0);
 always @(posedge clk_ni) begin
    if(rst_ni) pend_ms_read_req <= #`dh 0;
    else begin
       if(pend_ms_read_req_set)
          pend_ms_read_req <= #`dh 1;
       else if(pend_ms_read_req_clr)
          pend_ms_read_req <= #`dh 0;
    end
 end
//
// Mem george
//
////////////////////////////////////////////////////////////////////////////////
//
 reg         mbox_men_rd0, mbox_men_rd1;
//
 wire [15:0] mbox_men_rdata0, mbox_men_rdata1;
//
 wire [ 1:0] mbox_men_wen   = mbox_enq ? 2'b11 : 2'b00;
//
 wire [10:0] mbox_men_adr   = mb_write_req ? mbox_wr_ptr : mbox_rd_ptr;
//
 wire [15:0] mbox_men_wdata = i_ctl_wdata;
//
 wire        mbox_men_en0   = ~mbox_men_adr[10];
 wire        mbox_men_en1   =  mbox_men_adr[10];
//
xil_mem_sp_1024x16 mboxmem0(
  .clk      ( clk_ni ),
  .i_en     ( mbox_men_en0 ),
  .i_wen    ( mbox_men_wen ),
  .i_adr    ( mbox_men_adr[9:0] ),
  .i_wdata  ( mbox_men_wdata ),
  .o_rdata  ( mbox_men_rdata0 ));
//
xil_mem_sp_1024x16 mboxmem1(
  .clk      ( clk_ni ),
  .i_en     ( mbox_men_en1 ),
  .i_wen    ( mbox_men_wen ),
  .i_adr    ( mbox_men_adr[9:0] ),
  .i_wdata  ( mbox_men_wdata ),
  .o_rdata  ( mbox_men_rdata1 ));
//
 always @(posedge clk_ni) mbox_men_rd0 <= #`dh mbox_men_en0;
 always @(posedge clk_ni) mbox_men_rd1 <= #`dh mbox_men_en1;
//
 wire [15:0] mbox_men_rdata = mbox_men_rd0 ? mbox_men_rdata0 :
                                             mbox_men_rdata1;
//
//////////////////////////////////////////////////////////////
//
 wire [ 1:0] cnt_mem_wen0   = (cnt_write_req | 
                               (CtlState==CntIncr1) |
                               (CtlState==CntIncr3)) ? 2'b11 : 2'b0;
//
 assign      CntIncL = cnt_mem_rdata0 + DataReg;
 assign      CntIncH = cnt_mem_rdata0 + (Carry ? 16'b1 : 16'b0);
//
 wire [15:0] cnt_mem_wdata0 = (CtlState==CntIncr1) ? CntIncL[15:0] :
                              (CtlState==CntIncr3) ? CntIncH       :
                                                     i_ctl_wdata;
//
 wire [ 9:0] cnt_mem_addr0  = (CtlState==CntIncr0)     ? {AddrReg[9:3],3'b000} : 
                              (CtlState==CntIncr1)     ? {AddrReg[9:3],3'b000} :
                              (CtlState==CntIncr2)     ? {AddrReg[9:3],3'b001} :
                              (CtlState==CntIncr3)     ? {AddrReg[9:3],3'b001} :
                              (cnt_op)                 ? {i_ctl_cnt_adr}       :
                              cnt_read_op              ? {(AddrReg + {RdOffset[2:1],~RdOffset[0]})} :
                                                         10'b0;
//
xil_mem_dp_1024x16 cnt_mem(
   .clk0     (clk_ni),
   .i_en0    (1'b1),
   .i_wen0   (cnt_mem_wen0),
   .i_adr0   (cnt_mem_addr0),
   .i_wdata0 (cnt_mem_wdata0),
   .o_rdata0 (cnt_mem_rdata0),
   .clk1     (clk_ni),
   .i_en1    (1'b1),
   .i_wen1   (2'b00),
   .i_adr1   (cnt_mem_addr1),
   .i_wdata1 (16'b0),
   .o_rdata1 (rdata1));
//
 reg cnt_data_out_sel;
 always @(posedge clk_ni)  cnt_data_out_sel <= #`dh (CtlState==CntRead);
 assign resp_data = cnt_data_out_sel ? cnt_mem_rdata0 : mbox_men_rdata;
//
////////////////////////////////////////////////////////////////////////////////
//
//
 assign mbox_enq = mb_write_req;
 assign mbox_deq = (CtlState==MboxRead0)  | (CtlState==MboxRead1) |
                   (CtlState==MboxURead0) | (CtlState==MboxURead1);
//
// mbox_rd_ptr mbox_wr_ptr
//
fifo_align_ptr # (
  
  // Paremeters
  .N_log              ( 11 ),
  .RD_PTR_UNBUF       ( 0 ),
  .NEED_WR_WORDS      ( 1 ),
  .NEED_RD_WORDS      ( 1 )

) i0_fifo_align_ptr (
  
  // Write side
  .clk_wr             ( clk_ni ),
  .rst_wr             ( rst_ni ),
  .i_wr_advance       ( mbox_enq ),
  .o_wr_full          ( mbox_full ),
  .o_wr_ptr           ( mbox_wr_ptr ),
  .o_wr_words         ( mbox_wr_words ),

  // Read side
  .clk_rd             ( clk_ni ),
  .rst_rd             ( rst_ni ),
  .i_rd_advance       ( mbox_deq ),
  .o_rd_empty         ( mbox_empty ),
  .o_rd_ptr_nxt       ( mbox_rd_ptr ),
  .o_rd_words         ( mbox_rd_words )
);
//
 assign o_mni_mbox_space = mbox_wr_words;
//
// ctl out regs
//
 reg ctl_resp_valid;
 reg ctl_resp_block;
 reg ctl_resp_unblock;
 reg SlotRegSelH, SlotRegSelL;
//
 always @(posedge clk_ni) SlotRegSelH <= #`dh ((CtlState==SlotRead0)|(CtlState==SlotURead0));
 always @(posedge clk_ni) SlotRegSelL <= #`dh ((CtlState==SlotRead1)|(CtlState==SlotURead1));
//
 always @(posedge clk_ni) begin
    if(rst_ni) begin
       ctl_resp_valid     <= #`dh 0;
       ctl_resp_block     <= #`dh 0;
       ctl_resp_unblock   <= #`dh 0;
       
       o_ctl_stall          <= #`dh 0;
       o_ctl_resp_valid     <= #`dh 0;
       o_ctl_resp_block     <= #`dh 0;
       o_ctl_resp_unblock   <= #`dh 0;

    end
    else begin
       o_ctl_stall          <= #`dh ((CtlState==CtlIdle) & 
                                     (mb_depth_req |
                                      sl_depth_req |
                                      cnt_read_req |
                                      pend_mb_read_dt_av |
                                      pend_sl_read_dt_av |
                                      (mb_read_req & mb_data_avail) | 
                                      (sl_read_req & sl_data_avail) |
                                      (cnt_incr_req & (MniStart | mni_wait)))) |
                                    (CtlState==MboxRead0) |
                                    (CtlState==MboxDepth0) |
                                    (CtlState==SlotRead0) |
                                    (CtlState==SlotDepth0) |
                                    ((CtlState==CntRead) &~ReadCntEnd) |
                                    (CtlState==CntIncr0) |
                                    (CtlState==CntIncr1) |
                                    (CtlState==CntIncr2);
//
       ctl_resp_valid       <= #`dh ((CtlState==CtlIdle) &
                                     (mb_depth_req |
                                      sl_depth_req |
                                      cnt_read_req |
                                      pend_mb_read_dt_av |
                                      pend_sl_read_dt_av |
                                      (mb_read_req & mb_data_avail)|
                                      (sl_read_req & sl_data_avail))) |
                                    (CtlState==MboxRead0) |
                                    (CtlState==MboxURead0) | 
                                    (CtlState==MboxDepth0) |
                                    (CtlState==SlotRead0) |
                                    (CtlState==SlotURead0) |
                                    (CtlState==SlotDepth0) |
                                    (CtlState==IRQServ0) | 
                                    (CtlState==IRQServ1) | 
                                    ((CtlState==CntRead) &~ReadCntEnd);
//
       ctl_resp_block       <= #`dh (CtlState==MboxRead1) & pend_mb_read_req |
                                    (CtlState==SlotRead1) & pend_ms_read_req;
       ctl_resp_unblock     <= #`dh ((CtlState==CtlIdle) & (pend_mb_read_dt_av|pend_sl_read_dt_av)) |
                                     (CtlState==MboxURead0) |
                                     (CtlState==SlotURead0) |
                                     (CtlState==IRQServ0) |
                                     (CtlState==IRQServ1);
//
       o_ctl_resp_valid     <= #`dh ctl_resp_valid;
       o_ctl_resp_block     <= #`dh ctl_resp_block;
       o_ctl_resp_unblock   <= #`dh ctl_resp_unblock;
    end
 end
 assign o_ctl_resp_rdata = (CtlState==MboxDepth1) ? {3'b0, mbox_wr_words, 1'b0}:
                           (CtlState==MboxDepth2) ? {3'b0, mbox_rd_words, 1'b0}:
                           (CtlState==SlotDepth1) ? 16'b0:
                           (CtlState==SlotDepth2) ? {13'b0,slot_valid,2'b0}:
                           SlotRegSelH ? slot_reg[31:16] :
                           SlotRegSelL ? slot_reg[15: 0] :
                           ((CtlState==IRQServ2) | 
                            (CtlState==IRQServ3)) ? 16'b0 : resp_data;
//
// MNI FSM
//
 always @(posedge clk_ni) MniStart <= #`dh (cnt_zero | cnt_error);
 always @(posedge clk_ni) begin
    if(rst_ni) MniState <= #`dh MniIdle;
    else       MniState <= #`dh nxt_MniState;
 end
//
 always @(*) begin
       case(MniState)
//
       MniIdle    : begin
                       if(MniStart)
                            nxt_MniState <= #`dh MniRead0;
                       else nxt_MniState <= #`dh MniIdle;
                    end
//
       MniRead0   : begin
                       if(Valid)
                          nxt_MniState <= #`dh MniSend00;
                       else 
                          nxt_MniState <= #`dh MniRead1;
                    end
//
       MniSend00  : begin
                       if (mni_stall)
                          nxt_MniState <= #`dh MniSend00;
                       else
                          nxt_MniState <= #`dh MniSend01;
                    end
//
       MniSend01  : begin
                       if (mni_stall)
                          nxt_MniState <= #`dh MniSend01;
                       else
                          nxt_MniState <= #`dh MniSend02;
                    end
//
       MniSend02  : begin
                       if (mni_stall)
                          nxt_MniState <= #`dh MniSend02;
                       else
                          nxt_MniState <= #`dh MniSend03;
                    end
//
       MniSend03  : begin
                       if (mni_stall)
                          nxt_MniState <= #`dh MniSend03;
                       else
                          nxt_MniState <= #`dh MniRead1;
                    end
//
       MniRead1   : begin
                       if(Valid)
                          nxt_MniState <= #`dh MniSend10;
                       else 
                          nxt_MniState <= #`dh MniIdle;
                    end
//
       MniSend10  : begin
                       if (mni_stall)
                          nxt_MniState <= #`dh MniSend10;
                       else
                          nxt_MniState <= #`dh MniSend11;
                    end
//
       MniSend11  : begin
                       if (mni_stall)
                          nxt_MniState <= #`dh MniSend11;
                       else
                          nxt_MniState <= #`dh MniSend12;
                    end
//
       MniSend12  : begin
                       if (mni_stall)
                          nxt_MniState <= #`dh MniSend12;
                       else
                          nxt_MniState <= #`dh MniSend13;
                    end
//
       MniSend13  : begin
                       if (mni_stall)
                          nxt_MniState <= #`dh MniSend13;
                       else
                          nxt_MniState <= #`dh MniIdle;
                    end
//
       default    : nxt_MniState <= #`dh MniIdle;
//
       endcase
 end
//
 wire mni_valid = (MniState==MniSend00) |
                  (MniState==MniSend01) |
                  (MniState==MniSend02) |
                  (MniState==MniSend03) |
                  (MniState==MniSend10) |
                  (MniState==MniSend11) |
                  (MniState==MniSend12) |
                  (MniState==MniSend13);

 wire [15:0] mni_data = ((MniState==MniSend00) | 
                         (MniState==MniSend10)) ? rdata1 & 16'h0FFF : 
                        ((MniState==MniSend03) |
                         (MniState==MniSend13)) ? {15'b0, ~no_increment} :
                                                  rdata1;
//
align_clk_sync_2 # (
  .N       ( 16 )
) i0_align_clk_sync_2 (
  .clk_in  ( clk_ni ),
  .rst_in  ( rst_ni ),
  .i_data  ( mni_data ),
  .i_valid ( mni_valid ),
  .o_stall ( mni_stall ),
  .clk_out ( clk_ni ),
  .rst_out ( rst_ni ),
  .o_data  ( o_mni_data ),
  .o_valid ( o_mni_valid ),
  .i_stall ( i_mni_stall ) 
);
//
// CTL Interrupts
//
 assign o_ctl_int_cnt     = cnt_zero | cnt_error;
 assign o_ctl_int_cnt_adr = AddrReg[8:3];
//
// o_ctl_int_mbox
//
 reg mbox_empty_reg, mslot_empty_reg;
 always @(posedge clk_ni) begin
    if(rst_ni) begin
       mbox_empty_reg  <= #`dh 0;
       mslot_empty_reg <= #`dh 0;
       o_ctl_int_mbox  <= #`dh 0;
    end
    else begin
       mbox_empty_reg  <= #`dh mbox_empty;
       mslot_empty_reg <= #`dh~slot_valid;
       o_ctl_int_mbox  <= #`dh (mbox_empty_reg  &~mbox_empty) |
                               (mslot_empty_reg & slot_valid);
    end
 end
//
 assign o_ctl_block_aborted = (CtlState==IRQServ1);
//
// Slot
//
 reg slot_wr_h;
 always @(posedge clk_ni) begin
    if(rst_ni) begin
       slot_wr_h  <= #`dh 1;
       slot_valid <= #`dh 0;
    end
    else begin
       if(sl_write_req) begin
          if(slot_wr_h)
             slot_reg[31:16] <= #`dh  i_ctl_wdata;
          else begin
             slot_reg[15: 0] <= #`dh  i_ctl_wdata;
             slot_valid      <= #`dh 1;
          end
          slot_wr_h <= #`dh~slot_wr_h;
       end
       if((CtlState==SlotRead1) ||
          (CtlState==SlotURead1))
          slot_valid <= #`dh 0;
    end
 end
//
 assign o_mni_mslot_space =~slot_valid;
//
endmodule
