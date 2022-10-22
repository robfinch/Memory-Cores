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
import const_pkg::*;
import wishbone_pkg::*;
import mpmc10_pkg::*;

module mpmc10_cache_test();

reg rst;
reg clk;
reg wclk;
reg ch6clk;
typedef enum logic [5:0] {
	ST1 = 6'd1,
	ST2,ST3,ST4,ST5
} state_t;
state_t state;

initial begin
	clk = 1'b0;
	wclk = 1'b0;
	ch6clk = 1'b0;
	rst = 1'b0;
	#5 rst = 1'b1;
	#305 rst = 1'b0;
end

always #5 clk = ~clk;
always #5 wclk = ~wclk;
always #12 ch6clk = ~ch6clk;

reg [7:0] count, count2;
wb_write_request128_t ld, ch6i;
wb_read_response128_t ch6o;

mpmc10_cache_wb ucache1
(
	.rst(rst),
	.wclk(wclk),
	.inv(1'b0),
	.wchi('d0),
	.wcho(),
	.ld(ld),
	.ch0i('d0),
	.ch1i('d0),
	.ch2i('d0),
	.ch3i('d0),
	.ch4i('d0),
	.ch5i('d0),
	.ch6i(ch6i),
	.ch7i('d0),
	.ch0clk(1'b0),
	.ch1clk(1'b0),
	.ch2clk(1'b0),
	.ch3clk(1'b0),
	.ch4clk(1'b0),
	.ch5clk(1'b0),
	.ch6clk(ch6clk),
	.ch7clk(1'b0),
	.ch0wack(),
	.ch1wack(),
	.ch2wack(),
	.ch3wack(),
	.ch4wack(),
	.ch5wack(),
	.ch6wack(1'b0),
	.ch7wack(),
	.ch0o(),
	.ch1o(),
	.ch2o(),
	.ch3o(),
	.ch4o(),
	.ch5o(),
	.ch6o(ch6o),
	.ch7o()
);

always @(posedge ch6clk)
if (rst)
	state <= ST1;
else begin
	case(state)
	ST1:	state <= ST2;
	ST2:	state <= ST3;
	ST3:	state <= ST4;
	ST4:
		if (ch6o.ack)
			state <= ST5;
	ST5:	state <= ST1;
	default:	state <= ST1;
	endcase
end

always @(posedge wclk)
if (rst) begin
	ld <= 'd0;
	count <= 'd0;
end
else begin
	case(state)
	ST1,ST2,ST3,ST4:
		begin
			ld.cyc <= 1'b1;
			ld.stb <= 1'b1;
			ld.we <= 1'b0;
			ld.adr <= 32'h300000 + {count,4'h0};
			ld.dat <= {8{16'h7C00}};
			ld.sel <= -1;
			count <= count + 2'd1;
		end
	endcase
end


always @(posedge ch6clk)
if (rst) begin
	ch6i <= 'd0;
	count2 <= 'd0;
end
else
case(state)
ST3:
	begin
		ch6i.cyc <= 1'b1;
		ch6i.stb <= 1'b1;
		ch6i.we <= 1'b0;
		ch6i.sel <= -1;
		ch6i.adr <= 32'h300000 + {count2,4'h0};
	end
ST4:
	if (ch6o.ack) begin
		ch6i.cyc <= 1'b0;
		ch6i.stb <= 1'b0;
		count2 <= count2 + 2'd1;
	end
endcase

endmodule
