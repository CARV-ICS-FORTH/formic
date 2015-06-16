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
// Abstract      : Crossbar input arbiter
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: xbar_arb_in.v,v $
// CVS revision  : $Revision: 1.14 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module xbar_arb_in # (

  parameter     ARM_MODE = 0

) (
  
  // Clock and reset
  input         clk,
  input         rst,

  // Static configuration
  input   [7:0] i_board_id,

  // Input FIFO interface
  output  [2:0] o_fifo_deq,
  output  [5:0] o_fifo_offset,
  output        o_fifo_eop,
  input  [15:0] i_fifo_data,
  input   [2:0] i_fifo_empty,

  // Output arbiters interface
  output [21:0] o_req0,
  output [21:0] o_req1,
  output [21:0] o_req2,
  input  [21:0] i_gnt0,
  input  [21:0] i_gnt1,
  input  [21:0] i_gnt2,

  // Switching fabric interface
  output [15:0] o_data
);

  // ==========================================================================
  // Wires
  // ==========================================================================
  wire [21:0] in_gnt0_d;
  reg  [21:0] in_gnt0_q;
  wire [21:0] in_gnt1_d;
  reg  [21:0] in_gnt1_q;
  wire [21:0] in_gnt2_d;
  reg  [21:0] in_gnt2_q;

  (* ram_style = "distributed" *)
  reg  [21:0] req0_d;
  reg  [21:0] req0_q;
  (* ram_style = "distributed" *)
  reg  [21:0] req1_d;
  reg  [21:0] req1_q;
  (* ram_style = "distributed" *)
  reg  [21:0] req2_d;
  reg  [21:0] req2_q;

  wire        my_w_d;
  (* equivalent_register_removal = "no" *)
  reg         my_w_q;
  wire  [1:0] my_x_d;
  (* equivalent_register_removal = "no" *)
  reg   [1:0] my_x_q;
  wire  [1:0] my_y_d;
  (* equivalent_register_removal = "no" *)
  reg   [1:0] my_y_q;
  wire  [1:0] my_z_d;
  (* equivalent_register_removal = "no" *)
  reg   [1:0] my_z_q;

  wire        dst_w_d;
  reg         dst_w_q;
  wire  [1:0] dst_x_d;
  reg   [1:0] dst_x_q;
  wire  [1:0] dst_y_d;
  reg   [1:0] dst_y_q;
  wire  [1:0] dst_z_d;
  reg   [1:0] dst_z_q;
  wire  [3:0] dst_node_d;
  reg   [3:0] dst_node_q;

  wire        diff_w;
  wire        same_x;
  wire        greater_x;
  wire        smaller_x;
  wire        greater_y;
  wire        smaller_y;
  wire        greater_z;
  wire        smaller_z;
  wire        remote;
  wire  [4:0] route_q;
  wire        dst_mem_q;
  wire  [4:0] route;

  wire  [2:0] mem_rr_cnt_d;
  reg   [2:0] mem_rr_cnt_q;

  wire        gnt0_d;
  reg         gnt0_q;
  wire        gnt1_d;
  reg         gnt1_q;
  wire        gnt2_d;
  reg         gnt2_q;
  wire        gnt;
  wire  [3:0] gnt_priority;

  wire        new_packet0;
  wire        new_packet1;
  wire        new_packet2;
  wire        dst_found;

  wire  [2:0] routing_vc_d;
  reg   [2:0] routing_vc_q;
  wire  [2:0] sending_vc_d;
  reg   [2:0] sending_vc_q;

  wire        packet_valid0_d;
  reg         packet_valid0_q;
  wire  [4:0] packet_port0_d;
  reg   [4:0] packet_port0_q;
  wire        packet_valid1_d;
  reg         packet_valid1_q;
  wire  [4:0] packet_port1_d;
  reg   [4:0] packet_port1_q;
  wire        packet_valid2_d;
  reg         packet_valid2_q;
  wire  [4:0] packet_port2_d;
  reg   [4:0] packet_port2_q;

  wire  [2:0] fifo_deq_d;
  reg   [2:0] fifo_deq_q;
  wire  [5:0] fifo_offset_d;
  reg   [5:0] fifo_offset_q;
  wire        fifo_eop_d;
  reg         fifo_eop_q;
  wire [15:0] data_d;
  reg  [15:0] data_q;
  wire  [2:0] empty_d;
  reg   [2:0] empty_q;
  wire  [5:0] size_d;
  reg   [5:0] size_q;

  // ==========================================================================
  // FSM
  // ==========================================================================
  localparam Idle       = 11'b000_0000_0001,
             ReadDst    = 11'b000_0000_0010,
             Route1     = 11'b000_0000_0100,
             Route2     = 11'b000_0000_1000,
             Start      = 11'b000_0001_0000,
             WaitMux    = 11'b000_0010_0000,
             Send       = 11'b000_0100_0000,
             Stop1      = 11'b000_1000_0000,
             Stop2      = 11'b001_0000_0000,
             Stop3      = 11'b010_0000_0000,
             Stop4      = 11'b100_0000_0000;

  reg  [10:0] state_d;
  reg  [10:0] state_q;

  // synthesis translate_off
  reg [256:0] InArbiterStateString;
  always @(state_q) begin
    case (state_q)
      Idle       : InArbiterStateString = "Idle";
      ReadDst    : InArbiterStateString = "ReadDst";
      Route1     : InArbiterStateString = "Route1";
      Route2     : InArbiterStateString = "Route2";
      Start      : InArbiterStateString = "Start";
      WaitMux    : InArbiterStateString = "WaitMux";
      Send       : InArbiterStateString = "Send";
      Stop1      : InArbiterStateString = "Stop1";
      Stop2      : InArbiterStateString = "Stop2";
      Stop3      : InArbiterStateString = "Stop3";
      Stop4      : InArbiterStateString = "Stop4";
      default    : InArbiterStateString = "ERROR";
    endcase
  end
  // synthesis translate_on

  always @(*) begin
    case (state_q)

      Idle: begin
          if (gnt)
            state_d = Start;
          else if (new_packet0 | new_packet1 | new_packet2)
            state_d = ReadDst;
          else 
            state_d = Idle;
        end

      ReadDst: begin
          if (gnt)
            state_d = Start;
          else if (dst_found)
            state_d = Route1;
          else 
            state_d = ReadDst;
        end

      Route1: begin
          if (gnt)
            state_d = Start;
          else 
            state_d = Route2;
        end

      Route2: begin
          if (gnt)
            state_d = Start;
          else 
            state_d = Idle;
        end

      Start: begin
          state_d = WaitMux;
        end

      WaitMux: begin
          state_d = Send;
        end

      Send: begin
          if (fifo_eop_q)
            state_d = Stop1;
          else
            state_d = Send;
        end

      Stop1: begin
          state_d = Stop2;
        end

      Stop2: begin
          state_d = Stop3;
        end

      Stop3: begin
          state_d = Stop4;
        end

      Stop4: begin
          state_d = Idle;
        end

      default:
        begin
          state_d = Idle;
        end
    endcase
  end

  
  // ==========================================================================
  // Req-gnt stuff
  // ==========================================================================
  assign in_gnt0_d = i_gnt0;
  assign in_gnt1_d = i_gnt1;
  assign in_gnt2_d = i_gnt2;
  
  assign gnt0_d = | in_gnt0_q;
  assign gnt1_d = | in_gnt1_q;
  assign gnt2_d = | in_gnt2_q;

  assign gnt = gnt0_q | gnt1_q | gnt2_q;

  RR_prior_enf_combout # (
    .N_log      ( 2 )
  ) i0_RR_prior_enf (
    .Clk        ( clk ),
    .Rst        ( rst ),
    .In         ( {1'b0, gnt2_q, gnt1_q, gnt0_q} ),
    .Out        ( gnt_priority ),
    .ld_en      ( (state_d == Start) )
  );

  assign sending_vc_d = (state_d != Start) ? sending_vc_q : gnt_priority[2:0];

  assign new_packet0 = ~empty_q[0] & ~packet_valid0_q;
  assign new_packet1 = ~empty_q[1] & ~packet_valid1_q;
  assign new_packet2 = ~empty_q[2] & ~packet_valid2_q;

  assign routing_vc_d = (state_q != Idle) ? routing_vc_q :
                        (new_packet0) ? 3'b001 :
                        (new_packet1) ? 3'b010 : 
                                        3'b100 ;

  assign dst_found = (state_q == ReadDst) & (data_q[14:12] == routing_vc_q);

  always @(*) begin
    if ((state_q == Idle) & packet_valid0_q) begin
      (* full_case *)
      case (packet_port0_q)
        5'd00   : req0_d = 22'b0000000000000000000001;
        5'd01   : req0_d = 22'b0000000000000000000010;
        5'd02   : req0_d = 22'b0000000000000000000100;
        5'd03   : req0_d = 22'b0000000000000000001000;
        5'd04   : req0_d = 22'b0000000000000000010000;
        5'd05   : req0_d = 22'b0000000000000000100000;
        5'd06   : req0_d = 22'b0000000000000001000000;
        5'd07   : req0_d = 22'b0000000000000010000000;
        5'd08   : req0_d = 22'b0000000000000100000000;
        5'd09   : req0_d = 22'b0000000000001000000000;
        5'd10   : req0_d = 22'b0000000000010000000000;
        5'd11   : req0_d = 22'b0000000000100000000000;
        5'd12   : req0_d = 22'b0000000001000000000000;
        5'd13   : req0_d = 22'b0000000010000000000000;
        5'd14   : req0_d = 22'b0000000100000000000000;
        5'd15   : req0_d = 22'b0000001000000000000000;
        5'd16   : req0_d = 22'b0000010000000000000000;
        5'd17   : req0_d = 22'b0000100000000000000000;
        5'd18   : req0_d = 22'b0001000000000000000000;
        5'd19   : req0_d = 22'b0010000000000000000000;
        5'd20   : req0_d = 22'b0100000000000000000000;
        5'd21   : req0_d = 22'b1000000000000000000000;
        default : req0_d = 22'bx;
      endcase
    end
    else if (((state_q == Start)   & ~sending_vc_q[0]) |
             ((state_q == WaitMux) &  sending_vc_q[0])) begin
      req0_d = 22'b0;
    end
    else begin
      req0_d = req0_q;
    end
  end

  always @(*) begin
    if ((state_q == Idle) & packet_valid1_q) begin
      (* full_case *)
      case (packet_port1_q)
        5'd00   : req1_d = 22'b0000000000000000000001;
        5'd01   : req1_d = 22'b0000000000000000000010;
        5'd02   : req1_d = 22'b0000000000000000000100;
        5'd03   : req1_d = 22'b0000000000000000001000;
        5'd04   : req1_d = 22'b0000000000000000010000;
        5'd05   : req1_d = 22'b0000000000000000100000;
        5'd06   : req1_d = 22'b0000000000000001000000;
        5'd07   : req1_d = 22'b0000000000000010000000;
        5'd08   : req1_d = 22'b0000000000000100000000;
        5'd09   : req1_d = 22'b0000000000001000000000;
        5'd10   : req1_d = 22'b0000000000010000000000;
        5'd11   : req1_d = 22'b0000000000100000000000;
        5'd12   : req1_d = 22'b0000000001000000000000;
        5'd13   : req1_d = 22'b0000000010000000000000;
        5'd14   : req1_d = 22'b0000000100000000000000;
        5'd15   : req1_d = 22'b0000001000000000000000;
        5'd16   : req1_d = 22'b0000010000000000000000;
        5'd17   : req1_d = 22'b0000100000000000000000;
        5'd18   : req1_d = 22'b0001000000000000000000;
        5'd19   : req1_d = 22'b0010000000000000000000;
        5'd20   : req1_d = 22'b0100000000000000000000;
        5'd21   : req1_d = 22'b1000000000000000000000;
        default : req1_d = 22'bx;
      endcase
    end
    else if (((state_q == Start)   & ~sending_vc_q[1]) |
             ((state_q == WaitMux) &  sending_vc_q[1])) begin
      req1_d = 22'b0;
    end
    else begin
      req1_d = req1_q;
    end
  end

  always @(*) begin
    if ((state_q == Idle) & packet_valid2_q) begin
      (* full_case *)
      case (packet_port2_q)
        5'd00   : req2_d = 22'b0000000000000000000001;
        5'd01   : req2_d = 22'b0000000000000000000010;
        5'd02   : req2_d = 22'b0000000000000000000100;
        5'd03   : req2_d = 22'b0000000000000000001000;
        5'd04   : req2_d = 22'b0000000000000000010000;
        5'd05   : req2_d = 22'b0000000000000000100000;
        5'd06   : req2_d = 22'b0000000000000001000000;
        5'd07   : req2_d = 22'b0000000000000010000000;
        5'd08   : req2_d = 22'b0000000000000100000000;
        5'd09   : req2_d = 22'b0000000000001000000000;
        5'd10   : req2_d = 22'b0000000000010000000000;
        5'd11   : req2_d = 22'b0000000000100000000000;
        5'd12   : req2_d = 22'b0000000001000000000000;
        5'd13   : req2_d = 22'b0000000010000000000000;
        5'd14   : req2_d = 22'b0000000100000000000000;
        5'd15   : req2_d = 22'b0000001000000000000000;
        5'd16   : req2_d = 22'b0000010000000000000000;
        5'd17   : req2_d = 22'b0000100000000000000000;
        5'd18   : req2_d = 22'b0001000000000000000000;
        5'd19   : req2_d = 22'b0010000000000000000000;
        5'd20   : req2_d = 22'b0100000000000000000000;
        5'd21   : req2_d = 22'b1000000000000000000000;
        default : req2_d = 22'bx;
      endcase
    end
    else if (((state_q == Start)   & ~sending_vc_q[2]) |
             ((state_q == WaitMux) &  sending_vc_q[2])) begin
      req2_d = 22'b0;
    end
    else begin
      req2_d = req2_q;
    end
  end


  // ==========================================================================
  // Routing
  // ==========================================================================
  assign my_w_d = i_board_id[6];
  assign my_x_d = i_board_id[5:4];
  assign my_y_d = i_board_id[3:2];
  assign my_z_d = i_board_id[1:0];
  
  assign dst_w_d    = (dst_found) ? data_q[10]  : dst_w_q;
  assign dst_x_d    = (dst_found) ? data_q[9:8] : dst_x_q;
  assign dst_y_d    = (dst_found) ? data_q[7:6] : dst_y_q;
  assign dst_z_d    = (dst_found) ? data_q[5:4] : dst_z_q;
  assign dst_node_d = (dst_found) ? data_q[3:0] : dst_node_q;

  // Stage 1: routing table
  generate
    if (ARM_MODE == 0) begin

      // Formic board routing
      assign diff_w    = (dst_w_q != my_w_q);
      assign greater_x = (dst_x_q >  my_x_q);
      assign smaller_x = (dst_x_q <  my_x_q);
      assign greater_y = (dst_y_q >  my_y_q);
      assign smaller_y = (dst_y_q <  my_y_q);
      assign greater_z = (dst_z_q >  my_z_q);
      assign smaller_z = (dst_z_q <  my_z_q);
      
      xbar_route_formic i0_xbar_route_formic (
        .clk            ( clk ),
        .i_diff_w       ( diff_w ),
        .i_greater_x    ( greater_x ),
        .i_smaller_x    ( smaller_x ),
        .i_greater_y    ( greater_y ),
        .i_smaller_y    ( smaller_y ),
        .i_greater_z    ( greater_z ),
        .i_smaller_z    ( smaller_z ),
        .i_dst_node     ( dst_node_q ),
        .o_port         ( route_q ),
        .o_mem          ( dst_mem_q )
      );

    end
    else begin

      // Versatile board routing
      assign remote = ~((dst_w_q == my_w_q) & (dst_x_q[1] == my_x_q[1]) & 
                        (dst_y_q == my_y_q) & (dst_z_q == my_z_q));

      xbar_route_versatile i0_xbar_route_versatile (
        .clk            ( clk ),
        .i_remote       ( remote ),
        .i_my_x         ( my_x_q ),
        .i_dst_x        ( dst_x_q ),
        .i_dst_node     ( dst_node_q ),
        .o_port         ( route_q )
      );

      assign dst_mem_q = 1'b0;

    end
  endgenerate


  // Stage 2
  assign mem_rr_cnt_d = (state_q != Route2)      ? mem_rr_cnt_q :
                        (~dst_mem_q)             ? mem_rr_cnt_q :
                        (mem_rr_cnt_q == 3'b100) ? 3'b0 : 
                                                   mem_rr_cnt_q + 3'b1;

  assign route = (dst_mem_q) ? route_q + mem_rr_cnt_q : route_q;

  assign packet_valid0_d = ((state_q == Route2) & 
                            routing_vc_q[0]) ? 1'b1 :
                           ((state_q == Stop4) &
                            sending_vc_q[0]) ? 1'b0 : packet_valid0_q;
                           
  assign packet_valid1_d = ((state_q == Route2) & 
                            routing_vc_q[1]) ? 1'b1 :
                           ((state_q == Stop4) &
                            sending_vc_q[1]) ? 1'b0 : packet_valid1_q;
                           
  assign packet_valid2_d = ((state_q == Route2) & 
                            routing_vc_q[2]) ? 1'b1 :
                           ( (state_q == Stop4) &
                            sending_vc_q[2]) ? 1'b0 : packet_valid2_q;

  assign packet_port0_d = ((state_q == Route2) & 
                            routing_vc_q[0]) ? route : packet_port0_q;
                           
  assign packet_port1_d = ((state_q == Route2) & 
                            routing_vc_q[1]) ? route : packet_port1_q;
                           
  assign packet_port2_d = ((state_q == Route2) & 
                            routing_vc_q[2]) ? route : packet_port2_q;
                           

  // ==========================================================================
  // FIFO control
  // ==========================================================================

  assign fifo_deq_d[0] = ((state_d == WaitMux) | 
                          (state_d == Send)) & sending_vc_d[0];
  assign fifo_deq_d[1] = ((state_d == WaitMux) | 
                          (state_d == Send)) & sending_vc_d[1];
  assign fifo_deq_d[2] = ((state_d == WaitMux) | 
                          (state_d == Send)) & sending_vc_d[2];

  assign fifo_offset_d = (state_d == ReadDst) ? 6'd1 :
                         (state_d == WaitMux) ? 6'd0 :
                         (state_d == Send) ? fifo_offset_q + 1'b1 : 
                                             fifo_offset_q;

  assign size_d = (state_q == WaitMux) ? 6'd7 :
                  ((state_q == Send) & 
                   (fifo_offset_q == 6'd4)) ? (data_q[5:0] + 6'h5) : size_q;

  assign fifo_eop_d = (state_q == Send) & (fifo_offset_q == size_q);

  assign data_d = i_fifo_data;
  
  assign empty_d = i_fifo_empty;



  // ==========================================================================
  // Registers
  // ==========================================================================
  always @(posedge clk) begin
    if (rst) begin
      in_gnt0_q         <= #`dh 0;
      in_gnt1_q         <= #`dh 0;
      in_gnt2_q         <= #`dh 0;
      req0_q            <= #`dh 0;
      req1_q            <= #`dh 0;
      req2_q            <= #`dh 0;
      gnt0_q            <= #`dh 0;
      gnt1_q            <= #`dh 0;
      gnt2_q            <= #`dh 0;
      mem_rr_cnt_q      <= #`dh 0;
      state_q           <= #`dh Idle;
      packet_valid0_q   <= #`dh 0;
      packet_valid1_q   <= #`dh 0;
      packet_valid2_q   <= #`dh 0;
      fifo_deq_q        <= #`dh 0;
    end
    else begin
      in_gnt0_q         <= #`dh in_gnt0_d;
      in_gnt1_q         <= #`dh in_gnt1_d;
      in_gnt2_q         <= #`dh in_gnt2_d;
      req0_q            <= #`dh req0_d;
      req1_q            <= #`dh req1_d;
      req2_q            <= #`dh req2_d;
      gnt0_q            <= #`dh gnt0_d;
      gnt1_q            <= #`dh gnt1_d;
      gnt2_q            <= #`dh gnt2_d;
      mem_rr_cnt_q      <= #`dh mem_rr_cnt_d;
      state_q           <= #`dh state_d;
      packet_valid0_q   <= #`dh packet_valid0_d;
      packet_valid1_q   <= #`dh packet_valid1_d;
      packet_valid2_q   <= #`dh packet_valid2_d;
      fifo_deq_q        <= #`dh fifo_deq_d;
    end
  end

  always @(posedge clk) begin
    my_w_q              <= #`dh my_w_d;
    my_x_q              <= #`dh my_x_d;
    my_y_q              <= #`dh my_y_d;
    my_z_q              <= #`dh my_z_d;
    dst_w_q             <= #`dh dst_w_d;
    dst_x_q             <= #`dh dst_x_d;
    dst_y_q             <= #`dh dst_y_d;
    dst_z_q             <= #`dh dst_z_d;
    dst_node_q          <= #`dh dst_node_d;
    packet_port0_q      <= #`dh packet_port0_d;
    packet_port1_q      <= #`dh packet_port1_d;
    packet_port2_q      <= #`dh packet_port2_d;
    routing_vc_q        <= #`dh routing_vc_d;
    sending_vc_q        <= #`dh sending_vc_d;
    fifo_offset_q       <= #`dh fifo_offset_d;
    fifo_eop_q          <= #`dh fifo_eop_d;
    data_q              <= #`dh data_d;
    empty_q             <= #`dh empty_d;
    size_q              <= #`dh size_d;
  end

  // ==========================================================================
  // Outputs
  // ==========================================================================
  assign o_req0         = req0_q;
  assign o_req1         = req1_q;
  assign o_req2         = req2_q;
  assign o_fifo_deq     = fifo_deq_q;
  assign o_fifo_offset  = fifo_offset_q;
  assign o_fifo_eop     = fifo_eop_q;
  assign o_data         = data_q;

endmodule
