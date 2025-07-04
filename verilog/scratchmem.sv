// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2025  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
module scratchmem(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o);
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [3:0] sel_i;
input [31:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;

integer n;

wire cs = cyc_i && stb_i && cs_i;
wire clka = clk_i;
wire clkb = clk_i;
wire [14:0] addra = adr_i[16:2];
wire [14:0] addrb = adr_i[16:2];
wire [31:0] dina = dat_i;
wire [31:0] doutb;
reg ena;
reg enb;
reg [3:0] wea;

always_ff @(posedge clk_i)
	ena <= cs;
always_ff @(posedge clk_i)
	enb <= cs;
always_ff @(posedge clk_i)
	wea <= {4{cs & we_i}} & sel_i;

reg rdy,rdy1,rdy2;
always_ff @(posedge clk_i)
begin
	rdy1 <= cs;
	rdy2 <= rdy1 & cs;
	rdy <= rdy2 & rdy1 & cs;
end
assign ack_o = cs ? (we_i ? rdy : rdy) : 1'b0;

always_ff @(posedge clk_i)
if (rst_i)
	dat_o <= 32'd0;
else begin
	if (cs)
		dat_o <= doutb;
	else
		dat_o <= 32'd0;
end

   // xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2025.1

   xpm_memory_sdpram #(
      .ADDR_WIDTH_A(15),              // DECIMAL
      .ADDR_WIDTH_B(15),              // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(8),         // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_BIT_RANGE("7:0"),          // String
      .ECC_MODE("no_ecc"),            // String
      .ECC_TYPE("none"),              // String
      .IGNORE_INIT_SYNTH(0),          // DECIMAL
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String
      .MEMORY_SIZE(131072*8),         // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .RAM_DECOMP("auto"),            // String
      .READ_DATA_WIDTH_B(32),         // DECIMAL
      .READ_LATENCY_B(1),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .USE_MEM_INIT_MMI(0),           // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(32),        // DECIMAL
      .WRITE_MODE_B("no_change"),     // String
      .WRITE_PROTECT(1)               // DECIMAL
   )
   xpm_memory_sdpram_inst (
      .dbiterrb(),        				     // 1-bit output: Status signal to indicate double bit error occurrence on the data output of port B.
      .doutb(doutb),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(), 				            // 1-bit output: Status signal to indicate single bit error occurrence on the data output of port B.
      .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(clka),                     // 1-bit input: Clock signal for port A. Also clocks port B when parameter CLOCKING_MODE is "common_clock".
      .clkb(clkb),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is "independent_clock". Unused when
      .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock cycles when write operations are
      .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock cycles when read operations are
      .injectdbiterra(1'b0),					 // 1-bit input: Controls double bit error injection on input data when ECC enabled (Error injection capability
      .injectsbiterra(1'b0), 					// 1-bit input: Controls single bit error injection on input data when ECC enabled (Error injection capability
      .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output data path.
      .rstb(1'b0),                     // 1-bit input: Reset signal for the final port B output register stage. Synchronously resets output port
      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(wea)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector for port A input data port dina. 1 bit
   );

				
always_ff @(posedge clk_i)
	if (cs & we_i)
		$display ("wrote to scratchmem: %h=%h", addra, dina);

always_ff @(posedge clk_i)
	if (cs & ~we_i)
		$display("read from scratchmem: %h=%h", addrb, doutb);

endmodule
