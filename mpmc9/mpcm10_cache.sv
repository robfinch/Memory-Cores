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
import mpmc10_pkg::*;

module mpmc10_cache(rst, wclk, wr, wway, wadr, wdat, inv,
	rclk0, radr0, rdat0, hit0,
	rclk1, radr1, rdat1, hit1,
	rclk2, radr2, rdat2, hit2,
	rclk3, radr3, rdat3, hit3,
	rclk4, radr4, rdat4, hit4,
	rclk5, radr5, rdat5, hit5,
	rclk6, radr6, rdat6, hit6,
	rclk7, radr7, rdat7, hit7
);
input rst;
input wclk;
input [31:0] wr;
input [31:0] wadr;
input [2:0] wway;
input mpmc9_cache_line_t wdat;
input inv;
input rclk0;
input [31:0] radr0;
output mpmc9_cache_line_t rdat0;
output reg hit0;
input rclk1;
input [31:0] radr1;
output mpmc9_cache_line_t rdat1;
output reg hit1;
input rclk2;
input [31:0] radr2;
output mpmc9_cache_line_t rdat2;
output reg hit2;
input rclk3;
input [31:0] radr3;
output mpmc9_cache_line_t rdat3;
output reg hit3;
input rclk4;
input [31:0] radr4;
output mpmc9_cache_line_t rdat4;
output reg hit4;
input rclk5;
input [31:0] radr5;
output mpmc9_cache_line_t rdat5;
output reg hit5;
input rclk6;
input [31:0] radr6;
output mpmc9_cache_line_t rdat6;
output reg hit6;
input rclk7;
input [31:0] radr7;
output mpmc9_cache_line_t rdat7;
output reg hit7;

integer n;

(* ram_style="distributed" *)
reg [127:0] vbit [0:CACHE_ASSOC-1];

reg [31:0] radrr0;
reg [31:0] radrr1;
reg [31:0] radrr2;
reg [31:0] radrr3;
reg [31:0] radrr4;
reg [31:0] radrr5;
reg [31:0] radrr6;
reg [31:0] radrr7;

reg [35:0] wea;
always_comb
begin
	wea[31:0] = wr[31:0];
	wea[35:32] = {4{|wr[31:0]}};
end

mpmc9_cache_line_t doutb [0:7][0:7];

reg vbito0a [0:7];
reg vbito1a [0:7];
reg vbito2a [0:7];
reg vbito3a [0:7];
reg vbito4a [0:7];
reg vbito5a [0:7];
reg vbito6a [0:7];
reg vbito7a [0:7];

reg [7:0] hit0a;
reg [7:0] hit1a;
reg [7:0] hit2a;
reg [7:0] hit3a;
reg [7:0] hit4a;
reg [7:0] hit5a;
reg [7:0] hit6a;
reg [7:0] hit7a;

always_ff @(posedge rclk0)
	radrr0 <= radr0;
always_ff @(posedge rclk1)
	radrr1 <= radr1;
always_ff @(posedge rclk2)
	radrr2 <= radr2;
always_ff @(posedge rclk3)
	radrr3 <= radr3;
always_ff @(posedge rclk4)
	radrr4 <= radr4;
always_ff @(posedge rclk5)
	radrr5 <= radr5;
always_ff @(posedge rclk6)
	radrr6 <= radr6;
always_ff @(posedge rclk7)
	radrr7 <= radr7;

reg [7:0] rclkp;
always_comb
begin
	rclkp[0] = rclk0;
	rclkp[1] = rclk1;
	rclkp[2] = rclk2;
	rclkp[3] = rclk3;
	rclkp[4] = rclk4;
	rclkp[5] = rclk5;
	rclkp[6] = rclk6;
	rclkp[7] = rclk7;
end

reg [31:0] radr [0:7];
always_comb
begin
	radr[0] = radr0;
	radr[1] = radr1;
	radr[2] = radr2;
	radr[3] = radr3;
	radr[4] = radr4;
	radr[5] = radr5;
	radr[6] = radr6;
	radr[7] = radr7;
end

   // xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2020.2

genvar gway,gport;

