`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2025  Robert Finch, Waterloo
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
//`define SUPPORT_AMO	1'b1
//`define SUPPORT_AMO_TETRA	1'b1
//`define SUPPORT_AMO_OCTA 1'b1
//`define SUPPORT_AMO_SHIFT	1'b1
//`define SUPPORT_AMO_MULTI_SHIFT	1'b1

import wb_bus_pkg::*;
import mpmc11_pkg::*;

module mpmc11_fta (
input rst,
input sys_clk_i,
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
output [mpmc11_pkg::WIDX8/8-1:0] app_wdf_mask,
output reg [mpmc11_pkg::WIDX8-1:0] app_wdf_data,
input app_wdf_rdy,
output app_wdf_wren,
output app_wdf_end,
input [mpmc11_pkg::WIDX8-1:0] app_rd_data,
input app_rd_data_end,
output reg app_ref_req,
input app_ref_ack,
wb_bus_interface.slave ch0,
wb_bus_interface.slave ch1,
wb_bus_interface.slave ch2,
wb_bus_interface.slave ch3,
wb_bus_interface.slave ch4,
wb_bus_interface.slave ch5,
wb_bus_interface.slave ch6,
wb_bus_interface.slave ch7,
input [7:0] fifo_rst,
//input wb_cmd_request256_t ch0i,
//output wb_cmd_response256_t ch0o,
output mpmc11_state_t state,
output rst_busy
);
parameter NAR = 2;			// Number of address reservations
parameter CL = 3'd4;		// Cache read latency
parameter PORT_PRESENT = 9'h181;
parameter REFRESH_BIT = 4'd0;
parameter CACHE = 9'h4C;
parameter STREAM = 8'h21;
parameter RMW = 8'h00;
parameter MDW = 256;

wire clk100 = sys_clk_i;
wb_cmd_request256_t [7:0] chi;

always_comb
begin
	chi[0] = 1000'd0;
	chi[0].blen = ch0.req.blen;
	chi[0].cmd = ch0.req.cmd;
	chi[0].cti = ch0.req.cti;
	chi[0].cyc = ch0.req.cyc;
	chi[0].stb = ch0.req.stb;
	chi[0].we = ch0.req.we;
	chi[0].sel = ch0.req.sel;
	chi[0].adr = ch0.req.adr;
	chi[0].data1 = ch0.req.data1;

	chi[1] = 1000'd0;
	chi[1].blen = ch1.req.blen;
	chi[1].cmd = ch1.req.cmd;
	chi[1].cyc = ch1.req.cyc;
	chi[1].stb = ch1.req.stb;
	chi[1].we = ch1.req.we;
	chi[1].sel = ch1.req.sel;
	chi[1].adr = ch1.req.adr;
	chi[1].data1 = ch1.req.data1;

	chi[2] = 1000'd0;
	chi[2].blen = ch2.req.blen;
	chi[2].cmd = ch2.req.cmd;
	chi[2].cyc = ch2.req.cyc;
	chi[2].stb = ch2.req.stb;
	chi[2].we = ch2.req.we;
	chi[2].sel = ch2.req.sel;
	chi[2].adr = ch2.req.adr;
	chi[2].data1 = ch2.req.data1;

	chi[3] = 1000'd0;
	chi[3].blen = ch3.req.blen;
	chi[3].cmd = ch3.req.cmd;
	chi[3].cyc = ch3.req.cyc;
	chi[3].stb = ch3.req.stb;
	chi[3].we = ch3.req.we;
	chi[3].sel = ch3.req.sel;
	chi[3].adr = ch3.req.adr;
	chi[3].data1 = ch3.req.data1;

	chi[4] = 1000'd0;
	chi[4].blen = ch4.req.blen;
	chi[4].cmd = ch4.req.cmd;
	chi[4].cyc = ch4.req.cyc;
	chi[4].stb = ch4.req.stb;
	chi[4].we = ch4.req.we;
	chi[4].sel = ch4.req.sel;
	chi[4].adr = ch4.req.adr;
	chi[4].data1 = ch4.req.data1;

	chi[5] = 1000'd0;
	chi[5].blen = ch5.req.blen;
	chi[5].cmd = ch5.req.cmd;
	chi[5].cti = ch5.req.cti;
	chi[5].cyc = ch5.req.cyc;
	chi[5].stb = ch5.req.stb;
	chi[5].we = ch5.req.we;
	chi[5].sel = ch5.req.sel;
	chi[5].adr = ch5.req.adr;
	chi[5].data1 = ch5.req.data1;

	chi[6] = 1000'd0;
	chi[6].blen = ch6.req.blen;
	chi[6].cmd = ch6.req.cmd;
	chi[6].cti = ch6.req.cti;
	chi[6].cyc = ch6.req.cyc;
	chi[6].stb = ch6.req.stb;
	chi[6].we = ch6.req.we;
	chi[6].sel = ch6.req.sel;
	chi[6].adr = ch6.req.adr;
	chi[6].data1 = ch6.req.data1;

	chi[7] = 1000'd0;
	chi[7].blen = ch7.req.blen;
	chi[7].cmd = ch7.req.cmd;
	chi[7].cti = ch7.req.cti;
	chi[7].cyc = ch7.req.cyc;
	chi[7].stb = ch7.req.stb;
	chi[7].we = ch7.req.we;
	chi[7].sel = ch7.req.sel;
	chi[7].adr = ch7.req.adr;
	chi[7].data1 = ch7.req.data1;
end

wb_cmd_request256_t ch0i2;
wb_cmd_request256_t ch1i2;
wb_cmd_request256_t ch2i2;
wb_cmd_request256_t ch3i2;
wb_cmd_request256_t ch4i2;
wb_cmd_request256_t ch5i2;
wb_cmd_request256_t ch6i2;
wb_cmd_request256_t ch7i2;

wb_cmd_response256_t ch0oa, ch0ob, ch0oc, ch0od;
wb_cmd_response256_t ch1oa, ch1ob, ch1oc, ch1od;
wb_cmd_response256_t ch2oa, ch2ob, ch2oc, ch2od;
wb_cmd_response256_t ch3oa, ch3ob, ch3oc, ch3od;
wb_cmd_response256_t ch4oa, ch4ob, ch4oc, ch4od;
wb_cmd_response256_t ch5oa, ch5ob, ch5oc, ch5od;
wb_cmd_response256_t ch6oa, ch6ob, ch6oc, ch6od;
wb_cmd_response256_t ch7oa, ch7ob, ch7oc, ch7od;
wb_cmd_response256_t ch8oa, ch8ob, ch8oc, ch8od;
wb_cmd_response256_t [8:0] chob;
always_comb ch0ob = chob[0];
always_comb ch1ob = chob[1];
always_comb ch2ob = chob[2];
always_comb ch3ob = chob[3];
always_comb ch4ob = chob[4];
always_comb ch5ob = chob[5];
always_comb ch6ob = chob[6];
always_comb ch7ob = chob[7];
always_comb ch8ob = chob[8];

wire [8:0] chclk;
assign chclk[0] = ch0.clk;
assign chclk[1] = ch1.clk;
assign chclk[2] = ch2.clk;
assign chclk[3] = ch3.clk;
assign chclk[4] = ch4.clk;
assign chclk[5] = ch5.clk;
assign chclk[6] = ch6.clk;
assign chclk[7] = ch7.clk;
assign chclk[8] = ch0.clk;

reg rmw0;
reg rmw1;
reg rmw2;
reg rmw3;
reg rmw4;
reg rmw5;
reg rmw6;
reg rmw7;

