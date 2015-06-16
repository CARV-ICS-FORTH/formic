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
// Abstract      : MNI DMA engine
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni_dma.v,v $
// CVS revision  : $Revision: 1.36 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

`define READP_VC        2'b10
`define WRITEP_VC       2'b01
`define ACKP_VC         2'b00

module mni_dma (

  // Clocks and resets
  input             clk_ni,
  input             rst_ni,

  // Static configuration
  input       [7:0] i_board_id,
  input       [3:0] i_node_id,

  // L2C Read Interface
  output            o_l2c_read_valid,
  output     [31:0] o_l2c_read_adr,
  output            o_l2c_read_ignore,
  input             i_l2c_read_stall,
  input             i_l2c_read_nack,
  input      [31:0] i_l2c_data,

  // Network Operation FIFO interface
  input      [15:0] i_netop_fifo_rd_data,
  output      [3:0] o_netop_fifo_rd_offset,
  output            o_netop_fifo_rd_eop,
  input             i_netop_fifo_empty,

  // CTL Operation FIFO interface
  input      [15:0] i_cpuop_fifo_rd_data,
  output      [3:0] o_cpuop_fifo_rd_offset,
  output            o_cpuop_fifo_rd_eop,
  input             i_cpuop_fifo_empty,

  // Read FIFO interface
  output     [15:0] o_read_fifo_wr_data,
  output            o_read_fifo_wr_en,
  input      [15:0] i_read_fifo_rd_data,
  output            o_read_fifo_rd_en,

  // out interface
  output      [1:0] o_out_req,
  input             i_out_ack,
  output reg  [5:0] o_out_offset,
  output reg  [2:0] o_out_enq,
  output reg [15:0] o_out_data,
  output reg        o_out_eop
);
//
parameter Idle       = 37'b0_0000_0000_0000_0000_0000_0000_0000_0000_0001,
          ReadOp     = 37'b0_0000_0000_0000_0000_0000_0000_0000_0000_0010,
          L2Req      = 37'b0_0000_0000_0000_0000_0000_0000_0000_0000_0100,

          WrMessReq  = 37'b0_0000_0000_0000_0000_0000_0000_0000_0000_1000,
          WrMessHdr0 = 37'b0_0000_0000_0000_0000_0000_0000_0000_0001_0000,
          WrMessHdr1 = 37'b0_0000_0000_0000_0000_0000_0000_0000_0010_0000,
          WrMessHdr2 = 37'b0_0000_0000_0000_0000_0000_0000_0000_0100_0000,
          WrMessHdr3 = 37'b0_0000_0000_0000_0000_0000_0000_0000_1000_0000,
          WrMessHdr4 = 37'b0_0000_0000_0000_0000_0000_0000_0001_0000_0000,
          WrMessHdr5 = 37'b0_0000_0000_0000_0000_0000_0000_0010_0000_0000,
          WrMessHdr6 = 37'b0_0000_0000_0000_0000_0000_0000_0100_0000_0000,
          WrMessMSG0 = 37'b0_0000_0000_0000_0000_0000_0000_1000_0000_0000,
          WrMessMSG1 = 37'b0_0000_0000_0000_0000_0000_0001_0000_0000_0000,
          WrMessMSG2 = 37'b0_0000_0000_0000_0000_0000_0010_0000_0000_0000,
          WrMessMSG3 = 37'b0_0000_0000_0000_0000_0000_0100_0000_0000_0000,
          RdPcktReq  = 37'b0_0000_0000_0000_0000_0000_1000_0000_0000_0000,
          RdPcktSrv0 = 37'b0_0000_0000_0000_0000_0001_0000_0000_0000_0000,
          RdPcktSrv1 = 37'b0_0000_0000_0000_0000_0010_0000_0000_0000_0000,
          RdPcktSrv2 = 37'b0_0000_0000_0000_0000_0100_0000_0000_0000_0000,
          RdPcktSrv3 = 37'b0_0000_0000_0000_0000_1000_0000_0000_0000_0000,
          RdPcktSrv4 = 37'b0_0000_0000_0000_0001_0000_0000_0000_0000_0000,
          RdPcktSrv5 = 37'b0_0000_0000_0000_0010_0000_0000_0000_0000_0000,
          RdPcktSrv6 = 37'b0_0000_0000_0000_0100_0000_0000_0000_0000_0000,
          RdPcktSrv7 = 37'b0_0000_0000_0000_1000_0000_0000_0000_0000_0000,
          RdPcktSrv8 = 37'b0_0000_0000_0001_0000_0000_0000_0000_0000_0000,
          RdPcktSrv9 = 37'b0_0000_0000_0010_0000_0000_0000_0000_0000_0000,
          RdPcktSrvA = 37'b0_0000_0000_0100_0000_0000_0000_0000_0000_0000,
          RdPcktSrvB = 37'b0_0000_0000_1000_0000_0000_0000_0000_0000_0000,
          WrPcktReq  = 37'b0_0000_0001_0000_0000_0000_0000_0000_0000_0000,
          WrPcktHdr0 = 37'b0_0000_0010_0000_0000_0000_0000_0000_0000_0000,
          WrPcktHdr1 = 37'b0_0000_0100_0000_0000_0000_0000_0000_0000_0000,
          WrPcktHdr2 = 37'b0_0000_1000_0000_0000_0000_0000_0000_0000_0000,
          WrPcktHdr3 = 37'b0_0001_0000_0000_0000_0000_0000_0000_0000_0000,
          WrPcktHdr4 = 37'b0_0010_0000_0000_0000_0000_0000_0000_0000_0000,
          WrPcktHdr5 = 37'b0_0100_0000_0000_0000_0000_0000_0000_0000_0000,
          WrPcktHdr6 = 37'b0_1000_0000_0000_0000_0000_0000_0000_0000_0000,
          WrPcktData = 37'b1_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//
reg  [36:0] DmaState;
// synthesis translate_off
reg [256:0] DmaStateString;
always @(DmaState) begin
  case (DmaState)
    Idle       : DmaStateString = "Idle";
    ReadOp     : DmaStateString = "ReadOp";
    L2Req      : DmaStateString = "L2Req";
    WrMessReq  : DmaStateString = "WrMessReq";
    WrMessHdr0 : DmaStateString = "WrMessHdr0";
    WrMessHdr1 : DmaStateString = "WrMessHdr1";
    WrMessHdr2 : DmaStateString = "WrMessHdr2";
    WrMessHdr3 : DmaStateString = "WrMessHdr3";
    WrMessHdr4 : DmaStateString = "WrMessHdr4";
    WrMessHdr5 : DmaStateString = "WrMessHdr5";
    WrMessHdr6 : DmaStateString = "WrMessHdr6";
    WrMessMSG0 : DmaStateString = "WrMessMSG0";
    WrMessMSG1 : DmaStateString = "WrMessMSG1";
    WrMessMSG2 : DmaStateString = "WrMessMSG2";
    WrMessMSG3 : DmaStateString = "WrMessMSG3";
    RdPcktReq  : DmaStateString = "RdPcktReq";
    RdPcktSrv0 : DmaStateString = "RdPcktSrv0";
    RdPcktSrv1 : DmaStateString = "RdPcktSrv1";
    RdPcktSrv2 : DmaStateString = "RdPcktSrv2";
    RdPcktSrv3 : DmaStateString = "RdPcktSrv3";
    RdPcktSrv4 : DmaStateString = "RdPcktSrv4";
    RdPcktSrv5 : DmaStateString = "RdPcktSrv5";
    RdPcktSrv6 : DmaStateString = "RdPcktSrv6";
    RdPcktSrv7 : DmaStateString = "RdPcktSrv7";
    RdPcktSrv8 : DmaStateString = "RdPcktSrv8";
    RdPcktSrv9 : DmaStateString = "RdPcktSrv9";
    RdPcktSrvA : DmaStateString = "RdPcktSrvA";
    RdPcktSrvB : DmaStateString = "RdPcktSrvB";
    WrPcktReq  : DmaStateString = "WrPcktReq";
    WrPcktHdr0 : DmaStateString = "WrPcktHdr0";
    WrPcktHdr1 : DmaStateString = "WrPcktHdr1";
    WrPcktHdr2 : DmaStateString = "WrPcktHdr2";
    WrPcktHdr3 : DmaStateString = "WrPcktHdr3";
    WrPcktHdr4 : DmaStateString = "WrPcktHdr4";
    WrPcktHdr5 : DmaStateString = "WrPcktHdr5";
    WrPcktHdr6 : DmaStateString = "WrPcktHdr6";
    WrPcktData : DmaStateString = "WrPcktData";
    default    : DmaStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
reg  [ 5:0] Cnt;
reg  [25:0] SrcAddr;
reg  [25:0] AddrOffset;
reg  [14:0] Size;
reg  [ 5:0] OpCd;
reg         Local;
reg         Memory;
reg  [ 7:0] MemoryBoardID;
reg         ReqFromDram;
reg         Hdr0Sel_q;
reg         MemDstSel_q;
reg         MemSizeHSel_q;
reg         MemSizeLSel_q;
reg         AddrAderSel_q;
reg         RdFifoSel_q;
reg  [ 3:0] RdFifoOffset;
//
wire        CntEnd;
wire        DmaEnd;
wire        NetOpSel;
wire        CtlOpSel;
wire        net_eop;
//
wire op_fifo_eop = ((DmaState==WrMessMSG1) &~OpCd[0]) |
                   (DmaState==WrMessMSG3) |
                   ((DmaState==RdPcktSrvB) &~((Memory &~DmaEnd) | (ReqFromDram &~DmaEnd))) |
                   ((DmaState==WrPcktData) & CntEnd & DmaEnd);
//
assign        o_netop_fifo_rd_eop = NetOpSel & op_fifo_eop;
assign        o_cpuop_fifo_rd_eop = CtlOpSel & op_fifo_eop;
//
assign        o_netop_fifo_rd_offset = RdFifoOffset;
assign        o_cpuop_fifo_rd_offset = RdFifoOffset;
//
 wire [15:0] op_fifo_data = NetOpSel ? i_netop_fifo_rd_data : i_cpuop_fifo_rd_data;
//
// L2C Read
//
 wire read_data_enq = ~i_l2c_read_stall &~i_l2c_read_nack;
 reg rd_dt_selL;
 always @(posedge clk_ni) begin
    if(rst_ni)
       rd_dt_selL <= #`dh 0;
    else if(read_data_enq)
       rd_dt_selL <= #`dh~rd_dt_selL;
 end
