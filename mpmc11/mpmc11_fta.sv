`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2024  Robert Finch, Waterloo
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
// 26500 LUTs, 130 BRAM (64kB cache)
// 21400 LUTs no AMO
//
// Read channels always wait until there is valid data in the cache.
// ============================================================================
//
//`define RED_SCREEN	1'b1
`define SUPPORT_AMO	1'b1
//`define SUPPORT_AMO_TETRA	1'b1
//`define SUPPORT_AMO_OCTA 1'b1
//`define SUPPORT_AMO_SHIFT	1'b1
//`define SUPPORT_AMO_MULTI_SHIFT	1'b1

import fta_bus_pkg::*;
import mpmc11_pkg::*;

module mpmc11_fta (
input rst,
input clk100MHz,
input mem_ui_rst,
input mem_ui_clk,
input calib_complete,
output reg rstn,
output [31:0] app_waddr,
input app_rdy,
output app_en,
output [2:0] app_cmd,
output [29:0] app_addr,
input app_rd_data_valid,
output [31:0] app_wdf_mask,
output reg [WIDX8-1:0] app_wdf_data,
input app_wdf_rdy,
output app_wdf_wren,
output app_wdf_end,
input [WIDX8-1:0] app_rd_data,
input app_rd_data_end,
input ch0clk, ch1clk, ch2clk, ch3clk, ch4clk, ch5clk, ch6clk, ch7clk,
input fta_cmd_request256_t ch0i,
output fta_cmd_response256_t ch0o,
input fta_cmd_request256_t ch1i,
output fta_cmd_response256_t ch1o,
input fta_cmd_request256_t ch2i,
output fta_cmd_response256_t ch2o,
input fta_cmd_request256_t ch3i,
output fta_cmd_response256_t ch3o,
input fta_cmd_request256_t ch4i,
output fta_cmd_response256_t ch4o,
input fta_cmd_request256_t ch5i,
output fta_cmd_response256_t ch5o,
input fta_cmd_request256_t ch6i,
output fta_cmd_response256_t ch6o,
input fta_cmd_request256_t ch7i,
output fta_cmd_response256_t ch7o,
output mpmc11_state_t state
);
parameter NAR = 2;			// Number of address reservations
parameter CL = 3'd4;		// Cache read latency
parameter STREAM0 = 1'b1;
parameter STREAM1 = 1'b0;
parameter STREAM2 = 1'b0;
parameter STREAM3 = 1'b0;
parameter STREAM4 = 1'b0;
parameter STREAM5 = 1'b1;
parameter STREAM6 = 1'b0;
parameter STREAM7 = 1'b0;
parameter RMW0 = 1'b0;
parameter RMW1 = 1'b1;
parameter RMW2 = 1'b0;
parameter RMW3 = 1'b0;
parameter RMW4 = 1'b0;
parameter RMW5 = 1'b0;
parameter RMW6 = 1'b0;
parameter RMW7 = 1'b1;

fta_cmd_request256_t ch0i2;
fta_cmd_request256_t ch1i2;
fta_cmd_request256_t ch2i2;
fta_cmd_request256_t ch3i2;
fta_cmd_request256_t ch4i2;
fta_cmd_request256_t ch5i2;
fta_cmd_request256_t ch6i2;
fta_cmd_request256_t ch7i2;
fta_cmd_request256_t [7:0] chi;

always_comb chi[0] = ch0i;
always_comb chi[1] = ch1i;
always_comb chi[2] = ch2i;
always_comb chi[3] = ch3i;
always_comb chi[4] = ch4i;
always_comb chi[5] = ch5i;
always_comb chi[6] = ch6i;
always_comb chi[7] = ch7i;

fta_cmd_response256_t ch0oa, ch0ob, ch0oc;
fta_cmd_response256_t ch1oa, ch1ob, ch1oc;
fta_cmd_response256_t ch2oa, ch2ob, ch2oc;
fta_cmd_response256_t ch3oa, ch3ob, ch3oc;
fta_cmd_response256_t ch4oa, ch4ob, ch4oc;
fta_cmd_response256_t ch5oa, ch5ob, ch5oc;
fta_cmd_response256_t ch6oa, ch6ob, ch6oc;
fta_cmd_response256_t ch7oa, ch7ob, ch7oc;
fta_cmd_response256_t [7:0] chob;
always_comb ch0ob = chob[0];
always_comb ch1ob = chob[1];
always_comb ch2ob = chob[2];
always_comb ch3ob = chob[3];
always_comb ch4ob = chob[4];
always_comb ch5ob = chob[5];
always_comb ch6ob = chob[6];
always_comb ch7ob = chob[7];

fta_cmd_request256_t ch0is;
fta_cmd_request256_t ch1is;
fta_cmd_request256_t ch2is;
fta_cmd_request256_t ch3is;
fta_cmd_request256_t ch4is;
fta_cmd_request256_t ch5is;
fta_cmd_request256_t ch6is;
fta_cmd_request256_t ch7is;

