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
// Abstract      : GTP auto-tester
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rio_packet_validator.v,v $
// CVS revision  : $Revision: 1.3 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rio_packet_validator(
    clk,
    rst,

    i_rx_valid,
    i_rx_sop,
    i_rx_eop,
    i_rx_data,

    o_rx_data_error,
    o_rx_size_error
);


parameter DATA_WIDTH = 16;
parameter VLD_IDLE = 3'b001;
parameter VLD_DATA = 3'b010;

input clk;
input rst;
input i_rx_valid;
input i_rx_sop;
input i_rx_eop;
input [DATA_WIDTH-1 : 0] i_rx_data;
output o_rx_data_error;
output o_rx_size_error;

reg [2:0] vld_state;
reg [2:0] vld_nextstate;

always @(posedge clk) begin
  if ( rst ) begin
    vld_state <= #`dh VLD_IDLE;
  end
  else begin    
    vld_state <= #`dh vld_nextstate;
  end
end


reg [DATA_WIDTH-1 : 0] dcounter;
wire dcounter_en;
always @(posedge clk) begin
  if ( rst ) begin
    dcounter <= #`dh 0;
  end
  else if ( dcounter_en ) begin
    dcounter <= #`dh dcounter + 1;
  end
end

reg [7:0] lfsr;
wire lfsr_en;
always @(posedge clk) begin
  if ( rst ) begin
    lfsr <= #`dh 8'h5;
  end
  else if ( lfsr_en ) begin
    lfsr <= #`dh {lfsr[6:0], lfsr[7]^lfsr[5]^lfsr[4]^lfsr[3]};
    //maximal lfsr
    //poly: x8 + x6 + x5 + x4 + 1;
  end
end

reg [7:0] wcounter;
wire wcounter_rst;
wire wcounter_en;

always @(posedge clk) begin
  if (rst | wcounter_rst) begin
    wcounter <= #`dh 0;
  end
  else if (wcounter_en) begin
    wcounter <= #`dh wcounter + 1;
  end
end

always @(vld_state, i_rx_valid, i_rx_sop, i_rx_eop ) begin
  vld_nextstate <= vld_state;

  case(vld_state)
    VLD_IDLE:
    begin
      if ( i_rx_sop & i_rx_valid )
        vld_nextstate <= VLD_DATA;
    end

    VLD_DATA:
    begin
      if ( i_rx_eop & i_rx_valid )
        vld_nextstate <= VLD_IDLE;
    end
  endcase
end


assign dcounter_en = i_rx_valid;
assign wcounter_en = i_rx_valid;
assign wcounter_rst = i_rx_valid & i_rx_eop;
assign lfsr_en = i_rx_valid & i_rx_eop;

wire data_error = i_rx_valid & ( i_rx_data != dcounter );
wire size_error = i_rx_valid & i_rx_eop & ( wcounter != lfsr );

//
reg [19:0] data_error_cnt;
reg [19:0] size_error_cnt;
reg o_rx_data_error;
reg o_rx_size_error;
always @(posedge clk) begin
  if ( rst ) begin
	data_error_cnt <= #`dh 0;
	size_error_cnt <= #`dh 0;
	o_rx_data_error <= #`dh 0;
	o_rx_size_error <= #`dh 0;
  end
  else begin
	if ( data_error ) begin
	  $display("RX DATA ERROR!");
	  data_error_cnt <= #`dh data_error_cnt + 1;
	end
	if ( size_error ) begin
	  $display("RX SIZE ERROR!");
	  size_error_cnt <= #`dh size_error_cnt + 1;
	end

	o_rx_data_error <= #`dh (data_error_cnt != 0);
	o_rx_size_error <= #`dh (size_error_cnt != 0);
  end
end

endmodule
