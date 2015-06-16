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
// Abstract      : MBS Control (CTL) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: ctl.v,v $
// CVS revision  : $Revision: 1.61 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

`define MBOX_WRITE      4'b1000  
`define MBOX_READ       4'b1001
`define MBOX_DEPTH_READ 4'b1011
`define SLOT_WRITE      4'b1100
`define SLOT_READ       4'b1101
`define SLOT_DEPTH_READ 4'b1111
`define COUNTER_WRITE   4'b0000
`define COUNTER_READ    4'b0001
`define COUNTER_INCR    4'b0010

//
// CTL
//
module ctl # (
   parameter          ARM_MODE = 0
) (
   input        [7:0] i_board_id,
   input        [2:0] i_core_id,
   input              i_cpu_enable_rst_value,
// Clocks and Resets
   input              clk_cpu,
   input              clk_ni,
   input              rst_ni,
   input              rst_mc,
   input              i_boot_done,
// BCTL UART Interface
   input              i_uart_irq,
   output reg         o_uart_irq_clear,
// Timer interface
   input              i_bctl_tmr_drift_fw,  // ???
   input              i_bctl_tmr_drift_bw,  // ???
// CPU Interface
   output reg         o_cpu_interrupt,
   output             rst_cpu,
   input              i_cpu_trace_daccess,
   input       [31:0] i_cpu_trace_inst_adr,
   input       [31:0] i_cpu_trace_data_adr,
   input              i_cpu_trace_energy,
   input        [2:0] i_cpu_trace_energy_val,
// ART Interface
   output      [11:0] o_art_entry0_base,
   output             o_art_entry0_u_flag,
   output      [11:0] o_art_entry1_base,
   output      [11:0] o_art_entry1_end,
   output      [ 4:0] o_art_entry1_flags,
   output             o_art_entry1_valid,
   output      [11:0] o_art_entry2_base,
   output      [11:0] o_art_entry2_end,
   output      [ 4:0] o_art_entry2_flags,
   output             o_art_entry2_valid,
   output      [11:0] o_art_entry3_base,
   output      [11:0] o_art_entry3_end,
   output      [ 4:0] o_art_entry3_flags,
   output             o_art_entry3_valid,
   output      [11:0] o_art_entry4_base,
   output      [11:0] o_art_entry4_end,
   output      [ 4:0] o_art_entry4_flags,
   output             o_art_entry4_valid,
   output             o_art_privileged,
   output reg         o_art_fault_ack,
   input              i_art_perm_fault,
   input              i_art_miss_fault,
   input              i_art_tlb_fault,
// Caches common enable
   output             o_cache_en,
// IL1 Interface
   output reg         o_il1_clear_req,
   input              i_il1_clear_ack,
   input              i_il1_trace_hit,
   input              i_il1_trace_miss,
// DL1 Interface
   output reg         o_dl1_clear_req,
   input              i_dl1_clear_ack,
   input              i_dl1_trace_hit,
   input              i_dl1_trace_miss,
// L2 Interface
   output             o_lru_mode,
   output reg         o_l2c_clear_req,
   output reg         o_l2c_flush_req,
   input              i_l2c_maint_ack,
   output      [ 2:0] o_l2c_epoch,
   output      [ 2:0] o_l2c_min_cpu_ways,
   input              i_l2c_trace_ihit,
   input              i_l2c_trace_imiss,
   input              i_l2c_trace_dhit,
   input              i_l2c_trace_dmiss,
// Board controller trace interface
   output reg         o_bctl_trc_valid,
   output reg   [7:0] o_bctl_trc_data,
// MNI Registers Access Interface
   input       [19:0] i_mni_reg_adr,
   input              i_mni_reg_valid,
   input              i_mni_reg_wen,
   input              i_mni_reg_from_cpu,
   input       [ 1:0] i_mni_reg_ben,
   input       [15:0] i_mni_reg_wdata,
   input       [ 2:0] i_mni_reg_rlen,
   output reg         o_mni_reg_stall,
   output reg  [15:0] o_mni_reg_resp_rdata,
   output reg         o_mni_reg_resp_valid,
   output reg         o_mni_reg_block,
   output reg         o_mni_reg_unblock,
// MNI Operation Interface
   output reg         o_mni_op_valid,
   output reg  [15:0] o_mni_op_data,
   input              i_mni_op_stall,
   input       [ 5:0] i_mni_cpu_fifo_ops,
   input       [ 5:0] i_mni_net_fifo_ops,
// MNI Trace Interface
   input              i_mni_trace_op_local,
   input              i_mni_trace_op_remote,
   input              i_mni_trace_read_hit,
   input              i_mni_trace_read_miss,
   input              i_mni_trace_write_hit,
   input              i_mni_trace_write_miss,
   input              i_mni_trace_vc0_in,
   input              i_mni_trace_vc0_out,
   input              i_mni_trace_vc1_in,
   input              i_mni_trace_vc1_out,
   input              i_mni_trace_vc2_in,
   input              i_mni_trace_vc2_out,
// CMX Interface
   output             o_cmx_valid,
   output      [ 3:0] o_cmx_opcode,
   output      [ 2:0] o_cmx_rd_len,
   output      [ 9:0] o_cmx_cnt_adr,
   output      [15:0] o_cmx_wdata,
   input              i_cmx_block_aborted,
   input              i_cmx_stall,
   input       [15:0] i_cmx_resp_rdata,
   input              i_cmx_resp_valid,
   input              i_cmx_resp_block,
   input              i_cmx_resp_unblock,
   input              i_cmx_int_mbox,
   input              i_cmx_int_cnt,
   input       [ 5:0] i_cmx_int_cnt_adr);
//
localparam MainIdle  = 5'b0_0001,
           ReadH     = 5'b0_0010,
           ReadL     = 5'b0_0100,
           SendMniOp = 5'b0_1000,
           MnIIRQ    = 5'b1_0000;
//
 reg [4:0] CtlState;
// synthesis translate_off
  reg [256:0] CtlStateString;
  always @(CtlState) begin
    case (CtlState)
      MainIdle  : CtlStateString = "MainIdle";
      ReadH     : CtlStateString = "ReadH";
      ReadL     : CtlStateString = "ReadL";
      SendMniOp : CtlStateString = "SendMniOp";
      MnIIRQ    : CtlStateString = "MnIIRQ";
      default   : CtlStateString = "ERROR";
    endcase
  end
  // synthesis translate_on
 reg [19:0] mni_reg_adr_inReg;
 reg [ 1:0] read_cnt;
//
 wire       mni_reg_write = i_mni_reg_wen & i_mni_reg_valid;
 wire [2:0] b_enc_in      = (CtlState==MainIdle) ? i_mni_reg_adr[19:17] : mni_reg_adr_inReg[19:17];
 wire [3:0] r_enc_in      = (CtlState==MainIdle) ? i_mni_reg_adr[5:2]   : mni_reg_adr_inReg[5:2];
 wire       r_enc_hi_zero = (CtlState==MainIdle) ? (i_mni_reg_adr[15:5] == 11'b0) : 
                                                   (mni_reg_adr_inReg[15:5] == 11'b0);
 wire       reg_sel_extra = (CtlState==MainIdle) ? i_mni_reg_adr[5]     : mni_reg_adr_inReg[5];
 wire [7:0] block_sel;
 wire [7:0] reg_sel_raw;
 wire [7:0] reg_sel;
 wire [15:0] Read_Word_Mux;
 wire        read_low;
 wire [31:0] b0_mux,
             b1_mux,
             b2_mux,
             b4_mux,
             b6_mux;
 wire [15:0] b0_mux16,
             b1_mux16,
             b2_mux16,
             b4_mux16,
             b6_mux16;
 wire        MniOpStart;
 wire        interrupt;
 wire        Yield_Block_Clr;
 wire        YieldSet;
//
// MniXCnt
//
reg  [3:0] MniXCnt;
wire [2:0] MniXCntH = MniXCnt[3:1];
 always @(posedge clk_ni) begin
      if(rst_ni)
         MniXCnt<= #`dh 0;
      else if(CtlState==SendMniOp)
         MniXCnt<= #`dh MniXCnt + 4'b1;
 end
 wire MniXCntEnd = (MniXCnt==4'hF);
//
// Main FSM
//
 wire ReadOpStart = i_mni_reg_valid &~i_mni_reg_wen &~o_mni_reg_stall &
                    ~(block_sel[7] | (block_sel[6] &~reg_sel[0])) ;
 wire ReadOpEnd   = (read_cnt==0);
 always @(posedge clk_ni) begin
    if(rst_ni) CtlState <= #`dh MainIdle;
    else begin
       case(CtlState)
//
       MainIdle   : begin
                       if(ReadOpStart)
                            CtlState <= #`dh ReadH;
                       else if(MniOpStart) begin
                            if(i_mni_op_stall)
                                 CtlState <= #`dh MnIIRQ;
                            else CtlState <= #`dh SendMniOp;
                       end
                       else CtlState <= #`dh MainIdle;
                    end
//
       ReadH     : CtlState <= #`dh ReadL;
//
       ReadL     : begin
                       if(ReadOpEnd)
                            CtlState <= #`dh MainIdle;
                       else CtlState <= #`dh ReadH;
                    end
//
       SendMniOp : begin
                      if(MniXCntEnd)
                           CtlState <= #`dh MainIdle;
                      else CtlState <= #`dh SendMniOp;
                   end
//
       MnIIRQ    : CtlState <= #`dh MainIdle;
//
       default   : CtlState <= #`dh MainIdle;
//
       endcase
//
    end
 end
//
// mni_reg_adr Input Register 
//
 wire mni_reg_adr_inReg_Ld  = i_mni_reg_valid &~o_mni_reg_stall;
 always @(posedge clk_ni) begin
    if(rst_ni)  begin
          mni_reg_adr_inReg <= #`dh 0;
          read_cnt          <= #`dh 0;
    end
    else begin
       if(mni_reg_adr_inReg_Ld) begin
          mni_reg_adr_inReg <= #`dh i_mni_reg_adr;
          read_cnt          <= #`dh i_mni_reg_rlen[2:1];
       end
       else begin
          if(CtlState==ReadL)  begin
             read_cnt          <= #`dh read_cnt - 2'b1;
//          if(CtlState==ReadH)
             mni_reg_adr_inReg <= #`dh mni_reg_adr_inReg + 20'h4;
          end
       end
    end
 end
//
// CPU Registers
//
wire wr_b0_00;
wire wr_b0_01;
//
wire wr_b0_10;
wire wr_b0_11;
wire wr_b0_12;
wire wr_b0_13;
//
wire wr_b0_30;
wire wr_b0_31;
wire wr_b0_32;
//
wire        b0_r4_10_set;
reg         b0_r4_0;
reg         reset_b0_r4_0_done;
reg         b0_r4_8;
reg         b0_r4_9;
reg         b0_r4_10;
reg         b0_r4_24;
reg         b0_r4_25;
//
wire [ 4:0] b0_r8_12_8;
wire [ 7:0] b0_r8_23_16;
//
reg  [ 7:0] b0_rC_7_0;
generate
  if (ARM_MODE == 0) begin

    assign wr_b0_00 = block_sel[0] & reg_sel[0] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b0_01 = block_sel[0] & reg_sel[0] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
    assign wr_b0_10 = block_sel[0] & reg_sel[1] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b0_11 = block_sel[0] & reg_sel[1] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b0_12 = block_sel[0] & reg_sel[1] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b0_13 = block_sel[0] & reg_sel[1] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
    assign wr_b0_30 = block_sel[0] & reg_sel[3] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b0_31 = block_sel[0] & reg_sel[3] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b0_32 = block_sel[0] & reg_sel[3] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    //
     always @(posedge clk_ni) begin
        if(rst_ni) begin
            reset_b0_r4_0_done <= #`dh 1'b0;
            b0_r4_0            <= #`dh 1'b0;
            b0_r4_8            <= #`dh 1;
            b0_r4_9            <= #`dh 0;
            b0_r4_10           <= #`dh 0;
            b0_r4_24           <= #`dh 0;
            b0_r4_25           <= #`dh 0;
            b0_rC_7_0          <= #`dh 8'b1111_1111;
        end
        else begin

           if (~reset_b0_r4_0_done) begin
             reset_b0_r4_0_done <= #`dh 1'b1;
             b0_r4_0 <= #`dh i_cpu_enable_rst_value;
           end

           if(wr_b0_10)
              b0_r4_0    <= #`dh  i_mni_reg_wdata[0];
           if(wr_b0_11)
              b0_r4_8    <= #`dh  i_mni_reg_wdata[8];
           if(wr_b0_13) begin
              b0_r4_24   <= #`dh  i_mni_reg_wdata[8];
              b0_r4_25   <= #`dh  i_mni_reg_wdata[9];
           end

           if (interrupt)
              b0_r4_9    <= #`dh  1'b1;
           if(b0_r4_10_set) 
              b0_r4_10   <= #`dh 1'b1;
           else if(wr_b0_11)
              b0_r4_10   <= #`dh  i_mni_reg_wdata[10];
           if(wr_b0_11)
              b0_r4_9    <= #`dh  i_mni_reg_wdata[9];
           if(wr_b0_30)
              b0_rC_7_0  <= #`dh  i_mni_reg_wdata[7:0];
        end
     end
  end
endgenerate




//
/////////////////////////////////////////////////////////////////////////////////
//
// ART Registers
//
/////////////////////////////////////////////////////////////////////////////////
//
wire wr_b1_00;
wire wr_b1_01;
wire wr_b1_03;
//
wire wr_b1_10;
wire wr_b1_11;
wire wr_b1_12;
wire wr_b1_13;
//
wire wr_b1_20;
wire wr_b1_21;
wire wr_b1_22;
wire wr_b1_23;
//
wire wr_b1_30;
wire wr_b1_31;
wire wr_b1_32;
wire wr_b1_33;
//
wire wr_b1_40;
wire wr_b1_41;
wire wr_b1_42;
wire wr_b1_43;
//
reg  [11:0] b1_r0_11_0;
reg         b1_r0_27;
//
reg  [11:0] b1_r4_11_0;
reg  [11:0] b1_r4_23_12;
reg         b1_r4_24;
reg         b1_r4_26;
reg         b1_r4_27;
reg         b1_r4_28;
reg         b1_r4_29;
reg         b1_r4_31;
//
reg  [11:0] b1_r8_11_0;
reg  [11:0] b1_r8_23_12;
reg         b1_r8_24;
reg         b1_r8_26;
reg         b1_r8_27;
reg         b1_r8_28;
reg         b1_r8_29;
reg         b1_r8_31;
//
reg  [11:0] b1_rC_11_0;
reg  [11:0] b1_rC_23_12;
reg         b1_rC_24;
reg         b1_rC_26;
reg         b1_rC_27;
reg         b1_rC_28;
reg         b1_rC_29;
reg         b1_rC_31;
//
reg  [11:0] b1_r10_11_0;
reg  [11:0] b1_r10_23_12;
reg         b1_r10_24;
reg         b1_r10_26;
reg         b1_r10_27;
reg         b1_r10_28;
reg         b1_r10_29;
reg         b1_r10_31;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode

    assign wr_b1_00 = block_sel[1] & reg_sel[0] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_01 = block_sel[1] & reg_sel[0] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b1_03 = block_sel[1] & reg_sel[0] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
    assign wr_b1_10 = block_sel[1] & reg_sel[1] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_11 = block_sel[1] & reg_sel[1] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b1_12 = block_sel[1] & reg_sel[1] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_13 = block_sel[1] & reg_sel[1] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
    assign wr_b1_20 = block_sel[1] & reg_sel[2] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_21 = block_sel[1] & reg_sel[2] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b1_22 = block_sel[1] & reg_sel[2] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_23 = block_sel[1] & reg_sel[2] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
    assign wr_b1_30 = block_sel[1] & reg_sel[3] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_31 = block_sel[1] & reg_sel[3] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b1_32 = block_sel[1] & reg_sel[3] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_33 = block_sel[1] & reg_sel[3] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
    assign wr_b1_40 = block_sel[1] & reg_sel[4] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_41 = block_sel[1] & reg_sel[4] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b1_42 = block_sel[1] & reg_sel[4] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b1_43 = block_sel[1] & reg_sel[4] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
     always @(posedge clk_ni) begin
        if(rst_ni) begin
           b1_r0_11_0  <= #`dh 12'hFFF;
           b1_r0_27    <= #`dh 0; 
    //
           b1_r4_11_0  <= #`dh 12'h0;
           b1_r4_23_12 <= #`dh 12'hFFE;
           b1_r4_24    <= #`dh 1;
           b1_r4_26    <= #`dh 1;
           b1_r4_27    <= #`dh 0;
           b1_r4_28    <= #`dh 1;
           b1_r4_29    <= #`dh 0;
           b1_r4_31    <= #`dh 0;
    //
           b1_r8_11_0  <= #`dh 12'h0;
           b1_r8_23_12 <= #`dh 12'h0;
           b1_r8_24    <= #`dh 0;
           b1_r8_26    <= #`dh 0;
           b1_r8_27    <= #`dh 0;
           b1_r8_28    <= #`dh 0;
           b1_r8_29    <= #`dh 0;
           b1_r8_31    <= #`dh 0;
    //
           b1_rC_11_0  <= #`dh 12'h0;
           b1_rC_23_12 <= #`dh 12'h0;
           b1_rC_24    <= #`dh 0;
           b1_rC_26    <= #`dh 0;
           b1_rC_27    <= #`dh 0;
           b1_rC_28    <= #`dh 0;
           b1_rC_29    <= #`dh 0;
           b1_rC_31    <= #`dh 0;
    //
           b1_r10_11_0  <= #`dh 12'h0;
           b1_r10_23_12 <= #`dh 12'h0;
           b1_r10_24    <= #`dh 0;
           b1_r10_26    <= #`dh 0;
           b1_r10_27    <= #`dh 0;
           b1_r10_28    <= #`dh 0;
           b1_r10_29    <= #`dh 0;
           b1_r10_31    <= #`dh 0;
        end
    //
        else begin
           if(wr_b1_00) 
                b1_r0_11_0[ 7:0]  <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_01)
                b1_r0_11_0[11:8]  <= #`dh i_mni_reg_wdata[11:8];
           if(wr_b1_03)
                b1_r0_27          <= #`dh i_mni_reg_wdata[11];
    //
           if(wr_b1_10) 
                b1_r4_11_0[ 7:0]  <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_11) begin
                b1_r4_11_0[11:8]  <= #`dh i_mni_reg_wdata[11:8];
                b1_r4_23_12[ 3:0] <= #`dh i_mni_reg_wdata[15:12];
           end
           if(wr_b1_12)
                b1_r4_23_12[11:4] <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_13) begin
               b1_r4_23_12[11:4]  <= #`dh i_mni_reg_wdata[7:0];
               b1_r4_24           <= #`dh i_mni_reg_wdata[8];
               b1_r4_26           <= #`dh i_mni_reg_wdata[10];
               b1_r4_27           <= #`dh i_mni_reg_wdata[11];
               b1_r4_28           <= #`dh i_mni_reg_wdata[12];
               b1_r4_29           <= #`dh i_mni_reg_wdata[13];
               b1_r4_31           <= #`dh i_mni_reg_wdata[15];
            end
    //
           if(wr_b1_20) 
                b1_r8_11_0        <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_21) begin
                b1_r8_11_0[11:8]  <= #`dh i_mni_reg_wdata[11:8];
                b1_r8_23_12[ 3:0] <= #`dh i_mni_reg_wdata[15:12];
           end
           if(wr_b1_22)
                b1_r8_23_12[11:4] <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_23) begin
               b1_r8_23_12[11:4]  <= #`dh i_mni_reg_wdata[7:0];
               b1_r8_24           <= #`dh i_mni_reg_wdata[8];
               b1_r8_26           <= #`dh i_mni_reg_wdata[10];
               b1_r8_27           <= #`dh i_mni_reg_wdata[11];
               b1_r8_28           <= #`dh i_mni_reg_wdata[12];
               b1_r8_29           <= #`dh i_mni_reg_wdata[13];
               b1_r8_31           <= #`dh i_mni_reg_wdata[15];
            end
    //
           if(wr_b1_30) 
                b1_rC_11_0        <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_31) begin
                b1_rC_11_0[11:8]  <= #`dh i_mni_reg_wdata[11:8];
                b1_rC_23_12[ 3:0] <= #`dh i_mni_reg_wdata[15:12];
           end
           if(wr_b1_32)
                b1_rC_23_12[11:4] <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_33) begin
               b1_rC_23_12[11:4]  <= #`dh i_mni_reg_wdata[7:0];
               b1_rC_24           <= #`dh i_mni_reg_wdata[8];
               b1_rC_26           <= #`dh i_mni_reg_wdata[10];
               b1_rC_27           <= #`dh i_mni_reg_wdata[11];
               b1_rC_28           <= #`dh i_mni_reg_wdata[12];
               b1_rC_29           <= #`dh i_mni_reg_wdata[13];
               b1_rC_31           <= #`dh i_mni_reg_wdata[15];
            end
    //
           if(wr_b1_40) 
                b1_r10_11_0        <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_41) begin
                b1_r10_11_0[11:8]  <= #`dh i_mni_reg_wdata[11:8];
                b1_r10_23_12[ 3:0] <= #`dh i_mni_reg_wdata[15:12];
           end
           if(wr_b1_42)
                b1_r10_23_12[11:4] <= #`dh i_mni_reg_wdata[ 7:0];
           if(wr_b1_43) begin
               b1_r10_23_12[11:4]  <= #`dh i_mni_reg_wdata[7:0];
               b1_r10_24           <= #`dh i_mni_reg_wdata[8];
               b1_r10_26           <= #`dh i_mni_reg_wdata[10];
               b1_r10_27           <= #`dh i_mni_reg_wdata[11];
               b1_r10_28           <= #`dh i_mni_reg_wdata[12];
               b1_r10_29           <= #`dh i_mni_reg_wdata[13];
               b1_r10_31           <= #`dh i_mni_reg_wdata[15];
            end
    //
        end
    //
     end
    //
     assign o_art_entry0_base   = b1_r0_11_0;
     assign o_art_entry0_u_flag = b1_r0_27;
    //
     assign o_art_entry1_base  = b1_r4_11_0;
     assign o_art_entry1_end   = b1_r4_23_12;
     assign o_art_entry1_flags = {b1_r4_31,b1_r4_29,b1_r4_28,b1_r4_27,b1_r4_26};
     assign o_art_entry1_valid = b1_r4_24;
    //
     assign o_art_entry2_base  = b1_r8_11_0;
     assign o_art_entry2_end   = b1_r8_23_12;
     assign o_art_entry2_flags = {b1_r8_31,b1_r8_29,b1_r8_28,b1_r8_27,b1_r8_26};
     assign o_art_entry2_valid = b1_r8_24;
    //
     assign o_art_entry3_base  = b1_rC_11_0;
     assign o_art_entry3_end   = b1_rC_23_12;
     assign o_art_entry3_flags = {b1_rC_31,b1_rC_29,b1_rC_28,b1_rC_27,b1_rC_26};
     assign o_art_entry3_valid = b1_rC_24;
    //
     assign o_art_entry4_base  = b1_r10_11_0;
     assign o_art_entry4_end   = b1_r10_23_12;
     assign o_art_entry4_flags = {b1_r10_31,b1_r10_29,b1_r10_28,b1_r10_27,b1_r10_26};
     assign o_art_entry4_valid = b1_r10_24;
    //
     assign o_art_privileged = b0_r4_8 | b0_r4_9;

  end
  else begin

    // ARM mode
    assign o_art_entry0_base    = 0;
    assign o_art_entry0_u_flag  = 0;
    assign o_art_entry1_base    = 0;
    assign o_art_entry1_end     = 0;
    assign o_art_entry1_flags   = 0;
    assign o_art_entry1_valid   = 0;
    assign o_art_entry2_base    = 0;
    assign o_art_entry2_end     = 0;
    assign o_art_entry2_flags   = 0;
    assign o_art_entry2_valid   = 0;
    assign o_art_entry3_base    = 0;
    assign o_art_entry3_end     = 0;
    assign o_art_entry3_flags   = 0;
    assign o_art_entry3_valid   = 0;
    assign o_art_entry4_base    = 0;
    assign o_art_entry4_end     = 0;
    assign o_art_entry4_flags   = 0;
    assign o_art_entry4_valid   = 0;
    assign o_art_privileged     = 0;

  end
