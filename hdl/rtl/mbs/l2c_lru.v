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
// Abstract      : L2C LRU replacement policy
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_lru.v,v $
// CVS revision  : $Revision: 1.15 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// l2c_tag
//
module l2c_lru(
   input        Clk,
   input        Reset,
//
   input        i_lru_enable,
   input  [7:0] i_tag_V,
   input  [7:0] i_inv_tag_msk,
   input        i_inv_tag_detect,
   input  [7:0] i_hit_mask,
   input        i_replace_req,
   input  [2:0] i_tag0_lru,
   input  [2:0] i_tag1_lru,
   input  [2:0] i_tag2_lru,
   input  [2:0] i_tag3_lru,
   input  [2:0] i_tag4_lru,
   input  [2:0] i_tag5_lru,
   input  [2:0] i_tag6_lru,
   input  [2:0] i_tag7_lru,
   input        i_WriteCheckOp,
//
   output       o_WriteCheckOpAllowed,
   output [2:0] o_tag0_lru,
   output [2:0] o_tag1_lru,
   output [2:0] o_tag2_lru,
   output [2:0] o_tag3_lru,
   output [2:0] o_tag4_lru,
   output [2:0] o_tag5_lru,
   output [2:0] o_tag6_lru,
   output [2:0] o_tag7_lru,
   output [7:0] o_tag_V,
   output [7:0] o_replace_msk);
//
// Comparator Tree
//
 wire       cmpb01   = (i_tag0_lru > i_tag1_lru);
 wire       cmpb23   = (i_tag2_lru > i_tag3_lru);
 wire       cmpb45   = (i_tag4_lru > i_tag5_lru);
 wire       cmpb56   = (i_tag6_lru > i_tag7_lru);
 wire [2:0] selb01   = cmpb01 ? i_tag0_lru : i_tag1_lru;
 wire [2:0] selb23   = cmpb23 ? i_tag2_lru : i_tag3_lru;
 wire [2:0] selb45   = cmpb45 ? i_tag4_lru : i_tag5_lru;
 wire [2:0] selb67   = cmpb56 ? i_tag6_lru : i_tag7_lru;
//
 wire       cmp0123  = (selb01 > selb23);
 wire       cmp4567  = (selb45 > selb67);
 wire [2:0] selb0123 = cmp0123 ? selb01  : selb23;
 wire [2:0] selb4567 = cmp4567 ? selb45  : selb67;
//
 wire       cmpb     = (selb0123 > selb4567);
//
 wire big0 = cmpb01 & cmp0123 & cmpb;
 wire big1 =~cmpb01 & cmp0123 & cmpb;
//
 wire big2 = cmpb23 &~cmp0123 & cmpb;
 wire big3 =~cmpb23 &~cmp0123 & cmpb;
//
 wire big4 = cmpb45 & cmp4567 &~cmpb;
 wire big5 =~cmpb45 & cmp4567 &~cmpb;
//
 wire big6 = cmpb56 &~cmp4567 &~cmpb;
 wire big7 =~cmpb56 &~cmp4567 &~cmpb;
//
// Hit lru Select
//
 wire [2:0] hit_tag_mux = i_tag0_lru & {3{i_hit_mask[0]}} |
                          i_tag1_lru & {3{i_hit_mask[1]}} |
                          i_tag2_lru & {3{i_hit_mask[2]}} |
                          i_tag3_lru & {3{i_hit_mask[3]}} |
                          i_tag4_lru & {3{i_hit_mask[4]}} |
                          i_tag5_lru & {3{i_hit_mask[5]}} |
                          i_tag6_lru & {3{i_hit_mask[6]}} |
                          i_tag7_lru & {3{i_hit_mask[7]}};
//
// Comparators (tagi_lru < hit_tag_lru)
//
 wire cmps0 = (i_tag0_lru < hit_tag_mux);
 wire cmps1 = (i_tag1_lru < hit_tag_mux);
 wire cmps2 = (i_tag2_lru < hit_tag_mux);
 wire cmps3 = (i_tag3_lru < hit_tag_mux);
 wire cmps4 = (i_tag4_lru < hit_tag_mux);
 wire cmps5 = (i_tag5_lru < hit_tag_mux);
 wire cmps6 = (i_tag6_lru < hit_tag_mux);
 wire cmps7 = (i_tag7_lru < hit_tag_mux);
