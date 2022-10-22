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
// 16000 LUTs, 130 BRAM (64kB cache)
//
// Read channels always wait until there is valid data in the cache.
// ============================================================================
//
//`define RED_SCREEN	1'b1

import wishbone_pkg::*;
import mpmc10_pkg::*;

module mpmc10_wb(
input rst,
input clk100MHz,
input mem_ui_rst,
input mem_ui_clk,
output reg rstn,
output [31:0] app_waddr,
input app_rdy,
output app_en,
output [2:0] app_cmd,
output [28:0] app_addr,
input app_rd_data_valid,
output [15:0] app_wdf_mask,
output reg [127:0] app_wdf_data,
input app_wdf_rdy,
output app_wdf_wren,
output app_wdf_end,
input [127:0] app_rd_data,
input app_rd_data_end,
input ch0clk, ch1clk, ch2clk, ch3clk, ch4clk, ch5clk, ch6clk, ch7clk,
input wb_write_request128_t ch0i,
output wb_read_response128_t ch0o,
input wb_write_request128_t ch1i,
output wb_read_response128_t ch1o,
input wb_write_request128_t ch2i,
output wb_read_response128_t ch2o,
input wb_write_request128_t ch3i,
output wb_read_response128_t ch3o,
input wb_write_request128_t ch4i,
output wb_read_response128_t ch4o,
input wb_write_request128_t ch5i,
output wb_read_response128_t ch5o,
input wb_write_request128_t ch6i,
output wb_read_response128_t ch6o,
input wb_write_request128_t ch7i,
output wb_read_response128_t ch7o,
output [3:0] state
);
parameter NAR = 2;

wb_write_request128_t ch0is;
wb_write_request128_t ch0is2;
wb_write_request128_t ch1is;
wb_write_request128_t ch2is;
wb_write_request128_t ch3is;
wb_write_request128_t ch4is;
wb_write_request128_t ch5is;
wb_write_request128_t ch5is2;
wb_write_request128_t ch6is;
wb_write_request128_t ch7is;

wb_write_request128_t req_fifoi;
wb_write_request128_t req_fifoo;
wb_write_request128_t ld;

genvar g;
integer n1,n2;
wire almost_full;
wire [4:0] cnt;
reg wr_fifo;
wire [3:0] prev_state;
wire [3:0] state;
wire rd_fifo;	// from state machine
reg [5:0] num_strips;	// from fifo
wire [5:0] req_strip_cnt;
wire [5:0] resp_strip_cnt;
wire [15:0] tocnt;
wire [31:0] app_waddr;
reg [31:0] adr;
reg [3:0] uch;		// update channel
wire [15:0] wmask;
wire [15:0] mem_wdf_mask2;
reg [127:0] dat128;
wire [255:0] dat256;
wire [3:0] resv_ch [0:NAR-1];
wire [31:0] resv_adr [0:NAR-1];
wire rb1;
reg [7:0] req;
wire [1:0] wway;
reg [127:0] rd_data_r;
reg rd_data_valid_r;

wire ch0_hit_s, ch5_hit_s;
wire ch0_hit_ne, ch5_hit_ne;
wire [8:0] ch0_cnt, ch5_cnt;
wire [6:0] ch1_cnt;
wire [6:0] ch2_cnt;
wire [6:0] ch3_cnt;
wire [6:0] ch4_cnt;
wire [6:0] ch6_cnt;
wire [6:0] ch7_cnt;

always_ff @(posedge mem_ui_clk)
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
	rstn <= rst_ctr[15];
end

