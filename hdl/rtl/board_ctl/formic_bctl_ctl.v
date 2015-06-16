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
// Abstract      : Control block for Formic board controller
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: formic_bctl_ctl.v,v $
// CVS revision  : $Revision: 1.29 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

//
`timescale 1ns/1ps
//
// CTL
//
 module formic_bctl_ctl (
// Clocks and Resets
    input              clk_cpu,
    input              clk_ni,
    input              rst_cpu,
    input              rst_ni,
    input              clk_xbar,
    input              rst_xbar,
    input              clk_ddr,
    input              rst_ddr,
    // LEDs
    output      [11:0] o_led,
    // Reset Management Interface (asynchronous)
    output             o_rst_soft,
    output             o_rst_hard,
    // Static configuration
    input       [ 7:0] i_board_id,
    input       [ 3:0] i_dip_sw,
    // GTP Interface (assynchronus)
    input       [ 7:0] i_gtp_link_up,
    input       [ 7:0] i_gtp_link_error,
    input       [ 7:0] i_gtp_credit_error,
    input       [ 7:0] i_gtp_crc_error,
    // MBS Load Status interface (clk_ni)
    input       [ 3:0] i_mbs0_status,
    input       [ 3:0] i_mbs1_status,
    input       [ 3:0] i_mbs2_status,
    input       [ 3:0] i_mbs3_status,
    input       [ 3:0] i_mbs4_status,
    input       [ 3:0] i_mbs5_status,
    input       [ 3:0] i_mbs6_status,
    input       [ 3:0] i_mbs7_status,
    // DDR controller error monitoring (clk_ddr)
    input              i_ddr_p0_error,
    input              i_ddr_p1_error,
    input              i_ddr_p2_error,
    input              i_ddr_p3_error,
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
    // UART Interface (clk_xbar and clk_ni)
    output reg        o_uart_enq,
    output reg [ 7:0] o_uart_enq_data,
    input      [10:0] i_uart_tx_words,
    input             i_uart_tx_full,
    output reg        o_uart_deq,
    input      [ 7:0] i_uart_deq_data,
    input      [10:0] i_uart_rx_words,
    input             i_uart_rx_empty,
    input             i_uart_byte_rcv,
    // MBS UART & Timer Interface (clk_cpu)
    output     [ 7:0] o_mbs_uart_irq,
    input      [ 7:0] i_mbs_uart_irq_clear,
    output            o_mbs_drift_fw,
    output            o_mbs_drift_bw,
    // TLB Maintenance Interface (clk_ddr)
    output reg        o_tlb_enabled,
    output reg        o_tlb_maint_cmd,
    output reg        o_tlb_maint_wr_en,
    output reg [11:0] o_tlb_virt_adr,
    output reg [ 6:0] o_tlb_phys_adr,
    output reg        o_tlb_entry_valid,
    input      [ 6:0] i_tlb_phys_adr,
    input             i_tlb_entry_valid,
    input      [ 4:0] i_tlb_drop,
    // Trace Interface
    output     [25:0] o_bctl_trc_base,
    output     [25:0] o_bctl_trc_bound,
    output            o_bctl_trc_en);
//
 wire  wr_b0_0_0  = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h0_0000); 
 wire  wr_b0_0_1  = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h0_0000);
 wire  wr_b0_0_2  = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h0_0002); 
 wire  wr_b0_0_3  = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h0_0002);

 wire  wr_b0_8_0  = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h0_0008); 
 wire  wr_b0_8_1  = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h0_0008); 
 wire  wr_b0_8_2  = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h0_000A); 
 wire  wr_b0_8_3  = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h0_000A); 

 wire  wr_b0_10_0 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h0_0010);
//
 reg         BCR_S;
 reg         BCR_H;
 reg  [23:0] BCR_LED;
 reg  [ 1:0] BCR_LED_MODE;
 wire [31:0] BCR = {BCR_LED,2'b0,BCR_LED_MODE,4'b0};
//
 wire [31:0] BSR = {20'b0,i_dip_sw,i_board_id};
//
 
 reg  [ 7:0] BLSR_CRC_ERROR;
 reg  [ 7:0] BLSR_CREDIT_ERROR;
 reg  [ 7:0] BLSR_LINK_ERROR;
 reg  [ 7:0] BLSR_LINK_UP;
 wire [31:0] BLSR = {BLSR_CRC_ERROR, BLSR_CREDIT_ERROR,
                    BLSR_LINK_ERROR, BLSR_LINK_UP};
//
 wire [ 3:0] BCSR_C7 = i_mbs7_status;
 wire [ 3:0] BCSR_C6 = i_mbs6_status;
 wire [ 3:0] BCSR_C5 = i_mbs5_status;
 wire [ 3:0] BCSR_C4 = i_mbs4_status;
 wire [ 3:0] BCSR_C3 = i_mbs3_status;
 wire [ 3:0] BCSR_C2 = i_mbs2_status;
 wire [ 3:0] BCSR_C1 = i_mbs1_status;
 wire [ 3:0] BCSR_C0 = i_mbs0_status;
 wire [31:0] BCSR = {BCSR_C7, BCSR_C6, BCSR_C5, BCSR_C4,
                     BCSR_C3, BCSR_C2, BCSR_C1, BCSR_C0};
//
 reg  [ 3:0] BDRAMSR;
 wire [31:0] BDRAMS = {28'b0, BDRAMSR};
//
 pulse_sync i0_pulse_sync (
   .clk_in     ( clk_ddr ),
   .rst_in     ( rst_ddr ),
   .i_pulse    ( i_ddr_p0_error ),
   .clk_out    ( clk_ni ),
   .rst_out    ( rst_ni ),
   .o_pulse    ( ddr_p0_error_sync )
 );

 pulse_sync i1_pulse_sync (
   .clk_in     ( clk_ddr ),
   .rst_in     ( rst_ddr ),
   .i_pulse    ( i_ddr_p1_error ),
   .clk_out    ( clk_ni ),
   .rst_out    ( rst_ni ),
   .o_pulse    ( ddr_p1_error_sync )
 );

 pulse_sync i2_pulse_sync (
   .clk_in     ( clk_ddr ),
   .rst_in     ( rst_ddr ),
   .i_pulse    ( i_ddr_p2_error ),
   .clk_out    ( clk_ni ),
   .rst_out    ( rst_ni ),
   .o_pulse    ( ddr_p2_error_sync )
 );

 pulse_sync i3_pulse_sync (
   .clk_in     ( clk_ddr ),
   .rst_in     ( rst_ddr ),
   .i_pulse    ( i_ddr_p3_error ),
   .clk_out    ( clk_ni ),
   .rst_out    ( rst_ni ),
   .o_pulse    ( ddr_p3_error_sync )
 );
//
 always @(posedge clk_ni) begin
    BLSR_LINK_UP <= #`dh i_gtp_link_up;
 end
