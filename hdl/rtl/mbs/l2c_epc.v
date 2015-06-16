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
// Abstract      : L2C epoch replacement policy
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_epc.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_epc
//
module l2c_epc(
   input        Clk,
   input        Reset,
//
   input        i_rnd_shift,
   input  [2:0] i_ctl_epoch,
   input  [2:0] i_ctl_min_cpu_ways,
//
   input  [7:0] i_tag_V,
   input  [7:0] i_tag_transient,
   input  [7:0] i_inv_mask_oh,
   input        i_inv_tag_detect,
   input  [2:0] i_tag0_epc,
   input  [2:0] i_tag1_epc,
   input  [2:0] i_tag2_epc,
   input  [2:0] i_tag3_epc,
   input  [2:0] i_tag4_epc,
   input  [2:0] i_tag5_epc,
   input  [2:0] i_tag6_epc,
   input  [2:0] i_tag7_epc,
   input        i_WriteCheckOp,
   input        i_WriteOp,
   input        i_L1Op,
//
   output [7:0] o_repl_way_mask,
   output       o_WriteCheckOpAllowed,
   output [2:0] o_cur_epoch,
   output [2:0] o_nxt_epoch);
//
// epoch registers
//
reg [2:0] cur_epoch;
reg [2:0] nxt_epoch;
 always @(posedge Clk) begin
    cur_epoch <= #`dh i_ctl_epoch;
    nxt_epoch <= #`dh i_ctl_epoch + 1'b1;
 end
//
wire [7:0] rnd_termo;
 //
 rnd irnd(
     .Clk         ( Clk ),
     .Reset       ( Reset ),
     .i_shift     ( i_rnd_shift ),
     .o_out       (),
     .o_out_termo ( rnd_termo ));
//
wire epc0_cpu_cmp = (i_tag0_epc==cur_epoch) & i_tag_V[0] & ~i_tag_transient[0];
wire epc0_ni_cmp  = (i_tag0_epc==nxt_epoch) & i_tag_V[0] & ~i_tag_transient[0];
//                                                        
wire epc1_cpu_cmp = (i_tag1_epc==cur_epoch) & i_tag_V[1] & ~i_tag_transient[1];
wire epc1_ni_cmp  = (i_tag1_epc==nxt_epoch) & i_tag_V[1] & ~i_tag_transient[1];
//                                                        
wire epc2_cpu_cmp = (i_tag2_epc==cur_epoch) & i_tag_V[2] & ~i_tag_transient[2];
wire epc2_ni_cmp  = (i_tag2_epc==nxt_epoch) & i_tag_V[2] & ~i_tag_transient[2];
//                                                        
wire epc3_cpu_cmp = (i_tag3_epc==cur_epoch) & i_tag_V[3] & ~i_tag_transient[3];
wire epc3_ni_cmp  = (i_tag3_epc==nxt_epoch) & i_tag_V[3] & ~i_tag_transient[3];
//                                                        
wire epc4_cpu_cmp = (i_tag4_epc==cur_epoch) & i_tag_V[4] & ~i_tag_transient[4];
wire epc4_ni_cmp  = (i_tag4_epc==nxt_epoch) & i_tag_V[4] & ~i_tag_transient[4];
//                                                        
wire epc5_cpu_cmp = (i_tag5_epc==cur_epoch) & i_tag_V[5] & ~i_tag_transient[5];
wire epc5_ni_cmp  = (i_tag5_epc==nxt_epoch) & i_tag_V[5] & ~i_tag_transient[5];
//                                                        
wire epc6_cpu_cmp = (i_tag6_epc==cur_epoch) & i_tag_V[6] & ~i_tag_transient[6];
wire epc6_ni_cmp  = (i_tag6_epc==nxt_epoch) & i_tag_V[6] & ~i_tag_transient[6];
//                                                        
wire epc7_cpu_cmp = (i_tag7_epc==cur_epoch) & i_tag_V[7] & ~i_tag_transient[7];
wire epc7_ni_cmp  = (i_tag7_epc==nxt_epoch) & i_tag_V[7] & ~i_tag_transient[7];
//
wire [7:0] cur_cpu_epc_mask = {epc7_cpu_cmp,
                               epc6_cpu_cmp,
                               epc5_cpu_cmp,
                               epc4_cpu_cmp,
                               epc3_cpu_cmp,
                               epc2_cpu_cmp,
                               epc1_cpu_cmp,
                               epc0_cpu_cmp};
//
wire [7:0] cur_ni_epc_mask  = {epc7_ni_cmp,
                               epc6_ni_cmp,
                               epc5_ni_cmp,
                               epc4_ni_cmp,
                               epc3_ni_cmp,
                               epc2_ni_cmp,
                               epc1_ni_cmp,
                               epc0_ni_cmp};
//
wire [7:0] old_epc_mask     = {(~(epc7_cpu_cmp | epc7_ni_cmp) & ~i_tag_transient[7]),
                               (~(epc6_cpu_cmp | epc6_ni_cmp) & ~i_tag_transient[6]),
                               (~(epc5_cpu_cmp | epc5_ni_cmp) & ~i_tag_transient[5]),
                               (~(epc4_cpu_cmp | epc4_ni_cmp) & ~i_tag_transient[4]),
                               (~(epc3_cpu_cmp | epc3_ni_cmp) & ~i_tag_transient[3]),
                               (~(epc2_cpu_cmp | epc2_ni_cmp) & ~i_tag_transient[2]),
                               (~(epc1_cpu_cmp | epc1_ni_cmp) & ~i_tag_transient[1]),
                               (~(epc0_cpu_cmp | epc0_ni_cmp) & ~i_tag_transient[0])};
//
wire [3:0] cpu_way_sum = epc0_cpu_cmp +
                         epc1_cpu_cmp +
                         epc2_cpu_cmp +
                         epc3_cpu_cmp +
                         epc4_cpu_cmp +
                         epc5_cpu_cmp +
                         epc6_cpu_cmp +
                         epc7_cpu_cmp;
//
wire [7:0] old_epc_mask_oh;
PriorEnf old_epc_mask_prenf(
           .In          ( old_epc_mask ),
           .Out         ( old_epc_mask_oh ),
           .Mask        (),
           .OneDetected ( old_epc_tag_detected));
//
wire [7:0] cur_cpu_epc_mask_oh;
Rnd_RR_prior_enf cur_cpu_epc_mask_prenf(
           .i_mask      ( rnd_termo ),
           .i_In        ( cur_cpu_epc_mask ),
           .o_Out       ( cur_cpu_epc_mask_oh ));
//
wire [7:0] cur_ni_epc_mask_oh;
Rnd_RR_prior_enf cur_ni_epc_mask_prenf(
           .i_mask      ( rnd_termo ),
           .i_In        ( cur_ni_epc_mask ),
           .o_Out       ( cur_ni_epc_mask_oh ));
//
wire replace_cpu_tag = ((i_L1Op | i_WriteOp) & (cpu_way_sum > i_ctl_min_cpu_ways));
//
assign o_WriteCheckOpAllowed = i_WriteCheckOp &
                               (i_inv_tag_detect |
                                old_epc_tag_detected |
                                replace_cpu_tag );
//
assign o_repl_way_mask = i_inv_tag_detect     ? i_inv_mask_oh :
                         old_epc_tag_detected ? old_epc_mask_oh :
                         replace_cpu_tag      ? cur_cpu_epc_mask_oh :
                                                cur_ni_epc_mask_oh;
//
 assign o_cur_epoch = cur_epoch;
 assign o_nxt_epoch = nxt_epoch;
//
endmodule
