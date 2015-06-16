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
// Abstract      : Dual-port memory 512x36
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xil_mem_dp_512x36.v,v $
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

module xil_mem_dp_512x36 (
  input             clk0,
  input             i_en0,
  input       [3:0] i_wen0,
  input       [8:0] i_adr0,
  input      [35:0] i_wdata0,
  output     [35:0] o_rdata0,
  input             clk1,
  input             i_en1,
  input       [3:0] i_wen1,
  input       [8:0] i_adr1,
  input      [35:0] i_wdata1,
  output     [35:0] o_rdata1
);
  
  // ==========================================================================
  // Simulation model
  // ==========================================================================
  // synthesis translate_off

  reg [35:0] mem_q [0:511];
  reg  [8:0] adr0_q;
  reg  [8:0] adr1_q;

  // Port 0
  always @(posedge clk0) begin
    if (i_en0) begin

      adr0_q <= #`dh i_adr0;

      if (i_wen0[0]) begin
        mem_q[i_adr0][8:0] <= #`dh i_wdata0[8:0];
      end

      if (i_wen0[1]) begin
        mem_q[i_adr0][17:9] <= #`dh i_wdata0[17:9];
      end

      if (i_wen0[2]) begin
        mem_q[i_adr0][26:18] <= #`dh i_wdata0[26:18];
      end

      if (i_wen0[3]) begin
        mem_q[i_adr0][35:27] <= #`dh i_wdata0[35:27];
      end
    end
  end

  assign o_rdata0 = mem_q[adr0_q];


  // Port 1
  always @(posedge clk1) begin
    if (i_en1) begin

      adr1_q <= #`dh i_adr1;

      if (i_wen1[0]) begin
        mem_q[i_adr1][8:0] <= #`dh i_wdata1[8:0];
      end

      if (i_wen1[1]) begin
        mem_q[i_adr1][17:9] <= #`dh i_wdata1[17:9];
      end

      if (i_wen1[2]) begin
        mem_q[i_adr1][26:18] <= #`dh i_wdata1[26:18];
      end

      if (i_wen1[3]) begin
        mem_q[i_adr1][35:27] <= #`dh i_wdata1[35:27];
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

    wire [31:0] wdata0 = {i_wdata0[34:27], i_wdata0[25:18], 
                          i_wdata0[16:9],  i_wdata0[7:0]};
    wire [31:0] wdata1 = {i_wdata1[34:27], i_wdata1[25:18], 
                          i_wdata1[16:9],  i_wdata1[7:0]};
    wire  [3:0] wpar0  = {i_wdata0[35],    i_wdata0[26], 
                          i_wdata0[17],    i_wdata0[8]};
    wire  [3:0] wpar1  = {i_wdata1[35],    i_wdata1[26], 
                          i_wdata1[17],    i_wdata1[8]};

    wire  [3:0] wen0   = i_wen0;
    wire  [3:0] wen1   = i_wen1;

    `define MEM_WIDTH 36
    wire [13:0] adr0   = {i_adr0, 5'b0};
    wire [13:0] adr1   = {i_adr1, 5'b0};

    wire [31:0] rdata0;
    wire [31:0] rdata1;
    wire  [3:0] rpar0;
    wire  [3:0] rpar1;

    assign o_rdata0 = {rpar0[3], rdata0[31:24], rpar0[2], rdata0[23:16],
                       rpar0[1], rdata0[15:8],  rpar0[0], rdata0[7:0]};
    assign o_rdata1 = {rpar1[3], rdata1[31:24], rpar1[2], rdata1[23:16],
                       rpar1[1], rdata1[15:8],  rpar1[0], rdata1[7:0]};

  `endif

  `ifdef SYNTH_SPARTAN6

    RAMB16BWER # (
      .DATA_WIDTH_A     ( `MEM_WIDTH ),
      .DATA_WIDTH_B     ( `MEM_WIDTH ),
      .DOA_REG          ( 0 ),
      .DOB_REG          ( 0 ),
      .EN_RSTRAM_A      ( 0 ),
      .EN_RSTRAM_B      ( 0 ),
      .SIM_DEVICE       ( "SPARTAN6" ),
      .SIM_COLLISION_CHECK ( "GENERATE_X_ONLY" ),
      .WRITE_MODE_A     ( "WRITE_FIRST" ),
      .WRITE_MODE_B     ( "WRITE_FIRST" )
    ) i0_RAMB16BWER (
      .CLKA             ( clk0 ),
      .CLKB             ( clk1 ),
      .ENA              ( i_en0 ),
      .ENB              ( i_en1 ),
      .REGCEA           ( 1'b1 ),
      .REGCEB           ( 1'b1 ),
      .RSTA             ( 1'b0 ),
      .RSTB             ( 1'b0 ),
      .ADDRA            ( adr0 ),
      .ADDRB            ( adr1 ),
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

  `ifdef SYNTH_VIRTEX5

    RAMB36 # (
      .WRITE_WIDTH_A    ( `MEM_WIDTH ),
      .WRITE_WIDTH_B    ( `MEM_WIDTH ),
      .READ_WIDTH_A     ( `MEM_WIDTH ),
      .READ_WIDTH_B     ( `MEM_WIDTH ),
      .DOA_REG          ( 0 ),
      .DOB_REG          ( 0 ),
      .WRITE_MODE_A     ( "WRITE_FIRST" ),
      .WRITE_MODE_B     ( "WRITE_FIRST" )
    ) i0_RAMB36 (
      .CASCADEOUTLATA   ( ),
      .CASCADEOUTLATB   ( ),
      .CASCADEOUTREGA   ( ),
      .CASCADEOUTREGB   ( ),
      .CASCADEINLATA    ( ),
      .CASCADEINLATB    ( ),
      .CASCADEINREGA    ( ),
      .CASCADEINREGB    ( ),
      .CLKA             ( clk0 ),
      .CLKB             ( clk1 ),
      .ENA              ( i_en0 ),
      .ENB              ( i_en1 ),
      .REGCEA           ( 1'b1 ),
      .REGCEB           ( 1'b1 ),
      .SSRA             ( 1'b0 ),
      .SSRB             ( 1'b0 ),
      .ADDRA            ( {2'b0, adr0} ), // +1 bit (unused cascade mode),
      .ADDRB            ( {2'b0, adr1} ), // +1 bit (double than spartan-6)
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
