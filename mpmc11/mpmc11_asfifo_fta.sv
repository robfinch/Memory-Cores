`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2025  Robert Finch, Waterloo
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
import fta_bus_pkg::*;
import mpmc11_pkg::*;

module mpmc11_asfifo_fta(rst, rd_clk, rd_fifo, wr_clk, wr_fifo,
	req_fifoi, req_fifoo, ocd, rty,
	full, empty, almost_full, prog_full, rd_rst_busy, wr_rst_busy, cnt);
parameter DEPTH=32;
input rst;
input rd_clk;
input rd_fifo;
input wr_clk;
input wr_fifo;
input rty;
input mpmc11_fifoe_t req_fifoi;
output mpmc11_fifoe_t req_fifoo;
output ocd;									// output change detect
output full;
output empty;
output almost_full;
output prog_full;
output reg rd_rst_busy;
output reg wr_rst_busy;
output [5:0] cnt;

always_comb
if (DEPTH < 16) begin
	$display("MPMC11: fifo depth is too small");
	$finish;
end
/* I think this is caught by the template
else if ((16'd1 << $clog2(DEPTH)) != DEPTH) begin
	$display("MPMC11: fifo depth must be power of two");
	$finish;
end
*/

wire ocd1;
wire data_valid;
wire rd_rst_busy1;
wire ne_rd_rst_busy;
edge_det urstbusy (.rst(rst), .clk(rd_clk), .ce(1'b1), .i(rd_rst_busy1), .pe(), .ne(ne_rd_rst_busy), .ee());

always_ff @(posedge rd_clk)
if (rst)
	rd_rst_busy = 1'b1;
else begin
	if (ne_rd_rst_busy)
		rd_rst_busy <= 1'b0;
end

wire wr_rst_busy1;
wire ne_wr_rst_busy;
edge_det uwrrstbusy (.rst(rst), .clk(wr_clk), .ce(1'b1), .i(wr_rst_busy1), .pe(), .ne(ne_wr_rst_busy), .ee());

always_ff @(posedge wr_clk)
if (rst)
	wr_rst_busy = 1'b1;
else begin
	if (ne_wr_rst_busy)
		wr_rst_busy <= 1'b0;
end

change_det #($bits(mpmc11_fifoe_t)) ucdfifo1
(
	.rst(rst),
	.clk(rd_clk),
	.ce(1'b1),
	.i(req_fifoo),
	.cd(ocd1)
);

assign ocd = data_valid;

// XPM_FIFO instantiation template for Asynchronous FIFO configurations
// Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
// =======================================================================================================================
   // xpm_fifo_async: Asynchronous FIFO
   // Xilinx Parameterized Macro, version 2022.2

   xpm_fifo_async #(
      .CASCADE_HEIGHT(0),        // DECIMAL
      .CDC_SYNC_STAGES(2),       // DECIMAL
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("distributed"), // String
      .FIFO_READ_LATENCY(0),     // DECIMAL
      .FIFO_WRITE_DEPTH(DEPTH),  // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(5),    // DECIMAL
      .PROG_FULL_THRESH(DEPTH-5),	// DECIMAL
      .RD_DATA_COUNT_WIDTH($clog2(DEPTH)+1),   // DECIMAL
      .READ_DATA_WIDTH($bits(mpmc11_fifoe_t)),      // DECIMAL
      .READ_MODE("fwft"),         // String
      .RELATED_CLOCKS(0),        // DECIMAL
      .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_ADV_FEATURES("100E"), // String		enable data valid, almost full and prog full
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH($bits(mpmc11_fifoe_t)),     // DECIMAL
      .WR_DATA_COUNT_WIDTH($clog2(DEPTH)+1)    // DECIMAL
   )
   xpm_fifo_async_inst (
      .almost_empty(),						   // 1-bit output: Almost Empty : When asserted, this signal indicates that
                                     // only one more read can be performed before the FIFO goes to empty.
      .almost_full(almost_full),		// 1-bit output: Almost Full: When asserted, this signal indicates that
                                     // only one more write can be performed before the FIFO is full.
      .data_valid(data_valid),	    // 1-bit output: Read Data Valid: When asserted, this signal indicates
                                     // that valid data is available on the output bus (dout).
      .dbiterr(),				             // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
                                     // a double-bit error and data in the FIFO core is corrupted.
      .dout(req_fifoo),              // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                     // when reading the FIFO.
      .empty(empty),                 // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                                     // FIFO is empty. Read requests are ignored when the FIFO is empty,
                                     // initiating a read while empty is not destructive to the FIFO.
      .full(full),                   // 1-bit output: Full Flag: When asserted, this signal indicates that the
                                     // FIFO is full. Write requests are ignored when the FIFO is full,
                                     // initiating a write when the FIFO is full is not destructive to the
                                     // contents of the FIFO.
      .overflow(),				           // 1-bit output: Overflow: This signal indicates that a write request
                                     // (wren) during the prior clock cycle was rejected, because the FIFO is
                                     // full. Overflowing the FIFO is not destructive to the contents of the
                                     // FIFO.
      .prog_empty(),					       // 1-bit output: Programmable Empty: This signal is asserted when the
                                     // number of words in the FIFO is less than or equal to the programmable
                                     // empty threshold value. It is de-asserted when the number of words in
                                     // the FIFO exceeds the programmable empty threshold value.
      .prog_full(prog_full),         // 1-bit output: Programmable Full: This signal is asserted when the
                                     // number of words in the FIFO is greater than or equal to the
                                     // programmable full threshold value. It is de-asserted when the number of
                                     // words in the FIFO is less than the programmable full threshold value.
      .rd_data_count(),							 // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
                                     // number of words read from the FIFO.
      .rd_rst_busy(rd_rst_busy1),     // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
                                     // domain is currently in a reset state.
      .sbiterr(),				             // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
                                     // and fixed a single-bit error.
      .underflow(),					         // 1-bit output: Underflow: Indicates that the read request (rd_en) during
                                     // the previous clock cycle was rejected because the FIFO is empty. Under
                                     // flowing the FIFO is not destructive to the FIFO.
      .wr_ack(),			               // 1-bit output: Write Acknowledge: This signal indicates that a write
                                     // request (wr_en) during the prior clock cycle is succeeded.
      .wr_data_count(cnt),					 // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                     // the number of words written into the FIFO.
      .wr_rst_busy(wr_rst_busy1),     // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                     // write domain is currently in a reset state.
      .din(req_fifoi),               // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                     // writing the FIFO.
      .injectdbiterr(1'b0),					 // 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                     // the ECC feature is used on block RAMs or UltraRAM macros.
      .injectsbiterr(1'b0), 				// 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                     // the ECC feature is used on block RAMs or UltraRAM macros.
      .rd_clk(rd_clk),               // 1-bit input: Read clock: Used for read operation. rd_clk must be a free
                                     // running clock.
      .rd_en(rd_fifo & ~rd_rst_busy1 & ~rd_rst_busy & ~rst),	
      															// 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                     // signal causes data (on dout) to be read from the FIFO. Must be held
                                     // active-low when rd_rst_busy is active high.
      .rst(rst),                     // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                     // unstable at the time of applying reset, but reset must be released only
                                     // after the clock(s) is/are stable.
      .sleep(1'b0),		               // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
                                     // block is in power saving mode.
      .wr_clk(wr_clk),               // 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                     // free running clock.
      .wr_en(wr_fifo & ~wr_rst_busy1 & ~wr_rst_busy & ~rst) // 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                     // signal causes data (on din) to be written to the FIFO. Must be held
                                     // active-low when rst or wr_rst_busy is active high.
   );

endmodule
