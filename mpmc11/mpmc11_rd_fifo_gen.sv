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

module mpmc11_rd_fifo_gen(rst, clk, state, empty, rd_rst_busy, calib_complete, rd);
input rst;
input clk;
input mpmc11_state_t state;
input [7:0] empty;
input [7:0] rd_rst_busy;
input calib_complete;
output reg [7:0] rd;

integer jj;
reg [7:0] next_rd;

always_comb
begin
	next_rd = 8'h00;
	case(state)
	mpmc11_pkg::IDLE:
		begin
			for (jj = 0; jj < 8; jj = jj + 1)
				if (!empty[jj] && !rd_rst_busy[jj] && calib_complete)
					next_rd[jj] = 1'b1;
		end
	default:	;
	endcase
end

always_ff @(posedge clk)
if (rst)
	rd <= 8'h00;
else
	rd <= next_rd;

endmodule
