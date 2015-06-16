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
// Abstract      : L2C tags logic
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c_tag.v,v $
// CVS revision  : $Revision: 1.49 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// l2c_tag
//
module l2c_tag(
   input             Clk,
   input             Reset,
//
   input             i_lru_mode,
   input      [ 2:0] i_ctl_epoch,
   input      [ 2:0] i_ctl_min_cpu_ways,
//
   input      [31:0] i_fill_adr,
   input             i_fill_check_req,
   input             i_fill_set_req,
   input      [ 2:0] i_fill_set_way,
   output reg        o_fill_success,
   output reg        o_fill_fail,
//
   input      [31:0] i_wb_ack_adr,
   input             i_wb_ack_req,
   output reg        o_wb_ack_ack,
//
   input      [31:0] i_dl1_adr,
   input             i_dl1_wen,
   input             i_dl1_req,
   output reg        o_dl1_hit,
   output reg        o_dl1_retry,
   output reg        o_dl1_miss,
//
   input      [31:0] i_il1_adr,
   input             i_il1_req,
   output reg        o_il1_hit,
   output reg        o_il1_retry,
   output reg        o_il1_miss,
//
   input      [31:0] i_write_adr,
   input             i_write_dirty,
   input             i_write_check,
   input             i_write_req,
   output reg        o_write_success,
   output reg        o_write_retry,
   output reg        o_write_fail,
//
   input      [31:0] i_read_adr,
   input             i_read_ignore_dirty,
   input             i_read_req,
   output reg        o_read_success,
   output reg        o_read_fail,
   output reg        o_read_retry,
//
   input             i_writeback_req,
   input             i_writeback_combo,
   output            o_writeback_ack,
//
   input      [31:0] i_maintenance_adr,
   input             i_maintenance_clear,
   input             i_maintenance_req,
   output reg        o_maintenance_clear_ack,
   output reg        o_maintenance_flush_dirty,
   output reg        o_maintenance_flush_clean,
//
   output reg [ 2:0] o_hit_way,
   output reg [16:0] o_old_tag,
   output reg [ 4:0] o_tag_flags,
//
   output     [ 5:0] o_sram_arb,
   output            o_sram_valid,
   input             i_sram_stall);
//////////////////////////
wire       epc_sel =~i_lru_mode;
wire       lru_tag_wr;
wire [7:0] lru_repl_way_mask;
wire [7:0] lru_tag_V;
wire [2:0] lru_tag0;
wire [2:0] lru_tag1;
wire [2:0] lru_tag2;
wire [2:0] lru_tag3;
wire [2:0] lru_tag4;
wire [2:0] lru_tag5;
wire [2:0] lru_tag6;
wire [2:0] lru_tag7;
//////////////////////////
// Tag FSM Parameters
parameter Idle      = 5'b00001,
          ReadTag   = 5'b00010,
          WriteTag  = 5'b00100,
          Sram0     = 5'b01000,
          Sram1     = 5'b10000;
//
reg  [4:0] TagState;

// synthesis translate_off
reg [256:0] TagStateString;
always @(TagState) begin
  case (TagState) 
    Idle     : TagStateString = "Idle";
    ReadTag  : TagStateString = "ReadTag";
    WriteTag : TagStateString = "WriteTag";
    Sram0    : TagStateString = "Sram0";
    Sram1    : TagStateString = "Sram1";
    default  : TagStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
// Priority Enforcer
// Priority is right <- left (MS)
//
wire [15:0] in_sel;
//
LdEnPriorEnf # (
  .N_log    ( 4 )
) ipr_enf (
  .Clk         ( Clk ),
  .Reset       ( Reset ),
  .LdEn        ( (TagState==Idle) ),
  .In          ( {4'b0,
                  i_maintenance_req & ~i_maintenance_clear,
                  i_maintenance_req &  i_maintenance_clear,
                  i_writeback_req &  i_writeback_combo,
                  i_writeback_req & ~i_writeback_combo,
                  i_read_req,
                  i_write_req & ~i_write_check,
                  i_write_req &  i_write_check,
                  i_il1_req,
                  i_dl1_req,
                  i_wb_ack_req,
                  i_fill_set_req,
                  i_fill_check_req}),
  .Out         ( in_sel ),
  .Mask        (),
  .OneDetected ( TagFsmStart )
);
//
wire FillCheckOp  = in_sel[0];
wire FillSetOp    = in_sel[1];
wire WbAckOp      = in_sel[2];
wire DL1Op        = in_sel[3];
wire IL1Op        = in_sel[4];
wire WriteCheckOp = in_sel[5];
wire WriteSetOp   = in_sel[6];
wire ReadOp       = in_sel[7];
wire WbSingleOp   = in_sel[8];
wire WbComboOp    = in_sel[9];
wire MaintClearOp = in_sel[10];
wire MaintFlushOp = in_sel[11];
//
wire FillOp       = FillCheckOp | FillSetOp;
wire L1Op         = DL1Op | IL1Op;
wire WriteOp      = WriteCheckOp | WriteSetOp;
wire WbOp         = WbSingleOp | WbComboOp;
wire MaintOp      = MaintClearOp | MaintFlushOp;
//
wire [31:0] add_mux = i_fill_adr        & {32{FillOp}} |
                      i_wb_ack_adr      & {32{WbAckOp}} |
                      i_dl1_adr         & {32{DL1Op}} |
                      i_il1_adr         & {32{IL1Op}} |
                      i_write_adr       & {32{WriteOp}} |
                      i_read_adr        & {32{ReadOp}} |
                      i_maintenance_adr & {32{MaintOp}};
