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
// Abstract      : MNI register interface
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: mni_regif.v,v $
// CVS revision  : $Revision: 1.36 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module mni_regif (

  // Clock and reset
  input             clk_ni,
  input             rst_ni,

  // CTL Registers Interface
  output     [19:0] o_ctl_reg_adr,
  output            o_ctl_reg_valid,
  output            o_ctl_reg_wen,
  output            o_ctl_reg_from_cpu,
  output      [1:0] o_ctl_reg_ben,
  output     [15:0] o_ctl_reg_wdata,
  output      [2:0] o_ctl_reg_rlen,
  input             i_ctl_reg_stall,
  input      [15:0] i_ctl_reg_resp_rdata,
  input             i_ctl_reg_resp_valid,
  input             i_ctl_reg_block,
  input             i_ctl_reg_unblock,

  // in interface
  input             i_in_valid,
  output            o_in_stall,
  input      [15:0] i_in_data,
  output            o_in_resp_valid,
  output     [15:0] o_in_resp_data,

  // miss interface
  input             i_miss_valid,
  output            o_miss_stall,
  input      [15:0] i_miss_data,
  output            o_miss_wr_accept,
  output            o_miss_resp_valid,
  output     [15:0] o_miss_resp_data,

  // ack interface
  input             i_ack_valid,
  output            o_ack_stall,
  input      [15:0] i_ack_data
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  wire        block_req_d;
  reg         block_req_q;
  wire        block_write_d;
  reg         block_write_q;
  wire [31:0] unblock_data_d;
  reg  [31:0] unblock_data_q;
  wire        unblock_req_d;
  reg         unblock_req_q;

  wire  [3:0] pr_valid;
  wire        pr_detect;
  wire        serve_in;
  wire        serve_ack;
  wire        serve_miss;
  wire [15:0] inp_data;

  wire        is_write_d;
  reg         is_write_q;
  wire  [5:0] size_d;
  reg   [5:0] size_q;
  wire  [3:0] ben_d;
  reg   [3:0] ben_q;
  wire [19:0] adr_d;
  reg  [19:0] adr_q;
  wire        cnt_end;
  wire [15:0] wdata_d;
  reg  [15:0] wdata_q;

  wire        stall;


  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle         = 11'b00000000001,
             AdrHigh      = 11'b00000000010,
             AdrLow       = 11'b00000000100,
             WrInit       = 11'b00000001000,
             WrData       = 11'b00000010000,
             WrWait       = 11'b00000100000,
             RdCmd        = 11'b00001000000,
             RdDataHigh   = 11'b00010000000,
             RdDataLow    = 11'b00100000000,
             UnblockHigh  = 11'b01000000000,
             UnblockLow   = 11'b10000000000;

  reg  [10:0] state_d;
  reg  [10:0] state_q;

  // synthesis translate_off
  reg [256:0] RegifStateString;
  always @(state_q) begin
    case (state_q)
      Idle         : RegifStateString = "Idle";
      AdrHigh      : RegifStateString = "AdrHigh";
      AdrLow       : RegifStateString = "AdrLow";
      WrInit       : RegifStateString = "WrInit";
      WrData       : RegifStateString = "WrData";
      WrWait       : RegifStateString = "WrWait";
      RdCmd        : RegifStateString = "RdCmd";
      RdDataHigh   : RegifStateString = "RdDataHigh";
      RdDataLow    : RegifStateString = "RdDataLow";
      UnblockHigh  : RegifStateString = "UnblockHigh";
      UnblockLow   : RegifStateString = "UnblockLow";
      default      : RegifStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (unblock_req_q)
            state_d = UnblockHigh;
          else if (~pr_detect)
            state_d = Idle;
          else
            state_d = AdrHigh;
        end

      AdrHigh: begin
          state_d = AdrLow;
        end

      AdrLow: begin
          if (is_write_q) 
            state_d = WrInit;
          else
            state_d = RdCmd;
        end

      WrInit: begin
          if (i_ctl_reg_stall)
            state_d = WrInit;
          else
            state_d = WrData;
        end

      WrData: begin
          if (i_ctl_reg_stall | ~cnt_end)
            state_d = WrData;
          else if (serve_miss)
            state_d = WrWait;
          else
            state_d = Idle;
        end

      WrWait: begin
          state_d = Idle;
        end

      RdCmd: begin
          if (i_ctl_reg_stall)
            state_d = RdCmd;
          else
            state_d = RdDataHigh;
        end

      RdDataHigh: begin
          if (i_ctl_reg_block)
            state_d = Idle;
          else if (i_ctl_reg_resp_valid)
            state_d = RdDataLow;
          else
            state_d = RdDataHigh;
        end

      RdDataLow: begin
          if (i_ctl_reg_resp_valid)
            state_d = Idle;
          else
            state_d = RdDataLow;
        end

      UnblockHigh: begin
          if (block_write_q)
            state_d = Idle;
          else
            state_d = UnblockLow;
        end

      UnblockLow: begin
          state_d = Idle;
        end

      default:
        begin
          state_d = Idle;
        end

    endcase
  end


  // ==========================================================================
  // Datapath
  // ==========================================================================

  // Interface selection
  LdEnPriorEnf #(
    .N_log       ( 2 )
  ) i0_LdEnPriorEnf (
    .Clk         ( clk_ni ),
    .Reset       ( rst_ni ),
    .LdEn        ( (state_q == Idle) & ~unblock_req_q ),
    .In          ( {1'b0, i_in_valid, i_ack_valid, i_miss_valid} ),
    .Out         ( pr_valid ),
    .Mask        ( ),
    .OneDetected ( pr_detect )
  );

  assign serve_in     = pr_valid[2];
  assign serve_ack    = pr_valid[1];
  assign serve_miss   = pr_valid[0];

  assign inp_data = (i_in_data     & {16{serve_in}}) |
                    (i_ack_data    & {16{serve_ack}}) |
                    (i_miss_data   & {16{serve_miss}});

  // Opcode stuff
  assign is_write_d = (state_q == AdrHigh) ? inp_data[4] :
                                             is_write_q;

  assign size_d = (state_q == AdrHigh)     ? inp_data[14:9] :
                  (((state_q == WrInit) |
                    (state_q == WrData)) &
                   ~i_ctl_reg_stall)       ? size_q - 1'b1 :
                                             size_q;

  assign ben_d = (state_q == AdrHigh) ? inp_data[8:5] :
                                        ben_q;

  // Read/write datapath
  assign adr_d = (state_q == AdrHigh)   ? {inp_data[3:0], adr_q[15:0]} :
                 (state_q == AdrLow)    ? {adr_q[19:16], inp_data} :
                 ((state_q == WrData) &
                  ~i_ctl_reg_stall)     ? adr_q + 2'd2 :
                                          adr_q;

  assign cnt_end = (size_q == 6'd0);

  assign wdata_d = inp_data;


  // Blocking
  assign block_req_d   = (i_ctl_reg_block)        ? 1'b1 :
                         (state_q == UnblockHigh) ? 1'b0 :
                                                    block_req_q;
  
  assign block_write_d = (i_ctl_reg_block)        ? is_write_q :
                                                    block_write_q;

  assign unblock_req_d = (i_ctl_reg_unblock)      ? 1'b1 :
                         (state_q == UnblockHigh) ? 1'b0 :
                                                    unblock_req_q;

  assign unblock_data_d[31:16] = (i_ctl_reg_unblock &
                                  ~unblock_req_q)     ? i_ctl_reg_resp_rdata :
                                                        unblock_data_q[31:16];
  assign unblock_data_d[15:0]  = (i_ctl_reg_unblock &
                                   unblock_req_q)     ? i_ctl_reg_resp_rdata :
                                                        unblock_data_q[15:0];



  
  
  // CTL interface
  assign o_ctl_reg_adr      = { adr_q[19:2], 
                                (state_q == RdCmd) ?  adr_q[1] :
                                                     ~adr_q[1], 
                                1'b0};
  assign o_ctl_reg_valid    = (state_q == WrData) | (state_q == RdCmd);
  assign o_ctl_reg_wen      = (state_q == WrData);
  assign o_ctl_reg_from_cpu = serve_miss;
  assign o_ctl_reg_ben      = (adr_q[1]) ? ben_q[3:2] : ben_q[1:0];
  assign o_ctl_reg_wdata    = wdata_q;
  assign o_ctl_reg_rlen     = 3'd1;

  // in/ack/miss stalls
  assign stall = ~((state_q == AdrHigh) |
                   (state_q == AdrLow) |
                   ((state_q == WrInit) & ~i_ctl_reg_stall) |
                   ((state_q == WrData) & ~i_ctl_reg_stall));
                 
  assign o_in_stall   = ~serve_in   | stall;
  assign o_miss_stall = ~serve_miss | stall;
  assign o_ack_stall  = ~serve_ack  | stall;

  // Response to in
  assign o_in_resp_valid   = serve_in & i_ctl_reg_resp_valid;
  assign o_in_resp_data    = i_ctl_reg_resp_rdata;


  // Response to miss
  assign o_miss_resp_valid = (serve_miss & i_ctl_reg_resp_valid) |
                             ((state_q == UnblockHigh) & ~block_write_q) |
                             (state_q == UnblockLow);

  assign o_miss_resp_data  = (state_q == UnblockHigh) ? unblock_data_q[31:16] :
                             (state_q == UnblockLow)  ? unblock_data_q[15:0] :
                                                        i_ctl_reg_resp_rdata;

  assign o_miss_wr_accept  = ((state_q == WrWait) & ~block_req_d) |
                             ((state_q == UnblockHigh) & block_write_q);


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_ni) begin
    if (rst_ni) begin
      state_q           <= #`dh Idle;
      unblock_req_q     <= #`dh 0;
      block_req_q       <= #`dh 0;
    end
    else begin
      state_q           <= #`dh state_d;
      unblock_req_q     <= #`dh unblock_req_d;
      block_req_q       <= #`dh block_req_d;
    end
  end
  
  always @(posedge clk_ni) begin
    unblock_data_q      <= #`dh unblock_data_d;
    block_write_q       <= #`dh block_write_d;
    is_write_q          <= #`dh is_write_d;
    size_q              <= #`dh size_d;
    ben_q               <= #`dh ben_d;
    adr_q               <= #`dh adr_d;
    wdata_q             <= #`dh wdata_d;
  end

endmodule
