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
// Abstract      : GTP receive controller
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rio_link_rx_ctrl.v,v $
// CVS revision  : $Revision: 1.6 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rio_link_rx_ctrl(
  // CLK, RST
  clk,
  rst,

  // LINK
  i_link_error,
  o_link_up,
  o_link_sync,

  // CREDITSpap
  o_ds_credit,
  o_ds_credit_valid,

  // USER RX IF
  o_rx_valid,
  o_rx_sop,
  o_rx_eop,
  o_rx_data,

  // RIO RX IF
  i_rio_rx_data,
  i_rio_rx_isk
);


parameter DATA_WIDTH = 16;
parameter CREDIT_WIDTH = 16;

parameter RIO_COMMA_CHAR = 8'hbc;       // COMMA = K28.5
parameter RIO_SYN_CHAR   = 8'hf7;       // SYNC  = K23.7
parameter RIO_SKP_CHAR   = 8'hfb;       // SKIP  = K27.7
parameter RIO_SOP_CHAR   = 8'hfd;       // SOP   = K29.7
parameter RIO_EOP_CHAR   = 8'hfe;       // EOP   = K30.7

parameter RIO_CRD_MSB = 15;
parameter RIO_CRD_LSB = 8;

parameter RIO_SKP_MSB = 15;
parameter RIO_SKP_LSB = 8;

parameter RIO_SOP_MSB = 15;
parameter RIO_SOP_LSB = 8;

parameter RIO_EOP_MSB = 15;
parameter RIO_EOP_LSB = 8;

///////////////////////////////////////////////////////////////////////////////

input clk;
input rst;

// LINK
input i_link_error;
output o_link_up;
output o_link_sync;

// CREDITS
output [CREDIT_WIDTH-1:0] o_ds_credit;
output o_ds_credit_valid;

// USER RX IF
output o_rx_valid;
output o_rx_sop;
output o_rx_eop;
output [DATA_WIDTH-1 : 0] o_rx_data;

// RIO RX IF
input [DATA_WIDTH-1 : 0] i_rio_rx_data;
input [(DATA_WIDTH/8)-1 : 0] i_rio_rx_isk;

///////////////////////////////////////////////////////////////////////////////
// RIO RX IF IMPLEMENTATION
// INTERNAL 

wire rx_syn = i_rio_rx_isk[1] & (i_rio_rx_data[RIO_SKP_MSB : RIO_SKP_LSB] == RIO_SYN_CHAR);
wire rx_sop = i_rio_rx_isk[1] & (i_rio_rx_data[RIO_SOP_MSB : RIO_SOP_LSB] == RIO_SOP_CHAR);
wire rx_eop = i_rio_rx_isk[1] & (i_rio_rx_data[RIO_EOP_MSB : RIO_EOP_LSB] == RIO_EOP_CHAR);

reg [6:0] rx_state;
reg [6:0] rx_nextstate;
parameter RX_INIT  = 7'b0000001;
parameter RX_SYNC  = 7'b0000010;
parameter RX_IDLE  = 7'b0000100;
parameter RX_START = 7'b0001000;
parameter RX_SOP   = 7'b0010000;
parameter RX_DATA  = 7'b0100000;
parameter RX_ERROR = 7'b1000000;

always @(posedge clk) begin
  if ( rst ) begin
    rx_state <= #`dh RX_INIT;
  end
  else begin
    rx_state <= #`dh rx_nextstate;
  end
end

// RX stability initialization phase
reg [16:0] rx_init_counter;
wire rx_init_inc = (rx_state == RX_INIT);
wire rx_init_done = rx_init_counter[12];
wire rx_init_rst = ((rx_state == RX_INIT) | (rx_state == RX_SYNC)) & i_link_error;
always @(posedge clk) begin
  if ( rst ) begin
    rx_init_counter <= #`dh 0;
  end
  else if ( rx_init_rst ) begin
    rx_init_counter <= #`dh 0;
  end
  else if ( rx_init_inc ) begin
    rx_init_counter <= #`dh rx_init_counter + 1'b1;
  end
end

// LINK UP
reg o_link_up;
always @(posedge clk) begin
  if ( rst ) begin
    o_link_up <= #`dh 0;
  end
  else begin
    o_link_up <= #`dh (rx_state != RX_INIT) &&
                      (rx_state != RX_SYNC) &&
                      (rx_state != RX_ERROR);
  end
end
// LINK SYNC
wire o_link_sync = (rx_state == RX_SYNC);

always @(rx_state , rx_sop , rx_eop , rx_syn, rx_init_done, i_link_error, o_link_up) begin
  if ( i_link_error && o_link_up ) begin
    rx_nextstate <= RX_ERROR;
  end
  else begin
    rx_nextstate <= rx_state;

    case(rx_state)

      RX_INIT: 
      begin
        if ( rx_init_done ) begin
          rx_nextstate <= RX_SYNC;
        end
      end

      RX_SYNC: 
      begin
        if ( i_link_error ) begin
          rx_nextstate <= RX_INIT;
        end
        else if ( rx_syn ) begin
          rx_nextstate <= RX_IDLE;
        end
      end

      RX_IDLE: 
      begin
        if ( rx_sop ) begin
          rx_nextstate <= RX_START;
        end
      end

      RX_START: 
      begin
        rx_nextstate <= RX_SOP;
      end

      RX_SOP: 
      begin
        if ( rx_eop ) begin
          rx_nextstate <= RX_IDLE;
        end
        else begin
          rx_nextstate <= RX_DATA;
        end
      end

      RX_DATA:
      begin
        if ( rx_eop ) begin
          rx_nextstate <= RX_IDLE;
        end
      end

      RX_ERROR:
      begin
        rx_nextstate <= RX_ERROR;
      end

    endcase
  end
end

// registered rocketio input
reg [DATA_WIDTH-1 : 0] rx_data_q;
always @(posedge clk) begin
  if ( rst ) begin
    rx_data_q <= #`dh 0;
  end
  else begin
    rx_data_q <= #`dh i_rio_rx_data;
  end
end

///////////////////////////////////////////////////////////////////////////////
// USER RX IF IMPLEMENTATION
// registered user outputs
reg o_rx_valid;
reg o_rx_sop;
reg o_rx_eop;
reg [DATA_WIDTH-1 : 0] o_rx_data;

always @(posedge clk) begin
  if ( rst ) begin
    o_rx_valid <= #`dh 0;
    o_rx_sop <= #`dh 0;
    o_rx_eop <= #`dh 0;        
    o_rx_data <= #`dh 0;
  end
  else begin
    o_rx_valid <= #`dh ((rx_state == RX_SOP) | (rx_state == RX_DATA));
    o_rx_sop <= #`dh (rx_state == RX_SOP);
    o_rx_eop <= #`dh rx_eop;
    o_rx_data <= #`dh rx_data_q;
  end
end

///////////////////////////////////////////////////////////////////////////////
// CREDITS
// when out of packet bounds and not control characters
wire rx_crd = (i_rio_rx_isk == 2'b00) & (rx_state == RX_IDLE);

reg o_ds_credit_valid;
reg [CREDIT_WIDTH-1 : 0] o_ds_credit;
always @(posedge clk) begin
  if ( rst ) begin
    o_ds_credit_valid <= #`dh 0;
    o_ds_credit <= #`dh 0;
  end
  else begin
    o_ds_credit_valid <= #`dh rx_crd;
    o_ds_credit <= #`dh i_rio_rx_data;
  end
end


endmodule
