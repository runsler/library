
`ifndef __SFIFO__
	`define __SFIFO__

module tokens_sfifo #(
	parameter DW   = 32,
	parameter DP   = 8,
	parameter MSKO = 0,
	parameter FWFT = 0

)(
	input           clk,    // Clock
	input           rst_n,  // Asynchronous reset active low

	input 	        src_vld,
	output          src_rdy,
	input [DW-1:0]  src_dat,

	output          dst_vld,
	input           dst_rdy,
	output [DW-1:0] dst_dat
);

genvar i;

generate
	if(DP == 0) begin: dp_ft
		assign dst_vld = src_vld;
		assign src_rdy = dst_rdy;
		assign dst_dat = src_dat;
	end else begin : dp_gt1
		// FIFO on registers
		reg [DW-1:0]  fifo [DP-1:0];
		wire [DP-1:0] fifo_wen;

		wire wen = src_vld & src_rdy;
		wire ren = dst_vld & dst_rdy;

		wire [DP-1:0] rptr_vec_nxt;
		reg  [DP-1:0] rptr_vec;
		wire [DP-1:0] wptr_vec_nxt;
		reg  [DP-1:0] wptr_vec;

		if (DP == 1) begin: rptr_dp_1
			assign rptr_vec_nxt = 1'b1;
		end else begin : rptr_gt1
			assign rptr_vec_nxt = rptr_vec[DP-1] ? {{DP-1{1'b0}}, 1'b1} : (rptr_vec << 1);
		end

		if (DP == 1) begin : wptr_dp_1
			assign wptr_vec_nxt = 1'b1;
		end else begin : wptr_gt1
			assign wptr_vec_nxt = wptr_vec[DP-1] ? {{DP-1{1'b0}}, 1'b1} : (wptr_vec << 1);
		end

		always_ff @(posedge clk, negedge rst_n)
			if(~rst_n)    rptr_vec <= {{DP-1{1'b0}}, 1'b1};
			else if (ren) rptr_vec <= rptr_vec_nxt;

		always_ff @(posedge clk, negedge rst_n)
			if(~rst_n)    wptr_vec <= {{DP-1{1'b0}}, 1'b1};
			else if (wen) wptr_vec <= wptr_vec_nxt;

		wire [DP:0] src_vec;
		wire [DP:0] dst_vec;
		wire [DP:0] vec_nxt;
		reg  [DP:0] vec;

		wire vec_en = (ren ^ wen);
		assign vec_nxt = wen ? {vec[DP-1:0], 1'b1} : (vec >> 1);

		always_ff @(posedge clk, negedge rst_n)
			if(~rst_n)       vec <= {{DP-1{1'b0}}, 1'b1};
			else if (vec_en) vec <= vec_nxt;

		assign src_vec = {1'b0, vec[DP:1]};
		assign dst_vec = {1'b0, vec[DP:1]};

		if (DP ==1) begin : dp_eq1
			if (FWFT) begin : fwft
				assign src_rdy = (~src_vec[DP-1]);
			end else begin : nfwft
				assign src_rdy = (~src_vec[DP-1]) | ren;
			end
		end else begin : nfwft_dp_gt1
			assign src_rdy = (~src_vec[DP-1]);
		end

		for (i = 0; i < DP; i++) begin: gen
			assign fifo_wen[i] = wen & wptr_vec[i];

			always_ff @(posedge clk)
				if (fifo_wen[i]) fifo[i] <= src_dat;
		end

		reg [DW-1:0] mux_dat;

		always_comb begin
			mux_dat = {DW{1'b0}};
			for (int j = 0; j < DP; j++) begin
				mux_dat = mux_dat | {DW{rptr_vec[j]}} & fifo[j];
			end
		end

		if (MSKO) begin : mask_out
			assign dst_dat = {DW{dst_vld}} & mux_dat;
		end else begin : no_mask_out
			assign dst_dat = mux_dat;
		end

		assign dst_vld = dst_vec[0];
	end
endgenerate

endmodule

`endif// __SFIFO__