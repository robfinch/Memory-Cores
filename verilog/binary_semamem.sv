// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	binary_semamem.sv
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
// Address
// 0b00nnnnnnnnnn00		write value only if mem is zero (lock)
// 0b01nnnnnnnnnn00	  write zero only if mem==write data (unlock)
// 0b10nnnnnnnnnn00		write value
// 0b11nnnnnnnnnn00		write value
//
// To Lock Semaphore:
//	write a key value to address 0b00nnnnnnnnnn00 where n...n is the semaphore
//  read back the value stored to see if the update was successful and the key
//  was stored.
// To Unlock Semaphore
//  write the key value to address 0x01nnnnnnnnnn00
//  
// ============================================================================

module binary_semamem(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o);
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [13:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;

wire cs = cs_i & cyc_i & stb_i;

ack_gen #(
	.READ_STAGES(2),
	.WRITE_STAGES(4),
	.REGISTER_OUTPUT(1)
) uag1
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.rid_i('d0),
	.wid_i('d0),
	.i(cs & ~we_i),
	.we_i(cs & we_i),
	.o(ack_o),
	.rid_o(),
	.wid_o()
);

(* ram_style="block" *)
reg [31:0] mem [0:1023];
reg [31:0] memo, memi;
reg [13:0] radr;
always_ff @(posedge clk_i)
	radr <= adr_i;
always_ff @(posedge clk_i)
	memo <= mem[radr[11:2]];
always_ff @(posedge clk_i)
if (cs & we_i & ack_o)
	mem[adr_i[11:2]] <= memi;
always_ff @(posedge clk_i)
	casez(adr_i[13:12])
	2'b00:	memi <= (~|memo) ? dat_i : memo;
	2'b01:	memi <= (memo[23:0]==dat_i[23:0]) ? 32'd0 : memo;
	2'b1?:	memi <= dat_i;
	endcase

always_ff @(posedge clk_i)
if (cs)
  dat_o <= mem[adr_i[11:2]];
else
	dat_o <= 32'h00;

endmodule
