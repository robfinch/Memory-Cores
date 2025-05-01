// ============================================================================
//        __
//   \\__/ o\    (C) 2022-2024  Robert Finch, Waterloo
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
// mem_access_counter:
//	- check priv level and key for accessibility
//	- count the number of accesses to a page of memory.
//
// 431 LUTs / 1733 FFs / 32 BRAMS (for 8192 entries (DRAM)).
// 424 LUTs / 1719 FFs / 2 BRAMS (for 64 entries (IO)). 
// ============================================================================

import fta_bus_pkg::*;

module mem_gate(rst, clk, age, cs, fta_req_i, fta_resp_o, fta_req_o, fta_resp_i);
parameter SIZE=8192;	// number of 64kB pages
parameter FUNC=3'd0;
input rst;
input clk;
input age;
input cs;
input fta_cmd_request128_t fta_req_i;
output fta_cmd_response128_t fta_resp_o;
output fta_cmd_request128_t fta_req_o;
input fta_cmd_response128_t fta_resp_i;

parameter IO_ADDR = 32'hFEF80001;	//32'hFEFC0001;
parameter IO_ADDR_MASK = 32'h00FE0000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd15;
parameter CFG_FUNC = FUNC;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'd1;
parameter CFG_SUBCLASS = 8'h00;					// 00 = RAM
parameter CFG_CLASS = 8'h05;						// 05 = memory controller
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'hFF;

localparam CFG_HEADER_TYPE = 8'h00;			// 00 = a general device

integer n;
reg csb;							// core select - gateway
reg cs_config1,cs_config2;
wire clka = clk;
wire clkb = clk;
wire ena = 1'b1;
wire enb = 1'b1;
reg [8191:0] gate;		// gates 16 bits in a asid
initial begin
	for (n = 0; n < 8192; n = n + 1)
		gate[n] = 1'b0;
end
reg gate_open;
reg [15:0] tid_ndx;
reg [27:0] tmp;
reg [16:0] iadr;
reg cs1,cs2,cs3,csb1,csb2;
reg [15:0] addra, addra1;
reg [15:0] addrb, addrb2, addrb3;
reg [127:0] doutb;
reg [127:0] dina;
reg wea0, wea1, wea2, wea3;
reg m;
wire rstb = rst;
reg cs_config;
fta_cmd_request128_t fta1, fta2, fta3;
fta_cmd_response128_t fta_resp1, fta_resp2;

always_ff @(posedge clk)
	cs_config1 <= fta_req_i.cyc && fta_req_i.stb &&
		fta_req_i.padr[31:28]==4'hD &&
		fta_req_i.padr[27:20]==CFG_BUS &&
		fta_req_i.padr[19:15]==CFG_DEVICE &&
		fta_req_i.padr[14:12]==CFG_FUNC;

always_comb
	csb <= cs_gt && fta1.cyc && fta1.stb;

pci128_config #(
	.CFG_BUS(CFG_BUS),
	.CFG_DEVICE(CFG_DEVICE),
	.CFG_FUNC(CFG_FUNC),
	.CFG_VENDOR_ID(CFG_VENDOR_ID),
	.CFG_DEVICE_ID(CFG_DEVICE_ID),
	.CFG_BAR0(IO_ADDR),
	.CFG_BAR0_MASK(IO_ADDR_MASK),
	.CFG_SUBSYSTEM_VENDOR_ID(CFG_SUBSYSTEM_VENDOR_ID),
	.CFG_SUBSYSTEM_ID(CFG_SUBSYSTEM_ID),
	.CFG_ROM_ADDR(CFG_ROM_ADDR),
	.CFG_REVISION_ID(CFG_REVISION_ID),
	.CFG_PROGIF(CFG_PROGIF),
	.CFG_SUBCLASS(CFG_SUBCLASS),
	.CFG_CLASS(CFG_CLASS),
	.CFG_CACHE_LINE_SIZE(CFG_CACHE_LINE_SIZE),
	.CFG_MIN_GRANT(CFG_MIN_GRANT),
	.CFG_MAX_LATENCY(CFG_MAX_LATENCY),
	.CFG_IRQ_LINE(CFG_IRQ_LINE)
)
upci
(
	.rst_i(rst),
	.clk_i(clk),
	.irq_i(1'b0),
	.irq_o(),
	.cs_config_i(cs_config1),
	.we_i(fta1.we),
	.sel_i(fta1.sel),
	.adr_i(fta1.padr),
	.dat_i(fta1.data1),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_gt),
	.cs_bar1_o(),
	.cs_bar2_o(),
	.irq_en_o()
);

always_ff @(posedge clk)
	tid_ndx <= fta_resp_i.tid;
always_ff @(posedge clk)
	gate_open <= gate[tid_ndx];
always_ff @(posedge clk)
	fta_resp1 <= fta_resp_i;
