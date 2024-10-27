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

// Manage memory strip counters.

module mpmc11_req_strip_cnt(clk, state, wdf_rdy, rdy, num_strips, strip_cnt);
input clk;
input mpmc11_state_t state;
input wdf_rdy;
input rdy;
input [5:0] num_strips;
output reg [5:0] strip_cnt;

reg on;
always_ff @(posedge clk)
if (state==mpmc11_pkg::IDLE) begin
	strip_cnt <= 6'd0;
	on <= 1'b0;
end
else begin
	if (state==mpmc11_pkg::PRESET3)
		on <= 1'b1;
	if (state==mpmc11_pkg::WRITE_DATA0 && wdf_rdy && on) begin
  	if (strip_cnt != num_strips)
    	strip_cnt <= strip_cnt + 3'd1;
    else
    	on <= 1'b0;
  end
  else if (state==mpmc11_pkg::READ_DATA1 && rdy && on) begin
  	if (strip_cnt != num_strips)
	  	strip_cnt <= strip_cnt + 3'd1;
	  else
	  	on <= 1'b0;
	end
end

endmodule