//
// Read align fifo
//
assign o_read_fifo_wr_data = rd_dt_selL ? i_l2c_data[15:0] : i_l2c_data[31:16];
assign o_read_fifo_wr_en = read_data_enq;
assign o_read_fifo_rd_en = RdFifoSel_q;//(DmaState==WrPcktData);
//
//  Operation Fifo Select
//
 wire NetOpReq =~i_netop_fifo_empty;
 wire CtlOpReq =~i_cpuop_fifo_empty;
//
rr_penf2 fifoSelect(
     .Clk    ( clk_ni ),
     .Reset  ( rst_ni ),
     .i_reqa ( NetOpReq ),
     .i_reqb ( CtlOpReq ),
     .i_ld   ( (DmaState==Idle) & (NetOpReq | CtlOpReq) ),
     .o_gnta ( NetOpSel ),
     .o_gntb ( CtlOpSel ));
//
// FSM
//
wire Message = ~OpCd[1];
//
 always @(posedge clk_ni) begin
    if(rst_ni)
       DmaState <= #`dh Idle;
     else begin
        case (DmaState)
        Idle       : begin
                        if(NetOpReq | CtlOpReq)
                             DmaState <= #`dh ReadOp;
                        else DmaState <= #`dh Idle;
                     end
//
        ReadOp     : begin
                        if(CntEnd) begin
                           if(Message)
                                DmaState <= #`dh WrMessReq;
                           else if(Local)
                                DmaState <= #`dh L2Req;
                           else DmaState <= #`dh RdPcktReq;
                        end
                        else DmaState <= #`dh ReadOp ;
                     end
