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

module mpmc10_addr_gen(rst, clk, state, rdy, num_strips, strip_cnt, addr_base, addr);
parameter WID=256;
input rst;
input clk;
input mpmc10_state_t state;
input rdy;
input [5:0] num_strips;
input [5:0] strip_cnt;
input [31:0] addr_base;
output reg [31:0] addr;

always_ff @(posedge clk)
if (rst)
	addr <= 32'h3FFFFFFF;
else begin
	if (state==mpmc10_pkg::PRESET2)
		addr <= WID==256 ? {addr_base[31:5],5'h0} : {addr_base[31:4],4'h0};
	else if (state==mpmc10_pkg::READ_DATA1 && rdy && strip_cnt != num_strips) begin
		if (WID==256)
			addr[31:5] <= addr[31:5] + 2'd1;
		else
			addr[31:4] <= addr[31:4] + 2'd1;
	end
	// Increment the address if we had to start a new burst.
//	else if (state==WRITE_DATA3 && req_strip_cnt!=num_strips)
//		app_addr <= app_addr + {req_strip_cnt,4'h0};	// works for only 1 missed burst
end

endmodule
