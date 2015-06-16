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
// Abstract      : Back-end driver for the ZBT SRAM modules
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: zbt_ctl.v,v $
// CVS revision  : $Revision: 1.8 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
module zbt_ctl(
// -- System Signals
   input Clk,
   input Reset,
// -- USER Signals
   input      [17:0] i_addr,
   input      [ 3:0] i_wb,
   input      [31:0] i_wdata,
   input             i_wen,
   input             i_ren,
   output reg [31:0] o_rdata,
   output reg        o_rdata_valid,
// -- sram Signals
   inout      [35:0] io_sram_data,
   output reg [17:0] o_sram_addr,
   output reg [ 3:0] o_sram_bw_n,   
   output reg        o_sram_we_n,   
   output reg        o_sram_en_n
   );
//
reg [31:0] write_data_l0;
reg [31:0] write_data_l1;
reg [31:0] write_data_l2;
reg [31:0] write_data_l3;
reg        we_l0, we_l1;
(* equivalent_register_removal = "no" *) 
reg [35:0] we_l2;
(* equivalent_register_removal = "no" *) 
reg [35:0] we_l3;
reg        re_l0, re_l1, re_l2, re_l3;
//
// Write Data 2 stage pipeline
//
always @ (posedge Clk) begin
   write_data_l0 <= #`dh  i_wdata;
   write_data_l1 <= #`dh  write_data_l0;
   write_data_l2 <= #`dh  write_data_l1;
   write_data_l3 <= #`dh  write_data_l2;
end
//
always @ (posedge Clk) begin
   if(Reset) begin
      re_l0 <= #`dh 1'b0;
      re_l1 <= #`dh 1'b0;
      re_l2 <= #`dh 1'b0;
      re_l3 <= #`dh 1'b0;
   end
   else begin
      re_l0 <= #`dh i_ren;
      re_l1 <= #`dh re_l0;
      re_l2 <= #`dh re_l1;
      re_l3 <= #`dh re_l2;
   end
end      
//
always @ (posedge Clk) begin
  we_l0 <= #`dh i_wen;
  we_l1 <= #`dh ~we_l0;
  we_l2 <= #`dh {36{we_l1}};
  we_l3 <= #`dh we_l2;
end
//
reg [17:0] sram_addr_q;
reg [ 3:0] sram_bw_n_q;
reg        sram_we_n_q;
reg        sram_en_n_q;
//
always @(posedge Clk) begin
  sram_addr_q <= #`dh i_addr;
  sram_bw_n_q <= #`dh~i_wb;
  sram_we_n_q <= #`dh~i_wen;
  sram_en_n_q <= #`dh~(i_wen | i_ren);

  o_sram_addr <= #`dh sram_addr_q;
  o_sram_bw_n <= #`dh sram_bw_n_q;
  o_sram_we_n <= #`dh sram_we_n_q;
  o_sram_en_n <= #`dh sram_en_n_q;
end
//
wire [35:0] sram_data_out = {4'b0, write_data_l3};
wire [35:0] sram_data_in;

// synthesis attribute IOB of o_sram_addr is "TRUE"
// synthesis attribute IOB of o_sram_bw_n is "TRUE"
// synthesis attribute IOB of o_sram_we_n is "TRUE"
// synthesis attribute IOB of o_sram_en_n is "TRUE"

// To explicitly force IFF, OFF and TFF for sram*dq pins (otherwise
// hierarchical synthesis does not work):

// synthesis attribute IOB of o_rdata is "TRUE"
// synthesis attribute IOB of write_data_l3 is "TRUE"
// synthesis attribute IOB of we_l3 is "TRUE"

genvar i;
generate
  for (i = 0; i < 36; i = i + 1) begin:gen_iobuf
    IOBUF # (
      .DRIVE        ( 6 ),          // These must match the UCF file,
      .SLEW         ( "FAST" ),     // to avoid stupid warnings
      .IOSTANDARD   ( "LVCMOS25" )
    ) iobuf (
      .IO           ( io_sram_data[i] ),
      .T            ( we_l3[i] ),
      .I            ( sram_data_out[i] ),
      .O            ( sram_data_in[i] )
    );
  end
endgenerate
//
always @(posedge Clk) o_rdata       <= #`dh sram_data_in[31:0];
always @(posedge Clk) o_rdata_valid <= #`dh re_l3;
//
endmodule
