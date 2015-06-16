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
// Abstract      : MicroBlaze Slice (MBS) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mbs.v,v $
// CVS revision  : $Revision: 1.33 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

// synthesis translate_off
`define SYNTH_NEED_TRACING 1
`define SYNTH_NEED_DEBUG 1
// synthesis translate_on

module mbs (

  // Clocks and resets
  input              clk_cpu,
  input              clk_mc,
  input              clk_ni,
  input              clk_xbar,
  input              rst_mc,
  input              rst_ni,
  input              rst_xbar,
  input              i_boot_done,

  // Static configuration signals
  input      [ 7:0] i_board_id,
  input      [ 3:0] i_node_id,
  input             i_cpu_enable_rst_value,

  // Board controller interface
  output     [ 3:0] o_bctl_load_status,
  input             i_bctl_uart_irq,
  output            o_bctl_uart_irq_clear,
  input             i_bctl_tmr_drift_fw,
  input             i_bctl_tmr_drift_bw,
  output            o_bctl_trc_valid,
  output     [ 7:0] o_bctl_trc_data,

  // SRAM Controller interface
  output     [17:0] o_sctl_req_adr,
  output            o_sctl_req_we,
  output     [31:0] o_sctl_req_wdata,
  output     [ 3:0] o_sctl_req_be,
  output            o_sctl_req_valid,
  input      [31:0] i_sctl_resp_rdata,
  input             i_sctl_resp_valid,
   
  // Crossbar interface
  input        [2:0] i_xbar_out_enq,
  input        [5:0] i_xbar_out_offset,
  input              i_xbar_out_eop,
  input       [15:0] i_xbar_out_data,
  output       [2:0] o_xbar_out_full,
  output       [2:0] o_xbar_out_packets_vc0,
  output       [2:0] o_xbar_out_packets_vc1,
  output       [2:0] o_xbar_out_packets_vc2,
  input        [2:0] i_xbar_in_deq,
  input        [5:0] i_xbar_in_offset,
  input              i_xbar_in_eop,
  output      [15:0] o_xbar_in_data,
  output       [2:0] o_xbar_in_empty,

  // Microblaze debug interface
  input              i_mdm_brk,
  input              i_mdm_nm_brk,
  input              i_mdm_clk,
  input              i_mdm_tdi,
  output             o_mdm_tdo,
  input        [7:0] i_mdm_reg_en,
  input              i_mdm_shift,
  input              i_mdm_capture,
  input              i_mdm_update,
  input              i_mdm_reset
);


  // ==========================================================================
  // Wires
  // ==========================================================================

  // CPU - ART interface
  wire [31:0] cpu_art_iadr;
  wire [31:0] cpu_art_idata;
  wire        cpu_art_ifetch;
  wire        cpu_art_istrobe;
  wire        cpu_art_iready;
  wire [31:0] cpu_art_dadr;
  wire [31:0] cpu_art_dwdata;
  wire [31:0] cpu_art_drdata;
  wire        cpu_art_dstrobe;
  wire        cpu_art_drd;
  wire        cpu_art_dwr;
  wire        cpu_art_dready;
  wire  [3:0] cpu_art_dben;
  
  // ART - IL1 interface
  wire [31:0] art_il1_adr;
  wire        art_il1_valid;
  wire        art_il1_flag;
  wire [31:0] art_il1_data;
  wire        art_il1_tlb_fault;
  wire        art_il1_stall;

  // ART - DL1 interface
  wire [31:0] art_dl1_adr;
  wire        art_dl1_valid;
  wire [ 1:0] art_dl1_flags;
  wire [ 3:0] art_dl1_ben;
  wire        art_dl1_wen;
  wire [31:0] art_dl1_rdata;
  wire [31:0] art_dl1_wdata;
  wire        art_dl1_tlb_fault;
  wire        art_dl1_stall;

  // IL1 - L2C interface
  wire [31:0] il1_l2c_adr;
  wire [ 1:0] il1_l2c_flags;
  wire        il1_l2c_valid;
  wire [31:0] il1_l2c_rdata;
  wire        il1_l2c_resp_valid;
  wire        il1_l2c_tlb_fault;
  wire        il1_l2c_stall;
  wire [31:0] il1_l2c_inv_adr;
  wire        il1_l2c_inv_req;
  wire        il1_l2c_inv_ack;

  // DL1 - L2C interface
  wire [31:0] dl1_l2c_adr;
  wire [ 1:0] dl1_l2c_flags;
  wire [ 3:0] dl1_l2c_ben;
  wire        dl1_l2c_wen;
  wire [31:0] dl1_l2c_wdata;
  wire        dl1_l2c_valid;
  wire [31:0] dl1_l2c_rdata;
  wire        dl1_l2c_resp_valid;
  wire        dl1_l2c_tlb_fault;
  wire        dl1_l2c_stall;
  wire [31:0] dl1_l2c_inv_adr;
  wire        dl1_l2c_inv_req;
  wire        dl1_l2c_inv_ack;

  // L2C - MNI Writeback interface
  wire        l2c_mni_wb_space;
  wire        l2c_mni_wb_valid;
  wire [31:0] l2c_mni_wb_adr;

  // L2C - MNI Writeback Acknowledge interface
  wire        l2c_mni_wb_ack_valid;
  wire        l2c_mni_wb_ack_fault;
  wire [31:0] l2c_mni_wb_ack_adr;
  wire        l2c_mni_wb_ack_stall;

  // L2C - MNI Miss interface
  wire        l2c_mni_miss_valid;
  wire [31:0] l2c_mni_miss_adr;
  wire  [1:0] l2c_mni_miss_flags;
  wire        l2c_mni_miss_wen;
  wire  [3:0] l2c_mni_miss_ben;
  wire [31:0] l2c_mni_miss_wdata;
  wire        l2c_mni_miss_stall;

  // L2C - MNI Fill interface
  wire        l2c_mni_fill_valid;
  wire        l2c_mni_fill_fault;
  wire  [3:0] l2c_mni_fill_len;
  wire [31:0] l2c_mni_fill_adr;
  wire        l2c_mni_fill_stall;

  // L2C - MNI Write interface
  wire        l2c_mni_write_valid;
  wire [31:0] l2c_mni_write_adr;
  wire        l2c_mni_write_dirty;
  wire        l2c_mni_write_stall;
  wire        l2c_mni_write_nack;
  wire        l2c_mni_write_done;

  // L2C - MNI Read interface
  wire        l2c_mni_read_valid;
  wire [31:0] l2c_mni_read_adr;
  wire        l2c_mni_read_ignore;
  wire        l2c_mni_read_stall;
  wire        l2c_mni_read_nack;

  // L2C - MNI common data busses
  wire [31:0] mni_l2c_data;
  wire [31:0] l2c_mni_data;

  // MNI - XBI interface
  wire  [2:0] mni_xbi_nout_enq;
  wire  [5:0] mni_xbi_nout_offset;
  wire        mni_xbi_nout_eop;
  wire [15:0] mni_xbi_nout_data;
  wire  [2:0] mni_xbi_nout_full;
  wire  [2:0] mni_xbi_nout_packets_vc0;
  wire  [2:0] mni_xbi_nout_packets_vc1;
  wire  [2:0] mni_xbi_nout_packets_vc2;
  wire  [2:0] mni_xbi_nin_deq;
  wire  [5:0] mni_xbi_nin_offset;
  wire        mni_xbi_nin_eop;
  wire [15:0] mni_xbi_nin_data;
  wire  [2:0] mni_xbi_nin_empty;
  wire  [2:0] mni_xbi_nin_packets_vc0;
  wire  [2:0] mni_xbi_nin_packets_vc1;
  wire  [2:0] mni_xbi_nin_packets_vc2;

  // MNI - CTL Register interface
  wire [19:0] mni_ctl_reg_adr;
  wire        mni_ctl_reg_valid;
  wire        mni_ctl_reg_wen;
  wire        mni_ctl_reg_from_cpu;
  wire [ 1:0] mni_ctl_reg_ben;
  wire [15:0] mni_ctl_reg_wdata;
  wire [ 2:0] mni_ctl_reg_rlen;
  wire        mni_ctl_reg_stall;
  wire [15:0] mni_ctl_reg_resp_rdata;
  wire        mni_ctl_reg_resp_valid;
  wire        mni_ctl_reg_block;
  wire        mni_ctl_reg_unblock;
  
  // CTL - CPU interface
  wire        rst_cpu;
  wire        ctl_cpu_interrupt;
  wire        ctl_cpu_trace_daccess;
  wire [31:0] ctl_cpu_trace_inst_adr;
  wire [31:0] ctl_cpu_trace_data_adr;
  wire        ctl_cpu_trace_energy;
  wire  [2:0] ctl_cpu_trace_energy_val;

  // CTL - ART Regions interface
  wire [11:0] ctl_art_entry0_base;
  wire        ctl_art_entry0_u_flag;
  wire [11:0] ctl_art_entry1_base;
  wire [11:0] ctl_art_entry1_end;
  wire [ 4:0] ctl_art_entry1_flags;
  wire        ctl_art_entry1_valid;
  wire [11:0] ctl_art_entry2_base;
  wire [11:0] ctl_art_entry2_end;
  wire [ 4:0] ctl_art_entry2_flags;
  wire        ctl_art_entry2_valid;
  wire [11:0] ctl_art_entry3_base;
  wire [11:0] ctl_art_entry3_end;
  wire [ 4:0] ctl_art_entry3_flags;
  wire        ctl_art_entry3_valid;
  wire [11:0] ctl_art_entry4_base;
  wire [11:0] ctl_art_entry4_end;
  wire [ 4:0] ctl_art_entry4_flags;
  wire        ctl_art_entry4_valid;

  // CTL - ART Fault interface
  wire        ctl_art_privileged;
  wire        ctl_art_fault_ack;
  wire        ctl_art_perm_fault;
  wire        ctl_art_miss_fault;
  wire        ctl_art_tlb_fault;

  // CTL Caches enable
  wire        ctl_cache_en;

  // CTL - IL1 interface
  wire        ctl_il1_clear_req;
  wire        ctl_il1_clear_ack;
  wire        ctl_il1_trace_hit;
  wire        ctl_il1_trace_miss;

  // CTL - DL1 interface
  wire        ctl_dl1_clear_req;
  wire        ctl_dl1_clear_ack;
  wire        ctl_dl1_trace_hit;
  wire        ctl_dl1_trace_miss;
  
  // CTL - L2C interface
  wire        ctl_l2c_clear_req;
  wire        ctl_l2c_flush_req;
  wire        ctl_l2c_maint_ack;
  wire [ 2:0] ctl_l2c_epoch;
  wire [ 2:0] ctl_l2c_min_cpu_ways;
  wire        ctl_l2c_trace_hit;
  wire        ctl_l2c_trace_miss;
 
  // CTL - MNI Operation interface
  wire        ctl_mni_op_valid;
  wire [15:0] ctl_mni_op_data;
  wire        ctl_mni_op_stall;
  wire [ 5:0] ctl_mni_cpu_fifo_ops;
  wire [ 5:0] ctl_mni_net_fifo_ops;

  // CTL - MNI Trace interface
  wire        ctl_mni_trace_op_local;
  wire        ctl_mni_trace_op_remote;
  wire        ctl_mni_trace_read_hit;
  wire        ctl_mni_trace_read_miss;
  wire        ctl_mni_trace_write_hit;
  wire        ctl_mni_trace_write_miss;
  wire        ctl_mni_trace_vc0_in;
  wire        ctl_mni_trace_vc0_out;
  wire        ctl_mni_trace_vc1_in;
  wire        ctl_mni_trace_vc1_out;
  wire        ctl_mni_trace_vc2_in;
  wire        ctl_mni_trace_vc2_out;

  // CTL - CMX interface
  wire        ctl_cmx_valid;
  wire [ 3:0] ctl_cmx_opcode;
  wire [ 2:0] ctl_cmx_rd_len;
  wire [ 9:0] ctl_cmx_cnt_adr;
  wire [15:0] ctl_cmx_wdata;
  wire        ctl_cmx_stall;
  wire [15:0] ctl_cmx_resp_rdata;
  wire        ctl_cmx_resp_valid;
  wire        ctl_cmx_resp_block;
  wire        ctl_cmx_resp_unblock;
  wire        ctl_cmx_int_mbox;
  wire        ctl_cmx_int_cnt;
  wire [ 5:0] ctl_cmx_int_cnt_adr;

  // CMX - MNI Interface
  wire        cmx_mni_valid;
  wire [15:0] cmx_mni_data;
  wire        cmx_mni_stall;
  wire [11:0] cmx_mni_mbox_space;
  wire        cmx_mni_mslot_space;

  wire        lru_mode;
  // ==========================================================================
  // Extra registers
  // ==========================================================================
  (* equivalent_register_removal = "no" *)
  reg [7:0] board_id_q;
  (* equivalent_register_removal = "no" *)
  reg [3:0] node_id_q;

  always @(posedge clk_cpu) begin
    board_id_q <= #`dh i_board_id;
    node_id_q  <= #`dh i_node_id;
  end


  // ==========================================================================
  // Xilinx Microblaze CPU
  // ==========================================================================
  xil_microblaze # (

    .NEED_TRACING           ( `SYNTH_NEED_TRACING ),
    .NEED_DEBUG             ( `SYNTH_NEED_DEBUG )
  
  ) i0_xil_microblaze (

    // Core interface
    .clk_cpu                ( clk_cpu ),
    .rst_cpu                ( rst_cpu ),
    .i_ctl_interrupt        ( ctl_cpu_interrupt ),

    // Instruction LMB
    .o_iadr                 ( cpu_art_iadr ),
    .o_istrobe              ( cpu_art_istrobe ),
    .o_ifetch               ( cpu_art_ifetch ),
    .i_idata                ( cpu_art_idata ),
    .i_iready               ( cpu_art_iready ),

    // Data LMB
    .o_dadr                 ( cpu_art_dadr ),
    .o_dstrobe              ( cpu_art_dstrobe ),
    .o_drd                  ( cpu_art_drd ),
    .o_dwr                  ( cpu_art_dwr ),
    .o_ben                  ( cpu_art_dben ),
    .o_dwdata               ( cpu_art_dwdata ),
    .i_drdata               ( cpu_art_drdata ),
    .i_dready               ( cpu_art_dready ),

    // Trace interface
    .o_ctl_trace_daccess    ( ctl_cpu_trace_daccess ),
    .o_ctl_trace_inst_adr   ( ctl_cpu_trace_inst_adr ),
    .o_ctl_trace_data_adr   ( ctl_cpu_trace_data_adr ),
    .o_ctl_trace_energy     ( ctl_cpu_trace_energy ),
    .o_ctl_trace_energy_val ( ctl_cpu_trace_energy_val ),

    // MDM Debug interface
    .i_mdm_brk              ( i_mdm_brk ),
    .i_mdm_nm_brk           ( i_mdm_nm_brk ),
    .i_mdm_clk              ( i_mdm_clk ),
    .i_mdm_tdi              ( i_mdm_tdi ),
    .o_mdm_tdo              ( o_mdm_tdo ),
    .i_mdm_reg_en           ( i_mdm_reg_en ),
    .i_mdm_shift            ( i_mdm_shift ),
    .i_mdm_capture          ( i_mdm_capture ),
    .i_mdm_update           ( i_mdm_update ),
    .i_mdm_reset            ( i_mdm_reset )
  );


  // ==========================================================================
  // ART (Address Region Table)
  // ==========================================================================
  art i0_art (
    
    // Clocks and Resets
    .clk_cpu                ( clk_cpu ), 
    .rst_cpu                ( rst_cpu ), 
    .clk_mc                 ( clk_mc ), 
    .rst_mc                 ( rst_mc ), 

    // Microblaze Instruction interface
    .i_cpu_iadr             ( cpu_art_iadr ),
    .i_cpu_istrobe          ( cpu_art_istrobe ), 
    .i_cpu_ifetch           ( cpu_art_ifetch ), 
    .o_cpu_idata            ( cpu_art_idata ), 
    .o_cpu_iready           ( cpu_art_iready ),

    // Microblaze Data interface
    .i_cpu_dadr             ( cpu_art_dadr ), 
    .i_cpu_dstrobe          ( cpu_art_dstrobe ), 
    .i_cpu_drd              ( cpu_art_drd ),
    .i_cpu_dwr              ( cpu_art_dwr ), 
    .i_cpu_dben             ( cpu_art_dben ),
    .i_cpu_dwdata           ( cpu_art_dwdata ), 
    .o_cpu_drdata           ( cpu_art_drdata ), 
    .o_cpu_dready           ( cpu_art_dready ),

    // CTL Regions interface
    .i_ctl_entry0_base      ( ctl_art_entry0_base ),
    .i_ctl_entry0_u_flag    ( ctl_art_entry0_u_flag ),
    .i_ctl_entry1_base      ( ctl_art_entry1_base ),
    .i_ctl_entry1_end       ( ctl_art_entry1_end ),
    .i_ctl_entry1_flags     ( ctl_art_entry1_flags ),
    .i_ctl_entry1_valid     ( ctl_art_entry1_valid ),
    .i_ctl_entry2_base      ( ctl_art_entry2_base ),
    .i_ctl_entry2_end       ( ctl_art_entry2_end ),
    .i_ctl_entry2_flags     ( ctl_art_entry2_flags ),
    .i_ctl_entry2_valid     ( ctl_art_entry2_valid ),
    .i_ctl_entry3_base      ( ctl_art_entry3_base ),
    .i_ctl_entry3_end       ( ctl_art_entry3_end ),
    .i_ctl_entry3_flags     ( ctl_art_entry3_flags ),
    .i_ctl_entry3_valid     ( ctl_art_entry3_valid ),
    .i_ctl_entry4_base      ( ctl_art_entry4_base ),
    .i_ctl_entry4_end       ( ctl_art_entry4_end ),
    .i_ctl_entry4_flags     ( ctl_art_entry4_flags ),
    .i_ctl_entry4_valid     ( ctl_art_entry4_valid ),

    // CTL Fault interface
    .i_ctl_privileged       ( ctl_art_privileged ),
    .i_ctl_fault_ack        ( ctl_art_fault_ack ),
    .o_ctl_perm_fault       ( ctl_art_perm_fault ),
    .o_ctl_miss_fault       ( ctl_art_miss_fault ),
    .o_ctl_tlb_fault        ( ctl_art_tlb_fault ),

    // IL1 interface
    .o_il1_adr              ( art_il1_adr ),
    .o_il1_valid            ( art_il1_valid ),
    .o_il1_flag             ( art_il1_flag ),
    .i_il1_data             ( art_il1_data ),
    .i_il1_tlb_fault        ( art_il1_tlb_fault ),
    .i_il1_stall            ( art_il1_stall ),

    // DL1 interface
    .o_dl1_adr              ( art_dl1_adr ),
    .o_dl1_valid            ( art_dl1_valid ),
    .o_dl1_flags            ( art_dl1_flags ),
    .o_dl1_ben              ( art_dl1_ben ),
    .o_dl1_wen              ( art_dl1_wen ),
    .i_dl1_rdata            ( art_dl1_rdata ),
    .o_dl1_wdata            ( art_dl1_wdata ),
    .i_dl1_tlb_fault        ( art_dl1_tlb_fault ),
    .i_dl1_stall            ( art_dl1_stall )
   );


  // ==========================================================================
  // IL1 (Instruction Level 1 Cache)
  // ==========================================================================
  il1 i0_il1 (

    // Clock and Reset
    .clk_mc                 ( clk_mc ),
    .rst_mc                 ( rst_mc ),

    // CTL Interface
    .i_ctl_en               ( ctl_cache_en ),
    .i_ctl_clear_req        ( ctl_il1_clear_req ),
    .o_ctl_clear_ack        ( ctl_il1_clear_ack ),
    .o_ctl_trace_hit        ( ctl_il1_trace_hit ),
    .o_ctl_trace_miss       ( ctl_il1_trace_miss),

    // ART Interface
    .i_art_adr              ( art_il1_adr ),
    .i_art_flags            ( {art_il1_flag,1'b0} ),
    .i_art_valid            ( art_il1_valid ),
    .o_art_rdata            ( art_il1_data ),
    .o_art_tlb_fault        ( art_il1_tlb_fault ),
    .o_art_stall            ( art_il1_stall ),

    // L2C Interface
    .o_l2c_adr              ( il1_l2c_adr ),
    .o_l2c_flags            ( il1_l2c_flags ),
    .o_l2c_valid            ( il1_l2c_valid ),
    .i_l2c_rdata            ( il1_l2c_rdata ),
    .i_l2c_rdata_valid      ( il1_l2c_resp_valid),
    .i_l2c_tlb_fault        ( il1_l2c_tlb_fault ),
    .i_l2c_stall            ( il1_l2c_stall ),
    .i_l2c_inv_adr          ( il1_l2c_inv_adr ),
    .i_l2c_inv_req          ( il1_l2c_inv_req ),
    .o_l2c_inv_ack          ( il1_l2c_inv_ack )
  );


  // ==========================================================================
  // DL1 (Data Level 1 Cache)
  // ==========================================================================
  dl1 i0_dl1 (

    // Clock and Reset
    .clk_mc                 ( clk_mc ),
    .rst_mc                 ( rst_mc ),

    // CTL Interface
    .i_ctl_en               ( ctl_cache_en ),
    .i_ctl_clear_req        ( ctl_dl1_clear_req ),
    .o_ctl_clear_ack        ( ctl_dl1_clear_ack ),
    .o_ctl_trace_hit        ( ctl_dl1_trace_hit ),
    .o_ctl_trace_miss       ( ctl_dl1_trace_miss),

    // ART Interface
    .i_art_adr              ( art_dl1_adr ),
    .i_art_flags            ( art_dl1_flags ),
    .i_art_ben              ( art_dl1_ben ),
    .i_art_wen              ( art_dl1_wen ),
    .i_art_wdata            ( art_dl1_wdata ),
    .i_art_valid            ( art_dl1_valid ),
    .o_art_rdata            ( art_dl1_rdata ),
    .o_art_tlb_fault        ( art_dl1_tlb_fault ),
    .o_art_stall            ( art_dl1_stall ),

    // L2C Interface
    .o_l2c_adr              ( dl1_l2c_adr ),
    .o_l2c_flags            ( dl1_l2c_flags ),
    .o_l2c_ben              ( dl1_l2c_ben ),
    .o_l2c_wen              ( dl1_l2c_wen ),
    .o_l2c_wdata            ( dl1_l2c_wdata ),
    .o_l2c_valid            ( dl1_l2c_valid ),
    .i_l2c_rdata            ( dl1_l2c_rdata ),
    .i_l2c_rdata_valid      ( dl1_l2c_resp_valid),
    .i_l2c_tlb_fault        ( dl1_l2c_tlb_fault ),
    .i_l2c_stall            ( dl1_l2c_stall ),
    .i_l2c_inv_adr          ( dl1_l2c_inv_adr ),
    .i_l2c_inv_req          ( dl1_l2c_inv_req ),
    .o_l2c_inv_ack          ( dl1_l2c_inv_ack )
  );

  
  // ==========================================================================
  // L2C (Level 2 Cache)
  // ==========================================================================
  l2c i0_l2c (
    .clk_mc                 ( clk_mc ),
    .rst_mc                 ( rst_mc ),

    // CTL Interface
    .i_lru_mode             ( lru_mode ),
    .i_ctl_en               ( ctl_cache_en ),
    .i_ctl_clear_req        ( ctl_l2c_clear_req ),
    .i_ctl_flush_req        ( ctl_l2c_flush_req ),
    .o_ctl_maint_ack        ( ctl_l2c_maint_ack ),
    .i_ctl_epoch            ( ctl_l2c_epoch ),
    .i_ctl_min_cpu_ways     ( ctl_l2c_min_cpu_ways ),
    .o_ctl_trace_ihit       ( ctl_l2c_trace_ihit ),
    .o_ctl_trace_imiss      ( ctl_l2c_trace_imiss ),
    .o_ctl_trace_dhit       ( ctl_l2c_trace_dhit ),
    .o_ctl_trace_dmiss      ( ctl_l2c_trace_dmiss ),
    
    // SRAM Controller Interface
    .o_sctl_req_adr         ( o_sctl_req_adr ),
    .o_sctl_req_we          ( o_sctl_req_we ),
    .o_sctl_req_wdata       ( o_sctl_req_wdata ),
    .o_sctl_req_be          ( o_sctl_req_be ),
    .o_sctl_req_valid       ( o_sctl_req_valid ),
    .i_sctl_resp_rdata      ( i_sctl_resp_rdata ),
    .i_sctl_resp_valid      ( i_sctl_resp_valid ),
    
    // IL1 Interface
    .i_il1_adr              ( il1_l2c_adr ),
    .i_il1_flags            ( il1_l2c_flags[1] ),
    .i_il1_valid            ( il1_l2c_valid ),
    .o_il1_rdata_valid      ( il1_l2c_resp_valid ),
    .o_il1_rdata            ( il1_l2c_rdata ),
    .o_il1_tlb_fault        ( il1_l2c_tlb_fault ),
    .o_il1_stall            ( il1_l2c_stall ),
    .o_il1_inv_req          ( il1_l2c_inv_req ),
    .o_il1_inv_adr          ( il1_l2c_inv_adr ),
    .i_il1_inv_ack          ( il1_l2c_inv_ack ),
 
    // DL1 Interface
    .i_dl1_adr              ( dl1_l2c_adr ),
    .i_dl1_flags            ( dl1_l2c_flags ),
    .i_dl1_ben              ( dl1_l2c_ben ),
    .i_dl1_wen              ( dl1_l2c_wen ),
    .i_dl1_wdata            ( dl1_l2c_wdata ),
    .i_dl1_valid            ( dl1_l2c_valid ),
    .o_dl1_rdata_valid      ( dl1_l2c_resp_valid ),
    .o_dl1_rdata            ( dl1_l2c_rdata ),
    .o_dl1_tlb_fault        ( dl1_l2c_tlb_fault ),
    .o_dl1_stall            ( dl1_l2c_stall ),
    .o_dl1_inv_req          ( dl1_l2c_inv_req ),
    .o_dl1_inv_adr          ( dl1_l2c_inv_adr ),
    .i_dl1_inv_ack          ( dl1_l2c_inv_ack ),

    // MNI Writeback Interface
    .i_mni_wb_space         ( l2c_mni_wb_space ),
    .o_mni_wb_valid         ( l2c_mni_wb_valid ),
    .o_mni_wb_adr           ( l2c_mni_wb_adr ),

    // MNI Writeback Acknowledge Interface
    .i_mni_wb_ack_valid     ( l2c_mni_wb_ack_valid ),
    .i_mni_wb_ack_fault     ( l2c_mni_wb_ack_fault ),
    .i_mni_wb_ack_adr       ( l2c_mni_wb_ack_adr ),
    .o_mni_wb_ack_stall     ( l2c_mni_wb_ack_stall ),

    // MNI Miss Interface
    .o_mni_miss_valid       ( l2c_mni_miss_valid ),
    .o_mni_miss_adr         ( l2c_mni_miss_adr ),
    .o_mni_miss_flags       ( l2c_mni_miss_flags ),
    .o_mni_miss_wen         ( l2c_mni_miss_wen ),
    .o_mni_miss_ben         ( l2c_mni_miss_ben ),
    .o_mni_miss_wdata       ( l2c_mni_miss_wdata ),
    .i_mni_miss_stall       ( l2c_mni_miss_stall ),

    // MNI Fill Interface
    .i_mni_fill_valid       ( l2c_mni_fill_valid ),
    .i_mni_fill_fault       ( l2c_mni_fill_fault ),
    .i_mni_fill_len         ( l2c_mni_fill_len ),
    .i_mni_fill_adr         ( l2c_mni_fill_adr ),
    .o_mni_fill_stall       ( l2c_mni_fill_stall ),

    // MNI Write Interface
    .i_mni_write_valid      ( l2c_mni_write_valid ),
    .i_mni_write_adr        ( l2c_mni_write_adr ),
    .i_mni_write_dirty      ( l2c_mni_write_dirty ),
    .o_mni_write_stall      ( l2c_mni_write_stall ),
    .o_mni_write_nack       ( l2c_mni_write_nack ),
    .o_mni_write_done       ( l2c_mni_write_done ),

    // MNI Read Interface
    .i_mni_read_valid       ( l2c_mni_read_valid ),
    .i_mni_read_adr         ( l2c_mni_read_adr ),
    .i_mni_read_ignore      ( l2c_mni_read_ignore ),
    .o_mni_read_stall       ( l2c_mni_read_stall ),
    .o_mni_read_nack        ( l2c_mni_read_nack ),
    
    // MNI Common Data Busses
    .i_mni_data             ( mni_l2c_data ),
    .o_mni_data             ( l2c_mni_data )
  );


  // ==========================================================================
  // MNI (MBS Network Interface)
  // ==========================================================================
  mni i0_mni (

    // Clocks and Resets
    .clk_mc                 ( clk_mc ),
    .rst_mc                 ( rst_mc ),
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),

    // Configuration
    .i_board_id             ( board_id_q ),
    .i_node_id              ( node_id_q ),
    .i_ctl_addr_base        ( ctl_art_entry0_base ),

    // CTL Registers Access Interface
    .o_ctl_reg_adr          ( mni_ctl_reg_adr ),
    .o_ctl_reg_valid        ( mni_ctl_reg_valid ),
    .o_ctl_reg_wen          ( mni_ctl_reg_wen ),
    .o_ctl_reg_from_cpu     ( mni_ctl_reg_from_cpu ),
    .o_ctl_reg_ben          ( mni_ctl_reg_ben ),
    .o_ctl_reg_wdata        ( mni_ctl_reg_wdata ),
    .o_ctl_reg_rlen         ( mni_ctl_reg_rlen ),
    .i_ctl_reg_stall        ( mni_ctl_reg_stall ),
    .i_ctl_reg_resp_rdata   ( mni_ctl_reg_resp_rdata ),
    .i_ctl_reg_resp_valid   ( mni_ctl_reg_resp_valid ),
    .i_ctl_reg_block        ( mni_ctl_reg_block ),
    .i_ctl_reg_unblock      ( mni_ctl_reg_unblock ),

    // CTL Operation Interface
    .i_ctl_op_valid         ( ctl_mni_op_valid ),
    .i_ctl_op_data          ( ctl_mni_op_data ),
    .o_ctl_op_stall         ( ctl_mni_op_stall ),
    .o_ctl_cpu_fifo_ops     ( ctl_mni_cpu_fifo_ops ),
    .o_ctl_net_fifo_ops     ( ctl_mni_net_fifo_ops ),

    // CTL Trace Interface
    .o_ctl_trace_op_local   ( ctl_mni_trace_op_local ),
    .o_ctl_trace_op_remote  ( ctl_mni_trace_op_remote ),
    .o_ctl_trace_read_hit   ( ctl_mni_trace_read_hit ),
    .o_ctl_trace_read_miss  ( ctl_mni_trace_read_miss ),
    .o_ctl_trace_write_hit  ( ctl_mni_trace_write_hit ),
    .o_ctl_trace_write_miss ( ctl_mni_trace_write_miss ),
    .o_ctl_trace_vc0_in     ( ctl_mni_trace_vc0_in ),
    .o_ctl_trace_vc0_out    ( ctl_mni_trace_vc0_out ),
    .o_ctl_trace_vc1_in     ( ctl_mni_trace_vc1_in ),
    .o_ctl_trace_vc1_out    ( ctl_mni_trace_vc1_out ),
    .o_ctl_trace_vc2_in     ( ctl_mni_trace_vc2_in ),
    .o_ctl_trace_vc2_out    ( ctl_mni_trace_vc2_out ),

    // CMX interface
    .i_cmx_valid            ( cmx_mni_valid ),
    .i_cmx_data             ( cmx_mni_data ),
    .o_cmx_stall            ( cmx_mni_stall ),
    .i_cmx_mbox_space       ( cmx_mni_mbox_space ),
    .i_cmx_mslot_space      ( cmx_mni_mslot_space ),

    // L2C Writeback Interface
    .o_l2c_wb_space         ( l2c_mni_wb_space ),
    .i_l2c_wb_valid         ( l2c_mni_wb_valid ),
    .i_l2c_wb_adr           ( l2c_mni_wb_adr ),

    // L2C Writeback Acknowledge Interface
    .o_l2c_wb_ack_valid     ( l2c_mni_wb_ack_valid ),
    .o_l2c_wb_ack_fault     ( l2c_mni_wb_ack_fault ),
    .o_l2c_wb_ack_adr       ( l2c_mni_wb_ack_adr ),
    .i_l2c_wb_ack_stall     ( l2c_mni_wb_ack_stall ),

    // L2C Miss Interface
    .i_l2c_miss_valid       ( l2c_mni_miss_valid ),
    .i_l2c_miss_adr         ( l2c_mni_miss_adr ),
    .i_l2c_miss_flags       ( l2c_mni_miss_flags ),
    .i_l2c_miss_wen         ( l2c_mni_miss_wen ),
    .i_l2c_miss_ben         ( l2c_mni_miss_ben ),
    .i_l2c_miss_wdata       ( l2c_mni_miss_wdata ),
    .o_l2c_miss_stall       ( l2c_mni_miss_stall ),

    // L2C Fill Interface
    .o_l2c_fill_valid       ( l2c_mni_fill_valid ),
    .o_l2c_fill_fault       ( l2c_mni_fill_fault ),
    .o_l2c_fill_len         ( l2c_mni_fill_len ),
    .o_l2c_fill_adr         ( l2c_mni_fill_adr ),
    .i_l2c_fill_stall       ( l2c_mni_fill_stall ),

    // L2C Write Interface
    .o_l2c_write_valid      ( l2c_mni_write_valid ),
    .o_l2c_write_adr        ( l2c_mni_write_adr ),
    .o_l2c_write_dirty      ( l2c_mni_write_dirty ),
    .i_l2c_write_stall      ( l2c_mni_write_stall ),
    .i_l2c_write_nack       ( l2c_mni_write_nack ),
    .i_l2c_write_done       ( l2c_mni_write_done ),

    // L2C Read Interface
    .o_l2c_read_valid       ( l2c_mni_read_valid ),
    .o_l2c_read_adr         ( l2c_mni_read_adr ),
    .o_l2c_read_ignore      ( l2c_mni_read_ignore ),
    .i_l2c_read_stall       ( l2c_mni_read_stall ),
    .i_l2c_read_nack        ( l2c_mni_read_nack ),
    
    // L2C Common Data Busses
    .o_l2c_data             ( mni_l2c_data ),
    .i_l2c_data             ( l2c_mni_data ),

    // Network Out Interface
    .o_nout_enq             ( mni_xbi_nout_enq ),
    .o_nout_offset          ( mni_xbi_nout_offset ),
    .o_nout_eop             ( mni_xbi_nout_eop ),
    .o_nout_data            ( mni_xbi_nout_data ),
    .i_nout_full            ( mni_xbi_nout_full ),
    .i_nout_packets_vc0     ( mni_xbi_nout_packets_vc0 ),
    .i_nout_packets_vc1     ( mni_xbi_nout_packets_vc1 ),
    .i_nout_packets_vc2     ( mni_xbi_nout_packets_vc2 ),

    // Network In Interface
    .o_nin_deq              ( mni_xbi_nin_deq ),
    .o_nin_offset           ( mni_xbi_nin_offset ),
    .o_nin_eop              ( mni_xbi_nin_eop ),
    .i_nin_data             ( mni_xbi_nin_data ),
    .i_nin_empty            ( mni_xbi_nin_empty ),
    .i_nin_packets_vc0      ( mni_xbi_nin_packets_vc0 ),
    .i_nin_packets_vc1      ( mni_xbi_nin_packets_vc1 ),
    .i_nin_packets_vc2      ( mni_xbi_nin_packets_vc2 )
   );


  // ==========================================================================
  // CTL (Control Block) 
  // ==========================================================================
  ctl # (
    .ARM_MODE               ( 0 ) 
  ) i0_ctl (

    // Static configuration
    .i_board_id             ( board_id_q ),
    .i_core_id              ( node_id_q[2:0] ),
    .i_cpu_enable_rst_value ( i_cpu_enable_rst_value ),

    // Clocks and Resets
    .clk_cpu                ( clk_cpu ),
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),
    .rst_mc                 ( rst_mc ),
    .i_boot_done            ( i_boot_done ),

    // BCTL UART Interface
    .i_uart_irq             ( i_bctl_uart_irq ),
    .o_uart_irq_clear       ( o_bctl_uart_irq_clear ),

    // Global Timer  interface
    .i_bctl_tmr_drift_fw    ( i_bctl_tmr_drift_fw ),
    .i_bctl_tmr_drift_bw    ( i_bctl_tmr_drift_bw ),
    // CPU interface
    .o_cpu_interrupt        ( ctl_cpu_interrupt ),
    .rst_cpu                ( rst_cpu ),
    .i_cpu_trace_daccess    ( ctl_cpu_trace_daccess ),
    .i_cpu_trace_inst_adr   ( ctl_cpu_trace_inst_adr ),
    .i_cpu_trace_data_adr   ( ctl_cpu_trace_data_adr ),
    .i_cpu_trace_energy     ( ctl_cpu_trace_energy ),
    .i_cpu_trace_energy_val ( ctl_cpu_trace_energy_val ),

    // ART interface
    .o_art_entry0_base      ( ctl_art_entry0_base ),
    .o_art_entry0_u_flag    ( ctl_art_entry0_u_flag ),
    .o_art_entry1_base      ( ctl_art_entry1_base ),
    .o_art_entry1_end       ( ctl_art_entry1_end ),
    .o_art_entry1_flags     ( ctl_art_entry1_flags ),
    .o_art_entry1_valid     ( ctl_art_entry1_valid ),
    .o_art_entry2_base      ( ctl_art_entry2_base ),
    .o_art_entry2_end       ( ctl_art_entry2_end ),
    .o_art_entry2_flags     ( ctl_art_entry2_flags ),
    .o_art_entry2_valid     ( ctl_art_entry2_valid ),
    .o_art_entry3_base      ( ctl_art_entry3_base ),
    .o_art_entry3_end       ( ctl_art_entry3_end ),
    .o_art_entry3_flags     ( ctl_art_entry3_flags ),
    .o_art_entry3_valid     ( ctl_art_entry3_valid ),
    .o_art_entry4_base      ( ctl_art_entry4_base ),
    .o_art_entry4_end       ( ctl_art_entry4_end ),
    .o_art_entry4_flags     ( ctl_art_entry4_flags ),
    .o_art_entry4_valid     ( ctl_art_entry4_valid ),
    .o_art_privileged       ( ctl_art_privileged ),
    .o_art_fault_ack        ( ctl_art_fault_ack ),
    .i_art_perm_fault       ( ctl_art_perm_fault ),
    .i_art_miss_fault       ( ctl_art_miss_fault ),
    .i_art_tlb_fault        ( ctl_art_tlb_fault ),

    // Caches common enable
    .o_cache_en             ( ctl_cache_en ),

    // IL1 interface
    .o_il1_clear_req        ( ctl_il1_clear_req ),
    .i_il1_clear_ack        ( ctl_il1_clear_ack ),
    .i_il1_trace_hit        ( ctl_il1_trace_hit ),
    .i_il1_trace_miss       ( ctl_il1_trace_miss),

    // DL1 interface
    .o_dl1_clear_req        ( ctl_dl1_clear_req ),
    .i_dl1_clear_ack        ( ctl_dl1_clear_ack ),
    .i_dl1_trace_hit        ( ctl_dl1_trace_hit ),
    .i_dl1_trace_miss       ( ctl_dl1_trace_miss),

    // L2C interface
    .o_lru_mode             ( lru_mode ),
    .o_l2c_clear_req        ( ctl_l2c_clear_req ),
    .o_l2c_flush_req        ( ctl_l2c_flush_req ),
    .i_l2c_maint_ack        ( ctl_l2c_maint_ack ),
    .o_l2c_epoch            ( ctl_l2c_epoch ),
    .o_l2c_min_cpu_ways     ( ctl_l2c_min_cpu_ways ),
    .i_l2c_trace_ihit       ( ctl_l2c_trace_ihit ),
    .i_l2c_trace_imiss      ( ctl_l2c_trace_imiss ),
    .i_l2c_trace_dhit       ( ctl_l2c_trace_dhit ),
    .i_l2c_trace_dmiss      ( ctl_l2c_trace_dmiss ),

    // MNI Register interface
    .i_mni_reg_adr          ( mni_ctl_reg_adr ),
    .i_mni_reg_valid        ( mni_ctl_reg_valid ),
    .i_mni_reg_wen          ( mni_ctl_reg_wen ),
    .i_mni_reg_from_cpu     ( mni_ctl_reg_from_cpu ),
    .i_mni_reg_ben          ( mni_ctl_reg_ben ),
    .i_mni_reg_wdata        ( mni_ctl_reg_wdata ),
    .i_mni_reg_rlen         ( mni_ctl_reg_rlen ),
    .o_mni_reg_stall        ( mni_ctl_reg_stall ),
    .o_mni_reg_resp_rdata   ( mni_ctl_reg_resp_rdata ),
    .o_mni_reg_resp_valid   ( mni_ctl_reg_resp_valid ),
    .o_mni_reg_block        ( mni_ctl_reg_block ),
    .o_mni_reg_unblock      ( mni_ctl_reg_unblock ),

    // MNI Operation interface  
    .o_mni_op_valid         ( ctl_mni_op_valid ),
    .o_mni_op_data          ( ctl_mni_op_data ),
    .i_mni_op_stall         ( ctl_mni_op_stall ),
    .i_mni_cpu_fifo_ops     ( ctl_mni_cpu_fifo_ops ),
    .i_mni_net_fifo_ops     ( ctl_mni_net_fifo_ops ),

    // MNI Trace Interface
    .i_mni_trace_op_local   ( ctl_mni_trace_op_local ),
    .i_mni_trace_op_remote  ( ctl_mni_trace_op_remote ),
    .i_mni_trace_read_hit   ( ctl_mni_trace_read_hit ),
    .i_mni_trace_read_miss  ( ctl_mni_trace_read_miss ),
    .i_mni_trace_write_hit  ( ctl_mni_trace_write_hit ),
    .i_mni_trace_write_miss ( ctl_mni_trace_write_miss ),
    .i_mni_trace_vc0_in     ( ctl_mni_trace_vc0_in ),
    .i_mni_trace_vc0_out    ( ctl_mni_trace_vc0_out ),
    .i_mni_trace_vc1_in     ( ctl_mni_trace_vc1_in ),
    .i_mni_trace_vc1_out    ( ctl_mni_trace_vc1_out ),
    .i_mni_trace_vc2_in     ( ctl_mni_trace_vc2_in ),
    .i_mni_trace_vc2_out    ( ctl_mni_trace_vc2_out ),

    // CMX interface
    .o_cmx_valid            ( ctl_cmx_valid ),
    .o_cmx_opcode           ( ctl_cmx_opcode ),
    .o_cmx_rd_len           ( ctl_cmx_rd_len ),
    .o_cmx_cnt_adr          ( ctl_cmx_cnt_adr ),
    .o_cmx_wdata            ( ctl_cmx_wdata ),
    .i_cmx_block_aborted    ( ctl_cmx_block_aborted ),
    .i_cmx_stall            ( ctl_cmx_stall ),
    .i_cmx_resp_rdata       ( ctl_cmx_resp_rdata ),
    .i_cmx_resp_valid       ( ctl_cmx_resp_valid ),
    .i_cmx_resp_block       ( ctl_cmx_resp_block ),
    .i_cmx_resp_unblock     ( ctl_cmx_resp_unblock ),
    .i_cmx_int_mbox         ( ctl_cmx_int_mbox ),
    .i_cmx_int_cnt          ( ctl_cmx_int_cnt ),
    .i_cmx_int_cnt_adr      ( ctl_cmx_int_cnt_adr ),

    // Board controller trace interface
    .o_bctl_trc_valid       ( o_bctl_trc_valid ),
    .o_bctl_trc_data        ( o_bctl_trc_data )
  );


  // ==========================================================================
  // CMX (Counters & Mailbox)
  // ==========================================================================
  cmx i0_cmx ( 

     // Clock and Reset
    .clk_ni                 ( clk_ni ),
    .rst_ni                 ( rst_ni ),
    //
    .i_cpu_interrupt        ( ctl_cpu_interrupt ),
    // CTL Interface
    .i_ctl_valid            ( ctl_cmx_valid ),
    .i_ctl_opcode           ( ctl_cmx_opcode ),
    .i_ctl_rd_len           ( ctl_cmx_rd_len ),
    .i_ctl_cnt_adr          ( ctl_cmx_cnt_adr ),
    .i_ctl_wdata            ( ctl_cmx_wdata ),
    .o_ctl_block_aborted    ( ctl_cmx_block_aborted ),
    .o_ctl_stall            ( ctl_cmx_stall ),
    .o_ctl_resp_rdata       ( ctl_cmx_resp_rdata ),
    .o_ctl_resp_valid       ( ctl_cmx_resp_valid ),
    .o_ctl_resp_block       ( ctl_cmx_resp_block ),
    .o_ctl_resp_unblock     ( ctl_cmx_resp_unblock ),
    .o_ctl_int_mbox         ( ctl_cmx_int_mbox ),
    .o_ctl_int_cnt          ( ctl_cmx_int_cnt ),
    .o_ctl_int_cnt_adr      ( ctl_cmx_int_cnt_adr ),

    // MNI Interface
    .o_mni_valid            ( cmx_mni_valid ),
    .o_mni_data             ( cmx_mni_data ),
    .i_mni_stall            ( cmx_mni_stall ),
    .o_mni_mbox_space       ( cmx_mni_mbox_space ),
    .o_mni_mslot_space      ( cmx_mni_mslot_space ));


  // ==========================================================================
  // XBI (Crossbar Interface)
  // ==========================================================================
  xbi i0_xbi (
    
    // User port
    .clk_usr                ( clk_ni ),
    .rst_usr                ( rst_ni ),
    .i_usr_nout_enq         ( mni_xbi_nout_enq ),
    .i_usr_nout_offset      ( mni_xbi_nout_offset ),
    .i_usr_nout_eop         ( mni_xbi_nout_eop ),
    .i_usr_nout_data        ( mni_xbi_nout_data ),
    .o_usr_nout_full        ( mni_xbi_nout_full ),
    .o_usr_nout_packets_vc0 ( mni_xbi_nout_packets_vc0 ),
    .o_usr_nout_packets_vc1 ( mni_xbi_nout_packets_vc1 ),
    .o_usr_nout_packets_vc2 ( mni_xbi_nout_packets_vc2 ),
    .i_usr_nin_deq          ( mni_xbi_nin_deq ),
    .i_usr_nin_offset       ( mni_xbi_nin_offset ),
    .i_usr_nin_eop          ( mni_xbi_nin_eop ),
    .o_usr_nin_data         ( mni_xbi_nin_data ),
    .o_usr_nin_empty        ( mni_xbi_nin_empty ),
    .o_usr_nin_packets_vc0  ( mni_xbi_nin_packets_vc0 ),
    .o_usr_nin_packets_vc1  ( mni_xbi_nin_packets_vc1 ),
    .o_usr_nin_packets_vc2  ( mni_xbi_nin_packets_vc2 ),

    // Crossbar port
    .clk_xbar               ( clk_xbar ),
    .rst_xbar               ( rst_xbar ),
    .i_xbar_out_enq         ( i_xbar_out_enq ),
    .i_xbar_out_offset      ( i_xbar_out_offset ),
    .i_xbar_out_eop         ( i_xbar_out_eop ),
    .i_xbar_out_data        ( i_xbar_out_data ),
    .o_xbar_out_full        ( o_xbar_out_full ),
    .o_xbar_out_packets_vc0 ( o_xbar_out_packets_vc0 ),
    .o_xbar_out_packets_vc1 ( o_xbar_out_packets_vc1 ),
    .o_xbar_out_packets_vc2 ( o_xbar_out_packets_vc2 ),
    .i_xbar_in_deq          ( i_xbar_in_deq ),
    .i_xbar_in_offset       ( i_xbar_in_offset ),
    .i_xbar_in_eop          ( i_xbar_in_eop ),
    .o_xbar_in_data         ( o_xbar_in_data ),
    .o_xbar_in_empty        ( o_xbar_in_empty )
  );


  // ==========================================================================
  // Dummy signals
  // ==========================================================================
  assign o_bctl_load_status = 0;

  
  // ==========================================================================
  // End of simulation detector: set when CPU writes DEADBEEF at FFFFFFFC
  // ==========================================================================
  // synthesis translate_off
  reg testbench_end_of_sim;
  always @(posedge clk_cpu) begin
    if (rst_cpu)
      testbench_end_of_sim = 1'b0;
    else
      if (cpu_art_dadr   == 32'hFFFFFFFC &&
          cpu_art_dwr    == 1'b1 &&
          cpu_art_dwdata == 32'hDEADBEEF) 
      testbench_end_of_sim = 1'b1;
  end
  // synthesis translate_on

endmodule



