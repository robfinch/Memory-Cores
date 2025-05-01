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
//`define SUPPORT_CAPABILITES	1'b1

import fta_bus_pkg::*;

module scratchmem256_fta(cs_config_i, sys_slave, fb_slave, ip, sp);
parameter pInitFile = "rom.mem";
parameter pMemSize = 524288;	// 512k
input cs_config_i;
fta_bus_interface.slave sys_slave;
fta_bus_interface.slave fb_slave;
input [31:0] ip;
input [31:0] sp;

parameter IO_ADDR = 32'hFFF00001;
parameter IO_ADDR_MASK = 32'hFFF00000;

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
fta_bus_interface #(.DATA_WIDTH(256)) sys_slaved();

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
vtdl #(.WID(1), .DEP(16)) udlyr (.clk(sys_slave.clk), .ce(1'b1), .a(1), .d(cs_ram & ~sys_slaved.req.we), .q(rd_ack));
vtdl #(.WID(1), .DEP(16)) udlyc (.clk(sys_slave.clk), .ce(1'b1), .a(0), .d(cs_config & ~sys_slaved.req.we), .q(cfg_rd_ack));
vtdl #(.WID(1), .DEP(16)) udlyw (.clk(sys_slave.clk), .ce(1'b1), .a(1), .d((cs_ram|cs_config) & sys_slaved.req.we & erc), .q(wr_ack));
always_ff @(posedge sys_slave.clk)
	sys_slave.resp.ack <= (rd_ack|cfg_rd_ack|wr_ack);//(cs|cs_config);	

always_ff @(posedge sys_slave.clk)
	cs_config <= cs_config_i & sys_slave.req.cyc &&
		sys_slave.req.adr[27:20]==CFG_BUS &&
		sys_slave.req.adr[19:15]==CFG_DEVICE &&
		sys_slave.req.adr[14:12]==CFG_FUNC;

always_ff @(posedge sys_slave.clk)
	sys_slaved.req <= sys_slave.req;
always_ff @(posedge sys_slave.clk)
	erc <= sys_slave.req.cti==fta_bus_pkg::ERC;
always_comb
	cs_ram <= cs_bar0 && sys_slaved.req.cyc;

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
	.rst_i(sys_slave.rst),
	.clk_i(sys_slave.clk),
	.cs_config_i(cs_config), 
	.we_i(sys_slaved.req.we),
	.sel_i(sys_slaved.req.sel),
	.adr_i(sys_slaved.req.adr),
	.dat_i(sys_slaved.req.data1),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_bar0),
	.cs_bar1_o(),
	.cs_bar2_o()
);

always_ff @(posedge sys_slave.clk)
	if (csd & sys_slaved.req.we) begin
		$display ("%d %h: wrote to scratchmem: %h=%h:%h", $time, ip, sys_slave.req.adr, sys_slaved.req.data1, sys_slaved.req.sel);
	end

reg [11:0] spr;
always_ff @(posedge sys_slave.clk)
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

wire rsta = sys_slave.rst;
wire rstb = fb_slave.rst;
wire clka = sys_slave.clk;
wire clkb = fb_slave.clk;
wire ena = cs_ram;
wire enb = fb_slave.req.cyc;

