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

module mpmc9_video_strm_read_cache(rst, wclk, wr, wadr, wdat,
	rclk, radr, rdat, hit
);
input rst;
input wclk;
input wr;
input [31:0] wadr;
input [127:0] wdat;
input rclk;
input [31:0] radr;
output reg [127:0] rdat;
output reg hit;

(* ram_style="block" *)
reg [127:0] lines [0:255];
reg [31:0] tag [0:255];
reg [31:0] radrr;
reg [31:0] tago;

always_ff @(posedge rclk)
	radrr <= radr;
always_ff @(posedge wclk)
	if (wr) lines[wadr[11:4]] <= wdat;
always_ff @(posedge rclk)
	rdat <= lines[radrr[11:4]];
always_ff @(posedge rclk)
	tago <= tag[radrr[11:4]];
always_ff @(posedge wclk)
	if (wr) tag[wadr[11:4]] <= wadr;
always_comb
	hit = tago[31:4]==radr[31:4];

endmodule
