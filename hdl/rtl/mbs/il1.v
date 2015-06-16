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
// Abstract      : Instruction L1 Cache (IL1) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: il1.v,v $
// CVS revision  : $Revision: 1.20 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// IL1
//
module il1(
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
 input             i_art_valid,
 output     [31:0] o_art_rdata,
 output            o_art_tlb_fault,
 output            o_art_stall,
// Level 2 Cache block (L2C) Interface
 output reg [31:0] o_l2c_adr,
 output reg [ 1:0] o_l2c_flags,
 output reg        o_l2c_valid,
 input      [31:0] i_l2c_rdata,
 input             i_l2c_rdata_valid,
 input             i_l2c_tlb_fault,
 input             i_l2c_stall,
 input      [31:0] i_l2c_inv_adr,
 input             i_l2c_inv_req,
 output            o_l2c_inv_ack);
//
parameter IdleSt     = 5'b0_0001,
          TagMatch   = 5'b0_0010,
          ReadMiss   = 5'b0_0100,
          ReadHit    = 5'b0_1000,
          Retry      = 5'b1_0000;
//
reg  [ 4:0] State;
// synthesis translate_off
reg [256:0] L1StateString;
always @(State) begin
  case (State)
    IdleSt      : L1StateString = "IdleSt";
    TagMatch    : L1StateString = "TagMatch";
    ReadMiss    : L1StateString = "ReadMiss";
    ReadHit     : L1StateString = "ReadHit";
    Retry       : L1StateString = "Retry";
    default     : L1StateString = "ERROR";
  endcase
end
// synthesis translate_on
wire        l1_en;
reg  [ 2:0] w_off;
wire [ 5:0] index = i_art_adr[10: 5];
wire [31:0] RdDtW00,
            RdDtW10;
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

  .NR_WAYS_IS_128   ( 0 )

) i0_l1_tags (
  .clk              ( clk_mc ),
  .rst              ( rst_mc ),

  // Access interface
  .i_acc_req        ( tag_req ),
  .i_acc_adr        ( i_art_adr ),
  .i_acc_wen        ( 1'b0 ),
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
wire        SelW00 = (tag_ack) ? ~tag_way : ~way_q;
wire        SelW10 = (tag_ack) ?  tag_way :  way_q;
//
wire [31:0] il1_wr_data = i_l2c_rdata;
wire [ 8:0] il1_addr    = (State==ReadMiss) ? {index, w_off} : {index, i_art_adr[4:2]};
wire [ 3:0] il1_we_w00  = ((State==ReadMiss) & i_l2c_rdata_valid & SelW00) ? 4'hF : 4'b0;
wire [ 3:0] il1_we_w10  = ((State==ReadMiss) & i_l2c_rdata_valid & SelW10) ? 4'hF : 4'b0;
//
  xil_mem_sp_512x32 i0_xil_mem_sp_512x32 (
    .clk        ( clk_mc ),
    .i_en       ( 1'b1 ),
    .i_adr      ( il1_addr ),
    .i_wen      ( il1_we_w00 ),
    .i_wdata    ( il1_wr_data ),
    .o_rdata    ( RdDtW00 ));
  xil_mem_sp_512x32 i1_xil_mem_sp_512x32 (
    .clk        ( clk_mc ),
    .i_en       ( 1'b1 ),
    .i_adr      ( il1_addr ),
    .i_wen      ( il1_we_w10 ),
    .i_wdata    ( il1_wr_data ),
    .o_rdata    ( RdDtW10 )
  );
//
wire [31:0] RdDtMux = ~tag_way ? RdDtW00 : RdDtW10;
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
       IdleSt     : begin
                       if(i_art_valid) begin
                          if(l1_en)
                               State <= #`dh TagMatch;
                          else State <= #`dh ReadMiss;
                       end
                       else State <= #`dh IdleSt;
                    end
//
       TagMatch   : begin
                       if(L1Miss)
                         State <= #`dh ReadMiss;
                       else if(L1Hit)
                         State <= #`dh ReadHit;
                       else
                         State <= #`dh TagMatch;
                    end
//
       ReadHit    : State <= #`dh IdleSt;
//
       ReadMiss   : begin
                       if(ReadMissEnd) begin
                          if(l1_en & ~i_l2c_tlb_fault)
                            State <= #`dh Retry;
                          else
                            State <= #`dh IdleSt;
                       end
                       else State <= #`dh ReadMiss;
                    end
//
       Retry      : State <= #`dh TagMatch;
//
       default    : State <= #`dh IdleSt;
//
       endcase
    end
 end
//
//
// Address Region Table block (ART) if
//
assign o_art_rdata     = (State==ReadMiss) ? i_l2c_rdata : RdDtMux;
//
assign o_art_tlb_fault = i_l2c_tlb_fault;
assign o_art_stall     =~(((State==TagMatch) & L1Hit) |
                          ((State==ReadMiss) & ReadMissEnd
                                             & (i_l2c_tlb_fault | ~l1_en)));
//
// Level 2 Cache block (L2C) if
//
 always @(posedge clk_mc) begin
    if(rst_mc) o_l2c_valid <= #`dh 0;
    else begin
       if(((State==IdleSt) & i_art_valid &~l1_en) |
          ((State==TagMatch) & L1Miss))
           o_l2c_valid <= #`dh 1;
       else if(~i_l2c_stall) 
           o_l2c_valid <= #`dh 0;
    end
 end 
 always @(posedge clk_mc) begin
    o_l2c_adr   <= #`dh {i_art_adr[31:2], 2'b0};
    o_l2c_flags <= #`dh i_art_flags;
 end 
//
endmodule
