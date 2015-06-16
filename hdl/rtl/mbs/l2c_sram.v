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
// Abstract      : L2C SRAM data access
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_sram.v,v $
// CVS revision  : $Revision: 1.24 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_sram
//
module l2c_sram(
   input             Clk,
   input             Reset,
//
   input      [ 5:0] i_tag_arb,
   input             i_tag_valid,
   output            o_tag_stall,
//
   input      [17:0] i_fill_adr,
   output            o_fill_start,
   output            o_fill_end,
//
   input      [17:0] i_dl1_adr,
   input      [ 3:0] i_dl1_be,
   input             i_dl1_read_hit,
   input             i_dl1_write_hit,
   output            o_dl1_start,
   output            o_dl1_end,
//
   input      [17:0] i_il1_adr,
   output            o_il1_start,
   output            o_il1_end,
//
   input      [17:0] i_writeback_adr,
   output            o_writeback_start,
   output            o_writeback_end,
//
   input      [17:0] i_write_adr,
   output            o_write_start,
   output            o_write_end,
//
   input      [17:0] i_read_adr,
   output            o_read_start,
   output            o_read_end,
// SRAM Interface
   output reg [17:0] o_sctl_req_adr,
   output reg        o_sctl_req_we,
   output reg [ 3:0] o_sctl_req_be,
   output reg        o_sctl_req_valid,
   input             i_sctl_resp_valid,
   output reg        o_dl1_wr_dt_sel);
//
wire [5:0] in_sel;
reg  [5:0] in_sel_old;
reg  [5:0] in_sel_read_old;
//
wire ReadHit  = (i_dl1_read_hit & in_sel_old[1]) | in_sel_old[2];
wire WriteHit = i_dl1_write_hit & in_sel[1];
wire AccessEnd;
//
// Tag FSM Parameters
//
parameter Idle       = 4'b0001,
          Start      = 4'b0010,
          Access     = 4'b0100,
          LastAccess = 4'b1000;
//
reg  [3:0] SramState;
// synthesis translate_off
reg [256:0] SramStateString;
always @(SramState) begin
  case (SramState) 
    Idle       : SramStateString = "Idle";
    Start      : SramStateString = "Start";
    Access     : SramStateString = "Access";
    LastAccess : SramStateString = "LastAccess";
    default    : SramStateString = "ERROR";
  endcase
end
// synthesis translate_on

//
// Arbitration order from Tags
//
align_clk_sync_2 # (
  .N       ( 6 )
) i0_align_clk_sync_2 (
  .clk_in  ( Clk ),
  .rst_in  ( Reset ),
  .i_data  ( i_tag_arb ),
  .i_valid ( i_tag_valid ),
  .o_stall ( o_tag_stall ),
  .clk_out ( Clk ),
  .rst_out ( Reset ),
  .o_data  ( in_sel ),
  .o_valid ( GotoStart ),
  .i_stall ( ~(((SramState==Start) & WriteHit) |
               ((SramState==Access) & AccessEnd)) ) 
);
//
//
 always @(posedge Clk) begin
    if(Reset) begin
       in_sel_old   <= #`dh 0;
    end
    else if(SramState==Start) begin
       in_sel_old   <= #`dh in_sel;
    end
 end
//
 wire [31:0] sram_addr = i_fill_adr      & {18{(SramState==Start) ? in_sel[0] : in_sel_old[0]}} |
                         i_dl1_adr       & {18{(SramState==Start) ? in_sel[1] : in_sel_old[1]}} |
                         i_il1_adr       & {18{(SramState==Start) ? in_sel[2] : in_sel_old[2]}} |
                         i_writeback_adr & {18{(SramState==Start) ? in_sel[3] : in_sel_old[3]}} |
                         i_write_adr     & {18{(SramState==Start) ? in_sel[4] : in_sel_old[4]}} |
                         i_read_adr      & {18{(SramState==Start) ? in_sel[5] : in_sel_old[5]}};
//
// SRAM FSM
//
 always @(posedge Clk) begin
    if(Reset) SramState <= #`dh Idle;
    else begin
       case(SramState)
//
       Idle       : begin
                       if(GotoStart)
                            SramState <= #`dh Start;
                       else SramState <= #`dh Idle;
                    end
//
       Start      : begin
                       if(WriteHit)
                            SramState <= #`dh Idle;
                       else SramState <= #`dh Access;
                    end
//
       Access     : begin
                       if(AccessEnd)
                            SramState <= #`dh LastAccess;
                       else SramState <= #`dh Access;
                    end
//
       LastAccess : begin
                       if(GotoStart)
                            SramState <= #`dh Start;
                       else SramState <= #`dh Idle;
                    end
//
       default    : SramState <= #`dh Idle;
//
       endcase
    end
 end