wire ch7cache = ch7.req.adr[31:30]==2'b10;

always_comb
begin
	if (STREAM[0]) begin
		ch0.resp.tid = ch0ob.tid;
		ch0.resp.adr = ch0ob.adr;
		ch0.resp.dat = ch0ob.dat;
		ch0.resp.ack = ch0ob.ack;
		ch0.resp.rty = 1'b0;
	end
	else if (rmw0) begin
		ch0.resp.tid = ch0oc.tid;
		ch0.resp.adr = ch0oc.adr;
		ch0.resp.dat = ch0oc.dat;
		ch0.resp.ack = ch0oc.ack;
		ch0.resp.rty = 1'b0;
	end
	else if (CACHE[0]) begin
		ch0.resp.tid = ch0oa.tid;
		ch0.resp.adr = ch0oa.adr;
		ch0.resp.dat = ch0oa.dat;
		ch0.resp.ack = ch0oa.ack;
		ch0.resp.rty = ch0oa.rty;
	end
	else begin
		ch0.resp.tid = ch0od.tid;
		ch0.resp.adr = ch0od.adr;
		ch0.resp.dat = ch0od.dat;
		ch0.resp.ack = ch0od.ack;
		ch0.resp.rty = 1'b0;
	end

	if (STREAM[1]) begin
		ch1.resp.tid = ch1ob.tid;
		ch1.resp.adr = ch1ob.adr;
		ch1.resp.dat = ch1ob.dat;
		ch1.resp.ack = ch1ob.ack;
	end
	else if (rmw1) begin
		ch1.resp.tid = ch1oc.tid;
		ch1.resp.adr = ch1oc.adr;
		ch1.resp.dat = ch1oc.dat;
		ch1.resp.ack = ch1oc.ack;
	end
	else if (CACHE[1]) begin
		ch1.resp.tid = ch1oa.tid;
		ch1.resp.adr = ch1oa.adr;
		ch1.resp.dat = ch1oa.dat;
		ch1.resp.ack = ch1oa.ack;
		ch1.resp.rty = ch1oa.rty;
	end
	else begin
		ch1.resp.tid = ch1od.tid;
		ch1.resp.adr = ch1od.adr;
		ch1.resp.dat = ch1od.dat;
		ch1.resp.ack = ch1od.ack;
	end

	if (STREAM[2]) begin
		ch2.resp.tid = ch2ob.tid;
		ch2.resp.adr = ch2ob.adr;
		ch2.resp.dat = ch2ob.dat;
		ch2.resp.ack = ch2ob.ack;
	end
	else if (rmw2) begin
		ch2.resp.tid = ch2oc.tid;
		ch2.resp.adr = ch2oc.adr;
		ch2.resp.dat = ch2oc.dat;
		ch2.resp.ack = ch2oc.ack;
	end
	else if (CACHE[2]) begin
		ch2.resp.tid = ch2oa.tid;
		ch2.resp.adr = ch2oa.adr;
		ch2.resp.dat = ch2oa.dat;
		ch2.resp.ack = ch2oa.ack;
	end
	else begin
		ch2.resp.tid = ch2od.tid;
		ch2.resp.adr = ch2od.adr;
		ch2.resp.dat = ch2od.dat;
		ch2.resp.ack = ch2od.ack;
	end

	if (STREAM[3]) begin
		ch3.resp.tid = ch3ob.tid;
		ch3.resp.adr = ch3ob.adr;
		ch3.resp.dat = ch3ob.dat;
		ch3.resp.ack = ch3ob.ack;
	end
	else if (rmw3) begin
		ch3.resp.tid = ch3oc.tid;
		ch3.resp.adr = ch3oc.adr;
		ch3.resp.dat = ch3oc.dat;
		ch3.resp.ack = ch3oc.ack;
	end
	else if (CACHE[3]) begin
		ch3.resp.tid = ch3oa.tid;
		ch3.resp.adr = ch3oa.adr;
		ch3.resp.dat = ch3oa.dat;
		ch3.resp.ack = ch3oa.ack;
	end
	else begin
		ch3.resp.tid = ch3od.tid;
		ch3.resp.adr = ch3od.adr;
		ch3.resp.dat = ch3od.dat;
		ch3.resp.ack = ch3od.ack;
	end

	if (STREAM[4]) begin
		ch4.resp.tid = ch4ob.tid;
		ch4.resp.adr = ch4ob.adr;
		ch4.resp.dat = ch4ob.dat;
		ch4.resp.ack = ch4ob.ack;
		ch4.resp.rty = 1'b0;
	end
	else if (rmw4) begin
		ch4.resp.tid = ch4oc.tid;
		ch4.resp.adr = ch4oc.adr;
		ch4.resp.dat = ch4oc.dat;
		ch4.resp.ack = ch4oc.ack;
		ch4.resp.rty = 1'b0;
	end
	else if (CACHE[4]) begin
		ch4.resp.tid = ch4oa.tid;
		ch4.resp.adr = ch4oa.adr;
		ch4.resp.dat = ch4oa.dat;
		ch4.resp.ack = ch4oa.ack;
		ch4.resp.rty = 1'b0;
	end
	else begin
		ch4.resp.tid = ch4od.tid;
		ch4.resp.adr = ch4od.adr;
		ch4.resp.dat = ch4od.dat;
		ch4.resp.ack = ch4od.ack;
		ch4.resp.rty = 1'b0;
	end

	if (STREAM[5]) begin
		ch5.resp.tid = ch5ob.tid;
		ch5.resp.adr = ch5ob.adr;
		ch5.resp.dat = ch5ob.dat;
		ch5.resp.ack = ch5ob.ack;
	end
	else if (rmw5) begin
		ch5.resp.tid = ch5oc.tid;
		ch5.resp.adr = ch5oc.adr;
		ch5.resp.dat = ch5oc.dat;
		ch5.resp.ack = ch5oc.ack;
	end
	else if (CACHE[5]) begin
		ch5.resp.tid = ch5oa.tid;
		ch5.resp.adr = ch5oa.adr;
		ch5.resp.dat = ch5oa.dat;
		ch5.resp.ack = ch5oa.ack;
	end
	else begin
		ch5.resp.tid = ch5od.tid;
		ch5.resp.adr = ch5od.adr;
		ch5.resp.dat = ch5od.dat;
		ch5.resp.ack = ch5od.ack;
	end

	if (STREAM[6]) begin
		ch6.resp.tid = ch6ob.tid;
		ch6.resp.adr = ch6ob.adr;
		ch6.resp.dat = ch6ob.dat;
		ch6.resp.ack = ch6ob.ack;
	end
	else if (rmw6) begin
		ch6.resp.tid = ch6oc.tid;
		ch6.resp.adr = ch6oc.adr;
		ch6.resp.dat = ch6oc.dat;
		ch6.resp.ack = ch6oc.ack;
	end
	else if (CACHE[6]) begin
		ch6.resp.tid = ch6oa.tid;
		ch6.resp.adr = ch6oa.adr;
		ch6.resp.dat = ch6oa.dat;
		ch6.resp.ack = ch6oa.ack;
	end
	else begin
		ch6.resp.tid = ch6od.tid;
		ch6.resp.adr = ch6od.adr;
		ch6.resp.dat = ch6od.dat;
		ch6.resp.ack = ch6od.ack;
	end

	if (STREAM[7]) begin
		ch7.resp.tid = ch7ob.tid;
		ch7.resp.adr = ch7ob.adr;
		ch7.resp.dat = ch7ob.dat;
		ch7.resp.ack = ch7ob.ack;
		ch7.resp.rty = 1'b0;
		ch7.resp.err = wb_bus_pkg::OKAY;
	end
	/*
	else if (rmw7) begin
		ch7.resp = 1000'd0;
		ch7.resp.tid = ch7oc.tid;
		ch7.resp.adr = ch7oc.adr;
		ch7.resp.dat = ch7oc.dat;
		ch7.resp.ack = ch7oc.ack;
	end
	*/
	else if (ch7cache) begin
		ch7.resp.tid = ch7oa.tid;
		ch7.resp.adr = ch7oa.adr;
		ch7.resp.dat = ch7oa.dat;
		ch7.resp.ack = ch7oa.ack;
		ch7.resp.rty = ch7oa.rty;
		ch7.resp.err = wb_bus_pkg::OKAY;
	end
	else begin
		ch7.resp.tid = ch7od.tid;
		ch7.resp.adr = ch7od.adr;
		ch7.resp.dat = ch7od.dat;
		ch7.resp.ack = ch7od.ack;
		ch7.resp.rty = 1'b0;
		ch7.resp.err = wb_bus_pkg::OKAY;
	end