//
wire [35:0] rdata0, rdata1, rdata2, rdata3, rdata4, rdata5;
reg  [16:0] tag_reg;
reg  [ 8:0] addr_reg;
//
always @(posedge Clk) 
  if (TagState == Idle) begin
    addr_reg <= #`dh add_mux[14:6];
    tag_reg  <= #`dh add_mux[31:15];
  end
//
wire [ 8:0] addr = (TagState == Idle) ? add_mux[14:6] : addr_reg;
//
wire [26:0] tag0_rdata = rdata0[26: 0];
wire        tag0_hit   = tag0_rdata[24] & (tag0_rdata[16:0] == tag_reg) & (TagState != Idle);
//
wire [26:0] tag1_rdata = {rdata1[17: 0], rdata0[35:27]};
wire        tag1_hit   = tag1_rdata[24] & (tag1_rdata[16:0] == tag_reg) & (TagState != Idle);
//
wire [26:0] tag2_rdata = {rdata2[ 8: 0], rdata1[35:18]};
wire        tag2_hit   = tag2_rdata[24] & (tag2_rdata[16:0] == tag_reg) & (TagState != Idle);
//
wire [26:0] tag3_rdata = rdata2[35: 9];
wire        tag3_hit   = tag3_rdata[24] & (tag3_rdata[16:0] == tag_reg) & (TagState != Idle);
//
wire [26:0] tag4_rdata = rdata3[26: 0];
wire        tag4_hit   = tag4_rdata[24] & (tag4_rdata[16:0] == tag_reg) & (TagState != Idle);
//
wire [26:0] tag5_rdata = {rdata4[17: 0], rdata3[35:27]};
wire        tag5_hit   = tag5_rdata[24] & (tag5_rdata[16:0] == tag_reg) & (TagState != Idle);
//
wire [26:0] tag6_rdata = {rdata5[ 8: 0], rdata4[35:18]};
wire        tag6_hit   = tag6_rdata[24] & (tag6_rdata[16:0] == tag_reg) & (TagState != Idle);
//
wire [26:0] tag7_rdata = rdata5[35: 9];
wire        tag7_hit   = tag7_rdata[24] & (tag7_rdata[16:0] == tag_reg) & (TagState != Idle);
//
wire        tag_hit    = tag0_hit | tag1_hit | tag2_hit | tag3_hit |
                         tag4_hit | tag5_hit | tag6_hit | tag7_hit; 
//
wire [ 7:0] hit_mask   = {tag7_hit, tag6_hit, tag5_hit, tag4_hit,
                          tag3_hit, tag2_hit, tag1_hit, tag0_hit}; 
