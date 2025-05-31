
module mpmc11_od_data_latch(rst, clk, port, fifo_port, rdy, rd_data, port_data);
parameter MDW = 256;
input rst;
input clk;
input [3:0] port;
input [3:0] fifo_port;
input rdy;
input [MDW-1:0] rd_data;
output reg [MDW-1:0] port_data;

always_ff @(posedge clk)
if (rst)
	port_data <= {MDW{1'b0}};
else begin
	if (rdy && port==fifo_port)
		port_data <= rd_data;
end

endmodule
