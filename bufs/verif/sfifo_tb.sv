
`ifndef __SFIFO_TB__
	`define __SFIFO_TB__

module sfifo_tb ();

time clk_per = 5ns;

bit rst_n, clk;

// clock generators
always #(clk_per) clk = ~clk;

localparam DW = 32;
localparam DP = 8;

localparam N_CHECK = 10;
localparam N_ITTER = 100;

bit          src_vld;
wire         src_rdy;
bit [DW-1:0] src_dat;
wire dst_vld;
bit  dst_rdy;
wire [DW-1:0] dst_dat;

task transfer();
	src_vld  = 1;
	@(negedge src_rdy);
	src_vld  = 0;

	dst_rdy = 1;
	@(negedge dst_vld);
	dst_rdy = 0;
endtask

always @(posedge clk) src_dat  = $random();

initial begin
	$display("start test");

	#32ns;
	rst_n = 1;

	for (int j = 0; j < N_ITTER; j++) begin

		for (int i = 1; i <= N_CHECK; i++) begin
			 transfer();
			 $display("cycle #%d ", j*N_CHECK + i);
		end
	end

	#100ns;
	$finish;
end

tokens_sfifo #(.DW(DW), .DP(DP), .FWFT(1)) i_tokens_sfifo (
	.clk    (clk    ),
	.rst_n  (rst_n  ),
	.src_vld(src_vld),
	.src_rdy(src_rdy),
	.src_dat(src_dat),
	.dst_vld(dst_vld),
	.dst_rdy(dst_rdy),
	.dst_dat(dst_dat)
);

endmodule

`endif//__SFIFO_TB__