generate begin : gCacheRAM
	for (gport = 0; gport < 8; gport = gport + 1)
		for (gway = 0; gway < CACHE_ASSOC; gway = gway + 1)
   xpm_memory_sdpram #(
      .ADDR_WIDTH_A(7),               // DECIMAL
      .ADDR_WIDTH_B(7),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(8),        // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("independent_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("block"),      // String
      .MEMORY_SIZE($bits(mpmc9_cache_line_t)*128),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B($bits(mpmc9_cache_line_t)),         // DECIMAL
      .READ_LATENCY_B(1),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A($bits(mpmc9_cache_line_t)),        // DECIMAL
      .WRITE_MODE_B("no_change")      // String
   )
   xpm_memory_sdpram_inst (
      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(doutb[gport][gway]),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(wadr),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb(radr[gport]),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(wclk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(rclkp[gport]),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(wdat),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(|wr & wway==gway),          // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when write operations are initiated. Pipelined internally.

      .enb(1'b1),                      // 1-bit input: Memory enable signal for port B. Must be high on clock
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
      .wea(wea)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );
end
endgenerate				
				
genvar g;
generate begin : gReaddat
	for (g = 0; g < CACHE_ASSOC; g = g + 1) begin
		always_ff @(posedge rclk0) vbito0a[g] <= vbit[g][radrr0[15:6]];
		always_ff @(posedge rclk1) vbito1a[g] <= vbit[g][radrr1[15:6]];
		always_ff @(posedge rclk2) vbito2a[g] <= vbit[g][radrr2[15:6]];
		always_ff @(posedge rclk3) vbito3a[g] <= vbit[g][radrr3[15:6]];
		always_ff @(posedge rclk4) vbito4a[g] <= vbit[g][radrr4[15:6]];
		always_ff @(posedge rclk5) vbito5a[g] <= vbit[g][radrr5[15:6]];
		always_ff @(posedge rclk6) vbito6a[g] <= vbit[g][radrr6[15:6]];
		always_ff @(posedge rclk7) vbito7a[g] <= vbit[g][radrr7[15:6]];
		
		always_comb	hit0a[g] = (doutb[0][g].tag==radrr0[31:13]) && (vbito0a[g]==1'b1);
		always_comb	hit1a[g] = (doutb[1][g].tag==radrr1[31:13]) && (vbito1a[g]==1'b1);
		always_comb	hit2a[g] = (doutb[2][g].tag==radrr2[31:13]) && (vbito2a[g]==1'b1);
		always_comb	hit3a[g] = (doutb[3][g].tag==radrr3[31:13]) && (vbito3a[g]==1'b1);
		always_comb	hit4a[g] = (doutb[4][g].tag==radrr4[31:13]) && (vbito4a[g]==1'b1);
		always_comb	hit5a[g] = (doutb[5][g].tag==radrr5[31:13]) && (vbito5a[g]==1'b1);
		always_comb	hit6a[g] = (doutb[6][g].tag==radrr6[31:13]) && (vbito6a[g]==1'b1);
		always_comb	hit7a[g] = (doutb[7][g].tag==radrr7[31:13]) && (vbito7a[g]==1'b1);
			
		always_comb if (hit0a[g]) rdat0 = doutb[0][g];
		always_comb if (hit1a[g]) rdat1 = doutb[1][g];
		always_comb if (hit2a[g]) rdat2 = doutb[2][g];
		always_comb if (hit3a[g]) rdat3 = doutb[3][g];
		always_comb if (hit4a[g]) rdat4 = doutb[4][g];
		always_comb if (hit5a[g]) rdat5 = doutb[5][g];
		always_comb if (hit6a[g]) rdat6 = doutb[6][g];
		always_comb if (hit7a[g]) rdat7 = doutb[7][g];
	end
end
endgenerate

always_ff @(posedge wclk)
if (rst) begin
	for (n = 0; n < 8; n = n + 1)
		vbit[n] <= 'b0;	
end
else begin
	if (wr)
		vbit[wway][wadr[15:6]] <= 1'b1;
	else if (inv)
		vbit[wway][wadr[15:6]] <= 1'b0;
end

always_comb
	hit0 = |hit0a;
always_comb
	hit1 = |hit1a;
always_comb
	hit2 = |hit2a;
always_comb
	hit3 = |hit3a;
always_comb
	hit4 = |hit4a;
always_comb
	hit5 = |hit5a;
always_comb
	hit6 = |hit6a;
always_comb
	hit7 = |hit7a;

endmodule
