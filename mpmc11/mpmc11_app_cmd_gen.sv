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

module mpmc11_app_cmd_gen(rst, clk, state, wr, cmd);
input rst;
input clk;
input mpmc11_state_t state;
input wr;
output reg [2:0] cmd;

// Strangely, for the DDR3 the default is to have a write command value,
// overridden when a read is needed. The command is processed by the 
// WRITE_DATAx states.
// Transition CMD only when EN is low.

reg next_cmd;

always_comb
if (rst)
	next_cmd = mpmc11_pkg::CMD_WRITE;
else begin
	case(state)
	mpmc11_pkg::IDLE:
		next_cmd = mpmc11_pkg::CMD_WRITE;
	mpmc11_pkg::PRESET3:
		if (wr)
			next_cmd = mpmc11_pkg::CMD_WRITE;
		else
			next_cmd = mpmc11_pkg::CMD_READ;
	mpmc11_pkg::WAIT_NACK,
	mpmc11_pkg::ALU:
		next_cmd = mpmc11_pkg::CMD_WRITE;
	default:
		next_cmd = cmd;
	endcase
end

always_ff @(posedge clk)
if (rst)
	cmd <= mpmc11_pkg::CMD_WRITE;
else
	cmd <= next_cmd;

endmodule