//
        WrMessReq  : begin
                        if(i_out_ack)
                             DmaState <= #`dh WrMessHdr0;
                        else DmaState <= #`dh WrMessReq;
                     end
//
        WrMessHdr0 : DmaState <= #`dh WrMessHdr1;
//
        WrMessHdr1 : DmaState <= #`dh WrMessHdr2;
//
        WrMessHdr2 : DmaState <= #`dh WrMessHdr3;
//
        WrMessHdr3 : begin
                        if(OpCd[2])
                             DmaState <= #`dh WrMessHdr4;
                        else DmaState <= #`dh WrMessMSG0;
                     end
        WrMessHdr4 : DmaState <= #`dh WrMessHdr5;
//
        WrMessHdr5 : DmaState <= #`dh WrMessHdr6;
//
        WrMessHdr6 : DmaState <= #`dh WrMessMSG0;
//
        WrMessMSG0 : DmaState <= #`dh WrMessMSG1;
//
        WrMessMSG1 : begin
                        if(OpCd[0]) 
                              DmaState <= #`dh WrMessMSG2;
                         else DmaState <= #`dh Idle;
                     end
        WrMessMSG2 : DmaState <= #`dh WrMessMSG3;
//
        WrMessMSG3 : DmaState <= #`dh Idle;
