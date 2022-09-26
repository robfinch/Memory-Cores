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

module mpmc9_data_select(clk, state, ch,
	dati0, dati1, dati2, dati3, dati4, dati5, dati6, dati7, dato
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
input [3:0] ch;
input [C0W-1:0] dati0;
input [C1W-1:0] dati1;
input [C2W-1:0] dati2;
input [C3W-1:0] dati3;
input [C4W-1:0] dati4;
input [C5W-1:0] dati5;
input [C6W-1:0] dati6;
input [C7W-1:0] dati7;
output reg [127:0] dato;

// Setting the write data
// Repeat the data across lanes when less than 128-bit.
always_ff @(posedge clk)
if (state==IDLE) begin
	case(ch)
	4'd0:	dato <= {(128/C0W){dati0}};
	4'd1:	dato <= {(128/C1W){dati1}};
	4'd2:	dato <= {(128/C2W){dati2}};
	4'd3:	dato <= {(128/C3W){dati3}};
	4'd4:	dato <= {(128/C4W){dati4}};
	4'd5:	dato <= {(128/C4W){dati5}};
	4'd6:	dato <= {(128/C6W){dati6}};
	4'd7:	dato <= {(128/C7W){dati7}};
	default:	dato <= {2{dati7}};
	endcase
end

endmodule