//
 always @(posedge clk_ni or posedge rst_ni) begin
    if(rst_ni) begin
       BCR_H  <= #`dh 1'b0;
    end
    else if(wr_b0_0_0) begin
       BCR_H  <= #`dh i_mni_reg_wdata[0];
    end
 end
//
 always @(posedge clk_ni) begin
    if(rst_ni) begin
       BCR_S             <= #`dh 1'b0;
       BCR_LED           <= #`dh {8'b0, 16'b1010101010101010};
       BCR_LED_MODE      <= #`dh 2'b10;
       BLSR_CRC_ERROR    <= #`dh 8'b0;
       BLSR_CREDIT_ERROR <= #`dh 8'b0;
       BLSR_LINK_ERROR   <= #`dh 8'b0;
       BDRAMSR           <= #`dh 1'b0;
    end
    else begin
       if(wr_b0_0_0) begin
          BCR_S         <= #`dh i_mni_reg_wdata[1];
          BCR_LED_MODE  <= #`dh i_mni_reg_wdata[5:4];
       end
       if(wr_b0_0_1) begin
          BCR_LED[ 7:0] <= #`dh i_mni_reg_wdata[15:8];
       end
       if(wr_b0_0_2) begin
          BCR_LED[15:8] <= #`dh i_mni_reg_wdata[7:0];
       end
       if(wr_b0_0_3) begin
          BCR_LED[23:16] <= #`dh i_mni_reg_wdata[15:8];
       end
//
       if(wr_b0_8_3) begin
          BLSR_CRC_ERROR    <= #`dh 8'b0;
       end
       if(wr_b0_8_2) begin
          BLSR_CREDIT_ERROR <= #`dh 8'b0;
       end
       if(i_gtp_credit_error[0]) BLSR_CREDIT_ERROR[0] <= #`dh 1'b1;
       if(i_gtp_credit_error[1]) BLSR_CREDIT_ERROR[1] <= #`dh 1'b1;
       if(i_gtp_credit_error[2]) BLSR_CREDIT_ERROR[2] <= #`dh 1'b1;
       if(i_gtp_credit_error[3]) BLSR_CREDIT_ERROR[3] <= #`dh 1'b1;
       if(i_gtp_credit_error[4]) BLSR_CREDIT_ERROR[4] <= #`dh 1'b1;
       if(i_gtp_credit_error[5]) BLSR_CREDIT_ERROR[5] <= #`dh 1'b1;
       if(i_gtp_credit_error[6]) BLSR_CREDIT_ERROR[6] <= #`dh 1'b1;
       if(i_gtp_credit_error[7]) BLSR_CREDIT_ERROR[7] <= #`dh 1'b1;
       if(i_gtp_crc_error[0])    BLSR_CRC_ERROR[0]    <= #`dh 1'b1;
       if(i_gtp_crc_error[1])    BLSR_CRC_ERROR[1]    <= #`dh 1'b1;
       if(i_gtp_crc_error[2])    BLSR_CRC_ERROR[2]    <= #`dh 1'b1;
       if(i_gtp_crc_error[3])    BLSR_CRC_ERROR[3]    <= #`dh 1'b1;
       if(i_gtp_crc_error[4])    BLSR_CRC_ERROR[4]    <= #`dh 1'b1;
       if(i_gtp_crc_error[5])    BLSR_CRC_ERROR[5]    <= #`dh 1'b1;
       if(i_gtp_crc_error[6])    BLSR_CRC_ERROR[6]    <= #`dh 1'b1;
       if(i_gtp_crc_error[7])    BLSR_CRC_ERROR[7]    <= #`dh 1'b1;
