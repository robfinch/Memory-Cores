`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2026  Robert Finch, Waterloo
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
// Requires:
//		rst be held at least 1024 clock cycles.
// ============================================================================
//
import const_pkg::*;
import fta_bus_pkg::*;
import mpmc11_pkg::*;

module mpmc11_cache_fta (input rst, wclk, inv,
	input fta_cmd_request256_t wchi, 
	output fta_cmd_response256_t wcho,
	input fta_cmd_request256_t ld,
	input to,
	fta_bus_interface.slave ch0,
	fta_bus_interface.slave ch1,
	fta_bus_interface.slave ch2,
	fta_bus_interface.slave ch3,
	fta_bus_interface.slave ch4,
	fta_bus_interface.slave ch5,
	fta_bus_interface.slave ch6,
	fta_bus_interface.slave ch7,
	input ch0wack,
	input ch1wack,
	input ch2wack,
	input ch3wack,
	input ch4wack,
	input ch5wack,
	input ch6wack,
	input ch7wack,
	output reg ch0hit,
	output reg ch1hit,
	output reg ch2hit,
	output reg ch3hit,
	output reg ch4hit,
	output reg ch5hit,
	output reg ch6hit,
	output reg ch7hit,
	output fta_cmd_request256_t miss
);
parameter SIM = TRUE;
parameter DEP=1024;
parameter LOBIT=5;
parameter HIBIT=14;
parameter TAGLOBIT=15;
parameter PORT_PRESENT=9'h1FF;

integer n,n2,n3,n4,n5;

reg [1023:0] vbit [0:CACHE_ASSOC-1];

reg rst1;
reg [7:0] ack,ack1,ack2;
reg [7:0] load;
reg [12:0] rtid [0:8];
reg [31:0] radrr [0:8];
reg wchi_stb, wchi_stb_r;
reg [31:0] wchi_sel;
reg [31:0] wchi_adr, wchi_adr1;
reg [255:0] wchi_dat;

mpmc11_quad_cache_line_t doutb [0:8];
mpmc11_quad_cache_line_t wrdata, wdata;

reg [31:0] wadr;
reg [255:0] lddat1, lddat2;
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

reg [8:0] hitv; 

reg stb0;
reg stb1;
reg stb2;
reg stb3;
reg stb4;
reg stb5;
reg stb6;
reg stb7;
reg stb0a;
reg stb1a;
reg stb2a;
reg stb3a;
reg stb4a;
reg stb5a;
reg stb6a;
reg stb7a;
reg [8:0] rstb,rstb2,rstb3,rstb4;

always_ff @(posedge ch0.clk) if (ch0.rst) rtid[0] <= 13'd0; else if (ch0.req.cyc) rtid[0] <= ch0.req.tid; 
always_ff @(posedge ch1.clk) if (ch1.rst) rtid[1] <= 13'd0; else if (ch1.req.cyc) rtid[1] <= ch1.req.tid; 
always_ff @(posedge ch2.clk) if (ch2.rst) rtid[2] <= 13'd0; else if (ch2.req.cyc) rtid[2] <= ch2.req.tid; 
always_ff @(posedge ch3.clk) if (ch3.rst) rtid[3] <= 13'd0; else if (ch3.req.cyc) rtid[3] <= ch3.req.tid; 
always_ff @(posedge ch4.clk) if (ch4.rst) rtid[4] <= 13'd0; else if (ch4.req.cyc) rtid[4] <= ch4.req.tid; 
always_ff @(posedge ch5.clk) if (ch5.rst) rtid[5] <= 13'd0; else if (ch5.req.cyc) rtid[5] <= ch5.req.tid; 
always_ff @(posedge ch6.clk) if (ch6.rst) rtid[6] <= 13'd0; else if (ch6.req.cyc) rtid[6] <= ch6.req.tid; 
always_ff @(posedge ch7.clk) if (ch7.rst) rtid[7] <= 13'd0; else if (ch7.req.cyc) rtid[7] <= ch7.req.tid; 

always_ff @(posedge ch0.clk) if (rst1) load[0] <= FALSE; else if (ch0.req.cyc) load[0] <= (ch0.req.cmd==fta_bus_pkg::CMD_LOAD||ch0.req.cmd==fta_bus_pkg::CMD_LOADZ); 
always_ff @(posedge ch1.clk) if (rst1) load[1] <= FALSE; else if (ch1.req.cyc) load[1] <= (ch1.req.cmd==fta_bus_pkg::CMD_LOAD||ch1.req.cmd==fta_bus_pkg::CMD_LOADZ); 
always_ff @(posedge ch2.clk) if (rst1) load[2] <= FALSE; else if (ch2.req.cyc) load[2] <= (ch2.req.cmd==fta_bus_pkg::CMD_LOAD||ch2.req.cmd==fta_bus_pkg::CMD_LOADZ); 
always_ff @(posedge ch3.clk) if (rst1) load[3] <= FALSE; else if (ch3.req.cyc) load[3] <= (ch3.req.cmd==fta_bus_pkg::CMD_LOAD||ch3.req.cmd==fta_bus_pkg::CMD_LOADZ); 
always_ff @(posedge ch4.clk) if (rst1) load[4] <= FALSE; else if (ch4.req.cyc) load[4] <= (ch4.req.cmd==fta_bus_pkg::CMD_LOAD||ch4.req.cmd==fta_bus_pkg::CMD_LOADZ); 
always_ff @(posedge ch5.clk) if (rst1) load[5] <= FALSE; else if (ch5.req.cyc) load[5] <= (ch5.req.cmd==fta_bus_pkg::CMD_LOAD||ch5.req.cmd==fta_bus_pkg::CMD_LOADZ); 
always_ff @(posedge ch6.clk) if (rst1) load[6] <= FALSE; else if (ch6.req.cyc) load[6] <= (ch6.req.cmd==fta_bus_pkg::CMD_LOAD||ch6.req.cmd==fta_bus_pkg::CMD_LOADZ); 
always_ff @(posedge ch7.clk) if (rst1) load[7] <= FALSE; else if (ch7.req.cyc) load[7] <= (ch7.req.cmd==fta_bus_pkg::CMD_LOAD||ch7.req.cmd==fta_bus_pkg::CMD_LOADZ); 

always_ff @(posedge ch0.clk) if (ch0.rst) radrr[0] <= 32'd0; else if (ch0.req.cyc) radrr[0] <= ch0.req.adr;
always_ff @(posedge ch1.clk) if (ch1.rst) radrr[1] <= 32'd0; else if (ch1.req.cyc) radrr[1] <= ch1.req.adr;
always_ff @(posedge ch2.clk) if (ch2.rst) radrr[2] <= 32'd0; else if (ch2.req.cyc) radrr[2] <= ch2.req.adr;
always_ff @(posedge ch3.clk) if (ch3.rst) radrr[3] <= 32'd0; else if (ch3.req.cyc) radrr[3] <= ch3.req.adr;
always_ff @(posedge ch4.clk) if (ch4.rst) radrr[4] <= 32'd0; else if (ch4.req.cyc) radrr[4] <= ch4.req.adr;
always_ff @(posedge ch5.clk) if (ch5.rst) radrr[5] <= 32'd0; else if (ch5.req.cyc) radrr[5] <= ch5.req.adr;
always_ff @(posedge ch6.clk) if (ch6.rst) radrr[6] <= 32'd0; else if (ch6.req.cyc) radrr[6] <= ch6.req.adr;
always_ff @(posedge ch7.clk) if (ch7.rst) radrr[7] <= 32'd0; else if (ch7.req.cyc) radrr[7] <= ch7.req.adr;
always_ff @(posedge wclk) radrr[8] <= ld.cyc ? ld.adr : wchi.adr;
always_ff @(posedge wclk) wchi_adr1 <= wchi.adr;
always_ff @(posedge wclk) wchi_adr <= wchi_adr1;

always_ff @(posedge ch0.clk) if (ch0.rst) stb0 <= 1'b0; else if (ch0.req.cyc) stb0 <= ch0.req.cyc; else if (ack[0] || !load[0]) stb0 <= 1'b0;
always_ff @(posedge ch1.clk) if (ch1.rst) stb1 <= 1'b0; else if (ch1.req.cyc) stb1 <= ch1.req.cyc; else if (ack[1] || !load[1]) stb1 <= 1'b0;
always_ff @(posedge ch2.clk) if (ch2.rst) stb2 <= 1'b0; else if (ch2.req.cyc) stb2 <= ch2.req.cyc; else if (ack[2] || !load[2]) stb2 <= 1'b0;
always_ff @(posedge ch3.clk) if (ch3.rst) stb3 <= 1'b0; else if (ch3.req.cyc) stb3 <= ch3.req.cyc; else if (ack[3] || !load[3]) stb3 <= 1'b0;
always_ff @(posedge ch4.clk) if (ch4.rst) stb4 <= 1'b0; else if (ch4.req.cyc) stb4 <= ch4.req.cyc; else if (ack[4] || !load[4]) stb4 <= 1'b0;
always_ff @(posedge ch5.clk) if (ch5.rst) stb5 <= 1'b0; else if (ch5.req.cyc) stb5 <= ch5.req.cyc; else if (ack[5] || !load[5]) stb5 <= 1'b0;
always_ff @(posedge ch6.clk) if (ch6.rst) stb6 <= 1'b0; else if (ch6.req.cyc) stb6 <= ch6.req.cyc; else if (ack[6] || !load[6]) stb6 <= 1'b0;
always_ff @(posedge ch7.clk) if (ch7.rst) stb7 <= 1'b0; else if (ch7.req.cyc) stb7 <= ch7.req.cyc; else if (ack[7] || !load[7]) stb7 <= 1'b0;

always_ff @(posedge ch1.clk) if (ch1.rst) stb1a <= 1'b0; else stb1a <= stb1;

always_ff @(posedge wclk)
	rstb2 <= rstb;
always_ff @(posedge wclk)
	rstb3 <= rstb2;

always_ff @(posedge ch0.clk) if (ch0.rst) rstb[0] <= 1'b0; else if (ch0.req.cyc) rstb[0] <= ch0.req.cyc & ~ch0.req.we; else if (ack[0]) rstb[0] <= 1'b0;
always_ff @(posedge ch1.clk) if (ch1.rst) rstb[1] <= 1'b0; else if (ch1.req.cyc) rstb[1] <= ch1.req.cyc & ~ch1.req.we; else if (ack[1]) rstb[1] <= 1'b0;
always_ff @(posedge ch2.clk) if (ch2.rst) rstb[2] <= 1'b0; else if (ch2.req.cyc) rstb[2] <= ch2.req.cyc & ~ch2.req.we; else if (ack[2]) rstb[2] <= 1'b0;
always_ff @(posedge ch3.clk) if (ch3.rst) rstb[3] <= 1'b0; else if (ch3.req.cyc) rstb[3] <= ch3.req.cyc & ~ch3.req.we; else if (ack[3]) rstb[3] <= 1'b0;
always_ff @(posedge ch4.clk) if (ch4.rst) rstb[4] <= 1'b0; else if (ch4.req.cyc) rstb[4] <= ch4.req.cyc & ~ch4.req.we; else if (ack[4]) rstb[4] <= 1'b0;
always_ff @(posedge ch5.clk) if (ch5.rst) rstb[5] <= 1'b0; else if (ch5.req.cyc) rstb[5] <= ch5.req.cyc & ~ch5.req.we; else if (ack[5]) rstb[5] <= 1'b0;
always_ff @(posedge ch6.clk) if (ch6.rst) rstb[6] <= 1'b0; else if (ch6.req.cyc) rstb[6] <= ch6.req.cyc & ~ch6.req.we; else if (ack[6]) rstb[6] <= 1'b0;
always_ff @(posedge ch7.clk) if (ch7.rst) rstb[7] <= 1'b0; else if (ch7.req.cyc) rstb[7] <= ch7.req.cyc & ~ch7.req.we; else if (ack[7]) rstb[7] <= 1'b0;
/*
always_comb rstb[1] <= ch1.req.cyc & ~ch1.req.we;
always_comb rstb[2] <= ch2.req.cyc & ~ch2.req.we;
always_comb rstb[3] <= ch3.req.cyc & ~ch3.req.we;
always_comb rstb[4] <= ch4.req.cyc & ~ch4.req.we;
always_comb rstb[5] <= ch5.req.cyc & ~ch5.req.we;
always_comb rstb[6] <= ch6.req.cyc & ~ch6.req.we;
always_comb rstb[7] <= ch7.req.cyc & ~ch7.req.we;
always_comb rstb[8] <= ld.cyc ? ld.cyc : wchi.cyc;
*/
always_ff @(posedge wclk) wchi_stb_r <= wchi.cyc;
always_ff @(posedge wclk) wchi_stb <= wchi_stb_r;
always_ff @(posedge wclk) wchi_sel <= wchi.sel;
always_ff @(posedge wclk) wchi_dat <= wchi.data1;

reg [8:0] rclkp;
always_comb
begin
	rclkp[0] = ch0.clk;
	rclkp[1] = ch1.clk;
	rclkp[2] = ch2.clk;
	rclkp[3] = ch3.clk;
	rclkp[4] = ch4.clk;
	rclkp[5] = ch5.clk;
	rclkp[6] = ch6.clk;
	rclkp[7] = ch7.clk;
	rclkp[8] = wclk;
end

reg [HIBIT-LOBIT:0] radr [0:8];
always_ff @(posedge ch0.clk) if (rst1) radr[0] <= 32'd0; else if (ch0.req.cyc) radr[0] <= ch0.req.adr[HIBIT:LOBIT];
always_ff @(posedge ch1.clk) if (rst1) radr[1] <= 32'd0; else if (ch1.req.cyc) radr[1] <= ch1.req.adr[HIBIT:LOBIT];
always_ff @(posedge ch2.clk) if (rst1) radr[2] <= 32'd0; else if (ch2.req.cyc) radr[2] <= ch2.req.adr[HIBIT:LOBIT];
always_ff @(posedge ch3.clk) if (rst1) radr[3] <= 32'd0; else if (ch3.req.cyc) radr[3] <= ch3.req.adr[HIBIT:LOBIT];
always_ff @(posedge ch4.clk) if (rst1) radr[4] <= 32'd0; else if (ch4.req.cyc) radr[4] <= ch4.req.adr[HIBIT:LOBIT];
always_ff @(posedge ch5.clk) if (rst1) radr[5] <= 32'd0; else if (ch5.req.cyc) radr[5] <= ch5.req.adr[HIBIT:LOBIT];
always_ff @(posedge ch6.clk) if (rst1) radr[6] <= 32'd0; else if (ch6.req.cyc) radr[6] <= ch6.req.adr[HIBIT:LOBIT];
always_ff @(posedge ch7.clk) if (rst1) radr[7] <= 32'd0; else if (ch7.req.cyc) radr[7] <= ch7.req.adr[HIBIT:LOBIT];
always_comb
begin
	radr[8] = ld.cyc ? ld.adr[HIBIT:LOBIT] : wchi.adr[HIBIT:LOBIT];
end

always_ff @(posedge ch0.clk) if (rst1) hitv[0] <= FALSE; else if (ch0.req.cyc) hitv[0] <= TRUE; else if (ack[0]) hitv[0] <= FALSE;
always_ff @(posedge ch1.clk) if (rst1) hitv[1] <= FALSE; else if (ch1.req.cyc) hitv[1] <= TRUE; else if (ack[1]) hitv[1] <= FALSE;
always_ff @(posedge ch2.clk) if (rst1) hitv[2] <= FALSE; else if (ch2.req.cyc) hitv[2] <= TRUE; else if (ack[2]) hitv[2] <= FALSE;
always_ff @(posedge ch3.clk) if (rst1) hitv[3] <= FALSE; else if (ch3.req.cyc) hitv[3] <= TRUE; else if (ack[3]) hitv[3] <= FALSE;
always_ff @(posedge ch4.clk) if (rst1) hitv[4] <= FALSE; else if (ch4.req.cyc) hitv[4] <= TRUE; else if (ack[4]) hitv[4] <= FALSE;
always_ff @(posedge ch5.clk) if (rst1) hitv[5] <= FALSE; else if (ch5.req.cyc) hitv[5] <= TRUE; else if (ack[5]) hitv[5] <= FALSE;
always_ff @(posedge ch6.clk) if (rst1) hitv[6] <= FALSE; else if (ch6.req.cyc) hitv[6] <= TRUE; else if (ack[6]) hitv[6] <= FALSE;
always_ff @(posedge ch7.clk) if (rst1) hitv[7] <= FALSE; else if (ch7.req.cyc) hitv[7] <= TRUE; else if (ack[7]) hitv[7] <= FALSE;
always_ff @(posedge wclk) if (rst1) hitv[8] <= FALSE; else if (ld.cyc) hitv[8] <= TRUE; else if (ack[8]) hitv[8] <= FALSE;

   // xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2020.2

genvar gway,gport;

generate begin : gCacheRAM
	for (gport = 0; gport < 9; gport = gport + 1) begin
if (PORT_PRESENT[gport] || gport==8) begin
	xpm_memory_sdpram #(
		.ADDR_WIDTH_A($clog2(DEP)),
		.ADDR_WIDTH_B($clog2(DEP)),
		.AUTO_SLEEP_TIME(0),
		.BYTE_WRITE_WIDTH_A($bits(mpmc11_quad_cache_line_t)),
		.CASCADE_HEIGHT(0),
		.CLOCKING_MODE("independent_clock"), // String
		.ECC_MODE("no_ecc"),            // String
		.MEMORY_INIT_FILE("none"),      // String
		.MEMORY_INIT_PARAM("0"),        // String
		.MEMORY_OPTIMIZATION("true"),   // String
		.MEMORY_PRIMITIVE("block"),      // String
		.MEMORY_SIZE($bits(mpmc11_quad_cache_line_t)*DEP),         // DECIMAL
		.MESSAGE_CONTROL(0),            // DECIMAL
		.READ_DATA_WIDTH_B($bits(mpmc11_quad_cache_line_t)),         // DECIMAL
		.READ_LATENCY_B(1),
		.READ_RESET_VALUE_B("0"),       // String
		.RST_MODE_A("SYNC"),            // String
		.RST_MODE_B("SYNC"),            // String
		.SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
		.USE_EMBEDDED_CONSTRAINT(0),
		.USE_MEM_INIT(1),
		.WAKEUP_TIME("disable_sleep"),  // String
		.WRITE_DATA_WIDTH_A($bits(mpmc11_quad_cache_line_t)),        // DECIMAL
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

		.clkb(wclk),//rclkp[gport]),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
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
end
endgenerate				
				
genvar g;
generate begin : gReaddat
	for (g = 0; g < CACHE_ASSOC; g = g + 1) begin
		always_comb vbito0a[g] = vbit[g][radrr[0][HIBIT:LOBIT]];
		always_comb vbito1a[g] = vbit[g][radrr[1][HIBIT:LOBIT]];
		always_comb vbito2a[g] = vbit[g][radrr[2][HIBIT:LOBIT]];
		always_comb vbito3a[g] = vbit[g][radrr[3][HIBIT:LOBIT]];
		always_comb vbito4a[g] = vbit[g][radrr[4][HIBIT:LOBIT]];
		always_comb vbito5a[g] = vbit[g][radrr[5][HIBIT:LOBIT]];
		always_comb vbito6a[g] = vbit[g][radrr[6][HIBIT:LOBIT]];
		always_comb vbito7a[g] = vbit[g][radrr[7][HIBIT:LOBIT]];
		always_comb vbito8a[g] = vbit[g][radrr[8][HIBIT:LOBIT]];
		
		always_ff @(posedge ch0.clk)	if (rst1) hit0a[g] <= FALSE; else hit0a[g] <= (doutb[0].lines[g].tag==radrr[0][31:TAGLOBIT]) && (vbito0a[g]==1'b1) && hitv[0];
		always_ff @(posedge ch1.clk)	if (rst1) hit1a[g] <= FALSE; else hit1a[g] <= (doutb[1].lines[g].tag==radrr[1][31:TAGLOBIT]) && (vbito1a[g]==1'b1) && hitv[1];// && !(stb1 && !stb1a);
		always_ff @(posedge ch2.clk)	if (rst1) hit2a[g] <= FALSE; else hit2a[g] <= (doutb[2].lines[g].tag==radrr[2][31:TAGLOBIT]) && (vbito2a[g]==1'b1) && hitv[2];
		always_ff @(posedge ch3.clk)	if (rst1) hit3a[g] <= FALSE; else hit3a[g] <= (doutb[3].lines[g].tag==radrr[3][31:TAGLOBIT]) && (vbito3a[g]==1'b1) && hitv[3];
		always_ff @(posedge ch4.clk)	if (rst1) hit4a[g] <= FALSE; else hit4a[g] <= (doutb[4].lines[g].tag==radrr[4][31:TAGLOBIT]) && (vbito4a[g]==1'b1) && hitv[4];
		always_ff @(posedge ch5.clk)	if (rst1) hit5a[g] <= FALSE; else hit5a[g] <= (doutb[5].lines[g].tag==radrr[5][31:TAGLOBIT]) && (vbito5a[g]==1'b1) && hitv[5];
		always_ff @(posedge ch6.clk)	if (rst1) hit6a[g] <= FALSE; else hit6a[g] <= (doutb[6].lines[g].tag==radrr[6][31:TAGLOBIT]) && (vbito6a[g]==1'b1) && hitv[6];
		always_ff @(posedge ch7.clk)	if (rst1) hit7a[g] <= FALSE; else hit7a[g] <= (doutb[7].lines[g].tag==radrr[7][31:TAGLOBIT]) && (vbito7a[g]==1'b1) && hitv[7];
		always_ff @(posedge wclk)	if (rst1) hit8a[g] <= FALSE; else hit8a[g] <= (doutb[8].lines[g].tag==radrr[8][31:TAGLOBIT]) && (vbito8a[g]==1'b1) && hitv[8];
	end
	always_comb
	begin
		ch0.resp.stall = 1'b0;
		ch0.resp.next = 1'b0;
		ch0.resp.pri = 4'd7;
		ch0.resp.ctag = 1'b0;
//		ch0.resp.adr = ch0.req.adr;
	end
end
endgenerate

always_comb ch0hit = |hit0a & stb0;
always_comb ch1hit = |hit1a & stb1;
always_comb ch2hit = |hit2a & stb2;
always_comb ch3hit = |hit3a & stb3;
always_comb ch4hit = |hit4a & stb4;
always_comb ch5hit = |hit5a & stb5;
always_comb ch6hit = |hit6a & stb6;
always_comb ch7hit = |hit7a & stb7;

always_comb ch0.resp.tid = rtid[0];
always_comb ch1.resp.tid = rtid[1];
always_comb ch2.resp.tid = rtid[2];
always_comb ch3.resp.tid = rtid[3];
always_comb ch4.resp.tid = rtid[4];
always_comb ch5.resp.tid = rtid[5];
always_comb ch6.resp.tid = rtid[6];
always_comb ch7.resp.tid = rtid[7];
always_comb ch0.resp.err = fta_bus_pkg::OKAY;
always_comb ch1.resp.err = fta_bus_pkg::OKAY;
always_comb ch2.resp.err = fta_bus_pkg::OKAY;
always_comb ch3.resp.err = fta_bus_pkg::OKAY;
always_comb ch4.resp.err = fta_bus_pkg::OKAY;
always_comb ch5.resp.err = fta_bus_pkg::OKAY;
always_comb ch6.resp.err = fta_bus_pkg::OKAY;
always_comb ch7.resp.err = fta_bus_pkg::OKAY;
always_comb ch0.resp.rty = 1'b0;//(stb0 & to) | (rstb[0] & ~ch0hit & ~ch0.req.we);
always_comb ch1.resp.rty = 1'b0;//(stb1 & to) | (rstb[1] & ~ch1hit & ~ch1.req.we);
always_comb ch2.resp.rty = 1'b0;//stb2 & to;
always_comb ch3.resp.rty = 1'b0;//stb3 & to;
always_comb ch4.resp.rty = 1'b0;//stb4 & to;
always_comb ch5.resp.rty = 1'b0;//stb5 & to;
always_comb ch6.resp.rty = 1'b0;//stb6 & to;
always_comb ch7.resp.rty = 1'b0;//(stb7 & to) | (rstb[7] & ~ch7hit & ~ch7.req.we);

// Ack pulses for only one clock cycle of the request's clock.
always_ff @(posedge ch0.clk) if (rst1) ack[0] <= 1'b0; else ack[0] <= ((|hit0a && stb0 && load[0]) | (ch0wack & stb0)) & ~ack[0] & ~ack1[0] & ~ack2[0];
always_ff @(posedge ch1.clk) if (rst1) ack[1] <= 1'b0; else ack[1] <= ((|hit1a && stb1 && load[1]) | (ch1wack & stb1)) & ~ack[1] & ~ack1[1] & ~ack2[1];
always_ff @(posedge ch2.clk) if (rst1) ack[2] <= 1'b0; else ack[2] <= ((|hit2a && stb2 && load[2]) | (ch2wack & stb2)) & ~ack[2] & ~ack1[2] & ~ack2[2];
always_ff @(posedge ch3.clk) if (rst1) ack[3] <= 1'b0; else ack[3] <= ((|hit3a && stb3 && load[3]) | (ch3wack & stb3)) & ~ack[3] & ~ack1[3] & ~ack2[3];
always_ff @(posedge ch4.clk) if (rst1) ack[4] <= 1'b0; else ack[4] <= ((|hit4a && stb4 && load[4]) | (ch4wack & stb4)) & ~ack[4] & ~ack1[4] & ~ack2[4];
always_ff @(posedge ch5.clk) if (rst1) ack[5] <= 1'b0; else ack[5] <= ((|hit5a && stb5 && load[5]) | (ch5wack & stb5)) & ~ack[5] & ~ack1[5] & ~ack2[5];
always_ff @(posedge ch6.clk) if (rst1) ack[6] <= 1'b0; else ack[6] <= ((|hit6a && stb6 && load[6]) | (ch6wack & stb6)) & ~ack[6] & ~ack1[6] & ~ack2[6];
always_ff @(posedge ch7.clk) if (rst1) ack[7] <= 1'b0; else ack[7] <= ((|hit7a && stb7 && load[7]) | (ch7wack & stb7)) & ~ack[7] & ~ack1[7] & ~ack2[7];

always_ff @(posedge ch0.clk) if (rst1) begin ack1[0] <= 1'b0; ack2[0] <= 1'b0; end else begin ack1[0] <= ack[0]; ack2[0] <= ack1[0]; end
always_ff @(posedge ch1.clk) if (rst1) begin ack1[1] <= 1'b0; ack2[1] <= 1'b0; end else begin ack1[1] <= ack[1]; ack2[1] <= ack1[1]; end
always_ff @(posedge ch2.clk) if (rst1) begin ack1[2] <= 1'b0; ack2[2] <= 1'b0; end else begin ack1[2] <= ack[2]; ack2[2] <= ack1[2]; end
always_ff @(posedge ch3.clk) if (rst1) begin ack1[3] <= 1'b0; ack2[3] <= 1'b0; end else begin ack1[3] <= ack[3]; ack2[3] <= ack1[3]; end
always_ff @(posedge ch4.clk) if (rst1) begin ack1[4] <= 1'b0; ack2[4] <= 1'b0; end else begin ack1[4] <= ack[4]; ack2[4] <= ack1[4]; end
always_ff @(posedge ch5.clk) if (rst1) begin ack1[5] <= 1'b0; ack2[5] <= 1'b0; end else begin ack1[5] <= ack[5]; ack2[5] <= ack1[5]; end
always_ff @(posedge ch6.clk) if (rst1) begin ack1[6] <= 1'b0; ack2[6] <= 1'b0; end else begin ack1[6] <= ack[6]; ack2[6] <= ack1[6]; end
always_ff @(posedge ch7.clk) if (rst1) begin ack1[7] <= 1'b0; ack2[7] <= 1'b0; end else begin ack1[7] <= ack[7]; ack2[7] <= ack1[7]; end

always_comb ch0.resp.ack = ack[0];
always_comb ch1.resp.ack = ack[1];
always_comb ch2.resp.ack = ack[2];
always_comb ch3.resp.ack = ack[3];
always_comb ch4.resp.ack = ack[4];
always_comb ch5.resp.ack = ack[5];
always_comb ch6.resp.ack = ack[6];
always_comb ch7.resp.ack = ack[7];

always_ff @(posedge wclk)
if (rst1) begin
	rstb4 <= 8'h00;
	miss <= 1000'd0;
	miss.bte <= fta_bus_pkg::LINEAR;
	miss.cti <= fta_bus_pkg::CLASSIC;
	miss.cmd <= fta_bus_pkg::CMD_LOAD;
	miss.blen <= 6'd0;
	miss.we <= 1'b0;
	miss.sel = {32{1'b1}};
end
else begin
	miss.cyc <= LOW;
	if (rstb3[0] & ~rstb4[0] & ~ch0hit & ~ch0.req.we) begin
		rstb4[0] <= 1'b1;
		miss.cyc <= HIGH;
		miss.tid <= rtid[0];
		miss.adr <= radrr[0];
	end
	else if (rstb[1] & ~rstb4[1] & ~ch1hit & ~ch1.req.we) begin
		rstb4[1] <= 1'b1;
		miss.cyc <= HIGH;
		miss.tid <= rtid[1];
		miss.adr <= radrr[1];
	end
	else if (rstb[2] & ~rstb4[2] & ~ch2hit & ~ch2.req.we) begin
		rstb4[2] <= 1'b1;
		miss.cyc <= HIGH;
		miss.tid <= rtid[2];
		miss.adr <= radrr[2];
	end
	else if (rstb[3] & ~rstb4[3] & ~ch3hit & ~ch3.req.we) begin
		rstb4[3] <= 1'b1;
		miss.cyc <= HIGH;
		miss.tid <= rtid[3];
		miss.adr <= radrr[3];
	end
	else if (rstb[6] & ~rstb4[6] & ~ch6hit & ~ch6.req.we) begin
		rstb4[6] <= 1'b1;
		miss.cyc <= HIGH;
		miss.tid <= rtid[6];
		miss.adr <= radrr[6];
	end
	else if (rstb[7] & ~rstb4[7] & ~ch7hit & ~ch7.req.we) begin
		rstb4[7] <= 1'b1;
		miss.cyc <= HIGH;
		miss.tid <= rtid[7];
		miss.adr <= radrr[7];
	end
	if (ch0hit) rstb4[0] <= 1'b0;
	if (ch1hit) rstb4[1] <= 1'b0;
	if (ch2hit) rstb4[2] <= 1'b0;
	if (ch3hit) rstb4[3] <= 1'b0;
	if (ch6hit) rstb4[6] <= 1'b0;
	if (ch7hit) rstb4[7] <= 1'b0;
end

always_comb wway = hit8a[0] ? 2'd0 : hit8a[1] ? 2'd1 : hit8a[2] ? 2'd2 : hit8a[3] ? 2'd3 : 2'd0;

always_comb
begin
	ch0.resp.dat <= 256'd0;
	ch1.resp.dat <= 256'd0;
	ch2.resp.dat <= 256'd0;
	ch3.resp.dat <= 256'd0;
	ch4.resp.dat <= 256'd0;
	ch5.resp.dat <= 256'd0;
	ch6.resp.dat <= 256'd0;
	ch7.resp.dat <= 256'd0;
	wrdata <= 256'd0;
	for (n2 = 0; n2 < CACHE_ASSOC; n2 = n2 + 1) begin
		if (hit0a[n2]) ch0.resp.dat <= doutb[0].lines[n2].data;
		if (hit1a[n2]) ch1.resp.dat <= doutb[1].lines[n2].data;
		if (hit2a[n2]) ch2.resp.dat <= doutb[2].lines[n2].data;
		if (hit3a[n2]) ch3.resp.dat <= doutb[3].lines[n2].data;
		if (hit4a[n2]) ch4.resp.dat <= doutb[4].lines[n2].data;
		if (hit5a[n2]) ch5.resp.dat <= doutb[5].lines[n2].data;
		if (hit6a[n2]) ch6.resp.dat <= doutb[6].lines[n2].data;
		if (hit7a[n2]) ch7.resp.dat <= doutb[7].lines[n2].data;
		if (hit8a[n2]) wrdata <= doutb[8].lines[n2].data;
	end
//	if (|hit8a)
end

reg b0,b1,b2;
reg ldcycd1,ldcycd2,ldcycd3;
always_ff @(posedge wclk)
	ldcycd1 <= ld.cyc;
always_ff @(posedge wclk)
	ldcycd2 <= ldcycd1;
always_ff @(posedge wclk)
	ldcycd3 <= ldcycd2;

// These signals registered to improve timing.
reg wchi_vbit,inv1;
always_ff @(posedge wclk)
	wchi_vbit <= |hit8a & |wchi_sel & wchi_stb & wchi.we & ~(ld.cyc|ldcycd1|ldcycd2|ldcycd3);
always_ff @(posedge wclk)
	inv1 <= inv;

always_ff @(posedge wclk)
if (rst1) begin
	vbit[0][wadr2[HIBIT:LOBIT]] <= 'b0;	
	vbit[1][wadr2[HIBIT:LOBIT]] <= 'b0;
	vbit[2][wadr2[HIBIT:LOBIT]] <= 'b0;	
	vbit[3][wadr2[HIBIT:LOBIT]] <= 'b0;	
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
	if (wchi_vbit)
		vbit[wway][wadr[HIBIT:LOBIT]] <= 1'b1;
	else if (inv1)
		vbit[wway][wadr[HIBIT:LOBIT]] <= 1'b0;
end

// Update the cache only if there was a write hit or if loading the cache line
// due to a read miss. For a read miss the entire line is updated, otherwise
// just the part of the line relevant to the write is updated.
always_ff @(posedge wclk)
begin
	if (ld.cyc)
		wadr <= ld.adr;
	else if (wchi.cyc)
		wadr <= wchi.adr;
end
// wadr2 is used to reset the cache tags during reset. Reset must be held for
// 1024 cycles to reset all the tags.
always_ff @(posedge wclk)
if (rst) begin
	rst1 <= 1'b1;
	wadr2 <= 32'h0;
end
else begin
	if (wadr2 >= 32'h08000 || SIM)
		rst1 <= 1'b0;
	if (rst1)
		wadr2 <= wadr2 + (32'd1 << LOBIT);
	else if (ld.cyc)
		wadr2 <= wadr;
end
always_ff @(posedge wclk)
	lddat1 <= ld.data1;
always_ff @(posedge wclk)
	lddat2 <= lddat1;
always_ff @(posedge wclk)
	wstrb <= ldcycd2 | (wchi_stb & |hit8a & wchi.we);
	
// Merge write data into cache line.
// For a load due to a read miss the entire line is updated.
// For a write hit, just the portion of the line corresponding to the hit is
// updated.
reg [16:0] t0,t1,t2;
reg m0,m1,m2;
generate begin : gWrData
	// LRU update
	always_ff @(posedge wclk)
	begin
		if (ldcycd2) begin
			wdata.lines[0].tag <= wadr2[31:TAGLOBIT];			// set tag
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
	for (g = 0; g < 32; g = g + 1)
	always_ff @(posedge wclk)
		begin
			if (ldcycd2) begin
	//			wdata <= wrdata << $bits(mpmc11_cache_line_t);
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
if (rst1)
	wack <= 1'b0;
else begin
	wack <= 1'b0;
	if (wchi_stb & ~ld.cyc & wchi.we)
		wack <= 1'b1;
end
assign wcho.ack = wack & wchi.cyc;

endmodule