//
// ReadCnt
//
 reg  [3:0] ReadCnt;
 reg  [3:0] ReadMax;
//
 wire ReadCntStart = (ReadCnt==4'd0)    & i_sctl_resp_valid;
 wire ReadCntEnd   = (ReadCnt==ReadMax) & i_sctl_resp_valid;
//
 always @(posedge Clk) begin
     if(Reset) begin
        ReadCnt <= #`dh 0;
        ReadMax <= #`dh 4'd15;
     end
     else begin
        if(ReadCntEnd) begin
             ReadCnt <= #`dh 0;
        end
        else if (i_sctl_resp_valid) begin 
             ReadCnt <= #`dh ReadCnt + 4'd1;
        end
        
        if(ReadCntStart) begin
             ReadMax <= #`dh ((in_sel[1] &~i_dl1_write_hit) | in_sel[2]) ? 4'd7 : 4'd15;
             in_sel_read_old <= #`dh in_sel;
        end
     end
 end
//
//
// Write  ..... AccessEnd
// Read   ..... ReadCntEnd
//
// Fill: write 16
//
 assign o_fill_start  = (SramState==Start)      & in_sel[0];
 assign o_fill_end    = (SramState==LastAccess) & in_sel_old[0];
//
// DL1: write 1 (writehit) / read 8 (readhit)
//
 assign o_dl1_start = ((SramState==Start)  & in_sel[1] & i_dl1_write_hit) |
                      (ReadCntStart & in_sel[1]);
 assign o_dl1_end   = (ReadCntEnd   & in_sel_read_old[1]) |
                      ((SramState==Start)  & in_sel[1] & i_dl1_write_hit);
//
// IL1: read 8
//
 assign o_il1_start = ReadCntStart & in_sel[2];
 assign o_il1_end   = ReadCntEnd   & in_sel_read_old[2];
//
// Writeback: read 16
//
 assign o_writeback_start = ReadCntStart & in_sel[3];
 assign o_writeback_end   = ReadCntEnd   & in_sel_read_old[3];
//
// Write: write 16
//
 assign o_write_start = (SramState==Start)      & in_sel[4];
 assign o_write_end   = (SramState==LastAccess) & in_sel_old[4];
//
// Read: read 16
//
 assign o_read_start = ReadCntStart & in_sel[5];
 assign o_read_end   = ReadCntEnd   & in_sel_read_old[5];
//
// adr_offset
//
 reg  [3:0] adr_offset;
 wire       adr_offset_inc = (SramState==Start) | (SramState==Access);
 always @(posedge Clk) begin
      if(Reset)
         adr_offset <= #`dh 4'b0;
      else if((SramState==Idle) | (SramState==LastAccess)) begin
         if (GotoStart & in_sel[1] & i_dl1_read_hit)
            adr_offset <= #`dh {i_dl1_adr[5],3'b0};
         else if (GotoStart & in_sel[1] & i_dl1_write_hit)
            adr_offset <= #`dh i_dl1_adr[5:2];
         else if (GotoStart & in_sel[2])
            adr_offset <= #`dh {i_il1_adr[5],3'b0};
         else
            adr_offset <= #`dh 4'b0;
      end
      else if(adr_offset_inc)
         adr_offset <= #`dh adr_offset + 4'h1;
 end
 assign AccessEnd = (ReadHit & (adr_offset==6)) | (adr_offset==14);
//
// SRAM IF
//
 always @(posedge Clk) begin
    if(Reset) begin
       o_sctl_req_be    <= #`dh 0;
       o_sctl_req_valid <= #`dh 0;
       o_sctl_req_we    <= #`dh 0;
       o_dl1_wr_dt_sel  <= #`dh 0;
    end
//
    else begin
       o_sctl_req_adr   <= #`dh {sram_addr[17:6],adr_offset,2'b0}; // ???
       o_dl1_wr_dt_sel  <= #`dh in_sel[1] & i_dl1_write_hit & 
                                ((SramState==Idle) | (SramState==LastAccess));

       if (SramState==Start) begin
         o_sctl_req_valid <= #`dh 1'b1;
         o_sctl_req_be    <= #`dh (in_sel[1] & i_dl1_write_hit) ? i_dl1_be : 4'b1111;
       end
       else if (SramState==Idle)
         o_sctl_req_valid <= #`dh 1'b0;

       if (SramState==Start) begin
          if (in_sel[0] | 
              (in_sel[1] & i_dl1_write_hit) |
              in_sel[4])
             o_sctl_req_we <= #`dh 1'b1;
          else
             o_sctl_req_we <= #`dh 1'b0;
       end
       else if (SramState==Idle)
         o_sctl_req_we <= #`dh 1'b0;

    end
//
 end
//
endmodule
