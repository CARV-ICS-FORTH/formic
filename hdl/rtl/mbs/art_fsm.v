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
// Abstract      : ART FSM
//
// =============================[ CVS Variables ]=============================
//
// File name     : $RCSfile: art_fsm.v,v $
// CVS revision  : $Revision: 1.8 $
// Last modified : $Date: 2012/07/03 16:28:57 $
// Last author   : $Author: lyberis $
//
// ===========================================================================

`timescale 1ns/1ps
//
module art_fsm # (
  // I/O width parameter
  parameter fsm_type = 0
) (
//
input        Clk,
input        Reset,
input        i_Mem_Ack,
input        i_Art_Req,
output       o_serving,
input        i_Art_Miss,
input        i_I_flag,
input        i_R_flag,
input        i_X_flag,
input        i_U_flag,
input        i_P_flag,
input        i_ctl_privileged,
input        i_wr_op,
output       o_Miss_Fault,
output       o_Perm_Fault,
output reg   o_Mem_Req,
input        i_Fault_Ack,
output       o_Fault_Strobe);
//
parameter IdleSt      = 3'b001,
          WaitMemAck  = 3'b010,
          FaultServ   = 3'b100;
//
reg  [2:0] State;
//
// synthesis translate_off
reg [256:0] StateString;
always @(State) begin
  case (State) 
    IdleSt     : StateString = "IdleSt";
    WaitMemAck : StateString = "WaitMemAck";
    FaultServ  : StateString = "FaultServ";
    default    : StateString = "ERROR";
  endcase
end
// synthesis translate_on
wire       GotoPermFault;
wire       MemAck = i_Mem_Ack;
wire       ArtReq = i_Art_Req;
//
// FSM
//
 wire GotoFault = GotoPermFault | i_Art_Miss;
//
 always @(posedge Clk) begin
    if(Reset) State <= #`dh IdleSt;
    else begin
       case(State)
//
       IdleSt     : begin
                       if(ArtReq) begin
                          if(GotoFault) 
                               State <= #`dh FaultServ;
                          else State <= #`dh WaitMemAck;
                       end
                       else State <= #`dh IdleSt;
                    end
//
       WaitMemAck : begin
                       if(MemAck)
                          State <= #`dh IdleSt;
                       else State <= #`dh WaitMemAck;
                    end
//
       FaultServ  : begin
                      if(i_Fault_Ack) 
                        State <= #`dh IdleSt;
                      else State <= #`dh FaultServ;
                    end
//
       default    : State <= #`dh IdleSt;
//
       endcase
    end
 end
//
 assign GotoPermFault = fsm_type ?
     // fsm_type = 1: D-type
     ( (i_wr_op & i_R_flag) |           // Write operation, but read-only region
       (i_ctl_privileged &~i_P_flag) |  // Privileged mode, but region non-privileged accessible
       (~i_ctl_privileged &~i_U_flag)   // User mode, but region non-user accessible
     ) :
     // fsm_type = 0: I-type
     ( ~i_X_flag |                      // Region is non-executable
       (i_ctl_privileged &~i_P_flag) |  // Privileged mode, but region non-privileged accessible
       (~i_ctl_privileged &~i_U_flag) | // User mode, but region non-user accessible
       i_I_flag                         // Register accesses not permitted from i-side
     );
//
always @(posedge Clk) begin
  if (Reset)
     o_Mem_Req <= #`dh 1'b0;
  else if ((State==IdleSt) & ArtReq & ~GotoFault)
     o_Mem_Req <= #`dh 1'b1;
  else if (MemAck)
     o_Mem_Req <= #`dh 1'b0;
end
//
assign o_Perm_Fault   = (State==IdleSt) & ArtReq & GotoPermFault & ~i_Art_Miss;
assign o_Miss_Fault   = (State==IdleSt) & ArtReq & i_Art_Miss;
assign o_Fault_Strobe = (State==FaultServ) & i_Fault_Ack;
assign o_serving      = (State==IdleSt) & ArtReq;
//
endmodule
