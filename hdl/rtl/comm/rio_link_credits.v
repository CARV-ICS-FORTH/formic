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
// Author        : Vassilis Papaefstathiou
// Abstract      : GTP credit logic
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rio_link_credits.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rio_link_credits(
  clk,
  rst,

  i_enq,
  i_ds_credit,
  i_ds_credit_valid,

  i_deq,
  o_us_credit,
  o_us_credit_valid,
  i_us_credit_accept,

  o_local_xoff
);


///////////////////////////////////////////////////////////////////////////////
// Parameters
parameter FIFO_SIZE = 4'd6;
parameter FIFO_FULL_THRESHOLD = 4'd4;
parameter FIFO_PTR_SIZE = 3;

parameter CREDIT_WIDTH = 16;

///////////////////////////////////////////////////////////////////////////////
// Ports
input clk;
input rst;

input [2:0] i_enq;
input [CREDIT_WIDTH-1:0] i_ds_credit;
input i_ds_credit_valid;

input [2:0] i_deq;
output [CREDIT_WIDTH-1:0] o_us_credit;
output o_us_credit_valid;
input i_us_credit_accept;

output [2:0] o_local_xoff;

///////////////////////////////////////////////////////////////////////////////
// CREDIT FORMAT (16-bits)
// ----------------------------------------------------------------------
// | even parity (1-bit) | vc one-hot (3-bits) | credit value (12-bits) |
// ----------------------------------------------------------------------
// |         15          |       14:12         |          11:0          |
// ----------------------------------------------------------------------
// credit value is the remote tail pointer (cummulative - wrap around)

//////////////////////////////////////////////////////////////////////////////
// INCOMING CREDITS from downstream (ds)
//
// parity checking of credits
wire ds_credit_parity = i_ds_credit[CREDIT_WIDTH-1];
// calculate even parity
wire ds_credit_parity_calc = ^i_ds_credit[CREDIT_WIDTH-2:0];
// check here
wire ds_credit_ok = ( ds_credit_parity == ds_credit_parity_calc ) & i_ds_credit_valid;
// decode credit reg enables
wire ds_credit0_valid = i_ds_credit[12] & i_ds_credit_valid & ds_credit_ok;
wire ds_credit1_valid = i_ds_credit[13] & i_ds_credit_valid & ds_credit_ok;
wire ds_credit2_valid = i_ds_credit[14] & i_ds_credit_valid & ds_credit_ok;

wire ds_credit_error = i_ds_credit_valid & (~(|i_ds_credit) | ~ds_credit_ok);

// remote tail pointer
reg [FIFO_PTR_SIZE-1: 0] ds_tail_ptr0;
reg [FIFO_PTR_SIZE-1: 0] ds_tail_ptr1;
reg [FIFO_PTR_SIZE-1: 0] ds_tail_ptr2;
always @(posedge clk) begin
  if ( rst ) begin
    ds_tail_ptr0 <= #`dh 0;
    ds_tail_ptr1 <= #`dh 0;
    ds_tail_ptr2 <= #`dh 0;
  end
  else begin
    if ( ds_credit0_valid ) ds_tail_ptr0 <= #`dh i_ds_credit[FIFO_PTR_SIZE-1:0];
    if ( ds_credit1_valid ) ds_tail_ptr1 <= #`dh i_ds_credit[FIFO_PTR_SIZE-1:0];
    if ( ds_credit2_valid ) ds_tail_ptr2 <= #`dh i_ds_credit[FIFO_PTR_SIZE-1:0];
  end
end

// local head pointer
reg [FIFO_PTR_SIZE-1: 0] ds_head_ptr0;
reg [FIFO_PTR_SIZE-1: 0] ds_head_ptr1;
reg [FIFO_PTR_SIZE-1: 0] ds_head_ptr2;
always @(posedge clk) begin
  if ( rst ) begin
    ds_head_ptr0 <= #`dh 0;
    ds_head_ptr1 <= #`dh 0;
    ds_head_ptr2 <= #`dh 0;
  end
  else begin
    if ( i_enq[0] ) ds_head_ptr0 <= #`dh (ds_head_ptr0 == FIFO_SIZE - 1'b1) ? 0 : ds_head_ptr0 + 1'b1;
    if ( i_enq[1] ) ds_head_ptr1 <= #`dh (ds_head_ptr1 == FIFO_SIZE - 1'b1) ? 0 : ds_head_ptr1 + 1'b1;
    if ( i_enq[2] ) ds_head_ptr2 <= #`dh (ds_head_ptr2 == FIFO_SIZE - 1'b1) ? 0 : ds_head_ptr2 + 1'b1;
  end
