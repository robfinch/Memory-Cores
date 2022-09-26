`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
// ============================================================================
//
//`define CH45	1'b1

module mpmc6(
rst_i, clk100MHz, clk200MHz, clk,
mem_ui_clk,
cyc0, stb0, ack0, we0, sel0, adr0, dati0, dato0,
cs1, cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1, sr1, cr1, rb1,
cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
`ifdef CH45
cyc4, stb4, ack4, we4, sel4, adr4, dati4, dato4,
cyc5, stb5, ack5, adr5, dato5,
`endif
cyc6, stb6, ack6, we6, sel6, adr6, dati6, dato6,
cs7, cyc7, stb7, ack7, we7, sel7, adr7, dati7, dato7, sr7, cr7, rb7,
ddr3_dq, ddr3_dqs_n, ddr3_dqs_p,
ddr3_addr, ddr3_ba, ddr3_ras_n, ddr3_cas_n, ddr3_we_n,
ddr3_ck_p, ddr3_ck_n, ddr3_cke, ddr3_reset_n, ddr3_dm, ddr3_odt,
ch, state
);
parameter SIM= "FALSE";
parameter SIM_BYPASS_INIT_CAL = "OFF";
parameter AMSB = 28;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter CMD_READ = 3'b001;
parameter CMD_WRITE = 3'b000;
// State machine states
parameter IDLE = 4'd0;
parameter PRESET = 4'd1;
parameter SEND_DATA = 4'd2;
parameter SET_CMD_RD = 4'd3;
parameter SET_CMD_WR = 4'd4;
parameter WAIT_NACK = 4'd5;
parameter WAIT_RD = 4'd6;


input rst_i;
input clk100MHz;
input clk200MHz;
input clk;
output mem_ui_clk;

// Channel 0 is reserved for bitmapped graphics display / sprites.
//
input cyc0;
input stb0;
output ack0;
input [15:0] sel0;
input we0;
input [31:0] adr0;
input [127:0] dati0;
output reg [127:0] dato0;
reg [127:0] dato0n;

// Channel 1 is reserved for cpu1
input cs1;
input cyc1;
input stb1;
output ack1;
input we1;
input [15:0] sel1;
input [31:0] adr1;
input [127:0] dati1;
output reg [127:0] dato1;
input sr1;
input cr1;
output reg rb1;

// Channel 2 is reserved for the ethernet controller
input cyc2;
input stb2;
output ack2;
input we2;
input [3:0] sel2;
input [31:0] adr2;
input [31:0] dati2;
output reg [31:0] dato2;

// Channel 3 is reserved for the graphics controller
input cyc3;
input stb3;
output ack3;
input we3;
input [15:0] sel3;
input [31:0] adr3;
input [127:0] dati3;
output reg [127:0] dato3;
`ifdef CH45
// Channel 4 is reserved for the graphics controller
input cyc4;
input stb4;
output ack4;
input we4;
input [15:0] sel4;
input [31:0] adr4;
input [127:0] dati4;
output reg [127:0] dato4;

// Channel 5 is reserved for sprite DMA, which is read-only
input cyc5;
input stb5;
output ack5;
input [31:0] adr5;
output reg [127:0] dato5;
`endif
// Channel 6 is reserved for the SD/MMC controller
input cyc6;
input stb6;
output ack6;
input we6;
input [3:0] sel6;
input [31:0] adr6;
input [31:0] dati6;
output reg [31:0] dato6;

// Channel 7 is reserved for the cpu
input cs7;
input cyc7;
input stb7;
output ack7;
input we7;
input [15:0] sel7;
input [31:0] adr7;
input [127:0] dati7;
output reg [127:0] dato7;
input sr7;
input cr7;
output reg rb7;

inout [15:0] ddr3_dq;
inout [1:0] ddr3_dqs_p;
inout [1:0] ddr3_dqs_n;
output [13:0] ddr3_addr;
output [2:0] ddr3_ba;
output ddr3_ras_n;
output ddr3_cas_n;
output ddr3_we_n;
output ddr3_ck_p;
output ddr3_ck_n;
output ddr3_cke;
output ddr3_reset_n;
output [1:0] ddr3_dm;
output ddr3_odt;

output reg [2:0] ch;
output reg [3:0] state;

reg [7:0] sel;
reg [31:0] adr;
reg [63:0] dato;
reg [63:0] dati;
reg [127:0] dat128;
reg [15:0] wmask;

reg [3:0] state;
reg [3:0] nch;
reg [2:0] ch;
reg do_wr;
reg [1:0] sreg;
reg rstn;
reg fast_read0, fast_read1, fast_read2, fast_read3;
reg fast_read4, fast_read5, fast_read6, fast_read7;
reg read0,read1,read2,read3;
reg read4,read5,read6,read7;

