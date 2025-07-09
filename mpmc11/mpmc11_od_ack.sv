`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2025  Robert Finch, Waterloo
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
//
// Generate read ack, crossing clock domains.
// The ack pulse should be active for only a single clock cycle of the
// destination clock domain.
// The controller clock is likely faster than the port clock, so extend the
// the controller generated ack by a few cycles, then detect the positive
// edge on the port clock domain.
// ============================================================================
//

module mpmc11_od_ack(rst, clk, pclk, port, fifo_port, rdy, port_ack);
input rst;
input clk;
input pclk;
input [3:0] port;
input [3:0] fifo_port;
input rdy;
output port_ack;

reg chod_ack;
reg chod_acks;
reg [3:0] chodq;

always_ff @(posedge clk)
if (rst) begin
	chod_ack <= 1'd0;
	chodq <= 4'd0;
end
else begin
	if (rdy && port==fifo_port) begin
		chodq <= 4'b0001;
		chod_ack <= 1'b1;
	end
	else
		chodq <= {chodq[2:0],1'b0};
	if (chodq[3])
		chod_ack <= 1'b0;
end

// Synchronize to port's clock domain.
always_ff @(posedge pclk) chod_acks <= chod_ack;

wire pe_chod_ack;
edge_det ued1 (.rst(rst), .clk(pclk), .ce(1'b1), .i(chod_acks), .pe(pe_chod_ack), .ne(), .ee());

assign	port_ack = pe_chod_ack;

endmodule
