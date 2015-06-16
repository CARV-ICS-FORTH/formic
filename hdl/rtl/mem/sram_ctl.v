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
// Abstract      : ZBT SRAM controller top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: sram_ctl.v,v $
// CVS revision  : $Revision: 1.8 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// sram_ctl
//
module sram_ctl(
//
 input             clk_sram,
 input             rst_master_assert,
 input             rst_sram_deassert,
//
 inout      [35:0] io_sram_dq,
 output     [17:0] o_sram_adr,
 output     [ 3:0] o_sram_bw_n,
 output            o_sram_we_n,
 output            o_sram_en_n,
//
 input      [17:0] i_mbs0_req_adr,
 input             i_mbs0_req_we,
 input      [31:0] i_mbs0_req_wdata,
 input      [ 3:0] i_mbs0_req_be,
 input             i_mbs0_req_valid,
 output reg [31:0] o_mbs0_resp_rdata,
 output reg        o_mbs0_resp_valid,
//
 input      [17:0] i_mbs1_req_adr,
 input             i_mbs1_req_we,
 input      [31:0] i_mbs1_req_wdata,
 input      [ 3:0] i_mbs1_req_be,
 input             i_mbs1_req_valid,
 output reg [31:0] o_mbs1_resp_rdata,
 output reg        o_mbs1_resp_valid,
//
 input      [17:0] i_mbs2_req_adr,
 input             i_mbs2_req_we,
 input      [31:0] i_mbs2_req_wdata,
 input      [ 3:0] i_mbs2_req_be,
 input             i_mbs2_req_valid,
 output reg [31:0] o_mbs2_resp_rdata,
 output reg        o_mbs2_resp_valid,
//
 input      [17:0] i_mbs3_req_adr,
 input             i_mbs3_req_we,
 input      [31:0] i_mbs3_req_wdata,
 input      [ 3:0] i_mbs3_req_be,
 input             i_mbs3_req_valid,
 output reg [31:0] o_mbs3_resp_rdata,
 output reg        o_mbs3_resp_valid
);
//
  rst_sync_simple # (
    .CLOCK_CYCLES       ( 4 )
  ) i0_rst_sync_simple (
    .clk                ( clk_sram ),
    .rst_async          ( rst_master_assert ),
    .deassert           ( rst_sram_deassert ),
    .rst                ( rst_sram )
  );
//
wire [31:0] RdDt;
wire [ 3:0] RdDtValid;
wire [ 3:0] Sel;
//
reg  [31:0] RdDt_q;
reg         RdDtVld_q;
//
 reg [17:0] mbs0_req_adr_q;
 reg        mbs0_req_we_q;
 reg [31:0] mbs0_req_wdata_q;
 reg [ 3:0] mbs0_req_be_q;
 reg        mbs0_req_valid_q;

 reg [17:0] mbs1_req_adr_q;
 reg        mbs1_req_we_q;
 reg [31:0] mbs1_req_wdata_q;
 reg [ 3:0] mbs1_req_be_q;
 reg        mbs1_req_valid_q;

 reg [17:0] mbs2_req_adr_q;
 reg        mbs2_req_we_q;
 reg [31:0] mbs2_req_wdata_q;
 reg [ 3:0] mbs2_req_be_q;
 reg        mbs2_req_valid_q;

 reg [17:0] mbs3_req_adr_q;
 reg        mbs3_req_we_q;
 reg [31:0] mbs3_req_wdata_q;
 reg [ 3:0] mbs3_req_be_q;
 reg        mbs3_req_valid_q;

 always @(posedge clk_sram) begin
   mbs0_req_adr_q    <= #`dh i_mbs0_req_adr;
   mbs0_req_we_q     <= #`dh i_mbs0_req_we;
   mbs0_req_wdata_q  <= #`dh i_mbs0_req_wdata;
   mbs0_req_be_q     <= #`dh i_mbs0_req_be;
   mbs0_req_valid_q  <= #`dh i_mbs0_req_valid;

   mbs1_req_adr_q    <= #`dh i_mbs1_req_adr;
   mbs1_req_we_q     <= #`dh i_mbs1_req_we;
   mbs1_req_wdata_q  <= #`dh i_mbs1_req_wdata;
   mbs1_req_be_q     <= #`dh i_mbs1_req_be;
   mbs1_req_valid_q  <= #`dh i_mbs1_req_valid;

   mbs2_req_adr_q    <= #`dh i_mbs2_req_adr;
   mbs2_req_we_q     <= #`dh i_mbs2_req_we;
   mbs2_req_wdata_q  <= #`dh i_mbs2_req_wdata;
   mbs2_req_be_q     <= #`dh i_mbs2_req_be;
   mbs2_req_valid_q  <= #`dh i_mbs2_req_valid;

   mbs3_req_adr_q    <= #`dh i_mbs3_req_adr;
   mbs3_req_we_q     <= #`dh i_mbs3_req_we;
   mbs3_req_wdata_q  <= #`dh i_mbs3_req_wdata;
   mbs3_req_be_q     <= #`dh i_mbs3_req_be;
   mbs3_req_valid_q  <= #`dh i_mbs3_req_valid;
 end