//
wire       tag7_V         = tag7_rdata[24];
wire       tag7_D         = tag7_rdata[23];
wire       tag7_B         = tag7_rdata[22];
wire       tag7_W         = tag7_rdata[21];
wire       tag7_F         = tag7_rdata[20];
wire [2:0] tag7_EPC       = tag7_rdata[19:17];
wire       tag7_transient = tag7_B | tag7_W | tag7_F;
//
wire       tag6_V         = tag6_rdata[24];
wire       tag6_D         = tag6_rdata[23];
wire       tag6_B         = tag6_rdata[22];
wire       tag6_W         = tag6_rdata[21];
wire       tag6_F         = tag6_rdata[20];
wire [2:0] tag6_EPC       = tag6_rdata[19:17];
wire       tag6_transient = tag6_B | tag6_W | tag6_F;
//
wire       tag5_V         = tag5_rdata[24];
wire       tag5_D         = tag5_rdata[23];
wire       tag5_B         = tag5_rdata[22];
wire       tag5_W         = tag5_rdata[21];
wire       tag5_F         = tag5_rdata[20];
wire [2:0] tag5_EPC       = tag5_rdata[19:17];
wire       tag5_transient = tag5_B | tag5_W | tag5_F;
//
wire       tag4_V         = tag4_rdata[24];
wire       tag4_D         = tag4_rdata[23];
wire       tag4_B         = tag4_rdata[22];
wire       tag4_W         = tag4_rdata[21];
wire       tag4_F         = tag4_rdata[20];
wire [2:0] tag4_EPC       = tag4_rdata[19:17];
wire       tag4_transient = tag4_B | tag4_W | tag4_F;
//
wire       tag3_V         = tag3_rdata[24];
wire       tag3_D         = tag3_rdata[23];
wire       tag3_B         = tag3_rdata[22];
wire       tag3_W         = tag3_rdata[21];
wire       tag3_F         = tag3_rdata[20];
wire [2:0] tag3_EPC       = tag3_rdata[19:17];
wire       tag3_transient = tag3_B | tag3_W | tag3_F;
//
wire       tag2_V         = tag2_rdata[24];
wire       tag2_D         = tag2_rdata[23];
wire       tag2_B         = tag2_rdata[22];
wire       tag2_W         = tag2_rdata[21];
wire       tag2_F         = tag2_rdata[20];
wire [2:0] tag2_EPC       = tag2_rdata[19:17];
wire       tag2_transient = tag2_B | tag2_W | tag2_F;
//
wire       tag1_V         = tag1_rdata[24];
wire       tag1_D         = tag1_rdata[23];
wire       tag1_B         = tag1_rdata[22];
wire       tag1_W         = tag1_rdata[21];
wire       tag1_F         = tag1_rdata[20];
wire [2:0] tag1_EPC       = tag1_rdata[19:17];
wire       tag1_transient = tag1_B | tag1_W | tag1_F;
//
wire       tag0_V         = tag0_rdata[24];
wire       tag0_D         = tag0_rdata[23];
wire       tag0_B         = tag0_rdata[22];
wire       tag0_W         = tag0_rdata[21];
wire       tag0_F         = tag0_rdata[20];
wire [2:0] tag0_EPC       = tag0_rdata[19:17];
wire       tag0_transient = tag0_B | tag0_W | tag0_F;
//
wire [26:0] tag_wdata;
wire [ 2:0] tag0_wen, tag1_wen, tag2_wen, tag3_wen,
            tag4_wen, tag5_wen, tag6_wen, tag7_wen;
//
wire [ 2:0] maint_lru_tag0 = MaintClearOp ? 0: lru_tag0;
wire [ 2:0] maint_lru_tag1 = MaintClearOp ? 0: lru_tag1;
wire [ 2:0] maint_lru_tag2 = MaintClearOp ? 0: lru_tag2;
wire [ 2:0] maint_lru_tag3 = MaintClearOp ? 0: lru_tag3;
wire [ 2:0] maint_lru_tag4 = MaintClearOp ? 0: lru_tag4;
wire [ 2:0] maint_lru_tag5 = MaintClearOp ? 0: lru_tag5;
wire [ 2:0] maint_lru_tag6 = MaintClearOp ? 0: lru_tag6;
wire [ 2:0] maint_lru_tag7 = MaintClearOp ? 0: lru_tag7;
wire [35:0] lru_wr = {12'b0,
                      maint_lru_tag7,maint_lru_tag6,
                      maint_lru_tag5,maint_lru_tag4,
                      maint_lru_tag3,maint_lru_tag2,
                      maint_lru_tag1,maint_lru_tag0};
wire [35:0] lru_rd;
wire [ 3:0] lru_mem_wen;
//
xil_mem_sp_512x36 
    tm0(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag1_wen[0], tag0_wen} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag_wdata[8:0], tag_wdata} ),
        .o_rdata ( rdata0 )),
//
    tm1(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag2_wen[1:0],tag1_wen[2:1]} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag_wdata[17:0], tag_wdata[26:9]} ),
        .o_rdata ( rdata1 )),
//
    tm2(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag3_wen,tag2_wen[2]} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag_wdata, tag_wdata[26:18]} ),
        .o_rdata ( rdata2 )),
//
    tm3(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag5_wen[0],tag4_wen} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag_wdata[8:0], tag_wdata} ),
        .o_rdata ( rdata3 )),
//
    tm4(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag6_wen[1:0],tag5_wen[2:1]} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag_wdata[17:0], tag_wdata[26:9]} ),
        .o_rdata ( rdata4 )),
//
    tm5(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag7_wen,tag6_wen[2]} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag_wdata, tag_wdata[26:18]} ),
        .o_rdata ( rdata5 )),
//
    lru(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( lru_mem_wen ),
        .i_adr   ( addr ),
        .i_wdata ( lru_wr ),
        .o_rdata ( lru_rd));
