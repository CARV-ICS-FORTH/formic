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
// Abstract      : Data L1 Cache (DL1) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: dl1.v,v $
// CVS revision  : $Revision: 1.29 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// DL1
//
module dl1(
//
 input             clk_mc,
 input             rst_mc,
// Control Block Interface
 input             i_ctl_en,
 input             i_ctl_clear_req,
 output            o_ctl_clear_ack,
 output            o_ctl_trace_hit,
 output            o_ctl_trace_miss,
// Address Region Table block (ART) Interface
 input      [31:0] i_art_adr,
 input      [ 1:0] i_art_flags,
 input      [ 3:0] i_art_ben,
 input             i_art_wen,
 input      [31:0] i_art_wdata,
 input             i_art_valid,
 output     [31:0] o_art_rdata,
 output            o_art_tlb_fault,
 output            o_art_stall,
// Level 2 Cache block (L2C) Interface
 output reg [31:0] o_l2c_adr,
 output reg [ 1:0] o_l2c_flags,
 output reg [ 3:0] o_l2c_ben,
 output reg        o_l2c_wen,
 output reg [31:0] o_l2c_wdata,
 output reg        o_l2c_valid,
 input      [31:0] i_l2c_rdata,
 input             i_l2c_rdata_valid,
 input             i_l2c_tlb_fault,
 input             i_l2c_stall,
 input      [31:0] i_l2c_inv_adr,
 input             i_l2c_inv_req,
 output            o_l2c_inv_ack);
//
parameter IdleSt       = 8'b0000_0001,
          TagMatch     = 8'b0000_0010,
          WriteMiss    = 8'b0000_0100,
          ReadMiss     = 8'b0000_1000,
          WriteHit     = 8'b0001_0000,
          WriteHitWait = 8'b0010_0000,
          ReadHit      = 8'b0100_0000,
          Retry        = 8'b1000_0000;
//
reg  [ 7:0] State;
// synthesis translate_off
reg [256:0] L1StateString;
always @(State) begin
  case (State)
    IdleSt       : L1StateString = "IdleSt";
    TagMatch     : L1StateString = "TagMatch";
    WriteMiss    : L1StateString = "WriteMiss";
    ReadMiss     : L1StateString = "ReadMiss";
    WriteHit     : L1StateString = "WriteHit";
    WriteHitWait : L1StateString = "WriteHitWait";
    ReadHit      : L1StateString = "ReadHit";
    Retry        : L1StateString = "Retry";
    default      : L1StateString = "ERROR";
  endcase
end
// synthesis translate_on
wire        l1_en;
reg  [ 2:0] w_off;
wire [ 6:0] index = i_art_adr[11: 5];
wire [31:0] RdDtW00,
            RdDtW01,
            RdDtW10,
            RdDtW11;
//
wire tag_req = ((State == IdleSt) & i_art_valid & l1_en) |
               (State == TagMatch) |
               (State == Retry);
//
wire tag_ack;
wire tag_hit;
wire tag_way;

//
l1_tags # (

  .NR_WAYS_IS_128   ( 1 )

) i0_l1_tags (
  .clk              ( clk_mc ),
  .rst              ( rst_mc ),

  // Access interface
  .i_acc_req        ( tag_req ),
  .i_acc_adr        ( i_art_adr ),
  .i_acc_wen        ( i_art_wen ),
  .o_acc_ack        ( tag_ack ),
  .o_acc_hit        ( tag_hit ),
  .o_acc_way        ( tag_way ),

  // Maintenance (clear) interface
  .i_clr_req        ( i_ctl_clear_req ),
  .o_clr_ack        ( o_ctl_clear_ack ),

  // Invalidation interface
  .i_inv_req        ( i_l2c_inv_req ),
  .i_inv_adr        ( i_l2c_inv_adr ),
  .o_inv_ack        ( o_l2c_inv_ack )
);
//
wire L1Miss  = (State == TagMatch) & tag_ack & ~tag_hit;
wire L1Hit   = (State == TagMatch) & tag_ack &  tag_hit;
//
assign o_ctl_trace_hit  = L1Hit;
assign o_ctl_trace_miss = L1Miss;
//
reg way_q;
always @(posedge clk_mc) begin
  if (tag_ack)
    way_q <= #`dh tag_way;
end
//
wire SelW00 =~index[6] & i_ctl_en & ~way_q;
wire SelW01 = index[6] & i_ctl_en & ~way_q;
wire SelW10 =~index[6] & i_ctl_en &  way_q;
wire SelW11 = index[6] & i_ctl_en &  way_q;
//
wire [31:0] dl1_wr_data = (State==ReadMiss)  ? i_l2c_rdata : i_art_wdata;
wire [ 8:0] dl1_addr    = (State==ReadMiss) ? {index[5:0], w_off} : {index[5:0], i_art_adr[4:2]};
wire [ 3:0] dl1_we_w00  = (i_l2c_rdata_valid & SelW00) ? 4'hF : 
                          ((State==WriteHit) & SelW00) ? i_art_ben : 4'b0;
wire [ 3:0] dl1_we_w01  = (i_l2c_rdata_valid & SelW01) ? 4'hF :
                          ((State==WriteHit) & SelW01) ? i_art_ben : 4'b0;
wire [ 3:0] dl1_we_w10  = (i_l2c_rdata_valid & SelW10) ? 4'hF :
                          ((State==WriteHit) & SelW10) ? i_art_ben : 4'b0;
wire [ 3:0] dl1_we_w11  = (i_l2c_rdata_valid & SelW11) ? 4'hF :
                          ((State==WriteHit) & SelW11) ? i_art_ben : 4'b0;
