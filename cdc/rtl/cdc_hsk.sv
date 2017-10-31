
`ifndef __CDC_HSK__
	`define __CDC_HSK__

module cdc_hsk #(
	parameter IDS = 1, // input data stable inside transfer window
	parameter ODS = 1, // output data stable after fransfer (no need latch)
	parameter DW  = 32,
	parameter N   = 2
)(
	input               src_clk,
	input               src_rst_n,

	input               dst_clk,
	input               dst_rst_n,

	input               src_vld,
	output              src_rdy,
	input  [DW-1:0]     src_dat,

	output              dst_vld,
	input               dst_rdy,
	output [DW-1:0]     dst_dat
);

reg src_tgl, dst_tgl;

wire src_tgl_synched, dst_tgl_synched;

reg [DW-1:0] tx_dat, rx_dat;

wire rx_dat_en;

reg rx_vld;

cdc_sync #(.N(N)) src_cdc_sync (.clk(dst_clk), .rst_n(dst_rst_n), .din(src_tgl), .dout(src_tgl_synched));
cdc_sync #(.N(N)) dst_cdc_sync (.clk(src_clk), .rst_n(src_rst_n), .din(dst_tgl), .dout(dst_tgl_synched));

generate
	if (IDS) begin : src_lgc
		assign tx_dat = src_dat;
	end else begin : src_reg
		always_ff @(posedge src_clk, negedge src_rst_n)
			if (~src_rst_n)   tx_dat <= {DW{1'b0}};
			else if (src_vld) tx_dat <= src_dat;
	end
endgenerate

always_ff @(posedge src_clk, negedge src_rst_n)
	if(~src_rst_n)              src_tgl <= 1'b0;
	else if (src_vld & src_rdy) src_tgl <= ~src_tgl;

assign src_rdy = ~(src_tgl^dst_tgl_synched);

always_ff @(posedge dst_clk, negedge dst_rst_n)
	if(~dst_rst_n)                dst_tgl <= 1'b0;
	else if (rx_dat_en & dst_rdy) dst_tgl <= ~dst_tgl;

assign rx_dat_en = dst_tgl ^ src_tgl_synched;

generate
	if (ODS) begin : dst_reg
		always_ff @(posedge dst_clk, negedge dst_rst_n)
			if (~dst_rst_n)     rx_dat <= {DW{1'b0}};
			else if (rx_dat_en) rx_dat <= tx_dat;

		always_ff @(posedge dst_clk, negedge dst_rst_n)
			if (~dst_rst_n)			rx_vld <= 1'b0;
			else                rx_vld <= rx_dat_en;
	end else begin : dst_lgc
		assign rx_dat = tx_dat;

		assign rx_vld = rx_dat_en;
	end
endgenerate

assign dst_vld = rx_vld;

assign dst_dat = rx_dat;

`ifndef SYNTHESIS
bit assert_disable;

initial begin
	assert_disable = 1'b1;
	@(posedge src_clk);
	@(posedge src_clk);
	assert_disable = 1'b0;
end

wire [DW-1:0] transfer_dat;

generate
		if (IDS) assign transfer_dat = src_dat;
		else     assign transfer_dat = tx_dat;
endgenerate

property p_data_stable;
	@(posedge src_clk) disable iff (~src_rst_n || assert_disable)
		(src_vld & src_rdy) |=> ##1 $stable(transfer_dat) ##[1:$] $rose(src_rdy);
endproperty : p_data_stable

sva_cdc_check_transfer_data_stable : assert property(p_data_stable);
`endif //SYNTHESIS

endmodule

`endif// __CDC_HSK__