//
assign lru_mem_wen = ((TagState==WriteTag) & lru_tag_wr) ? 3'b111 : 3'b000;
//
wire [7:0] tag_way_sel;
/*
wire [26:0] tag0_wdata = epc_sel        ? tag_wdata : 
                         tag_way_sel[0] ? {tag_wdata[26:20],  maint_lru_tag0, tag_wdata[16:0]} :
                                          {tag0_rdata[26:20], maint_lru_tag0, tag0_rdata[16:0]};
wire [26:0] tag1_wdata = epc_sel        ? tag_wdata : 
                         tag_way_sel[1] ? {tag_wdata[26:20],  maint_lru_tag1, tag_wdata[16:0]} :
                                          {tag1_rdata[26:20], maint_lru_tag1, tag1_rdata[16:0]};
wire [26:0] tag2_wdata = epc_sel        ? tag_wdata : 
                         tag_way_sel[2] ? {tag_wdata[26:20],  maint_lru_tag2, tag_wdata[16:0]} :
                                          {tag2_rdata[26:20], maint_lru_tag2, tag2_rdata[16:0]};
wire [26:0] tag3_wdata = epc_sel        ? tag_wdata : 
                         tag_way_sel[3] ? {tag_wdata[26:20],  maint_lru_tag3, tag_wdata[16:0]} :
                                          {tag3_rdata[26:20], maint_lru_tag3, tag3_rdata[16:0]};
wire [26:0] tag4_wdata = epc_sel        ? tag_wdata : 
                         tag_way_sel[4] ? {tag_wdata[26:20],  maint_lru_tag4, tag_wdata[16:0]} :
                                          {tag4_rdata[26:20], maint_lru_tag4, tag4_rdata[16:0]};
wire [26:0] tag5_wdata = epc_sel        ? tag_wdata : 
                         tag_way_sel[5] ? {tag_wdata[26:20],  maint_lru_tag5, tag_wdata[16:0]} :
                                          {tag5_rdata[26:20], maint_lru_tag5, tag5_rdata[16:0]};
wire [26:0] tag6_wdata = epc_sel        ? tag_wdata : 
                         tag_way_sel[6] ? {tag_wdata[26:20],  maint_lru_tag6, tag_wdata[16:0]} :
                                          {tag6_rdata[26:20], maint_lru_tag6, tag6_rdata[16:0]};
wire [26:0] tag7_wdata = epc_sel        ? tag_wdata : 
                         tag_way_sel[7] ? {tag_wdata[26:20],  maint_lru_tag7, tag_wdata[16:0]} :
                                          {tag7_rdata[26:20], maint_lru_tag7, tag7_rdata[16:0]};
//
 xil_mem_sp_512x36
    tm0(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag1_wen[0], tag0_wen} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag1_wdata[8:0], tag0_wdata} ),
        .o_rdata ( rdata0 )),
//
    tm1(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag2_wen[1:0],tag1_wen[2:1]} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag2_wdata[17:0], tag1_wdata[26:9]} ),
        .o_rdata ( rdata1 )),
//
    tm2(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag3_wen,tag2_wen[2]} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag3_wdata, tag2_wdata[26:18]} ),
        .o_rdata ( rdata2 )),
//
    tm3(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag5_wen[0],tag4_wen} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag5_wdata[8:0], tag4_wdata} ),
        .o_rdata ( rdata3 )),
//
    tm4(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag6_wen[1:0],tag5_wen[2:1]} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag6_wdata[17:0], tag5_wdata[26:9]} ),
        .o_rdata ( rdata4 )),
//
    tm5(.clk     ( Clk ),
        .i_en    ( 1'b1 ),
        .i_wen   ( {tag7_wen,tag6_wen[2]} ),
        .i_adr   ( addr ),
        .i_wdata ( {tag7_wdata, tag6_wdata[26:18]} ),
        .o_rdata ( rdata5 ));
*/
// Tag FSM
//
wire w_tag_B;
//
 always @(posedge Clk) begin
    if(Reset) TagState <= #`dh Idle;
    else begin
       case(TagState)
//
       Idle     : begin
                     if (~TagFsmStart)
                        TagState <= #`dh Idle;
                     else if (WbSingleOp | WbComboOp)
                        TagState <= #`dh Sram0;
                     else
                        TagState <= #`dh ReadTag;
                  end
//
       ReadTag  : TagState <= #`dh WriteTag;
//
       WriteTag : begin
                     if ((FillCheckOp & o_fill_success) |

                         o_dl1_hit |

                         o_il1_hit |

                         (o_write_success & // "pure" writes only:
                          WriteCheckOp &    // wb and then write
                          ~w_tag_B) |       // is handled by the
                                            // WbComboOp
                         o_read_success)

                       TagState <= #`dh Sram0;
                     else
                       TagState <= #`dh Idle;
                  end
//
       Sram0    : begin
                     if (i_sram_stall) 
                        TagState <= #`dh Sram0;
                     else if (WbComboOp)
                        TagState <= #`dh Sram1;
                     else
                        TagState <= #`dh Idle;
                  end
//
       Sram1    : begin
                     if (i_sram_stall) 
                        TagState <= #`dh Sram1;
                     else
                        TagState <= #`dh Idle;
                  end
//
       default  : TagState <= #`dh Idle;
//
       endcase
    end
 end