//
 reg [31:0] mbs0_resp_rdata_q;
 wire       mbs0_resp_valid_q;
 reg [31:0] mbs1_resp_rdata_q;
 wire       mbs1_resp_valid_q;
 reg [31:0] mbs2_resp_rdata_q;
 wire       mbs2_resp_valid_q;
 reg [31:0] mbs3_resp_rdata_q;
 wire       mbs3_resp_valid_q;
//
 always @(posedge clk_sram) begin
    if(RdDtValid[0]) mbs0_resp_rdata_q <= #`dh RdDt_q;
    if(RdDtValid[1]) mbs1_resp_rdata_q <= #`dh RdDt_q;
    if(RdDtValid[2]) mbs2_resp_rdata_q <= #`dh RdDt_q;
    if(RdDtValid[3]) mbs3_resp_rdata_q <= #`dh RdDt_q;
 end
//
 hold ihold0(.Clk(clk_sram), .Reset(rst_sram),
             .In(RdDtValid[0]), .Out(mbs0_resp_valid_q));
 hold ihold1(.Clk(clk_sram), .Reset(rst_sram),
             .In(RdDtValid[1]), .Out(mbs1_resp_valid_q));
 hold ihold2(.Clk(clk_sram), .Reset(rst_sram),
             .In(RdDtValid[2]), .Out(mbs2_resp_valid_q));
 hold ihold3(.Clk(clk_sram), .Reset(rst_sram),
             .In(RdDtValid[3]), .Out(mbs3_resp_valid_q));
//
  always @(posedge clk_sram) begin
    o_mbs0_resp_rdata <= #`dh mbs0_resp_rdata_q;
    o_mbs1_resp_rdata <= #`dh mbs1_resp_rdata_q;
    o_mbs2_resp_rdata <= #`dh mbs2_resp_rdata_q;
    o_mbs3_resp_rdata <= #`dh mbs3_resp_rdata_q;

    o_mbs0_resp_valid <= #`dh mbs0_resp_valid_q;
    o_mbs1_resp_valid <= #`dh mbs1_resp_valid_q;
    o_mbs2_resp_valid <= #`dh mbs2_resp_valid_q;
    o_mbs3_resp_valid <= #`dh mbs3_resp_valid_q;
  end
//
reg [4:0] Sreg;
always @ (posedge clk_sram) begin
   if(rst_sram) Sreg <= #`dh 4'b1000;
   else         Sreg <= #`dh {Sreg[2:0],Sreg[3]};
end
//
assign Sel = {(Sreg[3] & mbs3_req_valid_q),
              (Sreg[2] & mbs2_req_valid_q),
              (Sreg[1] & mbs1_req_valid_q),
              (Sreg[0] & mbs0_req_valid_q)};
