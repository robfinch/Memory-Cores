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

module mpmc10_cache_wb (input rst, wclk, inv, 
	input wb_write_request128_t wchi, 
	output wb_write_response_t wcho,
	input wb_write_request128_t ld,
	input ch0clk, 
	input ch1clk, 
	input ch2clk, 
	input ch3clk, 
	input ch4clk, 
	input ch5clk, 
	input ch6clk, 
	input ch7clk, 
	input wb_write_request128_t ch0i,
	input wb_write_request128_t ch1i,
	input wb_write_request128_t ch2i,
	input wb_write_request128_t ch3i,
	input wb_write_request128_t ch4i,
	input wb_write_request128_t ch5i,
	input wb_write_request128_t ch6i,
	input wb_write_request128_t ch7i,
	input ch0wack,
	input ch1wack,
	input ch2wack,
	input ch3wack,
	input ch4wack,
	input ch5wack,
	input ch6wack,
	input ch7wack,
	output wb_read_response128_t ch0o,
	output wb_read_response128_t ch1o,
	output wb_read_response128_t ch2o,
	output wb_read_response128_t ch3o,
	output wb_read_response128_t ch4o,
	output wb_read_response128_t ch5o,
	output wb_read_response128_t ch6o,
	output wb_read_response128_t ch7o
);
parameter DEP=1024;
parameter LOBIT=4;
parameter HIBIT=13;

integer n,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13;

(* ram_style="distributed" *)
reg [1023:0] vbit [0:CACHE_ASSOC-1];
initial begin
	for (n5 = 0; n5 < CACHE_ASSOC; n5 = n5 + 1)
		vbit[n5] <= 'd0;
end

reg [31:0] radrr [0:8];
reg wchi_stb, wchi_stb_r;
reg [15:0] wchi_sel;
reg [31:0] wchi_adr, wchi_adr1;
reg [127:0] wchi_dat;

mpmc10_quad_cache_line_t doutb [0:8];
mpmc10_quad_cache_line_t wrdata, wdata;

reg [31:0] wadr;
reg [127:0] lddat1, lddat2;
reg [31:0] wadr2;
reg wstrb;
reg [$clog2(CACHE_ASSOC)-1:0] wway;

reg [CACHE_ASSOC-1:0] vbito0a;
reg [CACHE_ASSOC-1:0] vbito1a;
reg [CACHE_ASSOC-1:0] vbito2a;
reg [CACHE_ASSOC-1:0] vbito3a;
reg [CACHE_ASSOC-1:0] vbito4a;
reg [CACHE_ASSOC-1:0] vbito5a;
reg [CACHE_ASSOC-1:0] vbito6a;
reg [CACHE_ASSOC-1:0] vbito7a;
reg [CACHE_ASSOC-1:0] vbito8a;

reg [CACHE_ASSOC-1:0] hit0a;
reg [CACHE_ASSOC-1:0] hit1a;
reg [CACHE_ASSOC-1:0] hit2a;
reg [CACHE_ASSOC-1:0] hit3a;
reg [CACHE_ASSOC-1:0] hit4a;
reg [CACHE_ASSOC-1:0] hit5a;
reg [CACHE_ASSOC-1:0] hit6a;
reg [CACHE_ASSOC-1:0] hit7a;
reg [CACHE_ASSOC-1:0] hit8a;

reg stb0;
reg stb1;
reg stb2;
reg stb3;
reg stb4;
reg stb5;
reg stb6;
reg stb7;
reg [8:0] rstb;

always_ff @(posedge ch0clk) radrr[0] <= ch0i.adr;
always_ff @(posedge ch1clk) radrr[1] <= ch1i.adr;
always_ff @(posedge ch2clk) radrr[2] <= ch2i.adr;
always_ff @(posedge ch3clk) radrr[3] <= ch3i.adr;
always_ff @(posedge ch4clk) radrr[4] <= ch4i.adr;
always_ff @(posedge ch5clk) radrr[5] <= ch5i.adr;
always_ff @(posedge ch6clk) radrr[6] <= ch6i.adr;
always_ff @(posedge ch7clk) radrr[7] <= ch7i.adr;
always_ff @(posedge wclk) radrr[8] <= ld.cyc ? ld.adr : wchi.adr;
always_ff @(posedge wclk) wchi_adr1 <= wchi.adr;
always_ff @(posedge wclk) wchi_adr <= wchi_adr1;