mpmc10_chcnt #(.BITS(8)) uchc0(.rst(rst), .clk(mem_ui_clk), .hit(ch0_hit_s), .cnt(ch0_cnt));
mpmc10_chcnt #(.BITS(7)) uchc1(.rst(rst), .clk(mem_ui_clk), .hit(ch1o.ack || !ch1is.stb), .cnt(ch1_cnt));
mpmc10_chcnt #(.BITS(7)) uchc2(.rst(rst), .clk(mem_ui_clk), .hit(ch2o.ack || !ch2is.stb), .cnt(ch2_cnt));
mpmc10_chcnt #(.BITS(7)) uchc3(.rst(rst), .clk(mem_ui_clk), .hit(ch3o.ack || !ch3is.stb), .cnt(ch3_cnt));
mpmc10_chcnt #(.BITS(7)) uchc4(.rst(rst), .clk(mem_ui_clk), .hit(ch4o.ack || !ch4is.stb), .cnt(ch4_cnt));
mpmc10_chcnt #(.BITS(8)) uchc5(.rst(rst), .clk(mem_ui_clk), .hit(ch5_hit_s), .cnt(ch5_cnt));
mpmc10_chcnt #(.BITS(7)) uchc6(.rst(rst), .clk(mem_ui_clk), .hit(ch6o.ack || !ch6is.stb), .cnt(ch6_cnt));
mpmc10_chcnt #(.BITS(7)) uchc7(.rst(rst), .clk(mem_ui_clk), .hit(ch7o.ack || !ch7is.stb), .cnt(ch7_cnt));

reg [7:0] stb [0:7];
always_comb stb[0] = ch0is.stb;
always_comb stb[1] = ch1is.stb;
always_comb stb[2] = ch2is.stb;
always_comb stb[3] = ch3is.stb;
always_comb stb[4] = ch4is.stb;
always_comb stb[5] = ch5is.stb;
always_comb stb[6] = ch6is.stb;
always_comb stb[7] = ch7is.stb;

reg [2:0] chcnt [0:7];
always_ff @(posedge mem_ui_clk)
if (rst) begin
	for (n2 = 0; n2 < 8; n2 = n2 + 1)
		chcnt[n2] <= 'd0;
end
else begin
	for (n2 = 0; n2 < 8; n2 = n2 + 1)
		if (stb[n2]) begin
			if (!chcnt[n2][1])
				chcnt[n2] <= chcnt[n2] + 2'd1;
		end
		else
			chcnt[n2] <= 'd0;
end

reg [7:0] pe_req;
reg [7:0] chack;
always_comb chack[0] = ch0o.ack;
always_comb chack[1] = ch1o.ack;
always_comb chack[2] = ch2o.ack;
always_comb chack[3] = ch3o.ack;
always_comb chack[4] = ch4o.ack;
always_comb chack[5] = ch5o.ack;
always_comb chack[6] = ch6o.ack;
always_comb chack[7] = ch7o.ack;

	// A request for channel zero is allowed only every 256 clocks.