//
wire Wen0 = Sel[0] & mbs0_req_we_q;
wire Ren0 = Sel[0] &~mbs0_req_we_q;
wire Wen1 = Sel[1] & mbs1_req_we_q;
wire Ren1 = Sel[1] &~mbs1_req_we_q;
wire Wen2 = Sel[2] & mbs2_req_we_q;
wire Ren2 = Sel[2] &~mbs2_req_we_q;
wire Wen3 = Sel[3] & mbs3_req_we_q;
wire Ren3 = Sel[3] &~mbs3_req_we_q;
//
wire Wen = Wen0 | Wen1 | Wen2 | Wen3;
//
wire [17:0] Addr = {2'b00, mbs0_req_adr_q[17:2]} & {18{Sel[0]}} |
                   {2'b01, mbs1_req_adr_q[17:2]} & {18{Sel[1]}} |
                   {2'b10, mbs2_req_adr_q[17:2]} & {18{Sel[2]}} |
                   {2'b11, mbs3_req_adr_q[17:2]} & {18{Sel[3]}};
//
wire [31:0] WrDt = mbs0_req_wdata_q & {32{Sel[0]}} |
                   mbs1_req_wdata_q & {32{Sel[1]}} |
                   mbs2_req_wdata_q & {32{Sel[2]}} |
                   mbs3_req_wdata_q & {32{Sel[3]}};
//
wire [ 3:0] Ben  = mbs0_req_be_q & {4{Sel[0]}} | 
                   mbs1_req_be_q & {4{Sel[1]}} | 
                   mbs2_req_be_q & {4{Sel[2]}} | 
                   mbs3_req_be_q & {4{Sel[3]}};
//
wire [ 3:0] RdEn = {Ren3, Ren2, Ren1, Ren0};
//
reg [3:0] RdDtValidl0, RdDtValidl1, RdDtValidl2, RdDtValidl3, RdDtValidl4,
          RdDtValidl5;
//
always @ (posedge clk_sram)begin
   if(rst_sram) begin
      RdDtValidl0 <= #`dh 1'b0;
      RdDtValidl1 <= #`dh 1'b0;
      RdDtValidl2 <= #`dh 1'b0;
      RdDtValidl3 <= #`dh 1'b0;
      RdDtValidl4 <= #`dh 1'b0;
      RdDtValidl5 <= #`dh 1'b0;
   end
   else begin
      RdDtValidl0 <= #`dh RdEn;
      RdDtValidl1 <= #`dh RdDtValidl0;
      RdDtValidl2 <= #`dh RdDtValidl1;
      RdDtValidl3 <= #`dh RdDtValidl2;
      RdDtValidl4 <= #`dh RdDtValidl3;
      RdDtValidl5 <= #`dh RdDtValidl4;
   end
end
//
// zbt_ctl
//
zbt_ctl izbt_ctl(.Clk(clk_sram),
                 .Reset(rst_sram),
                 .i_addr(Addr),
                 .i_wb(Ben),
                 .i_wdata(WrDt),
                 .i_wen(Wen),
                 .i_ren(|RdEn),
                 .o_rdata(RdDt),
                 .o_rdata_valid(RdDtVld),
// -- sram Signals
                 .io_sram_data(io_sram_dq),
                 .o_sram_addr(o_sram_adr),
                 .o_sram_bw_n(o_sram_bw_n),
                 .o_sram_we_n(o_sram_we_n),
                 .o_sram_en_n(o_sram_en_n)
                 );
//
always @(posedge clk_sram) begin
  RdDt_q    <= #`dh RdDt;
  RdDtVld_q <= #`dh RdDtVld;
end
//
assign RdDtValid = RdDtValidl5 & {4{RdDtVld_q}};
//
endmodule 
//
// hold
//
module hold(
  input  Clk,
  input  Reset,
  input  In,
  output Out);
//
reg [1:0] Cnt;
reg       CntEn;

always @ (posedge Clk or posedge Reset) begin
   if(Reset) CntEn <= #`dh 0;
   else begin
      if(In) CntEn <= #`dh 1;
      else if(Cnt==3)  CntEn <= #`dh 0;
   end
end
//
always @ (posedge Clk or posedge Reset) begin
   if(Reset) Cnt <= #`dh 0;
   else if(CntEn) Cnt <= #`dh Cnt + 1'b1;
end
//   
assign Out = CntEn;
//
endmodule
