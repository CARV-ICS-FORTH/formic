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
// Abstract      : Level 2 Cache (L2C) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l2c.v,v $
// CVS revision  : $Revision: 1.41 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// L2
//
module l2c(
   input             clk_mc,
   input             rst_mc,
// Control Block Interface
   input             i_lru_mode,
   input             i_ctl_en,
   input             i_ctl_clear_req,
   input             i_ctl_flush_req,
   output            o_ctl_maint_ack,
   input      [ 2:0] i_ctl_epoch,
   input      [ 2:0] i_ctl_min_cpu_ways,
   output            o_ctl_trace_ihit,
   output            o_ctl_trace_imiss,
   output            o_ctl_trace_dhit,
   output            o_ctl_trace_dmiss,
// SRAM Interface
   output     [17:0] o_sctl_req_adr,
   output            o_sctl_req_we,
   output reg [31:0] o_sctl_req_wdata,
   output     [ 3:0] o_sctl_req_be,
   output            o_sctl_req_valid,
   input      [31:0] i_sctl_resp_rdata,
   input             i_sctl_resp_valid,
// Instruction L1 Cache (IL1) Interface
   input      [31:0] i_il1_adr,
   input             i_il1_flags,
   input             i_il1_valid,
   output            o_il1_rdata_valid,
   output reg [31:0] o_il1_rdata,
   output            o_il1_tlb_fault,
   output            o_il1_stall,
   output            o_il1_inv_req,
   output     [31:0] o_il1_inv_adr,
   input             i_il1_inv_ack,
// Data L1 Cache block (D1C) Interface
   input      [31:0] i_dl1_adr,
   input      [ 1:0] i_dl1_flags,
   input      [ 3:0] i_dl1_ben,
   input             i_dl1_wen,
   input      [31:0] i_dl1_wdata,
   input             i_dl1_valid,
   output            o_dl1_rdata_valid,
   output reg [31:0] o_dl1_rdata,
   output            o_dl1_tlb_fault,
   output            o_dl1_stall,
   output            o_dl1_inv_req,
   output     [31:0] o_dl1_inv_adr,
   input             i_dl1_inv_ack,
// Microblaze Network Interface (MNI) Writeback Interface
   input              i_mni_wb_space,
   output             o_mni_wb_valid,
   output      [31:0] o_mni_wb_adr,
// Microblaze Network Interface (MNI) Writeback Acknowledge Interface
   input              i_mni_wb_ack_valid,
   input              i_mni_wb_ack_fault,
   input       [31:0] i_mni_wb_ack_adr,
   output             o_mni_wb_ack_stall,
// Microblaze Network Interface (MNI) Miss Interface
   output             o_mni_miss_valid,
   output      [31:0] o_mni_miss_adr,
   output      [ 1:0] o_mni_miss_flags,
   output             o_mni_miss_wen,
   output reg  [ 3:0] o_mni_miss_ben,
   output reg  [31:0] o_mni_miss_wdata,
   input              i_mni_miss_stall,
// Microblaze Network Interface (MNI)  Fill Interface
   input              i_mni_fill_valid,
   input              i_mni_fill_fault,
   input       [ 3:0] i_mni_fill_len,
   input       [31:0] i_mni_fill_adr,
   output             o_mni_fill_stall,

// Microblaze Network Interface (MNI)  Write Interface
   input              i_mni_write_valid,
   input       [31:0] i_mni_write_adr,
   input              i_mni_write_dirty,
   output             o_mni_write_stall,
   output             o_mni_write_nack,
   output             o_mni_write_done,

// Microblaze Network Interface (MNI)  Read Interface
   input              i_mni_read_valid,
   input       [31:0] i_mni_read_adr,
   input              i_mni_read_ignore,
   output             o_mni_read_stall,
   output             o_mni_read_nack,
// Microblaze Network Interface (MNI) Common Data Busses
   input       [31:0] i_mni_data,
   output reg  [31:0] o_mni_data
);

//
/////////////////////////////////////////////////////////////////
//
wire [17:0] il1_sram_adr,    dl1_sram_adr,
            fill_sram_adr,   writeback_sram_adr,
            read_sram_adr,   write_sram_adr;
