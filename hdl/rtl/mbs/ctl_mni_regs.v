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
// Author        : Spyros Lyberis
// Abstract      : CTL network-related registers
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: ctl_mni_regs.v,v $
// CVS revision  : $Revision: 1.10 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// mni_regs
//
module ctl_mni_regs(
//
 input             clk_ni,
//
 input             i_reg_sel0,
 input      [ 2:0] i_reg_sel_enc,
 input             i_mni_reg_write,
 input             i_block_sel,
 input             i_reg_sel_extra,
 input             i_mni_reg_adr1,
 input      [ 1:0] i_mni_reg_ben,
 input      [15:0] i_mni_reg_wdata,
//
 input      [ 5:0] i_mni_cpu_fifo_ops,
 input      [ 5:0] i_mni_net_fifo_ops,
//
 output            o_mni_op_start,
 input             i_read_low,
 output     [15:0] o_dt_out);

 
 (* ram_style = "distributed" *)
 reg [15:0] mem_q[0:15];

 always @(posedge clk_ni) begin
     if (i_block_sel & i_mni_reg_write & i_mni_reg_ben[0])
       mem_q[{i_reg_sel_enc,i_mni_reg_adr1}][7:0] <= #`dh i_mni_reg_wdata[7:0];

     if (i_block_sel & i_mni_reg_write & i_mni_reg_ben[1])
       mem_q[{i_reg_sel_enc,i_mni_reg_adr1}][15:8] <= #`dh i_mni_reg_wdata[15:8];
 end

 wire [15:0] mem_out = mem_q[{i_reg_sel_enc,~i_read_low}];

 wire [15:0] extra_out = {10'b0, ((i_read_low) ? i_mni_cpu_fifo_ops : 
                                                 i_mni_net_fifo_ops) };

 assign o_dt_out = (i_reg_sel_extra) ? extra_out : mem_out;

 assign o_mni_op_start = i_block_sel & i_reg_sel0 & i_mni_reg_write &~i_mni_reg_adr1 & i_mni_reg_ben[0];

endmodule
