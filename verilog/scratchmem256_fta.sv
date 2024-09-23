// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2024  Robert Finch, Waterloo
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
//`define SUPPORT_CAPABILITES	1'b1

import fta_bus_pkg::*;

module scratchmem256_fta(rst_i, clk_i, cs_config_i, cs_ram_i, 
	req, resp, ip, sp);
parameter pInitFile = "f:\\cores2024\\Qupls\\software\\boot\\rom.ver";
input rst_i;
input clk_i;
input cs_config_i;
input cs_ram_i;
input fta_cmd_request256_t req;
output fta_cmd_response256_t resp;
input [31:0] ip;
input [31:0] sp;

parameter IO_ADDR = 32'hFFF80001;
parameter IO_ADDR_MASK = 32'h00F80000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd11;
parameter CFG_FUNC = 3'd0;
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


integer nn;
genvar g;
fta_cmd_request256_t reqd;

reg cs_ram, cs_config;
wire cs_bar0;

/*
reg [127:0] rommem [0:32767];
initial begin
	`include "f:\\cores2024\\Qupls\\software\\boot\\rom.ver";
end
reg [14:0] radr;
*/

wire [255:0] cfg_out;
reg [255:0] ram_dat_o, ram_dat;

wire cs = cs_ram;
reg csd;
wire cfg_rd_ack;
reg erc;

wire rd_ack, wr_ack;
vtdl #(.WID(1), .DEP(16)) udlyr (.clk(clk_i), .ce(1'b1), .a(1), .d((csd) & ~reqd.we), .q(rd_ack));
vtdl #(.WID(1), .DEP(16)) udlyc (.clk(clk_i), .ce(1'b1), .a(0), .d((cs_config) & ~reqd.we), .q(cfg_rd_ack));
vtdl #(.WID(1), .DEP(16)) udlyw (.clk(clk_i), .ce(1'b1), .a(1), .d((csd|cs_config) &  reqd.we & erc), .q(wr_ack));
always_ff @(posedge clk_i)
	resp.ack <= (rd_ack|cfg_rd_ack|wr_ack);//(cs|cs_config);	

always_ff @(posedge clk_i)
	cs_config <= cs_config_i & req.cyc & req.stb &&
		req.padr[27:20]==CFG_BUS &&
		req.padr[19:15]==CFG_DEVICE &&
		req.padr[14:12]==CFG_FUNC;

always_ff @(posedge clk_i)
	reqd <= req;
always_ff @(posedge clk_i)
	erc <= req.cti==fta_bus_pkg::ERC;
always_ff @(posedge clk_i)
	csd <= cs_ram_i && req.cyc && req.stb;
always_comb
	cs_ram <= csd && cs_bar0;

ddbb256_config #(
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
ucfg1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.irq_i(1'b0),
	.irq_o(),
	.cs_config_i(cs_config), 
	.we_i(reqd.we),
	.sel_i(reqd.sel),
	.adr_i(reqd.padr),
	.dat_i(reqd.data1),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_bar0),
	.cs_bar1_o(),
	.cs_bar2_o(),
	.irq_en_o()
);

always_ff @(posedge clk_i)
	if (csd & reqd.we) begin
		$display ("%d %h: wrote to scratchmem: %h=%h:%h", $time, ip, reqd.padr, reqd.data1, reqd.sel);
	end

reg [11:0] spr;
always_ff @(posedge clk_i)
	spr <= sp[18:5];

//always_ff @(posedge clk_i)
//begin
//	datod <= rommem[radr];
	/*
	if (!we_i & cs)
		$display("%d %h: read from scratchmem: %h=%h", $time, ip, radr, rommem[radr]);
	*/
//	$display("-------------- Stack --------------");
//	for (n = -6; n < 8; n = n + 1) begin
//		$display("%c%c %h %h", n==0 ? "-": " ", n==0 ?">" : " ",spr + n, rommem[spr+n]);
//	end
//end