wire rmw0 = ch0is.cmd[4];
wire rmw1 = ch1is.cmd[4];
wire rmw2 = ch2is.cmd[4];
wire rmw3 = ch3is.cmd[4];
wire rmw4 = ch4is.cmd[4];
wire rmw5 = ch5is.cmd[4];
wire rmw6 = ch6is.cmd[4];
wire rmw7 = ch7is.cmd[4];

wire [7:0] chclk;
assign chclk[0] = ch0clk;
assign chclk[1] = ch1clk;
assign chclk[2] = ch2clk;
assign chclk[3] = ch3clk;
assign chclk[4] = ch4clk;
assign chclk[5] = ch5clk;
assign chclk[6] = ch6clk;
assign chclk[7] = ch7clk;

wire [7:0] streaming;
assign streaming[0] = STREAM0;
assign streaming[1] = STREAM1;
assign streaming[2] = STREAM2;
assign streaming[3] = STREAM3;
assign streaming[4] = STREAM4;
assign streaming[5] = STREAM5;
assign streaming[6] = STREAM6;
assign streaming[7] = STREAM7;

assign ch0o = STREAM0 ? ch0ob : rmw0 ? ch0oc : ch0oa;
assign ch1o = STREAM1 ? ch1ob : rmw1 ? ch1oc : ch1oa;
assign ch2o = STREAM2 ? ch2ob : rmw2 ? ch2oc : ch2oa;
assign ch3o = STREAM3 ? ch3ob : rmw3 ? ch3oc : ch3oa;
assign ch4o = STREAM4 ? ch4ob : rmw4 ? ch4oc : ch4oa;
assign ch5o = STREAM5 ? ch5ob : rmw5 ? ch5oc : ch5oa;
assign ch6o = STREAM6 ? ch6ob : rmw6 ? ch6oc : ch6oa;
assign ch7o = STREAM7 ? ch7ob : rmw7 ? ch7oc : ch7oa;

mpmc11_fifoe_t [7:0] req_fifoi;
mpmc11_fifoe_t [7:0] req_fifog;
mpmc11_fifoe_t req_fifoo;
fta_cmd_request256_t ld;
fta_cmd_request256_t fifo_mask;
mpmc11_fifoe_t fifoo;

assign fifoo.req = req_fifoo.req & fifo_mask;
assign fifoo.port = req_fifoo.port;

genvar g;
integer n1,n2,n3;
reg v;
wire full;
wire [7:0] empty;
wire almost_full;
wire [4:0] cnt;
reg [7:0] rd_fifo;
reg [7:0] wr_fifo;
wire rd_fifo_sm;
mpmc11_state_t prev_state;
reg [5:0] num_strips;	// from fifo
wire [5:0] req_strip_cnt;
wire [5:0] resp_strip_cnt;
wire [15:0] tocnt;
reg [31:0] adr;
reg [3:0] uport;		// update port
wire [31:0] wmask;
wire [31:0] mem_wdf_mask2;
reg [WIDX8-1:0] dat128;
wire [WIDX8-1:0] dat256;
wire [3:0] resv_ch [0:NAR-1];
wire [31:0] resv_adr [0:NAR-1];
wire rb1;
reg [7:0] req;
reg [WIDX8-1:0] rd_data_r;
reg rd_data_valid_r;
reg cas_ok;

wire [7:0] ch_hit_s;
wire ch0_hit_ne, ch5_hit_ne;
wire hit0, hit1, hit2, hit3, hit4, hit5, hit6, hit7;

always_ff @(posedge mem_ui_clk)
if (app_rd_data_valid)
	rd_data_r <= app_rd_data;
always_ff @(posedge mem_ui_clk)
	rd_data_valid_r <= app_rd_data_valid;

reg [19:0] rst_ctr;
always @(posedge clk100MHz)
if (rst)
	rst_ctr <= 24'd0;
else begin
	if (!rst_ctr[15])
		rst_ctr <= rst_ctr + 2'd1;
	rstn <= rst_ctr[15] || rst_ctr < 20'd16;
end

reg [7:0] cyc;
always_comb cyc[0] = ch0is.cyc;
always_comb cyc[1] = ch1is.cyc;
always_comb cyc[2] = ch2is.cyc;
always_comb cyc[3] = ch3is.cyc;
always_comb cyc[4] = ch4is.cyc;
always_comb cyc[5] = ch5is.cyc;
always_comb cyc[6] = ch6is.cyc;
always_comb cyc[7] = ch7is.cyc;

reg [2:0] chcnt [0:7];
always_ff @(posedge mem_ui_clk)
if (rst) begin
	for (n2 = 0; n2 < 8; n2 = n2 + 1)
		chcnt[n2] <= 3'd0;
end
else begin
	for (n2 = 0; n2 < 8; n2 = n2 + 1)
		if (cyc[n2]) begin
			if (chcnt[n2] < CL)
				chcnt[n2] <= chcnt[n2] + 2'd1;
		end
		else
			chcnt[n2] <= 3'd0;
