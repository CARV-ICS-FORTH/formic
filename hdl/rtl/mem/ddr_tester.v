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
// Abstract      : DDR2 DRAM automatic tester (reads/writes all DRAM contents)
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: ddr_tester.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module ddr_tester(

  // Clocking
  input          clk_ddr,
  input          rst_ddr,

  // DDR Controller
  output         o_cmd_en,
  output   [2:0] o_cmd_instr,
  output   [5:0] o_cmd_bl,
  output  [29:0] o_cmd_byte_addr,
  input          i_cmd_full,
  output         o_wr_en,
  output   [3:0] o_wr_mask,
  output  [31:0] o_wr_data,
  input          i_wr_almost_full,
  output         o_rd_en,
  input   [31:0] i_rd_data,
  input          i_rd_empty,
  input          i_error,

  // Management
  input          i_start,
  output         o_finished,
  output         o_pass
);

  // Tester address limit: max 20'hFFFFF (writes all 128-B lines up to 128 MB)
  //localparam CNT_END_VALUE = 20'h0000F;
  localparam CNT_END_VALUE = 20'hFFFFF;

  // ==========================================================================
  // Wires
  // ==========================================================================
  reg  [19:0] adr_cnt_q;
  wire [19:0] adr_cnt_d;
  wire        adr_cnt_end;

  reg   [4:0] data_cnt_q;
  wire  [4:0] data_cnt_d;
  wire        data_cnt_end;

  reg  [31:0] lfsr_q;
  wire [31:0] lfsr_d;

  wire        adr_init;
  wire        adr_next;
  wire        data_init;
  wire        data_next;

  reg         error_q;
  wire        error_d;
  reg         finished_q;
  wire        finished_d;


  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle       = 5'b00001,
             SendData   = 5'b00010,
             SendCmd    = 5'b00100,
             RecvCmd    = 5'b01000,
             RecvData   = 5'b10000;

  reg  [4:0] state_d;
  reg  [4:0] state_q;

  // synthesis translate_off
  reg [256:0] StateString;
  always @(state_q) begin
    case (state_q)
      Idle     : StateString = "Idle";
      SendData : StateString = "SendData";
      SendCmd  : StateString = "SendCmd";
      RecvCmd  : StateString = "RecvCmd";
      RecvData : StateString = "RecvData";
      default  : StateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
        if (i_start)
          state_d = SendData;
        else
          state_d = Idle;
        end

      SendData: begin
          if (data_cnt_end & ~i_wr_almost_full)
            state_d = SendCmd;
          else
            state_d = SendData;
        end

      SendCmd: begin
          if (i_cmd_full)
            state_d = SendCmd;
          else if (adr_cnt_end)
            state_d = RecvCmd;
          else
            state_d = SendData;
        end

      RecvCmd: begin
          if (i_cmd_full)
            state_d = RecvCmd;
          else
            state_d = RecvData;
        end

      RecvData: begin
          if (data_cnt_end & ~i_rd_empty) begin
            if (adr_cnt_end)
              state_d = Idle;
            else
              state_d = RecvCmd;
          end
          else
            state_d = RecvData;
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

  // Conditions
  assign adr_init = (state_q == Idle) | 
                    ((state_d == RecvCmd) & (state_q == SendCmd));

  assign adr_next = ((state_q == SendCmd) & ~i_cmd_full) |
                    ((state_q == RecvCmd) & ~i_cmd_full);

  assign data_init = (state_q == Idle) | 
                     (state_q == SendCmd) |
                     (state_q == RecvCmd);

  assign data_next = ((state_q == SendData) & ~i_wr_almost_full) |
                     ((state_q == RecvData) & ~i_rd_empty);


  // Address counter
  assign adr_cnt_d = adr_init ? 20'b0 :
                     adr_next ? adr_cnt_q + 1'b1 :
                                adr_cnt_q;

  assign adr_cnt_end = (adr_cnt_q == CNT_END_VALUE);



  // Data counter
  assign data_cnt_d = data_init ? 5'b0 :
                      data_next ? data_cnt_q + 1'b1 :
                                  data_cnt_q;

  assign data_cnt_end = (data_cnt_q == 5'd31);


  // Send data / recv expected data LFSR
  assign lfsr_d = adr_init ?  32'hCAFE_DECA :
                  data_next ? {(lfsr_q[31] ^ lfsr_q[21] ^ 
                                lfsr_q[1] ^ lfsr_q[0]), 
                               lfsr_q[31:1]} :
                  lfsr_q;
                       

  // Completion
  assign error_d = ((state_q == Idle) &
                    (state_d == SendCmd))   ? 1'b0 :
                   (error_q)                ? 1'b1 :
                   (i_error)                ? 1'b1 :
                   ((state_q == RecvData) & 
                    ~i_rd_empty)            ? (i_rd_data != lfsr_q) :
                                              error_q;

  assign finished_d = ((state_q == Idle) & (state_d == SendCmd))  ? 1'b0 :
                      ((state_q == RecvData) & (state_d == Idle)) ? 1'b1 :
                                                                    finished_q;


  // ==========================================================================
  // Outputs
  // ==========================================================================
  assign o_cmd_en        = (state_q == SendCmd) | (state_q == RecvCmd);
  assign o_cmd_instr     = (state_q == SendCmd) ? 3'b010 : 3'b011;
  assign o_cmd_bl        = 6'd31;
  assign o_cmd_byte_addr = {3'b000, adr_cnt_q, 5'b0, 2'b0};
  assign o_wr_en         = (state_q == SendData) & ~i_wr_almost_full;
  assign o_wr_mask       = 4'b0000;
  assign o_wr_data       = lfsr_q;
  assign o_rd_en         = (state_q == RecvData);

  assign o_finished      = finished_q;
  assign o_pass          = ~error_q;


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_ddr) begin
    if (rst_ddr) begin
      state_q        <= #`dh Idle;
      finished_q     <= #`dh 1'b0;
    end
    else begin
      state_q        <= #`dh state_d;
      finished_q     <= #`dh finished_d;
    end
  end
  
  always @(posedge clk_ddr) begin
    adr_cnt_q      <= #`dh adr_cnt_d;
    data_cnt_q     <= #`dh data_cnt_d;
    lfsr_q         <= #`dh lfsr_d;
    error_q        <= #`dh error_d;
  end


endmodule