always_ff @(posedge ch0clk) stb0 <= ch0i.stb;
always_ff @(posedge ch1clk) stb1 <= ch1i.stb;
always_ff @(posedge ch2clk) stb2 <= ch2i.stb;
always_ff @(posedge ch3clk) stb3 <= ch3i.stb;
always_ff @(posedge ch4clk) stb4 <= ch4i.stb;
always_ff @(posedge ch5clk) stb5 <= ch5i.stb;
always_ff @(posedge ch6clk) stb6 <= ch6i.stb;
always_ff @(posedge ch7clk) stb7 <= ch7i.stb;

always_comb rstb[0] <= ch0i.stb & ~ch0i.we;
always_comb rstb[1] <= ch1i.stb & ~ch1i.we;
always_comb rstb[2] <= ch2i.stb & ~ch2i.we;
always_comb rstb[3] <= ch3i.stb & ~ch3i.we;
always_comb rstb[4] <= ch4i.stb & ~ch4i.we;
always_comb rstb[5] <= ch5i.stb & ~ch5i.we;
always_comb rstb[6] <= ch6i.stb & ~ch6i.we;
always_comb rstb[7] <= ch7i.stb & ~ch7i.we;
always_comb rstb[8] <= ld.cyc ? ld.stb : wchi.stb;

always_ff @(posedge wclk) wchi_stb_r <= wchi.stb;
always_ff @(posedge wclk) wchi_stb <= wchi_stb_r;
always_ff @(posedge wclk) wchi_sel <= wchi.sel;
always_ff @(posedge wclk) wchi_dat <= wchi.dat;

reg [8:0] rclkp;
always_comb
begin
	rclkp[0] = ch0clk;
	rclkp[1] = ch1clk;
	rclkp[2] = ch2clk;
	rclkp[3] = ch3clk;
	rclkp[4] = ch4clk;
	rclkp[5] = ch5clk;
	rclkp[6] = ch6clk;
	rclkp[7] = ch7clk;
	rclkp[8] = wclk;
end

reg [HIBIT-LOBIT:0] radr [0:8];
always_comb
begin
	radr[0] = ch0i.adr[HIBIT:LOBIT];
	radr[1] = ch1i.adr[HIBIT:LOBIT];
	radr[2] = ch2i.adr[HIBIT:LOBIT];
	radr[3] = ch3i.adr[HIBIT:LOBIT];
	radr[4] = ch4i.adr[HIBIT:LOBIT];
	radr[5] = ch5i.adr[HIBIT:LOBIT];
	radr[6] = ch6i.adr[HIBIT:LOBIT];
	radr[7] = ch7i.adr[HIBIT:LOBIT];
	radr[8] = ld.cyc ? ld.adr[HIBIT:LOBIT] : wchi.adr[HIBIT:LOBIT];
end

   // xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2020.2

genvar gway,gport;