//
  xil_mem_sp_512x32 i0_xil_mem_sp_512x32 (
    .clk        ( clk_mc ),
    .i_en       ( l1_en ),
    .i_adr      ( dl1_addr ),
    .i_wen      ( dl1_we_w00 ),
    .i_wdata    ( dl1_wr_data ),
    .o_rdata    ( RdDtW00 ));
//
  xil_mem_sp_512x32 i1_xil_mem_sp_512x32 (
    .clk        ( clk_mc ),
    .i_en       ( l1_en ),
    .i_adr      ( dl1_addr ),
    .i_wen      ( dl1_we_w01 ),
    .i_wdata    ( dl1_wr_data ),
    .o_rdata    ( RdDtW01 ));
//
  xil_mem_sp_512x32 i2_xil_mem_sp_512x32 (
    .clk        ( clk_mc ),
    .i_en       ( l1_en ),
    .i_adr      ( dl1_addr ),
    .i_wen      ( dl1_we_w10 ),
    .i_wdata    ( dl1_wr_data ),
    .o_rdata    ( RdDtW10 ));
//
  xil_mem_sp_512x32 i3_xil_mem_sp_512x32 (
    .clk        ( clk_mc ),
    .i_en       ( l1_en ),
    .i_adr      ( dl1_addr ),
    .i_wen      ( dl1_we_w11 ),
    .i_wdata    ( dl1_wr_data ),
    .o_rdata    ( RdDtW11 ));
//
wire [31:0] RdDtMux = ~tag_way ? (index[6] ? RdDtW01 : RdDtW00) :
                                 (index[6] ? RdDtW11 : RdDtW10);
//
// Word Offset
//
 wire w_off_clr = (State==IdleSt) & i_art_valid;
 always @(posedge clk_mc) begin
    if(w_off_clr)
       w_off <= #`dh 3'b0;
    else if((State==ReadMiss) & i_l2c_rdata_valid)
       w_off <= #`dh w_off + 1'b1;
 end    
//
// FSM
//
 assign l1_en = i_ctl_en & i_art_flags[1] &~i_art_flags[0];
 wire ReadMissEnd = i_l2c_tlb_fault | 
                    (l1_en ? ~i_l2c_stall : i_l2c_rdata_valid);
//
 always @(posedge clk_mc) begin
    if(rst_mc) State <= #`dh IdleSt;
    else begin
       case(State)
//
       IdleSt       : begin
                         if(i_art_valid) begin
                            if(l1_en)
                              State <= #`dh TagMatch;
                            else begin
                               if(i_art_wen)
                                       State <= #`dh WriteMiss;
                                  else State <= #`dh ReadMiss;
                            end
                         end
                         else State <= #`dh IdleSt;
                      end
//
       TagMatch     : begin
                         if(L1Miss) begin
                             if(i_art_wen)
                                  State <= #`dh WriteMiss;
                             else State <= #`dh ReadMiss;
                         end
                         else if(L1Hit) begin
                            if(i_art_wen)
                                 State <= #`dh WriteHit;
                            else State <= #`dh ReadHit;
                         end
                         else
                           State <= #`dh TagMatch;
                      end
//
       WriteHit     : State <= #`dh WriteHitWait;
//
       WriteHitWait : begin
                           if(~i_l2c_stall)
                                State <= #`dh IdleSt;
                           else State <= #`dh WriteHitWait;
                        end
//
       ReadHit      : State <= #`dh IdleSt;
//
       WriteMiss    : begin
                         if(i_l2c_tlb_fault |~i_l2c_stall)
                              State <= #`dh IdleSt;
                         else State <= #`dh WriteMiss;
                      end
//
       ReadMiss     : begin
                         if(ReadMissEnd) begin
                            if(l1_en & ~i_l2c_tlb_fault)
                              State <= #`dh Retry;
                            else
                              State <= #`dh IdleSt;
                         end
                         else State <= #`dh ReadMiss;
                      end
//
       Retry        : State <= #`dh TagMatch;
//
       default      : State <= #`dh IdleSt;
//
       endcase
    end
 end
//
// Address Region Table block (ART) if
//
assign o_art_rdata     = (State==ReadMiss) ? i_l2c_rdata : RdDtMux;
//
assign o_art_tlb_fault = i_l2c_tlb_fault;
assign o_art_stall     =~(((State==TagMatch) & L1Hit) |
                          ((State==WriteMiss) & (i_l2c_tlb_fault |~i_l2c_stall)) |
                          ((State==ReadMiss) & ReadMissEnd
                                             & (i_l2c_tlb_fault | ~l1_en)));
//
// Level 2 Cache block (L2C) if
//
 wire assert_valid = ((State==IdleSt) & i_art_valid &~l1_en) | 
                     ((State==TagMatch) & L1Miss) |
                     ((State==TagMatch) & L1Hit & i_art_wen);
//
 always @(posedge clk_mc) begin
    if(rst_mc) o_l2c_valid <= #`dh 0;
    else begin
       if (assert_valid) begin
           o_l2c_valid <= #`dh 1;
       end
       else if(~i_l2c_stall) 
           o_l2c_valid <= #`dh 0;
    end
 end 
//
 always @(posedge clk_mc) begin
    if (assert_valid) begin
        o_l2c_wdata <= #`dh i_art_wdata;
        o_l2c_adr   <= #`dh {i_art_adr[31:2], 2'b0};
        o_l2c_flags <= #`dh i_art_flags;
        o_l2c_ben   <= #`dh i_art_ben;
        o_l2c_wen   <= #`dh i_art_wen;
    end
 end 
//
endmodule