endgenerate

//
// Cache Registers
//
wire wr_b2_00;
wire wr_b2_02;
wire wr_b2_03;
//
wire wr_b2_10;
wire wr_b2_11;
wire wr_b2_12;
//
wire maint_il1_clear;
wire maint_dl1_clear;
wire maint_l2c_clear;
wire maint_l2c_flush;
//
reg        b2_r0_0;
reg        b2_r0_4;
reg [ 2:0] b2_r0_18_16;
reg [ 2:0] b2_r0_26_24;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode

    assign wr_b2_00 = block_sel[2] & reg_sel[0] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b2_02 = block_sel[2] & reg_sel[0] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b2_03 = block_sel[2] & reg_sel[0] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
    assign wr_b2_10 = block_sel[2] & reg_sel[1] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b2_11 = block_sel[2] & reg_sel[1] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b2_12 = block_sel[2] & reg_sel[1] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    //
     always @(posedge clk_ni) begin
        if(rst_ni) begin
            b2_r0_0     <= #`dh 0;
            b2_r0_4     <= #`dh 0;
            b2_r0_18_16 <= #`dh 0;
            b2_r0_26_24 <= #`dh 4;
        end
        else begin
           if(wr_b2_00) begin
              b2_r0_0 <= #`dh i_mni_reg_wdata[0];
              b2_r0_4 <= #`dh i_mni_reg_wdata[4];
           end
           if(wr_b2_02)
              b2_r0_18_16 <= #`dh i_mni_reg_wdata[2:0];
           if(wr_b2_03)
              b2_r0_26_24 <= #`dh i_mni_reg_wdata[10:8];
        end
     end
    //
    assign maint_il1_clear = wr_b2_10 & i_mni_reg_wdata[0];
    assign maint_dl1_clear = wr_b2_11 & i_mni_reg_wdata[8];
    assign maint_l2c_clear = wr_b2_12 & i_mni_reg_wdata[0];
    assign maint_l2c_flush = wr_b2_12 & i_mni_reg_wdata[1];
    //
     always @(posedge clk_ni) begin
        if(rst_ni) begin
           o_il1_clear_req <= #`dh 0;
           o_dl1_clear_req <= #`dh 0;
           o_l2c_clear_req <= #`dh 0;
           o_l2c_flush_req <= #`dh 0;
        end
        else begin
           if (maint_il1_clear)
             o_il1_clear_req <= #`dh 1'b1;
           else if (i_il1_clear_ack)
             o_il1_clear_req <= #`dh 1'b0;

           if (maint_dl1_clear)
             o_dl1_clear_req <= #`dh 1'b1;
           else if (i_dl1_clear_ack)
             o_dl1_clear_req <= #`dh 1'b0;

           if (maint_l2c_clear)
             o_l2c_clear_req <= #`dh 1'b1;
           else if (i_l2c_maint_ack)
             o_l2c_clear_req <= #`dh 1'b0;

           if (maint_l2c_flush)
             o_l2c_flush_req <= #`dh 1'b1;
           else if (i_l2c_maint_ack)
             o_l2c_flush_req <= #`dh 1'b0;
        end
     end
    //
    assign o_cache_en         = b2_r0_0;
    assign o_lru_mode         = b2_r0_4;
    assign o_l2c_epoch        = b2_r0_18_16;
    assign o_l2c_min_cpu_ways = b2_r0_26_24;
  end
  else begin

    // ARM mode
    assign o_cache_en           = 0;
    assign o_l2c_epoch          = 0;
    assign o_l2c_min_cpu_ways   = 0;
  
    always @(posedge clk_ni) begin
      o_il1_clear_req      <= 0;
      o_dl1_clear_req      <= 0;
      o_l2c_clear_req      <= 0;
      o_l2c_flush_req      <= 0;
    end

  end