wire [16:0] write_old_tag;
wire [ 2:0] hit_way;
wire [16:0] il1_old_tag,     dl1_old_tag;
wire [16:0] tag_old_tag;
wire [ 4:0] tag_flags;
wire        maintenance_active;
wire        il1_tag_req,      dl1_tag_req;
wire        il1_miss_req,     dl1_miss_req;
wire        il1_miss_ack,     dl1_miss_ack;
wire        il1_start,        dl1_start;
wire        il1_end,          dl1_end;
wire        il1_hit,          dl1_hit;
wire        il1_miss,         dl1_miss;
wire        il1_retry,        dl1_retry;
wire        fill_direct,      fill_broadcast;
wire        fill_start,       fill_end;
wire        read_hit,         read_miss,      read_retry;
wire        read_start,       read_end;
wire        writeback_start,  writeback_end;
wire        write_hit,        write_miss,     write_retry;
wire        write_sram_start, write_sram_end;
wire        dl1_wb_ack,       il1_wb_ack;
wire [31:0] write_adr;
wire [ 5:0] tag_sram_arb;
//
// CTL trace interface
//
assign o_ctl_trace_ihit  = il1_hit;
assign o_ctl_trace_imiss = il1_miss;
assign o_ctl_trace_dhit  = dl1_hit;
assign o_ctl_trace_dmiss = dl1_miss;
//
// SRAM controller input registers
//
reg [31:0] sctl_resp_rdata_q;
reg        sctl_resp_valid_q;

always @(posedge clk_mc) begin
  sctl_resp_rdata_q <= #`dh i_sctl_resp_rdata;
  sctl_resp_valid_q <= #`dh i_sctl_resp_valid;
end
//
// Data L1 Interface
//
l2c_l1 dl1_if(
   .Clk                  ( clk_mc ),
   .Reset                ( rst_mc ),
   .i_ctl_en             ( i_ctl_en ),
   .o_l2c_idle           ( dl1_idle ),
//
   .i_l1_adr             ( i_dl1_adr ),
   .i_l1_flags           ( i_dl1_flags ),
   .i_l1_wen             ( i_dl1_wen ),
   .i_l1_valid           ( i_dl1_valid ),
   .o_l1_rdata_valid     ( o_dl1_rdata_valid ),
   .o_l1_stall           ( o_dl1_stall ),
//
   .i_maintenance_active ( maintenance_active ),
   .i_fill_adr           ( i_mni_fill_adr ),
   .i_fill_start         ( fill_start ),
   .i_B_flag             ( tag_flags[2] ),
   .i_hit                ( dl1_hit ),
   .i_retry              ( dl1_retry ),
   .i_miss               ( dl1_miss ),
   .i_way                ( hit_way ),
   .i_old_tag            ( tag_old_tag ),
   .i_start              ( dl1_start ),
   .i_end                ( dl1_end ),
   .i_wb_ack             ( dl1_wb_ack ),
   .i_direct             ( fill_direct ),
   .i_fill_broadcast     ( fill_broadcast ),
   .i_write_broadcast    ( write_broadcast ),
   .i_miss_ack           ( dl1_miss_ack ),
   .i_wb_ack_broadcast   ( wb_ack_broadcast ),
   .i_wb_ack_adr         ( i_mni_wb_ack_adr ),
   .i_sctl_resp_valid    ( sctl_resp_valid_q ),
   .o_l2c_replace_fault  ( dl1_replace_fault ),
   .o_old_tag            ( dl1_old_tag ),
   .o_read_hit           ( dl1_read_hit ),
   .o_write_hit          ( dl1_write_hit ),
   .o_wb_req             ( dl1_wb_req ),
   .o_sram_acc           ( dl1_sram_acc ),
   .o_sram_adr           ( dl1_sram_adr ),
   .o_tag_req            ( dl1_tag_req ),
   .o_miss               ( dl1_miss_req ),
   .o_l2c_replace_data   ( dl1_replace_data));