wire cs0 = cyc0 && stb0 && adr0[31:29]==3'h0;
wire ics1 = cyc1 & stb1 & cs1;
wire cs2 = cyc2 && stb2 && adr2[31:29]==3'h0;
wire cs3 = cyc3 && stb3 && adr3[31:29]==3'h0;
`ifdef CH45
wire cs4 = cyc4 && stb4 && adr4[31:29]==3'h0;
wire cs5 = cyc5 && stb5 && adr5[31:29]==3'h0;
`endif
wire cs6 = cyc6 && stb6 && adr6[31:29]==3'h0;
wire ics7 = cyc7 & stb7 & cs7;

reg acki0,acki1,acki2,acki3,acki4,acki5,acki6,acki7;

// Record of the last read address for each channel.
// Cache address tag
reg [31:0] ch0_addr;
reg [31:0] ch1_addr;
reg [31:0] ch2_addr;
reg [31:0] ch3_addr;
reg [31:0] ch4_addr;
reg [31:0] ch5_addr;
reg [31:0] ch6_addr;
reg [31:0] ch7_addr;

// Read data caches
reg [127:0] ch0_rd_data [0:3];
reg [127:0] ch1_rd_data [0:1];
reg [127:0] ch2_rd_data;
reg [127:0] ch3_rd_data;
reg [127:0] ch4_rd_data;
reg [127:0] ch5_rd_data [0:3];
reg [127:0] ch6_rd_data;
reg [127:0] ch7_rd_data [0:1];

reg [1:0] num_strips;
reg [1:0] strip_cnt;
reg [1:0] strip_cnt2;
reg [AMSB:0] mem_addr;
reg [AMSB:0] mem_addr0;
reg [AMSB:0] mem_addr1;
reg [AMSB:0] mem_addr2;
reg [AMSB:0] mem_addr3;
reg [AMSB:0] mem_addr4;
reg [AMSB:0] mem_addr5;
reg [AMSB:0] mem_addr6;
reg [AMSB:0] mem_addr7;
wire [2:0] mem_cmd;
wire mem_en;
reg [127:0] mem_wdf_data;
reg [15:0] mem_wdf_mask;
wire mem_wdf_end;
wire mem_wdf_wren;

wire [127:0] mem_rd_data;
wire mem_rd_data_end;
wire mem_rd_data_valid;
wire mem_rdy;
wire mem_wdf_rdy;
wire mem_ui_clk;
wire mem_ui_rst;
wire calib_complete;
reg [15:0] refcnt;
reg refreq;
wire refack;
reg [15:0] tocnt;					// memory access timeout counter

reg [3:0] resv_ch0,resv_ch1;
reg [31:0] resv_adr0,resv_adr1;

reg [7:0] match;
always @(posedge mem_ui_clk)
if (rst_i)
	match <= 8'h00;
else
	match <= match + 8'd1;

reg cs1xx;
reg we1xx;
reg [15:0] sel1xx;
reg [31:0] adr1xx;
reg [127:0] dati1xx;
reg sr1xx;
reg cr1xx;

reg cs7xx;
reg we7xx;
reg [15:0] sel7xx;
reg [31:0] adr7xx;
reg [127:0] dati7xx;
reg sr7xx;
reg cr7xx;

reg [63:0] mem_rd_data1;
reg [7:0] to_cnt;

// Terminate the ack signal as soon as the circuit select goes away.
assign ack0 = acki0 & cs0;
assign ack1 = acki1 & ics1;
assign ack2 = acki2 & cs2;
assign ack3 = acki3 & cs3;
`ifdef CH45
assign ack4 = acki4 & cs4;
assign ack5 = acki5 & cs5;
`endif
assign ack6 = acki6 & cs6;
assign ack7 = acki7 & ics7;

// Register signals onto mem_ui_clk domain
// The following channels don't need to be registered as they are operating
// under the mem_ui_clk domain already.
// Channel 0 (bmp controller) 
// Channel 5 (sprite controller)
always @(posedge mem_ui_clk)
begin
	cs1xx <= ics1;
	we1xx <= we1;
	sel1xx <= sel1;
	adr1xx <= adr1;
	dati1xx <= dati1;
	sr1xx <= sr1;
	cr1xx <= cr1;

	cs7xx <= ics7;
    we7xx <= we7;
    sel7xx <= sel7;
    adr7xx <= adr7;
    dati7xx <= dati7;
    sr7xx <= sr7;
    cr7xx <= cr7;
end