endgenerate

//
// Performance Registers
//
wire [15:0] perf_regs_out16;
//
wire perf_enable;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode
    assign perf_enable = b0_r4_24;

  end
  else begin
    
    // ARM mode
    assign perf_enable = 1'b1;

  end
endgenerate

//
ctl_perf_regs iperf_regs(
  //
   .clk_ni                  ( clk_ni ),
   .rst_ni                  ( rst_ni ),
   .clk_cpu                 ( clk_cpu ),
   .rst_cpu                 ( rst_cpu ),
  //
   .i_reg_sel_enc           ( r_enc_in ),
   .i_mni_reg_write         ( mni_reg_write),
   .i_mni_reg_valid         ( i_mni_reg_valid ),
   .i_block_sel             ( block_sel[3] ),
   .i_mni_reg_adr1          ( i_mni_reg_adr[1] ),
   .i_mni_reg_ben           ( i_mni_reg_ben[0] ),
  //
   .i_read_low              ( read_low ),
   .o_dt_out                ( perf_regs_out16 ),
  //
   .i_enable                ( perf_enable ),
   .i_il1_trace_hit         ( i_il1_trace_hit ),
   .i_il1_trace_miss        ( i_il1_trace_miss ),
   .i_dl1_trace_hit         ( i_dl1_trace_hit ),
   .i_dl1_trace_miss        ( i_dl1_trace_miss ),
   .i_l2c_trace_ihit        ( i_l2c_trace_ihit ),
   .i_l2c_trace_imiss       ( i_l2c_trace_imiss ),
   .i_l2c_trace_dhit        ( i_l2c_trace_dhit ),
   .i_l2c_trace_dmiss       ( i_l2c_trace_dmiss ),
   .i_ctl_trace_cpu_io      ( i_mni_reg_valid &  i_mni_reg_from_cpu ),
   .i_ctl_trace_net_io      ( i_mni_reg_valid & ~i_mni_reg_from_cpu ),
   .i_mni_trace_op_local    ( i_mni_trace_op_local ),
   .i_mni_trace_op_remote   ( i_mni_trace_op_remote ),
   .i_mni_trace_read_hit    ( i_mni_trace_read_hit ),
   .i_mni_trace_read_miss   ( i_mni_trace_read_miss ),
   .i_mni_trace_write_hit   ( i_mni_trace_write_hit ),
   .i_mni_trace_write_miss  ( i_mni_trace_write_miss ),
   .i_mni_trace_vc0_in      ( i_mni_trace_vc0_in ),
   .i_mni_trace_vc0_out     ( i_mni_trace_vc0_out ),
   .i_mni_trace_vc1_in      ( i_mni_trace_vc1_in ),
   .i_mni_trace_vc1_out     ( i_mni_trace_vc1_out ),
   .i_mni_trace_vc2_in      ( i_mni_trace_vc2_in ),
   .i_mni_trace_vc2_out     ( i_mni_trace_vc2_out ),
   .i_cpu_trace_energy      ( i_cpu_trace_energy ),
   .i_cpu_trace_energy_val  ( i_cpu_trace_energy_val ));



