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
// Abstract      : GTP link layer top-level
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rio_link.v,v $
// CVS revision  : $Revision: 1.5 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rio_link(
  // CLK, RST
  clk,
  rst,

  // USER TX IF
  i_tx_valid,
  i_tx_sop,
  i_tx_eop,
  i_tx_data,
  o_tx_rdy,

  // USER RX IF
  o_rx_valid,
  o_rx_sop,
  o_rx_eop,
  o_rx_data,

  // RIO TX IF
  o_rio_tx_data,
  o_rio_tx_isk,

  // RIO RX IF
  i_rio_rx_data,
  i_rio_rx_isk,


  // USER LINK IF
  o_link_up,
  o_link_error,

  // FLOW CONTROL IF 
  i_link_enq,
  i_link_deq,
  o_link_xoff,

  // RIO ERROR AND STATE
  i_rio_loss_of_sync,
  i_rio_rx_disp_err,
  i_rio_rx_not_in_table,
  i_rio_rx_buf_status
);

parameter DATA_WIDTH = 16;
parameter CREDIT_WIDTH = 16;

input clk;
input rst;

// USER TX IF
input i_tx_valid;
input i_tx_sop;
input i_tx_eop;
input [DATA_WIDTH-1 : 0] i_tx_data;
output o_tx_rdy;

// USER RX IF
output o_rx_valid;
output o_rx_sop;
output o_rx_eop;
output [DATA_WIDTH-1 : 0] o_rx_data;

// RIO TX IF
output [DATA_WIDTH-1 : 0] o_rio_tx_data;
output [(DATA_WIDTH/8)-1 : 0] o_rio_tx_isk;

// RIO RX IF
input [DATA_WIDTH-1 : 0] i_rio_rx_data;
input [(DATA_WIDTH/8)-1 : 0] i_rio_rx_isk;

// USER LINK IF
output o_link_up;
output o_link_error;

// FLOW CONTROL
input [2:0] i_link_enq;
input [2:0] i_link_deq;
output [2:0] o_link_xoff;

// RIO ERROR AND STATE
input [1:0] i_rio_loss_of_sync;
input [1:0] i_rio_rx_disp_err;
input [1:0] i_rio_rx_not_in_table;
input [2:0] i_rio_rx_buf_status;


///////////////////////////////////////////////////////////////////////////////
wire [DATA_WIDTH-1 : 0] rio_rx_data_aligned;
wire [(DATA_WIDTH/8)-1 : 0] rio_rx_isk_aligned;

///////////////////////////////////////////////////////////////////////////////

wire rx_up;
wire rx_sync;

reg rx_error;
reg [1:0] rio_rx_disp_err;
reg [1:0] rio_rx_not_in_table;
reg [1:0] rio_loss_of_sync;
reg [2:0] rio_rx_buf_status;

always @(posedge clk) begin
 rio_rx_disp_err <= i_rio_rx_disp_err;
 rio_rx_not_in_table <= i_rio_rx_not_in_table;
 rio_loss_of_sync <= i_rio_loss_of_sync;
 rio_rx_buf_status <= i_rio_rx_buf_status;

 rx_error <= ( rio_rx_disp_err[0] | rio_rx_disp_err[1] | 
               rio_rx_not_in_table[0] | rio_rx_not_in_table[1] |
               rio_loss_of_sync[1] |
               rio_rx_buf_status[2] );
end

///////////////////////////////////////////////////////////////////////////////
wire [CREDIT_WIDTH-1:0] ds_credit;
wire ds_credit_valid;

wire [CREDIT_WIDTH-1:0] us_credit;
wire us_credit_valid;
wire us_credit_accept;

wire [2:0] link_xoff;
///////////////////////////////////////////////////////////////////////////////
// TX control
rio_link_tx_ctrl rio_tx(
  .clk(clk),
  .rst(rst),

  .i_link_up(o_link_up),
  .i_link_sync(rx_sync),

  .i_us_credit(us_credit),
  .i_us_credit_valid(us_credit_valid),
  .o_us_credit_accept(us_credit_accept),

  .i_tx_valid(i_tx_valid),
  .i_tx_sop(i_tx_sop),
  .i_tx_eop(i_tx_eop),
  .i_tx_data(i_tx_data),
  .o_tx_rdy(o_tx_rdy),

  .o_rio_tx_data(o_rio_tx_data),
  .o_rio_tx_isk(o_rio_tx_isk)
);

// RX control
rio_link_rx_align rio_rx_align (
  .clk(clk), 
  .rst(rst), 
  .i_rio_rx_data(i_rio_rx_data), 
  .i_rio_rx_isk(i_rio_rx_isk), 
  .o_rio_rx_data(rio_rx_data_aligned), 
  .o_rio_rx_isk(rio_rx_isk_aligned)
);

rio_link_rx_ctrl rio_rx(
  .clk(clk),
  .rst(rst),

  .i_link_error(rx_error),
  .o_link_up(rx_up),
  .o_link_sync(rx_sync),

  .o_ds_credit(ds_credit),
  .o_ds_credit_valid(ds_credit_valid),

  .o_rx_valid(o_rx_valid),
  .o_rx_sop(o_rx_sop),
  .o_rx_eop(o_rx_eop),
  .o_rx_data(o_rx_data),

  .i_rio_rx_data(rio_rx_data_aligned),
  .i_rio_rx_isk(rio_rx_isk_aligned)
);

// CREDITS
rio_link_credits rio_credits(
  .clk(clk),
  .rst(rst),
 
  .i_enq(i_link_enq),
  .i_ds_credit(ds_credit),
  .i_ds_credit_valid(ds_credit_valid),

  .i_deq(i_link_deq),
  .o_us_credit(us_credit),
  .o_us_credit_valid(us_credit_valid),
  .i_us_credit_accept(us_credit_accept),

  .o_local_xoff(link_xoff)
);

rio_link_errors rio_errors(
  .clk(clk),
  .rst(rst),
  .i_rx_up(rx_up),
  .i_rx_error(rx_error),
  .o_link_up(o_link_up),
  .o_link_error(o_link_error)
);

// TX backpressure
wire [2:0] o_link_xoff = link_xoff | {3{~o_tx_rdy}};
//wire [2:0] o_link_xoff = link_xoff;

endmodule
