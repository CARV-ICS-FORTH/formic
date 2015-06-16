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
// Abstract      : Address Region Table (ART) top-level module
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: art.v,v $
// CVS revision  : $Revision: 1.14 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
// ART
//
module art (
 input             clk_cpu, 
 input             rst_cpu, 
 input             clk_mc, 
 input             rst_mc, 
//
 input      [31:0] i_cpu_iadr,
 input             i_cpu_istrobe, 
 input             i_cpu_ifetch, 
 output     [31:0] o_cpu_idata, 
 output            o_cpu_iready,
//
 input      [31:0] i_cpu_dadr, 
 input             i_cpu_dstrobe, 
 input             i_cpu_drd,
 input             i_cpu_dwr, 
 input      [ 3:0] i_cpu_dben,
 input      [31:0] i_cpu_dwdata, 
 output     [31:0] o_cpu_drdata, 
 output            o_cpu_dready,
//
 input      [11:0] i_ctl_entry0_base,
 input             i_ctl_entry0_u_flag,
 input      [11:0] i_ctl_entry1_base,
 input      [11:0] i_ctl_entry1_end,
 input      [ 4:0] i_ctl_entry1_flags,
 input             i_ctl_entry1_valid,
 input      [11:0] i_ctl_entry2_base,
 input      [11:0] i_ctl_entry2_end,
 input      [ 4:0] i_ctl_entry2_flags,
 input             i_ctl_entry2_valid,
 input      [11:0] i_ctl_entry3_base,
 input      [11:0] i_ctl_entry3_end,
 input      [ 4:0] i_ctl_entry3_flags,
 input             i_ctl_entry3_valid,
 input      [11:0] i_ctl_entry4_base,
 input      [11:0] i_ctl_entry4_end,
 input      [ 4:0] i_ctl_entry4_flags,
 input             i_ctl_entry4_valid,
//
 input             i_ctl_privileged,
 output reg        o_ctl_perm_fault,
 output reg        o_ctl_miss_fault,
 output reg        o_ctl_tlb_fault,
 input             i_ctl_fault_ack,
//
 output     [31:0] o_il1_adr,
 output            o_il1_valid,
 output reg        o_il1_flag,
 input      [31:0] i_il1_data,
 input             i_il1_tlb_fault,
 input             i_il1_stall,
//
 output     [31:0] o_dl1_adr,
 output            o_dl1_valid,
 output reg [ 1:0] o_dl1_flags,
 output     [ 3:0] o_dl1_ben,
 output            o_dl1_wen,
 input      [31:0] i_dl1_rdata,
 output     [31:0] o_dl1_wdata,
 input             i_dl1_tlb_fault,
 input             i_dl1_stall);
//
wire [31:0] cpu_iadr_sync;
wire [31:0] cpu_idata_sync;
wire [31:0] dl1_data_sync;
wire [31:0] cpu_dadr_sync;
wire [31:0] cpu_dwdata_sync;
wire [ 5:0] flags;
wire        I_ArtReq, D_ArtReq;
wire        ArtMiss ;
wire        I_Fault_Strobe, D_Fault_Strobe;
wire [31:0] i_resp_data  = I_Fault_Strobe ? 32'h8000_0000 : i_il1_data;
wire [31:0] d_resp_data  = D_Fault_Strobe ? 32'h0000_0000 : i_dl1_rdata;
//
// I Sync
//
  align_clk_sync isync0(.clk_in(clk_cpu), .rst_in(rst_cpu),
                        .i_data(i_cpu_iadr), .i_valid(i_cpu_istrobe), .o_stall(),
                        .clk_out(clk_mc), .rst_out(rst_mc),
                        .o_data(cpu_iadr_sync), .o_valid(I_ArtReq), .i_stall(D_ArtReq)),
