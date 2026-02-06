`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2026  Robert Finch, Waterloo
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

import wishbone_pkg::*;
import mmu_pkg::*;

module tlb_bi(clk, cs_tlb, bus, dly, douta,
	hold_entry, hold_entry_no, hold_way);
parameter TLB_ASSOC=4;
input clk;
input cs_tlb;
wb_bus_interface.slave bus;
input dly;
input tlb_entry_t [TLB_ASSOC-1:0] douta;
output tlb_entry_t hold_entry;
output reg [15:0] hold_entry_no;
output reg [7:0] hold_way;

reg read_bit;

// Bus interface
always_ff @(posedge clk)
if (bus.rst) begin
	bus.resp <= {$bits(wb_cmd_response64_t){1'b0}};
	hold_entry <= {$bits(tlb_entry_t){1'b0}};
	hold_entry_no <= 16'h0;
	hold_way <= TLB_ASSOC-1;
	read_bit <= 1'b0;
end
else begin
	if (cs_tlb & bus.req.cyc & bus.req.stb & bus.req.we)
		case(bus.req.adr[5:3])
		3'd0:	hold_entry[ 63: 0] <= bus.req.dat;
		3'd1:	hold_entry[127:64] <= bus.req.dat;
		3'd4:	
			begin
				hold_entry_no <= bus.req.dat[15:0];
				hold_way <= bus.req.dat[17:16];
				read_bit <= bus.req.dat[30];
			end
		default:	;
		endcase
	if (cs_tlb & bus.req.cyc & bus.req.stb) begin
		bus.resp <= {$bits(wb_cmd_response64_t){1'b0}};
		case(bus.req.adr[5:3])
		3'd0:	bus.resp.dat <= read_bit ? douta[hold_way][ 63: 0] : hold_entry[ 63: 0];
		3'd1:	bus.resp.dat <= read_bit ? douta[hold_way][127:64] : hold_entry[127:64];
		3'd4:	bus.resp.dat <= {46'd0,hold_way,hold_entry_no};
		default:	bus.resp.dat <= 64'd0;
		endcase
		bus.resp.tid <= bus.req.tid;
		bus.resp.pri <= bus.req.pri;
		bus.resp.ack <= cs_tlb & bus.req.cyc & bus.req.stb & dly;
	end
	else
		bus.resp <= {$bits(wb_cmd_response64_t){1'b0}};

end

endmodule