//
//
//
 wire tag0_clr = (((big0 &~i_inv_tag_detect) | i_inv_tag_msk[0]) & i_replace_req) | i_hit_mask[0];
 wire tag1_clr = (((big1 &~i_inv_tag_detect) | i_inv_tag_msk[1]) & i_replace_req) | i_hit_mask[1];
 wire tag2_clr = (((big2 &~i_inv_tag_detect) | i_inv_tag_msk[2]) & i_replace_req) | i_hit_mask[2];
 wire tag3_clr = (((big3 &~i_inv_tag_detect) | i_inv_tag_msk[3]) & i_replace_req) | i_hit_mask[3];
 wire tag4_clr = (((big4 &~i_inv_tag_detect) | i_inv_tag_msk[4]) & i_replace_req) | i_hit_mask[4];
 wire tag5_clr = (((big5 &~i_inv_tag_detect) | i_inv_tag_msk[5]) & i_replace_req) | i_hit_mask[5];
 wire tag6_clr = (((big6 &~i_inv_tag_detect) | i_inv_tag_msk[6]) & i_replace_req) | i_hit_mask[6];
 wire tag7_clr = (((big7 &~i_inv_tag_detect) | i_inv_tag_msk[7]) & i_replace_req) | i_hit_mask[7];
//
 wire hit      = |i_hit_mask;
 wire tag0_inc = ((cmps0 & hit) | i_replace_req) & i_tag_V[0];
 wire tag1_inc = ((cmps1 & hit) | i_replace_req) & i_tag_V[1];
 wire tag2_inc = ((cmps2 & hit) | i_replace_req) & i_tag_V[2];
 wire tag3_inc = ((cmps3 & hit) | i_replace_req) & i_tag_V[3];
 wire tag4_inc = ((cmps4 & hit) | i_replace_req) & i_tag_V[4];
 wire tag5_inc = ((cmps5 & hit) | i_replace_req) & i_tag_V[5];
 wire tag6_inc = ((cmps6 & hit) | i_replace_req) & i_tag_V[6];
 wire tag7_inc = ((cmps7 & hit) | i_replace_req) & i_tag_V[7];
//
 assign o_tag0_lru =~i_lru_enable ? i_tag0_lru :
                     tag0_clr  ? 3'b0 :
                     tag0_inc  ? i_tag0_lru + 1'b1 : i_tag0_lru;
//
 assign o_tag1_lru =~i_lru_enable ? i_tag1_lru :
                     tag1_clr  ? 3'b0 :
                     tag1_inc  ? i_tag1_lru + 1'b1 : i_tag1_lru;
//
 assign o_tag2_lru =~i_lru_enable ? i_tag2_lru :
                     tag2_clr  ? 3'b0 :
                     tag2_inc  ? i_tag2_lru + 1'b1 : i_tag2_lru;
//
 assign o_tag3_lru =~i_lru_enable ? i_tag3_lru :
                     tag3_clr  ? 3'b0 :
                     tag3_inc  ? i_tag3_lru + 1'b1 : i_tag3_lru;
//
 assign o_tag4_lru =~i_lru_enable ? i_tag4_lru :
                     tag4_clr  ? 3'b0 :
                     tag4_inc  ? i_tag4_lru + 1'b1 : i_tag4_lru;
//
 assign o_tag5_lru =~i_lru_enable ? i_tag5_lru :
                     tag5_clr  ? 3'b0 :
                     tag5_inc  ? i_tag5_lru + 1'b1 : i_tag5_lru;
//
 assign o_tag6_lru =~i_lru_enable ? i_tag6_lru :
                     tag6_clr  ? 3'b0 :
                     tag6_inc  ? i_tag6_lru + 1'b1 : i_tag6_lru;
//
 assign o_tag7_lru =~i_lru_enable ? i_tag7_lru :
                     tag7_clr  ? 3'b0 :
                     tag7_inc  ? i_tag7_lru + 1'b1 : i_tag7_lru;
//
 assign o_tag_V = i_tag_V              & {8{hit & i_lru_enable}} |
                  (i_tag_V | i_inv_tag_msk) & {8{i_replace_req & i_lru_enable}};
/*
 assign o_replace_msk = ({big7 &~i_inv_tag_detect,
                          big6 &~i_inv_tag_detect,
                          big5 &~i_inv_tag_detect,
                          big4 &~i_inv_tag_detect,
                          big3 &~i_inv_tag_detect,
                          big2 &~i_inv_tag_detect,
                          big1 &~i_inv_tag_detect,
                          big0 &~i_inv_tag_detect} |
                         i_inv_tag_msk) & {8{i_replace_req}};
*/
 assign o_replace_msk = i_replace_req ? (i_inv_tag_detect ? i_inv_tag_msk : 
                                                            {big7, big6, big5, big4,
                                                             big3,big2,big1,big0}) : 8'b0;
//
assign o_WriteCheckOpAllowed = 1'b1;
//
endmodule
