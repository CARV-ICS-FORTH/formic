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
// Abstract      : Dual-port memory 512x16
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xil_mem_dp_512x16.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

// Unfortunately, the synthesizable style we use for single-port memories 
// is not supported for dual-port memories with byte enables (the Virtex-5 XST
// backend), so we work around it.
//
// All xil_mem_dp_* files contain a verilog memory array for simulation
// purposes, which can be initialized and dumped by NCSim. For synthesis,
// the SYNTH_SPARTAN6 or SYNTH_VIRTEX5 macro is defined by the scripts,
// depending on the target device. The verilog code is ignored by XST,
// and the appropriate RAMB* Xilinx block is used instead.
//
// This poses the problem of inconsistent simulation/synthesis for all
// xil_mem_dp_* files, so be aware of this issue if weird behavior is
// encountered.

module xil_mem_dp_512x16 (
  input             clk0,
  input             i_en0,
  input       [1:0] i_wen0,
  input       [8:0] i_adr0,
  input      [15:0] i_wdata0,
  output     [15:0] o_rdata0,
  input             clk1,
  input             i_en1,
  input       [1:0] i_wen1,
  input       [8:0] i_adr1,
  input      [15:0] i_wdata1,
  output     [15:0] o_rdata1
);
  
  // ==========================================================================
  // Simulation model
  // ==========================================================================
  // synthesis translate_off

  reg [15:0] mem_q [0:511];
  reg  [8:0] adr0_q;
  reg  [8:0] adr1_q;

  // Port 0
  always @(posedge clk0) begin
    if (i_en0) begin

      adr0_q <= #`dh i_adr0;

      if (i_wen0[0]) begin
        mem_q[i_adr0][7:0] <= #`dh i_wdata0[7:0];
      end

      if (i_wen0[1]) begin
        mem_q[i_adr0][15:8] <= #`dh i_wdata0[15:8];
      end

    end
  end

  assign o_rdata0 = mem_q[adr0_q];


  // Port 1
  always @(posedge clk1) begin
    if (i_en1) begin

      adr1_q <= #`dh i_adr1;

      if (i_wen1[0]) begin
        mem_q[i_adr1][7:0] <= #`dh i_wdata1[7:0];
      end

      if (i_wen1[1]) begin
        mem_q[i_adr1][15:8] <= #`dh i_wdata1[15:8];
      end

    end
  end

  assign o_rdata1 = mem_q[adr1_q];


  // ==========================================================================
  // Synthesis per-family models
  // ==========================================================================
  // synthesis translate_on

  `ifdef SYNTH_SPARTAN6 
  `define SYNTH_WIRES
  `endif

  `ifdef SYNTH_VIRTEX5
  `define SYNTH_WIRES
  `endif

  `ifdef SYNTH_WIRES

    wire [15:0] wdata0 = i_wdata0;
    wire [15:0] wdata1 = i_wdata1;
    wire  [1:0] wpar0  = 2'b0;
    wire  [1:0] wpar1  = 2'b0;
    wire  [1:0] wen0   = i_wen0;
    wire  [1:0] wen1   = i_wen1;

    `define MEM_WIDTH 18 
    wire [12:0] adr0   = {i_adr0, 4'b0};
    wire [12:0] adr1   = {i_adr1, 4'b0};

    wire [15:0] rdata0;
    wire [15:0] rdata1;
    wire  [1:0] rpar0;
    wire  [1:0] rpar1;

    assign o_rdata0 = rdata0;
    assign o_rdata1 = rdata1;

  `endif

  `ifdef SYNTH_SPARTAN6

    RAMB8BWER # (
      .DATA_WIDTH_A     ( `MEM_WIDTH ),
      .DATA_WIDTH_B     ( `MEM_WIDTH ),
      .DOA_REG          ( 0 ),
      .DOB_REG          ( 0 ),
      .EN_RSTRAM_A      ( 0 ),
      .EN_RSTRAM_B      ( 0 ),
      .SIM_COLLISION_CHECK ( "GENERATE_X_ONLY" ),
      .RAM_MODE         ( "TDP" ),
      .WRITE_MODE_A     ( "WRITE_FIRST" ),
      .WRITE_MODE_B     ( "WRITE_FIRST" )
    ) i0_RAMB8BWER (
      .CLKAWRCLK        ( clk0 ),
      .CLKBRDCLK        ( clk1 ),
      .ENAWREN          ( i_en0 ),
      .ENBRDEN          ( i_en1 ),
      .REGCEA           ( 1'b1 ),
      .REGCEBREGCE      ( 1'b1 ),
      .RSTA             ( 1'b0 ),
      .RSTBRST          ( 1'b0 ),
      .ADDRAWRADDR      ( adr0 ),
      .ADDRBRDADDR      ( adr1 ),
      .WEAWEL           ( wen0 ),
      .WEBWEU           ( wen1 ),
      .DIADI            ( wdata0 ),
      .DIBDI            ( wdata1 ),
      .DIPADIP          ( wpar0 ),
      .DIPBDIP          ( wpar1 ),
      .DOADO            ( rdata0 ),
      .DOBDO            ( rdata1 ),
      .DOPADOP          ( rpar0 ),
      .DOPBDOP          ( rpar1 )
    );

  `endif

  `ifdef SYNTH_VIRTEX5

    RAMB18 # (
      .WRITE_WIDTH_A    ( `MEM_WIDTH ),
      .WRITE_WIDTH_B    ( `MEM_WIDTH ),
      .READ_WIDTH_A     ( `MEM_WIDTH ),
      .READ_WIDTH_B     ( `MEM_WIDTH ),
      .DOA_REG          ( 0 ),
      .DOB_REG          ( 0 ),
      .WRITE_MODE_A     ( "WRITE_FIRST" ),
      .WRITE_MODE_B     ( "WRITE_FIRST" )
    ) i0_RAMB18 (
      .CLKA             ( clk0 ),
      .CLKB             ( clk1 ),
      .ENA              ( i_en0 ),
      .ENB              ( i_en1 ),
      .REGCEA           ( 1'b1 ),
      .REGCEB           ( 1'b1 ),
      .SSRA             ( 1'b0 ),
      .SSRB             ( 1'b0 ),
      .ADDRA            ( {1'b0, adr0} ), // +1 bit (double than spartan-6)
      .ADDRB            ( {1'b0, adr1} ),
      .WEA              ( wen0 ),
      .WEB              ( wen1 ),
      .DIA              ( wdata0 ),
      .DIB              ( wdata1 ),
      .DIPA             ( wpar0 ),
      .DIPB             ( wpar1 ),
      .DOA              ( rdata0 ),
      .DOB              ( rdata1 ),
      .DOPA             ( rpar0 ),
      .DOPB             ( rpar1 )
    );

  `endif

endmodule