//
/////////////////// Tag Replacement ////////////////////////
//
wire [7:0] inv_mask_oh;
//
PriorEnf prenf_v(.In          ( {(~tag7_V & ~tag7_transient),
                                 (~tag6_V & ~tag6_transient),
                                 (~tag5_V & ~tag5_transient),
                                 (~tag4_V & ~tag4_transient),
                                 (~tag3_V & ~tag3_transient),
                                 (~tag2_V & ~tag2_transient),
                                 (~tag1_V & ~tag1_transient),
                                 (~tag0_V & ~tag0_transient)}),
                 .Out         ( inv_mask_oh ),
                 .Mask        (),
                 .OneDetected ( invalid_tag_detected));
//
///////////////////////// George ///////////////////////////
//
// EPC
//
wire       rnd_shift = (TagState==WriteTag);
wire [7:0] epc_repl_way_mask;
wire [2:0] cur_epoch;
wire [2:0] nxt_epoch;
//
l2c_epc il2c_epc(
   .Clk                    ( Clk ),
   .Reset                  ( Reset ),
   .i_rnd_shift            ( rnd_shift ),
   .i_ctl_epoch            ( i_ctl_epoch ),
   .i_ctl_min_cpu_ways     ( i_ctl_min_cpu_ways ),
   .i_tag_V                ( {tag7_V, tag6_V, tag5_V, tag4_V,
                              tag3_V, tag2_V, tag1_V, tag0_V} ),
   .i_tag_transient        ( {tag7_transient,tag6_transient,
                              tag5_transient,tag4_transient,
                              tag3_transient,tag2_transient,
                              tag1_transient,tag0_transient} ),
   .i_inv_mask_oh          ( inv_mask_oh ),
   .i_inv_tag_detect       ( invalid_tag_detected ),
   .i_tag0_epc             ( tag0_EPC ),
   .i_tag1_epc             ( tag1_EPC ),
   .i_tag2_epc             ( tag2_EPC ),
   .i_tag3_epc             ( tag3_EPC ),
   .i_tag4_epc             ( tag4_EPC ),
   .i_tag5_epc             ( tag5_EPC ),
   .i_tag6_epc             ( tag6_EPC ),
   .i_tag7_epc             ( tag7_EPC ),
   .i_WriteCheckOp         ( WriteCheckOp ),
   .i_WriteOp              ( WriteOp ),
   .i_L1Op                 ( L1Op ),
   .o_repl_way_mask        ( epc_repl_way_mask ),
   .o_WriteCheckOpAllowed  ( epc_WriteCheckOpAllowed ),
   .o_cur_epoch            ( cur_epoch ),
   .o_nxt_epoch            ( nxt_epoch ));
//
// LRU
//
wire       WriteCheckOpAllowed;
wire       lru_replace_req = (((L1Op & ~tag_hit) | 
                               (WriteCheckOp & ~tag_hit & WriteCheckOpAllowed)) &~epc_sel);
wire       lru_enable      = lru_replace_req | ((L1Op & tag_hit) &~epc_sel);
//
l2c_lru il2c_lru(
   .Clk                   ( Clk ),
   .Reset                 ( Reset ),
//
   .i_lru_enable          ( lru_enable ),
   .i_tag_V               ( {tag7_V, tag6_V,
                             tag5_V, tag4_V,
                             tag3_V, tag2_V,
                             tag1_V, tag0_V} ),
   .i_inv_tag_msk         ( inv_mask_oh ),
   .i_inv_tag_detect      ( invalid_tag_detected ),
   .i_hit_mask            ( hit_mask ),
   .i_replace_req         ( lru_replace_req ),
   .i_tag0_lru            ( lru_rd[ 2: 0] ),
   .i_tag1_lru            ( lru_rd[ 5: 3] ),
   .i_tag2_lru            ( lru_rd[ 8: 6] ),
   .i_tag3_lru            ( lru_rd[11: 9] ),
   .i_tag4_lru            ( lru_rd[14:12] ),
   .i_tag5_lru            ( lru_rd[17:15] ),
   .i_tag6_lru            ( lru_rd[20:18] ),
   .i_tag7_lru            ( lru_rd[23:21] ),
   .i_WriteCheckOp        ( WriteCheckOp ),
//
   .o_WriteCheckOpAllowed ( lru_WriteCheckOpAllowed ),
   .o_tag0_lru            ( lru_tag0 ),
   .o_tag1_lru            ( lru_tag1 ),
   .o_tag2_lru            ( lru_tag2 ),
   .o_tag3_lru            ( lru_tag3 ),
   .o_tag4_lru            ( lru_tag4 ),
   .o_tag5_lru            ( lru_tag5 ),
   .o_tag6_lru            ( lru_tag6 ),
   .o_tag7_lru            ( lru_tag7 ),
   .o_tag_V               ( lru_tag_V ),
   .o_replace_msk         ( lru_repl_way_mask ));