end

mpmc11_fifoe_t [8:0] req_fifoi;
mpmc11_fifoe_t [8:0] req_fifog;
mpmc11_fifoe_t [8:0] req_fifoh;
mpmc11_fifoe_t req_fifoo;
wb_cmd_request256_t ld,miss;
wb_cmd_request256_t fifo_mask;
mpmc11_fifoe_t fifoo;

assign fifoo.req = req_fifoo.req;// & fifo_mask;
assign fifoo.port = req_fifoo.port;

genvar g;
integer n1,n2,n3;
reg v;
wire full;
wire [8:0] empty;
wire [8:0] almost_full;
wire almost_full0;
wire almost_full1;
wire almost_full2;
wire almost_full3;
wire almost_full4;
wire almost_full5;
wire almost_full6;
wire almost_full7;
wire almost_full8;
wire [4:0] cnt;
reg [8:0] rd_fifo;
reg [8:0] wr_fifo;
wire [8:0] rd_fifo_sm;
mpmc11_state_t prev_state;
reg [7:0] burst_len;	// from fifo
wire [7:0] req_burst_cnt;
wire [7:0] resp_burst_cnt;

wire [15:0] tocnt;
reg [31:0] adr;
reg [3:0] uport;		// update port
reg [mpmc11_pkg::WIDX8-1:0] dat128;
wire [mpmc11_pkg::WIDX8-1:0] dat256;
wire [3:0] resv_ch [0:NAR-1];
wire [31:0] resv_adr [0:NAR-1];
wire rb1;
reg [7:0] req;
reg [mpmc11_pkg::WIDX8-1:0] rd_data_r;
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

reg [9:0] rst_ctr;
reg irst;

