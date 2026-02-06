import fta_bus_pkg::*;
import mpmc11_pkg::*;

module mpmc11_wb_tb();

reg rst;
reg clk;
reg clk100;

initial begin
	#0 clk = 0;
	#0 clk100 = 0;
	#0 rst = 0;
	#20 rst = 1;
	#100 rst = 0;
end

always #2.5 clk = ~clk;
always #5 clk100 = ~clk100;

reg [9:0] cnt;
reg [15:0] cnt1;
reg [7:0] ack0_cnt;
reg app_rdy;
wire app_en;
wire [2:0] app_cmd;
wire [29:0] app_addr;
reg app_rd_data_valid;
wire [31:0] app_wdf_mask;
wire [255:0] app_wdf_data;
reg app_wdf_rdy;
wire app_wdf_wren;
wire app_wdf_end;
reg [255:0] app_rd_data;
reg app_rd_data_end;
mpmc11_state_t mpmc_state;
reg [3:0] state;
reg [31:0] addr;
reg [31:0] rnd, rnd7;
reg [2:0] ch1_cmd;
reg [31:0] ch1_adr, ch7_adr;
reg ch1_we;
reg [3:0] tidcnt;
reg got_ack, got_ack7;
reg wb0_cs;
reg wb1_cs;
reg wb2_cs;
reg wb3_cs;
reg wb4_cs;
reg wb5_cs;
reg wb6_cs;
reg wb7_cs;

fta_bus_interface #(.DATA_WIDTH(256)) ch0_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch1_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch2_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch3_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch4_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch5_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch6_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch7_if();

wb_bus_interface #(.DATA_WIDTH(256)) wb0_if();
wb_bus_interface #(.DATA_WIDTH(256)) wb1_if();
wb_bus_interface #(.DATA_WIDTH(256)) wb2_if();
wb_bus_interface #(.DATA_WIDTH(256)) wb3_if();
wb_bus_interface #(.DATA_WIDTH(256)) wb4_if();
wb_bus_interface #(.DATA_WIDTH(256)) wb5_if();
wb_bus_interface #(.DATA_WIDTH(256)) wb6_if();
wb_bus_interface #(.DATA_WIDTH(256)) wb7_if();

wb_to_fta_bridge uwbft0 (.rst_i(rst), .clk_i(wb0_if.clk), .cs_i(wb0_cs), .wb_i(wb0_if), .fta_o(ch0_if));
wb_to_fta_bridge uwbft1 (.rst_i(rst), .clk_i(wb1_if.clk), .cs_i(wb1_cs), .wb_i(wb1_if), .fta_o(ch1_if));
wb_to_fta_bridge uwbft2 (.rst_i(rst), .clk_i(wb2_if.clk), .cs_i(wb2_cs), .wb_i(wb2_if), .fta_o(ch2_if));
wb_to_fta_bridge uwbft3 (.rst_i(rst), .clk_i(wb3_if.clk), .cs_i(wb3_cs), .wb_i(wb3_if), .fta_o(ch3_if));
wb_to_fta_bridge uwbft4 (.rst_i(rst), .clk_i(wb4_if.clk), .cs_i(wb4_cs), .wb_i(wb4_if), .fta_o(ch4_if));
wb_to_fta_bridge uwbft5 (.rst_i(rst), .clk_i(wb5_if.clk), .cs_i(wb5_cs), .wb_i(wb5_if), .fta_o(ch5_if));
wb_to_fta_bridge uwbft6 (.rst_i(rst), .clk_i(wb6_if.clk), .cs_i(wb6_cs), .wb_i(wb6_if), .fta_o(ch6_if));
wb_to_fta_bridge uwbft7 (.rst_i(rst), .clk_i(wb7_if.clk), .cs_i(wb7_cs), .wb_i(wb7_if), .fta_o(ch7_if));

always_comb
begin
	wb0_if.clk = clk100;
	wb1_if.clk = clk100;
	wb2_if.clk = clk100;
	wb3_if.clk = clk100;
	wb4_if.clk = clk100;
	wb5_if.clk = clk100;
	wb6_if.clk = clk100;
	wb7_if.clk = clk100;

	wb0_if.rst = rst;
	wb1_if.rst = rst;
	wb2_if.rst = rst;
	wb3_if.rst = rst;
	wb4_if.rst = rst;
	wb5_if.rst = rst;
	wb6_if.rst = rst;
	wb7_if.rst = rst;

	ch0_if.clk = clk100;
	ch1_if.clk = clk100;
	ch2_if.clk = clk100;
	ch3_if.clk = clk100;
	ch4_if.clk = clk100;
	ch5_if.clk = clk100;
	ch6_if.clk = clk100;
	ch7_if.clk = clk100;

	ch0_if.rst = rst;
	ch1_if.rst = rst;
	ch2_if.rst = rst;
	ch3_if.rst = rst;
	ch4_if.rst = rst;
	ch5_if.rst = rst;
	ch6_if.rst = rst;
	ch7_if.rst = rst;