//
assign lru_tag_wr = |lru_tag_V;
assign WriteCheckOpAllowed = epc_sel ? epc_WriteCheckOpAllowed : lru_WriteCheckOpAllowed;
wire [7:0] repl_way_mask   = epc_sel ? epc_repl_way_mask       : lru_repl_way_mask;
//
///////////////////////// George ///////////////////////////
//
wire [7:0] W_mask = {tag7_W, tag6_W, tag5_W, tag4_W,
                     tag3_W, tag2_W, tag1_W, tag0_W};
//
wire [7:0] B_mask = {tag7_hit & tag7_B, tag6_hit & tag6_B, 
                     tag5_hit & tag5_B, tag4_hit & tag4_B, 
                     tag3_hit & tag3_B, tag2_hit & tag2_B, 
                     tag1_hit & tag1_B, tag0_hit & tag0_B};
//
wire [7:0] FB_mask_in = {tag7_F & ~tag7_B, tag6_F & ~tag6_B, 
                         tag5_F & ~tag5_B, tag4_F & ~tag4_B, 
                         tag3_F & ~tag3_B, tag2_F & ~tag2_B, 
                         tag1_F & ~tag1_B, tag0_F & ~tag0_B};
//
wire [7:0] D_mask_in = {tag7_D, tag6_D, tag5_D, tag4_D,
                        tag3_D, tag2_D, tag1_D, tag0_D};
wire [7:0] D_mask;
//
PriorEnf D_maskPriorEnf(
             .In          ( D_mask_in ),
             .Out         ( D_mask ),
             .Mask        ( ),
             .OneDetected ( D_Detected ));

//
wire [7:0] FB_mask;
//
PriorEnf FB_maskPriorEnf(
             .In          ( FB_mask_in ),
             .Out         ( FB_mask ),
             .Mask        ( ),
             .OneDetected ( FB_Detected ));
//
wire [7:0] fill_set_way_mask;
decoder # (.N_log    ( 3 ))
  fill_set_way_dec (
  .o_out    ( fill_set_way_mask ), 
  .i_in     ( i_fill_set_way ));
//
 //wire [7:0] tag_way_sel = ((L1Op | WriteCheckOp) &~tag_hit) ? repl_way_mask :
 assign  tag_way_sel = (L1Op & ~tag_hit) ? repl_way_mask :
                       (WriteCheckOp & ~tag_hit & WriteCheckOpAllowed) ? repl_way_mask :
                       WriteSetOp    ? W_mask :
                       FillCheckOp   ? FB_mask :
                       FillSetOp     ? fill_set_way_mask :
                       MaintFlushOp  ? D_mask :
                       MaintClearOp  ? 8'b1111_1111 : hit_mask;
//
 always @(posedge Clk) begin
   (* full_case *)
   case (tag_way_sel)
     8'b0000_0001: o_hit_way <= #`dh 3'd0;
     8'b0000_0010: o_hit_way <= #`dh 3'd1;
     8'b0000_0100: o_hit_way <= #`dh 3'd2;
     8'b0000_1000: o_hit_way <= #`dh 3'd3;
     8'b0001_0000: o_hit_way <= #`dh 3'd4;
     8'b0010_0000: o_hit_way <= #`dh 3'd5;
     8'b0100_0000: o_hit_way <= #`dh 3'd6;
     8'b1000_0000: o_hit_way <= #`dh 3'd7;
     default     : o_hit_way <= #`dh 3'bx;
   endcase
 end
//
 assign tag0_wen = ((TagState==WriteTag) & tag_way_sel[0]) ? 3'b111 : 3'b000;
 assign tag1_wen = ((TagState==WriteTag) & tag_way_sel[1]) ? 3'b111 : 3'b000;
 assign tag2_wen = ((TagState==WriteTag) & tag_way_sel[2]) ? 3'b111 : 3'b000;
 assign tag3_wen = ((TagState==WriteTag) & tag_way_sel[3]) ? 3'b111 : 3'b000;
 assign tag4_wen = ((TagState==WriteTag) & tag_way_sel[4]) ? 3'b111 : 3'b000;
 assign tag5_wen = ((TagState==WriteTag) & tag_way_sel[5]) ? 3'b111 : 3'b000;
 assign tag6_wen = ((TagState==WriteTag) & tag_way_sel[6]) ? 3'b111 : 3'b000;
 assign tag7_wen = ((TagState==WriteTag) & tag_way_sel[7]) ? 3'b111 : 3'b000;
//
wire [26:0] tag_rdata = tag7_rdata & {27{tag_way_sel[7]}} |
                        tag6_rdata & {27{tag_way_sel[6]}} |
                        tag5_rdata & {27{tag_way_sel[5]}} |
                        tag4_rdata & {27{tag_way_sel[4]}} |
                        tag3_rdata & {27{tag_way_sel[3]}} |
                        tag2_rdata & {27{tag_way_sel[2]}} |
                        tag1_rdata & {27{tag_way_sel[1]}} |
                        tag0_rdata & {27{tag_way_sel[0]}};