`ifdef SUPPORT_CAPABILITIES
// Always write the capabilities tag bit.
wire [32:0] wea = {reqd.we,{16{reqd.we}}&reqd.sel};
// Must clear the capabilities tag bit if anything other than a capabilites
// store occurs.
wire [256:0] dina = {7'd0,reqd.ctag&&reqd.cmd==fta_bus_pkg::CMD_STORECAP,reqd.data1};
`else
wire [31:0] wea = {{16{reqd.we}}&reqd.sel};
// Must clear the capabilities tag bit if anything other than a capabilites
// store occurs.
wire [255:0] dina = reqd.data1;
`endif

// xpm_memory_spram: Single Port RAM
// Xilinx Parameterized Macro, version 2022.2

xpm_memory_spram #(
  .ADDR_WIDTH_A(14),              // DECIMAL
  .AUTO_SLEEP_TIME(0),           // DECIMAL
  .BYTE_WRITE_WIDTH_A(8),       	// DECIMAL
  .CASCADE_HEIGHT(0),            // DECIMAL
  .ECC_MODE("no_ecc"),           // String
  .MEMORY_INIT_FILE("rom.mem"),     // String
  .MEMORY_INIT_PARAM(""),       // String
  .MEMORY_OPTIMIZATION("true"),  // String
  .MEMORY_PRIMITIVE("block"),     // String
  .MEMORY_SIZE(16384*256),       // DECIMAL
  .MESSAGE_CONTROL(0),           // DECIMAL
  .READ_DATA_WIDTH_A(256),        // DECIMAL
  .READ_LATENCY_A(2),            // DECIMAL
  .READ_RESET_VALUE_A("0"),      // String
  .RST_MODE_A("SYNC"),           // String
  .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .USE_MEM_INIT(1),              // DECIMAL
  .USE_MEM_INIT_MMI(0),          // DECIMAL
  .WAKEUP_TIME("disable_sleep"), // String
  .WRITE_DATA_WIDTH_A(256),       // DECIMAL
  .WRITE_MODE_A("read_first"),   // String
  .WRITE_PROTECT(1)              // DECIMAL
)
xpm_memory_spram_inst (
  .dbiterra(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                   // on the data output of port A.

  .douta(ram_dat_o),       // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
  .sbiterra(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                   // on the data output of port A.

  .addra(reqd.padr[18:5]),       // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
  .clka(clk_i),                  // 1-bit input: Clock signal for port A.
  .dina(dina),             // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
  .ena(1'b1),                    // 1-bit input: Memory enable signal for port A. Must be high on clock
                                   // cycles when read or write operations are initiated. Pipelined
                                   // internally.

  .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                   // ECC enabled (Error injection capability is not available in
                                   // "decode_only" mode).

  .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
//      .regcea(cs|rd_ack),                 // 1-bit input: Clock Enable for the last register stage on the output
                                   // data path.

  .rsta(1'b0),                // 1-bit input: Reset signal for the final port A output register stage.
                                   // Synchronously resets output port douta to the value specified by
                                   // parameter READ_RESET_VALUE_A.

  .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
  .wea(wea)     // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                   // for port A input data port dina. 1 bit wide when word-wide writes are
                                   // used. In byte-wide write configurations, each bit controls the
                                   // writing one byte of dina to address addra. For example, to
                                   // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                   // is 32, wea would be 4'b0010.

);

/*
generate begin : gRam
	for (g = 0; g < 16; g = g + 1)
	always_ff @(posedge clk_i)
		if (reqd.we)
			if (reqd.sel[g])
				rommem[reqd.padr[18:4]][g*8+7:g*8] <= reqd.data1[g*8+7:g*8];
end
endgenerate	

always_ff @(posedge clk_i)
	radr <= reqd.padr[18:4];		
always_ff @(posedge clk_i)
	ram_dat_o <= rommem[radr];
*/
/*	
always_ff @(posedge clk_i)
	ram_dat_o <= ram_dat;
*/

`ifdef SUPPORT_CAPABILITIES
always_ff @(posedge clk_i)
	if (cfg_rd_ack)
		{resp.ctag,resp.dat} <= {1'b0,cfg_out};
	else
		{resp.ctag,resp.dat} <= ram_dat_o[256:0];
`else
always_ff @(posedge clk_i)
begin
	resp.ctag <= 1'b0;
	if (cfg_rd_ack)
		resp.dat <= cfg_out;
	else
		resp.dat <= ram_dat_o[255:0];
end
`endif

fta_asid_t asid3;
fta_tranid_t tid3;
wire [31:0] adr3;
vtdl #(.WID($bits(fta_asid_t)), .DEP(16)) udlyasid (.clk(clk_i), .ce(1'b1), .a(2), .d(req.asid), .q(asid3));
vtdl #(.WID($bits(fta_tranid_t)), .DEP(16)) udlytid (.clk(clk_i), .ce(1'b1), .a(2), .d(req.tid), .q(tid3));
vtdl #(.WID(32), .DEP(16)) udlyadr (.clk(clk_i), .ce(1'b1), .a(2), .d(req.padr), .q(adr3));
always_ff @(posedge clk_i)
	resp.asid <= asid3;
always_ff @(posedge clk_i)
	resp.tid <= tid3;
always_ff @(posedge clk_i)
	resp.adr <= adr3;
assign resp.next = 1'd0;
assign resp.stall = 1'd0;
assign resp.err = fta_bus_pkg::OKAY;
assign resp.rty = 1'd0;
assign resp.pri = 4'd7;

endmodule