edge_det edch0 (
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(!ch0_hit_s && ch0_cnt[7] && ch0is.stb && chcnt[0][1]),
	.pe(pe_req[0]),
	.ne(),
	.ee()
);
edge_det edch1 (
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i((!ch1o.ack && ch1_cnt[6] && ch1is.stb && !ch1is.we && chcnt[1][1]) || (ch1is.we && ch1is.stb)),
	.pe(pe_req[1]),
	.ne(),
	.ee()
);
edge_det edch2 (
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i((!ch2o.ack && ch2_cnt[6] && ch2is.stb && chcnt[2][1]) || (ch2is.we && ch2is.stb)),
	.pe(pe_req[2]),
	.ne(),
	.ee()
);
edge_det edch3 (
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i((!ch3o.ack && ch3_cnt[6] && ch3is.stb && chcnt[3][1]) || (ch3is.we && ch3is.stb)),
	.pe(pe_req[3]),
	.ne(),
	.ee()
);
edge_det edch4 (
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i((!ch4o.ack && ch4_cnt[6] && ch4is.stb && chcnt[4][1]) || (ch4is.we && ch4is.stb)),
	.pe(pe_req[4]),
	.ne(),
	.ee()
);
edge_det edch5 (
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i(!ch5_hit_s && ch5_cnt[7] && ch5is.stb && chcnt[5][1]),
	.pe(pe_req[5]),
	.ne(),
	.ee()
);
edge_det edch6 (
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i((!ch6o.ack && ch6_cnt[3] && ch6is.stb && chcnt[6][1]) || (ch6is.we && ch6is.stb)),
	.pe(pe_req[6]),
	.ne(),
	.ee()
);
edge_det edch7 (
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.ce(1'b1),
	.i((!ch7o.ack && ch7_cnt[6] && ch7is.stb && chcnt[7][1]) || (ch7is.we && ch7is.stb)),
	.pe(pe_req[7]),
	.ne(),
	.ee()
);
wire [3:0] req_sel;
generate begin : gReq
	for (g = 0; g < 8; g = g + 1)
		always_ff @(posedge mem_ui_clk)
			if (pe_req[g])
				req[g] <= 1'b1;
			else if (req_sel==g[3:0] || chack[g])
				req[g] <= 1'b0;
end
endgenerate

// Register signals onto mem_ui_clk domain
mpmc10_sync128_wb usyn0
(
	.clk(mem_ui_clk),
	.i(ch0i),
	.o(ch0is)
);
mpmc10_sync128_wb usyn1
(
	.clk(mem_ui_clk),
	.i(ch1i),
	.o(ch1is)
);
mpmc10_sync128_wb usyn2
(
	.clk(mem_ui_clk),
	.i(ch2i),
	.o(ch2is)
);
mpmc10_sync128_wb usyn3
(
	.clk(mem_ui_clk),
	.i(ch3i),
	.o(ch3is)
);
mpmc10_sync128_wb usyn4
(
	.clk(mem_ui_clk),
	.i(ch4i),
	.o(ch4is)
);
mpmc10_sync128_wb usyn5
(
	.clk(mem_ui_clk),
	.i(ch5i),
	.o(ch5is)
);
mpmc10_sync128_wb usyn6
(
	.clk(mem_ui_clk),
	.i(ch6i),
	.o(ch6is)
);
mpmc10_sync128_wb usyn7
(
	.clk(mem_ui_clk),
	.i(ch7i),
	.o(ch7is)
);

always_comb
begin
	ch0is2 <= ch0is;
	ch0is2.adr <= {ch0is.adr[31:10],10'b0};
end
// For the sprite channel, the burst length is 64, round the address to the
// burst length.
always_comb
begin
	ch5is2 <= ch5is;
	ch5is2.adr <= {ch5is.adr[31:10],10'b0};
end

always_comb
begin
	ld.bte <= wishbone_pkg::LINEAR;
	ld.cti <= wishbone_pkg::CLASSIC;
	ld.blen <= 'd0;
	ld.cyc <= req_fifoo.stb && !req_fifoo.we && rd_data_valid_r && (uch!=4'd0 && uch!=4'd5);
	ld.stb <= req_fifoo.stb && !req_fifoo.we && rd_data_valid_r && (uch!=4'd0 && uch!=4'd5);
	ld.we <= 1'b0;
	ld.adr <= {app_waddr[31:4],4'h0};
	ld.dat <= {app_waddr[31:14],8'h00,rd_data_r};	// modified=false,tag = high order address bits
	ld.sel <= {36{1'b1}};		// update all bytes
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
	if (!ch0i.stb)	ch0wack <= 1'b0;
	if (!ch1i.stb)	ch1wack <= 1'b0;
	if (!ch2i.stb)	ch2wack <= 1'b0;
	if (!ch3i.stb)	ch3wack <= 1'b0;
	if (!ch4i.stb)	ch4wack <= 1'b0;
	if (!ch5i.stb)	ch5wack <= 1'b0;
	if (!ch6i.stb)	ch6wack <= 1'b0;
	if (!ch7i.stb)	ch7wack <= 1'b0;
	if (state==WRITE_DATA3)
		case(uch)
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

mpmc10_cache_wb ucache1
(
	.rst(mem_ui_rst),
	.wclk(mem_ui_clk),
	.inv(),
	.wchi(req_fifoo),
	.wcho(),
	.ld(ld),
	.ch0clk(ch0clk),
	.ch1clk(ch1clk),
	.ch2clk(ch2clk),
	.ch3clk(ch3clk),
	.ch4clk(ch4clk),
	.ch5clk(ch5clk),
	.ch6clk(ch6clk),
	.ch7clk(ch7clk),
	.ch0i('d0),
	.ch1i(ch1is),
	.ch2i(ch2is),
	.ch3i(ch3is),
	.ch4i(ch4is),
	.ch5i('d0),
	.ch6i(ch6is),
	.ch7i(ch7is),
	.ch0wack(ch0wack),
	.ch1wack(ch1wack),
	.ch2wack(ch2wack),
	.ch3wack(ch3wack),
	.ch4wack(ch4wack),
	.ch5wack(ch5wack),
	.ch6wack(ch6wack),
	.ch7wack(ch7wack),
	.ch0o(),
	.ch1o(ch1o),
	.ch2o(ch2o),
	.ch3o(ch3o),
	.ch4o(ch4o),
	.ch5o(),
	.ch6o(ch6o),
	.ch7o(ch7o)
);

mpmc10_strm_read_cache ustrm0
(
	.rst(rst),
	.wclk(mem_ui_clk),
	.wr(uch==4'd0 && rd_data_valid_r),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(rd_data_r),
//	.inv(1'b0),
	.rclk(mem_ui_clk),
	.rd(ch0is.stb & ~ch0is.we),
	.radr({ch0is.adr[31:4],4'h0}),
	.rdat(ch0o.dat),
	.hit(ch0_hit_s)
);

mpmc10_strm_read_cache ustrm5
(
	.rst(rst),
	.wclk(mem_ui_clk),
	.wr(uch==4'd5 && rd_data_valid_r),
	.wadr({app_waddr[31:4],4'h0}),
	.wdat(rd_data_r),
//	.inv(1'b0),
	.rclk(mem_ui_clk),
	.rd(ch5is.stb & ~ch5is.we),
	.radr({ch5is.adr[31:4],4'h0}),
	.rdat(ch5o.dat),
	.hit(ch5_hit_s)
);

always_comb
begin
	ch0o.ack = ch0_hit_s & ch0i.stb;
end

always_comb
begin
	ch5o.ack = ch5_hit_s & ch5i.stb;
//	ch5o.dat = {8{16'h7C00}};
end

wire [7:0] sel;
wire rd_rst_busy;
wire wr_rst_busy;
wire cd_sel;
change_det #(.WID(8)) ucdsel (.rst(rst), .clk(mem_ui_clk), .i(sel), .cd(cd_sel));

always_comb	//ff @(posedge mem_ui_clk)
	wr_fifo = |sel & ~almost_full & ~wr_rst_busy & cd_sel;

roundRobin rr1
(
	.rst(rst),
	.clk(mem_ui_clk),
	.ce(1'b1),//~|req || chack[req_sel]),
	.req(req),
	.lock(8'h00),
	.sel(sel),
	.sel_enc(req_sel)
);

always_comb
	case(req_sel)
	4'd0:	req_fifoi <= ch0is2;
	4'd1:	req_fifoi <= ch1is;
	4'd2:	req_fifoi <= ch2is;
	4'd3:	req_fifoi <= ch3is;
	4'd4:	req_fifoi <= ch4is;
	4'd5:	req_fifoi <= ch5is2;
	4'd6:	req_fifoi <= ch6is;
	4'd7:	req_fifoi <= ch7is;
	default:	req_fifoi <= 'd0;
	endcase

mpmc10_fifo ufifo1
(
	.rst(rst),
	.clk(mem_ui_clk),
	.rd_fifo(rd_fifo),
	.wr_fifo(wr_fifo),
	.req_fifoi(req_fifoi),
	.req_fifoo(req_fifoo),
	.v(v),
	.full(full),
	.empty(empty),
	.almost_full(almost_full),
	.rd_rst_busy(rd_rst_busy),
	.wr_rst_busy(wr_rst_busy),
	.cnt(cnt)
);

always_comb
	uch <= req_fifoo.cid;
always_comb
	num_strips <= req_fifoo.blen;
always_comb
	adr <= req_fifoo.adr;

wire [2:0] app_addr3;	// dummy to make up 32-bits

mpmc10_addr_gen uag1
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

mpmc10_waddr_gen uwag1
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

mpmc10_set_write_mask_wb uswm1
(
	.clk(mem_ui_clk),
	.state(state),
	.we(req_fifoo.we), 
	.sel(req_fifoo.sel[15:0]),
	.adr(adr|{req_strip_cnt[0],4'h0}),
	.mask(wmask)
);

mpmc10_mask_select unsks1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.wmask(wmask),
	.mask(app_wdf_mask),
	.mask2(mem_wdf_mask2)
);

mpmc10_data_select #(.WID(128)) uds1
(
	.clk(mem_ui_clk),
	.state(state),
	.dati(req_fifoo.dat),
	.dato(dat256)
);

always_comb
	dat128 <= dat256;//req_strip_cnt[0] ? dat256[255:128] : dat256[127:0];

// Setting the data value. Unlike reads there is only a single strip involved.
// Force unselected byte lanes to $FF
reg [127:0] dat128x;
generate begin
	for (g = 0; g < 16; g = g + 1)
		always_comb
			if (mem_wdf_mask2[g])
				dat128x[g*8+7:g*8] = 8'hFF;
			else
				dat128x[g*8+7:g*8] = dat128[g*8+7:g*8];
end
endgenerate

always_ff @(posedge mem_ui_clk)
if (mem_ui_rst)
  app_wdf_data <= 128'd0;
else begin
	if (state==PRESET2)
		app_wdf_data <= dat128x;
//	else if (state==WRITE_TRAMP1)
//		app_wdf_data <= rmw_data;
end


mpmc10_state_machine_wb usm1
(
	.rst(rst|mem_ui_rst),
	.clk(mem_ui_clk),
	.to(tocnt[9]),
	.rdy(app_rdy),
	.wdf_rdy(app_wdf_rdy),
	.fifo_empty(empty),
	.rd_rst_busy(rd_rst_busy),
	.rd_fifo(rd_fifo),
	.fifo_out(req_fifoo),
	.state(state),
	.num_strips(num_strips),
	.req_strip_cnt(req_strip_cnt),
	.resp_strip_cnt(resp_strip_cnt),
	.rd_data_valid(rd_data_valid_r)
);

mpmc10_to_cnt utoc1
(
	.clk(mem_ui_clk),
	.state(state),
	.prev_state(prev_state),
	.to_cnt(tocnt)
);

mpmc10_prev_state upst1
(
	.clk(mem_ui_clk),
	.state(state),
	.prev_state(prev_state)
);

mpmc10_app_en_gen ueng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.strip_cnt(req_strip_cnt),
	.num_strips(num_strips),
	.en(app_en)
);

mpmc10_app_cmd_gen ucg1
(
	.clk(mem_ui_clk),
	.state(state),
	.cmd(app_cmd)
);

mpmc10_app_wdf_wren_gen uwreng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_wdf_rdy),
	.wren(app_wdf_wren)
);

mpmc10_app_wdf_end_gen uwendg1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_wdf_rdy),
	.strip_cnt(req_strip_cnt),
	.num_strips(num_strips),
	.wend(app_wdf_end)
);

mpmc10_req_strip_cnt ursc1
(
	.clk(mem_ui_clk),
	.state(state),
	.wdf_rdy(app_wdf_rdy),
	.rdy(app_rdy),
	.num_strips(num_strips),
	.strip_cnt(req_strip_cnt)
);

mpmc10_resp_strip_cnt urespsc1
(
	.clk(mem_ui_clk),
	.state(state),
	.valid(rd_data_valid_r),
	.num_strips(num_strips),
	.strip_cnt(resp_strip_cnt)
);

// Reservation status bit
mpmc10_resv_bit ursb1
(
	.clk(mem_ui_clk),
	.state(state),
	.wch(req_fifoo.cid),
	.we(req_fifoo.stb & req_fifoo.we),
	.cr(req_fifoo.csr & req_fifoo.we),
	.adr(req_fifoo.adr),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.rb(rb1)
);

mpmc10_addr_resv_man #(.NAR(NAR)) ursvm1
(
	.rst(mem_ui_rst),
	.clk(mem_ui_clk),
	.state(state),
	.adr0(32'h0),
	.adr1(ch1is.adr),
	.adr2(ch2is.adr),
	.adr3(ch3is.adr),
	.adr4(ch4is.adr),
	.adr5(32'h0),
	.adr6(ch6is.adr),
	.adr7(ch7is.adr),
	.sr0(1'b0),
	.sr1(ch1is.csr & ch1is.stb & ~ch1is.we),
	.sr2(ch2is.csr & ch2is.stb & ~ch2is.we),
	.sr3(ch3is.csr & ch3is.stb & ~ch3is.we),
	.sr4(ch4is.csr & ch4is.stb & ~ch4is.we),
	.sr5(1'b0),
	.sr6(ch6is.csr & ch6is.stb & ~ch6is.we),
	.sr7(ch7is.csr & ch7is.stb & ~ch7is.we),
	.wch(req_fifoo.stb ? req_fifoo.cid : 4'd15),
	.we(req_fifoo.stb & req_fifoo.we),
	.wadr(req_fifoo.adr),
	.cr(req_fifoo.csr & req_fifoo.stb & req_fifoo.we),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr)
);

endmodule