//
                 isync1(.clk_in(clk_mc), .rst_in(rst_mc),
                        .i_data(i_resp_data), .i_valid(~i_il1_stall | I_Fault_Strobe), .o_stall(),
                        .clk_out(clk_cpu), .rst_out(rst_cpu),
                        .o_data(cpu_idata_sync), .o_valid(o_cpu_iready), .i_stall(1'b0)),
//
// D Sync
//
                 isync2(.clk_in(clk_cpu), .rst_in(rst_cpu),
                        .i_data({i_cpu_dben,
                                 i_cpu_dwr,
                                 i_cpu_dwdata,
                                 i_cpu_dadr}), .i_valid(i_cpu_dstrobe), .o_stall(),
                        .clk_out(clk_mc), .rst_out(rst_mc),
                        .o_data({o_dl1_ben,
                                 o_dl1_wen,
                                 cpu_dwdata_sync,
                                 cpu_dadr_sync}), .o_valid(D_ArtReq), .i_stall(1'b0)),
//
                 isync3(.clk_in(clk_mc), .rst_in(rst_mc),
                        .i_data(d_resp_data), .i_valid(~i_dl1_stall | D_Fault_Strobe), .o_stall(),
                        .clk_out(clk_cpu), .rst_out(rst_cpu),
                        .o_data(o_cpu_drdata), .o_valid(o_cpu_dready), .i_stall(1'b0));
//
  defparam isync0.N = 32;
  defparam isync1.N = 32;
  defparam isync2.N = 69;
  defparam isync3.N = 32;
//
// flags [C, I, R, X, U, P]
//
wire C_flag = flags[5];
wire I_flag = flags[4];
wire R_flag = flags[3];
wire X_flag = flags[2];
wire U_flag = flags[1];
wire P_flag = flags[0];
//
art_fsm ifsm(.o_Mem_Req        ( o_il1_valid ),
             .o_Miss_Fault     ( I_Miss_Fault ),
             .o_Perm_Fault     ( I_Perm_Fault ),
             .o_Fault_Strobe   ( I_Fault_Strobe ),
             .i_Fault_Ack      ( i_ctl_fault_ack ),
             .i_Art_Req        ( (I_ArtReq & ~D_serving) ),
             .o_serving        ( I_serving ),
             .i_Mem_Ack        ( ~i_il1_stall ),
             .i_Art_Miss       ( ArtMiss ),
             .i_I_flag         ( I_flag ),
             .i_R_flag         ( R_flag ),
             .i_X_flag         ( X_flag ),
             .i_U_flag         ( U_flag ),
             .i_P_flag         ( P_flag ),
             .i_ctl_privileged ( i_ctl_privileged ),
             .i_wr_op          ( 1'b0 ),
             .Clk              ( clk_mc ),
             .Reset            ( rst_mc )),
  //
        dfsm(.o_Mem_Req        ( o_dl1_valid ),
             .o_Miss_Fault     ( D_Miss_Fault ),
             .o_Perm_Fault     ( D_Perm_Fault ),
             .o_Fault_Strobe   ( D_Fault_Strobe ),
             .i_Fault_Ack      ( i_ctl_fault_ack ),
             .i_Art_Req        ( D_ArtReq),
             .o_serving        ( D_serving ),
             .i_Mem_Ack        ( ~i_dl1_stall ),
             .i_Art_Miss       ( ArtMiss ),
             .i_I_flag         ( I_flag ),
             .i_R_flag         ( R_flag ),
             .i_X_flag         ( X_flag ),
             .i_U_flag         ( U_flag ),
             .i_P_flag         ( P_flag ),
             .i_ctl_privileged ( i_ctl_privileged ),
             .i_wr_op          ( o_dl1_wen ),
             .Clk              ( clk_mc ),
             .Reset            ( rst_mc ));
//
defparam ifsm.fsm_type = 0;
defparam dfsm.fsm_type = 1;
//
wire [11:0] addr_msb   = (D_serving) ? cpu_dadr_sync[31:20] : cpu_iadr_sync[31:20];
//
wire entry0_hit = (addr_msb == i_ctl_entry0_base);
//
wire entry1_hit = (addr_msb >= i_ctl_entry1_base) &
                  (addr_msb <= i_ctl_entry1_end) &
                  i_ctl_entry1_valid &
                  ~entry0_hit;
//
wire entry2_hit = (addr_msb >= i_ctl_entry2_base) &
                  (addr_msb <= i_ctl_entry2_end) &
                  i_ctl_entry2_valid &
                  ~entry0_hit & ~entry1_hit;
//
wire entry3_hit = (addr_msb >= i_ctl_entry3_base) &
                  (addr_msb <= i_ctl_entry3_end) &
                  i_ctl_entry3_valid &
                  ~entry0_hit & ~entry1_hit & ~entry2_hit;
//
wire entry4_hit = (addr_msb >= i_ctl_entry4_base) &
                  (addr_msb <= i_ctl_entry4_end) &
                  i_ctl_entry4_valid &
                  ~entry0_hit & ~entry1_hit & ~entry2_hit & ~entry3_hit;
//
assign flags = {4'b0100,i_ctl_entry0_u_flag,1'b1}                   & {6{entry0_hit}} |
               {i_ctl_entry1_flags[4],1'b0,i_ctl_entry1_flags[3:0]} & {6{entry1_hit}} |
               {i_ctl_entry2_flags[4],1'b0,i_ctl_entry2_flags[3:0]} & {6{entry2_hit}} |
               {i_ctl_entry3_flags[4],1'b0,i_ctl_entry3_flags[3:0]} & {6{entry3_hit}} |
               {i_ctl_entry4_flags[4],1'b0,i_ctl_entry4_flags[3:0]} & {6{entry4_hit}};
//
assign ArtMiss = ~(entry0_hit | entry1_hit | entry2_hit | entry3_hit | entry4_hit);
assign o_il1_adr    = cpu_iadr_sync;
assign o_dl1_adr    = cpu_dadr_sync;
assign o_dl1_wdata  = cpu_dwdata_sync;
assign o_cpu_idata  = cpu_idata_sync;
//
// o_ctl_perm_fault
//
always @(posedge clk_mc) begin
   if(rst_mc) 
       o_ctl_perm_fault <= #`dh 1'b0;
   else begin
       if(I_Perm_Fault | D_Perm_Fault)
          o_ctl_perm_fault <= #`dh 1'b1;
       else if(i_ctl_fault_ack)
          o_ctl_perm_fault <= #`dh 1'b0;
   end
end
//
// o_ctl_miss_fault
//
always @(posedge clk_mc) begin
   if(rst_mc) 
       o_ctl_miss_fault <= #`dh 1'b0;
   else begin
       if(I_Miss_Fault | D_Miss_Fault)
          o_ctl_miss_fault <= #`dh 1'b1;
       else if(i_ctl_fault_ack)
          o_ctl_miss_fault <= #`dh 1'b0;
   end
end
//
// o_ctl_tlb_fault
//
always @(posedge clk_mc) begin
   if(rst_mc)
       o_ctl_tlb_fault <= #`dh 1'b0;
   else begin
       if(i_il1_tlb_fault | i_dl1_tlb_fault)
          o_ctl_tlb_fault <= #`dh 1'b1;
       else if(i_ctl_fault_ack)
          o_ctl_tlb_fault <= #`dh 1'b0;
   end
end
//
always @(posedge clk_mc) begin
   if(rst_mc) begin
      o_il1_flag  <= #`dh 0;
      o_dl1_flags <= #`dh 0;
   end
   else begin
     if(I_serving) o_il1_flag  <= #`dh flags[5];
     if(D_serving) o_dl1_flags <= #`dh flags[5:4];
   end
end
//
endmodule
