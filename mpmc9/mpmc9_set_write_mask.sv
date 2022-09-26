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

module mpmc9_set_write_mask(clk, state,
	we0, we1, we2, we3, we4, we5, we6, we7,
	sel0, sel1, sel2, sel3, sel4, sel5, sel6, sel7,
	adr0, adr1, adr2, adr3, adr4, adr5, adr6, adr7,
	mask0, mask1, mask2, mask3, mask4, mask5, mask6, mask7
);
parameter C0W = 128;
parameter C1W = 128;
parameter C2W = 128;
parameter C3W = 128;
parameter C4W = 128;
parameter C5W = 128;
parameter C6W = 128;
parameter C7W = 128;
input clk;
input [3:0] state;
input we0;
input we1;
input we2;
input we3;
input we4;
input we5;
input we6;
input we7;
input [C0W/8-1:0] sel0;
input [C1W/8-1:0] sel1;
input [C2W/8-1:0] sel2;
input [C3W/8-1:0] sel3;
input [C4W/8-1:0] sel4;
input [C5W/8-1:0] sel5;
input [C6W/8-1:0] sel6;
input [C7W/8-1:0] sel7;
input [31:0] adr0;
input [31:0] adr1;
input [31:0] adr2;
input [31:0] adr3;
input [31:0] adr4;
input [31:0] adr5;
input [31:0] adr6;
input [31:0] adr7;
output reg [15:0] mask0;
output reg [15:0] mask1;
output reg [15:0] mask2;
output reg [15:0] mask3;
output reg [15:0] mask4;
output reg [15:0] mask5;
output reg [15:0] mask6;
output reg [15:0] mask7;

always_ff @(posedge clk)
	tMask(C0W,we0,{15'd0,sel0},adr0[3:0],mask0);
always_ff @(posedge clk)
	tMask(C1W,we1,{15'd0,sel1},adr1[3:0],mask1);
always_ff @(posedge clk)
	tMask(C2W,we2,{15'd0,sel2},adr2[3:0],mask2);
always_ff @(posedge clk)
	tMask(C3W,we3,{15'd0,sel3},adr3[3:0],mask3);
always_ff @(posedge clk)
	tMask(C4W,we4,{15'd0,sel4},adr4[3:0],mask4);
always_ff @(posedge clk)
	tMask(C5W,we5,{15'd0,sel5},adr5[3:0],mask5);
always_ff @(posedge clk)
	tMask(C6W,we6,{15'd0,sel6},adr6[3:0],mask6);
always_ff @(posedge clk)
	tMask(C7W,we7,{15'd0,sel7},adr7[3:0],mask7);

task tMask;
input [7:0] widi;
input wei;
input [15:0] seli;
input [3:0] adri;
output [15:0] masko;
begin
if (state==IDLE)
	if (wei) begin
		if (widi==8'd128)
			masko <= ~seli;
		else if (widi==8'd64)
			masko <= ~({8'd0,seli[7:0]} << {adri[3],3'b0});
		else if (widi==8'd32)
			masko <= ~({12'd0,seli[3:0]} << {adri[3:2],2'b0});
		else if (widi==8'd16)
			masko <= ~({14'd0,seli[1:0]} << {adri[3:1],1'b0});
		else
			masko <= ~({15'd0,seli[0]} << adri[3:0]);
	end
	else
		masko <= 16'h0000;	// read all bytes
end
endtask

endmodule