always_ff @(posedge clk)
	fta_resp2 <= fta_resp1;

always_ff @(posedge clk)
	fta1 <= fta_req_i;
always_ff @(posedge clk)
	fta2 <= fta1;
always_ff @(posedge clk)
	cs_config2 <= cs_config1;
always_ff @(posedge clk)
	cs1 <= cs & ~csb;
always_ff @(posedge clk)
	cs2 <= cs1;
always_ff @(posedge clk)
	cs3 <= cs2;
always_ff @(posedge clk)
	csb1 <= csb & fta_req_i.cyc;
always_ff @(posedge clk)
	csb2 <= csb1;
always_ff @(posedge clk)
	addra1 <= addrb;
always_ff @(posedge clk)
	addra <= addra1;

always_ff @(posedge clk)
if (rst)
	iadr <= SIZE;
else begin
	if (age)
		iadr <= 17'd0;
	else if (!cs & !csb && iadr!=SIZE)
		iadr <= iadr + 2'd1;
end

always_comb
	addrb <= csb ? fta_req_i.padr[16:4] : cs ? fta_req_i.padr[28:16] : iadr;

always_comb
begin
	tmp = doutb[58:32] + 2'd1;
	if (tmp[27])
		tmp = 27'h7ffffff;
end

always_comb
	m = fta1.we;

always_ff @(posedge clk)
begin
	wea0 <= csb1 && &fta1.sel[ 3: 0];
	wea1 <= (csb1 && &fta1.sel[ 7: 4]) || cs1 || iadr != SIZE;
	wea2 <= csb1 && &fta1.sel[11: 8];
	wea3 <= csb1 && &fta1.sel[15:12];
end
always_ff @(posedge clk)
begin
	dina[31:0] <= fta1.data1[31:0];
	if (csb1)
		dina[63:32] <= fta1.data1[63:32];
	else
		dina[63:32] <= cs1 ? {m ? 1'b1 : doutb[63],4'd0,tmp} : {doutb[63],4'd0,doutb[58:32] >> 2'd1};
	dina[127:64] <= fta1.data1[127:64];
end


