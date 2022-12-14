`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2022  Robert Finch, Waterloo
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
import mpmc9_pkg::*;

module mpmc9_set_num_strips(clk, state, ch,
	we0, we1, we2, we3, we4, we5, we6, we7, num_strips);
parameter S0 = 6'd63;
parameter S1 = 6'd1;
parameter S2 = 6'd31;
parameter S3 = 6'd63;
parameter S4 = 6'd0;
parameter S5 = 6'd63;
parameter S6 = 6'd63;
parameter S7 = 6'd3;
input clk;
input [3:0] state;
input [3:0] ch;
input we0;
input we1;
input we2;
input we3;
input we4;
input we5;
input we6;
input we7;
output reg [5:0] num_strips;

// Setting burst length
always_ff @(posedge clk)
if (state==IDLE) begin
	num_strips <= 3'd0;
	case(ch)
	4'd0:	if (!we0) num_strips <= S0;		//7
	4'd1:	if (!we1)	num_strips <= S1;		//1
	4'd2:	if (!we2)	num_strips <= S2;
	4'd3:	if (!we3)	num_strips <= S3;
	4'd4:	if (!we4)	num_strips <= S4;
	4'd5:	if (!we5) num_strips <= S5;	//3
	4'd6:	if (!we6)	num_strips <= S6;
	4'd7:	if (!we7) num_strips <= S7;
	default:	;
	endcase
end

endmodule