//
wire        r_tag_V      = tag_rdata[24];
wire        r_tag_D      = tag_rdata[23];
wire        r_tag_B      = tag_rdata[22];
wire        r_tag_W      = tag_rdata[21];
wire        r_tag_F      = tag_rdata[20];
wire [ 2:0] r_tag_EPC    = tag_rdata[19:17];
wire [ 2:0] r_tag_LRU    = tag_rdata[19:17];
wire [16:0] r_tag_adr    = tag_rdata[16:0];
wire        r_transient  = r_tag_B | r_tag_F | r_tag_W;
wire        r_write_race = r_tag_B & r_tag_F & ~r_tag_W;
//
wire w_tag_V_set = (WriteSetOp &~r_tag_B) | 
                   FillSetOp;
wire w_tag_V_clr = MaintClearOp;
//
wire w_tag_D_set = (L1Op & i_dl1_wen & DL1Op) |  // D_set has priority over D_clr (L1Op & ~tag_hit) below
                   (WriteSetOp &~r_tag_B & i_write_dirty);
wire w_tag_D_clr = MaintClearOp | 
                   MaintFlushOp |
                   (L1Op & ~tag_hit) |
                   (WriteCheckOp & tag_hit &~r_transient) |
                   (WriteCheckOp & ~tag_hit & WriteCheckOpAllowed) |
                   (ReadOp & tag_hit &~r_tag_B & i_read_ignore_dirty);
//
wire w_tag_B_set = (L1Op &~tag_hit & r_tag_D) |
                   (WriteCheckOp & ~tag_hit & WriteCheckOpAllowed & r_tag_D) |
                   (MaintFlushOp & r_tag_D);
wire w_tag_B_clr = MaintClearOp | WbAckOp;
//
wire w_tag_W_set = (WriteCheckOp & tag_hit &~r_transient) |
                   (WriteCheckOp & ~tag_hit & WriteCheckOpAllowed);
wire w_tag_W_clr = MaintClearOp | 
                   (WriteSetOp &~r_tag_B) |
                   FillSetOp;
//
wire w_tag_F_set = (L1Op &~tag_hit);
wire w_tag_F_clr = MaintClearOp | FillSetOp;
//
wire w_tag_EPC_cpu = (L1Op & tag_hit) | FillSetOp;
wire w_tag_EPC_ni  = (WriteSetOp &~r_tag_B);
//
wire       w_tag_V   = w_tag_V_set ? 1'b1 :
                       w_tag_V_clr ? 1'b0 : r_tag_V;
//
wire       w_tag_D   = w_tag_D_set ? 1'b1 :
                       w_tag_D_clr ? 1'b0 : r_tag_D;
//
assign     w_tag_B   = w_tag_B_set ? 1'b1 :
                       w_tag_B_clr ? 1'b0 : r_tag_B;
//
wire       w_tag_W   = w_tag_W_set ? 1'b1 :
                       w_tag_W_clr ? 1'b0 : r_tag_W;
//
wire       w_tag_F   = w_tag_F_set ? 1'b1 :
                       w_tag_F_clr ? 1'b0 : r_tag_F;
// George
wire [2:0] w_tag_EPC = MaintClearOp  ? 3'b0 :
                       w_tag_EPC_cpu ? cur_epoch :
                       w_tag_EPC_ni  ? nxt_epoch : r_tag_EPC;
// George
wire [16:0] w_tag_addr = MaintClearOp ? 17'b0 :
                         w_tag_V_set  ? tag_reg : r_tag_adr;
//
assign tag_wdata = {2'b0,w_tag_V,w_tag_D,w_tag_B,w_tag_W,w_tag_F,w_tag_EPC,w_tag_addr};
//
 always @(posedge Clk) begin
    if(Reset) o_tag_flags <= #`dh 0;
    else      o_tag_flags <= #`dh {w_tag_V, w_tag_D, w_tag_B, w_tag_W, w_tag_F};
 end
//
 wire B_flag_valid = tag7_rdata[22] | tag6_rdata[22] | 
                     tag5_rdata[22] | tag4_rdata[22] |
                     tag3_rdata[22] | tag2_rdata[22] |
                     tag1_rdata[22] | tag0_rdata[22];
//
 always @(posedge Clk) begin
    if(Reset)begin
//
       o_fill_success  <= #`dh 0;
       o_fill_fail     <= #`dh 0;
//
       o_wb_ack_ack    <= #`dh 0;
//
       o_dl1_hit       <= #`dh 0;
       o_dl1_retry     <= #`dh 0;
       o_dl1_miss      <= #`dh 0;
//
       o_il1_hit       <= #`dh 0;
       o_il1_retry     <= #`dh 0;
       o_il1_miss      <= #`dh 0;
//
       o_write_success  <= #`dh 0;
       o_write_retry    <= #`dh 0;
       o_write_fail     <= #`dh 0;
//
       o_read_success  <= #`dh 0;
       o_read_retry    <= #`dh 0;
       o_read_fail     <= #`dh 0;
//
       o_maintenance_clear_ack   <= #`dh 0;
       o_maintenance_flush_dirty <= #`dh 0;
       o_maintenance_flush_clean <= #`dh 0;
//
    end
    else begin
       o_fill_success  <= #`dh (TagState==ReadTag) & (FillSetOp | 
                                                      (FillCheckOp & FB_Detected));
       o_fill_fail     <= #`dh (TagState==ReadTag) & (FillCheckOp &~FB_Detected);
