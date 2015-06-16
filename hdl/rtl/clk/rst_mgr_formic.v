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
// Abstract      : Reset manager for Formic Spartan-6
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rst_mgr_formic.v,v $
// CVS revision  : $Revision: 1.6 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rst_mgr_formic # (

  // Parameters
  parameter NEED_GTP0 = 1,
  parameter NEED_GTP1 = 1

) (

  // Reset triggering events
  input         rst_btn_n,
  input         i_bctl_rst_soft,
  input         i_bctl_rst_hard,
  input         i_mdm_rst_sys,

  // Clock inputs from clock manager
  input         clk_cpu,
  input         clk_mc,
  input         clk_ni,
  input         clk_drp,
  input         clk_xbar,
  input         clk_sram,
  input         clk_ddr,
  input         clk_gtp0,
  input         clk_gtp1,

  // Calibration inputs from clock manager
  input         i_plls_locked,
  input         i_dig_dcms_locked,
  input         i_gtp0_dcm_locked,
  input         i_gtp1_dcm_locked,

  // Calibration inputs from DDR and GTPs
  input         i_ddr_ctl_calib_done,
  output reg    o_ddr_boot_req,
  input         i_ddr_boot_done,
  input         i_gtp0_ref_clk_locked,
  input         i_gtp1_ref_clk_locked,
  input         i_gtp0_init_done,
  input         i_gtp1_init_done,

  // Clock enable outputs to clock manager
  output        clk_mc_en,
  output        clk_ni_en,
  output        clk_ddr_en,
  output        clk_xbar_en,

  // Reset outputs to clock manager
  output        rst_plls,
  output        rst_dig_dcms,
  output        rst_ext_clkouts,
  output        rst_gtp_phy,
  output        rst_gtp0_dcm,
  output        rst_gtp1_dcm,

  // Resets to in-FPGA logic (complete, treated as false paths)
  output        rst_mc,
  output        rst_ni,
  output        rst_ddr,
  output        rst_xbar,

  // Incomplete reset outputs for in-block reset generation
  output        rst_master_assert,
  output        rst_drp_deassert,
  output        rst_sram_deassert,
  output        rst_gtp0_deassert,
  output        rst_gtp1_deassert
);

  // ==========================================================================
  // Hard and soft resets
  // ==========================================================================

  // Hard reset must be at least 10ns long for correct PLL reset
  reg        bctl_rst_hard;
  reg [15:0] bctl_rst_hard_del; /* synthesis syn_keep */
  integer    i;

  always @(*) begin
    bctl_rst_hard_del[0] <= #`dh i_bctl_rst_hard;
    for (i = 1; i < 16; i = i + 1) begin
      bctl_rst_hard_del[i] <= #`dh bctl_rst_hard_del[i-1];
    end
    bctl_rst_hard = | bctl_rst_hard_del;
  end

  // Master resets
  wire rst_hard = ~rst_btn_n | bctl_rst_hard;
  wire rst_soft = i_bctl_rst_soft | i_mdm_rst_sys;
  wire rst_hard_or_soft = rst_hard | rst_soft;

  assign rst_master_assert = rst_hard;

  // Boot ROM control. On a hard reset, we boot. The o_ddr_boot_req drops after
  // that. If a soft reset occurs, it is not asserted again (and we don't
  // boot).
  reg ddr_boot_done_prv;

  always @(posedge clk_mc or posedge rst_hard) begin
    if (rst_hard) begin
      o_ddr_boot_req    <= #`dh 1'b1;
    end
    else begin
      ddr_boot_done_prv <= #`dh i_ddr_boot_done;
      if (i_ddr_boot_done & ~ddr_boot_done_prv) begin
        o_ddr_boot_req <= #`dh 1'b0;
      end
    end
  end


  // ==========================================================================
  // Asynchronous resets to clock manager & GTPs
  // ==========================================================================

  // We reset first the PLLs
  assign rst_plls = rst_hard;

  // Then the digital DCMs
  assign rst_dig_dcms = ~i_plls_locked;
  assign rst_ext_clkouts = ~i_plls_locked;

  // Then the GTP physical blocks
  assign rst_gtp_phy = ~i_dig_dcms_locked;

  // Then the GTP DCMs
  assign rst_gtp0_dcm = ~i_gtp0_ref_clk_locked;
  assign rst_gtp1_dcm = ~i_gtp1_ref_clk_locked;


  // ==========================================================================
  // Reset deassertion conditions
  // ==========================================================================

  // All clocks are valid
  wire clocking_complete = i_plls_locked &
                           i_dig_dcms_locked & 
                           ((NEED_GTP0 == 1) ? i_gtp0_dcm_locked : 1'b1) &
                           ((NEED_GTP1 == 1) ? i_gtp1_dcm_locked : 1'b1);

  // DDR and GTP initialization complete
  wire init_complete     = clocking_complete &
                           i_ddr_ctl_calib_done &
                           ((NEED_GTP0 == 1) ? i_gtp0_init_done : 1'b1) & 
                           ((NEED_GTP1 == 1) ? i_gtp1_init_done : 1'b1);

  // Boot complete
  wire boot_complete     = init_complete &
                           i_ddr_boot_done;


  // Assignment to clock domains
  assign rst_drp_deassert  = clocking_complete;

  wire   rst_ddr_deassert  = init_complete;
  wire   rst_xbar_deassert = init_complete;
  assign rst_sram_deassert = init_complete;
  assign rst_gtp0_deassert = init_complete;
  assign rst_gtp1_deassert = init_complete;
  wire   rst_ni_deassert   = init_complete;
  wire   rst_mc_deassert   = init_complete;


  // ==========================================================================
  // Reset synchronizers which stop their clocks to deassert the reset.
  // These resets must be declared as false paths in the UCF and as such
  // do not need additional synchronization, registers, reset trees, etc.
  // ==========================================================================

  // clk_mc reset synchronizer
  rst_sync_clockstop # (
    .DEASSERT_CLOCK_CYCLES  ( 4 ),
    .STOP_CLOCK_CYCLES      ( 4 )
  ) i0_rst_sync_clockstop (
    .clk_always_on          ( clk_cpu ),
    .clk                    ( clk_mc ),
    .clk_en                 ( clk_mc_en ),
    .rst_async              ( rst_hard_or_soft ),
    .deassert               ( rst_mc_deassert ),
    .rst                    ( rst_mc )
  );

  // clk_ni reset synchronizer
  rst_sync_clockstop # (
    .DEASSERT_CLOCK_CYCLES  ( 4 ),
    .STOP_CLOCK_CYCLES      ( 1 )
  ) i1_rst_sync_clockstop (
    .clk_always_on          ( clk_cpu ),
    .clk                    ( clk_ni ),
    .clk_en                 ( clk_ni_en ),
    .rst_async              ( rst_hard_or_soft ),
    .deassert               ( rst_ni_deassert ),
    .rst                    ( rst_ni )
  );

  // clk_ddr reset synchronizer
  rst_sync_clockstop # (
    .DEASSERT_CLOCK_CYCLES  ( 4 ),
    .STOP_CLOCK_CYCLES      ( 1 )
  ) i2_rst_sync_clockstop (
    .clk_always_on          ( clk_cpu ),
    .clk                    ( clk_ddr ),
    .clk_en                 ( clk_ddr_en ),
    .rst_async              ( rst_hard_or_soft ),
    .deassert               ( rst_ddr_deassert ),
    .rst                    ( rst_ddr )
  );

  // clk_xbar reset synchronizer
  rst_sync_clockstop # (
    .DEASSERT_CLOCK_CYCLES  ( 4 ),
    .STOP_CLOCK_CYCLES      ( 1 )
  ) i3_rst_sync_clockstop (
    .clk_always_on          ( clk_cpu ),
    .clk                    ( clk_xbar ),
    .clk_en                 ( clk_xbar_en ),
    .rst_async              ( rst_hard_or_soft ),
    .deassert               ( rst_xbar_deassert ),
    .rst                    ( rst_xbar )
  );


endmodule