generate begin : gCacheRAM
	for (gport = 0; gport < 9; gport = gport + 1) begin
	xpm_memory_sdpram #(
		.ADDR_WIDTH_A($clog2(DEP)),
		.ADDR_WIDTH_B($clog2(DEP)),
		.AUTO_SLEEP_TIME(0),
		.BYTE_WRITE_WIDTH_A($bits(mpmc10_quad_cache_line_t)),
		.CASCADE_HEIGHT(0),
		.CLOCKING_MODE("independent_clock"), // String
		.ECC_MODE("no_ecc"),            // String
		.MEMORY_INIT_FILE("none"),      // String
		.MEMORY_INIT_PARAM("0"),        // String
		.MEMORY_OPTIMIZATION("true"),   // String
		.MEMORY_PRIMITIVE("block"),      // String
		.MEMORY_SIZE($bits(mpmc10_quad_cache_line_t)*DEP),         // DECIMAL
		.MESSAGE_CONTROL(0),            // DECIMAL
		.READ_DATA_WIDTH_B($bits(mpmc10_quad_cache_line_t)),         // DECIMAL
		.READ_LATENCY_B(1),
		.READ_RESET_VALUE_B("0"),       // String
		.RST_MODE_A("SYNC"),            // String
		.RST_MODE_B("SYNC"),            // String
		.SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
		.USE_EMBEDDED_CONSTRAINT(0),
		.USE_MEM_INIT(1),
		.WAKEUP_TIME("disable_sleep"),  // String
		.WRITE_DATA_WIDTH_A($bits(mpmc10_quad_cache_line_t)),        // DECIMAL
		.WRITE_MODE_B("no_change")      // String
	)
		xpm_memory_sdpram_inst1 (
		.dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
		                                 // on the data output of port B.

		.doutb(doutb[gport]),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
		.sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
		                                 // on the data output of port B.

		.addra(wadr2[HIBIT:LOBIT]),        				// ADDR_WIDTH_A-bit input: Address for port A write operations.
		.addrb(radr[gport]),             // ADDR_WIDTH_B-bit input: Address for port B read operations.
		.clka(wclk),                 // 1-bit input: Clock signal for port A. Also clocks port B when
		                                 // parameter CLOCKING_MODE is "common_clock".

		.clkb(rclkp[gport]),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
		                                 // "independent_clock". Unused when parameter CLOCKING_MODE is
		                                 // "common_clock".

		.dina(wdata),                // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
		.ena(wstrb),          			// 1-bit input: Memory enable signal for port A. Must be high on clock
		                                 // cycles when write operations are initiated. Pipelined internally.

		.enb(rstb[gport]),                // 1-bit input: Memory enable signal for port B. Must be high on clock
		                                 // cycles when read operations are initiated. Pipelined internally.

		.injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
		                                 // ECC enabled (Error injection capability is not available in
		                                 // "decode_only" mode).

		.injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
		                                 // ECC enabled (Error injection capability is not available in
		                                 // "decode_only" mode).

		.regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
		                                 // data path.

		.rstb(rst),                     // 1-bit input: Reset signal for the final port B output register stage.
		                                 // Synchronously resets output port doutb to the value specified by
		                                 // parameter READ_RESET_VALUE_B.

		.sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
		.wea(wstrb)                     // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
		                                 // for port A input data port dina. 1 bit wide when word-wide writes are
		                                 // used. In byte-wide write configurations, each bit controls the
		                                 // writing one byte of dina to address addra. For example, to
		                                 // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
		                                 // is 32, wea would be 4'b0010.

	);
	end
end
endgenerate				
				