end

// remote queue occupancy calculation
// occupancy = (N + hd -tl) % N
reg [FIFO_PTR_SIZE:0] ds_fifo_occupancy0;
reg [FIFO_PTR_SIZE:0] ds_fifo_occupancy1;
reg [FIFO_PTR_SIZE:0] ds_fifo_occupancy2;
always @(posedge clk) begin
  if ( rst ) begin
    ds_fifo_occupancy0 <= #`dh 0;
    ds_fifo_occupancy1 <= #`dh 0;
    ds_fifo_occupancy2 <= #`dh 0;
  end
  else begin
    if (ds_head_ptr0 < ds_tail_ptr0) 
      ds_fifo_occupancy0 <= #`dh (FIFO_SIZE + ds_head_ptr0 - ds_tail_ptr0);
    else
      ds_fifo_occupancy0 <= #`dh (ds_head_ptr0 - ds_tail_ptr0);

    if (ds_head_ptr1 < ds_tail_ptr1)
      ds_fifo_occupancy1 <= #`dh (FIFO_SIZE + ds_head_ptr1 - ds_tail_ptr1);
    else
      ds_fifo_occupancy1 <= #`dh (ds_head_ptr1 - ds_tail_ptr1);
    
    if (ds_head_ptr2 < ds_tail_ptr2)
      ds_fifo_occupancy2 <= #`dh (FIFO_SIZE + ds_head_ptr2 - ds_tail_ptr2);
    else
      ds_fifo_occupancy2 <= #`dh (ds_head_ptr2 - ds_tail_ptr2);
  end
end

// output xoff 
reg [2:0] o_local_xoff;
always @(posedge clk) begin
  if ( rst ) begin
    o_local_xoff <= #`dh 3'b111;
  end
  else begin
    o_local_xoff[0] <= #`dh ( ds_fifo_occupancy0 > FIFO_FULL_THRESHOLD );
    o_local_xoff[1] <= #`dh ( ds_fifo_occupancy1 > FIFO_FULL_THRESHOLD );
    o_local_xoff[2] <= #`dh ( ds_fifo_occupancy2 > FIFO_FULL_THRESHOLD );

  end
end


//////////////////////////////////////////////////////////////////////////////
// OUTGOING CREDITS from upstream (us)
//
// local tail pointer
reg [FIFO_PTR_SIZE-1: 0] us_tail_ptr0;
reg [FIFO_PTR_SIZE-1: 0] us_tail_ptr1;
reg [FIFO_PTR_SIZE-1: 0] us_tail_ptr2;
always @(posedge clk) begin
  if ( rst ) begin
    us_tail_ptr0 <= #`dh 0;
    us_tail_ptr1 <= #`dh 0;
    us_tail_ptr2 <= #`dh 0;
  end
  else begin
    if ( i_deq[0] ) us_tail_ptr0 <= #`dh (us_tail_ptr0 == FIFO_SIZE - 1'b1) ? 0 : us_tail_ptr0 + 1'b1;
    if ( i_deq[1] ) us_tail_ptr1 <= #`dh (us_tail_ptr1 == FIFO_SIZE - 1'b1) ? 0 : us_tail_ptr1 + 1'b1;
    if ( i_deq[2] ) us_tail_ptr2 <= #`dh (us_tail_ptr2 == FIFO_SIZE - 1'b1) ? 0 : us_tail_ptr2 + 1'b1;
  end
end

// calculate outgoing credits              VC      CREDIT
wire [CREDIT_WIDTH-2:0] us_credit0_val = {3'b001, 9'b0, us_tail_ptr0};
wire [CREDIT_WIDTH-2:0] us_credit1_val = {3'b010, 9'b0, us_tail_ptr1};
wire [CREDIT_WIDTH-2:0] us_credit2_val = {3'b100, 9'b0, us_tail_ptr2};
// calculate parity
wire us_credit0_parity = ^us_credit0_val;
wire us_credit1_parity = ^us_credit1_val;
wire us_credit2_parity = ^us_credit2_val;

