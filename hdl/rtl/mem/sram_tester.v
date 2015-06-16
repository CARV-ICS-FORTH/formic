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
// Abstract      : SRAM memory auto-tester. Writes and then reads all the
//                 SRAM contents.
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: sram_tester.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module sram_tester(

  // Clocking
  input          clk_mc,
  input          rst_mc,

  // SRAM Controller
  output  [17:0] o_sctl_req_adr,
  output         o_sctl_req_we,
  output  [31:0] o_sctl_req_wdata,
  output  [ 3:0] o_sctl_req_be,
  output         o_sctl_req_valid,
  input   [31:0] i_sctl_resp_rdata,
  input          i_sctl_resp_valid,

  // Management
  input          i_start,
  input   [31:0] i_init_val,
  output         o_finished,
  output         o_pass,
  output  [15:0] o_error_cnt
);

  // Tester address limit: max is 16'hFFFF, which writes all words up to 256 KB
  //localparam CNT_END_VALUE = 16'h00FF;
  localparam CNT_END_VALUE = 16'hFFFF;

  // ==========================================================================
  // Wires
  // ==========================================================================
  reg  [15:0] send_cnt_q;
  wire [15:0] send_cnt_d;
  wire        send_cnt_end;

  reg  [15:0] recv_cnt_q;
  wire [15:0] recv_cnt_d;
  wire        recv_cnt_end;

  reg  [31:0] lfsr_q;
  wire [31:0] lfsr_d;

  reg         error_q;
  wire        error_d;
  reg         finished_q;
  wire        finished_d;
  reg  [15:0] error_cnt_q;
  wire [15:0] error_cnt_d;


  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle       = 4'b0001,
             Send       = 4'b0010,
             Recv       = 4'b0100,
             Wait       = 4'b1000;

  reg  [3:0] state_d;
  reg  [3:0] state_q;

  // synthesis translate_off
  reg [256:0] StateString;
  always @(state_q) begin
    case (state_q)
      Idle    : StateString = "Idle";
      Send    : StateString = "Send";
      Recv    : StateString = "Recv";
      Wait    : StateString = "Wait";
      default : StateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
        if (i_start)
          state_d = Send;
        else
          state_d = Idle;
        end

      Send: begin
          if (send_cnt_end) 
            state_d = Recv;
          else
            state_d = Send;
        end

      Recv: begin
          if (send_cnt_end)
            state_d = Wait;
          else
            state_d = Recv;
        end

      Wait: begin
          if (recv_cnt_end)
            state_d = Idle;
          else
            state_d = Wait;
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

  // Request address counter
  assign send_cnt_d = (((state_d == Send) &
                        (state_q != Send))|
                       ((state_d == Recv) &
                        (state_q != Recv))) ? 16'b0 :

                      ((state_q == Send) |
                       (state_q == Recv))   ? send_cnt_q + 1'b1 :
                                              send_cnt_q;

  assign send_cnt_end = (send_cnt_q == CNT_END_VALUE);

  // Send data / recv expected data LFSR
  assign lfsr_d = (((state_d == Send) &
                    (state_q != Send)) |
                   ((state_d == Recv) &
                    (state_q != Recv))) ? i_init_val :

                  ((state_q == Send) |
                   (i_sctl_resp_valid)) ? {(lfsr_q[31] ^ lfsr_q[21] ^
                                            lfsr_q[1]  ^ lfsr_q[0]), 
                                            lfsr_q[31:1]} :
                                           lfsr_q;
                       
  // Response counter
  assign recv_cnt_d = (state_q == Send)   ? 16'b0 :
                      (i_sctl_resp_valid) ? recv_cnt_q + 1'b1 :
                                            recv_cnt_q;

  assign recv_cnt_end = i_sctl_resp_valid & (recv_cnt_q == CNT_END_VALUE);


  // Completion
  assign error_d = ((state_q == Idle) & 
                    (state_d == Send))  ? 1'b0 :
                   (error_q)            ? 1'b1 :
                   (i_sctl_resp_valid)  ? (i_sctl_resp_rdata != lfsr_q) :
                                          error_q;

  assign finished_d = ((state_q == Idle) & (state_d == Send)) ? 1'b0 :
                      ((state_q == Wait) & (state_d == Idle)) ? 1'b1 :
                                                                finished_q;  

  assign error_cnt_d = ((state_q == Idle) & 
                        (state_d == Send))             ? 0 :
                       ((i_sctl_resp_valid) & 
                        (i_sctl_resp_rdata != lfsr_q)) ? error_cnt_q + 1'b1 :
                                                         error_cnt_q;


  // ==========================================================================
  // Outputs
  // ==========================================================================
  assign o_sctl_req_valid   = (state_q == Send) | (state_q == Recv);
  assign o_sctl_req_adr     = {send_cnt_q, 2'b00};
  assign o_sctl_req_we      = (state_q == Send);
  assign o_sctl_req_wdata   = lfsr_q;
  assign o_sctl_req_be      = 4'b1111;

  assign o_finished = finished_q;
  assign o_pass     = ~error_q;
  assign o_error_cnt = error_cnt_q;


  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk_mc) begin
    if (rst_mc) begin
      state_q        <= #`dh Idle;
      finished_q     <= #`dh 1'b0;
    end
    else begin
      state_q        <= #`dh state_d;
      finished_q     <= #`dh finished_d;
    end
  end

  always @(posedge clk_mc) begin
    send_cnt_q       <= #`dh send_cnt_d;
    lfsr_q           <= #`dh lfsr_d;
    recv_cnt_q       <= #`dh recv_cnt_d;
    error_q          <= #`dh error_d;
    error_cnt_q      <= #`dh error_cnt_d;
  end

endmodule
