// ============================================================================
//        __
//   \\__/ o\    (C) 2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// MemoryRandomizer.sv
// - Randomize DRAM memory. Used primarily for testing.
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

module MemoryRandomizer(rst, clk, req);
input rst;
input clk;
output fta_cmd_request128_t req;

reg [31:0] count;
wire [30:0] lfsr31o;

lfsr31 ulfsr1
(
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.cyc(1'b0),
	.o(lfsr31o)
);

always_ff @(posedge clk, posedge rst)
if (rst) begin
	req.vadr = 'd0;
	req.padr <= 'd0;
	req.cyc <= 'd0;
	req.stb <= 'd0;
	req.cid <= 4'd0;
	req.tid <= 15'h1234;
	req.blen <= 'd0;
	req.bte <= fta_bus_pkg::LINEAR;
	req.cti <= fta_bus_pkg::CLASSIC;
	req.we <= 'd0;
	req.sel <= 'd0;
	req.data1 <= 'd0;
end
else begin
	if (count[31]) begin
		req.cyc <= 'd0;
		req.stb <= 'd0;
		req.we <= 1'b0;
		req.sel <= 'd0;
	end
	else begin
		count <= count + 2;
		req.cyc <= 1'b1;
		req.stb <= 1'b1;
		req.we <= 1'b1;
		req.sel <= 16'h3 << {count[3:1],1'b0};
		req.data1 <= {8{lfsr31o[15:0]}};
		req.padr <= {count[29:1],1'b0};
	end
end

endmodule