//
// Timers
//
 reg [31:0] tmr_global;
 always @(posedge clk_cpu) begin
    if(rst_ni)
       tmr_global <= #`dh 0;
    else begin
       if(i_bctl_tmr_drift_fw)
          tmr_global <= #`dh tmr_global + 32'h2;
       else if(~i_bctl_tmr_drift_bw)
          tmr_global <= #`dh tmr_global + 32'h1;
    end
 end
//
wire        wr_b4_10;
wire        wr_b4_11;
wire        wr_b4_12;
wire        wr_b4_13;
//
reg         b4_r4_31;
reg         b4_r4_30;
//
reg  [29:0] b4_r4_29_0;
//
reg [29:0] tmr_local;
reg        tmr_running;
reg        Tmr_IrqSet;
wire       tmr_local_is_zero;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode

    assign wr_b4_10 = block_sel[4] & reg_sel[1] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b4_11 = block_sel[4] & reg_sel[1] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    assign wr_b4_12 = block_sel[4] & reg_sel[1] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    assign wr_b4_13 = block_sel[4] & reg_sel[1] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
     always @(posedge clk_ni) begin
        if(rst_ni) begin
            b4_r4_31      <= #`dh 0;
            b4_r4_30      <= #`dh 0;
        end
        else begin
           if(wr_b4_13) begin
             b4_r4_30          <= #`dh i_mni_reg_wdata[14];
             b4_r4_31          <= #`dh i_mni_reg_wdata[15];
           end
        end
     end
     always @(posedge clk_ni) begin
        if(wr_b4_10)
          b4_r4_29_0[7:0]   <= #`dh i_mni_reg_wdata[7:0];
        if(wr_b4_11)
          b4_r4_29_0[15:8]  <= #`dh i_mni_reg_wdata[15:8];
        if(wr_b4_12)
          b4_r4_29_0[23:16] <= #`dh i_mni_reg_wdata[7:0];
        if(wr_b4_13) begin
          b4_r4_29_0[29:24] <= #`dh i_mni_reg_wdata[13:8];
        end
     end
    //
    pulse_sync i0_pulse_sync (
      .clk_in    ( clk_ni ),
      .rst_in    ( rst_ni ),
      .i_pulse   ( wr_b4_13 ),
      .clk_out   ( clk_cpu ),
      .rst_out   ( rst_cpu ),
      .o_pulse   ( tmr_local_ld ));
    //
    assign tmr_local_is_zero = (tmr_local == 30'b0);
    //
    always @(posedge clk_cpu) begin
      if (rst_cpu) begin
        tmr_running <= #`dh 0;
      end
      else begin
        if (tmr_local_ld) begin
          tmr_running <= #`dh b4_r4_31;
        end
        else if (tmr_running) begin
          if (tmr_local_is_zero) begin
            tmr_running <= #`dh 0;
          end
        end
      end
    end
    always @(posedge clk_cpu) begin
        Tmr_IrqSet  <= #`dh 0;
        if (tmr_local_ld) begin
          tmr_local   <= #`dh b4_r4_29_0;
        end
        else if (tmr_running) begin
          if (tmr_local_is_zero) begin
            Tmr_IrqSet  <= #`dh 1;
          end
          else begin
            tmr_local <= #`dh tmr_local - 1'b1;
          end
        end
    end
  end
endgenerate


//
// MNI Registers
//
wire        SendMniOperation = (CtlState==SendMniOp);
wire [15:0] mni_regs_out16;
wire        imni_reg_sel0 = SendMniOperation ?  (MniXCntH==0) : reg_sel[0];
wire [ 2:0] imni_reg_sel_enc = SendMniOperation ?  MniXCntH : r_enc_in[2:0];
ctl_mni_regs imni_regs(
  //
   .clk_ni               ( clk_ni ),
  //
   .i_reg_sel0           ( imni_reg_sel0 ),
   .i_reg_sel_enc        ( imni_reg_sel_enc ),
   .i_mni_reg_write      ( mni_reg_write),
   .i_block_sel          ( block_sel[5] ),
   .i_reg_sel_extra      ( reg_sel_extra ) ,
   .i_mni_reg_adr1       ( i_mni_reg_adr[1] ),
   .i_mni_reg_ben        ( i_mni_reg_ben ),
   .i_mni_reg_wdata      ( i_mni_reg_wdata ),
  //
   .i_mni_net_fifo_ops   ( i_mni_net_fifo_ops ),
   .i_mni_cpu_fifo_ops   ( i_mni_cpu_fifo_ops ),
  //
   .o_mni_op_start       ( MniOpStart ),
   .i_read_low           ( read_low ),
   .o_dt_out             ( mni_regs_out16 ));

//
// Counter Interrupt Register
//
wire wr_b6_00;
wire wr_b6_01;
wire wr_b6_02;
wire wr_b6_03;
//
reg [5:0] b6_r0_5_0,
          b6_r0_13_8,
          b6_r0_21_16,
          b6_r0_29_24;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode

    wire wr_b6_00 = block_sel[6] & reg_sel[0] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[0];
    wire wr_b6_01 = block_sel[6] & reg_sel[0] & mni_reg_write &~i_mni_reg_adr[1] & i_mni_reg_ben[1];
    wire wr_b6_02 = block_sel[6] & reg_sel[0] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[0];
    wire wr_b6_03 = block_sel[6] & reg_sel[0] & mni_reg_write & i_mni_reg_adr[1] & i_mni_reg_ben[1];
    //
    //
     always @(posedge clk_ni) begin
         if(rst_ni) begin
            b6_r0_5_0   <= #`dh 0;
            b6_r0_13_8  <= #`dh 0;
            b6_r0_21_16 <= #`dh 0;
            b6_r0_29_24 <= #`dh 0;
         end
         else begin
            if(wr_b6_00)
               b6_r0_5_0   <= #`dh i_mni_reg_wdata[5:0];
            if(wr_b6_01)
               b6_r0_13_8  <= #`dh i_mni_reg_wdata[13:8];
            if(wr_b6_02)
               b6_r0_21_16 <= #`dh i_mni_reg_wdata[5:0];
            if(wr_b6_03)
               b6_r0_29_24 <= #`dh i_mni_reg_wdata[13:8];
         end
     end
     assign b6_mux = {2'b0,b6_r0_29_24, 
                      2'b0,b6_r0_21_16,
                      2'b0,b6_r0_13_8,
                      2'b0,b6_r0_5_0};
  end
endgenerate

//
// CMX if
//
wire [ 3:0] cmx_write_adr = (CtlState==MainIdle) ? i_mni_reg_adr[19:16] : mni_reg_adr_inReg[19:16];
wire        mbox_sel      = (cmx_write_adr == 4'hE);
wire        slot_sel      = (cmx_write_adr == 4'hF);
wire        cmx_stall;
wire [ 9:0] cmx_adr    = i_mni_reg_adr[10:1];
reg  [ 3:0] cmx_opcode;
//
always @(*) begin
   cmx_opcode = 4'bx;
//
   if (block_sel[7]) begin
     if (mbox_sel) begin
        if (i_mni_reg_wen)
           cmx_opcode = `MBOX_WRITE;
        else begin
           if(reg_sel[1])
                cmx_opcode = `MBOX_DEPTH_READ;
           else cmx_opcode = `MBOX_READ;
        end
     end
//
     else if (slot_sel) begin
        if (i_mni_reg_wen)
           cmx_opcode = `SLOT_WRITE;
        else begin
           if(reg_sel[1])
                cmx_opcode = `SLOT_DEPTH_READ;
           else cmx_opcode = `SLOT_READ;
        end
     end
   end
//
   else if (block_sel[6]) begin
      if (~i_mni_reg_from_cpu & i_mni_reg_wen)
           cmx_opcode = `COUNTER_INCR;
      else if (i_mni_reg_from_cpu) begin
        if (i_mni_reg_wen)
           cmx_opcode = `COUNTER_WRITE;
        else
           cmx_opcode = `COUNTER_READ;
      end
   end
//
end
//
wire cmx_valid  = (block_sel[7] | (block_sel[6] &~reg_sel[0])) & i_mni_reg_valid;
//
align_clk_sync_2 infifo(.clk_in  (clk_ni),
                        .rst_in  (rst_ni),
                        .i_data  ({cmx_opcode, i_mni_reg_rlen, i_mni_reg_wdata, cmx_adr}),
                        .i_valid (cmx_valid),
                        .o_stall (cmx_stall),
                        .clk_out (clk_ni),
                        .rst_out (rst_ni),
                        .o_data  ({o_cmx_opcode, o_cmx_rd_len, o_cmx_wdata, o_cmx_cnt_adr}),
                        .o_valid (o_cmx_valid),
                        .i_stall (i_cmx_stall));
defparam infifo.N = 33;


//
// MNI Interface
//

wire maint_begin;
wire maint_all_done;
reg  maint_pending;
//
wire ctl_Block_Set;
wire ctl_Block_Clr;
//
wire reg_block;
wire reg_unblock;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode

    assign maint_begin    = maint_il1_clear | maint_dl1_clear | maint_l2c_clear | maint_l2c_flush;
    assign maint_all_done = ~o_il1_clear_req & ~o_dl1_clear_req & ~o_l2c_clear_req & ~o_l2c_flush_req;
    //
    assign ctl_Block_Set = maint_begin;
    assign ctl_Block_Clr = maint_pending & maint_all_done;
    //
    always @(posedge clk_ni) begin
       if(rst_ni) begin
          maint_pending <= #`dh 1'b0;
       end
       else begin
          if (ctl_Block_Set)
             maint_pending <= #`dh 1'b1;
          else if (maint_all_done)
             maint_pending <= #`dh 1'b0;
       end
    end
    //
    assign reg_block   = i_cmx_resp_block   | ctl_Block_Set | YieldSet;
    assign reg_unblock = i_cmx_resp_unblock | ctl_Block_Clr | Yield_Block_Clr;
    //
  end
  else begin

    // ARM mode
    assign reg_block   = i_cmx_resp_block;
    assign reg_unblock = i_cmx_resp_unblock;

  end
endgenerate
//
 wire ctl_read_resp_valid  = ((CtlState==MainIdle) & ReadOpStart) |
                             (CtlState==ReadH) |
                             ((CtlState==ReadL) &~ReadOpEnd);
//
 wire ctl_write_resp_valid =  i_mni_reg_valid & i_mni_reg_wen &~o_mni_reg_stall;
//
 always @(posedge clk_ni) begin
    if(rst_ni) begin
       o_mni_reg_resp_valid <= #`dh 0;
       o_mni_reg_block      <= #`dh 0;
       o_mni_reg_unblock    <= #`dh 0;
       o_mni_reg_stall      <= #`dh 0;
    end
    else begin
       o_mni_reg_resp_valid <= #`dh i_cmx_resp_valid | ctl_read_resp_valid | ctl_write_resp_valid;
       o_mni_reg_block      <= #`dh reg_block;
       o_mni_reg_unblock    <= #`dh reg_unblock;
       o_mni_reg_stall      <= #`dh cmx_stall | 
                                    ((CtlState==MainIdle) & (ReadOpStart | MniOpStart)) | //???
                                    ((CtlState==SendMniOp) &~MniXCntEnd) |
                                    (CtlState==ReadH)  |
                                    ((CtlState==ReadL) &~ReadOpEnd);
    end
 end
 always @(posedge clk_ni) begin
    o_mni_reg_resp_rdata <= #`dh (block_sel[7] | (block_sel[6] &~reg_sel[0])) ?
                                                  i_cmx_resp_rdata :
                                                  Read_Word_Mux;
 end

//
// MNI Operation
//
 always @(posedge clk_ni) begin
    if(rst_ni) o_mni_op_valid <= #`dh 0;
    else begin
       o_mni_op_valid <= #`dh (CtlState==SendMniOp);
    end
 end
 always @(posedge clk_ni) begin
   o_mni_op_data  <= #`dh Read_Word_Mux;
 end
//
// Decoders
//
decoder # (
  .N_log    ( 3 )
) b_dec (
  .o_out    ( block_sel ), 
  .i_in     ( b_enc_in )
);

decoder # (
  .N_log    ( 3 )
) r_dec (
  .o_out    ( reg_sel_raw ), 
  .i_in     ( r_enc_in[2:0] )
);

assign reg_sel = {8{r_enc_hi_zero}} & reg_sel_raw;

//
// Read Operation
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode
    assign b0_mux = {6'b0, b0_r4_25, b0_r4_24, 13'b0, b0_r4_10,
                     b0_r4_9, b0_r4_8, 7'b0, b0_r4_0}        & {32{reg_sel[1]}} |
                    {i_board_id, b0_r8_23_16, 1'b0,
                     2'b0, b0_r8_12_8, 5'b0, i_core_id}      & {32{reg_sel[2]}} |
                    {24'b0, b0_rC_7_0}                       & {32{reg_sel[3]}};
    //
    assign b1_mux = {1'b0, 1'b1, 1'b0, 1'b0, b1_r0_27, 1'b1, 
                      1'b0, 1'b1, b1_r0_11_0, b1_r0_11_0} & {32{reg_sel[0]}} |
                    {b1_r4_31, 1'b0, b1_r4_29, b1_r4_28, b1_r4_27, b1_r4_26,
                      1'b0, b1_r4_24, b1_r4_23_12, b1_r4_11_0} & {32{reg_sel[1]}} |
                    {b1_r8_31, 1'b0, b1_r8_29, b1_r8_28, b1_r8_27, b1_r8_26,
                      1'b0, b1_r8_24, b1_r8_23_12, b1_r8_11_0} & {32{reg_sel[2]}} |
                    {b1_rC_31, 1'b0, b1_rC_29, b1_rC_28, b1_rC_27, b1_rC_26,
                      1'b0, b1_rC_24, b1_rC_23_12, b1_rC_11_0} & {32{reg_sel[3]}} |
                    {b1_r10_31, 1'b0, b1_r10_29, b1_r10_28, b1_r10_27, b1_r10_26,
                      1'b0, b1_r10_24, b1_r10_23_12, b1_r10_11_0} & {32{reg_sel[4]}} ;
    //
    assign b2_mux = {5'b0, b2_r0_26_24, 5'b0, b2_r0_18_16,
                     11'b0, b2_r0_4, 3'b0, b2_r0_0};
    //
    assign b4_mux = {tmr_global}                    & {32{reg_sel[0]}} |
                    {b4_r4_31, b4_r4_30, tmr_local} & {32{reg_sel[1]}};

  end
  else begin

    // ARM mode
    assign b0_mux = {i_board_id, 21'b0, i_core_id}  & {32{reg_sel[2]}};
    assign b1_mux = 32'b0;
    assign b2_mux = 32'b0;
    assign b4_mux = tmr_global;

  end
endgenerate
//
 assign read_low = (CtlState==ReadH) | (SendMniOperation & MniXCnt[0]);
//
 assign b0_mux16 = (read_low) ? b0_mux[15:0] : b0_mux[31:16];
 assign b1_mux16 = (read_low) ? b1_mux[15:0] : b1_mux[31:16];
 assign b2_mux16 = (read_low) ? b2_mux[15:0] : b2_mux[31:16];
 assign b4_mux16 = (read_low) ? b4_mux[15:0] : b4_mux[31:16];
 assign b6_mux16 = (read_low) ? b6_mux[15:0] : b6_mux[31:16];
//
 assign Read_Word_Mux = b0_mux16        & {16{block_sel[0]}} |
                        b1_mux16        & {16{block_sel[1]}} |
                        b2_mux16        & {16{block_sel[2]}} |
                        perf_regs_out16 & {16{block_sel[3]}} |
                        b4_mux16        & {16{block_sel[4]}} |
                        mni_regs_out16  & {16{block_sel[5]}} |
                        b6_mux16        & {16{block_sel[6] & reg_sel[0]}};

//
// CPU Interface
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode
    rst_sync_simple # (
      .CLOCK_CYCLES ( 2 )
    ) i0_rst_sync_simple (
      .clk          ( clk_cpu ),
      .rst_async    ( rst_mc | ~i_boot_done | ~b0_r4_0 ),
      .deassert     ( b0_r4_0 ),
      .rst          ( rst_cpu ));

  end
  else begin

    // ARM mode
    assign rst_cpu = 0;

  end
endgenerate


//
// CPU Interrupts
//
  reg art_perm_fault_reg,
      art_miss_fault_reg,
      art_tlb_fault_reg;
//
  reg  TLB_MIss_Fault;
  reg  ART_Miss_Fault;
  reg  Permission_Fault;
  reg  Net_Exception;
  reg  System_Call;
//
  reg  UART_Irq;
  reg  Tmr_Irq;
  reg  Soft_Irq;
  reg  mBox_Irq;
  reg  Cnt0_Irq;
  reg  Cnt1_Irq;
  reg  Cnt2_Irq;
  reg  Cnt3_Irq;
//
  wire Net_ExceptionSet;
  wire Permission_FaultSet;
  wire ART_Miss_FaultSet_Fault;
  wire TLB_MIss_FaultSet;
  wire System_CallSet;
//
  wire Cnt3_IrqSet;
  wire Cnt2_IrqSet;
  wire Cnt1_IrqSet;
  wire Cnt0_IrqSet;
  wire mBox_IrqSet;
  wire Soft_IrqSet;
//
  wire Net_ExceptionClr;
  wire Permission_FaultClr;
  wire ART_Miss_FaultClr;
  wire TLB_MIss_FaultClr;
  wire System_CallClr;
//
  wire UART_IrqClr;
  wire Tmr_IrqClr;
  wire Cnt3_IrqClr;
  wire Cnt2_IrqClr;
  wire Cnt1_IrqClr;
  wire Cnt0_IrqClr;
  wire mBox_IrqClr;
  wire Soft_IrqClr;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode

     always @(posedge clk_ni) begin
        if(rst_ni) begin
           art_perm_fault_reg     <= #`dh 1'b0;
           art_miss_fault_reg     <= #`dh 1'b0;
           art_tlb_fault_reg      <= #`dh 1'b0;
        end
        else begin
           art_perm_fault_reg     <= #`dh i_art_perm_fault;
           art_miss_fault_reg     <= #`dh i_art_miss_fault;
           art_tlb_fault_reg      <= #`dh i_art_tlb_fault;
        end
     end
    //
      assign Net_ExceptionSet        = (CtlState==MnIIRQ);
      assign Permission_FaultSet     = i_art_perm_fault &~art_perm_fault_reg;
      assign ART_Miss_FaultSet_Fault = i_art_miss_fault &~art_miss_fault_reg;
      assign TLB_MIss_FaultSet       = i_art_tlb_fault  &~art_tlb_fault_reg;
      assign System_CallSet          = wr_b0_00 & i_mni_reg_wdata[0];
    //
      assign Cnt3_IrqSet             = i_cmx_int_cnt & (i_cmx_int_cnt_adr==b6_r0_29_24);
      assign Cnt2_IrqSet             = i_cmx_int_cnt & (i_cmx_int_cnt_adr==b6_r0_21_16);
      assign Cnt1_IrqSet             = i_cmx_int_cnt & (i_cmx_int_cnt_adr==b6_r0_13_8);
      assign Cnt0_IrqSet             = i_cmx_int_cnt & (i_cmx_int_cnt_adr==b6_r0_5_0);
      assign mBox_IrqSet             = i_cmx_int_mbox;
      assign Soft_IrqSet             = wr_b0_12 & i_mni_reg_wdata[0];
    //
      assign Net_ExceptionClr        = wr_b0_31 & i_mni_reg_wdata[12];
      assign Permission_FaultClr     = wr_b0_31 & i_mni_reg_wdata[11];
      assign ART_Miss_FaultClr       = wr_b0_31 & i_mni_reg_wdata[10];
      assign TLB_MIss_FaultClr       = wr_b0_31 & i_mni_reg_wdata[9];
      assign System_CallClr          = wr_b0_31 & i_mni_reg_wdata[8];
    //
      assign UART_IrqClr             = wr_b0_32 & i_mni_reg_wdata[7];
      assign Tmr_IrqClr              = wr_b0_32 & i_mni_reg_wdata[6];
      assign Cnt3_IrqClr             = wr_b0_32 & i_mni_reg_wdata[5];
      assign Cnt2_IrqClr             = wr_b0_32 & i_mni_reg_wdata[4];
      assign Cnt1_IrqClr             = wr_b0_32 & i_mni_reg_wdata[3];
      assign Cnt0_IrqClr             = wr_b0_32 & i_mni_reg_wdata[2];
      assign mBox_IrqClr             = wr_b0_32 & i_mni_reg_wdata[1];
      assign Soft_IrqClr             = wr_b0_32 & i_mni_reg_wdata[0];
    //
     always @(posedge clk_ni) begin
           UART_Irq             <= #`dh i_uart_irq;
           o_uart_irq_clear     <= #`dh UART_IrqClr;
     end
    //
     always @(posedge clk_ni) begin
        if(rst_ni) begin
           Net_Exception     <= #`dh 1'b0;
           Permission_Fault  <= #`dh 1'b0;
           ART_Miss_Fault    <= #`dh 1'b0; 
           TLB_MIss_Fault    <= #`dh 1'b0;
           System_Call       <= #`dh 1'b0;
    //
           Tmr_Irq           <= #`dh 1'b0;
           Cnt3_Irq          <= #`dh 1'b0;
           Cnt2_Irq          <= #`dh 1'b0;
           Cnt1_Irq          <= #`dh 1'b0;
           Cnt0_Irq          <= #`dh 1'b0;
           mBox_Irq          <= #`dh 1'b0;
           Soft_Irq          <= #`dh 1'b0;
        end
        else begin
    //
           if(Net_ExceptionSet)
              Net_Exception     <= #`dh 1'b1;
           else if(Net_ExceptionClr)
              Net_Exception     <= #`dh 1'b0;
    //
           if(Permission_FaultSet)
              Permission_Fault  <= #`dh 1'b1;
           else if(Permission_FaultClr)
              Permission_Fault  <= #`dh 1'b0;
    //
           if(ART_Miss_FaultSet_Fault)
              ART_Miss_Fault    <= #`dh 1'b1;
           else if(ART_Miss_FaultClr)
              ART_Miss_Fault    <= #`dh 1'b0;
    //
           if(TLB_MIss_FaultSet)
              TLB_MIss_Fault    <= #`dh 1'b1;
           else if(TLB_MIss_FaultClr)
              TLB_MIss_Fault    <= #`dh 1'b0;
    //
           if(System_CallSet)
              System_Call       <= #`dh 1'b1;
           else if(System_CallClr)
              System_Call       <= #`dh 1'b0;
    //
    //
           if(Tmr_IrqSet)
              Tmr_Irq          <= #`dh 1'b1;
           else if(Tmr_IrqClr)
              Tmr_Irq          <= #`dh 1'b0;
    //
           if(Cnt3_IrqSet)
              Cnt3_Irq          <= #`dh 1'b1;
           else if(Cnt3_IrqClr)
              Cnt3_Irq          <= #`dh 1'b0;
    //
           if(Cnt2_IrqSet)
              Cnt2_Irq          <= #`dh 1'b1;
           else if(Cnt2_IrqClr)
              Cnt2_Irq          <= #`dh 1'b0;
    //
           if(Cnt1_IrqSet)
              Cnt1_Irq          <= #`dh 1'b1;
           else if(Cnt1_IrqClr)
              Cnt1_Irq          <= #`dh 1'b0;
    //
           if(Cnt0_IrqSet)
              Cnt0_Irq          <= #`dh 1'b1;
           else if(Cnt0_IrqClr)
              Cnt0_Irq          <= #`dh 1'b0;
    //
           if(Soft_IrqSet)
              Soft_Irq          <= #`dh 1'b1;
           else if(Soft_IrqClr)
              Soft_Irq          <= #`dh 1'b0;
    //
           if(mBox_IrqSet)
              mBox_Irq          <= #`dh 1'b1;
           else if(mBox_IrqClr)
              mBox_Irq          <= #`dh 1'b0;
    //
        end
     end
    //
     assign b0_r8_23_16 = {UART_Irq,
                           Tmr_Irq,
                           Cnt3_Irq,
                           Cnt2_Irq,
                           Cnt1_Irq,
                           Cnt0_Irq,
                           mBox_Irq,
                           Soft_Irq};
    //
     assign b0_r8_12_8 = {Net_Exception,
                          Permission_Fault,
                          ART_Miss_Fault,
                          TLB_MIss_Fault,
                          System_Call};
    //
    // cpu_interrupt
    //
    assign interrupt = TLB_MIss_Fault    |
                       ART_Miss_Fault    |
                       Permission_Fault  |
                       Net_Exception     |
                       System_Call       |
                       (UART_Irq &~b0_rC_7_0[7]) |
                       (Tmr_Irq  &~b0_rC_7_0[6]) |
                       (Cnt3_Irq &~b0_rC_7_0[5]) |
                       (Cnt2_Irq &~b0_rC_7_0[4]) |
                       (Cnt1_Irq &~b0_rC_7_0[3]) |
                       (Cnt0_Irq &~b0_rC_7_0[2]) |
                       (mBox_Irq &~b0_rC_7_0[1]) |
                       (Soft_Irq &~b0_rC_7_0[0]);
    //
     always @(posedge clk_cpu) begin
        if(rst_cpu) 
           o_cpu_interrupt <= #`dh 1'b0;
        else  
           o_cpu_interrupt <= #`dh interrupt;
     end
    //
    // o_art_fault_ack
    //
     wire ART_Fault = i_art_perm_fault | i_art_miss_fault | i_art_tlb_fault;
     always @(posedge clk_cpu) begin
        if(rst_cpu)
          o_art_fault_ack <= #`dh 1'b0;
        else
          o_art_fault_ack <= #`dh ART_Fault;
     end
  end
  else begin

    // ARM mode
    always @(posedge clk_ni) begin
      o_uart_irq_clear <= 0;
    end
    always @(posedge clk_cpu) begin
      o_cpu_interrupt  <= 0;
      o_art_fault_ack  <= 0;
    end

  end
endgenerate


//
// Board controller trace interface
//
reg [2:0] bctl_cnt;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode
    always @(posedge clk_ni) begin
      if (rst_ni) begin
        bctl_cnt <= #`dh 0;
        o_bctl_trc_valid <= 1'b0;
      end
      else begin
        if (b0_r4_25 & i_cpu_trace_daccess) begin
          bctl_cnt <= #`dh bctl_cnt + 1'b1;
          o_bctl_trc_valid <= #`dh 1'b1;
        end
        else begin
          o_bctl_trc_valid <= 1'b0;
        end
      end
    end
    always @(posedge clk_ni) begin
       if (b0_r4_25 & i_cpu_trace_daccess) begin
         o_bctl_trc_data <= #`dh 
                    (bctl_cnt == 3'b000) ? i_cpu_trace_inst_adr[31:24] :
                    (bctl_cnt == 3'b001) ? i_cpu_trace_inst_adr[23:16] :
                    (bctl_cnt == 3'b010) ? i_cpu_trace_inst_adr[15:8]  :
                    (bctl_cnt == 3'b011) ? i_cpu_trace_inst_adr[ 7:0]  :
                    (bctl_cnt == 3'b100) ? i_cpu_trace_data_adr[31:24] :
                    (bctl_cnt == 3'b101) ? i_cpu_trace_data_adr[23:16] :
                    (bctl_cnt == 3'b110) ? i_cpu_trace_data_adr[15:8]  :
                                           i_cpu_trace_data_adr[ 7:0];
       end
    end
  end
  else begin

    // ARM mode
    always @(posedge clk_ni) begin
      o_bctl_trc_valid     <= 0;
      o_bctl_trc_data      <= 0;
    end

  end
endgenerate

//
// Yield
//
 reg    Yield;
 wire   YieldClr;
//
generate
  if (ARM_MODE == 0) begin

    // MBS mode
    assign   YieldClr = rst_ni | (Yield & o_cpu_interrupt);
    assign YieldSet = wr_b0_01 & i_mni_reg_wdata[8];
    //
    always @(posedge clk_ni) begin
       if (YieldSet)     Yield <= #`dh 1;
       else if(YieldClr) Yield <= #`dh 0;
    end
    //
    assign Yield_Block_Clr = (Yield & o_cpu_interrupt);
    assign b0_r4_10_set    = Yield_Block_Clr | i_cmx_block_aborted;
  end
endgenerate
//
endmodule