end

wire [7:0] pe_req;
reg [7:0] chack;
always_comb chack[0] = ch0o.ack;
always_comb chack[1] = ch1o.ack;
always_comb chack[2] = ch2o.ack;
always_comb chack[3] = ch3o.ack;
always_comb chack[4] = ch4o.ack;
always_comb chack[5] = ch5o.ack;
always_comb chack[6] = ch6o.ack;
always_comb chack[7] = ch7o.ack;

reg [7:0] reqa;
always_comb reqa[0] = (!ch0o.ack && ch0is.cyc && !ch0is.we && chcnt[0]==CL) || (ch0is.we && ch0is.cyc);
always_comb reqa[1] = (!ch1o.ack && ch1is.cyc && !ch1is.we && chcnt[1]==CL) || (ch1is.we && ch1is.cyc);
always_comb reqa[2] = (!ch2o.ack && ch2is.cyc && !ch2is.we && chcnt[2]==CL) || (ch2is.we && ch2is.cyc);
always_comb reqa[3] = (!ch3o.ack && ch3is.cyc && !ch3is.we && chcnt[3]==CL) || (ch3is.we && ch3is.cyc);
always_comb reqa[4] = (!ch4o.ack && ch4is.cyc && !ch4is.we && chcnt[4]==CL) || (ch4is.we && ch4is.cyc);
always_comb reqa[5] = (!ch5o.ack && ch5is.cyc && !ch5is.we && chcnt[5]==CL) || (ch5is.we && ch5is.cyc);
always_comb reqa[6] = (!ch6o.ack && ch6is.cyc && !ch6is.we && chcnt[6]==CL) || (ch6is.we && ch6is.cyc);
always_comb reqa[7] = (!ch7o.ack && ch7is.cyc && !ch7is.we && chcnt[7]==CL) || (ch7is.we && ch7is.cyc);

wire rste = mem_ui_rst||rst||!calib_complete;

edge_det edch0 (
	.rst(rste),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(reqa[0]),
	.pe(pe_req[0]),
	.ne(),
	.ee()
);
edge_det edch1 (
	.rst(rste),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(reqa[1]),
	.pe(pe_req[1]),
	.ne(),
	.ee()
);
edge_det edch2 (
	.rst(rste),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(reqa[2]),
	.pe(pe_req[2]),
	.ne(),
	.ee()
);
edge_det edch3 (
	.rst(rste),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(reqa[3]),
	.pe(pe_req[3]),
	.ne(),
	.ee()
);
edge_det edch4 (
	.rst(rste),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(reqa[4]),
	.pe(pe_req[4]),
	.ne(),
	.ee()
);
edge_det edch5 (
	.rst(rste),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(reqa[5]),
	.pe(pe_req[5]),
	.ne(),
	.ee()
);
edge_det edch6 (
	.rst(rste),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(reqa[6]),
	.pe(pe_req[6]),
	.ne(),
	.ee()
);
edge_det edch7 (
	.rst(rste),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(reqa[7]),
	.pe(pe_req[7]),
	.ne(),
	.ee()
);
wire [3:0] req_sel;
always_ff @(posedge mem_ui_clk)
	for (n3 = 0; n3 < 8; n3 = n3 + 1)
		if (pe_req[n3])
			req[n3] <= 1'b1;
		else if ((req_sel==n3[3:0]) || chack[n3])
			req[n3] <= 1'b0;

// Register signals onto mem_ui_clk domain
mpmc11_sync256_fta usyn0
(
	.clk(mem_ui_clk),
	.i(ch0i),
	.o(ch0is)
);
mpmc11_sync256_fta usyn1
(
	.clk(mem_ui_clk),
	.i(ch1i),
	.o(ch1is)
);
mpmc11_sync256_fta usyn2
(
	.clk(mem_ui_clk),
	.i(ch2i),
	.o(ch2is)
);
mpmc11_sync256_fta usyn3
(
	.clk(mem_ui_clk),
	.i(ch3i),
	.o(ch3is)
);
mpmc11_sync256_fta usyn4
(
	.clk(mem_ui_clk),
	.i(ch4i),
	.o(ch4is)
);
mpmc11_sync256_fta usyn5
(
	.clk(mem_ui_clk),
	.i(ch5i),
	.o(ch5is)
);
mpmc11_sync256_fta usyn6
(
	.clk(mem_ui_clk),
	.i(ch6i),
	.o(ch6is)
);
mpmc11_sync256_fta usyn7
(
	.clk(mem_ui_clk),
	.i(ch7i),
	.o(ch7is)
);

