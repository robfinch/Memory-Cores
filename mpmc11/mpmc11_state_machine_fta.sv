`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
//
import fta_bus_pkg::*;
import mpmc11_pkg::*;

module mpmc11_state_machine_fta(rst, clk, calib_complete,
	ref_req, ref_ack, app_ref_ack,
	to, rdy, wdf_rdy, fifo_empty,
	rst_busy, fifo_out, fifo_v, state,
	burst_len, req_burst_cnt, resp_burst_cnt, rd_data_valid, rmw_hit);
input rst;
input clk;
input calib_complete;
input ref_req;
output reg ref_ack;
input app_ref_ack;
input to;							// state machine time-out
input rdy;
input wdf_rdy;
input fifo_empty;
input rst_busy;
input fta_cmd_request256_t fifo_out;
input fifo_v;
output mpmc11_state_t state;
input [5:0] burst_len;
input [5:0] req_burst_cnt;
input [5:0] resp_burst_cnt;
input rd_data_valid;
input rmw_hit;

mpmc11_state_t next_state;

always_ff @(posedge clk)
if (rst) begin
	ref_ack <= 1'b0;
	state <= mpmc11_pkg::IDLE;
end
else begin
	state <= next_state;
	if (state == mpmc11_pkg::IDLE && calib_complete && ref_req)
		ref_ack <= 1'b1;
	else if (state == mpmc11_pkg::REFRESH)
		ref_ack <= 1'b0;
end

always_comb
if (rst)
	next_state <= mpmc11_pkg::IDLE;	
else begin
	next_state <= mpmc11_pkg::IDLE;
	case(state)
	// If the request was a streaming channel and there was a hit on it, do
	// not do the request.
	mpmc11_pkg::IDLE:
		if (calib_complete) begin
			if (ref_req)
				next_state <= mpmc11_pkg::REFRESH;
			else if (!rst_busy) begin
				if (fifo_v)
					next_state <= PRESET1;
				else
					next_state <= mpmc11_pkg::IDLE;
			end
		end
		else
			next_state <= mpmc11_pkg::IDLE;
	REFRESH:
		if (app_ref_ack)
			next_state <= mpmc11_pkg::IDLE;
		else
			next_state <= mpmc11_pkg::REFRESH;
	PRESET1:
		next_state <= PRESET2;
	PRESET2:
		next_state <= PRESET3;
	PRESET3:
		if (fifo_out.cyc && fifo_out.we)//cmd==fta_bus_pkg::CMD_STORE)
			next_state <= WRITE_DATA0;
		else if (fifo_out.cyc)
			next_state <= READ_DATA0;
		else
			next_state <= mpmc11_pkg::IDLE;
	WRITE_DATA0:
		next_state <= WRITE_DATA1;
	// Write data fifo first, done when wdf_rdy is high
	WRITE_DATA1:	// set app_en high
		if (wdf_rdy & rdy)// && req_burst_cnt==burst_len)
			next_state <= mpmc11_pkg::IDLE;
//			next_state <= WRITE_DATA2;
		else
			next_state <= WRITE_DATA1;
//	WRITE_DATA1:	
//		next_state <= WRITE_DATA2;
	// Write command to the command fifo
	// Write occurs when app_rdy is true
	WRITE_DATA2:
		if (rdy)
			next_state <= mpmc11_pkg::IDLE;
		else
			next_state <= WRITE_DATA2;
	// Data is now written first, at WRITE_DATA0
	// Write data to the data fifo
	// Write occurs when app_wdf_wren is true and app_wdf_rdy is true
	/*
	WRITE_DATA3:
		if (wdf_rdy)
			next_state <= mpmc11_pkg::IDLE;
		else
			next_state <= WRITE_DATA3;
	*/
	// There could be multiple read requests submitted before any response occurs.
	READ_DATA0:
		if (rdy)
			next_state <= READ_DATA2;
		else
			next_state <= READ_DATA0;
//		next_state <= READ_DATA1;
	// Could it take so long to do the request that we start getting responses
	// back?
	READ_DATA1:
		if (req_burst_cnt==burst_len)
			next_state <= READ_DATA2;
		else
			next_state <= READ_DATA0;
	// Wait for incoming responses, but only for so long to prevent a hang.
	// Submit more requests for a burst.
	READ_DATA2:
		if (rd_data_valid && resp_burst_cnt==burst_len) begin
			case(fifo_out.cmd)
			fta_bus_pkg::CMD_LOAD,fta_bus_pkg::CMD_LOADZ:
				next_state <= WAIT_NACK;
			fta_bus_pkg::CMD_ADD,fta_bus_pkg::CMD_OR,fta_bus_pkg::CMD_AND,fta_bus_pkg::CMD_EOR,fta_bus_pkg::CMD_ASL,fta_bus_pkg::CMD_LSR,
			fta_bus_pkg::CMD_MIN,fta_bus_pkg::CMD_MAX,fta_bus_pkg::CMD_MINU,fta_bus_pkg::CMD_MAXU,fta_bus_pkg::CMD_CAS:
				next_state <= mpmc11_pkg::ALU;
			default:
				next_state <= WAIT_NACK;
			endcase
		end
		else
			next_state <= READ_DATA2;
	
	mpmc11_pkg::ALU:
		if (rmw_hit)
			next_state <= mpmc11_pkg::ALU1;
	mpmc11_pkg::ALU1:
		next_state <= mpmc11_pkg::ALU2;
	mpmc11_pkg::ALU2:
		next_state <= mpmc11_pkg::ALU3;
	mpmc11_pkg::ALU3:
		next_state <= mpmc11_pkg::ALU4;
	mpmc11_pkg::ALU4:
		next_state <= WRITE_TRAMP1;
		
	WRITE_TRAMP1:
		next_state <= WRITE_DATA0;

	WAIT_NACK:
		// If we're not seeing a nack and there is a channel selected, then the
		// cache tag must not have updated correctly.
		// For writes, assume a nack by now.
		next_state <= mpmc11_pkg::IDLE;
		
	default:	next_state <= mpmc11_pkg::IDLE;
	endcase

	// Is the state machine hung? Do not time out during calibration.
	if (to && calib_complete)
		next_state <= mpmc11_pkg::IDLE;
end

endmodule