//
        RdPcktReq  : begin
                        if(i_out_ack)
                             DmaState <= #`dh RdPcktSrv0;
                        else DmaState <= #`dh RdPcktReq;
                     end
//
        RdPcktSrv0 : DmaState <= #`dh RdPcktSrv1;
//
        RdPcktSrv1 : DmaState <= #`dh RdPcktSrv2;
//
        RdPcktSrv2 : DmaState <= #`dh RdPcktSrv3;
//
        RdPcktSrv3 : begin
                        if(OpCd[2])
                             DmaState <= #`dh RdPcktSrv4;
                        else DmaState <= #`dh RdPcktSrv7;
                     end
//
        RdPcktSrv4 : DmaState <= #`dh RdPcktSrv5;
//
        RdPcktSrv5 : DmaState <= #`dh RdPcktSrv6;
//
        RdPcktSrv6 : DmaState <= #`dh RdPcktSrv7;
//
        RdPcktSrv7 : DmaState <= #`dh RdPcktSrv8;
        RdPcktSrv8 : DmaState <= #`dh RdPcktSrv9;
        RdPcktSrv9 : DmaState <= #`dh RdPcktSrvA;
        RdPcktSrvA : DmaState <= #`dh RdPcktSrvB;
//
        RdPcktSrvB : begin
                        if(ReqFromDram &~DmaEnd)
                             DmaState <= #`dh L2Req;
                        else if(Memory &~DmaEnd) 
                             DmaState <= #`dh RdPcktReq;
                        else DmaState <= #`dh Idle;
                     end
//
        L2Req      : begin
                        if(~i_l2c_read_stall) begin
                           if(i_l2c_read_nack)
                                DmaState <= #`dh RdPcktReq;
                           else DmaState <= #`dh WrPcktReq;
                        end
                        else DmaState <= #`dh L2Req;
                     end
//
        WrPcktReq  : begin
                        if(i_out_ack)
                               DmaState <= #`dh WrPcktHdr0;
                          else DmaState <= #`dh WrPcktReq;
                       end
//
        WrPcktHdr0 : DmaState <= #`dh WrPcktHdr1;
//
        WrPcktHdr1 : DmaState <= #`dh WrPcktHdr2;
//
        WrPcktHdr2 : DmaState <= #`dh WrPcktHdr3;
//
        WrPcktHdr3 : begin
                        if(OpCd[2])
                             DmaState <= #`dh WrPcktHdr4;
                        else DmaState <= #`dh WrPcktData;
                     end
//
        WrPcktHdr4 : DmaState <= #`dh WrPcktHdr5;
