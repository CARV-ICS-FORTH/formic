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
// Abstract      : MBS Network Interface (MNI) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni.v,v $
// CVS revision  : $Revision: 1.58 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module mni (

  // Clocks and resets
  input             clk_mc,
  input             rst_mc,
  input             clk_ni,
  input             rst_ni,

  // Static configuration
  input      [ 7:0] i_board_id,
  input      [ 3:0] i_node_id,
  input      [11:0] i_ctl_addr_base,

  // CTL Registers Interface (clk_ni)
  output     [19:0] o_ctl_reg_adr,
  output            o_ctl_reg_valid,
  output            o_ctl_reg_wen,
  output            o_ctl_reg_from_cpu,
  output     [ 1:0] o_ctl_reg_ben,
  output     [15:0] o_ctl_reg_wdata,
  output     [ 2:0] o_ctl_reg_rlen,
  input             i_ctl_reg_stall,
  input      [15:0] i_ctl_reg_resp_rdata,
  input             i_ctl_reg_resp_valid,
  input             i_ctl_reg_block,
  input             i_ctl_reg_unblock,

  // CTL Operation Interface (clk_ni)
  input             i_ctl_op_valid,
  input      [15:0] i_ctl_op_data,
  output            o_ctl_op_stall,

  // CTL operation FIFO levels
  output     [ 5:0] o_ctl_cpu_fifo_ops,
  output     [ 5:0] o_ctl_net_fifo_ops,

  // CTL Trace Interface (clk_ni)
  output            o_ctl_trace_op_local,
  output            o_ctl_trace_op_remote,
  output            o_ctl_trace_read_hit,
  output            o_ctl_trace_read_miss,
  output            o_ctl_trace_write_hit,
  output            o_ctl_trace_write_miss,
  output            o_ctl_trace_vc0_in,
  output            o_ctl_trace_vc0_out,
  output            o_ctl_trace_vc1_in,
  output            o_ctl_trace_vc1_out,
  output            o_ctl_trace_vc2_in,
  output            o_ctl_trace_vc2_out,

  // CMX interface  (clk_ni)
  input             i_cmx_valid,
  input      [15:0] i_cmx_data,
  output            o_cmx_stall,
  input      [11:0] i_cmx_mbox_space,
  input             i_cmx_mslot_space,

  // L2C Writeback Interface (clk_mc)
  output            o_l2c_wb_space,
  input             i_l2c_wb_valid,
  input      [31:0] i_l2c_wb_adr,

  // L2C Writeback Acknowledge Interface (clk_mc)
  output            o_l2c_wb_ack_valid,
  output            o_l2c_wb_ack_fault,
  output     [31:0] o_l2c_wb_ack_adr,
  input             i_l2c_wb_ack_stall,

  // L2C Miss Interface (clk_mc)
  input             i_l2c_miss_valid,
  input      [31:0] i_l2c_miss_adr,
  input      [ 1:0] i_l2c_miss_flags,
  input             i_l2c_miss_wen,
  input      [ 3:0] i_l2c_miss_ben,
  input      [31:0] i_l2c_miss_wdata,
  output            o_l2c_miss_stall,

  // L2C Fill Interface (clk_mc)
  output            o_l2c_fill_valid,
  output            o_l2c_fill_fault,
  output     [ 3:0] o_l2c_fill_len,
  output     [31:0] o_l2c_fill_adr,
  input             i_l2c_fill_stall,

  // L2C Write Interface (clk_mc)
  output            o_l2c_write_valid,
  output     [31:0] o_l2c_write_adr,
  output            o_l2c_write_dirty,
  input             i_l2c_write_stall,
  input             i_l2c_write_nack,
  input             i_l2c_write_done,

  // L2C Read Interface (clk_mc)
  output            o_l2c_read_valid,
  output     [31:0] o_l2c_read_adr,
  output            o_l2c_read_ignore,
  input             i_l2c_read_stall,
  input             i_l2c_read_nack,

  // L2C Common Data Busses (clk_mc)
  output     [31:0] o_l2c_data,
  input      [31:0] i_l2c_data,

  // Network Out Interface (clk_ni)
  output     [ 2:0] o_nout_enq,
  output     [ 5:0] o_nout_offset,
  output            o_nout_eop,
  output     [15:0] o_nout_data,
  input      [ 2:0] i_nout_full,
  input      [ 2:0] i_nout_packets_vc0,
  input      [ 2:0] i_nout_packets_vc1,
  input      [ 2:0] i_nout_packets_vc2,

  // Network In Interface (clk_ni)
  output     [ 2:0] o_nin_deq,
  output     [ 5:0] o_nin_offset,
  output            o_nin_eop,
  input      [15:0] i_nin_data,
  input      [ 2:0] i_nin_empty,
  input      [ 2:0] i_nin_packets_vc0,
  input      [ 2:0] i_nin_packets_vc1,
  input      [ 2:0] i_nin_packets_vc2
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  wire        ack_regif_valid;
  wire        ack_regif_stall;
  wire [15:0] ack_regif_data;

  wire        ack_out_valid;
  wire        ack_out_stall;
  wire [15:0] ack_out_data;

  wire [15:0] cpuop_fifo_rd_data;
  wire  [3:0] cpuop_fifo_rd_offset;
  wire        cpuop_fifo_rd_eop;
  wire        cpuop_fifo_empty;

  wire [15:0] netop_fifo_rd_data;
  wire  [3:0] netop_fifo_rd_offset;
  wire        netop_fifo_rd_eop;
  wire        netop_fifo_empty;
  wire [15:0] netop_fifo_wr_data;
  wire        netop_fifo_wr_en;
  wire        netop_fifo_full;

  wire  [1:0] dma_out_req;
  wire        dma_out_ack;
  wire  [5:0] dma_out_offset;
  wire  [2:0] dma_out_enq;
  wire [15:0] dma_out_data;
  wire        dma_out_eop;

  wire        in_ack_valid;
  wire        in_ack_stall;
  wire [15:0] in_ack_data;

  wire        in_regif_valid;
  wire        in_regif_stall;
  wire [15:0] in_regif_data;
  wire        in_regif_resp_valid;
  wire [15:0] in_regif_resp_data;

  wire        in_out_valid;
  wire        in_out_stall;
  wire [15:0] in_out_data;

  wire        in_wrfill_busy;
  wire        in_wrfill_valid;
  wire [15:0] in_wrfill_data;

  wire        miss_regif_valid;
  wire        miss_regif_stall;
  wire [15:0] miss_regif_data;
  wire        miss_regif_wr_accept;
  wire        miss_regif_resp_valid;
  wire [15:0] miss_regif_resp_data;

  wire        miss_out_valid;
  wire        miss_out_stall;
  wire [15:0] miss_out_data;

  wire [15:0] read_fifo_rd_data;
  wire        read_fifo_rd_en;
  wire [15:0] read_fifo_wr_data;
  wire        read_fifo_wr_en;

  wire        miss_wrfill_valid;
  wire        miss_wrfill_stall;
  wire [15:0] miss_wrfill_data;

  wire [15:0] wb_fifo_rd_data;
  wire        wb_fifo_rd_en;
  wire [15:0] wb_fifo_wr_data;
  wire        wb_fifo_wr_en;

  wire        wb_out_valid;
  wire        wb_out_stall;
  wire [15:0] wb_out_data;

  wire        wrfill_dmem_wr_en;
  wire  [5:0] wrfill_dmem_wr_adr;
  wire [15:0] wrfill_dmem_wr_data;
  wire  [5:0] wrfill_dmem_rd_adr;
  wire [15:0] wrfill_dmem_rd_data;

  wire        wrfill_ack_valid;
  wire        wrfill_ack_stall;
  wire [15:0] wrfill_ack_data;

  wire        wrfill_out_valid;
  wire        wrfill_out_stall;
  wire [15:0] wrfill_out_data;


  // ==========================================================================
  // mni_in
  // ==========================================================================
  mni_in i0_mni_in (
    
    // Clock and reset
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),

    // Static configuration
    .i_ctl_addr_base        ( i_ctl_addr_base ),

    // Network In Interface
    .o_nin_deq              ( o_nin_deq ),
    .o_nin_offset           ( o_nin_offset ),
    .o_nin_eop              ( o_nin_eop ),
    .i_nin_data             ( i_nin_data ),
    .i_nin_empty            ( i_nin_empty ),

    // Network Out XBI levels
    .i_nout_packets_vc0     ( i_nout_packets_vc0 ),
    .i_nout_packets_vc1     ( i_nout_packets_vc1 ),

    // Mailbox level
    .i_cmx_mbox_space       ( i_cmx_mbox_space ),
    .i_cmx_mslot_space      ( i_cmx_mslot_space ),

    // L2C Writeback Acknowledge Interface (clk_mc)
    .o_l2c_wb_ack_valid     ( o_l2c_wb_ack_valid ),
    .o_l2c_wb_ack_fault     ( o_l2c_wb_ack_fault ),
    .o_l2c_wb_ack_adr       ( o_l2c_wb_ack_adr ),
    .i_l2c_wb_ack_stall     ( i_l2c_wb_ack_stall ),

    // wrfill interface: If busy, in packet is not eligible. Otherwise:
    //                   valid:     write enable for data below
    //                   word 0:    opcode/size
    //                   Word 1:    wr/fill adr HIGH
    //                   word 2:    wr/fill adr LOW
    //                   wrds 3-34: wr/fill data  (or 3-4, when size=2)
    //                   word 35:   ack BRD       (or 5, when size=2)
    //                   word 36:   ack adr HIGH  (or 6, when size=2)
    //                   word 37:   ack adr LOW   (or 7, when size=2)
    .i_wrfill_busy          ( in_wrfill_busy ),
    .o_wrfill_valid         ( in_wrfill_valid ),
    .o_wrfill_data          ( in_wrfill_data ),

    // regif interface: word 0: reg adr HIGH[19:16] | bit 4: 1 = write
    //                                                bits 5-8: byte enables
    //                                                bits 9-14: length (16b)
    //                  word 1: reg adr LOW
    //                  words 2-33: write data (if applicable)
    //
    //                  Writes can be any length up to a cache line.
    //                  Reads are 2 words. Response is given back on resp_*
    .o_regif_valid          ( in_regif_valid ),
    .i_regif_stall          ( in_regif_stall ),
    .o_regif_data           ( in_regif_data ),
    .i_regif_resp_valid     ( in_regif_resp_valid ),
    .i_regif_resp_data      ( in_regif_resp_data ),

    // netop_fifo interface
    .o_netop_fifo_wr_data   ( netop_fifo_wr_data ),
    .o_netop_fifo_wr_en     ( netop_fifo_wr_en ),
    .i_netop_fifo_full      ( netop_fifo_full ),

    // ack interface: word 0:   ack BRD
    //                word 1:   ack adr HIGH
    //                word 2:   ack adr LOW
    //                word 3:   payload LOW
    .o_ack_valid            ( in_ack_valid ),
    .i_ack_stall            ( in_ack_stall ),
    .o_ack_data             ( in_ack_data ),

    // out interface: word 0: bit 0: 1 if it has ack adr
    //                        bit 4: 1'b1
    //                        bits 5-8: 4'b1111
    //                        bits 9-14: 6'd2
    //                word 1: dst BRD / byte enables
    //                word 2: dst adr HIGH
    //                word 3: dst adr LOW
    //                word 4: ack adr BRD  (if applicable)
    //                word 5: ack adr HIGH  (if applicable)
    //                word 6: ack adr LOW  (if applicable)
    //                words 7-8: write data (or 4-5, if no ack)
    .o_out_valid            ( in_out_valid ),
    .i_out_stall            ( in_out_stall ),
    .o_out_data             ( in_out_data )
  );


  // ==========================================================================
  // mni_out
  // ==========================================================================
  mni_out i0_mni_out (
    
    // Clock and reset
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),
    
    // Static configuration
    .i_board_id             ( i_board_id ),
    .i_node_id              ( i_node_id ),

    // Network Out Interface
    .o_nout_enq             ( o_nout_enq ),
    .o_nout_offset          ( o_nout_offset ),
    .o_nout_eop             ( o_nout_eop ),
    .o_nout_data            ( o_nout_data ),
    .i_nout_full            ( i_nout_full ),

    // dma interface (special: gets permission to top-level MNI out,
    //                creates its own packets to VCs 1 or 2)
    .i_dma_req              ( dma_out_req ),
    .o_dma_ack              ( dma_out_ack ),
    .i_dma_offset           ( dma_out_offset ),
    .i_dma_enq              ( dma_out_enq ),
    .i_dma_data             ( dma_out_data ),
    .i_dma_eop              ( dma_out_eop ),

    // miss interface (two cases, depending on word 0:
    //                 VC 2, from node C, 2 words or 1 cache line size, no ack
    //                 VC 1, to node C,   2 words size, ack (adr = same))
    .i_miss_valid           ( miss_out_valid ),
    .o_miss_stall           ( miss_out_stall ),
    .i_miss_data            ( miss_out_data ),

    // wrfill interface (VC 1, to node C, cache line size, maybe with ack)
    .i_wrfill_valid         ( wrfill_out_valid ),
    .o_wrfill_stall         ( wrfill_out_stall ),
    .i_wrfill_data          ( wrfill_out_data ),

    // wb interface (VC 1, to node C, cache line size, with ack)
    .i_wb_valid             ( wb_out_valid ),
    .o_wb_stall             ( wb_out_stall ),
    .i_wb_data              ( wb_out_data ),

    // in interface (VC 1, to anywhere, 2 words size (response to reg read),
    //               maybe with ack)
    .i_in_valid             ( in_out_valid ),
    .o_in_stall             ( in_out_stall ),
    .i_in_data              ( in_out_data ),

    // ack interface (VC 0, to anywhere, 2 words size, no further ack)
    .i_ack_valid            ( ack_out_valid ),
    .o_ack_stall            ( ack_out_stall ),
    .i_ack_data             ( ack_out_data )
  );

  
  // ==========================================================================
  // mni_wrfill
  // ==========================================================================
  mni_wrfill i0_mni_wrfill (
    
    // Clocks and resets
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),

    // L2C Write Interface (clk_mc)
    .o_l2c_write_valid      ( o_l2c_write_valid ),
    .o_l2c_write_adr        ( o_l2c_write_adr ),
    .o_l2c_write_dirty      ( o_l2c_write_dirty ),
    .i_l2c_write_stall      ( i_l2c_write_stall ),
    .i_l2c_write_nack       ( i_l2c_write_nack ),
    .i_l2c_write_done       ( i_l2c_write_done ),

    // L2C Fill Interface (clk_mc)
    .o_l2c_fill_valid       ( o_l2c_fill_valid ),
    .o_l2c_fill_fault       ( o_l2c_fill_fault ),
    .o_l2c_fill_len         ( o_l2c_fill_len ),
    .o_l2c_fill_adr         ( o_l2c_fill_adr ),
    .i_l2c_fill_stall       ( i_l2c_fill_stall ),

    // L2C Common Data Busses (clk_mc)
    .o_l2c_data             ( o_l2c_data ),

    // Write/Fill FIFO interface
    .o_dmem_wr_data         ( wrfill_dmem_wr_data ),
    .o_dmem_wr_adr          ( wrfill_dmem_wr_adr ),
    .o_dmem_wr_en           ( wrfill_dmem_wr_en ),
    .o_dmem_rd_adr          ( wrfill_dmem_rd_adr ),
    .i_dmem_rd_data         ( wrfill_dmem_rd_data ),

    // in interface
    .o_in_busy              ( in_wrfill_busy ),
    .i_in_valid             ( in_wrfill_valid ),
    .i_in_data              ( in_wrfill_data ),

    // miss interface (always 2 words data, fill) 
    .i_miss_valid          ( miss_wrfill_valid ),
    .o_miss_stall          ( miss_wrfill_stall ),
    .i_miss_data           ( miss_wrfill_data ),

    // ack interface: word 0:   ack BRD
    //                word 1:   ack adr HIGH
    //                word 2:   ack adr LOW
    .o_ack_valid            ( wrfill_ack_valid ),
    .i_ack_stall            ( wrfill_ack_stall ),
    .o_ack_data             ( wrfill_ack_data ),
    
    // out interface: word 0:       bit 1: 1 = has ack
    //                word 1:       dst adr HIGH
    //                word 2:       dst adr LOW
    //                word 3:       ack BRD
    //                word 4:       ack adr HIGH
    //                word 5:       ack adr LOW
    //                words 3-34 (if no ack): cache line
    //                words 6-36 (if ack):    cache line
    .o_out_valid            ( wrfill_out_valid ),
    .i_out_stall            ( wrfill_out_stall ),
    .o_out_data             ( wrfill_out_data )
  );


  // ==========================================================================
  // mni_miss
  // ==========================================================================
  mni_miss i0_mni_miss (
    
    // Clocks and resets
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),

    // L2C Miss Interface (clk_mc)
    .i_l2c_miss_valid       ( i_l2c_miss_valid ),
    .i_l2c_miss_adr         ( i_l2c_miss_adr ),
    .i_l2c_miss_flags       ( i_l2c_miss_flags ),
    .i_l2c_miss_wen         ( i_l2c_miss_wen ),
    .i_l2c_miss_ben         ( i_l2c_miss_ben ),
    .i_l2c_miss_wdata       ( i_l2c_miss_wdata ),
    .o_l2c_miss_stall       ( o_l2c_miss_stall ),

    // regif interface: word 0: reg adr HIGH[19:16] | bit 4: 1 = write
    //                                                bits 5-8: byte enables
    //                                                bits 9-14: 6'd2
    //                  word 1: reg adr LOW
    //                  words 2-3: write data (if applicable)
    //
    //                  Writes are 2 words.
    //                  Reads are 2 words. Response is given back on resp_*
    .o_regif_valid          ( miss_regif_valid ),
    .i_regif_stall          ( miss_regif_stall ),
    .o_regif_data           ( miss_regif_data ),
    .i_regif_wr_accept      ( miss_regif_wr_accept ),
    .i_regif_resp_valid     ( miss_regif_resp_valid ),
    .i_regif_resp_data      ( miss_regif_resp_data ),

    // wrfill interface: word 0:    fill adr HIGH
    //                   word 1:    fill adr LOW
    //                   wrds 2-3:  fill data
    .o_wrfill_valid         ( miss_wrfill_valid ),
    .i_wrfill_stall         ( miss_wrfill_stall ),
    .o_wrfill_data          ( miss_wrfill_data ),

    // out interface: word 0: bit 4: 1 = write, 0 = read
    //                        bits 5-8: byte enables (for write)
    //                        bits 9-14: size in 16b words (can be 2 or 32)
    //                word 1: miss adr HIGH
    //                word 2: miss adr LOW
    //                word 3: miss adr HIGH (repetition, used as ack/src adr)
    //                word 4: miss adr LOW (repetition, used as ack/src adr)
    //                words 5-6: write data (if uncacheable write)
    .o_out_valid            ( miss_out_valid ),
    .i_out_stall            ( miss_out_stall ),
    .o_out_data             ( miss_out_data )
  );


  // ==========================================================================
  // mni_wb
  // ==========================================================================
  mni_wb i0_mni_wb (
    
    // Clocks and resets
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),

    // L2C Writeback Interface (clk_mc)
    .o_l2c_wb_space         ( o_l2c_wb_space ),
    .i_l2c_wb_valid         ( i_l2c_wb_valid ),
    .i_l2c_wb_adr           ( i_l2c_wb_adr ),
    .i_l2c_data             ( i_l2c_data ),

    // Writeback FIFO interface
    .o_fifo_wr_data         ( wb_fifo_wr_data ),
    .o_fifo_wr_en           ( wb_fifo_wr_en ),
    .i_fifo_rd_data         ( wb_fifo_rd_data ),
    .o_fifo_rd_en           ( wb_fifo_rd_en ),

    // out interface: word 0:       dst adr HIGH
    //                word 1:       dst adr LOW
    //                word 2:       ack adr HIGH (=dst adr)
    //                word 3:       ack adr LOW (=dst adr)
    //                words 2-33:   cache line
    .o_out_valid            ( wb_out_valid ),
    .i_out_stall            ( wb_out_stall ),
    .o_out_data             ( wb_out_data )
  );


  // ==========================================================================
  // mni_regif
  // ==========================================================================
  mni_regif i0_mni_regif (
    
    // Clock and reset
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),

    // CTL Registers Interface (clk_ni)
    .o_ctl_reg_adr          ( o_ctl_reg_adr ),
    .o_ctl_reg_valid        ( o_ctl_reg_valid ),
    .o_ctl_reg_wen          ( o_ctl_reg_wen ),
    .o_ctl_reg_from_cpu     ( o_ctl_reg_from_cpu ),
    .o_ctl_reg_ben          ( o_ctl_reg_ben ),
    .o_ctl_reg_wdata        ( o_ctl_reg_wdata ),
    .o_ctl_reg_rlen         ( o_ctl_reg_rlen ),
    .i_ctl_reg_stall        ( i_ctl_reg_stall ),
    .i_ctl_reg_resp_rdata   ( i_ctl_reg_resp_rdata ),
    .i_ctl_reg_resp_valid   ( i_ctl_reg_resp_valid ),
    .i_ctl_reg_block        ( i_ctl_reg_block ),
    .i_ctl_reg_unblock      ( i_ctl_reg_unblock ),

    // in interface
    .i_in_valid             ( in_regif_valid ),
    .o_in_stall             ( in_regif_stall ),
    .i_in_data              ( in_regif_data ),
    .o_in_resp_valid        ( in_regif_resp_valid ),
    .o_in_resp_data         ( in_regif_resp_data ),

    // miss interface
    .i_miss_valid           ( miss_regif_valid ),
    .o_miss_stall           ( miss_regif_stall ),
    .i_miss_data            ( miss_regif_data ),
    .o_miss_wr_accept       ( miss_regif_wr_accept ),
    .o_miss_resp_valid      ( miss_regif_resp_valid ),
    .o_miss_resp_data       ( miss_regif_resp_data ),

    // ack interface
    .i_ack_valid            ( ack_regif_valid ),
    .o_ack_stall            ( ack_regif_stall ),
    .i_ack_data             ( ack_regif_data )
  );


  // ==========================================================================
  // mni_dma
  // ==========================================================================
  mni_dma i0_mni_dma (
    
    // Clocks and resets
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),

    // Static configuration
    .i_board_id             ( i_board_id ),
    .i_node_id              ( i_node_id ),

    // L2C Read Interface (clk_mc)
    .o_l2c_read_valid       ( o_l2c_read_valid ),
    .o_l2c_read_adr         ( o_l2c_read_adr ),
    .o_l2c_read_ignore      ( o_l2c_read_ignore ),
    .i_l2c_read_stall       ( i_l2c_read_stall ),
    .i_l2c_read_nack        ( i_l2c_read_nack ),
    .i_l2c_data             ( i_l2c_data ),

    // Network Operation FIFO interface
    .i_netop_fifo_rd_data   ( netop_fifo_rd_data ),
    .o_netop_fifo_rd_offset ( netop_fifo_rd_offset ),
    .o_netop_fifo_rd_eop    ( netop_fifo_rd_eop ),
    .i_netop_fifo_empty     ( netop_fifo_empty ),

    // CTL Operation FIFO interface
    .i_cpuop_fifo_rd_data   ( cpuop_fifo_rd_data ),
    .o_cpuop_fifo_rd_offset ( cpuop_fifo_rd_offset ),
    .o_cpuop_fifo_rd_eop    ( cpuop_fifo_rd_eop ),
    .i_cpuop_fifo_empty     ( cpuop_fifo_empty ),

    // Read FIFO interface
    .o_read_fifo_wr_data    ( read_fifo_wr_data ),
    .o_read_fifo_wr_en      ( read_fifo_wr_en ),
    .i_read_fifo_rd_data    ( read_fifo_rd_data ),
    .o_read_fifo_rd_en      ( read_fifo_rd_en ),

    // out interface: req means "I need the top-level MNI out" 
    //                          (bit 0: for VC 1, bit 1: for VC 2)
    //                ack grants it
    //                DMA engine handles its own top-level MNI outputs
    //                eop terminates the request
    .o_out_req              ( dma_out_req ),
    .i_out_ack              ( dma_out_ack ),
    .o_out_offset           ( dma_out_offset ),
    .o_out_enq              ( dma_out_enq ),
    .o_out_data             ( dma_out_data ),
    .o_out_eop              ( dma_out_eop )
  );


  // ==========================================================================
  // mni_ack
  // ==========================================================================
  mni_ack i0_mni_ack (
    
    // Clock and reset
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),

    // Static configuration
    .i_board_id             ( i_board_id ),
    .i_node_id              ( i_node_id ),
    .i_ctl_addr_base        ( i_ctl_addr_base ),

    // CMX interface (clk_ni) (ack size: given in 4th word)
    .i_cmx_valid            ( i_cmx_valid ),
    .i_cmx_data             ( i_cmx_data ),
    .o_cmx_stall            ( o_cmx_stall ),
    
    // in interface (ack size: given in 4th word)
    .i_in_valid             ( in_ack_valid ),
    .o_in_stall             ( in_ack_stall ),
    .i_in_data              ( in_ack_data ),

    // wrfill interface (ack size: 64 bytes)
    .i_wrfill_valid         ( wrfill_ack_valid ),
    .o_wrfill_stall         ( wrfill_ack_stall ),
    .i_wrfill_data          ( wrfill_ack_data ),

    // regif interface: word 0:     reg adr HIGH[19:16] | bit 4: 1
    //                                                    bits 5-8: 4'b1111
    //                                                    bits 9-14: 6'd2
    //                  word 1:     reg adr LOW
    //                  words 2-3: write data (word 2 = 0, word 3 = ack value)
    //
    //                  Writes are 2 words.
    .o_regif_valid          ( ack_regif_valid ),
    .i_regif_stall          ( ack_regif_stall ),
    .o_regif_data           ( ack_regif_data ),

    // out interface: word 0: dst BRD / byte enables
    //                word 1: dst adr HIGH
    //                word 2: dst adr LOW
    //                word 3: 0
    //                word 4: ack size in bytes
    .o_out_valid            ( ack_out_valid ),
    .i_out_stall            ( ack_out_stall ),
    .o_out_data             ( ack_out_data )
  );

  

  // ==========================================================================
  // Net operation FIFO
  // ==========================================================================
  fifo_align_512x16_rd_offset netop_fifo (

    // Write interface
    .clk_wr                 ( clk_ni ),
    .rst_wr                 ( rst_ni ),
    .i_wr_data              ( netop_fifo_wr_data ),
    .i_wr_en                ( netop_fifo_wr_en ),
    .o_full                 ( netop_fifo_full ),
    .o_wr_packets           ( o_ctl_net_fifo_ops ),

    // Read interface
    .clk_rd                 ( clk_ni ),
    .rst_rd                 ( rst_ni ),
    .o_rd_data              ( netop_fifo_rd_data ),
    .i_rd_offset            ( netop_fifo_rd_offset ),
    .i_rd_eop               ( netop_fifo_rd_eop ),
    .o_empty                ( netop_fifo_empty )
  );


  // ==========================================================================
  // CPU operation FIFO
  // ==========================================================================
  fifo_align_512x16_rd_offset cpuop_fifo (

    // Write interface
    .clk_wr                 ( clk_ni ),
    .rst_wr                 ( rst_ni ),
    .i_wr_data              ( i_ctl_op_data ),
    .i_wr_en                ( i_ctl_op_valid ),
    .o_full                 ( o_ctl_op_stall ),
    .o_wr_packets           ( o_ctl_cpu_fifo_ops ),
  
    // Read interface
    .clk_rd                 ( clk_ni ),
    .rst_rd                 ( rst_ni ),
    .o_rd_data              ( cpuop_fifo_rd_data ),
    .i_rd_offset            ( cpuop_fifo_rd_offset ),
    .i_rd_eop               ( cpuop_fifo_rd_eop ),
    .o_empty                ( cpuop_fifo_empty )
  );

  
  // ==========================================================================
  // Write/Fill distributed memory
  // ==========================================================================
  xil_dmem_tp_64x16 wrfill_dmem (

    // Write interface
    .clk_wr                 ( clk_ni ),
    .i_wr_data              ( wrfill_dmem_wr_data ),
    .i_wr_adr               ( wrfill_dmem_wr_adr ),
    .i_wr_en                ( wrfill_dmem_wr_en ),

    // Read interface
    .i_rd_adr               ( wrfill_dmem_rd_adr ),
    .o_rd_data              ( wrfill_dmem_rd_data )
  );


  // ==========================================================================
  // Writeback FIFO
  // ==========================================================================
  fifo_align_32x16 wb_fifo (

    // Write interface
    .clk_wr                 ( clk_ni ),
    .rst_wr                 ( rst_ni ),
    .i_wr_data              ( wb_fifo_wr_data ),
    .i_wr_en                ( wb_fifo_wr_en ),
    .o_full                 ( ),

    // Read interface
    .clk_rd                 ( clk_ni ),
    .rst_rd                 ( rst_ni ),
    .o_rd_data              ( wb_fifo_rd_data ),
    .i_rd_en                ( wb_fifo_rd_en ),
    .o_empty                ( )
  );


  // ==========================================================================
  // Read FIFO
  // ==========================================================================
  fifo_align_32x16 read_fifo (

    // Write interface
    .clk_wr                 ( clk_ni ),
    .rst_wr                 ( rst_ni ),
    .i_wr_data              ( read_fifo_wr_data ),
    .i_wr_en                ( read_fifo_wr_en ),
    .o_full                 ( ),

    // Read interface
    .clk_rd                 ( clk_ni ),
    .rst_rd                 ( rst_ni ),
    .o_rd_data              ( read_fifo_rd_data ),
    .i_rd_en                ( read_fifo_rd_en ),
    .o_empty                ( )
  );


  // ==========================================================================
  // CTL Trace Interface
  // ==========================================================================
  wire trc_op_local_d;  reg trc_op_local_q;
  wire trc_op_remote_d; reg trc_op_remote_q;
  wire trc_read_hit_d;  reg trc_read_hit_q;
  wire trc_read_miss_d; reg trc_read_miss_q;
  wire trc_write_hit_d; reg trc_write_hit_q;
  wire trc_write_miss_d;reg trc_write_miss_q;
  wire trc_vc0_in_d;    reg trc_vc0_in_q;
  wire trc_vc0_out_d;   reg trc_vc0_out_q;
  wire trc_vc1_in_d;    reg trc_vc1_in_q;
  wire trc_vc1_out_d;   reg trc_vc1_out_q;
  wire trc_vc2_in_d;    reg trc_vc2_in_q;
  wire trc_vc2_out_d;   reg trc_vc2_out_q;
  
  assign trc_op_local_d   = i_ctl_op_valid;
  assign trc_op_remote_d  = netop_fifo_wr_en;
  assign trc_read_hit_d   = o_l2c_read_valid  & ~i_l2c_read_nack & 
                            ~i_l2c_read_stall;
  assign trc_read_miss_d  = o_l2c_read_valid  &  i_l2c_read_nack;
  assign trc_write_hit_d  = o_l2c_write_valid & ~i_l2c_write_nack &
                            ~i_l2c_write_stall;
  assign trc_write_miss_d = o_l2c_write_valid &  i_l2c_write_nack;
  assign trc_vc0_in_d     = o_nin_deq[0]  & o_nin_eop;
  assign trc_vc0_out_d    = o_nout_enq[0] & o_nout_eop;
  assign trc_vc1_in_d     = o_nin_deq[1]  & o_nin_eop;
  assign trc_vc1_out_d    = o_nout_enq[1] & o_nout_eop;
  assign trc_vc2_in_d     = o_nin_deq[2]  & o_nin_eop;
  assign trc_vc2_out_d    = o_nout_enq[2] & o_nout_eop;

  always @(posedge clk_ni) begin
    trc_op_local_q   <= #`dh trc_op_local_d;
    trc_op_remote_q  <= #`dh trc_op_remote_d;
    trc_read_hit_q   <= #`dh trc_read_hit_d;
    trc_read_miss_q  <= #`dh trc_read_miss_d;
    trc_write_hit_q  <= #`dh trc_write_hit_d;
    trc_write_miss_q <= #`dh trc_write_miss_d;
    trc_vc0_in_q     <= #`dh trc_vc0_in_d;
    trc_vc0_out_q    <= #`dh trc_vc0_out_d;
    trc_vc1_in_q     <= #`dh trc_vc1_in_d;
    trc_vc1_out_q    <= #`dh trc_vc1_out_d;
    trc_vc2_in_q     <= #`dh trc_vc2_in_d;
    trc_vc2_out_q    <= #`dh trc_vc2_out_d;
  end

  assign o_ctl_trace_op_local   = trc_op_local_d   & ~trc_op_local_q;
  assign o_ctl_trace_op_remote  = trc_op_remote_d  & ~trc_op_remote_q;
  assign o_ctl_trace_read_hit   = trc_read_hit_d   & ~trc_read_hit_q;
  assign o_ctl_trace_read_miss  = trc_read_miss_d  & ~trc_read_miss_q;
  assign o_ctl_trace_write_hit  = trc_write_hit_d  & ~trc_write_hit_q;
  assign o_ctl_trace_write_miss = trc_write_miss_d & ~trc_write_miss_q;
  assign o_ctl_trace_vc0_in     = trc_vc0_in_d     & ~trc_vc0_in_q;
  assign o_ctl_trace_vc0_out    = trc_vc0_out_d    & ~trc_vc0_out_q;
  assign o_ctl_trace_vc1_in     = trc_vc1_in_d     & ~trc_vc1_in_q;
  assign o_ctl_trace_vc1_out    = trc_vc1_out_d    & ~trc_vc1_out_q;
  assign o_ctl_trace_vc2_in     = trc_vc2_in_d     & ~trc_vc2_in_q;
  assign o_ctl_trace_vc2_out    = trc_vc2_out_d    & ~trc_vc2_out_q;

endmodule