end


mpmc11_fta #(
	.STREAM(8'h01),
	.CACHE(9'h082),
	.PORT_PRESENT(9'h183))
umpmc1
(
	.rst(rst),
	.sys_clk_i(clk),
	.mem_ui_rst(rst),
	.mem_ui_clk(clk),
	.calib_complete(1'b1),
	.rstn(),
	.app_rdy(app_rdy),
	.app_en(app_en),
	.app_cmd(app_cmd),
	.app_addr(app_addr),
	.app_rd_data_valid(app_rd_data_valid),
	.app_wdf_mask(app_wdf_mask),
	.app_wdf_data(app_wdf_data),
	.app_wdf_rdy(app_wdf_rdy),
	.app_wdf_wren(app_wdf_wren),
	.app_wdf_end(app_wdf_end),
	.app_rd_data(app_rd_data),
	.app_rd_data_end(app_rd_data_end),
	.app_ref_req(),
	.app_ref_ack(1'b0),
	.ch0(ch0_if),
	.ch1(ch1_if),
	.ch2(ch2_if),
	.ch3(ch3_if),
	.ch4(ch4_if),
	.ch5(ch5_if),
	.ch6(ch6_if),
	.ch7(ch7_if),
	.fifo_rst(8'h00),
//input fta_cmd_request256_t ch0i,
//output fta_cmd_response256_t ch0o,
	.state(mpmc_state),
	.rst_busy()
);

always_ff @(posedge clk)
if (rst) begin
	cnt <= 10'd0;
	state <= 4'd0;
	app_rd_data_valid <= 1'b0;
	app_rd_data_end <= 1'b0;
	app_rd_data <= {8{32'h0}};
end
else begin
	case(state)
	4'd0:
		if (app_en) begin
			cnt <= 10'd0;
			state <= 4'd1;
		end
	4'd1:
		begin
			cnt <= cnt + 5'd1;
			if (cnt > 10'd2) begin
				app_rd_data_valid <= app_cmd==3'd1;
				app_rd_data <= {8{32'hBEEFDEAD}};
			end
			if (cnt > 10'd30)
				app_rd_data_end <= 1'b1;
			if (cnt > 10'd32) begin
				state <= 4'd2;
			end
		end
	4'd2:	
		begin
			app_rd_data_valid <= 1'b0;
			app_rd_data_end <= 1'b0;
			state <= 4'd0;
		end
	endcase
end

always_ff @(posedge wb0_if.clk)
if (rst) begin
	cnt1 <= 16'd0;
	addr <= $urandom(0);
	wb0_if.req <= 1000'd0;
	wb2_if.req <= 1000'd0;
	wb3_if.req <= 1000'd0;
	wb4_if.req <= 1000'd0;
	wb5_if.req <= 1000'd0;
	wb6_if.req <= 1000'd0;
	wb7_if.req <= 1000'd0;
	wb0_if.req.adr <= $urandom();
	wb2_if.req.adr <= $urandom();
	wb3_if.req.adr <= $urandom();
	wb4_if.req.adr <= $urandom();
	wb5_if.req.adr <= $urandom();
	wb6_if.req.adr <= $urandom();
	wb7_if.req.adr <= $urandom();
	wb0_cs <= 1'b0;
	wb2_cs <= 1'b0;
	wb3_cs <= 1'b0;
	wb4_cs <= 1'b0;
	wb5_cs <= 1'b0;
	wb6_cs <= 1'b0;
	wb7_cs <= 1'b0;
	tidcnt <= 4'd0;
	ack0_cnt <= 8'd0;
end
else begin
	cnt1 <= cnt1 + 2'd1;
	app_rdy <= cnt1[4:0] != 5'd0;
	app_wdf_rdy = cnt1[4:0] != 5'd0;
	if (cnt1[6:0]==7'd10) begin
		wb0_cs <= 1'b1;
		wb0_if.req <= 1000'd0;
		wb0_if.req.tid <= 13'd0;	// {6'd1,3'd0,tidcnt}; must be zero to stream
		wb0_if.req.blen <= 8'd29;
		wb0_if.req.cyc <= 1'b1;
		wb0_if.req.stb <= 1'b1;
		wb0_if.req.adr <= $urandom();
		wb0_if.req.sel <= 32'hFFFFFFFF;
		wb0_if.req.we <= 1'b0;
		wb0_if.req.dat <= {8{32'hDEADBEEF}};
		tidcnt <= tidcnt + 1;
	end
	
	if (wb0_if.resp.ack) begin
		ack0_cnt <= ack0_cnt + 1;
		if (ack0_cnt==8'd29) begin
			ack0_cnt <= 8'd0;
			wb0_cs <= 1'b0;
			wb0_if.req <= 1000'd0;
		end
	end

end

always_ff @(posedge ch1_if.clk)
if (rst) begin
	got_ack <= 1'b1;
	wb1_cs <= 1'b0;
	wb1_if.req <= 1000'd0;
end
else begin
	if (!ch1_if.resp.stall && ($urandom() % 100) < 20 && got_ack) begin
		got_ack <= 1'b0;
		rnd = $urandom();
		wb1_cs <= 1'b1;
		wb1_if.req <= 1000'd0;
		wb1_if.req.tid <= {6'd2,3'd0,tidcnt};
		wb1_if.req.blen <= 8'd0;
		wb1_if.req.cyc <= 1'b1;//(rnd % 100) < 10;
		wb1_if.req.stb <= 1'b1;//(rnd % 100) < 10;
		wb1_if.req.adr <= (rnd % 100) < 30 ? $urandom() : 32'h0;
//		wb1_if.req.adr <= ch1_adr;
		wb1_if.req.sel <= 32'hFFFFFFFF;
		wb1_if.req.we <= rnd;
//		wb1_if.req.we <= ch1_we;
		wb1_if.req.dat <= {8{32'hDEADBEEF}};
	end
	if (wb1_if.resp.ack) begin
		got_ack <= 1'b1;
		wb1_if.req <= 1000'd0;
		wb1_cs <= 1'b0;
	end
	if (wb1_if.resp.rty) begin
		wb1_if.req <= 1000'd0;
		wb1_if.req.tid <= {6'd2,3'd0,tidcnt};
		wb1_if.req.blen <= 8'd0;
		wb1_if.req.cyc <= (rnd % 100) < 10;
		wb1_if.req.stb <= (rnd % 100) < 10;
		wb1_if.req.adr <= ch1_adr;
		wb1_if.req.sel <= 32'hFFFFFFFF;
		wb1_if.req.we <= rnd;//ch1_we;
		wb1_if.req.dat <= {8{32'hDEADBEEF}};
	end
end

always_ff @(posedge ch7_if.clk)
if (rst) begin
	got_ack7 <= 1'b1;
	wb7_cs <= 1'b0;
	wb7_if.req <= 1000'd0;
end
else begin
	if (!ch7_if.resp.stall && ($urandom() % 100) < 20 && got_ack7) begin
		got_ack7 <= 1'b0;
		rnd7 = $urandom();
		wb7_cs <= 1'b1;
		wb7_if.req <= 1000'd0;
		wb7_if.req.tid <= {6'd2,3'd0,tidcnt};
		wb7_if.req.blen <= 8'd0;
		wb7_if.req.cyc <= 1'b1;//(rnd % 100) < 10;
		wb7_if.req.stb <= 1'b1;//(rnd % 100) < 10;
		wb7_if.req.adr <= (rnd7 % 100) < 30 ? $urandom() : 32'h0;
//		wb7_if.req.adr <= ch1_adr;
		wb7_if.req.sel <= 32'hFFFFFFFF;
		wb7_if.req.we <= rnd7;
//		wb7_if.req.we <= ch1_we;
		wb7_if.req.dat <= {8{32'hDEADBEEF}};
	end
	if (wb7_if.resp.ack) begin
		got_ack7 <= 1'b1;
		wb7_if.req <= 1000'd0;
		wb7_cs <= 1'b0;
	end
	if (wb7_if.resp.rty) begin
		wb7_if.req <= 1000'd0;
		wb7_if.req.tid <= {6'd2,3'd0,tidcnt};
		wb7_if.req.blen <= 8'd0;
		wb7_if.req.cyc <= (rnd7 % 100) < 10;
		wb7_if.req.stb <= (rnd7 % 100) < 10;
		wb7_if.req.adr <= ch7_adr;
		wb7_if.req.sel <= 32'hFFFFFFFF;
		wb7_if.req.we <= rnd7;//ch1_we;
		wb7_if.req.dat <= {8{32'hDEADBEEF}};
	end
end

endmodule

