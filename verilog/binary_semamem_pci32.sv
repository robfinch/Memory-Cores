// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	binary_semamem_pci32.sv
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
// Key
// 0b10...kkkkkkkkkkkkkkkk		write value only if mem is zero (lock)
// 0b11...kkkkkkkkkkkkkkkk	  write zero only if mem==write data (unlock)
// 0b00...kkkkkkkkkkkkkkkk		write value
// 0b01...kkkkkkkkkkkkkkkk		write value
//
// To Lock Semaphore:
//	write a key value with bits 30,31=10b where n...n is the semaphore
//  read back the value stored to see if the update was successful and the key
//  was stored.
// To Unlock Semaphore
//  write the key value with bits 30,31=11b to address 0xnnnnnnnnnnnn
//
// 86 LUTs / 116 FFs / 1 BRAMs		2048 semaphores with 16-bit key
// ============================================================================

module binary_semamem_pci32(rst_i, clk_i, cs_config_i, cs_io_i,
	cyc_i, stb_i, ack_o, sel_i, we_i, adr_i, dat_i, dat_o);
input rst_i;
input clk_i;
input cs_config_i;
input cs_io_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [3:0] sel_i;
input [31:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;

parameter NUM_SEMAPHORE = 2048;
parameter LOG_NUM_SEMAPHORE = $clog2(NUM_SEMAPHORE);
parameter KEY_SIZE = 16;		// size of key in bits

parameter IO_ADDR = 32'hFEE80001;
parameter IO_ADDR_MASK = 32'h00FC0000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd17;
parameter CFG_FUNC = 3'd0;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'd1;
parameter CFG_SUBCLASS = 8'h80;					// 80 = Other
parameter CFG_CLASS = 8'h05;						// 05 = memory controller
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'hFF;

localparam CFG_HEADER_TYPE = 8'h00;			// 00 = a general device

wire [31:0] cfg_out;
wire cs_sema;
wire cs_config = cs_config_i & cyc_i & stb_i &&
	adr_i[27:20]==CFG_BUS &&
	adr_i[19:15]==CFG_DEVICE &&
	adr_i[14:12]==CFG_FUNC;
wire cs_io = cs_io_i & cyc_i & stb_i & cs_sema;
wire cs = cs_io;

reg we;
reg [3:0] sel;
reg [31:0] adr;
reg [31:0] dati;

ack_gen #(
	.READ_STAGES(2),
	.WRITE_STAGES(4),
	.REGISTER_OUTPUT(1)
) uag1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.ce_i(1'b1),
	.rid_i('d0),
	.wid_i('d0),
	.i((cs|cs_config) & ~we_i),
	.we_i((cs|cs_config) & we_i),
	.o(ack_o),
	.rid_o(),
	.wid_o()
);

pci32_config #(
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
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr),
	.dat_i(dati),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_sema),
	.cs_bar1_o(),
	.cs_bar2_o(),
	.irq_en_o()
);


wire [KEY_SIZE-1:0] memo;
reg [KEY_SIZE-1:0] memi;
// Register inputs
always_ff @(posedge clk_i)
	we <= we_i;
always_ff @(posedge clk_i)
	sel <= sel_i;
always_ff @(posedge clk_i)
	adr <= adr_i;
always_ff @(posedge clk_i)
	dati <= dat_i;

always_ff @(posedge clk_i)
	casez(dat_i[31:30])
	2'b0?:	memi <= dat_i[KEY_SIZE-1:0];
	2'b10:	memi <= (~|memo) ? dat_i[KEY_SIZE-1:0] : memo;
	2'b11:	memi <= (memo[KEY_SIZE-1:0]==dat_i[KEY_SIZE-1:0]) ? 'd0 : memo;
	endcase

   // xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2022.2

   xpm_memory_sdpram #(
      .ADDR_WIDTH_A(LOG_NUM_SEMAPHORE),
      .ADDR_WIDTH_B(LOG_NUM_SEMAPHORE),
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(KEY_SIZE),
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("block"),      // String
      .MEMORY_SIZE(NUM_SEMAPHORE*KEY_SIZE),
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B(KEY_SIZE),
      .READ_LATENCY_B(2),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .USE_MEM_INIT_MMI(0),           // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(KEY_SIZE),
      .WRITE_MODE_B("no_change"),     // String
      .WRITE_PROTECT(1)               // DECIMAL
   )
   xpm_memory_sdpram_inst (
      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(memo),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(adr[LOG_NUM_SEMAPHORE+2-1:2]),
      .addrb(adr[LOG_NUM_SEMAPHORE+2-1:2]),
      .clka(clk_i),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clk_i),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(memi),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(cs & ack_o),                // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when write operations are initiated. Pipelined internally.

      .enb(cs),                        // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regceb(cs),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rstb(1'b0),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(cs & ack_o & we)          	// WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );
				
always_ff @(posedge clk_i)
if (cs_config)
	dat_o <= cfg_out;
else if (cs)
  dat_o <= {32'd0,memo};
else
	dat_o <= 32'h00;

endmodule
