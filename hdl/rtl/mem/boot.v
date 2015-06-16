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
// Abstract      : Boot controller. Dumps the boot ROM memory onto the
//                 DRAM upon a boot request.
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: boot.v,v $
// CVS revision  : $Revision: 1.6 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// boot
//
module boot(
   input             clk_mc,
   input             rst_mc,
   // Boot Mem Interface
   input      [31:0] i_boot_data,
   output     [10:0] o_boot_adr,
   // L2C Writeback Interface (clk_mc)
   input             i_l2c_wb_space,
   output reg        o_l2c_wb_valid,
   output reg [31:0] o_l2c_wb_adr,
   // L2C Writeback Acknowledge Interface (clk_mc)
   input             i_l2c_wb_ack_valid,
   input             i_l2c_wb_ack_fault,
   input      [31:0] i_l2c_wb_ack_adr,
   output reg        o_l2c_wb_ack_stall,
   // Reset manager
   input             i_boot_req,
   output            o_boot_done);
//

//
 reg [6:0] ack_packet_cnt;
 reg [6:0] boot_packet_cnt;
 reg [3:0] boot_word_cnt;
//
 parameter WriteIdle  = 4'b0001,
           CheckSpace = 4'b0010,
           WriteCl    = 4'b0100,
           WriteDone  = 4'b1000;
//
 reg [3:0] WriteState;
// synthesis translate_off
 reg [256:0] WriteStateString;
 always @(WriteState) begin
    case (WriteState)
       WriteIdle  : WriteStateString = "WriteIdle";
       CheckSpace : WriteStateString = "CheckSpace";
       WriteCl    : WriteStateString = "WriteCl";
       WriteDone  : WriteStateString = "WriteDone";
       default    : WriteStateString = "ERROR";
    endcase
 end
// synthesis translate_on
 parameter AckIdle  = 3'b001,
           AckCount = 3'b010,
           AckDone  = 3'b100;
//
 reg [2:0] AckState;
// synthesis translate_off
 reg [256:0] AckStateString;
 always @(AckState) begin
    case (AckState)
       AckIdle  : AckStateString = "AckIdle";
       AckCount : AckStateString = "AckCount";
       AckDone  : AckStateString = "AckDone";
       default  : AckStateString = "ERROR";
    endcase
 end
// synthesis translate_on
//
// Counters
//
 wire boot_word_cnt_end   = (boot_word_cnt==4'd15);
 wire boot_packet_cnt_end = (boot_packet_cnt==8'd127);
 wire ack_packet_cnt_end  = (ack_packet_cnt==8'd127);
//
 always @(posedge clk_mc) begin
    if(rst_mc) begin
       ack_packet_cnt  <= #`dh 0;
       boot_packet_cnt <= #`dh 0;
       boot_word_cnt   <= #`dh 0;
    end
    else begin
       if(WriteState==WriteCl)
          boot_word_cnt <= #`dh boot_word_cnt + 1'b1;
       if((WriteState==WriteCl) & boot_word_cnt_end)
          boot_packet_cnt <= #`dh boot_packet_cnt + 1'b1;
       if(i_l2c_wb_ack_valid & ~o_l2c_wb_ack_stall)
          ack_packet_cnt  <= #`dh ack_packet_cnt + 1'b1;
    end
 end
//
// Write FSM
//
 always @(posedge clk_mc) begin
    if(rst_mc) WriteState <= #`dh WriteIdle;
    else begin
       case(WriteState)
//
       WriteIdle  : begin
                       if(i_boot_req)
                            WriteState <= #`dh CheckSpace;
                       else WriteState <= #`dh WriteDone;
                    end
//
       CheckSpace : begin
                       if(i_l2c_wb_space)
                            WriteState <= #`dh WriteCl;
                       else WriteState <= #`dh CheckSpace;
                    end
//
       WriteCl    : begin
                       if(boot_word_cnt_end) begin
                          if(boot_packet_cnt_end)
                               WriteState <= #`dh WriteDone;
                          else WriteState <= #`dh CheckSpace;
                       end
                       else WriteState <= #`dh WriteCl;
                    end
//
       WriteDone  : WriteState <= #`dh WriteDone;
//
       default    : WriteState <= #`dh WriteIdle;
//
       endcase
    end
 end
//
// Ack FSM
//
 always @(posedge clk_mc) begin
    if(rst_mc) AckState <= #`dh AckIdle;
    else begin
       case(AckState)
//
       AckIdle  : begin
                     if(i_boot_req)
                          AckState <= #`dh AckCount;
                     else AckState <= #`dh AckDone;
                  end
//
       AckCount : begin
                     if(ack_packet_cnt_end)
                          AckState <= #`dh AckDone;
                     else AckState <= #`dh AckCount;
                  end
//
       AckDone  : AckState <= #`dh AckDone;
//
       default  : AckState <= #`dh AckIdle;
//
       endcase
    end
 end
//
  assign o_boot_adr = {boot_packet_cnt, boot_word_cnt};
//
 always @(posedge clk_mc) begin
     o_l2c_wb_valid     <= #`dh (WriteState==WriteCl);
     o_l2c_wb_adr       <= #`dh {19'b0,boot_packet_cnt,6'b0};
	 o_l2c_wb_ack_stall <= #`dh ~i_l2c_wb_ack_valid;
 end
//
 assign o_boot_done = (WriteState==WriteDone) & (AckState==AckDone);
//
endmodule
