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
// Abstract      : IL1 & DL1 tags logic
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: l1_tags.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module l1_tags # (
  
  // Number of ways: 64 or 128 selection
  parameter         NR_WAYS_IS_128 = 0

) (

  // Clock & reset
  input             clk,
  input             rst,

  // Access interface
  input             i_acc_req,
  input      [31:0] i_acc_adr,
  input             i_acc_wen,
  output            o_acc_ack,
  output            o_acc_hit,
  output            o_acc_way,

  // Maintenance (clear) interface
  input             i_clr_req,
  output            o_clr_ack,

  // Invalidation interface
  input             i_inv_req,
  input      [31:0] i_inv_adr,
  output            o_inv_ack
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  localparam TAG_MSB   = (NR_WAYS_IS_128 == 0) ? 20 : 19,
             INDEX_MSB = (NR_WAYS_IS_128 == 0) ?  5 :  6;


  wire [INDEX_MSB:0] way_adr;
  wire [INDEX_MSB:0] index;
  wire               inv_index_sel;
  wire   [TAG_MSB:0] req_tag;
  
  reg  [INDEX_MSB:0] clr_cnt_q;
  wire [INDEX_MSB:0] clr_cnt_d;

  wire               hit0;
  wire               hit1;
  wire               hit;

  wire               clr_cnt_end;
  
  wire         [3:0] way0_wr_en;
  wire        [31:0] way0_wr_data;
  wire        [31:0] way0_rd_data;

  wire         [3:0] way1_wr_en;
  wire        [31:0] way1_wr_data;
  wire        [31:0] way1_rd_data;

  wire               way0_ctl_wen;
  wire               way0_tag_wen;
  wire               way0_wr_lru;
  wire               way0_wr_valid;
  wire               way0_rd_lru;
  wire               way0_rd_valid;
  wire   [TAG_MSB:0] way0_rd_tag;

  wire               way1_ctl_wen;
  wire               way1_tag_wen;
  wire               way1_wr_lru;
  wire               way1_wr_valid;
  wire               way1_rd_lru;
  wire               way1_rd_valid;
  wire   [TAG_MSB:0] way1_rd_tag;

  wire               way0_install;
  wire               way0_invalid;
  wire               way1_install;
  wire               way1_invalid;

  
  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle      = 7'b000_0001,
             InvMatch  = 7'b000_0010,
             AccMatch  = 7'b000_0100,
             UpdateLRU = 7'b000_1000,
             Install   = 7'b001_0000,
             Clear     = 7'b010_0000,
             Invalid   = 7'b100_0000;

  reg  [6:0] state_d;
  reg  [6:0] state_q;

  // synthesis translate_off
  reg [256:0] L1TagStateString;
  always @(state_q) begin
    case (state_q)
      Idle      : L1TagStateString = "Idle";
      InvMatch  : L1TagStateString = "InvMatch";
      AccMatch  : L1TagStateString = "AccMatch";
      UpdateLRU : L1TagStateString = "UpdateLRU";
      Install   : L1TagStateString = "Install";
      Clear     : L1TagStateString = "Clear";
      Invalid   : L1TagStateString = "Invalid";
      default   : L1TagStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (i_acc_req)
            state_d = AccMatch;
          else if (i_inv_req) 
            state_d = InvMatch;
          else if (i_clr_req)
            state_d = Clear;
          else
            state_d = Idle;
        end

      AccMatch: begin
          if (hit)
            state_d = UpdateLRU;
          else if (i_acc_wen)
            // Write miss does not allocate
            state_d = Idle;
          else
            state_d = Install;
        end

      InvMatch: begin
          if (hit)
            state_d = Invalid;
          else
            state_d = Idle;
        end

      UpdateLRU: begin
          state_d = Idle;
        end

      Install: begin
          state_d = Idle;
        end

      Clear: begin
          if (clr_cnt_end)
            state_d = Idle;
          else
            state_d = Clear;
        end

      Invalid: begin
          state_d = Idle;
        end

      default: begin
          state_d = Idle;
        end

    endcase
  end


  // ==========================================================================
  // Tags memory (single BRAM, partitioned in two ways)
  // ==========================================================================
  generate
    if (NR_WAYS_IS_128 == 0) begin

      // 64 ways version:

      xil_mem_dp_512x32 i0_xil_mem_dp_512x32 (

        // Way #0
        .clk0       ( clk ),
        .i_en0      ( 1'b1 ),
        .i_adr0     ( {3'b000, way_adr} ),
        .i_wen0     ( way0_wr_en ),
        .i_wdata0   ( way0_wr_data ),
        .o_rdata0   ( way0_rd_data ),

        // Way #1
        .clk1       ( clk ),
        .i_en1      ( 1'b1 ),
        .i_adr1     ( {3'b100, way_adr} ),
        .i_wen1     ( way1_wr_en ),
        .i_wdata1   ( way1_wr_data ),
        .o_rdata1   ( way1_rd_data )
      );

      assign way0_rd_lru   = way0_rd_data[28];
      assign way0_rd_valid = way0_rd_data[24];
      assign way0_rd_tag   = way0_rd_data[20:0];

      assign way0_wr_data = {3'b0, way0_wr_lru, 
                             3'b0, way0_wr_valid, 
                             3'b0, i_acc_adr[31:11]};
      assign way0_wr_en   = {way0_ctl_wen, {3{way0_tag_wen}}};

      assign way1_rd_lru   = way1_rd_data[28];
      assign way1_rd_valid = way1_rd_data[24];
      assign way1_rd_tag   = way1_rd_data[20:0];

      assign way1_wr_data = {3'b0, way1_wr_lru, 
                             3'b0, way1_wr_valid, 
                             3'b0, i_acc_adr[31:11]};
      assign way1_wr_en   = {way1_ctl_wen, {3{way1_tag_wen}}};

    end
    else begin

      // 128 ways version:

      xil_mem_dp_512x32 i0_xil_mem_dp_512x32 (

        // Way #0
        .clk0       ( clk ),
        .i_en0      ( 1'b1 ),
        .i_adr0     ( {2'b00, way_adr} ),
        .i_wen0     ( way0_wr_en ),
        .i_wdata0   ( way0_wr_data ),
        .o_rdata0   ( way0_rd_data ),

        // Way #1
        .clk1       ( clk ),
        .i_en1      ( 1'b1 ),
        .i_adr1     ( {2'b10, way_adr} ),
        .i_wen1     ( way1_wr_en ),
        .i_wdata1   ( way1_wr_data ),
        .o_rdata1   ( way1_rd_data )
      );

      assign way0_rd_lru   = way0_rd_data[28];
      assign way0_rd_valid = way0_rd_data[24];
      assign way0_rd_tag   = way0_rd_data[19:0];

      assign way0_wr_data = {3'b0, way0_wr_lru, 
                             3'b0, way0_wr_valid, 
                             4'b0, i_acc_adr[31:12]};
      assign way0_wr_en   = {way0_ctl_wen, {3{way0_tag_wen}}};

      assign way1_rd_lru   = way1_rd_data[28];
      assign way1_rd_valid = way1_rd_data[24];
      assign way1_rd_tag   = way1_rd_data[19:0];

      assign way1_wr_data = {3'b0, way1_wr_lru, 
                             3'b0, way1_wr_valid, 
                             4'b0, i_acc_adr[31:12]};
      assign way1_wr_en   = {way1_ctl_wen, {3{way1_tag_wen}}};

    end
  endgenerate


  // ==========================================================================
  // Datapath
  // ==========================================================================


  // Address index
  assign inv_index_sel = (state_d == InvMatch) |
                         (state_q == InvMatch) |
                         (state_q == Invalid);
  generate
    if (NR_WAYS_IS_128 == 0)
      assign index = inv_index_sel ? i_inv_adr[10:5] : i_acc_adr[10:5];
    else
      assign index = inv_index_sel ? i_inv_adr[11:5] : i_acc_adr[11:5];
  endgenerate
  
  assign way_adr = (state_q == Clear) ? clr_cnt_q : index;


  // Tag matching
  generate
    if (NR_WAYS_IS_128 == 0)
      assign req_tag = inv_index_sel ? i_inv_adr[31:11] : i_acc_adr[31:11];
    else
      assign req_tag = inv_index_sel ? i_inv_adr[31:12] : i_acc_adr[31:12];
  endgenerate

  assign hit0 = ((state_q == InvMatch) || (state_q == AccMatch)) & 
                (way0_rd_tag == req_tag) & (way0_rd_valid);
  assign hit1 = ((state_q == InvMatch) || (state_q == AccMatch)) & 
                (way1_rd_tag == req_tag) & (way1_rd_valid);
  assign hit = hit0 | hit1;
  
  
  // Install/invalidation enables
  assign way0_install = (state_d == Install) & 
                              (~way0_rd_valid |
                               (way0_rd_valid & way1_rd_valid & way0_rd_lru));
  assign way1_install = (state_d == Install) & 
                              ((way0_rd_valid & ~way1_rd_valid) |
                               (way0_rd_valid & way1_rd_valid & way1_rd_lru));

  assign way0_invalid = (state_d == Invalid) & hit0;
  assign way1_invalid = (state_d == Invalid) & hit1;


  // LRU bit meaning: 0 = most recent (or just installed)
  //                  1 = least recent, candidate for replacement

  // Way #0 logic
  assign way0_wr_lru   = (state_d == Install) ? ~way0_install :
                                                ~hit0; // (UpdateLRU)

  assign way0_wr_valid = (state_q == Clear) ? 1'b0 : 
                         (way0_install)     ? 1'b1 :
                         (way1_install)     ? way0_rd_valid :
                         (way0_invalid)     ? 1'b0 :
                                              way0_rd_valid; // (UpdateLRU)

  assign way0_ctl_wen  = (state_q == Clear) | 
                         (state_d == Install) | 
                         way0_invalid |
                         (state_d == UpdateLRU);

  assign way0_tag_wen  = way0_install;


  // Way #1 logic
  assign way1_wr_lru   = (state_d == Install) ? ~way1_install :
                                                ~hit1; // (UpdateLRU)

  assign way1_wr_valid = (state_q == Clear) ? 1'b0 : 
                         (way1_install)     ? 1'b1 :
                         (way0_install)     ? way1_rd_valid :
                         (way1_invalid)     ? 1'b0 :
                                              way1_rd_valid; // (UpdateLRU)

  assign way1_ctl_wen  = (state_q == Clear) | 
                         (state_d == Install) | 
                         way1_invalid |
                         (state_d == UpdateLRU);

  assign way1_tag_wen  = way1_install;


  // Clear counter
  generate
    if (NR_WAYS_IS_128 == 0) begin

      assign clr_cnt_d = (state_q == Idle)  ? 6'd0 :
                         (state_q == Clear) ? clr_cnt_q + 1'b1 :
                                              clr_cnt_q;

      assign clr_cnt_end = (clr_cnt_q == 6'd63);

    end
    else begin

      assign clr_cnt_d = (state_q == Idle)  ? 7'd0 :
                         (state_q == Clear) ? clr_cnt_q + 1'b1 :
                                              clr_cnt_q;

      assign clr_cnt_end = (clr_cnt_q == 7'd127);

    end
  endgenerate


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk) begin
    if (rst) begin
      state_q           <= #`dh Idle;
    end
    else begin
      state_q           <= #`dh state_d;
    end
  end

  always @(posedge clk) begin
    clr_cnt_q           <= #`dh clr_cnt_d;
  end
  
  // ==========================================================================
  // Outputs
  // ==========================================================================
  assign o_clr_ack = (state_q == Clear) & clr_cnt_end;
  
  assign o_inv_ack = ((state_q == InvMatch) & ~hit) |
                     (state_q == Invalid);
  
  assign o_acc_ack = (state_q == AccMatch);

  assign o_acc_hit = hit;
  
  assign o_acc_way = (hit0)           ? 1'b0 :  // Hits
                     (hit1)           ? 1'b1 :
                     (way0_install)   ? 1'b0 :  // Misses
                                        1'b1;

endmodule
