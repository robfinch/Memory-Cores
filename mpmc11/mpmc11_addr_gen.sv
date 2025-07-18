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
import mpmc11_pkg::*;

module mpmc11_addr_gen(rst, clk, state, rdy, wdf_rdy, burst_len, burst_cnt, addr_base, addr);
parameter WID=256;
localparam INC_AMT = WID/8;
input rst;
input clk;
input mpmc11_state_t state;
input rdy;
input wdf_rdy;
input [7:0] burst_len;
input [7:0] burst_cnt;
input [31:0] addr_base;
output reg [31:0] addr;

reg [31:0] next_addr;

always_comb
case(state)
mpmc11_pkg::IDLE:
	next_addr = 32'd0;
mpmc11_pkg::PRESET2:	// For both read and write.
	next_addr = {addr_base[31:5],5'h0};
mpmc11_pkg::READ_DATA0:
	if (rdy)
//		next_addr = burst_len==8'd0 ? addr : addr + INC_AMT;
		next_addr = addr + INC_AMT;
	else
		next_addr = addr;
mpmc11_pkg::READ_DATA1:
	if (rdy)
//		next_addr = burst_len==8'd0 ? addr : addr + INC_AMT;
		next_addr = addr + INC_AMT;
	else
		next_addr = addr;
mpmc11_pkg::READ_DATA2:
	if (rdy)
//		next_addr = burst_len==8'd0 ? addr : addr + INC_AMT;
		next_addr = addr + INC_AMT;
	else
		next_addr = addr;
mpmc11_pkg::WRITE_DATA1:
	if (wdf_rdy & rdy)
//		next_addr = burst_len==8'd0 ? addr : addr + INC_AMT;
		next_addr = addr + INC_AMT;
	else
		next_addr = addr;
default:
	next_addr = addr;
endcase

always_ff @(posedge clk)
if (rst)
	addr <= 32'h0;
else
	addr <= {2'b00,next_addr[29:0]};

endmodule