//------------------------------------------------------------------------
// Component Declarations
//------------------------------------------------------------------------
mig_7series_1 uddr3
(
	.ddr3_dq(ddr3_dq),
	.ddr3_dqs_p(ddr3_dqs_p),
	.ddr3_dqs_n(ddr3_dqs_n),
	.ddr3_addr(ddr3_addr),
	.ddr3_ba(ddr3_ba),
	.ddr3_ras_n(ddr3_ras_n),
	.ddr3_cas_n(ddr3_cas_n),
	.ddr3_we_n(ddr3_we_n),
	.ddr3_ck_p(ddr3_ck_p),
	.ddr3_ck_n(ddr3_ck_n),
	.ddr3_cke(ddr3_cke),
	.ddr3_dm(ddr3_dm),
	.ddr3_odt(ddr3_odt),
	.ddr3_reset_n(ddr3_reset_n),
	// Inputs
	.sys_clk_i(clk100MHz),
    .clk_ref_i(clk200MHz),
	.sys_rst(rstn),
	// user interface signals
	.app_addr(mem_addr),
	.app_cmd(mem_cmd),
	.app_en(mem_en),
	.app_wdf_data(mem_wdf_data),
	.app_wdf_end(mem_wdf_end),
	.app_wdf_mask(mem_wdf_mask),
	.app_wdf_wren(mem_wdf_wren),
	.app_rd_data(mem_rd_data),
	.app_rd_data_end(mem_rd_data_end),
	.app_rd_data_valid(mem_rd_data_valid),
	.app_rdy(mem_rdy),
	.app_wdf_rdy(mem_wdf_rdy),
	.app_sr_req(1'b0),
	.app_sr_active(),
	.app_ref_req(1'b0),
	.app_ref_ack(),
	.app_zq_req(1'b0),
	.app_zq_ack(),
	.ui_clk(mem_ui_clk),
	.ui_clk_sync_rst(mem_ui_rst),
	.init_calib_complete(calib_complete)
);



always @(posedge clk100MHz)
begin
	sreg <= {sreg[0],rst_i};
	rstn <= ~sreg[1];
end

reg toggle;	// CPU1 / CPU0 priority toggle
reg toggle_sr;
reg [19:0] resv_to_cnt;
reg sr1x,sr7x;
reg [127:0] dati128;

wire ch1_read = ics1 && !we1xx && cs1xx && (adr1xx[31:5]==ch1_addr[31:5]);
wire ch7_read = ics7 && !we7xx && cs7xx && (adr7xx[31:5]==ch7_addr[31:5]);

always @*
begin
	fast_read0 = FALSE;
	if (cs0 && !we0 && adr0[31:6]==ch0_addr[31:6])
		fast_read0 = TRUE;
end
always @*
begin
	fast_read1 = FALSE;
	if (ch1_read)
		fast_read1 = TRUE;
end
always @*
begin
	fast_read2 = FALSE;
	if (!we2 && cs2 && adr2[31:4]==ch2_addr[31:4])
    	fast_read2 = TRUE;
end
always @*
begin
	fast_read3 = FALSE;
	if (!we3 && cs3 && adr3[31:4]==ch3_addr[31:4])
		fast_read3 = TRUE;
end
`ifdef CH45
always @*
begin
    fast_read4 = FALSE;
	if (!we4 && cs4 && adr4[31:4]==ch4_addr[31:4])
		fast_read4 = TRUE;
end
always @*
begin
	fast_read5 = FALSE;
	if (cs5 && adr5[31:4]==ch5_addr[31:4])
		fast_read5 = TRUE;
end
`endif
always @*
begin
	fast_read6 = FALSE;
	if (!we6 && cs6 && adr6[31:4]==ch6_addr[31:4])
    	fast_read6 = TRUE;
end
always @*
begin
    fast_read7 = FALSE;
    if (ch7_read)
        fast_read7 = TRUE;
end

always @*
begin
	sr1x = FALSE;
    if (ch1_read)
        sr1x = sr1xx;
end
always @*
begin
	sr7x = FALSE;
    if (ch7_read)
        sr7x = sr7xx;
end

// Select the channel
always @*
begin
	// Channel 0 read or write takes precedence
	if (cs0 & we0)
		nch <= 3'd0;
	else if (cs0 & ~fast_read0)
		nch <= 3'd0;
	else if (cs1xx & we1xx)
		nch <= 3'd1;
	else if (cs2 & we2)
		nch <= 3'd2;
	else if (cs3 & we3)
		nch <= 3'd3;
`ifdef CH45
	else if (cs4 & we4)
		nch <= 3'd4;
`endif
	else if (cs6 & we6)
		nch <= 3'd6;
	else if (cs7xx & we7xx)
		nch <= 3'd7;
	// Reads, writes detected above
	else if (cs1xx & ~fast_read1)
		nch <= 3'd1;
	else if (cs2 & ~fast_read2)
		nch <= 3'd2;
	else if (cs3 & ~fast_read3)
		nch <= 3'd3;
`ifdef CH45
	else if (cs4 & ~fast_read4)
		nch <= 3'd4;
	else if (cs5 & ~fast_read5)
		nch <= 3'd5;
`endif
	else if (cs6 & ~fast_read6)
		nch <= 3'd6;
	else if (cs7xx & ~fast_read7)
		nch <= 3'd7;
	// Nothing selected
	else
		nch <= 4'hF;
end

always @(posedge mem_ui_clk)
	if (state==IDLE)
		ch <= nch;

// Select the address input
always @(posedge mem_ui_clk)
	if (state==IDLE) begin
		case(nch)
		3'd0:	if (we0)
					adr <= {adr0[AMSB:4],4'h0};
				else
					adr <= {adr0[AMSB:6],6'h0};
		3'd1:	if (we1xx)
					adr <= {adr1xx[AMSB:4],4'h0};
				else
					adr <= {adr1xx[AMSB:5],5'h0};
		3'd2:	adr <= {adr2[AMSB:4],4'h0};
		3'd3:	adr <= {adr3[AMSB:4],4'h0};
`ifdef CH45
		3'd4:	adr <= {adr4[AMSB:4],4'h0};
		3'd5:	adr <= {adr5[AMSB:6],6'h0};
`endif
		3'd6:	adr <= {adr6[AMSB:4],4'h0};
		3'd7:	if (we7xx)
					adr <= {adr7xx[AMSB:4],4'h0};
				else
					adr <= {adr7xx[AMSB:5],5'h0};
		default:	adr <= 29'h1FFFFFFF;
		endcase
	end

// Setting the write mask
always @(posedge mem_ui_clk)
	if (state==IDLE) begin
		wmask <= 16'h0000;
		case(nch)
		3'd0:	if (we0) wmask <= ~sel0;
		3'd1:	if (we1xx)	wmask <= ~sel1xx;
		3'd2:	if (we2)
		            case(adr2[3:2])
		            2'd0:  wmask <= {12'hFFF,~sel2[3:0]};
		            2'd1:  wmask <= {8'hFF,~sel2[3:0],4'hF};
		            2'd2:  wmask <= {4'hF,~sel2[3:0],8'hFF};
		            2'd3:  wmask <= {~sel2[3:0],12'hFFF};
		            endcase
		3'd3:	if (we3) wmask <= ~sel3;
`ifdef CH45
		3'd4:	if (we4) wmask <= ~sel4;
		3'd5:	;
`endif
		3'd6:	if (we6)
		            case(adr6[3:2])
		            2'd0:  wmask <= {12'hFFF,~sel6[3:0]};
		            2'd1:  wmask <= {8'hFF,~sel6[3:0],4'hF};
		            2'd2:  wmask <= {4'hF,~sel6[3:0],8'hFF};
		            2'd3:  wmask <= {~sel6[3:0],12'hFFF};
		            endcase
		3'd7:	if (we7xx) wmask <= ~sel7xx;
		default:	wmask <= 16'hFFFF;
		endcase
	end

// Setting the write data
always @(posedge mem_ui_clk)
	if (state==IDLE) begin
		case(nch)
		3'd0:	dat128 <= dati0;
		3'd1:	dat128 <= dati1xx;
		3'd2:	dat128 <= {4{dati2}};
		3'd3:	dat128 <= dati3;
`ifdef CH45
		3'd4:	dat128 <= dati4;
		3'd5:	;
`endif
		3'd6:	dat128 <= {4{dati6}};
		3'd7:	dat128 <= dati7xx;
		default:	dat128 <= dati7xx;
		endcase
	end


// Managing read cache addresses
always @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	ch0_addr <= 32'hFFFFFFFF;
	ch1_addr <= 32'hFFFFFFFF;
	ch2_addr <= 32'hFFFFFFFF;
	ch3_addr <= 32'hFFFFFFFF;
`ifdef CH45
	ch4_addr <= 32'hFFFFFFFF;
	ch5_addr <= 32'hFFFFFFFF;
`endif
	ch6_addr <= 32'hFFFFFFFF;
	ch7_addr <= 32'hFFFFFFFF;
end
else begin
	if (state==IDLE) begin
		if (cs0 & we0)
			clear_cache(adr0);
		if (cs1xx & we1xx)
			clear_cache(adr1xx);
		if (cs2 & we2)
			clear_cache(adr2);
		if (cs3 & we3)
			clear_cache(adr3);
`ifdef CH45
		if (cs4 & we4)
			clear_cache(adr4);
`endif
		if (cs6 & we6)
			clear_cache(adr6);
		if (cs7xx & we7xx)
			clear_cache(adr7xx);
	end
	if (state==WAIT_RD||state==SET_CMD_RD)
    	if (mem_rd_data_valid & mem_rd_data_end) begin
		    case(ch)
		    3'd0:	if (strip_cnt2==num_strips)
		          		ch0_addr <= {adr0[31:6],6'h0};
		    3'd1:   if (strip_cnt2==num_strips)
		            	ch1_addr <= {adr1xx[31:5],5'h00};
		    3'd2:   ch2_addr <= adr2;
		    3'd3:   ch3_addr <= adr3;
`ifdef CH45
		    3'd4:   ch4_addr <= adr4;
		    3'd5:   if (strip_cnt2==num_strips)
		            	ch5_addr <= {adr5[31:6],6'h00};
`endif
		    3'd6:   ch6_addr <= adr6;
		    3'd7:   if (strip_cnt2==num_strips)
		          		ch7_addr <= {adr7xx[31:5],5'h0};
		    endcase
    	end
end

// Setting burst length
always @(posedge mem_ui_clk)
	if (state==IDLE) begin
  		num_strips <= 2'd0;
		case(nch)
		3'd0:	if (!we0) 	num_strips <= 2'd3;
		3'd1:	if (!we1xx)	num_strips <= 2'd1;
		3'd2:	;
		3'd3:	;
`ifdef CH45
		3'd4:	;
		3'd5:	num_strips <= 2'd3;
`endif
		3'd6:	;
		3'd7:	if (!we7xx)	num_strips <= 2'd1;
		endcase
	end

// Auto-increment the request address during a read burst until the desired
// number of strips are requested.
always @(posedge mem_ui_clk)
if (state==PRESET)
	mem_addr <= adr;
else if (state==SET_CMD_RD)
    if (mem_rdy == TRUE) begin
        if (strip_cnt!=num_strips) begin
            mem_addr <= mem_addr + 10'd16;
        end
    end
always @(posedge mem_ui_clk)
if (state==PRESET)
	mem_wdf_mask <= wmask;
always @(posedge mem_ui_clk)
if (state==PRESET)
	mem_wdf_data <= dat128;

// Setting output data
always @(posedge mem_ui_clk)
	dato0 <= ch0_rd_data[adr0[5:4]];
always @(posedge mem_ui_clk)
    dato1 <= adr1xx[4] ? ch1_rd_data[1] : ch1_rd_data[0];
always @(posedge mem_ui_clk)
	case(adr2[3:2])
    2'd0:    dato2 <= ch2_rd_data[31:0];
    2'd1:    dato2 <= ch2_rd_data[63:32];
    2'd2:    dato2 <= ch2_rd_data[95:64];
    2'd3:    dato2 <= ch2_rd_data[127:96];
    endcase
always @(posedge mem_ui_clk)
	dato3 <= ch3_rd_data;
`ifdef CH45
always @(posedge mem_ui_clk)
	dato4 <= ch4_rd_data;
always @(posedge mem_ui_clk)
    dato5 <= ch5_rd_data[adr5[5:4]];
`endif
always @(posedge mem_ui_clk)
	case(adr6[3:2])
    2'd0:    dato6 <= ch6_rd_data[31:0];
    2'd1:    dato6 <= ch6_rd_data[63:32];
    2'd2:    dato6 <= ch6_rd_data[95:64];
    2'd3:    dato6 <= ch6_rd_data[127:96];
    endcase
always @(posedge mem_ui_clk)
    dato7 <= adr7xx[4] ? ch7_rd_data[1] : ch7_rd_data[0];

// Setting ack output
always @(posedge mem_ui_clk)
if (rst_i|mem_ui_rst) begin
	acki0 <= FALSE;
	acki1 <= FALSE;
	acki2 <= FALSE;
	acki3 <= FALSE;
`ifdef CH45
	acki4 <= FALSE;
	acki5 <= FALSE;
`endif
	acki6 <= FALSE;
	acki7 <= FALSE;
end
else begin
	// Reads: the ack doesn't happen until the data's been cached.
	if (cs0 && !we0 && adr0[31:6]==ch0_addr[31:6])
		acki0 <= TRUE;
	if (ch1_read)
		acki1 <= TRUE;
	if (!we2 && cs2 && adr2[31:4]==ch2_addr[31:4])
		acki2 <= TRUE;
	if (!we3 && cs3 && adr3[31:4]==ch3_addr[31:4])
		acki3 <= TRUE;
`ifdef CH45
	if (!we4 && cs4 && adr4[31:4]==ch4_addr[31:4])
		acki4 <= TRUE;
	if (cs5 && adr5[31:6]==ch5_addr[31:6])
        acki5 <= TRUE;
`endif
	if (!we6 && cs6 && adr6[31:4]==ch6_addr[31:4])
		acki6 <= TRUE;
    if (ch7_read)
        acki7 <= TRUE;

	if (state==IDLE) begin
	    if (cr1xx) begin
	        acki1 <= TRUE;
	        if ((resv_ch0==4'd1) && (resv_adr0[31:4]==adr1xx[31:4]))
	            acki1 <= FALSE;
	        if ((resv_ch1==4'd1) && (resv_adr1[31:4]==adr1xx[31:4]))
	            acki1 <= FALSE;
	    end
	    else
	        acki1 <= FALSE;
	    if (cr7xx) begin
	        acki7 <= TRUE;
	        if ((resv_ch0==4'd7) && (resv_adr0[31:4]==adr7xx[31:4]))
	            acki7 <= FALSE;
	        if ((resv_ch1==4'd7) && (resv_adr1[31:4]==adr7xx[31:4]))
	            acki7 <= FALSE;
	    end
	    else
	        acki7 <= FALSE;
	end

	// Write: an ack can be sent back as soon as the write state is reached..
	if (state==SET_CMD_WR) begin
        if (mem_rdy == TRUE)
		    case(ch)
		    3'd0:   acki0 <= TRUE;
		    3'd1:   acki1 <= TRUE;
		    3'd2:   acki2 <= TRUE;
		    3'd3:   acki3 <= TRUE;
`ifdef CH45		    
		    3'd4:   acki4 <= TRUE;
		    3'd5:   acki5 <= TRUE;
`endif		   
		    3'd6:   acki6 <= TRUE;
		    3'd7:   acki7 <= TRUE;
		    endcase
    end

	// Clear the ack when the circuit is de-selected.
	if (!cs0) acki0 <= FALSE;
	if (!cs1xx || !ics1) acki1 <= FALSE;
	if (!cs2) acki2 <= FALSE;
	if (!cs3) acki3 <= FALSE;
`ifdef CH45
	if (!cs4) acki4 <= FALSE;
	if (!cs5) acki5 <= FALSE;
`endif	
	if (!cs6) acki6 <= FALSE;
	if (!cs7xx || !ics7) acki7 <= FALSE;

end

// State machine
always @(posedge mem_ui_clk)
if (rst_i|mem_ui_rst)
	state <= IDLE;
else
case(state)
IDLE:
  // According to the docs there's no need to wait for calib complete.
  // Calib complete goes high in sim about 111 us.
  // Simulation setting must be set to FAST.
	if (calib_complete) begin
		case(nch)
		3'd0:	state <= PRESET;
		3'd1:
		    if (cr1xx) begin
		        state <= IDLE;
		        if ((resv_ch0==4'd1) && (resv_adr0[31:4]==adr1xx[31:4]))
		            state <= PRESET;
		        if ((resv_ch1==4'd1) && (resv_adr1[31:4]==adr1xx[31:4]))
		            state <= PRESET;
		    end
		    else
		        state <= PRESET;
		3'd2:	state <= PRESET;
		3'd3:	state <= PRESET;
`ifdef CH45
		3'd4:	state <= PRESET;
		3'd5:	state <= PRESET;
`endif	
		3'd6:	state <= PRESET;
		3'd7:
		    if (cr7xx) begin
		        state <= IDLE;
		        if ((resv_ch0==4'd7) && (resv_adr0[31:4]==adr7xx[31:4]))
		            state <= PRESET;
		        if ((resv_ch1==4'd7) && (resv_adr1[31:4]==adr7xx[31:4]))
		            state <= PRESET;
		    end
		    else
		        state <= PRESET;
		default:	;	// no channel selected -> stay in IDLE state
		endcase
	end

PRESET:
	if (do_wr)
		state <= SEND_DATA;
	else begin
		tocnt <= 16'd0;
		state <= SET_CMD_RD;
	end
SEND_DATA:
    if (mem_wdf_rdy == TRUE)
        state <= SET_CMD_WR;
SET_CMD_WR:
    if (mem_rdy == TRUE)
        state <= IDLE;
SET_CMD_RD:
	begin
		tocnt <= tocnt + 16'd1;
		if (tocnt==16'd120)
			state <= IDLE;
	    if (mem_rdy == TRUE) begin
	        if (strip_cnt==num_strips) begin
	        	tocnt <= 16'd0;
	            state <= WAIT_RD;
	        end
	    end
	    if (mem_rd_data_valid & mem_rd_data_end) begin
	        if (strip_cnt2==num_strips)
	            state <= IDLE;
	    end
	end
WAIT_RD:
	begin
		tocnt <= tocnt + 16'd1;
		if (tocnt==16'd120)
			state <= IDLE;
	    if (mem_rd_data_valid & mem_rd_data_end) begin
	        if (strip_cnt2==num_strips)
	            state <= IDLE;
	    end
	end
default:	state <= IDLE;
endcase


// Manage memory strip counters.
always @(posedge mem_ui_clk)
begin
	if (state==IDLE)
		strip_cnt <= 2'd0;
	else if (state==SET_CMD_RD)
	    if (mem_rdy == TRUE) begin
	        if (strip_cnt != num_strips)
	            strip_cnt <= strip_cnt + 2'd1;
	    end
end

always @(posedge mem_ui_clk)
begin
	if (state==IDLE)
		strip_cnt2 <= 2'd0;
	else if (state==WAIT_RD || state==SET_CMD_RD)
    	if (mem_rd_data_valid & mem_rd_data_end) begin
		    case(ch)
		    3'd0:	strip_cnt2 <= strip_cnt2 + 2'd1;
		    3'd1:	strip_cnt2 <= strip_cnt2 + 2'd1;
		    3'd5:	strip_cnt2 <= strip_cnt2 + 2'd1;
		    3'd7:	strip_cnt2 <= strip_cnt2 + 2'd1;
		    endcase
    	end
end

// Update data caches with read data.
always @(posedge mem_ui_clk)
begin
	if (state==WAIT_RD || state==SET_CMD_RD)
    	if (mem_rd_data_valid & mem_rd_data_end) begin
		    case(ch)
		    3'd0:	ch0_rd_data[strip_cnt2] <= mem_rd_data;
		    3'd1:	ch1_rd_data[strip_cnt2[0]] <= mem_rd_data;
		    3'd2:	ch2_rd_data <= mem_rd_data;
		    3'd3:	ch3_rd_data <= mem_rd_data;
`ifdef CH45	    
		    3'd4:	ch4_rd_data <= mem_rd_data;
		    3'd5:	ch5_rd_data[strip_cnt2] <= mem_rd_data;
`endif	    
		    3'd6:	ch6_rd_data <= mem_rd_data;
		    3'd7:	ch7_rd_data[strip_cnt2[0]] <= mem_rd_data;
		    endcase
		end
end

// Write operation indicator
always @(posedge mem_ui_clk)
begin
	if (state==IDLE) begin
		case(nch)
		3'd0:	do_wr <= we0;
		3'd1:
			if (we1xx) begin
			    if (cr1xx) begin
			    	do_wr <= FALSE;
			        if ((resv_ch0==4'd1) && (resv_adr0[31:4]==adr1xx[31:4]))
			            do_wr <= TRUE;
			        if ((resv_ch1==4'd1) && (resv_adr1[31:4]==adr1xx[31:4]))
			            do_wr <= TRUE;
			    end
			    else
			        do_wr <= TRUE;
			end
			else
				do_wr <= FALSE;
		3'd2:	do_wr <= we2;
		3'd3:	do_wr <= we3;
`ifdef CH45			
		3'd4:	do_wr <= we4;
`endif			
		3'd6:	do_wr <= we6;
		3'd7:
			if (we7xx) begin
			    if (cr7xx) begin
			    	do_wr <= FALSE;
			        if ((resv_ch0==4'd7) && (resv_adr0[31:4]==adr7xx[31:4]))
			            do_wr <= TRUE;
			        if ((resv_ch1==4'd7) && (resv_adr1[31:4]==adr7xx[31:4]))
			            do_wr <= TRUE;
			    end
			    else
			        do_wr <= TRUE;
			end
	        else
	        	do_wr <= FALSE;
	    default:	do_wr <= FALSE;
	    endcase
	end
end

// Reservation status bit
always @(posedge mem_ui_clk)
if (state==IDLE) begin
    if (cs1xx & we1xx & ~acki1) begin
        if (cr1xx) begin
            rb1 <= FALSE;
            if ((resv_ch0==4'd1) && (resv_adr0[31:4]==adr1xx[31:4]))
                rb1 <= TRUE;
            if ((resv_ch1==4'd1) && (resv_adr1[31:4]==adr1xx[31:4]))
                rb1 <= TRUE;
        end
    end
end

always @(posedge mem_ui_clk)
if (state==IDLE) begin
    if (cs7xx & we7xx & ~acki7) begin
        if (cr7xx) begin
            rb7 <= FALSE;
            if ((resv_ch0==4'd7) && (resv_adr0[31:4]==adr7xx[31:4]))
                rb7 <= TRUE;
            if ((resv_ch1==4'd7) && (resv_adr1[31:4]==adr7xx[31:4]))
                rb7 <= TRUE;
        end
    end
end

// Managing address reservations
always @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	resv_to_cnt <= 20'd0;
	toggle <= FALSE;
	toggle_sr <= FALSE;
	resv_ch0 <= 4'hF;
	resv_ch1 <= 4'hF;
end
else begin
	resv_to_cnt <= resv_to_cnt + 20'd1;

	if (sr1x & sr7x) begin
		if (toggle_sr) begin
			reserve_adr(4'h1,adr1xx);
			toggle_sr <= 1'b0;
		end
		else begin
			reserve_adr(4'h7,adr7xx);
			toggle_sr <= 1'b1;
		end
	end
	else begin
		if (sr1x)
			reserve_adr(4'h1,adr1xx);
		if (sr7x)
			reserve_adr(4'h7,adr7xx);
	end

	if (state==IDLE) begin
		if (cs1xx & we1xx & ~acki1) begin
		    toggle <= 1'b1;
		    if (cr1xx) begin
		        if ((resv_ch0==4'd1) && (resv_adr0[31:4]==adr1xx[31:4]))
		            resv_ch0 <= 4'hF;
		        if ((resv_ch1==4'd1) && (resv_adr1[31:4]==adr1xx[31:4]))
		            resv_ch1 <= 4'hF;
		    end
		end
		else if (cs7xx & we7xx & ~acki7) begin
		    toggle <= 1'b1;
		    if (cr7xx) begin
		        if ((resv_ch0==4'd7) && (resv_adr0[31:4]==adr7xx[31:4]))
		            resv_ch0 <= 4'hF;
		        if ((resv_ch1==4'd7) && (resv_adr1[31:4]==adr7xx[31:4]))
		            resv_ch1 <= 4'hF;
		    end
		end
		else if (!we1xx & cs1xx & ~fast_read1 & (cs7xx ? toggle : 1'b1))
			toggle <= 1'b0;
		else if (!we7xx & cs7xx & ~fast_read7)
			toggle <= 1'b1;
	end
end

assign mem_wdf_wren = state==SEND_DATA;
assign mem_wdf_end = state==SEND_DATA;
assign mem_en = state==SET_CMD_RD || state==SET_CMD_WR;
assign mem_cmd = state==SET_CMD_RD ? CMD_READ : CMD_WRITE;

// Clear the read cache where the cache address matches the given address. This is to
// prevent reading stale data from a cache.
task clear_cache;
input [31:0] adr;
begin
	if (ch0_addr[31:6]==adr[31:6])
		ch0_addr <= 32'hFFFFFFFF;
	if (ch1_addr[31:5]==adr[31:5])
		ch1_addr <= 32'hFFFFFFFF;
	if (ch2_addr[31:4]==adr[31:4])
		ch2_addr <= 32'hFFFFFFFF;
	if (ch3_addr[31:4]==adr[31:4])
		ch3_addr <= 32'hFFFFFFFF;
`ifdef CH45
	if (ch4_addr[31:4]==adr[31:4])
		ch4_addr <= 32'hFFFFFFFF;
	if (ch5_addr[31:6]==adr[31:6])
		ch5_addr <= 32'hFFFFFFFF;
`endif
	if (ch6_addr[31:4]==adr[31:4])
		ch6_addr <= 32'hFFFFFFFF;
	if (ch7_addr[31:5]==adr[31:5])
		ch7_addr <= 32'hFFFFFFFF;
end
endtask

// Two reservation buckets are allowed for. There are two (or more) CPU's in the
// system and as long as they are not trying to control the same resource (the
// same semaphore) then they should be able to set a reservation. Ideally there
// could be more reservation buckets available, but it starts to be a lot of
// hardware.
task reserve_adr;
input [3:0] ch;
input [31:0] adr;
begin
	// Ignore an attempt to reserve an address that's already reserved. The LWAR
	// instruction is usually called in a loop and we don't want it to use up
	// both address reservations.
	if (!(resv_ch0==ch && resv_adr0==adr) && !(resv_ch1==ch && resv_adr1==adr)) begin
		if (resv_ch0==4'hF) begin
			resv_ch0 <= ch;
			resv_adr0 <= adr;
		end
		else if (resv_ch1==4'hF) begin
			resv_ch1 <= ch;
			resv_adr1 <= adr;
		end
		else begin
			// Here there were no free reservation buckets, so toss one of the
			// old reservations out.
			if (match[6]) begin
				resv_ch0 <= ch;
				resv_adr0 <= adr;
			end
			else begin
				resv_ch1 <= ch;
				resv_adr1 <= adr;
			end
		end
	end
end
endtask

endmodule

