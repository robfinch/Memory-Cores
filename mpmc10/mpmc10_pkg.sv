// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
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
package mpmc10_pkg;

parameter CACHE_ASSOC = 4;

parameter RMW = 0;
parameter NAR = 2;
parameter AMSB = 28;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter CMD_READ = 3'b001;
parameter CMD_WRITE = 3'b000;

// State machine states
typedef enum logic [3:0] {
	IDLE = 4'd0,
	PRESET1 = 4'd1,
	PRESET2 = 4'd2,
	WRITE_DATA0 = 4'd3,
	WRITE_DATA1 = 4'd4,
	WRITE_DATA2 = 4'd5,
	WRITE_DATA3 = 4'd6,
	READ_DATA = 4'd7,
	READ_DATA0 = 4'd8,
	READ_DATA1 = 4'd9,
	READ_DATA2 = 4'd10,
	WAIT_NACK = 4'd11,
	WRITE_TRAMP = 4'd12,	// write trampoline
	WRITE_TRAMP1 = 4'd13,
	PRESET3 = 4'd14
} mpmc10_state_t;

typedef struct packed
{
	logic [31:4] tag;
	logic modified;
	logic [127:0] data;
} mpmc10_cache_line_t;

typedef struct packed
{
	mpmc10_cache_line_t [CACHE_ASSOC-1:0] lines;
} mpmc10_quad_cache_line_t;

endpackage
