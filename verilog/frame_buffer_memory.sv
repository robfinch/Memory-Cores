import fta_bus_pkg::*;

module frame_buffer_memory(fb_slave, sys_slave);
parameter MEMSIZE = 524288;	// 512k
localparam ABIT=$clog2(MEMSIZE)-1;	// 512k
fta_bus_interface.slave fb_slave;
fta_bus_interface.slave sys_slave;

wire clka = fb_slave.clk;
wire clkb = sys_slave.clk;
wire rsta = fb_slave.rst;
wire rstb = sys_slave.rst;
wire [ABIT:5] addra = fb_slave.req.padr[ABIT:5];
wire [ABIT:5] addrb = sys_slave.req.padr[ABIT:5];
wire [$bits(fb_slave.resp.dat)-1:0] douta;
wire [$bits(sys_slave.resp.dat)-1:0] doutb;
assign fb_slave.resp.dat = douta;
assign sys_slave.resp.dat = doutb;
reg [$bits(fb_slave.req.data1)-1:0] dina;
reg [$bits(sys_slave.req.data1)-1:0] dinb;
always_comb dina = fb_slave.req.data1;
always_comb dinb = sys_slave.req.data1;
wire ena = fb_slave.req.cyc && fb_slave.req.padr[31:20]==12'h000;
wire enb = sys_slave.req.cyc && sys_slave.req.padr[31:20]==12'h000;
wire wea = fb_slave.req.we;
wire [$bits(sys_slave.resp.dat)/8-1:0] web = sys_slave.req.sel & {$bits(sys_slave.resp.dat)/8{sys_slave.req.we}};

assign fb_slave.resp.err = fta_bus_pkg::OKAY;
assign fb_slave.resp.next = 1'b0;
assign fb_slave.resp.stall = 1'b0;
delay3 #(13) udly1 (.clk(fb_slave.clk), .ce(1'b1), .i(fb_slave.req.tid), .o(fb_slave.resp.tid));
delay3 #(1) udly2 (.clk(fb_slave.clk), .ce(1'b1), .i(ena), .o(fb_slave.resp.ack));
delay3 #(4) udly3 (.clk(fb_slave.clk), .ce(1'b1), .i(fb_slave.req.pri), .o(fb_slave.resp.pri));

assign sys_slave.resp.err = fta_bus_pkg::OKAY;
assign sys_slave.resp.next = 1'b0;
assign sys_slave.resp.stall = 1'b0;
delay3 #(13) udly4 (.clk(sys_slave.clk), .ce(1'b1), .i(sys_slave.req.tid), .o(sys_slave.resp.tid));
delay3 #(1) udly5 (.clk(sys_slave.clk), .ce(1'b1), .i(enb), .o(sys_slave.resp.ack));
delay3 #(4) udly6 (.clk(sys_slave.clk), .ce(1'b1), .i(sys_slave.req.pri), .o(sys_slave.resp.pri));

   // xpm_memory_tdpram: True Dual Port RAM
   // Xilinx Parameterized Macro, version 2024.1

   xpm_memory_tdpram #(
      .ADDR_WIDTH_A($clog2(MEMSIZE)-5),	// DECIMAL
      .ADDR_WIDTH_B($clog2(MEMSIZE)-5), // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A($bits(fb_slave.req.data1)),        // DECIMAL
      .BYTE_WRITE_WIDTH_B(8),        	// DECIMAL
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
      .MEMORY_SIZE(MEMSIZE*8),        // DECIMAL
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
      .WRITE_MODE_A("no_change"),     // String
      .WRITE_MODE_B("no_change"),     // String
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

      .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
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

endmodule
