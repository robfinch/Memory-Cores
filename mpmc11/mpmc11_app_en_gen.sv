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
import mpmc11_pkg::*;

module mpmc11_app_en_gen(rst, clk, state, rdy, wdf_rdy, burst_cnt, burst_len, en);
input rst;
input clk;
input mpmc11_state_t state;
input rdy;
input wdf_rdy;
input [7:0] burst_cnt;
input [7:0] burst_len;
output reg en;

// app_en latches the command and address when app_rdy is active. If app_rdy
// is not true, the command must be retried.
reg en1;
always_ff @(posedge clk)
if (rst)
	en1 <= 1'b0;
else begin
	case(state)
	mpmc11_pkg::WRITE_DATA1:
		en1 <= 1'b1;
	mpmc11_pkg::WRITE_DATA2:
		if (rdy)
			en1 <= 1'b0;
		else
			en1 <= 1'b1;
	mpmc11_pkg::READ_DATA0:
		en1 <= 1'b0;
	mpmc11_pkg::READ_DATA1:
		en1 <= 1'b1;
	default:
		en1 <= 1'b0;
	endcase
end

always_comb en = (state==mpmc11_pkg::WRITE_DATA1 & rdy & wdf_rdy) ||
	((state==mpmc11_pkg::READ_DATA0 & rdy) || (state==mpmc11_pkg::READ_DATA2 && rdy && burst_cnt <= burst_len));
// en1 & ~(state==READ_DATA1 && rdy && burst_cnt==burst_len);

endmodule