// Streaming channels have a burst length of 64. Round the address to the burst
// length???
always_comb
begin
	ch0i2 <= ch0i;
	ch0i2.padr <= {ch0i.padr[31:5],5'b0};
end
always_comb
begin
	ch1i2 <= ch1i;
	ch1i2.padr <= {ch1i.padr[31:5],5'b0};
end
always_comb
begin
	ch2i2 <= ch2i;
	ch2i2.padr <= {ch2i.padr[31:5],5'b0};
end
always_comb
begin
	ch3i2 <= ch3i;
	ch3i2.padr <= {ch3i.padr[31:5],5'b0};
end
always_comb
begin
	ch4i2 <= ch4i;
	ch4i2.padr <= {ch4i.padr[31:5],5'b0};
end
always_comb
begin
	ch5i2 <= ch5i;
	ch5i2.padr <= {ch5i.padr[31:5],5'b0};
end
always_comb
begin
	ch6i2 <= ch6i;
	ch6i2.padr <= {ch6i.padr[31:5],5'b0};
end
always_comb
begin
	ch7i2 <= ch7i;
	ch7i2.padr <= {ch7i.padr[31:5],5'b0};
end

always_comb
begin
	ld.bte <= fta_bus_pkg::LINEAR;
	ld.cti <= fta_bus_pkg::CLASSIC;
	ld.blen <= 6'd0;
	ld.cyc <= fifoo.req.cyc && !fifoo.req.we && rd_data_valid_r && (uport!=4'd0 && uport!=4'd5 && uport!=4'd15);
	ld.stb <= fifoo.req.cyc && !fifoo.req.we && rd_data_valid_r && (uport!=4'd0 && uport!=4'd5 && uport!=4'd15);
	ld.we <= 1'b0;
	ld.padr <= {app_waddr[31:5],5'h0};
	ld.data1 <= rd_data_r;
	ld.sel <= {32{1'b1}};		// update all bytes
end

reg ch0wack;
reg ch1wack;
reg ch2wack;
reg ch3wack;
reg ch4wack;
reg ch5wack;
reg ch6wack;
reg ch7wack;

always_ff @(posedge mem_ui_clk)
begin
	if (!ch0i.cyc)	ch0wack <= 1'b0;
	if (!ch1i.cyc)	ch1wack <= 1'b0;
	if (!ch2i.cyc)	ch2wack <= 1'b0;
	if (!ch3i.cyc)	ch3wack <= 1'b0;
	if (!ch4i.cyc)	ch4wack <= 1'b0;
	if (!ch5i.cyc)	ch5wack <= 1'b0;
	if (!ch6i.cyc)	ch6wack <= 1'b0;
	if (!ch7i.cyc)	ch7wack <= 1'b0;
	if (state==WRITE_DATA3)
		case(uport)
		4'd0:	ch0wack <= 1'b1;
		4'd1: ch1wack <= 1'b1;
		4'd2: ch2wack <= 1'b1;
		4'd3:	ch3wack <= 1'b1;
		4'd4:	ch4wack <= 1'b1;
		4'd5:	ch5wack <= 1'b1;
		4'd6:	ch6wack <= 1'b1;
		4'd7:	ch7wack <= 1'b1;
		default:	;
		endcase
end

mpmc11_cache_fta ucache1
(
	.rst(mem_ui_rst),
	.wclk(mem_ui_clk),
	.inv(1'b0),
	.wchi(fifoo),
	.wcho(),
	.ld(ld),
	.ch0clk(STREAM0 ? 1'b0 : ch0clk),
	.ch1clk(STREAM1 ? 1'b0 : ch1clk),
	.ch2clk(STREAM2 ? 1'b0 : ch2clk),
	.ch3clk(STREAM3 ? 1'b0 : ch3clk),
	.ch4clk(STREAM4 ? 1'b0 : ch4clk),
	.ch5clk(STREAM5 ? 1'b0 : ch5clk),
	.ch6clk(STREAM6 ? 1'b0 : ch6clk),
	.ch7clk(STREAM7 ? 1'b0 : ch7clk),
	.ch0i(STREAM0 ? {$bits(fta_cmd_request256_t){1'b0}} : ch0is),
	.ch1i(STREAM1 ? {$bits(fta_cmd_request256_t){1'b0}} : ch1is),
	.ch2i(STREAM2 ? {$bits(fta_cmd_request256_t){1'b0}} : ch2is),
	.ch3i(STREAM3 ? {$bits(fta_cmd_request256_t){1'b0}} : ch3is),
	.ch4i(STREAM4 ? {$bits(fta_cmd_request256_t){1'b0}} : ch4is),
	.ch5i(STREAM5 ? {$bits(fta_cmd_request256_t){1'b0}} : ch5is),
	.ch6i(STREAM6 ? {$bits(fta_cmd_request256_t){1'b0}} : ch6is),
	.ch7i(STREAM7 ? {$bits(fta_cmd_request256_t){1'b0}} : ch7is),
	.ch0wack(ch0wack),
	.ch1wack(ch1wack),
	.ch2wack(ch2wack),
	.ch3wack(ch3wack),
	.ch4wack(ch4wack),
	.ch5wack(ch5wack),
	.ch6wack(ch6wack),
	.ch7wack(ch7wack),
	.ch0o(ch0oa),
	.ch1o(ch1oa),
	.ch2o(ch2oa),
	.ch3o(ch3oa),
	.ch4o(ch4oa),
	.ch5o(ch5oa),
	.ch6o(ch6oa),
	.ch7o(ch7oa),
	.ch0hit(hit0),
	.ch1hit(hit1),
	.ch2hit(hit2),
	.ch3hit(hit3),
	.ch4hit(hit4),
	.ch5hit(hit5),
	.ch6hit(hit6),
	.ch7hit(hit7)
);

// A burst request has also been sent to the fifo. It will be cancelled out
// when the state machine detects an already successful read of the streaming
// channel.

generate begin : gStreamCache
for (g = 0; g < 8; g = g + 1) begin
mpmc11_strm_read_cache ustrm
(
	.rst(rst),
	.wclk(mem_ui_clk),
	.wr(uport==g[3:0] && rd_data_valid_r),
	.wadr({app_waddr[31:5],5'h0}),
	.wdat(rd_data_r),
	.inv(1'b0),
	.rclk(chclk[g]),
	.req(chi[g]),
	.resp(chob[g]),
	.hit(ch_hit_s[g])
);
end
end
endgenerate

wire [7:0] sel;
wire [7:0] rd_rst_busy;
wire [7:0] wr_rst_busy;
wire cd_sel;
change_det #(.WID($bits(mpmc11_fifoe_t))) ucdsel (.rst(rst), .ce(1'b1), .clk(mem_ui_clk), .i(req_fifoi), .cd(cd_sel));

wire [7:0] reqo;
wire [7:0] vg;

roundRobin rr1
(
	.rst(rst),
	.clk(mem_ui_clk),
	.ce(1'b1),//~|req || chack[req_sel]),
	.req(reqo),
	.lock(8'h00),
	.sel(sel),
	.sel_enc(req_sel)
);

always_comb
begin
	req_fifoi[0].port <= 4'd0;
	req_fifoi[0].req <= STREAM0 ? ch0i2 : ch0i;
	req_fifoi[1].port <= 4'd1;
	req_fifoi[1].req <= STREAM1 ? ch1i2 : ch1i;
	req_fifoi[2].port <= 4'd2;
	req_fifoi[2].req <= STREAM2 ? ch2i2 : ch2i;
	req_fifoi[3].port <= 4'd3;
	req_fifoi[3].req <= STREAM3 ? ch3i2 : ch3i;
	req_fifoi[4].port <= 4'd4;
	req_fifoi[4].req <= STREAM4 ? ch4i2 : ch4i;
	req_fifoi[5].port <= 4'd5;
	req_fifoi[5].req <= STREAM5 ? ch5i2 : ch5i;
	req_fifoi[6].port <= 4'd6;
	req_fifoi[6].req <= STREAM6 ? ch6i2 : ch6i;
	req_fifoi[7].port <= 4'd7;
	req_fifoi[7].req <= STREAM7 ? ch7i2 : ch7i;
end

// An asynchronous fifo is used at the input to allow the clock to be different
// than the ui_clk.

generate begin : gInputFifos
for (g = 0; g < 8; g = g + 1) begin
assign reqo[g] = req_fifog[g].req.cyc;
always_comb wr_fifo[g] = req_fifoi[g].req.cyc;
always_comb rd_fifo[g] = sel[g] & rd_fifo_sm;

mpmc11_asfifo_fta ufifo
(
	.rst(rst),
	.rd_clk(mem_ui_clk),
	.rd_fifo(rd_fifo[g]),
	.wr_clk(chclk[g]),
	.wr_fifo(wr_fifo[g]),
	.req_fifoi(req_fifoi[g]),
	.req_fifoo(req_fifog[g]),
	.v(vg[g]),
	.full(),
	.empty(empty[g]),
	.almost_full(),
	.rd_rst_busy(rd_rst_busy[g]),
	.wr_rst_busy(wr_rst_busy[g]),
	.cnt()
);
end
end
endgenerate

always_comb
	v = vg[req_sel];
always_comb
	req_fifoo = req_fifog[req_sel];
always_comb
	uport = fifoo.port;
always_comb
	num_strips = fifoo.req.blen;
always_comb
	adr = fifoo.req.padr;

wire [1:0] app_addr3;	// dummy to make up 32-bits

mpmc11_addr_gen uag1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.num_strips(num_strips),
	.strip_cnt(req_strip_cnt),
	.addr_base(adr),
	.addr({app_addr3,app_addr})
);

mpmc11_waddr_gen uwag1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.valid(rd_data_valid_r),
	.num_strips(num_strips),
	.strip_cnt(resp_strip_cnt),
	.addr_base(adr),
	.addr(app_waddr)
);

mpmc11_mask_select unsks1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.we(fifoo.req.we), 
	.wmask(req_fifoo.req.sel[31:0]),
	.mask(app_wdf_mask),
	.mask2(mem_wdf_mask2)
);

wire [WIDX8-1:0] data128a;
wire [WIDX8-1:0] data128b;

mpmc11_data_select #(.WID(256)) uds1
(
	.clk(mem_ui_clk),
	.state(state),
	.dati1(req_fifoo.req.data1),
	.dati2(req_fifoo.req.data2),
	.dato1(data128a),
	.dato2(data128b)
);

reg rmw_hit;
reg rmw_ack;
reg [WIDX8-1:0] opa, opa1, opb, opc, t1;
reg [WIDX8-1:0] rmw_dat;
`ifdef SUPPORT_AMO
always_comb
	case(req_fifoo.port)
	4'd0:	rmw_hit = hit0;
	4'd1:	rmw_hit = hit1;
	4'd2:	rmw_hit = hit2;
	4'd3:	rmw_hit = hit3;
	4'd4:	rmw_hit = hit4;
	4'd5:	rmw_hit = hit5;
	4'd6:	rmw_hit = hit6;
	4'd7:	rmw_hit = hit7;
	default:	rmw_hit = 1'b1;
	endcase
always_ff @(posedge mem_ui_clk)
	opb <= data128a >> {req_fifoo.req.padr[4:0],3'b0};
always_ff @(posedge mem_ui_clk)
	opc <= data128b >> {req_fifoo.req.padr[4:0],3'b0};
always_ff @(posedge mem_ui_clk)
	case(req_fifoo.port)
	4'd0:	opa1 <= ch0oa.dat;
	4'd1:	opa1 <= ch1oa.dat;
	4'd2:	opa1 <= ch2oa.dat;
	4'd3:	opa1 <= ch3oa.dat;
	4'd4:	opa1 <= ch4oa.dat;
	4'd5:	opa1 <= ch5oa.dat;
	4'd6:	opa1 <= ch6oa.dat;
	4'd7:	opa1 <= ch7oa.dat;
	default:	opa1 <= 'd0;
	endcase
always_ff @(posedge mem_ui_clk)
	opa <= opa1 >> {req_fifoo.req.padr[4:0],3'b0};
always_ff @(posedge mem_ui_clk)
case(req_fifoo.req.sz)
`ifdef SUPPORT_AMO_TETRA
fta_bus_pkg::tetra:
	case(req_fifoo.req.cmd)
	CMD_ADD:	t1 <= opa[31:0] + opb[31:0];
	CMD_AND:	t1 <= opa[31:0] & opb[31:0];
	CMD_OR:		t1 <= opa[31:0] | opb[31:0];
	CMD_EOR:	t1 <= opa[31:0] ^ opb[31:0];
`ifdef SUPPORT_AMO_SHIFT
	CMD_ASL:	t1 <= {opa[30:0],1'b0};
	CMD_LSR:	t1 <= {1'b0,opa[31:1]};
	CMD_ROL:	t1 <= {opa[30:0],opa[31]};
	CMD_ROR:	t1 <= {opa[0],opa[31:1]};
`endif
`ifdef SUPPORT_AMO_MULTI_SHIFT	
	CMD_ASL:	t1 <= opa[31:0] << opb[4:0];
	CMD_LSR:	t1 <= opa[31:0] >> opb[4:0];
`endif	
	CMD_MINU:	t1 <= opa[31:0] < opb[31:0] ? opa[31:0] : opb[31:0];
	CMD_MAXU:	t1 <= opa[31:0] > opb[31:0] ? opa[31:0] : opb[31:0];
	CMD_MIN:	t1 <= $signed(opa[31:0]) < $signed(opb[31:0]) ? opa[31:0] : opb[31:0];
	CMD_MAX:	t1 <= $signed(opa[31:0]) > $signed(opb[31:0]) ? opa[31:0] : opb[31:0];
	CMD_CAS:	t1 <= opa[31:0]==opb[31:0] ? opc[31:0] : opb[31:0];
	default:	t1 <= opa[31:0];
	endcase
`endif
`ifdef SUPPORT_AMO_OCTA
fta_bus_pkg::octa:
	case(req_fifoo.req.cmd)
	CMD_ADD:	t1 <= opa[63:0] + opb[63:0];
	CMD_AND:	t1 <= opa[63:0] & opb[63:0];
	CMD_OR:		t1 <= opa[63:0] | opb[63:0];
	CMD_EOR:	t1 <= opa[63:0] ^ opb[63:0];
`ifdef SUPPORT_AMO_SHIFT
	CMD_ASL:	t1 <= {opa[62:0],1'b0};
	CMD_LSR:	t1 <= {1'b0,opa[63:1]};
	CMD_ROL:	t1 <= {opa[62:0],opa[63]};
	CMD_ROR:	t1 <= {opa[0],opa[63:1]};
`endif
`ifdef SUPPORT_AMO_MULTI_SHIFT	
	CMD_ASL:	t1 <= opa[63:0] << opb[5:0];
	CMD_LSR:	t1 <= opa[63:0] >> opb[5:0];
`endif	
	CMD_MINU:	t1 <= opa[63:0] < opb[63:0] ? opa[63:0] : opb[63:0];
	CMD_MAXU:	t1 <= opa[63:0] > opb[63:0] ? opa[63:0] : opb[63:0];
	CMD_MIN:	t1 <= $signed(opa[63:0]) < $signed(opb[63:0]) ? opa[63:0] : opb[63:0];
	CMD_MAX:	t1 <= $signed(opa[63:0]) > $signed(opb[63:0]) ? opa[63:0] : opb[63:0];
	CMD_CAS:	t1 <= opa[63:0]==opb[63:0] ? opc[63:0] : opb[63:0];
	default:	t1 <= opa[63:0];
	endcase
`endif
default:
	case(req_fifoo.req.cmd)
	fta_bus_pkg::CMD_ADD:	t1 <= opa[127:0] + opb[127:0];
	fta_bus_pkg::CMD_AND:	t1 <= opa[127:0] & opb[127:0];
	fta_bus_pkg::CMD_OR:		t1 <= opa[127:0] | opb[127:0];
	fta_bus_pkg::CMD_EOR:	t1 <= opa[127:0] ^ opb[127:0];
`ifdef SUPPORT_AMO_SHIFT
	CMD_ASL:	t1 <= {opa[126:0],1'b0};
	CMD_LSR:	t1 <= {1'b0,opa[127:1]};
	CMD_ROL:	t1 <= {opa[126:0],opa[127]};
	CMD_ROR:	t1 <= {opa[0],opa[127:1]};
`endif
`ifdef SUPPORT_AMO_MULTI_SHIFT	
	CMD_ASL:	t1 <= opa[127:0] << opb[6:0];
	CMD_LSR:	t1 <= opa[127:0] >> opb[6:0];
`endif	
	fta_bus_pkg::CMD_MINU:	t1 <= opa[127:0] < opb[127:0] ? opa[127:0] : opb[127:0];
	fta_bus_pkg::CMD_MAXU:	t1 <= opa[127:0] > opb[127:0] ? opa[127:0] : opb[127:0];
	fta_bus_pkg::CMD_MIN:	t1 <= $signed(opa[127:0]) < $signed(opb[127:0]) ? opa[127:0] : opb[127:0];
	fta_bus_pkg::CMD_MAX:	t1 <= $signed(opa[127:0]) > $signed(opb[127:0]) ? opa[127:0] : opb[127:0];
	fta_bus_pkg::CMD_CAS:	t1 <= opa[127:0]==opb[127:0] ? opc[127:0] : opb[127:0];
	default:	t1 <= opa[127:0];
	endcase
endcase
always_ff @(posedge mem_ui_clk)
	rmw_dat <= t1 << {req_fifoo.req.padr[4:0],3'b0};

always_ff @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	ch0oc.dat <= 'd0;
	ch1oc.dat <= 'd0;
	ch2oc.dat <= 'd0;
	ch3oc.dat <= 'd0;
	ch4oc.dat <= 'd0;
	ch5oc.dat <= 'd0;
	ch6oc.dat <= 'd0;
	ch7oc.dat <= 'd0;
end
else begin
if (state==WRITE_TRAMP1)
	case(req_fifoo.port)
	4'd0:	ch0oc.dat <= opa;
	4'd1:	ch1oc.dat <= opa;
	4'd2:	ch2oc.dat <= opa;
	4'd3:	ch3oc.dat <= opa;
	4'd4:	ch4oc.dat <= opa;
	4'd5:	ch5oc.dat <= opa;
	4'd6:	ch6oc.dat <= opa;
	4'd7:	ch7oc.dat <= opa;
	default:	;
	endcase
end
always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
	rmw_ack <= 1'b0;
else begin
	if (state==WRITE_TRAMP1)
		rmw_ack <= 1'b1;
	else if (state==IDLE)
		rmw_ack <= 1'b0;
end
always_comb	ch0oc.ack = ch0i.cyc & rmw_ack & rmw0 && req_fifoo.port==4'd0;
always_comb	ch1oc.ack = ch1i.cyc & rmw_ack & rmw1 && req_fifoo.port==4'd1;
always_comb	ch2oc.ack = ch2i.cyc & rmw_ack & rmw2 && req_fifoo.port==4'd2;
always_comb	ch3oc.ack = ch3i.cyc & rmw_ack & rmw3 && req_fifoo.port==4'd3;
always_comb	ch4oc.ack = ch4i.cyc & rmw_ack & rmw4 && req_fifoo.port==4'd4;
always_comb	ch5oc.ack = ch5i.cyc & rmw_ack & rmw5 && req_fifoo.port==4'd5;
always_comb	ch6oc.ack = ch6i.cyc & rmw_ack & rmw6 && req_fifoo.port==4'd6;
always_comb	ch7oc.ack = ch7i.cyc & rmw_ack & rmw7 && req_fifoo.port==4'd7;
`endif

// Setting the data value. Unlike reads there is only a single strip involved.
// Force unselected byte lanes to $FF
reg [WIDX8-1:0] dat128x;
generate begin
	for (g = 0; g < WIDX8/8; g = g + 1)
		always_comb
			if (mem_wdf_mask2[g])
				dat128x[g*8+7:g*8] = 8'hFF;
			else
				dat128x[g*8+7:g*8] = data128a[g*8+7:g*8];
end
endgenerate

always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
  app_wdf_data <= 256'd0;
else begin
	if (state==PRESET3)
		app_wdf_data <= dat128x;
	else if (state==WRITE_TRAMP1)
		app_wdf_data <= rmw_dat;
end

mpmc11_rd_fifo_gen urdf1
(
	.rst(rst|mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.empty(&empty),
	.rd_rst_busy(|rd_rst_busy),
	.calib_complete(calib_complete),
	.rd(rd_fifo_sm)
);

always_ff @(posedge mem_ui_clk)
if (rst)
	fifo_mask <= {$bits(fifo_mask){1'b1}};
else begin
	if (rd_fifo)
		fifo_mask <= {$bits(fifo_mask){1'b1}};
	else if (state==IDLE)
		fifo_mask <= {$bits(fifo_mask){1'b0}};
end

reg stream_hit;
always_comb stream_hit = ch_hit_s[req_fifoo.port] && streaming[req_fifoo.port];

mpmc11_state_machine_fta usm1
(
	.rst(rst|mem_ui_rst),
	.clk(mem_ui_clk),
	.calib_complete(calib_complete),
	.to(tocnt[9]),
	.rdy(app_rdy),
	.wdf_rdy(app_wdf_rdy),
	.fifo_empty(&empty),
	.rd_rst_busy(|rd_rst_busy),
	.stream_hit(stream_hit),
	.fifo_out(req_fifoo.req),
	.state(state),
	.num_strips(num_strips),
	.req_strip_cnt(req_strip_cnt),
	.resp_strip_cnt(resp_strip_cnt),
	.rd_data_valid(rd_data_valid_r),
	.rmw_hit(rmw_hit)
);

mpmc11_to_cnt utoc1
(
	.clk(mem_ui_clk),
	.state(state),
	.prev_state(prev_state),
	.to_cnt(tocnt)
);

mpmc11_prev_state upst1
(
	.clk(mem_ui_clk),
	.state(state),
	.prev_state(prev_state)
);

mpmc11_app_en_gen ueng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.strip_cnt(req_strip_cnt),
	.num_strips(num_strips),
	.en(app_en)
);

mpmc11_app_cmd_gen ucg1
(
	.clk(mem_ui_clk),
	.state(state),
	.cmd(app_cmd)
);

mpmc11_app_wdf_wren_gen uwreng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_wdf_rdy),
	.wren(app_wdf_wren)
);

mpmc11_app_wdf_end_gen uwendg1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_wdf_rdy),
	.strip_cnt(req_strip_cnt),
	.num_strips(num_strips),
	.wend(app_wdf_end)
);

mpmc11_req_strip_cnt ursc1
(
	.clk(mem_ui_clk),
	.state(state),
	.wdf_rdy(app_wdf_rdy),
	.rdy(app_rdy),
	.num_strips(num_strips),
	.strip_cnt(req_strip_cnt)
);

mpmc11_resp_strip_cnt urespsc1
(
	.clk(mem_ui_clk),
	.state(state),
	.valid(rd_data_valid_r),
	.num_strips(num_strips),
	.strip_cnt(resp_strip_cnt)
);

// Reservation status bit
mpmc11_resv_bit ursb1
(
	.clk(mem_ui_clk),
	.state(state),
	.wch(fifoo.port),
	.we(fifoo.req.cyc & fifoo.req.we),
	.cr(fifoo.req.csr & fifoo.req.we),
	.adr(fifoo.req.padr),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.rb(rb1)
);

mpmc11_addr_resv_man #(.NAR(NAR)) ursvm1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.adr0(32'h0),
	.adr1(ch1is.padr),
	.adr2(ch2is.padr),
	.adr3(ch3is.padr),
	.adr4(ch4is.padr),
	.adr5(32'h0),
	.adr6(ch6is.padr),
	.adr7(ch7is.padr),
	.sr0(1'b0),
	.sr1(ch1is.csr & ch1is.cyc & ~ch1is.we),
	.sr2(ch2is.csr & ch2is.cyc & ~ch2is.we),
	.sr3(ch3is.csr & ch3is.cyc & ~ch3is.we),
	.sr4(ch4is.csr & ch4is.cyc & ~ch4is.we),
	.sr5(1'b0),
	.sr6(ch6is.csr & ch6is.cyc & ~ch6is.we),
	.sr7(ch7is.csr & ch7is.cyc & ~ch7is.we),
	.wch(fifoo.req.cyc ? fifoo.port : 4'd15),
	.we(fifoo.req.cyc & fifoo.req.we),
	.wadr(fifoo.req.padr),
	.cr(fifoo.req.csr & fifoo.req.cyc & fifoo.req.we),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr)
);

endmodule
