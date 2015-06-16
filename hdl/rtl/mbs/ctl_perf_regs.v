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
// Abstract      : CTL performance monitor registers
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: ctl_perf_regs.v,v $
// CVS revision  : $Revision: 1.4 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module ctl_perf_regs(

  // Clock
  input         clk_ni,
  input         rst_ni,
  input         clk_cpu,
  input         rst_cpu,

  // Write side
  input   [3:0] i_reg_sel_enc,
  input         i_mni_reg_write,
  input         i_block_sel,
  input         i_mni_reg_valid,
  input         i_mni_reg_adr1,
  input         i_mni_reg_ben,

  // Read side
  input         i_read_low,
  output [15:0] o_dt_out,

  // Traced events
  input         i_enable,
  input         i_il1_trace_hit,
  input         i_il1_trace_miss,
  input         i_dl1_trace_hit,
  input         i_dl1_trace_miss,
  input         i_l2c_trace_ihit,
  input         i_l2c_trace_imiss,
  input         i_l2c_trace_dhit,
  input         i_l2c_trace_dmiss,
  input         i_ctl_trace_cpu_io,
  input         i_ctl_trace_net_io,
  input         i_mni_trace_op_local,
  input         i_mni_trace_op_remote,
  input         i_mni_trace_read_hit,
  input         i_mni_trace_read_miss,
  input         i_mni_trace_write_hit,
  input         i_mni_trace_write_miss,
  input         i_mni_trace_vc0_in,
  input         i_mni_trace_vc0_out,
  input         i_mni_trace_vc1_in,
  input         i_mni_trace_vc1_out,
  input         i_mni_trace_vc2_in,
  input         i_mni_trace_vc2_out,
  input         i_cpu_trace_energy,
  input   [2:0] i_cpu_trace_energy_val
);


  // ==========================================================================
  // Wires
  // ==========================================================================
  reg  [31:0] req;
  wire [31:0] gnt;
  wire [31:0] gnt_b;
  wire  [4:0] trc_adr_d;
  reg   [4:0] trc_adr_q;
  reg         is22_q;
  reg         is24_q;
  reg         is31_q;
  wire  [0:0] carry;
  wire  [4:0] wr_adr;
  wire  [4:0] rd_adr;
  wire        trc_wen_d;
  reg         trc_wen_q;
  wire [15:0] trc_val;
  wire [16:0] new_val;
  wire        busy;
  wire  [2:0] cpu_trace_energy_val;
  wire        cpu_trace_energy;
  reg   [7:0] cpu_power;
  wire        copy_power0;
  reg         copy_power1;
  wire        copy_power;

  // ==========================================================================
  // Distributed memory
  // ==========================================================================
  (* ram_style = "distributed" *)
  reg [15:0] mem_q[0:31];

  reg mni_reg_valid_q;
  always @(posedge clk_ni)
    mni_reg_valid_q <= #`dh i_mni_reg_valid;

  assign busy = i_block_sel & (i_mni_reg_valid | mni_reg_valid_q);

  assign wr_adr = (busy)   ? {i_reg_sel_enc, i_mni_reg_adr1} : 
                  (is31_q) ? 5'd30 :
                             trc_adr_q;

  assign rd_adr = (busy)   ? {i_reg_sel_enc, ~i_read_low} :
                  (is24_q) ? 5'd30 :
                             trc_adr_q;

  wire [15:0] wr_data;
  wire        wr_en_zero;
  wire        wr_en_trc;
  wire        wr_en;
  
  assign wr_en_zero = (busy & i_mni_reg_write & i_mni_reg_ben);
  assign wr_en_trc  = (~busy & trc_wen_q & i_enable);
  assign wr_en = wr_en_zero | wr_en_trc;
  assign wr_data = (wr_en_zero) ? 16'b0 : trc_val;

  always @(posedge clk_ni) begin
    if (wr_en) 
      mem_q[wr_adr] <= #`dh wr_data;
  end

  wire [15:0] mem_out = mem_q[rd_adr];

  
  // ==========================================================================
  // CPU clock domain
  // ==========================================================================
  align_clk_sync # (
    .N    ( 3 )
  ) i0_align_clk_sync (
    .clk_in   ( clk_cpu ),
    .rst_in   ( rst_cpu ),
    .i_data   ( i_cpu_trace_energy_val ),
    .i_valid  ( i_cpu_trace_energy ),
    .o_stall  ( ),

    .clk_out  ( clk_ni ),
    .rst_out  ( rst_ni ),
    .o_data   ( cpu_trace_energy_val ),
    .o_valid  ( cpu_trace_energy ),
    .i_stall  ( 1'b0 )
  );

  always @(posedge clk_cpu) begin
    if (rst_cpu)
      cpu_power <= #`dh 0;
    else if (i_enable)
      cpu_power <= #`dh cpu_power + 1'b1;
  end

  assign copy_power0 = (cpu_power == 0);

  always @(posedge clk_ni) begin
    copy_power1 <= #`dh copy_power0;
  end

  assign copy_power = copy_power0 & ~copy_power1;



  // ==========================================================================
  // Event tracing requests
  // ==========================================================================
  assign gnt_b = gnt & {32{~busy}};

  always @(posedge clk_ni) begin
    if (rst_ni) begin
      req <= #`dh 0;
    end
    else if (i_enable) begin

    // 16-bit counters
    req[0]  <= #`dh gnt_b[0]  ? 1'b0 : i_il1_trace_hit        ? 1'b1 : req[0];
    req[1]  <= #`dh gnt_b[1]  ? 1'b0 : i_il1_trace_miss       ? 1'b1 : req[1];
    req[2]  <= #`dh gnt_b[2]  ? 1'b0 : i_dl1_trace_hit        ? 1'b1 : req[2];
    req[3]  <= #`dh gnt_b[3]  ? 1'b0 : i_dl1_trace_miss       ? 1'b1 : req[3];
    req[4]  <= #`dh gnt_b[4]  ? 1'b0 : i_l2c_trace_ihit       ? 1'b1 : req[4];
    req[5]  <= #`dh gnt_b[5]  ? 1'b0 : i_l2c_trace_imiss      ? 1'b1 : req[5];
    req[6]  <= #`dh gnt_b[6]  ? 1'b0 : i_l2c_trace_dhit       ? 1'b1 : req[6];
    req[7]  <= #`dh gnt_b[7]  ? 1'b0 : i_l2c_trace_dmiss      ? 1'b1 : req[7];
    req[8]  <= #`dh gnt_b[8]  ? 1'b0 : i_ctl_trace_cpu_io     ? 1'b1 : req[8];
    req[9]  <= #`dh gnt_b[9]  ? 1'b0 : i_ctl_trace_net_io     ? 1'b1 : req[9];
    req[10] <= #`dh gnt_b[10] ? 1'b0 : i_mni_trace_op_local   ? 1'b1 : req[10];
    req[11] <= #`dh gnt_b[11] ? 1'b0 : i_mni_trace_op_remote  ? 1'b1 : req[11];
    req[12] <= #`dh gnt_b[12] ? 1'b0 : i_mni_trace_read_hit   ? 1'b1 : req[12];
    req[13] <= #`dh gnt_b[13] ? 1'b0 : i_mni_trace_read_miss  ? 1'b1 : req[13];
    req[14] <= #`dh gnt_b[14] ? 1'b0 : i_mni_trace_write_hit  ? 1'b1 : req[14];
    req[15] <= #`dh gnt_b[15] ? 1'b0 : i_mni_trace_write_miss ? 1'b1 : req[15];
    req[16] <= #`dh gnt_b[16] ? 1'b0 : i_mni_trace_vc0_in     ? 1'b1 : req[16];
    req[17] <= #`dh gnt_b[17] ? 1'b0 : i_mni_trace_vc0_out    ? 1'b1 : req[17];
    req[18] <= #`dh gnt_b[18] ? 1'b0 : i_mni_trace_vc1_in     ? 1'b1 : req[18];
    req[19] <= #`dh gnt_b[19] ? 1'b0 : i_mni_trace_vc1_out    ? 1'b1 : req[19];
    req[20] <= #`dh gnt_b[20] ? 1'b0 : i_mni_trace_vc2_in     ? 1'b1 : req[20];
    req[21] <= #`dh gnt_b[21] ? 1'b0 : i_mni_trace_vc2_out    ? 1'b1 : req[21];

    // 32-bit counter
    req[22] <= #`dh gnt_b[22] ? 1'b0 : cpu_trace_energy       ? 1'b1 : req[22];
    req[23] <= #`dh gnt_b[23] ? 1'b0 : carry[0]               ? 1'b1 : req[23];

    // 16-bit shadow-copy counter (will have rd_adr = 30 and will copy)
    req[24] <= #`dh gnt_b[24] ? 1'b0 : copy_power             ? 1'b1 : req[24];

    // Hidden 16-bit, special use (when 31: wr_adr = 30 and will zero it)
    req[30] <= #`dh gnt_b[30] ? 1'b0 : cpu_trace_energy       ? 1'b1 : req[30];
    req[31] <= #`dh gnt_b[31] ? 1'b0 : copy_power             ? 1'b1 : req[31];

    end
  end

  // ==========================================================================
  // Request priority encoding & grant generation
  // ==========================================================================
  PriorEnf # (
    .N_log          ( 5 )
  ) i0_prior_enf (
    .In             ( req ),
    .Out            ( gnt ),
    .Mask           ( ),
    .OneDetected    ( trc_wen_d )
  );

  encoder # (
    .N_log          ( 5 )
  ) i0_encoder (
    .i_in           ( gnt ),
    .o_out          ( trc_adr_d )
  );

  always @(posedge clk_ni) begin
    if (~busy) begin
      trc_adr_q     <= #`dh trc_adr_d;
      trc_wen_q     <= #`dh trc_wen_d;
      is22_q        <= #`dh gnt[22];
      is24_q        <= #`dh gnt[24];
      is31_q        <= #`dh gnt[31];
    end
  end

  // ==========================================================================
  // Trace counter writes
  // ==========================================================================
  assign new_val = mem_out + ((busy | ~is22_q) ? 1'b1 : 
                                                 cpu_trace_energy_val);

  assign trc_val = (is24_q)                ? mem_out :
                   (is31_q)                ? 16'b0 :
                   (~new_val[16] | is22_q) ? new_val[15:0] :
                                             mem_out;

  assign carry = is22_q & {1{new_val[16]}};


  // ==========================================================================
  // MNI register read & 32-bit carry bypass
  // ==========================================================================
  assign o_dt_out = ((rd_adr == 5'd23) & (req[23] | carry[0])) ? new_val[15:0] :
                                                                 mem_out;
endmodule