`ifdef SUPPORT_CAPABILITIES
// Always write the capabilities tag bit.
wire [32:0] wea = {sys_slaved.req.we,{32{sys_slaved.req.we}}&sys_slaved.req.sel};
// Must clear the capabilities tag bit if anything other than a capabilites
// store occurs.
wire [256:0] dina = {7'd0,sys_slaved.req.ctag&&sys_slaved.req.cmd==fta_bus_pkg::CMD_STORECAP,sys_slaved.req.data1};
`else
wire [31:0] wea = {{32{sys_slaved.req.we}}&sys_slaved.req.sel};
// Must clear the capabilities tag bit if anything other than a capabilites
// store occurs.
wire [255:0] dina = sys_slaved.req.data1;
`endif
wire [19:0] addra = sys_slaved.req.adr[19:0];
wire [19:0] addrb = fb_slave.req.adr[19:0];
wire [31:0] web = fb_slave.req.we;
wire [255:0] dinb = fb_slave.req.data1;
wire [255:0] douta;
wire [255:0] doutb;
assign fb_slave.resp.dat = doutb;

   // xpm_memory_tdpram: True Dual Port RAM
   // Xilinx Parameterized Macro, version 2024.1

   xpm_memory_tdpram #(
      .ADDR_WIDTH_A($clog2(pMemSize)-5),	// DECIMAL
      .ADDR_WIDTH_B($clog2(pMemSize)-5), // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(8),        // DECIMAL
      .BYTE_WRITE_WIDTH_B($bits(fb_slave.req.data1)),        	// DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("independent_clock"), // String
      .ECC_BIT_RANGE("7:0"),          // String
      .ECC_MODE("no_ecc"),            // String
      .ECC_TYPE("none"),              // String
      .IGNORE_INIT_SYNTH(0),          // DECIMAL
      .MEMORY_INIT_FILE("rom.mem"),   // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String
      .MEMORY_SIZE(pMemSize*8),       // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .RAM_DECOMP("auto"),            // String
      .READ_DATA_WIDTH_A($bits(fb_slave.resp.dat)),         // DECIMAL
      .READ_DATA_WIDTH_B($bits(sys_slave.resp.dat)),         // DECIMAL
      .READ_LATENCY_A(2),             // DECIMAL
      .READ_LATENCY_B(2),             // DECIMAL
      .READ_RESET_VALUE_A("0"),       // String
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .USE_MEM_INIT_MMI(0),           // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A($bits(fb_slave.req.data1)),        // DECIMAL
      .WRITE_DATA_WIDTH_B($bits(sys_slave.req.data1)),        // DECIMAL
      .WRITE_MODE_A("read_first"),     // String
      .WRITE_MODE_B("read_first"),     // String
      .WRITE_PROTECT(1)               // DECIMAL
   )
   xpm_memory_tdpram_inst (
      .dbiterra(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .douta(douta),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .doutb(doutb),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterra(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(addra[19:5]),             // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .addrb(addrb[19:5]),             // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
      .clka(clka),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clkb),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .dinb(dinb),                     // WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
      .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectdbiterrb(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterrb(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(rsta),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .rstb(rstb),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(wea),                       // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

      .web(web)                        // WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                       // for port B input data port dinb. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dinb to address addrb. For example, to
                                       // synchronously write only bits [15-8] of dinb when WRITE_DATA_WIDTH_B
                                       // is 32, web would be 4'b0010.

   );

`ifdef SUPPORT_CAPABILITIES
always_ff @(posedge clk_i)
	if (cfg_rd_ack)
		{sys_slave.resp.ctag,sys_slave.resp.dat} <= {1'b0,cfg_out};
	else
		{sys_slave.resp.ctag,sys_slave.resp.dat} <= douta[256:0];
`else
always_ff @(posedge sys_slave.clk)
begin
	sys_slave.resp.ctag <= 1'b0;
	if (cfg_rd_ack)
		sys_slave.resp.dat <= cfg_out;
	else
		sys_slave.resp.dat <= douta[255:0];
end
`endif

fta_asid_t asid3;
fta_tranid_t tid3;
wire [31:0] adr3;
vtdl #(.WID($bits(fta_tranid_t)), .DEP(16)) udlytid (.clk(sys_slave.clk), .ce(1'b1), .a(2), .d(sys_slave.req.tid), .q(tid3));
vtdl #(.WID(32), .DEP(16)) udlyadr (.clk(sys_slave.clk), .ce(1'b1), .a(2), .d(sys_slave.req.adr), .q(adr3));
always_ff @(posedge sys_slave.clk)
	sys_slave.resp.tid <= tid3;
always_ff @(posedge sys_slave.clk)
	sys_slave.resp.adr <= adr3;
assign sys_slave.resp.next = 1'd0;
assign sys_slave.resp.stall = 1'd0;
assign sys_slave.resp.err = fta_bus_pkg::OKAY;
assign sys_slave.resp.rty = 1'd0;
assign sys_slave.resp.pri = 4'd7;

vtdl #(.WID(1), .DEP(16)) udlyfbcyc (.clk(fb_slave.clk), .ce(1'b1), .a(2), .d(fb_slave.req.cyc), .q(fb_slave.resp.ack));
vtdl #(.WID($bits(fta_tranid_t)), .DEP(16)) udlyfbtid (.clk(fb_slave.clk), .ce(1'b1), .a(2), .d(fb_slave.req.tid), .q(fb_slave.resp.tid));
vtdl #(.WID(32), .DEP(16)) udlyfbadr (.clk(fb_slave.clk), .ce(1'b1), .a(2), .d(fb_slave.req.adr), .q(fb_slave.resp.adr));
assign fb_slave.resp.next = 1'd0;
assign fb_slave.resp.stall = 1'd0;
assign fb_slave.resp.err = fta_bus_pkg::OKAY;
assign fb_slave.resp.rty = 1'd0;
assign fb_slave.resp.pri = 4'd7;

endmodule
