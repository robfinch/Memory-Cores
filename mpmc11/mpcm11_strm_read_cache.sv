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
// ============================================================================
//
import const_pkg::*;
import mpmc11_pkg::*;

module mpmc11_strm_read_cache(rst, wclk, wr, wadr, wdat, inv,
	rclk, req, resp, hit
);
input rst;
input wclk;
input wr;
input [31:0] wadr;
input [WIDX8-1:0] wdat;
input inv;
input rclk;
input fta_cmd_request256_t req;
output fta_cmd_response256_t resp;
output reg hit;

reg [WIDX8-1:0] rdat;
reg rd;
fta_cmd_request256_t reqh;
reg [31:0] radr;

// Latch incoming request until a hit is detected.
always_ff @(posedge rclk)
begin
	resp.ack <= FALSE;
	if (req.cyc) begin
		reqh <= req;
		resp.tid <= req.tid;
		resp.adr <= req.padr;
		rd <= req.cyc & ~req.we;
	end
	else if (hit) begin
		reqh <= {$bits(fta_cmd_request256_t){1'b0}};
		rd <= FALSE;
		resp.ack <= reqh.cyc;
		resp.dat <= rdat;
	end
end

always_comb radr = {reqh.padr[31:5],5'h0};

(* ram_style="distributed" *)
reg [17:0] tags [0:7];
(* ram_style="distributed" *)
reg [7:0] vbit = 'b0;
reg [31:0] radrr;
reg [17:0] tago;
reg vbito;

xpm_memory_sdpram #(
  .ADDR_WIDTH_A(9),               // DECIMAL
  .ADDR_WIDTH_B(9),               // DECIMAL
  .AUTO_SLEEP_TIME(0),            // DECIMAL
  .BYTE_WRITE_WIDTH_A(WIDX8),        // DECIMAL
  .CASCADE_HEIGHT(0),             // DECIMAL
  .CLOCKING_MODE("independent_clock"), // String
  .ECC_MODE("no_ecc"),            // String
  .MEMORY_INIT_FILE("none"),      // String
  .MEMORY_INIT_PARAM("0"),        // String
  .MEMORY_OPTIMIZATION("true"),   // String
  .MEMORY_PRIMITIVE("block"),      // String
  .MEMORY_SIZE(512*WIDX8),             // DECIMAL
  .MESSAGE_CONTROL(0),            // DECIMAL
  .READ_DATA_WIDTH_B(WIDX8),         // DECIMAL
  .READ_LATENCY_B(1),             // DECIMAL
  .READ_RESET_VALUE_B("0"),       // String
  .RST_MODE_A("SYNC"),            // String
  .RST_MODE_B("SYNC"),            // String
  .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
  .USE_MEM_INIT(1),               // DECIMAL
  .WAKEUP_TIME("disable_sleep"),  // String
  .WRITE_DATA_WIDTH_A(WIDX8),        // DECIMAL
  .WRITE_MODE_B("no_change")      // String
)
xpm_memory_sdpram_inst (
  .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                   // on the data output of port B.

  .doutb(rdat),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
  .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                   // on the data output of port B.

  .addra(wadr[13:5]),        				// ADDR_WIDTH_A-bit input: Address for port A write operations.
  .addrb(radr[13:5]),             // ADDR_WIDTH_B-bit input: Address for port B read operations.
  .clka(wclk),                 // 1-bit input: Clock signal for port A. Also clocks port B when
                                   // parameter CLOCKING_MODE is "common_clock".

  .clkb(rclk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                   // "independent_clock". Unused when parameter CLOCKING_MODE is
                                   // "common_clock".

  .dina(wdat),                // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
  .ena(wr),          					// 1-bit input: Memory enable signal for port A. Must be high on clock
                                   // cycles when write operations are initiated. Pipelined internally.

  .enb(rd),                    // 1-bit input: Memory enable signal for port B. Must be high on clock
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
  .wea(wr)                     	// WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                   // for port A input data port dina. 1 bit wide when word-wide writes are
                                   // used. In byte-wide write configurations, each bit controls the
                                   // writing one byte of dina to address addra. For example, to
                                   // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                   // is 32, wea would be 4'b0010.

);

always_ff @(posedge rclk)
	radrr <= radr;
always_ff @(posedge wclk)
	if (wr && wadr[10:5]==6'h3F)
		tags[wadr[13:11]] <= wadr[31:14];
always_comb
	tago <= tags[radrr[13:11]];
always_comb // @(posedge rclk)
	vbito <= vbit[radrr[13:11]];
always_ff @(posedge wclk)
if (rst)
	vbit[wadr[13:11]] <= 'b0;
else begin
	if (wr && wadr[10:5]==6'h3F)
		vbit[wadr[13:11]] <= 1'b1;
	else if (inv)
		vbit[wadr[13:11]] <= 1'b0;
end
always_comb
	hit = (tago==radrr[31:14]) && (vbito==1'b1);

endmodule
