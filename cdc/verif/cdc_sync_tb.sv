
`ifndef __CDC_SYNC_TB__
	`define  __CDC_SYNC_TB__

module cdc_sync_tb ();

time src_clk_per = 5ns;
time dst_clk_per = 7ns;

bit scr_clk, dst_clk;

task change_ratio();
	randcase
		1: begin src_clk_per = $urandom_range(5,10); dst_clk_per = $urandom_range(5,10); end
		1: begin src_clk_per = $urandom_range(6,10); dst_clk_per = $urandom_range(1,5) ; end
		1: begin src_clk_per = $urandom_range(1,5) ; dst_clk_per = $urandom_range(6,10); end
	endcase
endtask

bit rst_n;

// clock generators
always #(src_clk_per) scr_clk = ~scr_clk;

always #(dst_clk_per) dst_clk = ~dst_clk;

localparam DW = 32;
localparam N  = 2;

localparam N_CHECK = 10;
localparam N_ITTER = 100;


reg [DW-1:0] scr_data, dst_data;

initial begin
	rst_n    = 0;
	scr_data = 0;
	$display("start test");

	#32ns;
	rst_n = 1;

	for (int j = 0; j < N_ITTER; j++) begin

	change_ratio();

		for (int i = 1; i <= N_CHECK; i++) begin
			@(posedge scr_clk);
			scr_data = $random();
			@(posedge scr_clk);

			repeat(N)  @(posedge dst_clk);

			@(negedge dst_clk);

			if (scr_data != dst_data) $error("data compare fail exp: %h rcv: %h at %0t ", scr_data, dst_data, $realtime());
			else 											$display("check succes #%d ", j*N_CHECK + i);
		end
	end

	#100ns;
	$finish;
end

cdc_sync #(.DW(DW), .N(N)) i_cdc_sync (.clk(dst_clk), .rst_n(rst_n), .din(scr_data), .dout(dst_data));

endmodule

`endif// __CDC_SYNC_TB__