// Refresh generation
reg [REFRESH_BIT:0] ref_cnt;
reg ref_req;
wire ref_ack;
generate begin : gRefresh
if (REFRESH_BIT > 0) begin
always_ff @(posedge sys_clk_i)
if (rst)
	ref_cnt <= {REFRESH_BIT+1{1'd0}};
else
	ref_cnt <= ref_cnt + 2'd1;
// Trigger a refresh request immediately after calib_complete.
always_ff @(posedge sys_clk_i)
if (rst|~calib_complete)
	ref_req <= 1'b0;
else begin
	if (~|ref_cnt[REFRESH_BIT:0])
		ref_req <= 1'b1;
	else if (ref_ack)
		ref_req <= 1'b0;
end
always_ff @(posedge mem_ui_clk)
if (rst)
	app_ref_req <= 1'b0;
else
	app_ref_req <= 1'b0;//ref_req;
end
else begin
	always_comb app_ref_req <= 1'b0;
	always_comb ref_req <= 1'b0;
end
end
endgenerate

wire rst_ext;
// Generate negative pulse for MIG controller reset.
pulse_extender upe10(.clk_i(sys_clk_i), .ce_i(1'b1), .cnt_i(4'd9), .i(rst), .o(), .no(rstn));
always_comb irst = rst||mem_ui_rst;

wire [7:0] pe_req;
reg [7:0] chack;
reg [15:0] hitt;
always_comb chack[0] = ch0.resp.ack;
always_comb chack[1] = ch1.resp.ack;
always_comb chack[2] = ch2.resp.ack;
always_comb chack[3] = ch3.resp.ack;
always_comb chack[4] = ch4.resp.ack;
always_comb chack[5] = ch5.resp.ack;
always_comb chack[6] = ch6.resp.ack;
always_comb chack[7] = ch7.resp.ack;
always_comb hitt[0] = hit0;
always_comb hitt[1] = hit1;
always_comb hitt[2] = hit2;
always_comb hitt[3] = hit3;
always_comb hitt[4] = hit4;
always_comb hitt[5] = hit5;
always_comb hitt[6] = hit6;
always_comb hitt[7] = hit7;
always_comb hitt[8] = 1'b0;
always_comb hitt[9] = 1'b0;
always_comb hitt[10] = 1'b0;
always_comb hitt[11] = 1'b0;
always_comb hitt[12] = 1'b0;
always_comb hitt[13] = 1'b0;
always_comb hitt[14] = 1'b0;
always_comb hitt[15] = 1'b0;

wire [3:0] req_sel;

// Streaming channels have a burst length of 64. Round the address to the burst
// length???
always_comb
begin
	ch0i2 <= ch0.req;
	ch0i2.adr <= {ch0.req.adr[31:5],5'b0};
end
always_comb
begin
	ch1i2 <= ch1.req;
	ch1i2.adr <= {ch1.req.adr[31:5],5'b0};
end
always_comb
begin
	ch2i2 <= ch2.req;
	ch2i2.adr <= {ch2.req.adr[31:5],5'b0};
end
always_comb
begin
	ch3i2 <= ch3.req;
	ch3i2.adr <= {ch3.req.adr[31:5],5'b0};
end
always_comb
begin
	ch4i2 <= ch4.req;
	ch4i2.adr <= {ch4.req.adr[31:5],5'b0};
end
always_comb
begin
	ch5i2 <= ch5.req;
	ch5i2.adr <= {ch5.req.adr[31:5],5'b0};
end
always_comb
begin
	ch6i2 <= ch6.req;
	ch6i2.adr <= {ch6.req.adr[31:5],5'b0};
end
always_comb
begin
	ch7i2 <= ch7.req;
	ch7i2.adr <= {ch7.req.adr[31:5],5'b0};
end

always_comb
begin
	ld = 1000'd0;
	ld.bte = wb_bus_pkg::LINEAR;
	ld.cti = wb_bus_pkg::CLASSIC;
	ld.cmd = wb_bus_pkg::CMD_LOAD;
	ld.blen = 6'd0;
	ld.cyc =  uport==4'd8 &&
						 fifoo.req.cyc &&
						 !fifoo.req.we &&
						 rd_data_valid_r
						 ;
	ld.we = 1'b0;
	ld.adr = fifoo.req.adr;//{app_waddr[31:5],5'h0};
	ld.data1 = rd_data_r;
	ld.sel = {32{1'b1}};		// update all bytes
end

reg ch0wack;
reg ch1wack;
reg ch2wack;
reg ch3wack;
reg ch4wack;
reg ch5wack;
reg ch6wack;
reg ch7wack;
reg [7:0] chw;

always_ff @(posedge sys_clk_i)
begin
	ch0wack <= 1'b0;
	ch1wack <= 1'b0;
	ch2wack <= 1'b0;
	ch3wack <= 1'b0;
	ch4wack <= 1'b0;
	ch5wack <= 1'b0;
	ch6wack <= 1'b0;
	ch7wack <= 1'b0;
	if (state==WRITE_DATA3)
		case(uport)
		4'd0:	ch0wack <= req_fifoo.req.cti==ERC;
		4'd1: ch1wack <= req_fifoo.req.cti==ERC;
		4'd2: ch2wack <= req_fifoo.req.cti==ERC;
		4'd3:	ch3wack <= req_fifoo.req.cti==ERC;
		4'd4:	ch4wack <= req_fifoo.req.cti==ERC;
		4'd5:	ch5wack <= req_fifoo.req.cti==ERC;
		4'd6:	ch6wack <= req_fifoo.req.cti==ERC;
		4'd7:	ch7wack <= req_fifoo.req.cti==ERC;
		default:	;
		endcase
end

always_ff @(posedge sys_clk_i)
begin
	chw[0] <= 1'b0;
	chw[1] <= 1'b0;
	chw[2] <= 1'b0;
	chw[3] <= 1'b0;
	chw[4] <= 1'b0;
	chw[5] <= 1'b0;
	chw[6] <= 1'b0;
	chw[7] <= 1'b0;
	if (state==WRITE_DATA3)
		chw[uport] <= req_fifoo.req.cti==ERC;
end

wb_bus_interface #(.DATA_WIDTH(256)) ch0_if();
wb_bus_interface #(.DATA_WIDTH(256)) ch1_if();
wb_bus_interface #(.DATA_WIDTH(256)) ch2_if();
wb_bus_interface #(.DATA_WIDTH(256)) ch3_if();
wb_bus_interface #(.DATA_WIDTH(256)) ch4_if();
wb_bus_interface #(.DATA_WIDTH(256)) ch5_if();
wb_bus_interface #(.DATA_WIDTH(256)) ch6_if();
wb_bus_interface #(.DATA_WIDTH(256)) ch7_if();

assign ch0_if.rst = STREAM[0] ? 1'b0 : ch0.rst;
assign ch1_if.rst = STREAM[1] ? 1'b0 : ch1.rst;
assign ch2_if.rst = STREAM[2] ? 1'b0 : ch2.rst;
assign ch3_if.rst = STREAM[3] ? 1'b0 : ch3.rst;
assign ch4_if.rst = STREAM[4] ? 1'b0 : ch4.rst;
assign ch5_if.rst = STREAM[5] ? 1'b0 : ch5.rst;
assign ch6_if.rst = STREAM[6] ? 1'b0 : ch6.rst;
assign ch7_if.rst = STREAM[7] ? 1'b0 : ch7.rst;
assign ch0_if.clk = STREAM[0] ? 1'b0 : CACHE[0] ? ch0.clk : 1'b0;
assign ch1_if.clk = STREAM[1] ? 1'b0 : CACHE[1] ? ch1.clk : 1'b0;
assign ch2_if.clk = STREAM[2] ? 1'b0 : CACHE[2] ? ch2.clk : 1'b0;
assign ch3_if.clk = STREAM[3] ? 1'b0 : CACHE[3] ? ch3.clk : 1'b0;
assign ch4_if.clk = STREAM[4] ? 1'b0 : CACHE[4] ? ch4.clk : 1'b0;
assign ch5_if.clk = STREAM[5] ? 1'b0 : CACHE[5] ? ch5.clk : 1'b0;
assign ch6_if.clk = STREAM[6] ? 1'b0 : CACHE[6] ? ch6.clk : 1'b0;
assign ch7_if.clk = STREAM[7] ? 1'b0 : CACHE[7]|ch7cache ? ch7.clk : 1'b0;

assign ch0_if.req = STREAM[0] ? 1000'd0 : CACHE[0] ? ch0.req : 1000'd0;
assign ch1_if.req = STREAM[1] ? 1000'd0 : CACHE[1] ? ch1.req : 1000'd0;
assign ch2_if.req = STREAM[2] ? 1000'd0 : CACHE[2] ? ch2.req : 1000'd0;
assign ch3_if.req = STREAM[3] ? 1000'd0 : CACHE[3] ? ch3.req : 1000'd0;
assign ch4_if.req = STREAM[4] ? 1000'd0 : CACHE[4] ? ch4.req : 1000'd0;
assign ch5_if.req = STREAM[5] ? 1000'd0 : CACHE[5] ? ch5.req : 1000'd0;
assign ch6_if.req = STREAM[6] ? 1000'd0 : CACHE[6] ? ch6.req : 1000'd0;
assign ch7_if.req = STREAM[7] ? 1000'd0 : CACHE[7]|ch7cache ? ch7.req : 1000'd0;

wire [8:0] ch_retry;
assign ch_retry[0] = ch0_if.resp.rty;
assign ch_retry[1] = ch1_if.resp.rty;
assign ch_retry[2] = ch2_if.resp.rty;
assign ch_retry[3] = ch3_if.resp.rty;
assign ch_retry[4] = ch4_if.resp.rty;
assign ch_retry[5] = ch5_if.resp.rty;
assign ch_retry[6] = ch6_if.resp.rty;
assign ch_retry[7] = ch7_if.resp.rty;
assign ch_retry[8] = 1'b0;

always_comb
begin
	ch0oa = 1000'd0;
	ch0oa.tid = ch0_if.resp.tid;
	ch0oa.adr = ch0_if.resp.adr;
	ch0oa.dat = ch0_if.resp.dat;
	ch0oa.ack = ch0_if.resp.ack;
	ch0oa.rty = ch0_if.resp.rty;
	ch1oa = 1000'd0;
	ch1oa.tid = ch1_if.resp.tid;
	ch1oa.adr = ch1_if.resp.adr;
	ch1oa.dat = ch1_if.resp.dat;
	ch1oa.ack = ch1_if.resp.ack;
	ch1oa.rty = ch1_if.resp.rty;
	ch2oa = 1000'd0;
	ch2oa.tid = ch2_if.resp.tid;
	ch2oa.adr = ch2_if.resp.adr;
	ch2oa.dat = ch2_if.resp.dat;
	ch2oa.ack = ch2_if.resp.ack;
	ch2oa.rty = ch2_if.resp.rty;
	ch3oa = 1000'd0;
	ch3oa.tid = ch3_if.resp.tid;
	ch3oa.adr = ch3_if.resp.adr;
	ch3oa.dat = ch3_if.resp.dat;
	ch3oa.ack = ch3_if.resp.ack;
	ch3oa.rty = ch3_if.resp.rty;
	ch4oa = 1000'd0;
	ch4oa.tid = ch4_if.resp.tid;
	ch4oa.adr = ch4_if.resp.adr;
	ch4oa.dat = ch4_if.resp.dat;
	ch4oa.ack = ch4_if.resp.ack;
	ch4oa.rty = ch4_if.resp.rty;
	ch5oa = 1000'd0;
	ch5oa.tid = ch5_if.resp.tid;
	ch5oa.adr = ch5_if.resp.adr;
	ch5oa.dat = ch5_if.resp.dat;
	ch5oa.ack = ch5_if.resp.ack;
	ch5oa.rty = ch5_if.resp.rty;
	ch6oa = 1000'd0;
	ch6oa.tid = ch6_if.resp.tid;
	ch6oa.adr = ch6_if.resp.adr;
	ch6oa.dat = ch6_if.resp.dat;
	ch6oa.ack = ch6_if.resp.ack;
	ch6oa.rty = ch6_if.resp.rty;
	ch7oa = 1000'd0;
	ch7oa.tid = ch7_if.resp.tid;
	ch7oa.adr = ch7_if.resp.adr;
	ch7oa.dat = ch7_if.resp.dat;
	ch7oa.ack = ch7_if.resp.ack;
	ch7oa.rty = ch7_if.resp.rty;
end

mpmc11_cache_fta #(.PORT_PRESENT(PORT_PRESENT|9'h100)) ucache1
(
	.rst(irst),
	.wclk(sys_clk_i),
	.inv(1'b0),
	.wchi(fifoo.req),
	.wcho(),
	.ld(ld),
	.to(tocnt[8]),
	.ch0(ch0_if),
	.ch1(ch1_if),
	.ch2(ch2_if),
	.ch3(ch3_if),
	.ch4(ch4_if),
	.ch5(ch5_if),
	.ch6(ch6_if),
	.ch7(ch7_if),
	.ch0wack(chw[0]),
	.ch1wack(chw[1]),
	.ch2wack(chw[2]),
	.ch3wack(chw[3]),
	.ch4wack(chw[4]),
	.ch5wack(chw[5]),
	.ch6wack(chw[6]),
	.ch7wack(chw[7]),
	.ch0hit(hit0),
	.ch1hit(hit1),
	.ch2hit(hit2),
	.ch3hit(hit3),
	.ch4hit(hit4),
	.ch5hit(hit5),
	.ch6hit(hit6),
	.ch7hit(hit7),
	.miss(miss)
);

// A burst request has also been sent to the fifo. It will be cancelled out
// when the state machine detects an already successful read of the streaming
// channel.

wire [7:0] src_wr;

generate begin : gStreamCache
for (g = 0; g < 8; g = g + 1) begin
if (PORT_PRESENT[g] & STREAM[g]) begin
	assign src_wr[g] = uport==g[3:0] && rd_data_valid_r;
mpmc11_strm_read_fifo ustrm
(
	.rst(irst|fifo_rst[g]),
	.wclk(mem_ui_clk),
	.wr(src_wr[g]),
	.wadr({app_waddr[31:5],5'h0}),	// only approximate
	.wdat(rd_data_r),
	.last_strip(resp_burst_cnt==burst_len),
	.rclk(chclk[g]),
	.resp(chob[g])
);
end else begin
	assign src_wr[g] = 1'b0;
	assign chob[g] = {$bits(wb_cmd_response256_t){1'b0}};
end
end
end
endgenerate

wire [8:0] sel;
reg [8:0] sel1;
wire [15:0] rd_rst_busy;
wire [15:0] wr_rst_busy;
reg [9:0] reqo;
wire [8:0] vg;
reg [3:0] req_sel1;
wire select_next;
reg [9:0] reqod;
always_ff @(posedge mem_ui_clk)
	reqod <= reqo;
always_comb reqo[9] = select_next & ~|reqod;

RoundRobinArbiter #(
  .NumRequests(10)
) urr1 (
	.rst(rst),
  .clk(sys_clk_i),
  .ce(select_next),
  .hold(1'b1),
  .req(reqo),
  .grant(sel),
  .grant_enc(req_sel)
);

always_comb
begin
	req_fifoi[0].port <= 4'd0;
	req_fifoi[1].port <= 4'd1;
	req_fifoi[2].port <= 4'd2;
	req_fifoi[3].port <= 4'd3;
	req_fifoi[4].port <= 4'd4;
	req_fifoi[5].port <= 4'd5;
	req_fifoi[6].port <= 4'd6;
	req_fifoi[7].port <= 4'd7;
	req_fifoi[8].port <= 4'd8;
	
	req_fifoi[0].req = 1000'd0;
	req_fifoi[0].req.tid = ch0.req.tid;
	req_fifoi[0].req.blen = ch0.req.blen;
	req_fifoi[0].req.cmd = ch0.req.cmd;
	req_fifoi[0].req.cyc = ch0.req.cyc;
	req_fifoi[0].req.we = ch0.req.we;
	req_fifoi[0].req.sel = ch0.req.sel;
	req_fifoi[0].req.adr = ch0.req.adr;
	req_fifoi[0].req.data1 = ch0.req.data1;

	req_fifoi[1].req = 1000'd0;
	req_fifoi[1].req.tid = ch1.req.tid;
	req_fifoi[1].req.blen = ch1.req.blen;
	req_fifoi[1].req.cmd = ch1.req.cmd;
	req_fifoi[1].req.cyc = ch1.req.cyc;
	req_fifoi[1].req.we = ch1.req.we;
	req_fifoi[1].req.sel = ch1.req.sel;
	req_fifoi[1].req.adr = ch1.req.adr;
	req_fifoi[1].req.data1 = ch1.req.data1;

	req_fifoi[2].req = 1000'd0;
	req_fifoi[2].req.tid = ch2.req.tid;
	req_fifoi[2].req.blen = ch2.req.blen;
	req_fifoi[2].req.cmd = ch2.req.cmd;
	req_fifoi[2].req.cyc = ch2.req.cyc;
	req_fifoi[2].req.we = ch2.req.we;
	req_fifoi[2].req.sel = ch2.req.sel;
	req_fifoi[2].req.adr = ch2.req.adr;
	req_fifoi[2].req.data1 = ch2.req.data1;

	req_fifoi[3].req = 1000'd0;
	req_fifoi[3].req.tid = ch3.req.tid;
	req_fifoi[3].req.blen = ch3.req.blen;
	req_fifoi[3].req.cmd = ch3.req.cmd;
	req_fifoi[3].req.cyc = ch3.req.cyc;
	req_fifoi[3].req.we = ch3.req.we;
	req_fifoi[3].req.sel = ch3.req.sel;
	req_fifoi[3].req.adr = ch3.req.adr;
	req_fifoi[3].req.data1 = ch3.req.data1;

	req_fifoi[4].req = 1000'd0;
	req_fifoi[4].req.tid = ch4.req.tid;
	req_fifoi[4].req.blen = ch4.req.blen;
	req_fifoi[4].req.cmd = ch4.req.cmd;
	req_fifoi[4].req.cyc = ch4.req.cyc;
	req_fifoi[4].req.we = ch4.req.we;
	req_fifoi[4].req.sel = ch4.req.sel;
	req_fifoi[4].req.adr = ch4.req.adr;
	req_fifoi[4].req.data1 = ch4.req.data1;

	req_fifoi[5].req = 1000'd0;
	req_fifoi[5].req.tid = ch5.req.tid;
	req_fifoi[5].req.blen = ch5.req.blen;
	req_fifoi[5].req.cmd = ch5.req.cmd;
	req_fifoi[5].req.cyc = ch5.req.cyc;
	req_fifoi[5].req.we = ch5.req.we;
	req_fifoi[5].req.sel = ch5.req.sel;
	req_fifoi[5].req.adr = ch5.req.adr;
	req_fifoi[5].req.data1 = ch5.req.data1;

	req_fifoi[6].req = 1000'd0;
	req_fifoi[6].req.tid = ch6.req.tid;
	req_fifoi[6].req.blen = ch6.req.blen;
	req_fifoi[6].req.cmd = ch6.req.cmd;
	req_fifoi[6].req.cyc = ch6.req.cyc;
	req_fifoi[6].req.we = ch6.req.we;
	req_fifoi[6].req.sel = ch6.req.sel;
	req_fifoi[6].req.adr = ch6.req.adr;
	req_fifoi[6].req.data1 = ch6.req.data1;

	req_fifoi[7].req = 1000'd0;
	req_fifoi[7].req.tid = ch7.req.tid;
	req_fifoi[7].req.blen = ch7.req.blen;
	req_fifoi[7].req.cmd = ch7.req.cmd;
	req_fifoi[7].req.cyc = ch7.req.cyc;
	req_fifoi[7].req.we = ch7.req.we;
	req_fifoi[7].req.sel = ch7.req.sel;
	req_fifoi[7].req.adr = ch7.req.adr;
	req_fifoi[7].req.data1 = ch7.req.data1;

	req_fifoi[8].req = 1000'd0;
	req_fifoi[8].req.tid = miss.tid;
	req_fifoi[8].req.blen = miss.blen;
	req_fifoi[8].req.cmd = miss.cmd;
	req_fifoi[8].req.cyc = miss.cyc;
	req_fifoi[8].req.we = miss.we;
	req_fifoi[8].req.sel = miss.sel;
	req_fifoi[8].req.adr = miss.adr;
	req_fifoi[8].req.data1 = miss.data1;
end

// An asynchronous fifo is used at the input to allow the clock to be different
// than the ui_clk.

wire [8:0] cd_fifo;
reg [8:0] lcd_fifo;					// latched change detect
reg [8:0] rd_fifo_r;
always_ff @(posedge sys_clk_i)
	if (state==mpmc11_pkg::IDLE)
		req_sel1 <= req_sel;
generate begin : gInputFifos
for (g = 0; g < 9; g = g + 1) begin
always_comb
	reqo[g] = !empty[g];//req_fifog[g].req.cyc;
always_comb wr_fifo[g] = req_fifoi[g].req.cyc && (!(CACHE[g]||(g==4'd7 &&
  req_fifoi[g].req.adr[31:30]==2'b10))||req_fifoi[g].req.we);
always_comb
	rd_fifo[g] = sel[g] && rd_fifo_sm[g] && !rd_fifo_r[g] && state==mpmc11_pkg::IDLE;
always_ff @(posedge sys_clk_i)
	if (rd_fifo[g])
		rd_fifo_r[g] <= 1'b1;
	else if (state==mpmc11_pkg::PRESET1 && g[3:0]==req_sel1[3:0])
		rd_fifo_r[g] <= 1'b0;

if (((PORT_PRESENT >> g) & 1'b1) || g[3:0]==4'd8)
begin
	mpmc11_asfifo_fta ufifo
	(
		.rst(mem_ui_rst),
		.rd_clk(sys_clk_i),
		.rd_fifo(rd_fifo[g]),
		.wr_clk(chclk[g]),
		.wr_fifo(wr_fifo[g]),
		.rty(ch_retry[g]),
		.req_fifoi(req_fifoi[g]),
		.req_fifoo(req_fifog[g]),
		.ocd(cd_fifo[g]),
		.full(),
		.empty(empty[g]),
		.almost_full(),
		.prog_full(almost_full[g]),
		.rd_rst_busy(rd_rst_busy[g]),
		.wr_rst_busy(wr_rst_busy[g]),
		.cnt()
	);
	
	always_comb
	case(g)
	0:	ch0.resp.stall = almost_full[g]|wr_rst_busy[g];
	1:	ch1.resp.stall = almost_full[g]|wr_rst_busy[g];
	2:	ch2.resp.stall = almost_full[g]|wr_rst_busy[g];
	3:	ch3.resp.stall = almost_full[g]|wr_rst_busy[g];
	4:	ch4.resp.stall = almost_full[g]|wr_rst_busy[g];
	5:	ch5.resp.stall = almost_full[g]|wr_rst_busy[g];
	6:	ch6.resp.stall = almost_full[g]|wr_rst_busy[g];
	7:	ch7.resp.stall = almost_full[g]|wr_rst_busy[g];
	endcase
	
	// Make the change detect sticky until state machine reaches PRESET1.
	always_ff @(posedge sys_clk_i)
	if (mem_ui_rst)
		lcd_fifo[g] <= 1'b0;
	else begin
		if (cd_fifo[g])
			lcd_fifo[g] <= req_fifog[g].req.cyc;
		else if (state==mpmc11_pkg::PRESET1 && g[3:0]==req_sel1[3:0])
			lcd_fifo[g] <= 1'b0;
	end
	always_ff @(posedge sys_clk_i)
	if (state==mpmc11_pkg::IDLE)
		req_fifoh[g] <= req_fifog[g];

end 
else begin

	always_comb
	case(g)
	0:	ch0.resp.stall = almost_full[g];
	1:	ch1.resp.stall = almost_full[g];
	2:	ch2.resp.stall = almost_full[g];
	3:	ch3.resp.stall = almost_full[g];
	4:	ch4.resp.stall = almost_full[g];
	5:	ch5.resp.stall = almost_full[g];
	6:	ch6.resp.stall = almost_full[g];
	7:	ch7.resp.stall = almost_full[g];
	endcase

	assign req_fifog[g] = {$bits(mpmc11_fifoe_t){1'b0}};
	assign req_fifoh[g] = {$bits(mpmc11_fifoe_t){1'b0}};
	assign reqo[g] = 1'b0;
	assign rd_rst_busy[g] = 1'b0;
	assign wr_rst_busy[g] = 1'b0;
	assign vg[g] = 1'b0;
	assign empty[g] = 1'b1;
	assign almost_full[g] = 1'b0;
	assign cd_fifo[g] = 1'b0;
	assign lcd_fifo[g] = 1'b0;
end
end
assign rd_rst_busy[9] = 1'b0;
assign rd_rst_busy[10] = 1'b0;
assign rd_rst_busy[11] = 1'b0;
assign rd_rst_busy[12] = 1'b0;
assign rd_rst_busy[13] = 1'b0;
assign rd_rst_busy[14] = 1'b0;
assign rd_rst_busy[15] = 1'b0;
assign wr_rst_busy[9] = 1'b0;
assign wr_rst_busy[10] = 1'b0;
assign wr_rst_busy[11] = 1'b0;
assign wr_rst_busy[12] = 1'b0;
assign wr_rst_busy[13] = 1'b0;
assign wr_rst_busy[14] = 1'b0;
assign wr_rst_busy[15] = 1'b0;
end
endgenerate

assign rst_busy = (|rd_rst_busy) || (|wr_rst_busy) || irst;

always_ff @(posedge sys_clk_i)
if (state==mpmc11_pkg::WRITE_DATA0 || state==mpmc11_pkg::READ_DATA0)
	v <= 1'b0;
else if (req_sel < 4'd9 && state==mpmc11_pkg::IDLE)
	v <= lcd_fifo[req_sel];
else
	v <= 1'b0;
always_ff @(posedge sys_clk_i)
if (req_sel < 4'd9 && state==mpmc11_pkg::IDLE)
	req_fifoo <= req_fifoh[req_sel];
always_comb
	uport = fifoo.port;
always_comb
	burst_len = fifoo.req.blen;
always_comb
	adr = fifoo.req.adr;

wire [1:0] app_addr3;	// dummy to make up 32-bits

mpmc11_addr_gen uag1
(
	.rst(irst),
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.wdf_rdy(app_wdf_rdy),
	.burst_len(burst_len),
	.burst_cnt(req_burst_cnt),
	.addr_base(adr),
	.addr({app_addr3,app_addr})
);

mpmc11_waddr_gen uwag1
(
	.rst(irst),
	.clk(mem_ui_clk),
	.state(state),
	.valid(rd_data_valid_r),
	.burst_len(burst_len),
	.burst_cnt(resp_burst_cnt),
	.addr_base(adr),
	.addr(app_waddr)
);

mpmc11_mask_select #(.WID(WIDX8)) unsks1
(
	.rst(irst),
	.clk(sys_clk_i),
	.state(state),
	.we(req_fifoo.req.we), 
	.wmask(req_fifoo.req.sel),
	.mask(app_wdf_mask)
);

wire [WIDX8-1:0] data128a;
wire [WIDX8-1:0] data128b;

mpmc11_data_select #(.WID(WIDX8)) uds1
(
	.clk(sys_clk_i),
	.state(state),
	.dati1(req_fifoo.req.data1),
	.dati2(req_fifoo.req.data2),
	.dato1(data128a),
	.dato2(data128b)
);

reg rmw;
reg rmw_hit;
reg rmw_ack;
reg [mpmc11_pkg::WIDX8-1:0] opa, opa1, opb, opc, t1;
reg [mpmc11_pkg::WIDX8-1:0] rmw_dat;
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
always_ff @(posedge sys_clk_i)
	opb <= data128a >> {req_fifoo.req.padr[4:0],3'b0};
always_ff @(posedge sys_clk_i)
	opc <= data128b >> {req_fifoo.req.padr[4:0],3'b0};
always_ff @(posedge sys_clk_i)
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
always_ff @(posedge sys_clk_i)
	opa <= opa1 >> {req_fifoo.req.padr[4:0],3'b0};
always_ff @(posedge sys_clk_i)
case(req_fifoo.req.sz)
`ifdef SUPPORT_AMO_TETRA
wb_bus_pkg::tetra:
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
wb_bus_pkg::octa:
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
	wb_bus_pkg::CMD_ADD:	t1 <= opa[127:0] + opb[127:0];
	wb_bus_pkg::CMD_AND:	t1 <= opa[127:0] & opb[127:0];
	wb_bus_pkg::CMD_OR:		t1 <= opa[127:0] | opb[127:0];
	wb_bus_pkg::CMD_EOR:	t1 <= opa[127:0] ^ opb[127:0];
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
	wb_bus_pkg::CMD_MINU:	t1 <= opa[127:0] < opb[127:0] ? opa[127:0] : opb[127:0];
	wb_bus_pkg::CMD_MAXU:	t1 <= opa[127:0] > opb[127:0] ? opa[127:0] : opb[127:0];
	wb_bus_pkg::CMD_MIN:	t1 <= $signed(opa[127:0]) < $signed(opb[127:0]) ? opa[127:0] : opb[127:0];
	wb_bus_pkg::CMD_MAX:	t1 <= $signed(opa[127:0]) > $signed(opb[127:0]) ? opa[127:0] : opb[127:0];
	wb_bus_pkg::CMD_CAS:	t1 <= opa[127:0]==opb[127:0] ? opc[127:0] : opb[127:0];
	default:	t1 <= opa[127:0];
	endcase
endcase
always_ff @(posedge sys_clk_i)
	rmw_dat <= t1 << {req_fifoo.req.adr[4:0],3'b0};

always_ff @(posedge sys_clk_i)
if (irst) begin
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
always_ff @(posedge sys_clk_i)
if (irst)
	rmw_ack <= 1'b0;
else begin
	if (state==WRITE_TRAMP1)
		rmw_ack <= 1'b1;
	else if (state==mpmc11_pkg::IDLE)
		rmw_ack <= 1'b0;
end
always_comb rmw0 = fifoo.req.cmd[4] & rmw && req_fifoo.port==4'd0;
always_comb rmw1 = fifoo.req.cmd[4] & rmw && req_fifoo.port==4'd1;
always_comb rmw2 = fifoo.req.cmd[4] & rmw && req_fifoo.port==4'd2;
always_comb rmw3 = fifoo.req.cmd[4] & rmw && req_fifoo.port==4'd3;
always_comb rmw4 = fifoo.req.cmd[4] & rmw && req_fifoo.port==4'd4;
always_comb rmw5 = fifoo.req.cmd[4] & rmw && req_fifoo.port==4'd5;
always_comb rmw6 = fifoo.req.cmd[4] & rmw && req_fifoo.port==4'd6;
always_comb rmw7 = fifoo.req.cmd[4] & rmw && req_fifoo.port==4'd7;
always_comb	ch0oc.ack = rmw_ack & rmw0;
always_comb	ch1oc.ack = rmw_ack & rmw1;
always_comb	ch2oc.ack = rmw_ack & rmw2;
always_comb	ch3oc.ack = rmw_ack & rmw3;
always_comb	ch4oc.ack = rmw_ack & rmw4;
always_comb	ch5oc.ack = rmw_ack & rmw5;
always_comb	ch6oc.ack = rmw_ack & rmw6;
always_comb	ch7oc.ack = rmw_ack & rmw7;
`endif

// Direct accesses to DDRAM.
// Non-stream, non-cached
wb_bus_pkg::wb_tranid_t [8:0] chod_tid;
wire [31:0] chod_adr [0:8];
wire [8:0] chod_ack;
wire [MDW-1:0] chod_dat [0:8];
wire [8:0] ch_clk;
assign ch_clk[0] = ch0.clk;
assign ch_clk[1] = ch1.clk;
assign ch_clk[2] = ch2.clk;
assign ch_clk[3] = ch3.clk;
assign ch_clk[4] = ch4.clk;
assign ch_clk[5] = ch5.clk;
assign ch_clk[6] = ch6.clk;
assign ch_clk[7] = ch7.clk;
assign ch_clk[8] = ch0.clk;
generate begin : gPortDataAck
	for (g = 0; g < 9; g = g + 1)
		if (PORT_PRESENT[g] && !STREAM[g] && !CACHE[g]) begin
mpmc11_od_tid_latch uodtl (.rst(irst), .clk(mem_ui_clk), .pclk(ch_clk[g]), .port(g[3:0]),
	.req(req_fifoo), .rdy(rd_data_valid_r), .tid(chod_tid[g]));
	
mpmc11_od_addr_latch uodal (.rst(irst), .clk(mem_ui_clk), .pclk(ch_clk[g]), .port(g[3:0]),
	.req(req_fifoo), .rdy(rd_data_valid_r), .addr(chod_adr[g]));
	
mpmc11_od_data_latch #(.MDW(MDW)) uoddl (.rst(irst), .clk(mem_ui_clk), .pclk(ch_clk[g]), .port(g[3:0]),
	.fifo_port(req_fifoo.port), .rdy(rd_data_valid_r), .rd_data(rd_data_r), .port_data(chod_dat[g]));

// Writes will not generate an ack because rd_data_valid_r is valid only for
// reads.
mpmc11_od_ack uodack (.rst(irst), .clk(mem_ui_clk), .pclk(ch_clk[g]), .port(g[3:0]),
	.fifo_port(req_fifoo.port), .rdy(rd_data_valid_r), .port_ack(chod_ack[g]));
	end	
	else begin
assign chod_tid[g] = 13'd0;
assign chod_adr[g] = 32'd0;
assign chod_dat[g] = 256'd0;
assign chod_ack[g] = 1'b0;
	end
end
endgenerate
assign ch0od.tid = chod_tid[0];
assign ch1od.tid = chod_tid[1];
assign ch2od.tid = chod_tid[2];
assign ch3od.tid = chod_tid[3];
assign ch4od.tid = chod_tid[4];
assign ch5od.tid = chod_tid[5];
assign ch6od.tid = chod_tid[6];
assign ch7od.tid = chod_tid[7];
assign ch8od.tid = chod_tid[8];
assign ch0od.adr = chod_adr[0];
assign ch1od.adr = chod_adr[1];
assign ch2od.adr = chod_adr[2];
assign ch3od.adr = chod_adr[3];
assign ch4od.adr = chod_adr[4];
assign ch5od.adr = chod_adr[5];
assign ch6od.adr = chod_adr[6];
assign ch7od.adr = chod_adr[7];
assign ch8od.adr = chod_adr[8];
assign ch0od.dat = chod_dat[0];
assign ch1od.dat = chod_dat[1];
assign ch2od.dat = chod_dat[2];
assign ch3od.dat = chod_dat[3];
assign ch4od.dat = chod_dat[4];
assign ch5od.dat = chod_dat[5];
assign ch6od.dat = chod_dat[6];
assign ch7od.dat = chod_dat[7];
assign ch8od.dat = chod_dat[8];
assign ch0od.ack = chod_ack[0];
assign ch1od.ack = chod_ack[1];
assign ch2od.ack = chod_ack[2];
assign ch3od.ack = chod_ack[3];
assign ch4od.ack = chod_ack[4];
assign ch5od.ack = chod_ack[5];
assign ch6od.ack = chod_ack[6];
assign ch7od.ack = chod_ack[7];
assign ch8od.ack = chod_ack[8];

// Setting the data value. Unlike reads there is only a single strip involved.
// Force unselected byte lanes to $FF.???? Why?
reg [WIDX8-1:0] dat128x;
generate begin
	for (g = 0; g < WIDX8/8; g = g + 1)
		always_comb
//			if (app_wdf_mask[g])
//				dat128x[g*8+7:g*8] = 8'hFF;
//			else
				dat128x[g*8+7:g*8] = data128a[g*8+7:g*8];
end
endgenerate

always_ff @(posedge sys_clk_i)
if (irst)
  app_wdf_data <= 256'd0;
else begin
	if (state==mpmc11_pkg::PRESET3)
		app_wdf_data <= data128a;
	else if (state==mpmc11_pkg::WRITE_TRAMP1)
		app_wdf_data <= rmw_dat;
end

mpmc11_rd_fifo_gen urdf1
(
	.rst(irst),
	.clk(sys_clk_i),
	.state(state),
	.empty(9'h00), //empty),
	.rd_rst_busy(rd_rst_busy),
	.calib_complete(calib_complete),
	.rd(rd_fifo_sm)
);

always_ff @(posedge sys_clk_i)
if (rst)
	fifo_mask <= {$bits(fifo_mask){1'b1}};
else begin
	if (rd_fifo)
		fifo_mask <= {$bits(fifo_mask){1'b1}};
	else if (state==mpmc11_pkg::IDLE)
		fifo_mask <= {$bits(fifo_mask){1'b0}};
end

mpmc11_state_machine_fta usm1
(
	.rst(irst),
	.clk(sys_clk_i),
	.calib_complete(calib_complete),
	.ref_req(ref_req),
	.ref_ack(ref_ack),
	.app_ref_ack(app_ref_ack),
	.to(tocnt[8]),
	.rdy(app_rdy),
	.wdf_rdy(app_wdf_rdy),
	.fifo_v(v),
	.rst_busy((rd_rst_busy[req_sel]) || (wr_rst_busy[req_sel])),
	.fifo_out(req_fifoo.req),
	.state(state),
	.burst_len(burst_len),
	.req_burst_cnt(req_burst_cnt),
	.resp_burst_cnt(resp_burst_cnt),
	.rmw_hit(rmw_hit),
	.select_next(select_next)
);

mpmc11_to_cnt utoc1
(
	.clk(sys_clk_i),
	.state(state),
	.prev_state(prev_state),
	.to_cnt(tocnt)
);

mpmc11_prev_state upst1
(
	.clk(sys_clk_i),
	.state(state),
	.prev_state(prev_state)
);

mpmc11_app_en_gen ueng1
(
	.rst(irst),
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.wdf_rdy(app_wdf_rdy),
	.burst_cnt(req_burst_cnt),
	.burst_len(burst_len),
	.en(app_en)
);

mpmc11_app_cmd_gen ucg1
(
	.rst(irst),
	.clk(sys_clk_i),
	.state(state),
	.wr(req_fifoo.req.cyc & req_fifoo.req.we),
	.cmd(app_cmd)
);

mpmc11_app_wdf_wren_gen uwreng1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.wdf_rdy(app_wdf_rdy),
	.wren(app_wdf_wren)
);

mpmc11_app_wdf_end_gen uwendg1
(
	.clk(mem_ui_clk),
	.state(state),
	.rdy(app_rdy),
	.wdf_rdy(app_wdf_rdy),
	.burst_cnt(req_burst_cnt),
	.burst_len(burst_len),
	.wend(app_wdf_end)
);

mpmc11_req_burst_cnt ursc1
(
	.clk(mem_ui_clk),
	.state(state),
	.wdf_rdy(app_wdf_rdy),
	.rdy(app_rdy),
	.burst_len(burst_len),
	.burst_cnt(req_burst_cnt)
);

mpmc11_resp_burst_cnt urespsc1
(
	.clk(mem_ui_clk),
	.state(state),
	.valid(rd_data_valid_r),
	.burst_len(burst_len),
	.burst_cnt(resp_burst_cnt)
);

// Reservation status bit
mpmc11_resv_bit ursb1
(
	.clk(sys_clk_i),
	.state(state),
	.wch(fifoo.port),
	.we(fifoo.req.cyc & fifoo.req.we),
	.cr(fifoo.req.csr & fifoo.req.we),
	.adr(fifoo.req.adr),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr),
	.rb(rb1)
);

mpmc11_addr_resv_man #(.NAR(NAR)) ursvm1
(
	.rst(irst),
	.clk(sys_clk_i),
	.state(state),
	.adr0(32'h0),
	.adr1(ch1.req.adr),
	.adr2(ch2.req.adr),
	.adr3(ch3.req.adr),
	.adr4(ch4.req.adr),
	.adr5(32'h0),
	.adr6(ch6.req.adr),
	.adr7(ch7.req.adr),
	.sr0(1'b0),
	.sr1(ch1.req.csr & ch1.req.cyc & ~ch1.req.we),
	.sr2(ch2.req.csr & ch2.req.cyc & ~ch2.req.we),
	.sr3(ch3.req.csr & ch3.req.cyc & ~ch3.req.we),
	.sr4(ch4.req.csr & ch4.req.cyc & ~ch4.req.we),
	.sr5(1'b0),
	.sr6(ch6.req.csr & ch6.req.cyc & ~ch6.req.we),
	.sr7(ch7.req.csr & ch7.req.cyc & ~ch7.req.we),
	.wch(fifoo.req.cyc ? fifoo.port : 4'd15),
	.we(fifoo.req.cyc & fifoo.req.we),
	.wadr(fifoo.req.adr),
	.cr(fifoo.req.csr & fifoo.req.cyc & fifoo.req.we),
	.resv_ch(resv_ch),
	.resv_adr(resv_adr)
);

endmodule
