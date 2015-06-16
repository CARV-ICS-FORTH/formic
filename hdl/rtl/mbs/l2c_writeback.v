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
// Abstract      : L2C writeback interface
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_writeback.v,v $
// CVS revision  : $Revision: 1.15 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_writeback
//
module l2c_writeback(
   input             Clk,
   input             Reset,
//
   input             i_mni_wb_space,
//
   input      [17:0] i_dl1_sram_adr,
   input      [16:0] i_dl1_old_tag,
   input             i_dl1_req,
//
   input      [17:0] i_il1_sram_adr,
   input      [16:0] i_il1_old_tag,
   input             i_il1_req,
//
   input      [17:0] i_write_sram_adr,
   input      [16:0] i_write_old_tag,
   input             i_write_req,
//
   input      [16:0] i_maint_old_tag,
   input      [17:0] i_maint_sram_adr,
   input             i_maint_req,
//
   input             i_start,
   input             i_end,
//
   output            o_tag_sram_req,
   output            o_tag_sram_combo,
   input             i_tag_ack,
//
   output reg [31:0] o_writeback_adr,
   output reg [17:0] o_sram_adr,
   output reg        o_mni_wb_valid,
   output reg        o_il1_ack,
   output reg        o_dl1_ack,
   output reg        o_write_ack,
   output reg        o_maint_ack
);
// Tag FSM Parameters
parameter Idle       = 5'b0_0001,
          CheckSpace = 5'b0_0010,
          Tag        = 5'b0_0100,
          SRAM       = 5'b0_1000,
          Access     = 5'b1_0000;
//
reg  [4:0] WbState;
//
// synthesis translate_off
reg [256:0] WbStateString;
always @(WbState) begin
  case (WbState)
    Idle       : WbStateString = "Idle";
    CheckSpace : WbStateString = "CheckSpace";
    Tag        : WbStateString = "Tag";
    SRAM       : WbStateString = "SRAM";
    Access     : WbStateString = "Access";
    default    : WbStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
// Priority Enforcer
// Priority is right <- left (MS)
//
wire [3:0] in_sel;
//
LdEnPriorEnf ipr_enf(
                 .Clk         ( Clk ),
                 .Reset       ( Reset ),
                 .LdEn        ( (WbState==Idle) ),
                 .In          ( {i_maint_req,
                                 i_write_req,
                                 i_il1_req,
                                 i_dl1_req} ),
                 .Out         ( in_sel ),
                 .Mask        (),
                 .OneDetected ( WritebackFsmStart ));
defparam ipr_enf.N_log = 2;
//
wire [17:0] add_mux = i_dl1_sram_adr        & {18{in_sel[0]}} |
                      i_il1_sram_adr        & {18{in_sel[1]}} |
                      i_write_sram_adr      & {18{in_sel[2]}} |
                      i_maint_sram_adr      & {18{in_sel[3]}};
//
wire [16:0] tag_mux = i_dl1_old_tag         & {17{in_sel[0]}} |
                      i_il1_old_tag         & {17{in_sel[1]}} |
                      i_write_old_tag       & {17{in_sel[2]}} |
                      i_maint_old_tag       & {17{in_sel[3]}};
//
// o_writeback_adr
//
 always @(posedge Clk) 
    if((WbState==Idle) & WritebackFsmStart) begin
        o_sram_adr      <= #`dh add_mux;
        o_writeback_adr <= #`dh {tag_mux, add_mux[17:9], 6'b0};
    end
//
// FSM
//
 always @(posedge Clk) begin
    if(Reset) WbState <= #`dh Idle;
    else begin
       case(WbState)
//
       Idle       : begin
                       if(WritebackFsmStart) begin
                          if(i_mni_wb_space) 
                                 WbState <= #`dh Tag;
                            else WbState <= #`dh CheckSpace;
                       end
                       else WbState <= #`dh Idle;
                    end
//
       CheckSpace : begin
                       if(i_mni_wb_space)
                            WbState <= #`dh Tag;
                       else WbState <= #`dh CheckSpace;
                    end
//
       Tag        : begin
                       if(i_tag_ack)
                            WbState <= #`dh SRAM;
                       else WbState <= #`dh Tag;
                    end
//
       SRAM       : begin
                       if(i_start)
                            WbState <= #`dh Access;
                       else WbState <= #`dh SRAM;
                    end
//
       Access     : begin
                         if(i_end)
                              WbState <= #`dh Idle;
                         else WbState <= #`dh Access;
                      end
//
       default    : WbState <= #`dh Idle;
//
       endcase
    end
 end
//
 always @(posedge Clk) begin
    if(Reset) o_mni_wb_valid <= #`dh 1'b0;
    else begin
       if (i_start)
          o_mni_wb_valid <= #`dh 1'b1;
       else if (WbState==Idle)
          o_mni_wb_valid <= #`dh 1'b0;
    end
 end
//
 assign o_tag_sram_req    = (WbState==Tag);
 assign o_tag_sram_combo  = (WbState==Tag) & in_sel[2];
 always @(posedge Clk) begin
    o_dl1_ack    <= #`dh (WbState==Tag) & i_tag_ack & in_sel[0];
    o_il1_ack    <= #`dh (WbState==Tag) & i_tag_ack & in_sel[1];
    o_write_ack  <= #`dh (WbState==Tag) & i_tag_ack & in_sel[2];
    o_maint_ack  <= #`dh (WbState==Tag) & i_tag_ack & in_sel[3];  
 end
//
endmodule