reg [CREDIT_WIDTH-1:0] us_credit0;
reg [CREDIT_WIDTH-1:0] us_credit1;
reg [CREDIT_WIDTH-1:0] us_credit2;
always @(posedge clk) begin
  if ( rst ) begin
    us_credit0 <= #`dh 0;
    us_credit1 <= #`dh 0;
    us_credit2 <= #`dh 0;
  end
  else begin 
    us_credit0 <= #`dh {us_credit0_parity, us_credit0_val};
    us_credit1 <= #`dh {us_credit1_parity, us_credit1_val};
    us_credit2 <= #`dh {us_credit2_parity, us_credit2_val};
  end
end

// retransmit credits roughly every 64K cycles
reg [16:0] retransmission_counter;
wire retransmit_credits = retransmission_counter[16];
always @(posedge clk) begin
  if ( rst ) begin
    retransmission_counter <= #`dh 0;
  end
  else if ( retransmit_credits ) begin
    retransmission_counter <= #`dh 0;
  end
  else begin
    retransmission_counter <= #`dh retransmission_counter + 1'b1;
  end
end

// set when credits should be transmitted
reg [2:0] transmit_credits;
wire transmit_credits_done;
always @(posedge clk) begin
  if ( rst ) begin
    transmit_credits <= #`dh 0;
  end
  else begin
    if ( i_deq[0] | retransmit_credits ) transmit_credits[0] <= #`dh 1;
    else if ( transmit_credits_done )    transmit_credits[0] <= #`dh 0;

    if ( i_deq[1] | retransmit_credits ) transmit_credits[1] <= #`dh 1;
    else if ( transmit_credits_done )    transmit_credits[1] <= #`dh 0;

    if ( i_deq[2] | retransmit_credits ) transmit_credits[2] <= #`dh 1;
    else if ( transmit_credits_done )    transmit_credits[2] <= #`dh 0;
  end
end


///////////////////////////////////////////////////////////////////////////////
// CREDIT TRANSMISSION FSM
parameter CT_IDLE  = 5'b00001;
parameter CT_VC0   = 5'b00010;
parameter CT_VC1   = 5'b00100;
parameter CT_VC2   = 5'b01000;
parameter CT_DONE  = 5'b10000;
parameter CT_DONE1 = 5'b10001;
parameter CT_DONE2 = 5'b10010;
reg [4:0] ct_state;
reg [4:0] ct_nextstate;
always @(posedge clk) begin
  if ( rst ) begin
    ct_state <= #`dh CT_IDLE;
  end
  else begin
    ct_state <= #`dh ct_nextstate;
  end
end

always @(ct_state, transmit_credits, retransmit_credits, i_us_credit_accept) begin
  ct_nextstate <= ct_state;

  case (ct_state)
    CT_IDLE:
    begin
      if ( transmit_credits[0]  ) begin
        ct_nextstate <= CT_VC0;
      end
      else if ( transmit_credits[1]  ) begin
        ct_nextstate <= CT_VC1;
      end
      else if ( transmit_credits[2]  ) begin
        ct_nextstate <= CT_VC2;
      end
    end

    CT_VC0:
    begin
      if ( i_us_credit_accept ) begin
        if ( transmit_credits[1] ) begin
          ct_nextstate <= CT_VC1;
        end
        else if ( transmit_credits[2] ) begin
          ct_nextstate <= CT_VC2;
        end
        else begin
          ct_nextstate <= CT_DONE;
        end
      end
    end

    CT_VC1:
    begin
      if ( i_us_credit_accept ) begin
        if ( transmit_credits[2] ) begin
          ct_nextstate <= CT_VC2;
        end
        else begin
          ct_nextstate <= CT_DONE;
        end
      end
    end

    CT_VC2:
    begin
      if ( i_us_credit_accept ) begin
        ct_nextstate <= CT_DONE;
      end
    end

    CT_DONE:
    begin
      ct_nextstate <= CT_DONE1;
    end
    CT_DONE1:
    begin
      ct_nextstate <= CT_DONE2;
    end
    CT_DONE2:
    begin
      ct_nextstate <= CT_IDLE;
    end

  endcase
end

assign transmit_credits_done = ( ct_state == CT_DONE );

// credit transmit outputs
wire [CREDIT_WIDTH-1:0] o_us_credit = ( ct_state == CT_VC0 ) ? us_credit0 :
                                      ( ct_state == CT_VC1 ) ? us_credit1 :
                                      ( ct_state == CT_VC2 ) ? us_credit2 : 0;
wire o_us_credit_valid = ( ct_state == CT_VC0 ) | ( ct_state == CT_VC1 ) | ( ct_state == CT_VC2 );

endmodule