//
        WrPcktHdr5 : DmaState <= #`dh WrPcktHdr6;
//
        WrPcktHdr6 : DmaState <= #`dh WrPcktData;
//
        WrPcktData : begin
                        if(CntEnd) begin
                           if(DmaEnd)
                                DmaState <= #`dh Idle;
                           else DmaState <= #`dh L2Req;
                        end
                        else DmaState <= #`dh WrPcktData;
                     end
//
        default    : DmaState <= #`dh Idle;
//
        endcase
     end
 end
//
// Cnt
//
 wire CntClr = (DmaState==Idle) | rst_ni;
 wire CntInc = (DmaState==ReadOp)     |
               (DmaState==WrPcktData);
 always @(posedge clk_ni) begin
    if(CntClr)
        Cnt <= #`dh 0;
    else if(DmaState==WrPcktHdr0)
        Cnt <= #`dh 6'h7;
    else if(CntInc)
       Cnt <= #`dh Cnt + 6'b1;
 end
 assign CntEnd = (Cnt==((DmaState==ReadOp) ? 6'h6 : 6'h26));
//
// ReqFromDram
//
always @(posedge clk_ni) begin
   if((DmaState==Idle) | (DmaState==RdPcktSrvB))
      ReqFromDram <= #`dh 1'b0;
   else if((DmaState==L2Req) &~i_l2c_read_stall & i_l2c_read_nack)
      ReqFromDram <= #`dh 1'b1;
end
//
// Packet Parameters
// 
 wire OpLd = (DmaState==ReadOp);
 wire NextSize = (DmaState==WrPcktHdr3) |
                 (DmaState==RdPcktSrv8);
 wire NextAddr = ((DmaState==WrPcktData) & CntEnd) |
                 (DmaState==RdPcktSrvB);