// 
// Instruction L1 Interface
//
l2c_l1 il1_if(
   .Clk                  ( clk_mc ),
   .Reset                ( rst_mc ),
   .i_ctl_en             ( i_ctl_en ),
   .o_l2c_idle           ( il1_idle ),
//
   .i_l1_adr             ( i_il1_adr ),
   .i_l1_flags           ( {i_il1_flags,1'b0} ),
   .i_l1_wen             ( 1'b0 ),
   .i_l1_valid           ( i_il1_valid ),
   .o_l1_rdata_valid     ( o_il1_rdata_valid ),
   .o_l1_stall           ( o_il1_stall ),
//
   .i_maintenance_active ( maintenance_active ),
   .i_fill_adr           ( i_mni_fill_adr ),
   .i_fill_start         ( fill_start ),
   .i_B_flag             ( tag_flags[2] ),
   .i_hit                ( il1_hit ),
   .i_retry              ( il1_retry ),
   .i_miss               ( il1_miss ),
   .i_way                ( hit_way ),
   .i_old_tag            ( tag_old_tag ),
   .i_start              ( il1_start ),
   .i_end                ( il1_end ),
   .i_wb_ack             ( il1_wb_ack ) ,
   .i_direct             ( fill_direct ),
   .i_fill_broadcast     ( fill_broadcast ),
   .i_write_broadcast    ( write_broadcast ),
   .i_miss_ack           ( il1_miss_ack ),
   .i_wb_ack_broadcast   ( 1'b0 ),
   .i_wb_ack_adr         ( 32'b0 ),
   .i_sctl_resp_valid    ( sctl_resp_valid_q ),
   .o_l2c_replace_fault  ( ),
   .o_old_tag            ( il1_old_tag ),
   .o_read_hit           (),
   .o_write_hit          (),
   .o_wb_req             ( il1_wb_req ),
   .o_sram_acc           ( il1_sram_acc ),
   .o_sram_adr           ( il1_sram_adr ),
   .o_tag_req            ( il1_tag_req ),
   .o_miss               ( il1_miss_req),
   .o_l2c_replace_data   ( ));
//
// l2c_miss
//
l2c_miss il2c_miss(
   .Clk               ( clk_mc ),
   .Reset             ( rst_mc ),
//
   .i_ctl_en          ( i_ctl_en ),
   .i_dl1_miss_req    ( dl1_miss_req ),
   .i_dl1_wen         ( i_dl1_wen ),
   .i_dl1_miss_adr    ( i_dl1_adr ),
   .i_dl1_miss_flags  ( i_dl1_flags ),
   .o_dl1_miss_ack    ( dl1_miss_ack ),
//
   .i_il1_miss_req    ( il1_miss_req ),
   .i_il1_miss_adr    ( i_il1_adr ),
   .i_il1_miss_flags  ( {i_il1_flags,1'b0} ),
   .o_il1_miss_ack    ( il1_miss_ack ),
//
   .i_mni_miss_stall  ( i_mni_miss_stall ),
   .o_mni_miss_adr    ( o_mni_miss_adr ),
   .o_mni_miss_flags  ( o_mni_miss_flags ),
   .o_mni_miss_valid  ( o_mni_miss_valid ),
   .o_mni_miss_wen    ( o_mni_miss_wen ),
   .o_dl2_sel         ( dl2_sel ));
//
wire        fill_success , fill_fail;
wire [31:0] fill_adr;
wire [ 2:0] fill_set_way;
//
// Fill
//
l2c_fill il2c_fill(
   .Clk                   ( clk_mc ),
   .Reset                 ( rst_mc ),
//
   .i_mni_fill_valid      ( i_mni_fill_valid ),
   .i_mni_fill_len        ( i_mni_fill_len ),
   .i_mni_fill_adr        ( i_mni_fill_adr ),
//
   .i_fill_success        ( fill_success ),
   .i_fill_fail           ( fill_fail ),
   .i_way                 ( hit_way ),
   .o_fill_check_req      ( fill_check_req ),
   .o_fill_set_req        ( fill_set_req ),
   .o_fill_adr            ( fill_adr ),
   .o_fill_set_way        ( fill_set_way ),
//
   .i_wb_ack_broadcast    ( wb_ack_broadcast ),
//
   .i_fill_start          ( fill_start ),
   .i_fill_end            ( fill_end ),
   .o_sram_adr            ( fill_sram_adr ),
//
   .o_mni_fill_stall      ( o_mni_fill_stall ),
//
   .o_fill_direct         ( fill_direct ),
   .o_fill_broadcast      ( fill_broadcast ));
//
// Maintenance
// 
wire [16:0] maintenance_old_tag;
wire [ 8:0] maintenance_index;
wire [ 2:0] maintenance_way;
wire        maintenance_clear_ack;
wire        maintenance_flush_dirty;
wire        maintenance_flush_clean;
wire        Read_idle;
wire        Write_idle;
wire        fsm_idle = dl1_idle & il1_idle & Read_idle & Write_idle;
//
l2c_maintenance il2c_maintenance(
   .Clk                       ( clk_mc ),
   .Reset                     ( rst_mc ),
//
   .i_ctl_clear_req           ( i_ctl_clear_req ),
   .i_ctl_flush_req           ( i_ctl_flush_req ),
   .o_ctl_maint_ack           ( o_ctl_maint_ack ),
   .i_idle                    ( fsm_idle ),
   .i_maintenance_clear_ack   ( maintenance_clear_ack ),
   .i_maintenance_flush_dirty ( maintenance_flush_dirty ),
   .i_maintenance_flush_clean ( maintenance_flush_clean ),
   .i_maintenance_hit_way     ( hit_way ),
   .i_wb_ack_broadcast        ( wb_ack_broadcast ),
   .i_wb_ack_adr              ( i_mni_wb_ack_adr ),
   .i_old_tag                 ( tag_old_tag ),
//
   .o_writeback_req           ( maintenance_wb_req ),
   .i_writeback_ack           ( maintenance_wb_ack ),
   .o_maintenance             ( maintenance_active ),
   .o_maintenance_clear       ( maintenance_clear ),
   .o_maintenance_req         ( maintenance_req ),
   .o_old_tag                 ( maintenance_old_tag ),
   .o_index                   ( maintenance_index ),
   .o_way                     ( maintenance_way) 
);
//
// l2c_writeback
//
wire write_writeback_req;

l2c_writeback il2c_writeback(
   .Clk               ( clk_mc ),
   .Reset             ( rst_mc ),
//
   .i_mni_wb_space    ( i_mni_wb_space ),
//
   .i_dl1_sram_adr    ( dl1_sram_adr ),
   .i_dl1_old_tag     ( dl1_old_tag ),
   .i_dl1_req         ( dl1_wb_req ),
//
   .i_il1_sram_adr    ( il1_sram_adr ),
   .i_il1_old_tag     ( il1_old_tag ),
   .i_il1_req         ( il1_wb_req ),
//
   .i_write_sram_adr  ( write_sram_adr ),       // ???
   .i_write_old_tag   ( write_old_tag ),        // ???
   .i_write_req       ( write_writeback_req ),  // ???
//
   .i_maint_old_tag   ( maintenance_old_tag ),
   .i_maint_sram_adr  ( {maintenance_index, maintenance_way, 6'b0} ),
   .i_maint_req       ( maintenance_wb_req ),
   .o_maint_ack       ( maintenance_wb_ack ),
//
   .o_tag_sram_req    ( writeback_tag_req ),
   .o_tag_sram_combo  ( writeback_tag_combo ),
   .i_tag_ack         ( writeback_tag_ack ),
//
   .i_start           ( writeback_start ),
   .i_end             ( writeback_end) ,
   .o_writeback_adr   ( o_mni_wb_adr ),
   .o_sram_adr        ( writeback_sram_adr ),
   .o_mni_wb_valid    ( o_mni_wb_valid ),
   .o_il1_ack         ( il1_wb_ack  ) ,
   .o_dl1_ack         ( dl1_wb_ack  ) ,
   .o_write_ack       ( writeback_write_ack )
);
//
// l2c_wback
//
l2c_wb_ack il2c_wb_ack(
   .Clk                ( clk_mc ),
   .Reset              ( rst_mc ),
//
   .i_mni_wb_ack_valid ( i_mni_wb_ack_valid ),
   .i_tag_ack          ( wb_ack_ack ),
   .o_tag_req          ( wb_ack_req ),
   .o_mni_wb_ack_stall ( o_mni_wb_ack_stall ),
   .o_broadcast        ( wb_ack_broadcast ));
//
// l2c_read
//
l2c_read il2c_read(
     .Clk                  ( clk_mc ),
     .Reset                ( rst_mc ),
  //
     .i_maintenance_active ( maintenance_active ),
     .i_mni_read_adr       ( i_mni_read_adr ),
     .i_mni_read_valid     ( i_mni_read_valid ),
     .i_hit                ( read_hit ),
     .i_miss               ( read_miss ),
     .i_retry              ( read_retry ),
     .i_wb_ack_broadcast   ( wb_ack_broadcast ),
     .i_fill_broadcast     ( fill_broadcast ),
     .i_write_broadcast    ( write_broadcast ),
     .i_way                ( hit_way ),
     .i_start              ( read_start ),
     .i_end                ( read_end ),
     .o_read_idle          ( Read_idle ),
     .o_tag_req            ( read_tag_req ),
     .o_sram_adr           ( read_sram_adr ),
     .o_mni_read_stall     ( o_mni_read_stall ),
     .o_mni_read_nack      ( o_mni_read_nack ));
//
// l2c_write
//
l2c_write il2c_write(
   .Clk                  ( clk_mc ),
   .Reset                ( rst_mc ),
//
   .i_maintenance_active ( maintenance_active ),
   .i_mni_write_adr      ( i_mni_write_adr ),
   .i_mni_write_valid    ( i_mni_write_valid ),
   .i_mni_write_dirty    ( i_mni_write_dirty ),
   .o_mni_write_stall    ( o_mni_write_stall ),
   .o_mni_write_done     ( o_mni_write_done ),
   .o_mni_write_nack     ( o_mni_write_nack ),
//
   .i_B_flag             ( tag_flags[2] ),
   .i_hit                ( write_hit ),
   .i_retry              ( write_retry ),
   .i_miss               ( write_miss ),
   .i_way                ( hit_way ),
   .i_old_tag            ( tag_old_tag ),
//
   .i_start              ( write_sram_start ),
   .i_end                ( write_sram_end ),
//
   .i_wback_broadcast    ( wb_ack_broadcast ),
   .i_fill_broadcast     ( fill_broadcast ),
//
   .i_writeback_ack      ( writeback_write_ack ),
//
   .o_write_idle         ( Write_idle ),
   .o_write_tag_check    ( write_tag_check ),
   .o_write_tag_req      ( write_tag_req ),
   .o_write_adr          ( write_adr ),
   .o_write_dirty        ( write_dirty ),
   .o_writeback_req      ( write_writeback_req ),
   .o_write_sram_adr     ( write_sram_adr ),
   .o_old_tag            ( write_old_tag ),
//
   .o_il1_inv_adr        ( o_il1_inv_adr),
   .o_il1_inv_req        ( o_il1_inv_req ),
   .i_il1_inv_ack        ( i_il1_inv_ack ),
   .o_dl1_inv_adr        ( o_dl1_inv_adr ),
   .o_dl1_inv_req        ( o_dl1_inv_req ),
   .i_dl1_inv_ack        ( i_dl1_inv_ack ),
   .o_broadcast          ( write_broadcast ));
//
// TAG
//

l2c_tag il2c_tag(
   .Clk                       ( clk_mc ),
   .Reset                     ( rst_mc ),
//
   .i_lru_mode                ( i_lru_mode ),
   .i_ctl_epoch               ( i_ctl_epoch ),
   .i_ctl_min_cpu_ways        ( i_ctl_min_cpu_ways ),
//
   .i_fill_adr                ( fill_adr ),
   .i_fill_set_way            ( fill_set_way ),
   .i_fill_check_req          ( fill_check_req ),
   .i_fill_set_req            ( fill_set_req ),
   .o_fill_success            ( fill_success ),
   .o_fill_fail               ( fill_fail ),
//
   .i_wb_ack_adr              ( i_mni_wb_ack_adr ),
   .i_wb_ack_req              ( wb_ack_req ),
   .o_wb_ack_ack              ( wb_ack_ack ),
//
   .i_dl1_adr                 ( i_dl1_adr ),
   .i_dl1_wen                 ( i_dl1_wen ),
   .i_dl1_req                 ( dl1_tag_req ),
   .o_dl1_hit                 ( dl1_hit ),
   .o_dl1_retry               ( dl1_retry ),
   .o_dl1_miss                ( dl1_miss ),
//
   .i_il1_adr                 ( i_il1_adr ),
   .i_il1_req                 ( il1_tag_req ),
   .o_il1_hit                 ( il1_hit ),
   .o_il1_retry               ( il1_retry ),
   .o_il1_miss                ( il1_miss ),
//
   .i_write_adr               ( write_adr ),
   .i_write_dirty             ( write_dirty ),
   .i_write_check             ( write_tag_check ), // ???
   .i_write_req               ( write_tag_req ),   // ???
   .o_write_success           ( write_hit ),
   .o_write_retry             ( write_retry ),
   .o_write_fail              ( write_miss ),
//
   .i_read_adr                ( i_mni_read_adr ),
   .i_read_ignore_dirty       ( i_mni_read_ignore ),
   .i_read_req                ( read_tag_req ),
   .o_read_success            ( read_hit ),
   .o_read_fail               ( read_miss ),
   .o_read_retry              ( read_retry ),
//
   .i_writeback_req           ( writeback_tag_req ),
   .i_writeback_combo         ( writeback_tag_combo ),
   .o_writeback_ack           ( writeback_tag_ack ),
//
   .o_sram_arb                ( tag_sram_arb ),
   .o_sram_valid              ( tag_sram_valid ),
   .i_sram_stall              ( tag_sram_stall ),
//
   .i_maintenance_adr         ( {17'b0, maintenance_index, 6'b0} ),
   .i_maintenance_clear       ( maintenance_clear ),
   .i_maintenance_req         ( maintenance_req ),
   .o_maintenance_clear_ack   ( maintenance_clear_ack ),
   .o_maintenance_flush_dirty ( maintenance_flush_dirty ),
   .o_maintenance_flush_clean ( maintenance_flush_clean ),
//
   .o_hit_way                 ( hit_way ),
   .o_old_tag                 ( tag_old_tag ),
   .o_tag_flags               ( tag_flags ));
//
// SRAM IF
//
l2c_sram il2c_sram(
     .Clk               ( clk_mc ),
     .Reset             ( rst_mc ),
  //
     .i_tag_arb         ( tag_sram_arb ),
     .i_tag_valid       ( tag_sram_valid ),
     .o_tag_stall       ( tag_sram_stall ),
  //
     .i_fill_adr        ( fill_sram_adr ),
     .o_fill_start      ( fill_start ),
     .o_fill_end        ( fill_end ),
  //
     .i_dl1_adr         ( dl1_sram_adr ),
     .i_dl1_be          ( i_dl1_ben ),
     .i_dl1_read_hit    ( dl1_read_hit ),
     .i_dl1_write_hit   ( dl1_write_hit ),
     .o_dl1_start       ( dl1_start ),
     .o_dl1_end         ( dl1_end ),
  //
     .i_il1_adr         ( il1_sram_adr ),
     .o_il1_start       ( il1_start ),
     .o_il1_end         ( il1_end ),
  //
     .i_writeback_adr   ( writeback_sram_adr ),
     .o_writeback_start ( writeback_start ),
     .o_writeback_end   ( writeback_end ),
  //
     .i_write_adr       ( write_sram_adr ),    // ???
     .o_write_start     ( write_sram_start ),
     .o_write_end       ( write_sram_end ),
  //
     .i_read_adr        ( read_sram_adr ),
     .o_read_start      ( read_start ),
     .o_read_end        ( read_end ),
  // SRAM Interface
     .o_sctl_req_adr    ( o_sctl_req_adr ),
     .o_sctl_req_we     ( o_sctl_req_we ),
     .o_sctl_req_be     ( o_sctl_req_be ),
     .o_sctl_req_valid  ( o_sctl_req_valid ),
     .i_sctl_resp_valid ( sctl_resp_valid_q ),
     .o_dl1_wr_dt_sel   ( dl1_wr_dt_sel));
//
 always @(posedge clk_mc) begin
    o_sctl_req_wdata <= #`dh dl1_wr_dt_sel ? i_dl1_wdata : 
                   {(dl1_replace_data & i_dl1_ben[3]) ? i_dl1_wdata[31:24] : i_mni_data[31:24],
                    (dl1_replace_data & i_dl1_ben[2]) ? i_dl1_wdata[23:16] : i_mni_data[23:16],
                    (dl1_replace_data & i_dl1_ben[1]) ? i_dl1_wdata[15:8]  : i_mni_data[15:8],
                    (dl1_replace_data & i_dl1_ben[0]) ? i_dl1_wdata[7:0]   : i_mni_data[7:0]};
//
    o_mni_miss_wdata <= #`dh i_dl1_wdata;
    o_mni_miss_ben   <= #`dh i_dl1_ben;
    o_dl1_rdata      <= #`dh dl1_sram_acc ? sctl_resp_rdata_q : i_mni_data; //
    o_il1_rdata      <= #`dh il1_sram_acc ? sctl_resp_rdata_q : i_mni_data; //
    o_mni_data       <= #`dh sctl_resp_rdata_q;
 end
//
 assign o_dl1_tlb_fault = (i_mni_fill_fault & dl2_sel) | (i_mni_wb_ack_fault & dl1_replace_fault);
 assign o_il1_tlb_fault = i_mni_fill_fault &~dl2_sel;
//
endmodule