//
       if(wr_b0_8_1)
          BLSR_LINK_ERROR <= #`dh 8'b0;
       if(i_gtp_link_error[0]) BLSR_LINK_ERROR[0] <= #`dh 1'b1;
       if(i_gtp_link_error[1]) BLSR_LINK_ERROR[1] <= #`dh 1'b1;
       if(i_gtp_link_error[2]) BLSR_LINK_ERROR[2] <= #`dh 1'b1;
       if(i_gtp_link_error[3]) BLSR_LINK_ERROR[3] <= #`dh 1'b1;
       if(i_gtp_link_error[4]) BLSR_LINK_ERROR[4] <= #`dh 1'b1;
       if(i_gtp_link_error[5]) BLSR_LINK_ERROR[5] <= #`dh 1'b1;
       if(i_gtp_link_error[6]) BLSR_LINK_ERROR[6] <= #`dh 1'b1;
       if(i_gtp_link_error[7]) BLSR_LINK_ERROR[7] <= #`dh 1'b1;
//
       if(wr_b0_10_0)
          BDRAMSR <= #`dh 1'b0;
       if(ddr_p0_error_sync) BDRAMSR[0] <= #`dh 1'b1;
       if(ddr_p1_error_sync) BDRAMSR[1] <= #`dh 1'b1;
       if(ddr_p2_error_sync) BDRAMSR[2] <= #`dh 1'b1;
       if(ddr_p3_error_sync) BDRAMSR[3] <= #`dh 1'b1;
    end
 end
//
 wire [31:0] BMR = BCR    & {32{(i_mni_reg_adr[4:2]==0)}} |   // ???
                   BSR    & {32{(i_mni_reg_adr[4:2]==1)}} |
                   BLSR   & {32{(i_mni_reg_adr[4:2]==2)}} |
                   BCSR   & {32{(i_mni_reg_adr[4:2]==3)}} | // FIXME
                   BDRAMS & {32{(i_mni_reg_adr[4:2]==4)}};
//
//
 wire [31:0] GlobalTimer;
 wire [31:0] GlobalTimerNewVal;
 wire        wr_b2_0H = i_mni_reg_valid & i_mni_reg_wen & (i_mni_reg_adr==20'h4_0002);
 wire        wr_b2_0L = i_mni_reg_valid & i_mni_reg_wen & (i_mni_reg_adr==20'h4_0000);
//
align_clk_sync_2_halfword iGTall(
    // Input side
    .clk_in        ( clk_ni ),
    .rst_in        ( rst_ni ),
    .i_data        ( i_mni_reg_wdata ),
    .i_valid_high  ( wr_b2_0H ),
    .i_valid_low   ( wr_b2_0L ),
    .o_stall       ( ),
    // Output side
    .clk_out        ( clk_cpu ),
    .rst_out        ( rst_cpu ),
    .o_data         ( GlobalTimerNewVal ),
    .o_valid        ( GlobalTimerWrite ),
    .i_stall        ( 1'b0 ));

//
// Board Global Timer
//
GlobalTimer iGlobalTimer(
    .Clk         ( clk_cpu ),
    .Reset       ( rst_cpu ),
    .i_in        ( GlobalTimerNewVal ),
    .i_write     ( GlobalTimerWrite ),
    .o_out       ( GlobalTimer ),
    .o_drift_fw  ( o_mbs_drift_fw ),
    .o_drift_bw  ( o_mbs_drift_bw ));
//
// Trace Registers
//
 wire       wr_b4_0_0 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h8_0000);
 wire       wr_b4_0_1 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h8_0000);
 wire       wr_b4_0_2 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h8_0002);
 wire       wr_b4_0_3 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h8_0002);
 
 wire       wr_b4_4_0 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h8_0004);
 wire       wr_b4_4_1 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h8_0004);
 wire       wr_b4_4_2 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h8_0006);
 wire       wr_b4_4_3 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h8_0006);
