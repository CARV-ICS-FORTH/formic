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
// Abstract      : GTP transmit controller
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rio_link_tx_ctrl.v,v $
// CVS revision  : $Revision: 1.4 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rio_link_tx_ctrl(
  // CLK, RST
  clk,
  rst,

  // LINK
  i_link_up,
  i_link_sync,

  // CREDITS
  i_us_credit,
  i_us_credit_valid,
  o_us_credit_accept,

  // USER TX IF
  i_tx_valid,
  i_tx_sop,
  i_tx_eop,
  i_tx_data,
  o_tx_rdy,

  // RIO TX IF
  o_rio_tx_data,
  o_rio_tx_isk
);


parameter DATA_WIDTH = 16;
parameter CREDIT_WIDTH = 16;
parameter RIO_COMMA_CHAR = 8'hbc;        // COMMA = K28.5
parameter RIO_SYN_CHAR   = 8'hf7;        // SYNC  = K23.7
parameter RIO_SKP_CHAR   = 8'hfb;        // SKIP  = K27.7
parameter RIO_SOP_CHAR   = 8'hfd;        // SOP   = K29.7
parameter RIO_EOP_CHAR   = 8'hfe;        // EOP   = K30.7

///////////////////////////////////////////////////////////////////////////////

input clk;
input rst;

// LINK
input i_link_up;
input i_link_sync;

// CREDITS
input [CREDIT_WIDTH-1:0] i_us_credit;
input i_us_credit_valid;
output o_us_credit_accept;

// USER TX IF
input i_tx_valid;
input i_tx_sop;
input i_tx_eop;
input [DATA_WIDTH-1 : 0] i_tx_data;
output o_tx_rdy;

// RIO TX IF
output [DATA_WIDTH-1 : 0] o_rio_tx_data;
output [(DATA_WIDTH/8)-1 : 0] o_rio_tx_isk;

///////////////////////////////////////////////////////////////////////////////
// USER TX IF IMPLEMENTATION
reg [7:0] tx_state;
reg [7:0] tx_nextstate;
parameter TX_IDLE = 8'b00000001;
parameter TX_DATA = 8'b00000010;
parameter TX_EOP  = 8'b00000100;
parameter TX_END  = 8'b00001000;
parameter TX_CRD  = 8'b00010000;

always @(posedge clk) begin
  if ( rst ) begin
    tx_state <= #`dh TX_IDLE;
  end
  else begin
    tx_state <= #`dh tx_nextstate;
  end
end


always @( tx_state , i_tx_valid , i_tx_sop , i_tx_eop , i_us_credit_valid ) begin
  tx_nextstate <= tx_state;

  case(tx_state)

    TX_IDLE: 
    begin
      if ( i_tx_sop & i_tx_valid ) begin
        if ( i_tx_eop ) begin
          tx_nextstate <= TX_EOP;
        end
        else begin
          tx_nextstate <= TX_DATA;
        end
      end
    end

    TX_DATA: 
    begin
      if ( i_tx_eop & i_tx_valid ) begin
        tx_nextstate <= TX_EOP;
      end
    end

    TX_EOP:
    begin
      tx_nextstate <= TX_END;
    end

    TX_END:
    begin
      if ( i_us_credit_valid ) begin
        tx_nextstate <= TX_CRD;
      end
      else begin
        tx_nextstate <= TX_IDLE;
      end
    end

    TX_CRD:
    begin
      if ( ~i_us_credit_valid ) begin
        tx_nextstate <= TX_IDLE;
      end
    end

  endcase
end

wire o_tx_rdy = (tx_state == TX_IDLE) & i_link_up;

// HERE
wire o_us_credit_accept = i_us_credit_valid &  
                          ( (tx_state == TX_CRD) | 
                            ((tx_state == TX_IDLE) & ~i_tx_valid)
                          );

///////////////////////////////////////////////////////////////////////////////
// RIO TX IF IMPLEMENTATION
// INTERNAL 

// keep the data for 1 cycle to inject SOP control in link
reg [DATA_WIDTH-1 : 0] tx_data_q;
always @(posedge clk) begin
  if ( rst ) begin
    tx_data_q <= #`dh 0;
  end
  else begin
    tx_data_q <= #`dh i_tx_data;
  end
end

reg [DATA_WIDTH-1 : 0] rio_tx_data_int;
reg [(DATA_WIDTH/8)-1 : 0] rio_tx_isk_int;

// inject commas only in even positions since we use even comma alignment in rocketio
always @(tx_state , i_tx_valid , i_tx_sop , tx_data_q , i_link_sync, i_us_credit_valid, i_us_credit) begin
  rio_tx_data_int <= {RIO_SKP_CHAR,RIO_COMMA_CHAR};
  rio_tx_isk_int <= 2'b11;

  case(tx_state)

    TX_IDLE: 
    begin
      if ( i_tx_sop & i_tx_valid ) begin
        rio_tx_data_int <= {RIO_SOP_CHAR,RIO_COMMA_CHAR};
        rio_tx_isk_int <= 2'b11;
      end
      else if ( i_link_sync ) begin
        rio_tx_data_int <= {RIO_SYN_CHAR,RIO_COMMA_CHAR};
        rio_tx_isk_int <= 2'b11;
      end
      else if ( i_us_credit_valid ) begin
        rio_tx_data_int <= i_us_credit;
        rio_tx_isk_int <= 2'b0;
      end
    end

    TX_DATA:
    begin
      rio_tx_data_int <= tx_data_q;
      rio_tx_isk_int <= 2'b0;
    end

    TX_EOP:
    begin
      rio_tx_data_int <= tx_data_q;
      rio_tx_isk_int <= 2'b0;
    end

    TX_END:
    begin
      rio_tx_data_int <= {RIO_EOP_CHAR,RIO_COMMA_CHAR};
      rio_tx_isk_int <= 2'b11;
    end

    TX_CRD:
    begin
      if ( i_us_credit_valid ) begin
        rio_tx_data_int <= i_us_credit;
        rio_tx_isk_int <= 2'b0;
      end
    end

  endcase
end

///////////////////////////////////////////////////////////////////////////////
// registered outputs to rocketio
reg [DATA_WIDTH-1 : 0] o_rio_tx_data;
reg [(DATA_WIDTH/8)-1 : 0] o_rio_tx_isk;

always @(posedge clk or posedge rst) begin
  if ( rst ) begin
    o_rio_tx_data <= #`dh {RIO_SKP_CHAR,RIO_COMMA_CHAR};
    o_rio_tx_isk <= #`dh 2'b11;
  end
  else begin
    o_rio_tx_data <= #`dh rio_tx_data_int;
    o_rio_tx_isk <= #`dh rio_tx_isk_int;
  end
end

endmodule
