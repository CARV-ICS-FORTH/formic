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
// Abstract      : Clock manager for Formic Spartan-6
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: clk_mgr_formic.v,v $
// CVS revision  : $Revision: 1.7 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module clk_mgr_formic # (

  // Parameters
  parameter NEED_GTP0 = 1,  // 1: Provide clk_gtp0 clk_gtp0_2x, 0: disable them
  parameter NEED_GTP1 = 1,  // 1: Provide clk_gtp1 clk_gtp1_2x, 0: disable them
  
                            // For all NEED_SRAM? parameters below:
                            // 1: provide sram?_clk through its sram?_clk_fb
                            // 2: provide sram?_clk directly from clk_sram
                            // 0: disable sram?_clk altogether
  parameter NEED_SRAM0 = 1,
  parameter NEED_SRAM1 = 1,
  parameter NEED_SRAM2 = 1,

  parameter NEED_DDR   = 1, // 1: Provide clk_mcb* and o_mcb*, 0: disable them
  parameter NEED_REF_CLK = 0, // 1: Provide clk_ref, 0: disable it
  parameter NEED_MC    = 1, // 1: Provide clk_mc, 0: disable it
  parameter NEED_NI    = 1  // 1: Provide clk_ni, 0: disable it

) (

  // External reference clock inputs
  input         ref_clk_p,
  input         ref_clk_n,
  
  // Reset inputs
  input         rst_plls,
  input         rst_dig_dcms,
  input         rst_ext_clkouts,
  input         rst_gtp0_dcm,
  input         rst_gtp1_dcm,

  // Calibration done outputs
  output        o_plls_locked,
  output        o_dig_dcms_locked,
  output        o_gtp0_dcm_locked,
  output        o_gtp1_dcm_locked,

  // Clocks outputs for in-FPGA logic
  output        clk_cpu,
  output        clk_mc,
  output        clk_ni,
  output        clk_ddr,
  output        clk_sram,
  output        clk_xbar,

  // Always-on 200-MHz reference clock
  output        clk_ref,

  // Clock enables from reset manager
  input         clk_mc_en,
  input         clk_ni_en,
  input         clk_ddr_en,
  input         clk_xbar_en,
  
  // Clock interface to Xilinx DDR2 controller
  output        clk_mcb,
  output        clk_mcb_180,
  output        clk_drp,
  output        o_mcb_ce_0,
  output        o_mcb_ce_90,

  // Clock interface to Xilinx GTP banks
  input         gtp0_ref_clk_unbuf,
  output        clk_gtp0,
  output        clk_gtp0_2x,
  input         gtp1_ref_clk_unbuf,
  output        clk_gtp1,
  output        clk_gtp1_2x,

  // Clock outputs to external pins
  output        sram0_clk,
  output        sram1_clk,
  output        sram2_clk,

  // Feedback clock inputs from external pins
  input         sram0_clk_fb,
  input         sram1_clk_fb,
  input         sram2_clk_fb
);


  // ==========================================================================
  // Wires needed for conditional generation
  // ==========================================================================
  wire ref_clk_buf;
  wire ref_clk_unbuf;
  
  wire dcm0_locked;
  wire dcm1_locked;
  wire dcm2_locked;

  wire ddr_ctl_pll_locked;

  wire sram0_clk_buf;
  wire sram0_clk_unbuf;
  wire sram1_clk_buf;
  wire sram1_clk_unbuf;
  wire sram2_clk_buf;
  wire sram2_clk_unbuf;

  wire gtp0_clk_usr;
  wire gtp0_clk_usr2;
  wire gtp1_clk_usr;
  wire gtp1_clk_usr2;


  // ==========================================================================
  // PLLs and DDR clocks
  // ==========================================================================

  // Input 200 MHz reference clock
  generate
    if (NEED_REF_CLK == 1) begin

      IBUFDS i0_ibufds ( 
        .I                      ( ref_clk_p ),
        .IB                     ( ref_clk_n ),
        .O                      ( ref_clk_unbuf )
      );

      BUFG i14_bufg (
        .I                      ( ref_clk_unbuf ),
        .O                      ( ref_clk_buf )
      );

      assign clk_ref = ref_clk_buf;

    end
    
    else begin

      IBUFDS i0_ibufds ( 
        .I                      ( ref_clk_p ),
        .IB                     ( ref_clk_n ),
        .O                      ( ref_clk_buf )
      );

      assign clk_ref = 1'b0;

    end
  endgenerate


  // PLL to generate DDR2 clocks
  PLL_BASE # (
    .BANDWIDTH              ( "HIGH" ),
    .CLK_FEEDBACK           ( "CLKFBOUT" ),
    .COMPENSATION           ( "SYSTEM_SYNCHRONOUS" ),
    .DIVCLK_DIVIDE          ( 1 ),
    .CLKFBOUT_MULT          ( 4 ),
    .CLKFBOUT_PHASE         ( 0.000 ),
    .CLKOUT0_DIVIDE         ( 1 ),
    .CLKOUT0_PHASE          ( 0.000 ),
    .CLKOUT0_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT1_DIVIDE         ( 1 ),
    .CLKOUT1_PHASE          ( 180.000 ),
    .CLKOUT1_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT2_DIVIDE         ( 8 ),
    .CLKOUT2_PHASE          ( 0.000 ),
    .CLKOUT2_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT3_DIVIDE         ( 1 ), 
    .CLKOUT3_PHASE          ( 0.000 ),
    .CLKOUT3_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT4_DIVIDE         ( 1 ),
    .CLKOUT4_PHASE          ( 0.000 ),
    .CLKOUT4_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT5_DIVIDE         ( 1 ),
    .CLKOUT5_PHASE          ( 0.000 ),
    .CLKOUT5_DUTY_CYCLE     ( 0.500 ),
    .CLKIN_PERIOD           ( 5.0 ),
    .REF_JITTER             ( 0.001 )
  ) i0_pll_base (
    .CLKIN                  ( ref_clk_buf ),
    .CLKOUT0                ( clk_800_unbuf ),     // 800 MHz to MCB PLL
    .CLKOUT1                ( clk_800_180_unbuf ), // 800 MHz, 180 deg shift
    .CLKOUT2                ( clk_100_unbuf ),     // 100 MHz (drp/ddr clock)
    .CLKOUT3                ( ),
    .CLKOUT4                ( ), 
    .CLKOUT5                ( ), 
    .LOCKED                 ( pll0_locked ),
    .RST                    ( rst_plls ),
    .CLKFBOUT               ( pll0_fb ),
    .CLKFBIN                ( pll0_fb )
  );

  generate
    if (NEED_DDR == 1) begin

      // NOTE:
      //
      // * clk_800_unbuf and clk_800_180_unbuf must be CLKOUT0 and CLKOUT1 of a
      //   PLL, because only these 2 lines can connect to MCB PLLs.
      // 
      // * clk_drp must be "phase synchronized" to these 2 clocks, i.e.
      //   generated by the same PLL.

      // DDR MCB PLL driver
      BUFPLL_MCB i0_bufpll_mcb (
        .IOCLK0                 ( clk_mcb ),
        .IOCLK1                 ( clk_mcb_180 ),
        .LOCKED                 ( pll0_locked ),
        .GCLK                   ( clk_drp ),
        .SERDESSTROBE0          ( o_mcb_ce_0 ),
        .SERDESSTROBE1          ( o_mcb_ce_90 ),
        .PLLIN0                 ( clk_800_unbuf ),
        .PLLIN1                 ( clk_800_180_unbuf ),
        .LOCK                   ( ddr_ctl_pll_locked )
      );

    end

    else begin

      assign ddr_ctl_pll_locked = 1'b1;
      assign clk_mcb = 1'b0;
      assign clk_mcb_180 = 1'b0;
      assign o_mcb_ce_0 = 1'b0;
      assign o_mcb_ce_90 = 1'b0;

    end
  endgenerate

  // PLL to generate intra-FPGA logic clocks
  PLL_BASE # (
    .BANDWIDTH              ( "HIGH" ),
    .CLK_FEEDBACK           ( "CLKFBOUT" ),
    .COMPENSATION           ( "SYSTEM_SYNCHRONOUS" ),
    .DIVCLK_DIVIDE          ( 1 ),
    .CLKFBOUT_MULT          ( 8 ),
    .CLKFBOUT_PHASE         ( 0.000 ),
    .CLKOUT0_DIVIDE         ( 10 ),
    .CLKOUT0_PHASE          ( 0.000 ),
    .CLKOUT0_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT1_DIVIDE         ( 20 ),
    .CLKOUT1_PHASE          ( 0.000 ),
    .CLKOUT1_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT2_DIVIDE         ( 80 ),
    .CLKOUT2_PHASE          ( 0.000 ),
    .CLKOUT2_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT3_DIVIDE         ( 5 ), 
    .CLKOUT3_PHASE          ( 0.000 ),
    .CLKOUT3_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT4_DIVIDE         ( 1 ),
    .CLKOUT4_PHASE          ( 0.000 ),
    .CLKOUT4_DUTY_CYCLE     ( 0.500 ),
    .CLKOUT5_DIVIDE         ( 1 ),
    .CLKOUT5_PHASE          ( 0.000 ),
    .CLKOUT5_DUTY_CYCLE     ( 0.500 ),
    .CLKIN_PERIOD           ( 10.0 ),
    .REF_JITTER             ( 0.001 )
  ) i1_pll_base (
    .CLKIN                  ( clk_drp ),
    .CLKOUT0                ( clk_80_unbuf ),    //  80 MHz (ni clock)
    .CLKOUT1                ( clk_40_unbuf ),    //  40 MHz (mc clock)
    .CLKOUT2                ( clk_10_unbuf ),    //  10 MHz (cpu clock)
    .CLKOUT3                ( clk_160_unbuf ),   // 160 MHz (xbar/sram clock)
    .CLKOUT4                ( ),
    .CLKOUT5                ( ),    
    .LOCKED                 ( pll1_locked ),
    .RST                    ( ~pll0_locked ),
    .CLKFBOUT               ( pll1_fb ),
    .CLKFBIN                ( pll1_fb )
  );

  
  // ==========================================================================
  // The three SRAM clocks and their feedbacks
  // ==========================================================================
  generate
    if (NEED_SRAM0 == 1) begin

      // SRAM0 clock (160 MHz, deskewed with SRAM0 PCB trace delay)
      DCM_SP # (
        .CLKDV_DIVIDE          ( 2.000 ),
        .CLKFX_DIVIDE          ( 1 ),
        .CLKFX_MULTIPLY        ( 2 ),
        .CLKIN_DIVIDE_BY_2     ( 1'b0 ),
        .CLKIN_PERIOD          ( 6.25 ),
        .CLKOUT_PHASE_SHIFT    ( "NONE" ),
        .CLK_FEEDBACK          ( "1X" ),
        .DESKEW_ADJUST         ( "SYSTEM_SYNCHRONOUS" ),
        .PHASE_SHIFT           ( 0 ),
        .STARTUP_WAIT          ( 1'b0 )
      )
      i0_dcm (
        .CLKIN                 ( clk_sram ),
        .CLKFB                 ( dcm0_fb ),
        .CLK0                  ( sram0_clk_unbuf ),
        .CLK90                 ( ),
        .CLK180                ( ),
        .CLK270                ( ),
        .CLK2X                 ( ),
        .CLK2X180              ( ),
        .CLKFX                 ( ),
        .CLKFX180              ( ),
        .CLKDV                 ( ),
        .PSCLK                 (1'b0),
        .PSEN                  (1'b0),
        .PSINCDEC              (1'b0),
        .DSSEN                 (1'b0),
        .STATUS                ( ),
        .PSDONE                ( ),
        .LOCKED                ( dcm0_locked ),
        .RST                   ( rst_dig_dcms )
      );

      ODDR2 i0_oddr2 (
        .C0                     ( sram0_clk_buf ),
        .C1                     ( ~sram0_clk_buf ),
        .D0                     ( 1'b1 ),
        .D1                     ( 1'b0 ),
        .CE                     ( 1'b1 ),
        .S                      ( 1'b0 ),
        .R                      ( 1'b0 ),
        .Q                      ( sram0_clk )
      );

      IBUFG i0_ibufg (
        .I                      ( sram0_clk_fb ),
        .O                      ( sram0_clk_fb_buf )
      );

      BUFIO2FB i0_bufio2fb (
        .I                      ( sram0_clk_fb_buf ),
        .O                      ( dcm0_fb )
      );

    end
    else if (NEED_SRAM0 == 2) begin

      assign dcm0_locked = 1'b1;
      
      ODDR2 i0_oddr2 (
        .C0                     ( clk_sram ),
        .C1                     ( ~clk_sram ),
        .D0                     ( 1'b1 ),
        .D1                     ( 1'b0 ),
        .CE                     ( 1'b1 ),
        .S                      ( 1'b0 ),
        .R                      ( 1'b0 ),
        .Q                      ( sram0_clk )
      );
    end
    else begin

      assign dcm0_locked = 1'b1;
      assign sram0_clk = 1'b0;

    end
  endgenerate


  generate
    if (NEED_SRAM1 == 1) begin

      // SRAM1 clock (160 MHz, deskewed with SRAM1 PCB trace delay)
      DCM_SP # (
        .CLKDV_DIVIDE          ( 2.000 ),
        .CLKFX_DIVIDE          ( 1 ),
        .CLKFX_MULTIPLY        ( 2 ),
        .CLKIN_DIVIDE_BY_2     ( 1'b0 ),
        .CLKIN_PERIOD          ( 6.25 ),
        .CLKOUT_PHASE_SHIFT    ( "NONE" ),
        .CLK_FEEDBACK          ( "1X" ),
        .DESKEW_ADJUST         ( "SYSTEM_SYNCHRONOUS" ),
        .PHASE_SHIFT           ( 0 ),
        .STARTUP_WAIT          ( 1'b0 )
      )
      i1_dcm (
        .CLKIN                 ( clk_sram ),
        .CLKFB                 ( dcm1_fb ),
        .CLK0                  ( sram1_clk_unbuf ),
        .CLK90                 ( ),
        .CLK180                ( ),
        .CLK270                ( ),
        .CLK2X                 ( ),
        .CLK2X180              ( ),
        .CLKFX                 ( ),
        .CLKFX180              ( ),
        .CLKDV                 ( ),
        .PSCLK                 (1'b0),
        .PSEN                  (1'b0),
        .PSINCDEC              (1'b0),
        .DSSEN                 (1'b0),
        .STATUS                ( ),
        .PSDONE                ( ),
        .LOCKED                ( dcm1_locked ),
        .RST                   ( rst_dig_dcms )
      );

      ODDR2 i1_oddr2 (
        .C0                     ( sram1_clk_buf ),
        .C1                     ( ~sram1_clk_buf ),
        .D0                     ( 1'b1 ),
        .D1                     ( 1'b0 ),
        .CE                     ( 1'b1 ),
        .S                      ( 1'b0 ),
        .R                      ( 1'b0 ),
        .Q                      ( sram1_clk )
      );

      IBUFG i1_ibufg (
        .I                      ( sram1_clk_fb ),
        .O                      ( sram1_clk_fb_buf )
      );

      BUFIO2FB i1_bufio2fb (
        .I                      ( sram1_clk_fb_buf ),
        .O                      ( dcm1_fb )
      );

    end
    else if (NEED_SRAM1 == 2) begin

      assign dcm1_locked = 1'b1;
      
      ODDR2 i1_oddr2 (
        .C0                     ( clk_sram ),
        .C1                     ( ~clk_sram ),
        .D0                     ( 1'b1 ),
        .D1                     ( 1'b0 ),
        .CE                     ( 1'b1 ),
        .S                      ( 1'b0 ),
        .R                      ( 1'b0 ),
        .Q                      ( sram1_clk )
      );
    end
    else begin

      assign dcm1_locked = 1'b1;
      assign sram1_clk = 1'b0;

    end
  endgenerate


  generate
    if (NEED_SRAM2 == 1) begin

      // SRAM2 clock (160 MHz, deskewed with SRAM2 PCB trace delay)
      DCM_SP # (
        .CLKDV_DIVIDE          ( 2.000 ),
        .CLKFX_DIVIDE          ( 1 ),
        .CLKFX_MULTIPLY        ( 2 ),
        .CLKIN_DIVIDE_BY_2     ( 1'b0 ),
        .CLKIN_PERIOD          ( 6.25 ),
        .CLKOUT_PHASE_SHIFT    ( "NONE" ),
        .CLK_FEEDBACK          ( "1X" ),
        .DESKEW_ADJUST         ( "SYSTEM_SYNCHRONOUS" ),
        .PHASE_SHIFT           ( 0 ),
        .STARTUP_WAIT          ( 1'b0 )
      )
      i2_dcm (
        .CLKIN                 ( clk_sram ),
        .CLKFB                 ( dcm2_fb ),
        .CLK0                  ( sram2_clk_unbuf ),
        .CLK90                 ( ),
        .CLK180                ( ),
        .CLK270                ( ),
        .CLK2X                 ( ),
        .CLK2X180              ( ),
        .CLKFX                 ( ),
        .CLKFX180              ( ),
        .CLKDV                 ( ),
        .PSCLK                 (1'b0),
        .PSEN                  (1'b0),
        .PSINCDEC              (1'b0),
        .DSSEN                 (1'b0),
        .STATUS                ( ),
        .PSDONE                ( ),
        .LOCKED                ( dcm2_locked ),
        .RST                   ( rst_dig_dcms )
      );

      ODDR2 i2_oddr2 (
        .C0                     ( sram2_clk_buf ),
        .C1                     ( ~sram2_clk_buf ),
        .D0                     ( 1'b1 ),
        .D1                     ( 1'b0 ),
        .CE                     ( 1'b1 ),
        .S                      ( 1'b0 ),
        .R                      ( 1'b0 ),
        .Q                      ( sram2_clk )
      );

      IBUFG i2_ibufg (
        .I                      ( sram2_clk_fb ),
        .O                      ( sram2_clk_fb_buf )
      );

      BUFIO2FB i2_bufio2fb (
        .I                      ( sram2_clk_fb_buf ),
        .O                      ( dcm2_fb )
      );

    end
    else if (NEED_SRAM2 == 2) begin

      assign dcm2_locked = 1'b1;
      
      ODDR2 i2_oddr2 (
        .C0                     ( clk_sram ),
        .C1                     ( ~clk_sram ),
        .D0                     ( 1'b1 ),
        .D1                     ( 1'b0 ),
        .CE                     ( 1'b1 ),
        .S                      ( 1'b0 ),
        .R                      ( 1'b0 ),
        .Q                      ( sram2_clk )
      );
    end
    else begin

      assign dcm2_locked = 1'b1;
      assign sram2_clk = 1'b0;

    end
  endgenerate



  // ==========================================================================
  // Top side GTP bank (4 links)
  // ==========================================================================

  generate
    if (NEED_GTP0 == 1) begin

      // Buffer from GTP to DCM
      BUFIO2 # (
        .DIVIDE                 ( 1 ),
        .DIVIDE_BYPASS          ( 1'b1 )
      ) i0_bufio2 (
        .I                      ( gtp0_ref_clk_unbuf ),
        .DIVCLK                 ( gtp0_ref_clk ),
        .IOCLK                  ( ),
        .SERDESSTROBE           ( )
      );

      // Top analog reference clock DCM
      DCM_SP # (
        .CLKDV_DIVIDE          ( 2.000 ),
        .CLKFX_DIVIDE          ( 1 ),
        .CLKFX_MULTIPLY        ( 2 ),
        .CLKIN_DIVIDE_BY_2     ( 1'b0 ),
        .CLKIN_PERIOD          ( 6.667 ),
        .CLKOUT_PHASE_SHIFT    ( "NONE" ),
        .CLK_FEEDBACK          ( "1X" ),
        .DESKEW_ADJUST         ( "SOURCE_SYNCHRONOUS" ),
        .PHASE_SHIFT           ( 0 ),
        .STARTUP_WAIT          ( 1'b0 )
      )
      i3_dcm (
        .CLKIN                 ( gtp0_ref_clk ),
        .CLKFB                 ( gtp0_clk_usr2 ),
        .CLK0                  ( gtp0_clk_usr2 ),
        .CLK90                 ( ),
        .CLK180                ( ),
        .CLK270                ( ),
        .CLK2X                 ( gtp0_clk_usr ),
        .CLK2X180              ( ),
        .CLKFX                 ( ),
        .CLKFX180              ( ),
        .CLKDV                 ( ),
        .PSCLK                 (1'b0),
        .PSEN                  (1'b0),
        .PSINCDEC              (1'b0),
        .DSSEN                 (1'b0),
        .STATUS                ( ),
        .PSDONE                ( ),
        .LOCKED                ( o_gtp0_dcm_locked ),
        .RST                   ( rst_gtp0_dcm )
      );
    end
    else begin
      assign o_gtp0_dcm_locked = 1'b1;
    end
  endgenerate


  // ==========================================================================
  // Bottom side GTP bank (4 links)
  // ==========================================================================

  generate
    if (NEED_GTP0 == 1) begin

      // Buffer from GTP to DCM
      BUFIO2 # (
        .DIVIDE                 ( 1 ),
        .DIVIDE_BYPASS          ( 1'b1 )
      ) i1_bufio2 (
        .I                      ( gtp1_ref_clk_unbuf ),
        .DIVCLK                 ( gtp1_ref_clk ),
        .IOCLK                  ( ),
        .SERDESSTROBE           ( )
      );

      // Bottom analog reference clock DCM
      DCM_SP # (
        .CLKDV_DIVIDE          ( 2.000 ),
        .CLKFX_DIVIDE          ( 1 ),
        .CLKFX_MULTIPLY        ( 2 ),
        .CLKIN_DIVIDE_BY_2     ( 1'b0 ),
        .CLKIN_PERIOD          ( 6.667 ),
        .CLKOUT_PHASE_SHIFT    ( "NONE" ),
        .CLK_FEEDBACK          ( "1X" ),
        .DESKEW_ADJUST         ( "SOURCE_SYNCHRONOUS" ),
        .PHASE_SHIFT           ( 0 ),
        .STARTUP_WAIT          ( 1'b0 )
      )
      i4_dcm (
        .CLKIN                 ( gtp1_ref_clk ),
        .CLKFB                 ( gtp1_clk_usr2 ),
        .CLK0                  ( gtp1_clk_usr2 ),
        .CLK90                 ( ),
        .CLK180                ( ),
        .CLK270                ( ),
        .CLK2X                 ( gtp1_clk_usr ),
        .CLK2X180              ( ),
        .CLKFX                 ( ),
        .CLKFX180              ( ),
        .CLKDV                 ( ),
        .PSCLK                 (1'b0),
        .PSEN                  (1'b0),
        .PSINCDEC              (1'b0),
        .DSSEN                 (1'b0),
        .STATUS                ( ),
        .PSDONE                ( ),
        .LOCKED                ( o_gtp1_dcm_locked ),
        .RST                   ( rst_gtp1_dcm )
      );
    end
    else begin
      assign o_gtp1_dcm_locked = 1'b1;
    end
  endgenerate


  // ==========================================================================
  // Global clock lines for logic clocks
  // ==========================================================================


  // These two are placed as a pair (have same IN0/IN1 sources, inverted)
  BUFGMUX i0_bufgmux (
    .I0                     ( 1'b0 ),
    .I1                     ( clk_160_unbuf ),
    .S                      ( clk_xbar_en ),
    .O                      ( clk_xbar )
  );

  BUFGMUX i1_bufgmux (
    .I0                     ( clk_160_unbuf ),
    .I1                     ( 1'b0 ),
    .S                      ( 1'b0 ),
    .O                      ( clk_sram )
  );


  // These two are placed as a pair (have same IN0/IN1 sources, inverted)
  BUFGMUX i2_bufgmux (
    .I0                     ( 1'b0 ),
    .I1                     ( clk_100_unbuf ),
    .S                      ( clk_ddr_en ),
    .O                      ( clk_ddr )
  );

  BUFGMUX i3_bufgmux (
    .I0                     ( clk_100_unbuf ),
    .I1                     ( 1'b0 ),
    .S                      ( 1'b0 ),
    .O                      ( clk_drp )
  );


  // This takes up two BUFG spaces
  generate
    if (NEED_NI == 1) begin

      BUFGCE i4_bufgce (
        .I                      ( clk_80_unbuf ),
        .CE                     ( clk_ni_en ),
        .O                      ( clk_ni )
      );

    end
    else begin

      assign clk_ni = 1'b0;

    end
  endgenerate

  
  // This takes up two BUFG spaces
  generate
    if (NEED_MC == 1) begin

      BUFGCE i5_bufgce (
        .I                      ( clk_40_unbuf ),
        .CE                     ( clk_mc_en ),
        .O                      ( clk_mc )
      );

    end
    else begin

      assign clk_mc = 1'b0;

    end
  endgenerate



  // The rest take up only a single BUFG space each
  BUFG i6_bufg (
    .I                      ( clk_10_unbuf ),
    .O                      ( clk_cpu )
  );
  
  generate
    if (NEED_SRAM0 == 1) begin

      BUFG i7_bufg (
        .I                      ( sram0_clk_unbuf ),
        .O                      ( sram0_clk_buf )
      );
    end
  endgenerate

  generate
    if (NEED_SRAM1 == 1) begin

      BUFG i8_bufg (
        .I                      ( sram1_clk_unbuf ),
        .O                      ( sram1_clk_buf )
      );
    end
  endgenerate

  generate
    if (NEED_SRAM2 == 1) begin

      BUFG i9_bufg (
        .I                      ( sram2_clk_unbuf ),
        .O                      ( sram2_clk_buf )
      );
    end
  endgenerate

  generate
    if (NEED_GTP0 == 1) begin

      BUFG i10_bufg (
        .I                      ( gtp0_clk_usr2 ),
        .O                      ( clk_gtp0 )
      );

      BUFG i11_bufg (
        .I                      ( gtp0_clk_usr ),
        .O                      ( clk_gtp0_2x )
      );
    end
    else begin
      assign clk_gtp0    = 1'b0;
      assign clk_gtp0_2x = 1'b0;
    end
  endgenerate

  generate
    if (NEED_GTP1 == 1) begin

      BUFG i12_bufg (
        .I                      ( gtp1_clk_usr2 ),
        .O                      ( clk_gtp1 )
      );

      BUFG i13_bufg (
        .I                      ( gtp1_clk_usr ),
        .O                      ( clk_gtp1_2x )
      );
    end
    else begin
      assign clk_gtp1    = 1'b0;
      assign clk_gtp1_2x = 1'b0;
    end
  endgenerate



  // ==========================================================================
  // Calibration done aggregators
  // ==========================================================================
  assign o_plls_locked = pll0_locked & ddr_ctl_pll_locked & pll1_locked;
  assign o_dig_dcms_locked = dcm0_locked & dcm1_locked & dcm2_locked;

endmodule