//
 wire       wr_b4_8_0 = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[1] & (i_mni_reg_adr==20'h8_0008);
//
 reg  [25:0] TraceBaseAdrReg;
 reg  [25:0] TraceBoundAdrReg;
 reg         TraceEn;
//
 assign o_bctl_trc_base  = TraceBaseAdrReg;
 assign o_bctl_trc_bound = TraceBoundAdrReg;
 assign o_bctl_trc_en    = TraceEn;

//
  always @(posedge clk_ni) begin
      if(rst_ni) begin
         TraceBaseAdrReg  <= #`dh 1'b0;
         TraceBoundAdrReg <= #`dh 1'b0;
         TraceEn          <= #`dh 1'b0;
      end  
      else begin
          if(wr_b4_0_0) TraceBaseAdrReg[1:0]   <= #`dh i_mni_reg_wdata[7:6];
          if(wr_b4_0_1) TraceBaseAdrReg[9:2]   <= #`dh i_mni_reg_wdata[15:8];
          if(wr_b4_0_2) TraceBaseAdrReg[17:10] <= #`dh i_mni_reg_wdata[7:0];
          if(wr_b4_0_3) TraceBaseAdrReg[25:18] <= #`dh i_mni_reg_wdata[15:8];

          if(wr_b4_4_0) TraceBoundAdrReg[1:0]   <= #`dh i_mni_reg_wdata[7:6];
          if(wr_b4_4_1) TraceBoundAdrReg[9:2]   <= #`dh i_mni_reg_wdata[15:8];
          if(wr_b4_4_2) TraceBoundAdrReg[17:10] <= #`dh i_mni_reg_wdata[7:0];
          if(wr_b4_4_3) TraceBoundAdrReg[25:18] <= #`dh i_mni_reg_wdata[15:8];
          if(wr_b4_8_0) TraceEn                 <= #`dh i_mni_reg_wdata[0];
      end
  end
//
 wire [31:0] TraceAdrReg = {(i_mni_reg_adr[2] ? TraceBoundAdrReg : TraceBaseAdrReg), 6'b0};
//
// UART
//
parameter IdleSt    = 8'b0000_0001,
          BulkSize  = 8'b0000_0010,
          BulkEnq0  = 8'b0000_0100,
          BulkEnq1  = 8'b0000_1000,
          BulkEnq2  = 8'b0001_0000,
          BulkEnq3  = 8'b0010_0000,
          SingEnq0  = 8'b0100_0000,
          SingEnq1  = 8'b1000_0000;
//
reg  [7:0] UartState;
//
// synthesis translate_off
reg [256:0] UartStateString;
always @(UartState) begin
  case (UartState)
    IdleSt   : UartStateString = "IdleSt";
    BulkSize : UartStateString = "BulkSize";
    BulkEnq0 : UartStateString = "BulkEnq0";
    BulkEnq1 : UartStateString = "BulkEnq1";
    BulkEnq2 : UartStateString = "BulkEnq2";
    BulkEnq3 : UartStateString = "BulkEnq3";
    SingEnq0 : UartStateString = "SingEnq0";
    SingEnq1 : UartStateString = "SingEnq1";
    default  : UartStateString = "ERROR";
  endcase
end
// synthesis translate_on
//
reg [5:0] Cnt;
reg [15:0] UartRegL0, UartRegL1, UartRegL2;
//
 wire B_Enq = i_mni_reg_valid & i_mni_reg_wen & (i_mni_reg_adr[19:8]==12'h601);
 reg  B_EnqR0, B_EnqR1, B_EnqR2;
 wire S_Enq = i_mni_reg_valid & i_mni_reg_wen & i_mni_reg_ben[0] & (i_mni_reg_adr==20'h6_0008);
 wire Uart_deq = i_mni_reg_valid &~i_mni_reg_wen & (i_mni_reg_adr[19:0]==20'h6_0008);
 reg  S_EnqR0, S_EnqR1, S_EnqR2;
//
 always @(posedge clk_ni) begin
    B_EnqR0 <= #`dh B_Enq;
    B_EnqR1 <= #`dh B_EnqR0;
    B_EnqR2 <= #`dh B_EnqR1;
    S_EnqR0 <= #`dh S_Enq;
    S_EnqR1 <= #`dh S_EnqR0;
    S_EnqR2 <= #`dh S_EnqR1;
 end
//
 wire B_Start = B_EnqR1 &~B_EnqR2;
 wire S_Start = S_EnqR1 &~S_EnqR2;
//
 wire CntDec = (UartState==BulkSize) |
               (UartState==BulkEnq0) |
               (UartState==BulkEnq1) |
               (UartState==BulkEnq2) |
               (UartState==BulkEnq3);
//
 always @(posedge clk_xbar) begin
    if(rst_xbar)
       Cnt <= #`dh 0;
    else if((UartState==IdleSt) & B_Start)
       Cnt <= #`dh UartRegL0[5:0];
    else if(CntDec)
       Cnt <= #`dh Cnt - 1'b1;
 end
//
// FSM
//
wire CntEnd = (Cnt==6'h1);
//
 always @(posedge clk_xbar) begin
    if(rst_xbar)
       UartState <= #`dh IdleSt;
     else begin
        case (UartState)
        IdleSt   : begin
                      if(B_Start)
                           UartState <= #`dh BulkSize;
                      else if(S_Start)
                           UartState <= #`dh SingEnq0;
                      else UartState <= #`dh IdleSt;
                   end
//
        BulkSize : begin
                      if(CntEnd)
                           UartState <= #`dh IdleSt;
                      else UartState <= #`dh BulkEnq1;
                   end
//
        BulkEnq0 : begin
                      if(CntEnd)
                           UartState <= #`dh IdleSt;
                      else UartState <= #`dh BulkEnq1;
                   end
//
        BulkEnq1 : begin
                     if(CntEnd)
                           UartState <= #`dh IdleSt;
                      else UartState <= #`dh BulkEnq2;
                   end
//
        BulkEnq2 : begin
                      if(CntEnd)
                           UartState <= #`dh IdleSt;
                      else UartState <= #`dh BulkEnq3;
                   end
//
        BulkEnq3 : begin
                      if(CntEnd)
                           UartState <= #`dh IdleSt;
                      else UartState <= #`dh BulkEnq0;
                   end
//
        SingEnq0 : UartState <= #`dh SingEnq1;
//
        SingEnq1 : UartState <= #`dh IdleSt;
//
        default  : UartState <= #`dh IdleSt;
//
        endcase
     end
 end
//
 wire SelReg0H = (UartState==BulkEnq0) | (UartState==BulkSize);
 wire SelReg2L = (UartState==BulkEnq1) | (UartState==SingEnq1);
 wire SelReg2H = (UartState==BulkEnq2);
 wire SelReg0L = (UartState==BulkEnq3);
//
//
//
 always @(posedge clk_ni) begin
    UartRegL0 <= #`dh i_mni_reg_wdata;
    UartRegL1 <= #`dh UartRegL0;
    UartRegL2 <= #`dh UartRegL1;
 end
//
 always @(posedge clk_xbar) begin
      if(rst_xbar) o_uart_enq <= #`dh 0;
      else begin
         o_uart_enq      <= #`dh (UartState==BulkSize) |
                                 (UartState==BulkEnq0) |
                                 (UartState==BulkEnq1) |
                                 (UartState==BulkEnq2) |
                                 (UartState==BulkEnq3) |
                                 (UartState==SingEnq1);
      end
 end
 always @(posedge clk_xbar) begin
    o_uart_enq_data <= #`dh UartRegL0[ 7:0] & {8{SelReg0L}} |
                            UartRegL0[15:8] & {8{SelReg0H}} |
                            UartRegL2[ 7:0] & {8{SelReg2L}} |
                            UartRegL2[15:8] & {8{SelReg2H}};
//
 end
//
// Uart Status Register
//
 wire [31:0] uart_status = {5'h0,i_uart_tx_words, 5'h0,i_uart_rx_words};
//
//
// Uart Control Register
//
 reg [2:0] Uart_CID;
 reg       Uart_Ien;
 always @(posedge clk_ni) begin
    if(rst_ni) begin
       Uart_CID <= #`dh 0;
       Uart_Ien <= #`dh 0;
    end
    else if(i_mni_reg_valid & i_mni_reg_wen & (i_mni_reg_adr==20'h6_0000)) begin
        if(i_mni_reg_ben[0]) Uart_Ien <= #`dh i_mni_reg_wdata[0];
        if(i_mni_reg_ben[1]) Uart_CID <= #`dh i_mni_reg_wdata[10:8];
    end
 end
//
// Uart Interrupt Register
//
 reg [7:0] mbs_uart_irq;
 reg [7:0] mbs_uart_irq_clear;
 always @(posedge clk_ni) mbs_uart_irq_clear <= #`dh i_mbs_uart_irq_clear;
 always @(posedge clk_ni) begin
     if(rst_ni) mbs_uart_irq <= #`dh 0;
     else begin
        if(i_uart_byte_rcv & (Uart_CID==0)) mbs_uart_irq[0] <= #`dh 1'b1;
        else if(mbs_uart_irq_clear[0])    mbs_uart_irq[0] <= #`dh 1'b0;
        if(i_uart_byte_rcv & (Uart_CID==1)) mbs_uart_irq[1] <= #`dh 1'b1;
        else if(mbs_uart_irq_clear[1])    mbs_uart_irq[1] <= #`dh 1'b0;
        if(i_uart_byte_rcv & (Uart_CID==2)) mbs_uart_irq[2] <= #`dh 1'b1;
        else if(mbs_uart_irq_clear[2])    mbs_uart_irq[2] <= #`dh 1'b0;
        if(i_uart_byte_rcv & (Uart_CID==3)) mbs_uart_irq[3] <= #`dh 1'b1;
        else if(mbs_uart_irq_clear[3])    mbs_uart_irq[3] <= #`dh 1'b0;
        if(i_uart_byte_rcv & (Uart_CID==4)) mbs_uart_irq[4] <= #`dh 1'b1;
        else if(mbs_uart_irq_clear[4])    mbs_uart_irq[4] <= #`dh 1'b0;
        if(i_uart_byte_rcv & (Uart_CID==5)) mbs_uart_irq[5] <= #`dh 1'b1;
        else if(mbs_uart_irq_clear[5])    mbs_uart_irq[5] <= #`dh 1'b0;
        if(i_uart_byte_rcv & (Uart_CID==6)) mbs_uart_irq[6] <= #`dh 1'b1;
        else if(mbs_uart_irq_clear[6])    mbs_uart_irq[6] <= #`dh 1'b0;
        if(i_uart_byte_rcv & (Uart_CID==7)) mbs_uart_irq[7] <= #`dh 1'b1;
        else if(mbs_uart_irq_clear[7])    mbs_uart_irq[7] <= #`dh 1'b0;
     end
 end
//
 assign o_mbs_uart_irq = mbs_uart_irq & {8{Uart_Ien}}; 
//
 wire [31:0] UART_REG = {21'b0,Uart_CID,7'b0,Uart_Ien} & {32{(i_mni_reg_adr[3:2]==0)}} |
                        uart_status                    & {32{(i_mni_reg_adr[3:2]==1)}} |
                        {24'h0,i_uart_deq_data}        & {32{(i_mni_reg_adr[3:2]==2)}};
//
// TLB
//
 wire TLB_r_w = i_mni_reg_valid & ((i_mni_reg_adr[19:12]==8'h21) |
                                   (i_mni_reg_adr[19:12]==8'h22) |
                                   (i_mni_reg_adr[19:12]==8'h23) |
                                   (i_mni_reg_adr[19:12]==8'h24)) &
                                   ~i_mni_reg_adr[1];
//
 wire TLB_write = TLB_r_w & i_mni_reg_wen;
//
 wire TLB_read  = TLB_r_w &~i_mni_reg_wen;
 wire TLB_status_read = i_mni_reg_valid & (i_mni_reg_adr[19:12]==8'h20) &~i_mni_reg_wen;
//
 wire tlb_send_cmd = i_mni_reg_valid & i_mni_reg_wen & 
                     (i_mni_reg_adr[19:12]==8'h20) & i_mni_reg_ben[0];
 always @(posedge clk_ni) begin
    if(rst_ni) begin
       o_tlb_maint_wr_en <= #`dh 0;
       o_tlb_maint_cmd   <= #`dh 0;
       o_tlb_enabled     <= #`dh 0;
    end
    else if(tlb_send_cmd)
        o_tlb_enabled     <= #`dh i_mni_reg_wdata[0];
    else begin
        o_tlb_maint_cmd   <= #`dh TLB_r_w;
        o_tlb_maint_wr_en <= #`dh TLB_write;
    end
 end
 always @(posedge clk_ni) begin
   if (~tlb_send_cmd) begin
     o_tlb_virt_adr    <= #`dh {(i_mni_reg_adr[13:12]-1),i_mni_reg_adr[11:2]};
     o_tlb_entry_valid <= #`dh i_mni_reg_wdata[8];
     o_tlb_phys_adr    <= #`dh i_mni_reg_wdata[ 6:0];
   end
 end
//
// Control Read Operation
//
parameter Idle  = 7'b000_0001,
          CtlW0 = 7'b000_0010,
	  CtlW1 = 7'b000_0100, 
	  CtlW2 = 7'b000_1000, 
	  CtlW3 = 7'b001_0000, 
          ReadH = 7'b010_0000,
          ReadL = 7'b100_0000;
//
 reg [6:0] CtlState;
// synthesis translate_off
  reg [256:0] CtlStateString;
  always @(CtlState) begin
    case (CtlState)
      Idle    : CtlStateString = "Idle";
      CtlW0   : CtlStateString = "CtlW0";
      CtlW1   : CtlStateString = "CtlW1";
      CtlW2   : CtlStateString = "CtlW2";
      CtlW3   : CtlStateString = "CtlW3";
      ReadH   : CtlStateString = "ReadH";
      ReadL   : CtlStateString = "ReadL";
      default : CtlStateString = "ERROR";
    endcase
  end
// synthesis translate_on
//
// Idle FSM
//
 wire ReadOpStart = i_mni_reg_valid &~i_mni_reg_wen;
 always @(posedge clk_ni) begin
    if(rst_ni) CtlState <= #`dh Idle;
    else begin
       case(CtlState)
//
       Idle    : begin
                     if(ReadOpStart) begin
                        if(TLB_read)
                             CtlState <= #`dh CtlW0;
                        else CtlState <= #`dh ReadH;
                     end
                     else CtlState <= #`dh Idle;
                  end
//
       CtlW0   : CtlState <= #`dh CtlW1;
//
       CtlW1   : CtlState <= #`dh CtlW2;
//
       CtlW2   : CtlState <= #`dh CtlW3;
//
       CtlW3   : CtlState <= #`dh ReadH;
//
       ReadH   : CtlState <= #`dh ReadL;
//
       ReadL   : CtlState <= #`dh Idle;
//
       default : CtlState <= #`dh Idle;
//
       endcase
//
    end
 end
//
//
//
 reg [ 6:0] tlb_phys_adr_reg; 
 reg        tlb_entry_valid_reg; 
 reg        tlb_status;
//
 wire [15:0] BMR16          = (CtlState==ReadH) ? BMR[15:0]          : BMR[31:16];
 wire [15:0] TLB16          = (CtlState==ReadH) ? {7'b0, (tlb_status ? 
                                                    {8'b0, o_tlb_enabled} : 
                                                    {tlb_entry_valid_reg, 1'b0, tlb_phys_adr_reg})} : 
                                                  16'b0;
 wire [15:0] GlobalTimer16  = (CtlState==ReadH) ? GlobalTimer[15:0]  : GlobalTimer[31:16];
 wire [15:0] UART_REG16     = (CtlState==ReadH) ? UART_REG[15:0]     : UART_REG[31:16];
 wire [15:0] TraceAdrReg16 = (CtlState==ReadH)  ? TraceAdrReg[15:0] : TraceAdrReg[31:16];
//
 wire [15:0] Read_Word_Mux = BMR16           & {16{(i_mni_reg_adr[19:16]==0)}} |
                             TLB16           & {16{(i_mni_reg_adr[19:16]==2)}} |
                             GlobalTimer16   & {16{(i_mni_reg_adr[19:16]==4)}} |
                             UART_REG16      & {16{(i_mni_reg_adr[19:16]==6)}} |
                             TraceAdrReg16   & {16{(i_mni_reg_adr[19:16]==8)}};
//
 wire ctl_read_resp_valid  = (((CtlState==Idle) & ReadOpStart) &~TLB_read) |
                             (CtlState==CtlW3) |
                             (CtlState==ReadH);
 wire ctl_write_resp_valid =  i_mni_reg_valid & i_mni_reg_wen &~o_mni_reg_stall;
//
 always @(posedge clk_ni) begin
   if(rst_ni) begin
      o_mni_reg_resp_valid <= #`dh 1'b0;
      o_mni_reg_stall      <= #`dh 1'b0;
      o_uart_deq           <= #`dh 1'b0;
      tlb_status           <= #`dh 1'b0;
   end
   else begin
      tlb_status           <= #`dh TLB_status_read;
      o_mni_reg_resp_valid <= #`dh ctl_read_resp_valid | ctl_write_resp_valid;
      o_mni_reg_stall      <= #`dh ((CtlState==Idle) & ReadOpStart) | 
                                   (CtlState==ReadH) |
                                   (CtlState==CtlW0) |
                                   (CtlState==CtlW1) |
                                   (CtlState==CtlW2) |
                                   (CtlState==CtlW3);
      o_uart_deq           <= #`dh Uart_deq;
   end
 end
 always @(posedge clk_ni) begin
   tlb_phys_adr_reg     <= #`dh i_tlb_phys_adr;
   tlb_entry_valid_reg  <= #`dh i_tlb_entry_valid;
   o_mni_reg_resp_rdata <= #`dh Read_Word_Mux;
 end
//
assign o_rst_soft = BCR_S;
assign o_rst_hard = BCR_H;
//
// Led Control
//
 reg [23:0] led_cnt;
 always @(posedge clk_cpu) begin
    if(rst_cpu) led_cnt <= #`dh 0;
    else        led_cnt <= #`dh led_cnt + 24'b1;
 end
//
 wire on_75 = led_cnt[16];
 wire on_50 = led_cnt[16] & led_cnt[15] & led_cnt[14];
 wire blink = led_cnt[23] & on_75;
//
 wire [1:0] led00 = (BCR_LED_MODE == 2'b00) ? BCR_LED[ 1:0] :
                    (BCR_LED_MODE == 2'b10) ? ({2{BLSR_LINK_UP[0]}} & BCR_LED[ 1:0]) :
                    (BCR_LED_MODE == 2'b11) ? ({2{BLSR_LINK_ERROR[0]}} & BCR_LED[ 1:0]) :
                                              2'b0;
 wire [1:0] led01 = (BCR_LED_MODE == 2'b00) ? BCR_LED[ 3:2] :
                    (BCR_LED_MODE == 2'b10) ? ({2{BLSR_LINK_UP[1]}} & BCR_LED[ 3:2]) :
                    (BCR_LED_MODE == 2'b11) ? ({2{BLSR_LINK_ERROR[1]}} & BCR_LED[ 3:2]) :
                                              2'b0;
 wire [1:0] led02 = (BCR_LED_MODE == 2'b00) ? BCR_LED[ 5:4] :
                    (BCR_LED_MODE == 2'b10) ? ({2{BLSR_LINK_UP[2]}} & BCR_LED[ 5:4]) :
                    (BCR_LED_MODE == 2'b11) ? ({2{BLSR_LINK_ERROR[2]}} & BCR_LED[ 5:4]) :
                                              2'b0;
 wire [1:0] led03 = (BCR_LED_MODE == 2'b00) ? BCR_LED[ 7:6] :
                    (BCR_LED_MODE == 2'b10) ? ({2{BLSR_LINK_UP[3]}} & BCR_LED[ 7:6]) :
                    (BCR_LED_MODE == 2'b11) ? ({2{BLSR_LINK_ERROR[3]}} & BCR_LED[ 7:6]) :
                                              2'b0;
 wire [1:0] led04 = (BCR_LED_MODE == 2'b00) ? BCR_LED[ 9:8] :
                    (BCR_LED_MODE == 2'b10) ? ({2{BLSR_LINK_UP[4]}} & BCR_LED[ 9:8]) :
                    (BCR_LED_MODE == 2'b11) ? ({2{BLSR_LINK_ERROR[4]}} & BCR_LED[ 9:8]) :
                                              2'b0;
 wire [1:0] led05 = (BCR_LED_MODE == 2'b00) ? BCR_LED[11:10] :
                    (BCR_LED_MODE == 2'b10) ? ({2{BLSR_LINK_UP[5]}} & BCR_LED[11:10]) :
                    (BCR_LED_MODE == 2'b11) ? ({2{BLSR_LINK_ERROR[5]}} & BCR_LED[11:10]) :
                                              2'b0;
 wire [1:0] led06 = (BCR_LED_MODE == 2'b00) ? BCR_LED[13:12] :
                    (BCR_LED_MODE == 2'b10) ? ({2{BLSR_LINK_UP[6]}} & BCR_LED[13:12]) :
                    (BCR_LED_MODE == 2'b11) ? ({2{BLSR_LINK_ERROR[6]}} & BCR_LED[13:12]) :
                                              2'b0;
 wire [1:0] led07 = (BCR_LED_MODE == 2'b00) ? BCR_LED[15:14] :
                    (BCR_LED_MODE == 2'b10) ? ({2{BLSR_LINK_UP[7]}} & BCR_LED[15:14]) :
                    (BCR_LED_MODE == 2'b11) ? ({2{BLSR_LINK_ERROR[7]}} & BCR_LED[15:14]) :
                                              2'b0;
 wire [1:0] led08 = BCR_LED[17:16];
 wire [1:0] led09 = BCR_LED[19:18];
 wire [1:0] led10 = BCR_LED[21:20];
 wire [1:0] led11 = BCR_LED[23:22];
//
 LedCtl iLedCtl00(clk_cpu, rst_cpu, led00, on_50, on_75, blink, o_led[0]);
 LedCtl iLedCtl01(clk_cpu, rst_cpu, led01, on_50, on_75, blink, o_led[1]);
 LedCtl iLedCtl02(clk_cpu, rst_cpu, led02, on_50, on_75, blink, o_led[2]);
 LedCtl iLedCtl03(clk_cpu, rst_cpu, led03, on_50, on_75, blink, o_led[3]);
 LedCtl iLedCtl04(clk_cpu, rst_cpu, led04, on_50, on_75, blink, o_led[4]);
 LedCtl iLedCtl05(clk_cpu, rst_cpu, led05, on_50, on_75, blink, o_led[5]);
 LedCtl iLedCtl06(clk_cpu, rst_cpu, led06, on_50, on_75, blink, o_led[6]);
 LedCtl iLedCtl07(clk_cpu, rst_cpu, led07, on_50, on_75, blink, o_led[7]);
 LedCtl iLedCtl08(clk_cpu, rst_cpu, led08, on_50, on_75, blink, o_led[8]);
 LedCtl iLedCtl09(clk_cpu, rst_cpu, led09, on_50, on_75, blink, o_led[9]);
 LedCtl iLedCtl10(clk_cpu, rst_cpu, led10, on_50, on_75, blink, o_led[10]);
 LedCtl iLedCtl11(clk_cpu, rst_cpu, led11, on_50, on_75, blink, o_led[11]);
//     
endmodule
//
module LedCtl(
  input        clk,
  input        rst,
  input  [1:0] i_mode,
  input        i_on_50,
  input        i_on_75,
  input        i_blink,
  output reg   o_led);
//
  always @(posedge clk) begin
    if(rst) o_led <= #`dh 0;
    else begin
       case (i_mode)
         0 : o_led <= #`dh 0;
         1 : o_led <= #`dh i_on_50; 
         2 : o_led <= #`dh i_on_75; 
         3 : o_led <= #`dh i_blink; 
       endcase
    end
 end
//
endmodule
