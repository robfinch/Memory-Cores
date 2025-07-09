import fta_bus_pkg::*;
import mpmc11_pkg::*;

module mpmc11_tb();

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
reg [31:0] rnd;
reg [2:0] ch1_cmd;
reg [31:0] ch1_adr;
reg ch1_we;
reg [3:0] tidcnt;
reg got_ack;

fta_bus_interface #(.DATA_WIDTH(256)) ch0_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch1_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch2_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch3_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch4_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch5_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch6_if();
fta_bus_interface #(.DATA_WIDTH(256)) ch7_if();

always_comb
begin
	ch2_if.req = 1000'd0;
	ch3_if.req = 1000'd0;
	ch4_if.req = 1000'd0;
	ch5_if.req = 1000'd0;
	ch6_if.req = 1000'd0;
	ch7_if.req = 1000'd0;
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
	.CACHE(9'h002),
	.PORT_PRESENT(9'h103))
umpmc1
(
	.rst(rst),
	.sys_clk_i(clk),
	.mem_ui_rst(rst),
	.mem_ui_clk(clk),
	.calib_complete(1'b1),
	.rstn(),
	.app_waddr(),
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
	state <= 4'd0;
	cnt1 <= 16'd0;
	addr <= $urandom(0);
	app_rd_data_valid <= 1'b0;
	ch0_if.req <= 1000'd0;
	ch0_if.req.adr <= $urandom();
	tidcnt <= 4'd0;
end
else begin
	ch0_if.req <= 1000'd0;
	cnt1 <= cnt1 + 2'd1;
	app_rdy <= cnt1[4:0] != 5'd0;
	app_wdf_rdy = cnt1[4:0] != 5'd0;
	if (cnt1[6:0]==7'd10) begin
		ch0_if.req <= 1000'd0;
		ch0_if.req.tid <= {6'd1,3'd0,tidcnt};
		ch0_if.req.cmd <= fta_bus_pkg::CMD_LOAD;
		ch0_if.req.blen <= 8'd29;
		ch0_if.req.cyc <= 1'b1;
		ch0_if.req.adr <= $urandom();
		ch0_if.req.sel <= 32'hFFFFFFFF;
		ch0_if.req.we <= 1'b0;
		ch0_if.req.data1 <= {8{32'hDEADBEEF}};
		tidcnt <= tidcnt + 1;
	end
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
				app_rd_data_end <= 1'b1;
				app_rd_data <= {8{32'hBEEFDEAD}};
			end
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

always_ff @(posedge ch1_if.clk)
if (rst) begin
	got_ack <= 1'b1;
end
else begin
	ch1_if.req <= 1000'd0;
	if (!ch1_if.resp.stall && ($urandom() % 100) < 20 && got_ack) begin
		got_ack <= 1'b0;
		rnd = $urandom();
		ch1_if.req <= 1000'd0;
		ch1_if.req.tid <= {6'd2,3'd0,tidcnt};
		ch1_cmd = rnd[0] ? fta_bus_pkg::CMD_STORE : fta_bus_pkg::CMD_LOAD;
		ch1_if.req.cmd <= ch1_cmd;
		ch1_if.req.blen <= 8'd0;
		ch1_if.req.cyc <= 1'b1;//(rnd % 100) < 10;
		ch1_adr = (rnd % 100) < 10 ? $urandom() : 32'h0;
		ch1_if.req.adr <= ch1_adr;
		ch1_if.req.sel <= 32'hFFFFFFFF;
		ch1_we = rnd;
		ch1_if.req.we <= ch1_we;
		ch1_if.req.data1 <= {8{32'hDEADBEEF}};
		if (ch1_we)
			got_ack <= 1'b1;
	end
	if (ch1_if.resp.ack) begin
		got_ack <= 1'b1;
	end
	if (ch1_if.resp.rty) begin
		ch1_if.req <= 1000'd0;
		ch1_if.req.tid <= {6'd2,3'd0,tidcnt};
		ch1_if.req.cmd <= ch1_cmd;
		ch1_if.req.blen <= 8'd0;
		ch1_if.req.cyc <= (rnd % 100) < 10;
		ch1_if.req.adr <= ch1_adr;
		ch1_if.req.sel <= 32'hFFFFFFFF;
		ch1_if.req.we <= ch1_we;
		ch1_if.req.data1 <= {8{32'hDEADBEEF}};
	end
end

endmodule

