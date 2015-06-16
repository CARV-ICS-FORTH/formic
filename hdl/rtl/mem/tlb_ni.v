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
// Abstract      : TLB Network Interface
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: tlb_ni.v,v $
// CVS revision  : $Revision: 1.17 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module tlb_ni (

  // Clock and reset
  input         clk,
  input         rst,

  // BCTL interface
  output        o_bctl_drop,

  // Arbiter interface
  output        o_arb_req,
  input         i_arb_gnt,
  output        o_arb_done,

  // TLB interface
  output [11:0] o_tlb_virt_adr,
  input   [6:0] i_tlb_phys_adr,
  input         i_tlb_entry_valid,

  // Timestamp interface
  input  [15:0] i_timestamp_current,
  input  [15:0] i_timestamp_vc1,
  input         i_timestamp_vc1_empty,
  output        o_timestamp_vc1_deq,
  input  [15:0] i_timestamp_vc2,
  input         i_timestamp_vc2_empty,
  output        o_timestamp_vc2_deq,

  // XBI receive packet interface
  output  [2:0] o_xbi_in_deq,
  output  [4:0] o_xbi_in_offset,
  output        o_xbi_in_eop,
  input  [31:0] i_xbi_in_data,
  input   [2:0] i_xbi_in_empty,

  // XBI send packet interface
  output  [2:0] o_xbi_out_enq,
  output  [4:0] o_xbi_out_offset,
  output        o_xbi_out_eop,
  output [31:0] o_xbi_out_data,
  input   [2:0] i_xbi_out_full,

  // DDR controller interface
  output        o_ddr_cmd_en,
  output  [2:0] o_ddr_cmd_instr,
  output  [5:0] o_ddr_cmd_bl,
  output [29:0] o_ddr_cmd_byte_addr,
  input         i_ddr_cmd_full,
  input         i_ddr_cmd_empty,
  output        o_ddr_wr_en,
  output [31:0] o_ddr_wr_data,
  output  [3:0] o_ddr_wr_mask,
  input         i_ddr_wr_almost_full,
  output        o_ddr_rd_en,
  input  [31:0] i_ddr_rd_data,
  input         i_ddr_rd_empty
);

 // Minimum latency in CPU cycles that each DRAM packet should 
 // see before being serviced
  localparam [9:0] MIN_LATENCY = 10'd50;

// Type of input packets expected and respective output packets generated:
//
//    | Input -> Output  | Input    No  | Input -> Output  | Input -> Output 
//    | W ack    W ~ack  | W ~ack   Out | R ack    W ack   | R ~ack   W ~ack 
// ---+------------------+--------------+------------------+------------------
// 0H | W,size   2       | W,size   x   | R        size    | R        size   
// 0L | ben      AckBrd  | ben      x   | x        SrcBrd  | x        SrcBrd 
// ---+------------------+--------------+------------------+------------------
// 1H | VirtH    AckAdrH | VirtH    x   | VirtH    SrcAdrH | VirtH    SrcAdrH
// 1L | VirtL    AckAdrL | VirtL    x   | VirtL    SrcAdrL | VirtL    SrcAdrL
// ---+------------------+--------------+------------------+------------------
// 2H | AckBrd   x       | x        x   | AckBrd   AckBrd  | x        x      
// 2L | AckAdrH  x       | x        x   | AckAdrH  AckAdrH | x        x     
// ---+------------------+--------------+------------------+------------------
// 3H | AckAdrL  x       | x        x   | AckAdrL  AckAdrL | x        x     
// 3L | Wdata0H  0       | Wdata0H  x   | SrcBrd   Rdata0H | SrcBrd   Rdata0H
// ---+------------------+--------------+------------------+------------------
// 4H | Wdata0L  size    | Wdata0L  x   | SrcAdrH  Rdata0L | SrcAdrH  Rdata0L
// 4L | Wdata1H          | Wdata1H  x   | SrcAdrL  Rdata1H | SrcAdrL  Rdata1H
// ---+------------------+--------------+------------------+------------------
// 5H | Wdata1L          | Wdata1L  x   | size     Rdata1L | size     Rdata1L
// 5L | ...              | ...      x   | size     ...     | size     ...    
// ---+------------------+--------------+------------------+------------------