//
 always @(posedge clk_ni) begin
    if(NextSize)
       Size          <= #`dh Size - 1'b1;
    if(NextAddr) begin
       SrcAddr       <= #`dh SrcAddr + 1'b1;
       AddrOffset    <= #`dh AddrOffset + 1'b1;
    end
    else if(OpLd) begin
       AddrOffset    <= #`dh 26'b0;
       if (Cnt==6'h1) OpCd        <= #`dh op_fifo_data[5:0];
       if (Cnt==6'h2) Size[14:10] <= #`dh op_fifo_data[4:0];
       if (Cnt==6'h3) Size[9: 0]  <= #`dh op_fifo_data[15:6];
       if (Cnt==6'h4) begin
                         if(OpCd[1] & 
                            (op_fifo_data[11:4]==i_board_id) &
                            (op_fifo_data[ 3:0]==i_node_id))
                               Local  <= #`dh 1'b1;    
                         if(OpCd[1] & (op_fifo_data[3:0]==4'd12)) begin
                               Memory        <= #`dh 1'b1;
                               MemoryBoardID <= #`dh op_fifo_data[11:4];
                         end
                      end
       if (Cnt==6'h5) SrcAddr[25:10] <= #`dh op_fifo_data;
       if (Cnt==6'h6) SrcAddr[ 9: 0] <= #`dh op_fifo_data[15:6];
    end
    else if(DmaState==Idle) begin
       Memory        <= #`dh 1'b0;
       MemoryBoardID <= #`dh i_board_id;
       Local         <= #`dh 1'b0;
    end
 end
//
 assign DmaEnd = (Size==0);
//
 wire   ReadPacket = (DmaState==RdPcktReq)  |
                     (DmaState==RdPcktSrv0) |
                     (DmaState==RdPcktSrv1) |
                     (DmaState==RdPcktSrv2);
//
//////////////////////////////////////////////////////////////////////////////////
//
 reg        OffsetAdderCary;
 reg  [5:0] WriteOffset;
 reg  [5:0] WriteOffset_q;
 reg        Hdr0Sel;
 reg        MemDstSel;
 reg        MemSizeHSel;
 reg        MemSizeLSel;
 reg        AddrAderHSel;
 reg        AddrAderLSel;
 reg        RdFifoSel;
//
//
//
 reg AddrAderLSelQ , AddrAderHSelQ;
 always @(posedge clk_ni) AddrAderLSelQ <= #`dh AddrAderLSel;
 always @(posedge clk_ni) AddrAderHSelQ <= #`dh AddrAderHSel;
// 
 wire [16:0] OffsetAdder = op_fifo_data + 
                           (AddrAderLSelQ ? {AddrOffset[9:0], 6'b0} : AddrOffset[25:10]) +
                           ((AddrAderHSelQ & OffsetAdderCary) ? 16'b1 : 16'b0);
//
 always @(posedge clk_ni) OffsetAdderCary <= #`dh OffsetAdder[16];
//
//
//
 always @(*) begin
//
    RdFifoOffset = 4'b0;
    WriteOffset  = 6'b0;
    Hdr0Sel      = 1'b0;
    MemDstSel    = 1'b0;
    MemSizeHSel  = 1'b0;
    MemSizeLSel  = 1'b0;
    AddrAderHSel = 1'b0;
    AddrAderLSel = 1'b0;
    RdFifoSel    = 1'b0;
//
    if((DmaState==ReadOp) & (Cnt==6'd0)) RdFifoOffset = 4'h1;
    if((DmaState==ReadOp) & (Cnt==6'd1)) RdFifoOffset = 4'h2;
    if((DmaState==ReadOp) & (Cnt==6'd2)) RdFifoOffset = 4'h3;
    if((DmaState==ReadOp) & (Cnt==6'd3)) RdFifoOffset = 4'h6;
    if((DmaState==ReadOp) & (Cnt==6'd4)) RdFifoOffset = 4'hA;
    if((DmaState==ReadOp) & (Cnt==6'd5)) RdFifoOffset = 4'hB;
// Message
    if(DmaState==WrMessHdr0) begin Hdr0Sel      = 1'b1; WriteOffset  = 6'h0; end
    if(DmaState==WrMessHdr1) begin RdFifoOffset = 4'h0; WriteOffset  = 6'h1; end
    if(DmaState==WrMessHdr2) begin RdFifoOffset = 4'h4; WriteOffset  = 6'h2; end
    if(DmaState==WrMessHdr3) begin RdFifoOffset = 4'h5; WriteOffset  = 6'h3; end
    if(DmaState==WrMessHdr4) begin RdFifoOffset = 4'h7; WriteOffset  = 6'h4; end
    if(DmaState==WrMessHdr5) begin RdFifoOffset = 4'h8; WriteOffset  = 6'h5; end
    if(DmaState==WrMessHdr6) begin RdFifoOffset = 4'h9; WriteOffset  = 6'h6; end
    if(DmaState==WrMessMSG0) begin RdFifoOffset = 4'hC; WriteOffset  = 6'h7; end
    if(DmaState==WrMessMSG1) begin RdFifoOffset = 4'hD; WriteOffset  = 6'h8; end
    if(DmaState==WrMessMSG2) begin RdFifoOffset = 4'hE; WriteOffset  = 6'h9; end
    if(DmaState==WrMessMSG3) begin RdFifoOffset = 4'hF; WriteOffset  = 6'hA; end
// Read Packet
    if(DmaState==RdPcktSrv0) begin Hdr0Sel      = 1'b1; WriteOffset  = 6'h0; end
    if(DmaState==RdPcktSrv1) begin
                                RdFifoOffset = 4'h6;
                                WriteOffset  = 8'h1;
                                if(Memory | ReqFromDram)
                                   MemDstSel = 1'b1;
                             end
    if(DmaState==RdPcktSrv2) begin RdFifoOffset = 4'hB; WriteOffset  = 6'h3; 
                                   AddrAderLSel = 1'b1; end
    if(DmaState==RdPcktSrv3) begin RdFifoOffset = 4'hA; WriteOffset  = 6'h2;
                                   AddrAderHSel  = 1'b1; end
    if(DmaState==RdPcktSrv4) begin RdFifoOffset = 4'h7; WriteOffset  = 6'h4; end
    if(DmaState==RdPcktSrv5) begin RdFifoOffset = 4'h8; WriteOffset  = 6'h5; end
    if(DmaState==RdPcktSrv6) begin RdFifoOffset = 4'h9; WriteOffset  = 6'h6; end
    if(DmaState==RdPcktSrv7) begin RdFifoOffset = 4'h0; WriteOffset  = 6'h7; end
    if(DmaState==RdPcktSrv8) begin RdFifoOffset = 4'h5; WriteOffset  = 6'h9; 
                                   AddrAderLSel = 1'b1; end
    if(DmaState==RdPcktSrv9) begin RdFifoOffset = 4'h4; WriteOffset  = 6'h8;
                                   AddrAderHSel = 1'b1; end
    if(DmaState==RdPcktSrvA) begin
                                RdFifoOffset = 4'h2;
                                WriteOffset  = 6'hA;
                                if(Memory | ReqFromDram)
                                     MemSizeHSel = 1'b1;
                             end
    if(DmaState==RdPcktSrvB) begin
                                RdFifoOffset = 4'h3;
                                WriteOffset  = 6'hB;
                                if(Memory | ReqFromDram)
                                     MemSizeLSel = 1'b1;
                             end
// Write Packet
    if(DmaState==WrPcktHdr0) begin Hdr0Sel      = 1'b1; WriteOffset  = 6'h0; end
    if(DmaState==WrPcktHdr1) begin RdFifoOffset = 4'h0; WriteOffset  = 6'h1; end
    if(DmaState==WrPcktHdr2) begin RdFifoOffset = 4'h5; WriteOffset  = 6'h3;
                                   AddrAderLSel = 1'b1; end
    if(DmaState==WrPcktHdr3) begin RdFifoOffset = 4'h4; WriteOffset  = 6'h2;
                                   AddrAderHSel = 1'b1; end
    if(DmaState==WrPcktHdr4) begin RdFifoOffset = 4'h7; WriteOffset  = 6'h4; end
    if(DmaState==WrPcktHdr5) begin RdFifoOffset = 4'h8; WriteOffset  = 6'h5; end
    if(DmaState==WrPcktHdr6) begin RdFifoOffset = 4'h9; WriteOffset  = 6'h6; end
//
    if(DmaState==WrPcktData) begin RdFifoSel    = 1'b1; WriteOffset = Cnt; end
//
 end
//
// ReadPacket -> VC 2 (either remote read, memory read or a nacked L2 read)
// Message    -> VC 1 (write packet from a Message operation)
// Otherwise  -> VC 2 (write packet from a local DMA operation which made a successful L2 read)
 wire [15:0] Hdr0 = ReadPacket ? {6'b010001,OpCd[2],OpCd[5],`READP_VC,6'h5} :
                    Message    ? {6'b000001,OpCd[2],1'b0,`WRITEP_VC,(OpCd[0] ? 6'h4 : 6'h2)} :
                                 {3'b000,OpCd[3],OpCd[4],1'b1,OpCd[2],1'b0,`READP_VC,6'h20};
//
 reg  [2:0] nout_enq;
 reg        net_eop1;
//
 always @(posedge clk_ni) begin
    WriteOffset_q  <= #`dh WriteOffset;
    Hdr0Sel_q      <= #`dh Hdr0Sel;
    MemDstSel_q    <= #`dh MemDstSel;
    MemSizeHSel_q  <= #`dh MemSizeHSel;
    MemSizeLSel_q  <= #`dh MemSizeLSel;
    AddrAderSel_q  <= #`dh (AddrAderHSel|AddrAderLSel);
    RdFifoSel_q    <= #`dh RdFifoSel;
 end
//
// Net Data Mux
//
 always @(posedge clk_ni) begin
    if(Hdr0Sel_q)          o_out_data <= #`dh Hdr0;
    else if(MemDstSel_q)   o_out_data <= #`dh {4'b0,MemoryBoardID,4'd12};
    else if(MemSizeHSel_q) o_out_data <= #`dh 16'h00;
    else if(MemSizeLSel_q) o_out_data <= #`dh 16'h40;
    else if(AddrAderSel_q) o_out_data <= #`dh OffsetAdder[15:0];
    else if(RdFifoSel_q)   o_out_data <= #`dh i_read_fifo_rd_data;
    else                   o_out_data <= #`dh op_fifo_data;
//
    nout_enq      <= #`dh ((DmaState==WrMessHdr0) |
                           (DmaState==WrMessHdr1) |
                           (DmaState==WrMessHdr2) |
                           (DmaState==WrMessHdr3) |
                           (DmaState==WrMessHdr4) |
                           (DmaState==WrMessHdr5) |
                           (DmaState==WrMessHdr6) |
                           (DmaState==WrMessMSG0) |
                           (DmaState==WrMessMSG1) |
                           (DmaState==WrMessMSG2) |
                           (DmaState==WrMessMSG3)) ? 3'b010 :
                          ((DmaState==WrPcktHdr0) |
                           (DmaState==WrPcktHdr1) |
                           (DmaState==WrPcktHdr2) |
                           (DmaState==WrPcktHdr3) |
                           (DmaState==WrPcktHdr4) |
                           (DmaState==WrPcktHdr5) |
                           (DmaState==WrPcktHdr6) |
                           (DmaState==WrPcktData) | 
                           (DmaState==RdPcktSrv0) |
                           (DmaState==RdPcktSrv1) |
                           (DmaState==RdPcktSrv2) |
                           (DmaState==RdPcktSrv3) |
                           (DmaState==RdPcktSrv4) |
                           (DmaState==RdPcktSrv5) |
                           (DmaState==RdPcktSrv6) |
                           (DmaState==RdPcktSrv7) |
                           (DmaState==RdPcktSrv8) |
                           (DmaState==RdPcktSrv9) |
                           (DmaState==RdPcktSrvA) |
                           (DmaState==RdPcktSrvB)) ? 3'b100 :  3'b000;
//
    o_out_enq     <= #`dh nout_enq;
    o_out_offset  <= #`dh WriteOffset_q;
    net_eop1      <= #`dh net_eop;
    o_out_eop     <= #`dh net_eop1;

 end
//
assign net_eop  = ((DmaState==WrMessMSG1) &~OpCd[0]) |
                   (DmaState==WrMessMSG3) |
                   (DmaState==RdPcktSrvB) |
                   ((DmaState==WrPcktData) & CntEnd);
//
//////////////////////////////////////////////////////////////////////////////////
//
 assign o_l2c_read_adr    = {SrcAddr, 6'b0};
 assign o_l2c_read_valid  = (DmaState==L2Req);
 assign o_l2c_read_ignore = OpCd[5];
//
 //wire WritePacket = (DmaState==WrMessReq) | (DmaState==WrPcktReq) | (DmaState==WrPcktData);
 //assign o_out_req = ReadPacket  ? 2'b10 :
 //                   WritePacket ? 2'b01 : 2'b00;
 assign o_out_req = (DmaState == WrMessReq) ? 2'b01 : // Messages -> VC 1, write
                    (DmaState == WrPcktReq) ? 2'b10 : // Successful L2 read -> VC 2, write
                    (DmaState == RdPcktReq) ? 2'b10 : // Failed L2 read or Memory -> VC 2, read
                    2'b00;
//
endmodule
//
// rr_penf2
//
module rr_penf2(
   input      Clk,
   input      Reset,
   input      i_reqa,
   input      i_reqb,
   input      i_ld,
   output reg o_gnta,
   output reg o_gntb);
//
 always @(posedge Clk) begin
    if(Reset) begin
       o_gnta <= #`dh 1'b0;
       o_gntb <= #`dh 1'b0;
    end
    else if(i_ld) begin
       o_gnta <= #`dh i_reqa &~i_reqb | i_reqa & i_reqb &~o_gnta;
       o_gntb <= #`dh i_reqb &~i_reqa | i_reqa & i_reqb & o_gnta;
    end
 end
//
endmodule