//
       o_wb_ack_ack    <= #`dh (TagState==ReadTag) & WbAckOp;
//
       o_dl1_hit       <= #`dh (TagState==ReadTag) & DL1Op & tag_hit &~r_transient;
       o_dl1_retry     <= #`dh (TagState==ReadTag) & DL1Op & tag_hit & r_transient;
       o_dl1_miss      <= #`dh (TagState==ReadTag) & DL1Op &~tag_hit;
//
       o_il1_hit       <= #`dh (TagState==ReadTag) & IL1Op & tag_hit &~r_transient;
       o_il1_retry     <= #`dh (TagState==ReadTag) & IL1Op & tag_hit & r_transient;
       o_il1_miss      <= #`dh (TagState==ReadTag) & IL1Op &~tag_hit;
//
       o_write_success <= #`dh (TagState==ReadTag) & ((WriteCheckOp &~tag_hit & WriteCheckOpAllowed) | 
                                                      (WriteCheckOp & tag_hit &~r_transient) |
                                                      (WriteSetOp &~r_tag_B));
       o_write_retry   <= #`dh (TagState==ReadTag) & (WriteCheckOp & tag_hit & r_write_race);
       o_write_fail    <= #`dh (TagState==ReadTag) & ((WriteCheckOp &~tag_hit &~WriteCheckOpAllowed) |
                                                      (WriteCheckOp & tag_hit & r_transient &~r_write_race) |
                                                      (WriteSetOp & r_tag_B));
//
       o_read_success  <= #`dh (TagState==ReadTag) & ReadOp & tag_hit &~r_transient;
       o_read_retry    <= #`dh (TagState==ReadTag) & ReadOp & tag_hit & r_transient;
       o_read_fail     <= #`dh (TagState==ReadTag) & ReadOp &~tag_hit;
//
       o_maintenance_flush_dirty <= #`dh (TagState==ReadTag) & MaintFlushOp & D_Detected;
       o_maintenance_flush_clean <= #`dh (TagState==ReadTag) & MaintFlushOp &~D_Detected;
//
       o_maintenance_clear_ack <= #`dh (TagState==ReadTag) & MaintClearOp;
//  
    end
//
 end
//
assign o_writeback_ack = (TagState==Sram0) & (WbSingleOp | WbComboOp);
//
 always @(posedge Clk) begin
    if (TagState==ReadTag)
       o_old_tag <= #`dh r_tag_adr;
 end
//
// All arbitration values below have meaning only in Sram0 and Sram1 states
// (when o_sram_valid=1).
//
// "Pure" writes are done in Sram0 when WriteCheckOp=1.
// Single writebacks are done in Sram0 when WbSingleOp (which implies WbOp).
// A combo op is a writeback in Sram0 when WbComboOp (which implies WbOp) and
// then a write in Sram1, which is the only case we reach the Sram1 state.
//
assign o_sram_arb[5] = ReadOp;                              // read
assign o_sram_arb[4] = WriteCheckOp | (TagState == Sram1);  // write
assign o_sram_arb[3] = WbOp & (TagState == Sram0);          // writeback
assign o_sram_arb[2] = IL1Op;                               // IL1
assign o_sram_arb[1] = DL1Op;                               // DL1
assign o_sram_arb[0] = FillCheckOp;                         // Fill
//
assign o_sram_valid = (TagState == Sram0) | (TagState == Sram1);
//
// synthesis translate_off
wire George = L1Op & (addr==0) &~tag_hit & (TagState==WriteTag);
// synthesis translate_on
//
/*
reg [5:0] wr_ptr;
 always @(posedge Clk) begin
    if(Reset) wr_ptr <= #`dh 0;
    if(George) begin
//        $display (" Ptr : %h  Data : %h",wr_ptr,{w_tag_V,w_tag_D,w_tag_B,w_tag_W,w_tag_F,1'b0,w_tag_EPC});
        $display (" Ptr : %h  V : %h, D : %h  B : %h  W : %h  F : %h  LRU : %h",
                    wr_ptr,w_tag_V,w_tag_D,w_tag_B,w_tag_W,w_tag_F,w_tag_EPC);
        wr_ptr <= #`dh wr_ptr + 1;
    end
 end
*/
endmodule