always_ff @(posedge clk)
if (rst) begin
	fta_req_o <= {$bits(fta_cmd_request128_t){1'b0}};
	fta_resp_o <= {$bits(fta_cmd_response128_t){1'b0}};
end
else begin
	// Active signals for only one cycle.
	fta_req_o <= {$bits(fta_cmd_request128_t){1'b0}};
	fta_resp_o <= {$bits(fta_cmd_response128_t){1'b0}};
	// Normal request.
	if (cs1) begin
		// If a code area
		if (~doutb[31]) begin
			// and conforming or priv. match
			if ((doutb[7:0]==8'h00 || doutb[7:0]==fta1.pl) 
			&& (fta1.key[0]==doutb[27:8]
				|| fta1.key[1]==doutb[27:8]
				|| fta1.key[2]==doutb[27:8]
				|| fta1.key[3]==doutb[27:8]
				|| doutb[27:8]==20'h0)
			//&& fta1.seg==fta_bus_pkg::CODE	// ToDo: enable bit
			) begin
				// allow through
				fta_req_o <= fta1;
				gate[fta1.tid] <= 1'b1;
			end
			else begin
				// report back a priv error
				gate[fta1.tid] <= 1'b0;
				fta_resp_o.next <= 1'b0;
				fta_resp_o.stall <= 1'b0;
				fta_resp_o.pri <= 4'd7;
				fta_resp_o.err <= fta_bus_pkg::PROTERR;
				fta_resp_o.rty <= 1'b0;
				fta_resp_o.ack <= 1'b0;
				fta_resp_o.tid <= fta1.tid;
				fta_resp_o.adr <= fta1.padr;
				fta_resp_o.dat <= 128'd0;
			end
		end
		// If a data area
		else begin
			// and no priv required or priv. greater
			if ((doutb[7:0]==8'h00 || doutb[7:0] <= fta1.pl)
			&& (fta1.key[0]==doutb[27:8]
				|| fta1.key[1]==doutb[27:8]
				|| fta1.key[2]==doutb[27:8]
				|| fta1.key[3]==doutb[27:8]
				|| doutb[27:8]==20'h0)
			&& fta1.seg!=fta_bus_pkg::CODE) begin
				// allow through
				fta_req_o <= fta1;
				gate[fta1.tid] <= 1'b1;
			end
			else begin
				// report back a priv error
				gate[fta1.tid] <= 1'b0;
				fta_resp_o.next <= 1'b0;
				fta_resp_o.stall <= 1'b0;
				fta_resp_o.pri <= 4'd7;
				fta_resp_o.err <= fta_bus_pkg::PROTERR;
				fta_resp_o.rty <= 1'b0;
				fta_resp_o.ack <= 1'b0;
				fta_resp_o.tid <= fta1.tid;
				fta_resp_o.adr <= fta1.padr;
				fta_resp_o.dat <= 128'd0;
			end
		end
	end
	// Request to read lot gate info.
	else if (csb1) begin
		fta_resp_o.next <= 1'b0;
		fta_resp_o.stall <= 1'b0;
		fta_resp_o.pri <= 4'd7;
		fta_resp_o.err <= fta_bus_pkg::OKAY;
		fta_resp_o.rty <= 1'b0;
		fta_resp_o.ack <= csb1;
		fta_resp_o.tid <= fta1.tid;
		fta_resp_o.adr <= fta1.padr;
		fta_resp_o.dat <= doutb;
	end
	// Request to read config info.
	else if (cs_config2) begin
		fta_resp_o.next <= 1'b0;
		fta_resp_o.stall <= 1'b0;
		fta_resp_o.pri <= 4'd7;
		fta_resp_o.err <= fta_bus_pkg::OKAY;
		fta_resp_o.rty <= 1'b0;
		fta_resp_o.ack <= cs_config2;
		fta_resp_o.tid <= fta2.tid;
		fta_resp_o.adr <= fta2.padr;
		fta_resp_o.dat <= cfg_out;
	end
	if (gate_open) begin
		gate[fta_resp2.tid] <= 1'b0;
		fta_resp_o <= fta_resp2;
	end
end


// xpm_memory_sdpram: Simple Dual Port RAM
// Xilinx Parameterized Macro, version 2022.2

xpm_memory_sdpram #(
  .ADDR_WIDTH_A($clog2(SIZE)),    // DECIMAL
  .ADDR_WIDTH_B($clog2(SIZE)),    // DECIMAL
  .AUTO_SLEEP_TIME(0),            // DECIMAL
  .BYTE_WRITE_WIDTH_A(32),        // DECIMAL
  .CASCADE_HEIGHT(0),             // DECIMAL
  .CLOCKING_MODE("common_clock"), // String
  .ECC_MODE("no_ecc"),            // String
  .MEMORY_INIT_FILE("none"),      // String
  .MEMORY_INIT_PARAM("0"),        // String
  .MEMORY_OPTIMIZATION("true"),   // String
  .MEMORY_PRIMITIVE("auto"),      // String
  .MEMORY_SIZE(SIZE*32),             // DECIMAL
  .MESSAGE_CONTROL(0),            // DECIMAL
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
xpm_memory_sdpram_inst0 (
  .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                   // on the data output of port B.

  .doutb(doutb[31:0]),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
  .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                   // on the data output of port B.

  .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
  .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
  .clka(clka),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                   // parameter CLOCKING_MODE is "common_clock".

  .clkb(clkb),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                   // "independent_clock". Unused when parameter CLOCKING_MODE is
                                   // "common_clock".

  .dina(dina[31:0]),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
  .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                   // cycles when write operations are initiated. Pipelined internally.

  .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                   // cycles when read operations are initiated. Pipelined internally.

  .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                   // data path.

  .rstb(rstb),                     // 1-bit input: Reset signal for the final port B output register stage.
                                   // Synchronously resets output port doutb to the value specified by
                                   // parameter READ_RESET_VALUE_B.

  .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
  .wea(wea0)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                   // for port A input data port dina. 1 bit wide when word-wide writes are
                                   // used. In byte-wide write configurations, each bit controls the
                                   // writing one byte of dina to address addra. For example, to
                                   // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                   // is 32, wea would be 4'b0010.

);

xpm_memory_sdpram #(
  .ADDR_WIDTH_A($clog2(SIZE)),    // DECIMAL
  .ADDR_WIDTH_B($clog2(SIZE)),	  // DECIMAL
  .AUTO_SLEEP_TIME(0),            // DECIMAL
  .BYTE_WRITE_WIDTH_A(32),        // DECIMAL
  .CASCADE_HEIGHT(0),             // DECIMAL
  .CLOCKING_MODE("common_clock"), // String
  .ECC_MODE("no_ecc"),            // String
  .MEMORY_INIT_FILE("none"),      // String
  .MEMORY_INIT_PARAM("0"),        // String
  .MEMORY_OPTIMIZATION("true"),   // String
  .MEMORY_PRIMITIVE("auto"),      // String
  .MEMORY_SIZE(SIZE*32),             // DECIMAL
  .MESSAGE_CONTROL(0),            // DECIMAL
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
xpm_memory_sdpram_inst1 (
  .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                   // on the data output of port B.

  .doutb(doutb[63:32]),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
  .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                   // on the data output of port B.

  .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
  .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
  .clka(clka),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                   // parameter CLOCKING_MODE is "common_clock".

  .clkb(clkb),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                   // "independent_clock". Unused when parameter CLOCKING_MODE is
                                   // "common_clock".

  .dina(dina[63:32]),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
  .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                   // cycles when write operations are initiated. Pipelined internally.

  .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                   // cycles when read operations are initiated. Pipelined internally.

  .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                   // data path.

  .rstb(rstb),                     // 1-bit input: Reset signal for the final port B output register stage.
                                   // Synchronously resets output port doutb to the value specified by
                                   // parameter READ_RESET_VALUE_B.

  .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
  .wea(wea1)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                   // for port A input data port dina. 1 bit wide when word-wide writes are
                                   // used. In byte-wide write configurations, each bit controls the
                                   // writing one byte of dina to address addra. For example, to
                                   // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                   // is 32, wea would be 4'b0010.

);
				
xpm_memory_sdpram #(
  .ADDR_WIDTH_A($clog2(SIZE)),	  // DECIMAL
  .ADDR_WIDTH_B($clog2(SIZE)),    // DECIMAL
  .AUTO_SLEEP_TIME(0),            // DECIMAL
  .BYTE_WRITE_WIDTH_A(32),        // DECIMAL
  .CASCADE_HEIGHT(0),             // DECIMAL
  .CLOCKING_MODE("common_clock"), // String
  .ECC_MODE("no_ecc"),            // String
  .MEMORY_INIT_FILE("none"),      // String
  .MEMORY_INIT_PARAM("0"),        // String
  .MEMORY_OPTIMIZATION("true"),   // String
  .MEMORY_PRIMITIVE("auto"),      // String
  .MEMORY_SIZE(SIZE*32),             // DECIMAL
  .MESSAGE_CONTROL(0),            // DECIMAL
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
xpm_memory_sdpram_inst2 (
  .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                   // on the data output of port B.

  .doutb(doutb[95:64]),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
  .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                   // on the data output of port B.

  .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
  .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
  .clka(clka),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                   // parameter CLOCKING_MODE is "common_clock".

  .clkb(clkb),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                   // "independent_clock". Unused when parameter CLOCKING_MODE is
                                   // "common_clock".

  .dina(dina[95:64]),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
  .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                   // cycles when write operations are initiated. Pipelined internally.

  .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                   // cycles when read operations are initiated. Pipelined internally.

  .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                   // data path.

  .rstb(rstb),                     // 1-bit input: Reset signal for the final port B output register stage.
                                   // Synchronously resets output port doutb to the value specified by
                                   // parameter READ_RESET_VALUE_B.

  .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
  .wea(wea2)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                   // for port A input data port dina. 1 bit wide when word-wide writes are
                                   // used. In byte-wide write configurations, each bit controls the
                                   // writing one byte of dina to address addra. For example, to
                                   // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                   // is 32, wea would be 4'b0010.

);
				
xpm_memory_sdpram #(
  .ADDR_WIDTH_A($clog2(SIZE)),	  // DECIMAL
  .ADDR_WIDTH_B($clog2(SIZE)),    // DECIMAL
  .AUTO_SLEEP_TIME(0),            // DECIMAL
  .BYTE_WRITE_WIDTH_A(32),        // DECIMAL
  .CASCADE_HEIGHT(0),             // DECIMAL
  .CLOCKING_MODE("common_clock"), // String
  .ECC_MODE("no_ecc"),            // String
  .MEMORY_INIT_FILE("none"),      // String
  .MEMORY_INIT_PARAM("0"),        // String
  .MEMORY_OPTIMIZATION("true"),   // String
  .MEMORY_PRIMITIVE("auto"),      // String
  .MEMORY_SIZE(SIZE*32),             // DECIMAL
  .MESSAGE_CONTROL(0),            // DECIMAL
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
xpm_memory_sdpram_inst3 (
  .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                   // on the data output of port B.

  .doutb(doutb[127:96]),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
  .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                   // on the data output of port B.

  .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
  .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
  .clka(clka),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                   // parameter CLOCKING_MODE is "common_clock".

  .clkb(clkb),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                   // "independent_clock". Unused when parameter CLOCKING_MODE is
                                   // "common_clock".

  .dina(dina[127:96]),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
  .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                   // cycles when write operations are initiated. Pipelined internally.

  .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                   // cycles when read operations are initiated. Pipelined internally.

  .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                   // data path.

  .rstb(rstb),                     // 1-bit input: Reset signal for the final port B output register stage.
                                   // Synchronously resets output port doutb to the value specified by
                                   // parameter READ_RESET_VALUE_B.

  .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
  .wea(wea3)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                   // for port A input data port dina. 1 bit wide when word-wide writes are
                                   // used. In byte-wide write configurations, each bit controls the
                                   // writing one byte of dina to address addra. For example, to
                                   // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                   // is 32, wea would be 4'b0010.

);
				
endmodule