genvar g;
generate begin : gReaddat
	for (g = 0; g < CACHE_ASSOC; g = g + 1) begin
		always_comb vbito0a[g] <= vbit[g][radrr[0][HIBIT:LOBIT]];
		always_comb vbito1a[g] <= vbit[g][radrr[1][HIBIT:LOBIT]];
		always_comb vbito2a[g] <= vbit[g][radrr[2][HIBIT:LOBIT]];
		always_comb vbito3a[g] <= vbit[g][radrr[3][HIBIT:LOBIT]];
		always_comb vbito4a[g] <= vbit[g][radrr[4][HIBIT:LOBIT]];
		always_comb vbito5a[g] <= vbit[g][radrr[5][HIBIT:LOBIT]];
		always_comb vbito6a[g] <= vbit[g][radrr[6][HIBIT:LOBIT]];
		always_comb vbito7a[g] <= vbit[g][radrr[7][HIBIT:LOBIT]];
		always_comb vbito8a[g] <= vbit[g][radrr[8][HIBIT:LOBIT]];
		
		always_ff @(posedge ch0clk)	hit0a[g] <= (doutb[0].lines[g].tag==radrr[0][31:LOBIT]) && (vbito0a[g]==1'b1);
		always_ff @(posedge ch1clk)	hit1a[g] <= (doutb[1].lines[g].tag==radrr[1][31:LOBIT]) && (vbito1a[g]==1'b1);
		always_ff @(posedge ch2clk)	hit2a[g] <= (doutb[2].lines[g].tag==radrr[2][31:LOBIT]) && (vbito2a[g]==1'b1);
		always_ff @(posedge ch3clk)	hit3a[g] <= (doutb[3].lines[g].tag==radrr[3][31:LOBIT]) && (vbito3a[g]==1'b1);
		always_ff @(posedge ch4clk)	hit4a[g] <= (doutb[4].lines[g].tag==radrr[4][31:LOBIT]) && (vbito4a[g]==1'b1);
		always_ff @(posedge ch5clk)	hit5a[g] <= (doutb[5].lines[g].tag==radrr[5][31:LOBIT]) && (vbito5a[g]==1'b1);
		always_ff @(posedge ch6clk)	hit6a[g] <= (doutb[6].lines[g].tag==radrr[6][31:LOBIT]) && (vbito6a[g]==1'b1);
		always_ff @(posedge ch7clk)	hit7a[g] <= (doutb[7].lines[g].tag==radrr[7][31:LOBIT]) && (vbito7a[g]==1'b1);
		always_ff @(posedge wclk)	hit8a[g] <= (doutb[8].lines[g].tag==radrr[8][31:LOBIT]) && (vbito8a[g]==1'b1);
	end
	always_ff @(posedge ch0clk) ch0o.ack <= (|hit0a & stb0) | (ch0wack & stb0);
	always_ff @(posedge ch1clk) ch1o.ack <= (|hit1a & stb1) | (ch1wack & stb1);
	always_ff @(posedge ch2clk) ch2o.ack <= (|hit2a & stb2) | (ch2wack & stb2);
	always_ff @(posedge ch3clk) ch3o.ack <= (|hit3a & stb3) | (ch3wack & stb3);
	always_ff @(posedge ch4clk) ch4o.ack <= (|hit4a & stb4) | (ch4wack & stb4);
	always_ff @(posedge ch5clk) ch5o.ack <= (|hit5a & stb5) | (ch5wack & stb5);
	always_ff @(posedge ch6clk) ch6o.ack <= (|hit6a & stb6) | (ch6wack & stb6);
	always_ff @(posedge ch7clk) ch7o.ack <= (|hit7a & stb7) | (ch7wack & stb7);
	always_comb ch0o.err = 1'b0;
	always_comb ch1o.err = 1'b0;
	always_comb ch2o.err = 1'b0;
	always_comb ch3o.err = 1'b0;
	always_comb ch4o.err = 1'b0;
	always_comb ch5o.err = 1'b0;
	always_comb ch6o.err = 1'b0;
	always_comb ch7o.err = 1'b0;
	always_comb ch0o.rty = 1'b0;
	always_comb ch1o.rty = 1'b0;
	always_comb ch2o.rty = 1'b0;
	always_comb ch3o.rty = 1'b0;
	always_comb ch4o.rty = 1'b0;
	always_comb ch5o.rty = 1'b0;
	always_comb ch6o.rty = 1'b0;
	always_comb ch7o.rty = 1'b0;
	always_comb ch0o.cid = ch0i.cid;
	always_comb ch1o.cid = ch1i.cid;
	always_comb ch2o.cid = ch2i.cid;
	always_comb ch3o.cid = ch3i.cid;
	always_comb ch4o.cid = ch4i.cid;
	always_comb ch5o.cid = ch5i.cid;
	always_comb ch6o.cid = ch6i.cid;
	always_comb ch7o.cid = ch7i.cid;
end
endgenerate

always_comb wway = hit8a[0] ? 2'd0 : hit8a[1] ? 2'd1 : hit8a[2] ? 2'd2 : hit8a[3] ? 2'd3 : 2'd0;

always_ff @(posedge ch0clk)
begin
	ch0o.dat <= 'd0;
	for (n2 = 0; n2 < CACHE_ASSOC; n2 = n2 + 1)
		if (hit0a[n2]) ch0o.dat <= doutb[0].lines[n2];
end
always_ff @(posedge ch1clk)
begin
	ch1o.dat <= 'd0;
	for (n6 = 0; n6 < CACHE_ASSOC; n6 = n6 + 1)
		if (hit1a[n6]) ch1o.dat <= doutb[1].lines[n6];
end
always_ff @(posedge ch2clk)
begin
	ch2o.dat <= 'd0;
	for (n7 = 0; n7 < CACHE_ASSOC; n7 = n7 + 1)
		if (hit2a[n7]) ch2o.dat <= doutb[2].lines[n7];
end
always_ff @(posedge ch3clk)
begin
	ch3o.dat <= 'd0;
	for (n8 = 0; n8 < CACHE_ASSOC; n8 = n8 + 1)
		if (hit3a[n8]) ch3o.dat <= doutb[3].lines[n8];
end
always_ff @(posedge ch4clk)
begin
	ch4o.dat <= 'd0;
	for (n9 = 0; n9 < CACHE_ASSOC; n9 = n9 + 1)
		if (hit4a[n9]) ch4o.dat <= doutb[4].lines[n9];
end
always_ff @(posedge ch5clk)
begin
	ch5o.dat <= 'd0;
	for (n10 = 0; n10 < CACHE_ASSOC; n10 = n10 + 1)
		if (hit5a[n10]) ch5o.dat <= doutb[5].lines[n10];
end
always_ff @(posedge ch6clk)
begin
	ch6o.dat <= 'd0;
	for (n11 = 0; n11 < CACHE_ASSOC; n11 = n11 + 1)
		if (hit6a[n11]) ch6o.dat <= doutb[6].lines[n11];
end
always_ff @(posedge ch6clk)
begin
	ch7o.dat <= 'd0;
	for (n12 = 0; n12 < CACHE_ASSOC; n12 = n12 + 1)
		if (hit7a[n12]) ch7o.dat <= doutb[7].lines[n12];
end

always_comb
	wrdata <= doutb[8];

reg b0,b1,b2;
reg ldcycd1,ldcycd2;
always_ff @(posedge wclk)
	ldcycd1 <= ld.cyc;
always_ff @(posedge wclk)
	ldcycd2 <= ldcycd1;

always_ff @(posedge wclk)
if (rst) begin
	for (n = 0; n < 4; n = n + 1)
		vbit[n] <= 'b0;	
end
else begin
	if (ldcycd2) begin
		vbit[0][wadr2[HIBIT:LOBIT]] <= 1'b1;
		vbit[1][wadr2[HIBIT:LOBIT]] <= b0;
		vbit[2][wadr2[HIBIT:LOBIT]] <= b1;
		vbit[3][wadr2[HIBIT:LOBIT]] <= b2;
	end
	if (ldcycd1) begin
		b0 <= vbit[0][wadr[HIBIT:LOBIT]];
		b1 <= vbit[1][wadr[HIBIT:LOBIT]];
		b2 <= vbit[2][wadr[HIBIT:LOBIT]];
	end
	if (|hit8a & |wchi_sel & wchi_stb & wchi.we & ~(ld.cyc|ldcycd1|ldcycd2))
		vbit[wway][wadr[HIBIT:LOBIT]] <= 1'b1;
	else if (inv)
		vbit[wway][wadr[HIBIT:LOBIT]] <= 1'b0;
end

// Update the cache only if there was a write hit or if loading the cache line
// due to a read miss. For a read miss the entire line is updated, otherwise
// just the part of the line relevant to the write is updated.
always_ff @(posedge wclk)
begin
	if (ld.cyc)
		wadr <= ld.adr;
	else if (wchi.stb)
		wadr <= wchi.adr;
end
always_ff @(posedge wclk)
	wadr2 <= wadr;
always_ff @(posedge wclk)
	lddat1 <= ld.dat;
always_ff @(posedge wclk)
	lddat2 <= lddat1;
always_ff @(posedge wclk)
	wstrb <= ldcycd2 | (wchi_stb & |hit8a & wchi.we);
	
// Merge write data into cache line.
// For a load due to a read miss the entire line is updated.
// For a write hit, just the portion of the line corresponding to the hit is
// updated.
reg [18:0] t0,t1,t2;
reg m0,m1,m2;
generate begin : gWrData
	// LRU update
	always_ff @(posedge wclk)
	begin
		if (ldcycd2) begin
			wdata.lines[0].tag <= wadr2[31:LOBIT];			// set tag
			wdata.lines[1].tag <= t0;
			wdata.lines[2].tag <= t1;
			wdata.lines[3].tag <= t2;
			wdata.lines[0].modified <= 1'b0;						// clear modified flags
			wdata.lines[1].modified <= m0;
			wdata.lines[2].modified <= m1;
			wdata.lines[3].modified <= m2;
		end
		if (ldcycd1) begin
			t0 <= wrdata.lines[0].tag;
			t1 <= wrdata.lines[1].tag;
			t2 <= wrdata.lines[2].tag;
			m0 <= wrdata.lines[0].modified;
			m1 <= wrdata.lines[1].modified;
			m2 <= wrdata.lines[2].modified;
		end
		if (!(ld.cyc|ldcycd1|ldcycd2)) begin
			if (wchi_stb & hit8a[0] & wchi.we)
				wdata.lines[0].modified <= 1'b1;
			else
				wdata.lines[0].modified <= wrdata.lines[0].modified;
			if (wchi_stb & hit8a[1] & wchi.we)
				wdata.lines[1].modified <= 1'b1;
			else
				wdata.lines[1].modified <= wrdata.lines[1].modified;
			if (wchi_stb & hit8a[2] & wchi.we)
				wdata.lines[2].modified <= 1'b1;
			else
				wdata.lines[2].modified <= wrdata.lines[2].modified;
			if (wchi_stb & hit8a[3] & wchi.we)
				wdata.lines[3].modified <= 1'b1;
			else
				wdata.lines[3].modified <= wrdata.lines[3].modified;
			// Tag stays the same, it was hit
			wdata.lines[0].tag <= wrdata.lines[0].tag;
			wdata.lines[1].tag <= wrdata.lines[1].tag;
			wdata.lines[2].tag <= wrdata.lines[2].tag;
			wdata.lines[3].tag <= wrdata.lines[3].tag;
		end
	end
	for (g = 0; g < 16; g = g + 1)
	always_ff @(posedge wclk)
		begin
			if (ldcycd2) begin
	//			wdata <= wrdata << $bits(mpmc10_cache_line_t);
				wdata.lines[0].data[g*8+7:g*8] <= lddat2[g*8+7:g*8];		// set data
				wdata.lines[1].data[g*8+7:g*8] <= wrdata.lines[0].data[g*8+7:g*8];
				wdata.lines[2].data[g*8+7:g*8] <= wrdata.lines[1].data[g*8+7:g*8];
				wdata.lines[3].data[g*8+7:g*8] <= wrdata.lines[2].data[g*8+7:g*8];
			end
			if (!(ld.cyc|ldcycd1|ldcycd2)) begin
				if (wchi_stb & hit8a[0] & wchi.we)
					wdata.lines[0].data[g*8+7:g*8] <= wchi_sel[g] ? wchi_dat[g*8+7:g*8] : wrdata.lines[0].data[g*8+7:g*8];
				else
					wdata.lines[0].data[g*8+7:g*8] <= wrdata.lines[0].data[g*8+7:g*8];
				if (wchi_stb & hit8a[1] & wchi.we)
					wdata.lines[1].data[g*8+7:g*8] <= wchi_sel[g] ? wchi_dat[g*8+7:g*8] : wrdata.lines[1].data[g*8+7:g*8];
				else
					wdata.lines[1].data[g*8+7:g*8] <= wrdata.lines[1].data[g*8+7:g*8];
				if (wchi_stb & hit8a[2] & wchi.we)
					wdata.lines[2].data[g*8+7:g*8] <= wchi_sel[g] ? wchi_dat[g*8+7:g*8] : wrdata.lines[2].data[g*8+7:g*8];
				else
					wdata.lines[2].data[g*8+7:g*8] <= wrdata.lines[2].data[g*8+7:g*8];
				if (wchi_stb & hit8a[3] & wchi.we)
					wdata.lines[3].data[g*8+7:g*8] <= wchi_sel[g] ? wchi_dat[g*8+7:g*8] : wrdata.lines[3].data[g*8+7:g*8];
				else
					wdata.lines[3].data[g*8+7:g*8] <= wrdata.lines[3].data[g*8+7:g*8];
			end
		end
end
endgenerate

// Writes take two clock cycles, 1 to read the RAM and find out if it is a
// write hit and a second clock to write the data. The write cycle may be
// delayed by a cycle due to a load.
reg wack;
always_ff @(posedge wclk)
if (rst)
	wack <= 1'b0;
else begin
	wack <= 1'b0;
	if (wchi_stb & ~ld.stb & wchi.we)
		wack <= 1'b1;
end
assign wcho.ack = wack & wchi.stb;

endmodule
