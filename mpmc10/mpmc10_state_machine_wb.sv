`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2025  Robert Finch, Waterloo
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
import mpmc10_pkg::*;

`define WID256 1'b1;
//`define WID128 1'b1;

module mpmc10_state_machine_wb(rst, clk, calib_complete, to, rdy, wdf_rdy, fifo_empty,
	rd_rst_busy, fifo_out, state,
	num_strips, req_strip_cnt, resp_strip_cnt, rd_data_valid, rmw_hit);
input rst;
input clk;
input calib_complete;
input to;							// state machine time-out
input rdy;
input wdf_rdy;
input fifo_empty;
input rd_rst_busy;
`ifdef WID256
input wb_cmd_request256_t fifo_out;
`endif
`ifdef WID128
input wb_cmd_request128_t fifo_out;
`endif
output mpmc10_state_t state;
input [5:0] num_strips;
input [5:0] req_strip_cnt;
input [5:0] resp_strip_cnt;
input rd_data_valid;
input rmw_hit;

mpmc10_state_t next_state;

always_ff @(posedge clk)
	state <= next_state;

always_comb
if (rst)
	next_state <= mpmc10_pkg::IDLE;	
else begin
	case(state)
	mpmc10_pkg::IDLE:
		if (!fifo_empty && !rd_rst_busy && calib_complete)
			next_state <= mpmc10_pkg::PRESET1;
		else
			next_state <= mpmc10_pkg::IDLE;
	mpmc10_pkg::PRESET1:
		next_state <= mpmc10_pkg::PRESET2;
	mpmc10_pkg::PRESET2:
		next_state <= mpmc10_pkg::PRESET3;
	mpmc10_pkg::PRESET3:
		if (fifo_out.stb && fifo_out.cmd==wishbone_pkg::CMD_STORE)
			next_state <= mpmc10_pkg::WRITE_DATA0;
		else
			next_state <= mpmc10_pkg::READ_DATA0;
	// Write command to the command fifo
	// Write occurs when app_rdy is true
	mpmc10_pkg::WRITE_DATA0:
		if (rdy)// && req_strip_cnt==num_strips)
			next_state <= mpmc10_pkg::WRITE_DATA1;
		else
			next_state <= mpmc10_pkg::WRITE_DATA0;
	mpmc10_pkg::WRITE_DATA1:
		next_state <= mpmc10_pkg::WRITE_DATA2;
	mpmc10_pkg::WRITE_DATA2:
		if (rdy)
			next_state <= mpmc10_pkg::WRITE_DATA3;
		else
			next_state <= mpmc10_pkg::WRITE_DATA2;
	// Write data to the data fifo
	// Write occurs when app_wdf_wren is true and app_wdf_rdy is true
	mpmc10_pkg::WRITE_DATA3:
		if (wdf_rdy)
			next_state <= mpmc10_pkg::IDLE;
		else
			next_state <= mpmc10_pkg::WRITE_DATA3;

	// There could be multiple read requests submitted before any response occurs.
	// Stay in the SET_CMD_RD until all requested strips have been processed.
	mpmc10_pkg::READ_DATA0:
		next_state <= mpmc10_pkg::READ_DATA1;
	// Could it take so long to do the request that we start getting responses
	// back?
	mpmc10_pkg::READ_DATA1:
		if (rdy && req_strip_cnt==num_strips)
			next_state <= mpmc10_pkg::READ_DATA2;
		else
			next_state <= mpmc10_pkg::READ_DATA1;
	// Wait for incoming responses, but only for so long to prevent a hang.
	mpmc10_pkg::READ_DATA2:
		if (rd_data_valid && resp_strip_cnt==num_strips) begin
			case(fifo_out.cmd)
			wishbone_pkg::CMD_LOAD,wishbone_pkg::CMD_LOADZ:
				next_state <= mpmc10_pkg::WAIT_NACK;
			wishbone_pkg::CMD_ADD,wishbone_pkg::CMD_OR,wishbone_pkg::CMD_AND,wishbone_pkg::CMD_EOR,wishbone_pkg::CMD_ASL,wishbone_pkg::CMD_LSR,
			wishbone_pkg::CMD_MIN,wishbone_pkg::CMD_MAX,wishbone_pkg::CMD_MINU,wishbone_pkg::CMD_MAXU,wishbone_pkg::CMD_CAS:
				next_state <= mpmc10_pkg::ALU;
			default:
				next_state <= mpmc10_pkg::WAIT_NACK;
			endcase
		end
		else
			next_state <= mpmc10_pkg::READ_DATA2;
	
	mpmc10_pkg::ALU:
		if (rmw_hit)
			next_state <= mpmc10_pkg::ALU1;
	mpmc10_pkg::ALU1:
		next_state <= mpmc10_pkg::ALU2;
	mpmc10_pkg::ALU2:
		next_state <= mpmc10_pkg::ALU3;
	mpmc10_pkg::ALU3:
		next_state <= mpmc10_pkg::ALU4;
	mpmc10_pkg::ALU4:
		next_state <= mpmc10_pkg::WRITE_TRAMP1;
		
	mpmc10_pkg::WRITE_TRAMP1:
		next_state <= mpmc10_pkg::WRITE_DATA0;

	mpmc10_pkg::WAIT_NACK:
		// If we're not seeing a nack and there is a channel selected, then the
		// cache tag must not have updated correctly.
		// For writes, assume a nack by now.
		next_state <= mpmc10_pkg::IDLE;
		
	default:	next_state <= mpmc10_pkg::IDLE;
	endcase

	// Is the state machine hung? Do not time out during calibration.
	if (to && calib_complete)
		next_state <= mpmc10_pkg::IDLE;
end

endmodule
