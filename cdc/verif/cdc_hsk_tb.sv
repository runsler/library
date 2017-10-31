
`ifndef __CDC_HSK_TB__
	`define __CDC_HSK_TB__

module cdc_hsk_tb ();

time src_clk_per = 5ns;
time dst_clk_per = 7ns;

bit src_clk, dst_clk;

task change_ratio();
	randcase
		1: begin src_clk_per = $urandom_range(5,10); dst_clk_per = $urandom_range(5,10); end
		1: begin src_clk_per = $urandom_range(6,10); dst_clk_per = $urandom_range(1,5) ; end
		1: begin src_clk_per = $urandom_range(1,5) ; dst_clk_per = $urandom_range(6,10); end
	endcase
endtask

bit rst_n;

// clock generators
always #(src_clk_per) src_clk = ~src_clk;

always #(dst_clk_per) dst_clk = ~dst_clk;

localparam DW = 32;
localparam N  = 2;

localparam N_CHECK = 10;
localparam N_ITTER = 100;

reg [DW-1:0] src_dat, dst_dat;

bit  src_vld;
wire dst_vld;
wire src_rdy;
bit  dst_rdy;

task transfer();
	src_dat  = $random();
	src_vld  = 1;

	@(posedge dst_vld);
  	dst_rdy = 1;
	@(posedge src_rdy);
	src_vld  = 0;
	dst_rdy  = 0;
endtask

always_ff @(posedge dst_vld) begin
	if (src_dat != dst_dat) $error("data compare fail exp: %h rcv: %h at %0t ", src_dat, dst_dat, $realtime());
end

initial begin
	rst_n    = 0;
	src_dat  = 0;
	$display("start test");

	#32ns;
	rst_n = 1;

	for (int j = 0; j < N_ITTER; j++) begin

	change_ratio();

		for (int i = 1; i <= N_CHECK; i++) begin
			 transfer();
			 $display("cycle #%d ", j*N_CHECK + i);
		end
	end

	#100ns;
	$finish;
end


cdc_hsk #(.IDS(0), .ODS(1), .DW(DW), .N(N)) i_cdc_hsk (
	.src_clk  (src_clk  ),
	.src_rst_n(rst_n    ),
	.dst_clk  (dst_clk  ),
	.dst_rst_n(rst_n    ),

	.src_vld  (src_vld  ),
	.src_rdy  (src_rdy  ),
	.src_dat  (src_dat  ),
	.dst_vld  (dst_vld  ),
	.dst_rdy  (dst_rdy  ),
	.dst_dat  (dst_dat  )
);


endmodule
`endif // __CDC_HSK_TB__