// State progression for the 4 cases:
//
// ---+------------------+--------------+------------------+------------------
//    | Deq0             | Deq0         | Deq0             | Deq0            
//    | Deq1             | Deq1         | Deq1             | Deq1            
//    | Deq2             | Deq3         | Deq2             | Deq3            
//    | Deq3             | ArbReq       | Deq3             | Deq4            
//    | ArbReq           |              | Deq4             | Deq5            
//    |                  |              | Deq5             | ArbReq          
//    |                  |              | ArbReq           |                 
// ---+------------------+--------------+------------------+------------------

// Left column:  regs read from XBI In during Deq* state
// Right column: content written to XBI Out and respective offset
// 
// ---+------------------+--------------+------------------+------------------
// 0H | size     0    2H | size         | x                | x        0    2H 
// 0L |          0    2L |              |                  |          0    2L  
// ---+------------------+--------------+------------------+------------------
// 1H | virt     0    3H | virt         | virt             | virt            
// 1L |          0    3L |              |                  |                 
// ---+------------------+--------------+------------------+------------------
// 2H | tmp2             | xxxxxxxxxxxx | tmpH             | xxxxxxxxxxxxxxxx
// 2L | tmpL             | xxxxxxxxxxxx | tmpL             | xxxxxxxxxxxxxxxx
// ---+------------------+--------------+------------------+------------------
// 3H | tmp3     sz=2 0H |              | tmp3     tmpH 2H |                
// 3L | dataL    tmp2 0L | dataL        | tmp2     tmpL 2L | tmp2            
// ---+------------------+--------------+------------------+------------------
// 4H | [ArbReq] tmpL 1H | xxxxxxxxxxxx | tmpH             | tmpH            
// 4L |          tmp3 1L | xxxxxxxxxxxx | tmpL             | tmpL            
// ---+------------------+--------------+------------------+------------------
// 5H | xxxxxxxxxxxxxxxx | xxxxxxxxxxxx | size     tmpH 1H | size     tmpH 1H
// 5L | xxxxxxxxxxxxxxxx | xxxxxxxxxxxx |          tmpL 1L |          tmpL 1L
// ---+------------------+--------------+------------------+------------------
//    | xxxxxxxxxxxxxxxx | xxxxxxxxxxxx | [ArbReq] size 0H | [ArbReq] size 0H
//    | xxxxxxxxxxxxxxxx | xxxxxxxxxxxx |          tmp2 0L |          tmp2 0L
// ---+------------------+--------------+------------------+------------------
// ---+------------------+--------------+------------------+------------------
//    | [EnqAck] size 4H |              | [Enq    tmp3  3H | [Enq    0     3H
//    |          0    4L |              |  Data]  Rdt0H 3L |  Data]  Rdt0H 3L
// ---+------------------+--------------+------------------+------------------


  // ==========================================================================
  // Wires
  // ==========================================================================
  wire        vc1_eligible;
  wire        vc2_eligible;

  wire        serving_vc2_d;
  reg         serving_vc2_q;
  wire  [2:0] deq_vc;
  wire  [2:0] enq_vc;

  wire  [7:0] opcode_d;
  reg   [7:0] opcode_q;
  wire        opcode_is_read_d;
  wire        opcode_is_read_q;
  wire        opcode_has_ack_d;
  wire        opcode_has_ack_q;
  wire        opcode_error;
  wire  [1:0] vc_d;
  reg   [1:0] vc_q;
  wire        vc_error;
  wire  [5:0] size_d;
  reg   [5:0] size_q;
  wire  [3:0] ben_d;
  reg   [3:0] ben_q;
  wire        size_error;

  wire [31:0] virtual_adr_d;
  reg  [31:0] virtual_adr_q;
  wire  [6:0] translation_d;
  reg   [6:0] translation_q;
  wire [26:0] physical_adr;

  wire [15:0] tmp_lo_d;
  reg  [15:0] tmp_lo_q;
  wire [15:0] tmp_hi_d;
  reg  [15:0] tmp_hi_q;
  wire [15:0] tmp2_d;
  reg  [15:0] tmp2_q;
  wire [15:0] tmp3_d;
  reg  [15:0] tmp3_q;

  wire  [7:0] hdr_w_ack;
  wire  [7:0] hdr_r_ack;
  wire  [7:0] hdr_r_noack;
  wire  [7:0] hdr_w_fault;
  wire  [7:0] hdr_r_fault;

  wire  [4:0] deq_cnt_d;
  reg   [4:0] deq_cnt_q;
  wire        deq_cnt_end;
  wire  [4:0] deq_offset;
  wire [15:0] deq_tmp_d;
  reg  [15:0] deq_tmp_q;
  wire [31:0] ddr_wr_data_d;
  reg  [31:0] ddr_wr_data_q;
  wire        ddr_wr_en_d;
  reg         ddr_wr_en_q;
  wire        ddr_rd_empty_d;
  reg         ddr_rd_empty_q;

  wire  [4:0] enq_cnt_d;
  reg   [4:0] enq_cnt_q;
  wire        enq_cnt_end;
  wire  [4:0] enq_offset;
  wire [15:0] enq_tmp_d;
  reg  [15:0] enq_tmp_q;
  wire [31:0] enq_data_d;
  reg  [31:0] enq_data_q;

  wire [15:0] timestamp_allowed;
  wire        timestamp_vc1_ok;
  wire        timestamp_vc2_ok;


  
  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle       = 21'b0_0000_0000_0000_0000_0001,
             Deq0       = 21'b0_0000_0000_0000_0000_0010,
             Deq1       = 21'b0_0000_0000_0000_0000_0100,
             Deq2       = 21'b0_0000_0000_0000_0000_1000,
             Deq3       = 21'b0_0000_0000_0000_0001_0000,
             Deq4       = 21'b0_0000_0000_0000_0010_0000,
             Deq5       = 21'b0_0000_0000_0000_0100_0000,
             ArbReq     = 21'b0_0000_0000_0000_1000_0000,
             Translate  = 21'b0_0000_0000_0001_0000_0000,
             DeqInit    = 21'b0_0000_0000_0010_0000_0000,
             DeqData    = 21'b0_0000_0000_0100_0000_0000,
             CmdWrite   = 21'b0_0000_0000_1000_0000_0000,
             WaitWrite  = 21'b0_0000_0001_0000_0000_0000,
             EnqAck     = 21'b0_0000_0010_0000_0000_0000,
             CmdRead    = 21'b0_0000_0100_0000_0000_0000,
             EnqData    = 21'b0_0000_1000_0000_0000_0000,
             EnqFlush   = 21'b0_0001_0000_0000_0000_0000,
             EnqReply   = 21'b0_0010_0000_0000_0000_0000,
             Done       = 21'b0_0100_0000_0000_0000_0000,
             Drop       = 21'b0_1000_0000_0000_0000_0000,
             TLBFault   = 21'b1_0000_0000_0000_0000_0000;

  reg  [20:0] state_d;
  reg  [20:0] state_q;

  // synthesis translate_off
  reg [256:0] StateString;
  always @(state_q) begin
    case (state_q)
      Idle       : StateString = "Idle";
      Deq0       : StateString = "Deq0";
      Deq1       : StateString = "Deq1";
      Deq2       : StateString = "Deq2";
      Deq3       : StateString = "Deq3";
      Deq4       : StateString = "Deq4";
      Deq5       : StateString = "Deq5";
      ArbReq     : StateString = "ArbReq";
      Translate  : StateString = "Translate";
      DeqInit    : StateString = "DeqInit";
      DeqData    : StateString = "DeqData";
      CmdWrite   : StateString = "CmdWrite";
      WaitWrite  : StateString = "WaitWrite";
      EnqAck     : StateString = "EnqAck";
      CmdRead    : StateString = "CmdRead";
      EnqData    : StateString = "EnqData";
      EnqFlush   : StateString = "EnqFlush";
      EnqReply   : StateString = "EnqReply";
      Done       : StateString = "Done";
      Drop       : StateString = "Drop";
      TLBFault   : StateString = "TLBFault";
      default    : StateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
        if (vc1_eligible | vc2_eligible)
          state_d = Deq0;
        else
          state_d = Idle;
        end

      Deq0: begin
          state_d = Deq1;
        end

      Deq1: begin
          if (vc_error) 
            state_d = Drop;
          else if (opcode_has_ack_q) 
            state_d = Deq2;
          else
            state_d = Deq3;
        end

      Deq2: begin
          state_d = Deq3;
        end

      Deq3: begin
          if (opcode_is_read_q) 
            state_d = Deq4;
          else
            state_d = ArbReq;
        end

      Deq4: begin
          state_d = Deq5;
        end

      Deq5: begin
          state_d = ArbReq;
        end

      ArbReq: begin
          if (size_error) begin
            if (opcode_has_ack_q | opcode_is_read_q) 
              state_d = TLBFault;
            else
              state_d = Drop;
          end
          else if (i_arb_gnt) 
            state_d = Translate;
          else
            state_d = ArbReq;
        end

      Translate: begin
        if (~i_tlb_entry_valid)  begin
          if (~opcode_is_read_q & ~opcode_has_ack_q)
            state_d = Drop;
          else
            state_d = TLBFault;
        end
        else if (opcode_is_read_q) 
          state_d = CmdRead;
        else
          state_d = DeqInit;
        end

      DeqInit: begin
          if (~i_ddr_wr_almost_full)
            state_d = DeqData;
          else
            state_d = DeqInit;
        end

      DeqData: begin
        if (deq_cnt_end & ~i_ddr_wr_almost_full)
          state_d = CmdWrite;
        else
          state_d = DeqData;
        end

      CmdWrite: begin
          if (i_ddr_cmd_full)
            state_d = CmdWrite;
          else if (opcode_has_ack_q)
            state_d = WaitWrite;
          else
            state_d = Done;
        end

      WaitWrite: begin
          if (~i_ddr_cmd_empty)
            state_d = WaitWrite;
          else
            state_d = EnqAck;
        end

      EnqAck: begin
          state_d = Done;
        end

      CmdRead: begin
        if (i_ddr_cmd_full)
          state_d = CmdRead;
        else
          state_d = EnqData;
        end

      EnqData: begin
        if (enq_cnt_end & ~i_ddr_rd_empty)
          state_d = EnqFlush;
        else
          state_d = EnqData;
        end

      EnqFlush: begin
          state_d = EnqReply;
        end

      EnqReply: begin
          state_d = Done;
        end

      Done: begin
          state_d = Idle;
        end

      Drop: begin
          state_d = Idle;
        end

      TLBFault: begin
          state_d = Idle;
        end

      default:
        begin
          state_d = Idle;
        end
    endcase
  end

  // ==========================================================================
  // XBI logic
  // ==========================================================================

  assign timestamp_allowed = i_timestamp_current - MIN_LATENCY;

  assign timestamp_vc1_ok = ((i_timestamp_vc1[15:14] == 
                              timestamp_allowed[15:14]) && 
                             (i_timestamp_vc1[13:0] < 
                              timestamp_allowed[13:0])) |
                            (i_timestamp_vc1[15:14] ==
                             timestamp_allowed[15:14] - 2'b01);

  assign timestamp_vc2_ok = ((i_timestamp_vc2[15:14] == 
                              timestamp_allowed[15:14]) && 
                             (i_timestamp_vc2[13:0] < 
                              timestamp_allowed[13:0])) |
                            (i_timestamp_vc2[15:14] ==
                             timestamp_allowed[15:14] - 2'b01);

  assign o_timestamp_vc1_deq = (state_q == Deq0) & ~serving_vc2_q;
  assign o_timestamp_vc2_deq = (state_q == Deq0) &  serving_vc2_q;

  
  // VC1 is definitely a write. It may request an ack.
  assign vc1_eligible = ~i_xbi_in_empty[1] & 
                        ~i_xbi_out_full[0] &
                        ~i_timestamp_vc1_empty & timestamp_vc1_ok;

  // VC2 may be a read or write. We make sure that a write response or
  // an ack packet can be generated.
  assign vc2_eligible = ~i_xbi_in_empty[2] & 
                        ~i_xbi_out_full[1] & ~i_xbi_out_full[0] &
                        ~i_timestamp_vc2_empty & timestamp_vc2_ok;

  assign serving_vc2_d = ((state_q != Idle) | 
                          (~vc1_eligible & ~vc2_eligible)) ? serving_vc2_q :
                          ( vc1_eligible & ~vc2_eligible)  ? 1'b0 :
                          (~vc1_eligible &  vc2_eligible)  ? 1'b1 :
                                                             ~serving_vc2_q;

  assign deq_vc = {serving_vc2_d, ~serving_vc2_d, 1'b0};
  assign enq_vc = {1'b0, 
                   opcode_is_read_d, 
                   ~opcode_is_read_d & opcode_has_ack_d};

  assign o_xbi_in_offset = (state_d == Deq0)    ? 5'h0 :
                           (state_d == Deq1)    ? 5'h1 :
                           (state_d == Deq2)    ? 5'h2 :
                           (state_d == Deq3)    ? 5'h3 :
                           (state_d == Deq4)    ? 5'h4 :
                           (state_d == Deq5)    ? 5'h5 :
                                                  deq_offset;

  assign o_xbi_in_deq = ((state_d == Deq0) | (state_d == Deq1) |
                         (state_d == Deq2) | (state_d == Deq3) |
                         (state_d == Deq4) | (state_d == Deq5) |
                         (state_q == DeqInit) | (state_q == Drop) | 
                         (state_q == DeqData))  ? deq_vc : 3'b0;

  assign o_xbi_in_eop = ((state_q == DeqData) & deq_cnt_end & 
                         ~opcode_is_read_q) |
                        ((state_d == Deq5) & opcode_is_read_q) |
                        (state_q == Drop);

  assign o_xbi_out_offset = 
                         (state_q  == Deq0)                        ? 5'h2 :
                         (state_q  == Deq1)                        ? 5'h3 :
                         ((state_q == Deq3) & ~opcode_is_read_q)   ? 5'h0 :
                         ((state_q == Deq3) &  opcode_is_read_q)   ? 5'h2 :
                         (state_q  == Deq5)                        ? 5'h1 :
                         ((state_q == ArbReq) & ~opcode_is_read_q) ? 5'h1 :
                         ((state_q == ArbReq) &  opcode_is_read_q) ? 5'h0 :
                         (state_q  == TLBFault)                    ? 5'h0 :
                         (state_q  == EnqAck)                      ? 5'h4 :
                                                                     enq_offset;
  assign ddr_rd_empty_d = i_ddr_rd_empty;

  assign o_xbi_out_enq = ((state_q == Deq0) | 
                          ((state_q == Deq1) &
                           (~opcode_is_read_q & opcode_has_ack_q)) |
                          ((state_q == Deq3) & 
                           (~opcode_is_read_q | opcode_has_ack_q)) |
                          (state_q == Deq5) |
                          (state_q == ArbReq) |
                          (state_q == EnqAck) | 
                          ((state_q == EnqData) & ~ddr_rd_empty_q) |
                          (state_q == EnqFlush) |
                          (state_q == EnqReply)) ? enq_vc : 3'b0;

  assign o_xbi_out_eop = (state_q == EnqReply) | (state_q == EnqAck);

  assign o_xbi_out_data = 
                    (state_q  == Deq0)       ? 32'h0 :
                    (state_q  == Deq1)       ? 32'h0 :
                    ((state_q == Deq3) & 
                     ~opcode_is_read_q)      ? {hdr_w_ack, 8'h2, tmp2_q} :
                    ((state_q == Deq3) &     
                      opcode_is_read_q)      ? {tmp_hi_q, tmp_lo_q} :
                    (state_q  == Deq5)       ? {tmp_hi_q, tmp_lo_q} :
                    ((state_q == ArbReq) &    
                     ~opcode_is_read_q)      ? {tmp_lo_q, tmp3_q} :
                    ((state_q == ArbReq) &     
                      opcode_is_read_q &
                      opcode_has_ack_q)      ? {hdr_r_ack, size_q, tmp2_q} :
                    ((state_q == ArbReq) &     
                      opcode_is_read_q &
                     ~opcode_has_ack_q)      ? {hdr_r_noack, size_q, tmp2_q} :
                    ((state_q == TLBFault) &    
                     ~opcode_is_read_q)      ? {hdr_w_fault, 8'h0, tmp2_q} :
                    ((state_q == TLBFault) &    
                      opcode_is_read_q)      ? {hdr_r_fault, 8'h0, tmp2_q} :
                    (state_q  == EnqAck)     ? {9'h0, size_q, 17'h0} :
                                               enq_data_q;


  // ==========================================================================
  // Header decoding stuff
  // ==========================================================================
  assign opcode_d = (state_q == Deq0) ? i_xbi_in_data[31:24] : opcode_q;
  assign vc_d     = (state_q == Deq0) ? i_xbi_in_data[23:22] : vc_q;

  assign opcode_is_read_d = opcode_d[6];
  assign opcode_is_read_q = opcode_q[6];

  assign opcode_has_ack_d = opcode_d[1];
  assign opcode_has_ack_q = opcode_q[1];

  assign vc_error = ( serving_vc2_q & (vc_q != 2'b10)) |
                    (~serving_vc2_q & (vc_q != 2'b01));

  assign size_d = ((state_q == Deq0) & 
                   ~opcode_is_read_d)     ? i_xbi_in_data[21:16] :
                  (state_q == Deq5)       ? i_xbi_in_data[6:1] :
                                            size_q;

  assign ben_d = (state_q != Deq0) ? ben_q :
                 (size_d == 6'd2)  ? i_xbi_in_data[15:12] : 
                                     4'b1111;
        
  assign size_error = (size_q > 6'd32) | (size_q == 6'd0) | size_q[0];

  assign tmp_hi_d = (((state_q == Deq2) & opcode_has_ack_q & opcode_is_read_q) |
                     ((state_q == Deq4) & opcode_is_read_q)) ? 
                                                        i_xbi_in_data[31:16] :
                                                        tmp_hi_q;

  assign tmp_lo_d = (((state_q == Deq2) & (opcode_has_ack_q)) |
                     ((state_q == Deq4) & (opcode_is_read_q))) ? 
                                                        i_xbi_in_data[15:0] :
                                                        tmp_lo_q;

  assign tmp2_d = ((state_q == Deq3) & 
                   (opcode_is_read_q)) ?  i_xbi_in_data[15:0] :
                  ((state_q == Deq2) & 
                   (~opcode_is_read_q)) ? i_xbi_in_data[31:16] :
                                          tmp2_q;

  assign tmp3_d = (state_q == Deq3) ? i_xbi_in_data[31:16] : tmp3_q;

  assign hdr_w_ack =   {1'b0,         // fault
                        1'b0,         // clean on dst
                        1'b0,         // write through on dst
                        opcode_q[2],  // miss/fill traffic
                        1'b0,         // no ack
                        1'b0,         // ignore dirty on src
                        2'b00};       // Ack VC (#0)

  assign hdr_r_noack = {1'b0,         // no fault
                        opcode_q[4],  // clean on dst
                        opcode_q[3],  // write through on dst
                        opcode_q[2],  // miss/fill traffic
                        1'b0,         // no ack
                        1'b0,         // ignore dirty on src
                        2'b01};       // Data VC (#1)

  assign hdr_r_ack   = {1'b0,         // no fault
                        opcode_q[4],  // clean on dst
                        opcode_q[3],  // write through on dst
                        opcode_q[2],  // miss/fill traffic
                        1'b1,         // has ack
                        1'b0,         // ignore dirty on src
                        2'b01};       // Data VC (#1)

  assign hdr_w_fault = {1'b1,         // fault
                        1'b0,         // clean on dst
                        1'b0,         // write through on dst
                        opcode_q[2],  // miss/fill traffic
                        1'b0,         // no ack
                        1'b0,         // ignore dirty on src
                        2'b00};       // Ack VC (#0)

  assign hdr_r_fault = {1'b1,         // fault
                        1'b0,         // clean on dst
                        1'b0,         // write through on dst
                        opcode_q[2],  // miss/fill traffic
                        1'b0,         // no ack
                        1'b0,         // ignore dirty on src
                        2'b01};       // Data VC (#1)

  
  // ==========================================================================
  // XBI dequeue to DDR write datapath
  // ==========================================================================
  assign deq_cnt_d = (state_q == Translate)     ? 5'b0 :
                     (((state_q == DeqInit) | 
                       (state_q == DeqData)) & 
                      ~i_ddr_wr_almost_full)    ? deq_cnt_q + 1'b1 :
                                                  deq_cnt_q;

  assign deq_offset = 5'h4 + ((i_ddr_wr_almost_full) ? deq_cnt_q - 1'b1 : 
                                                       deq_cnt_q);

  assign deq_cnt_end = (deq_cnt_q == size_q[5:1] + 1'b1);

  assign deq_tmp_d = ((state_q == Deq3) |
                      ((state_q == DeqData) & 
                       ~i_ddr_wr_almost_full)) ? i_xbi_in_data[15:0] :
                                                 deq_tmp_q;
  assign ddr_wr_data_d = (((state_q == DeqInit) |
                           (state_q == DeqData)) & 
                          ~i_ddr_wr_almost_full) ? {deq_tmp_q, 
                                                    i_xbi_in_data[31:16]} :
                                                   ddr_wr_data_q;

  assign ddr_wr_en_d = (state_q == DeqData) & ~deq_cnt_end & 
                       ~i_ddr_wr_almost_full;


  // ==========================================================================
  // DDR read to XBI enqueue datapath
  // ==========================================================================
  assign enq_cnt_d = (state_q == CmdRead)       ? 5'b0 :
                     (((state_q == EnqData) & 
                       ~i_ddr_rd_empty) | 
                      (state_q == EnqFlush))    ? enq_cnt_q + 1'b1 :
                                                  enq_cnt_q;

  assign enq_cnt_end = (enq_cnt_q == size_q[5:1] - 1'b1);

  assign enq_offset = 5'h2 + enq_cnt_q;

  assign enq_tmp_d = ((state_q == CmdRead) &
                      opcode_has_ack_q)       ? tmp3_q :
                     ((state_q == CmdRead) &
                      ~opcode_has_ack_q)      ? 16'h0 :
                     ((state_q == EnqData) & 
                      ~i_ddr_rd_empty)        ? i_ddr_rd_data[15:0] :
                                                enq_tmp_q;

  assign enq_data_d = ((state_q == EnqData) & 
                        ~i_ddr_rd_empty)      ? {enq_tmp_q,
                                                 i_ddr_rd_data[31:16]} :
                       (state_q == EnqFlush)  ? {enq_tmp_q, 16'b0} :
                                                enq_data_q;


  // ==========================================================================
  // TLB logic
  // ==========================================================================
  assign virtual_adr_d = (state_q == Deq1) ? {i_xbi_in_data[31:2], 2'b00} : 
                                             virtual_adr_q;

  assign o_tlb_virt_adr = virtual_adr_q[31:20];

  assign translation_d = (state_q == Translate) ? i_tlb_phys_adr : 
                                                  translation_q;

  assign physical_adr = {translation_q, virtual_adr_q[19:0]};

  assign o_arb_req = (state_q == ArbReq) & ~size_error;
  
  assign o_arb_done = (state_q == Done);

  assign o_bctl_drop = (state_q == Drop);


  // ==========================================================================
  // DDR controller signals
  // ==========================================================================
  assign o_ddr_wr_data = ddr_wr_data_q;
  assign o_ddr_wr_mask = ~ben_q;
  assign o_ddr_wr_en = ddr_wr_en_q;

  assign o_ddr_cmd_en = (state_q == CmdWrite) | (state_q == CmdRead);
  assign o_ddr_cmd_instr = (state_q == CmdWrite) ? 3'b010 : 3'b011;
  assign o_ddr_cmd_byte_addr = {3'b000, physical_adr};
  assign o_ddr_cmd_bl = {2'b00, size_q[5:1] - 4'd1};                    

  assign o_ddr_rd_en = (state_q == EnqData);

  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk) begin
    if (rst) begin
      serving_vc2_q         <= #`dh 0;
      state_q               <= #`dh Idle;
      ddr_wr_en_q           <= #`dh 0;
    end
    else begin
      serving_vc2_q         <= #`dh serving_vc2_d;
      state_q               <= #`dh state_d;
      ddr_wr_en_q           <= #`dh ddr_wr_en_d;
    end
  end
  
  always @(posedge clk) begin
    opcode_q                <= #`dh opcode_d;
    size_q                  <= #`dh size_d;
    ben_q                   <= #`dh ben_d;
    vc_q                    <= #`dh vc_d;
    tmp_hi_q                <= #`dh tmp_hi_d;
    tmp_lo_q                <= #`dh tmp_lo_d;
    tmp2_q                  <= #`dh tmp2_d;
    tmp3_q                  <= #`dh tmp3_d;
    virtual_adr_q           <= #`dh virtual_adr_d;
    translation_q           <= #`dh translation_d;
    deq_cnt_q               <= #`dh deq_cnt_d;
    deq_tmp_q               <= #`dh deq_tmp_d;
    ddr_wr_data_q           <= #`dh ddr_wr_data_d;
    enq_cnt_q               <= #`dh enq_cnt_d;
    enq_tmp_q               <= #`dh enq_tmp_d;
    enq_data_q              <= #`dh enq_data_d; 
    ddr_rd_empty_q          <= #`dh ddr_rd_empty_d;
  end

endmodule

