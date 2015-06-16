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
// Abstract      : GTP auto-tester generator
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: rio_packet_generator.v,v $
// CVS revision  : $Revision: 1.4 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps

module rio_packet_generator(
  clk,
  rst,

  i_enable,
  o_tx_valid,
  o_tx_sop,
  o_tx_eop,
  o_tx_data,
  i_tx_rdy
);
    

parameter DATA_WIDTH = 16;

parameter GEN_IDLE = 4'b0001;
parameter GEN_SOP  = 4'b0010;
parameter GEN_DATA = 4'b0100;
parameter GEN_EOP  = 4'b1000;

input clk;
input rst;
input i_enable;
output o_tx_valid;
output o_tx_sop;
output o_tx_eop;
output [DATA_WIDTH-1 : 0] o_tx_data;
input i_tx_rdy;

reg [3:0] gen_state;
reg [3:0] gen_nextstate;

always @(posedge clk) begin
  if ( rst ) begin
    gen_state <= #`dh GEN_IDLE;
  end
  else begin    
    gen_state <= #`dh gen_nextstate;
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
    //$display("LFSR %d",lfsr);
  end
end

reg [7:0] wcounter;
wire wcounter_rst;
wire wcounter_en;

always @(posedge clk) begin
  if (rst | wcounter_rst) begin
    wcounter <= #`dh 1;
  end
  else if (wcounter_en) begin
    wcounter <= #`dh wcounter + 1;
  end
end

wire pck_end = ( wcounter == lfsr );

always @(gen_state, i_tx_rdy, pck_end, i_enable) begin
  gen_nextstate <= gen_state;

  case(gen_state)
    GEN_IDLE:
    begin
      if ( i_tx_rdy & i_enable )
		gen_nextstate <= GEN_SOP;
    end

    GEN_SOP:
    begin
      gen_nextstate <= GEN_DATA;
    end

    GEN_DATA:
    begin
      if ( pck_end )
		gen_nextstate <= GEN_EOP;
    end

    GEN_EOP:
    begin
      gen_nextstate <= GEN_IDLE;
    end
  endcase
end


assign dcounter_en = (gen_state != GEN_IDLE);
assign wcounter_en = (gen_state != GEN_IDLE);
assign wcounter_rst = (gen_state == GEN_IDLE);
assign lfsr_en = (gen_state == GEN_EOP);

wire [DATA_WIDTH-1 : 0] o_tx_data = dcounter;
wire o_tx_sop = (gen_state == GEN_SOP);
wire o_tx_eop = (gen_state == GEN_EOP);
wire o_tx_valid = (gen_state != GEN_IDLE);

endmodule
