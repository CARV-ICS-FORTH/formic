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
// Author        : George Kalokerinos
// Abstract      : Misc priority enforcers, encoders, decoders, etc.
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: RR_prior_enf.v,v $
// CVS revision  : $Revision: 1.7 $
// Last modified : $Date: 2012/07/03 16:28:58 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// Rnd_RR_prior_enf
//
module Rnd_RR_prior_enf(
//
   input  [7:0] i_mask,
   input  [7:0] i_In,
   output [7:0] o_Out);
//
wire [7:0] OutAll, OutPar;
//
PriorEnf PEnfAll(i_In, OutAll, , );
defparam PEnfAll.N_log = 3;
  
PriorEnf PEnfPar((~i_mask & i_In), OutPar, , OneDetectedPar);
defparam PEnfPar.N_log = 3;
//
assign o_Out = OneDetectedPar ? OutPar : OutAll;
//
endmodule
//
// RR_prior_enf
//
module RR_prior_enf(In, Out, ld_en, Clk, Reset_);
//
parameter N_log = 3;
//
input                   Clk;
input                   Reset_;
input                   ld_en;
input  [(1<<N_log)-1:0] In;
output [(1<<N_log)-1:0] Out;
//
reg  [(1<<N_log)-1:0] Mask;
wire [(1<<N_log)-1:0] OutAll, OutPar, MaskAll, MaskPar;
wire [(1<<N_log)-1:0] InPar = ~Mask & In &~Out;
//
PriorEnf PEnfAll(In, OutAll, MaskAll, );
defparam PEnfAll.N_log = N_log;

PriorEnf PEnfPar(InPar, OutPar, MaskPar, OneDetectedPar);
defparam PEnfPar.N_log = N_log;

// Out Mux         // MODIFY TO REG
//
reg [(1<<N_log)-1:0] Out;
always @(posedge Clk) begin
   if(~Reset_)     Out <= #`dh 0;
   else if (ld_en) Out <= #`dh OneDetectedPar ? OutPar : OutAll;
end
// Mask Register
always @(posedge Clk) begin
   if(~Reset_)     Mask <= #`dh 0;
   else if (ld_en) Mask <= #`dh OneDetectedPar ? MaskPar : MaskAll;
end
//
endmodule
//
//
// RR_prior_enf_combout
//
module RR_prior_enf_combout(In, Out, ld_en, Clk, Rst);
//
parameter N_log = 3;
//
input                   Clk;
input                   Rst;
input                   ld_en;
input  [(1<<N_log)-1:0] In;
output [(1<<N_log)-1:0] Out;
//
reg  [(1<<N_log)-1:0] Mask;
wire [(1<<N_log)-1:0] OutAll, OutPar, MaskAll, MaskPar;
wire [(1<<N_log)-1:0] InPar = ~Mask & In;
//
PriorEnf PEnfAll(In, OutAll, MaskAll, );
defparam PEnfAll.N_log = N_log;

PriorEnf PEnfPar(InPar, OutPar, MaskPar, OneDetectedPar);
defparam PEnfPar.N_log = N_log;

// Out Mux
//
assign Out = (OneDetectedPar) ? OutPar : OutAll;
// Mask Register
always @(posedge Clk) begin
   if (Rst) Mask <= #`dh 0;
   else if (ld_en) Mask <= #`dh OneDetectedPar ? MaskPar : MaskAll;
end
//
endmodule
//
// Priority Enforcer and Encoder Module
// Priority is right <- left (MS)
//
module PriorEnf(In, Out, Mask, OneDetected);
//
parameter N_log = 3 ;
//
input  [(1<<N_log)-1:0] In;
output [(1<<N_log)-1:0] Out;
output [(1<<N_log)-1:0] Mask;
output OneDetected;
//
reg [(1<<N_log)-1:0] Out;
reg [(1<<N_log)-1:0] Mask;
reg                  OneDetected;
//
// Temporary registers
reg [N_log:0] tmp;
reg           DetectNot;
//
   always @(In) begin
      DetectNot = 1;
      for (tmp=0; tmp<(1<<N_log); tmp=tmp+1) begin
         if(DetectNot) Mask[tmp] = 1;
         else Mask[tmp] = 0;
         if(In[tmp] & DetectNot) begin
            Out[tmp]  = 1;
            DetectNot = 0;
         end
         else begin
             Out[tmp] = 0;
         end
      end
      OneDetected   = !DetectNot;
   end
//
endmodule
//
// Priority Enforcer and Encoder Module
// Priority is right <- left (MS)
//
module LdEnPriorEnf(Clk, Reset, LdEn, In, Out, Mask, OneDetected);
//
parameter N_log = 3 ;
//
input  Clk;
input  Reset;
input  LdEn;
input  [(1<<N_log)-1:0] In;
output [(1<<N_log)-1:0] Out;
output [(1<<N_log)-1:0] Mask;
output OneDetected;
//
reg [(1<<N_log)-1:0] OutComb;
reg [(1<<N_log)-1:0] MaskComb;
reg                  OneDetectedComb;
//
reg [(1<<N_log)-1:0] OutReg;
reg [(1<<N_log)-1:0] MaskReg;
reg                  OneDetectedReg;
//
// Temporary registers
reg [N_log:0] tmp;
reg           DetectNot;
//
   always @(In) begin
      DetectNot = 1;
      for (tmp=0; tmp<(1<<N_log); tmp=tmp+1) begin
         if(DetectNot) MaskComb[tmp] = 1;
         else MaskComb[tmp] = 0;
         if(In[tmp] & DetectNot) begin
            OutComb[tmp]  = 1;
            DetectNot = 0;
         end
         else begin
             OutComb[tmp] = 0;
         end
      end
      OneDetectedComb   = !DetectNot;
   end
//
   always @(posedge Clk) begin
      if(Reset) begin
         OutReg <= #`dh 0;
         MaskReg <= #`dh 0;
         OneDetectedReg <= #`dh 0;
	  end
	  else if (LdEn) begin
         OutReg <= #`dh OutComb;
         MaskReg <= #`dh MaskComb;
         OneDetectedReg <= #`dh OneDetectedComb;
	  end
   end
//
   wire [(1<<N_log)-1:0] Out = (LdEn) ? OutComb : OutReg;
   wire [(1<<N_log)-1:0] Mask = (LdEn) ? MaskComb : MaskReg;
   wire                  OneDetected = (LdEn) ? OneDetectedComb : OneDetectedReg;

//
endmodule
//
// Decoder Module
//
module decoder(o_out, i_in);
//
parameter N_log = 3;
//
input  [(N_log-1):0]    i_in;
output [(1<<N_log)-1:0] o_out;
//
reg [(1<<N_log)-1:0] o_out;
// Temporary registers
reg [N_log:0] tmp;
//
 always @(i_in) begin
    for (tmp=0; tmp<(1<<N_log); tmp=tmp+1) begin
       if(i_in == tmp) begin
          o_out[tmp]  = 1;
       end
       else begin
          o_out[tmp] = 0;
       end
    end
 end
//
endmodule
//
// Encoder Module
//
module encoder(o_out, i_in);
//
parameter N_log = 3;
//
input  [(1<<N_log)-1:0] i_in;
output [(N_log-1):0]    o_out;
//
reg [(N_log-1):0] o_out;
// Temporary registers
reg [N_log:0] tmp;
//
 always @(i_in) begin
    o_out = 0;
    for (tmp=0; tmp<(1<<N_log); tmp=tmp+1) begin
       if(i_in[tmp]) begin
          o_out = tmp;
       end
    end
 end
//
endmodule

