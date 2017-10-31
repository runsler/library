
`ifndef __CDC_SYNC__
	`define __CDC_SYNC__

//==========================================================
//
// Description
//
//==========================================================

module cdc_sync #(
	parameter DW = 1,
	parameter N  = 2
)(
	input               clk,    // Clock
	input               rst_n,  // Asynchronous reset active low

	input      [DW-1:0] din,    //input data  (async)
	output reg [DW-1:0] dout    //output data (sync to clk)
);

  reg [N-1:0][DW-1:0] d_sync;


	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n) d_sync <= {(DW*N){1'b0}};
		else        d_sync <= {d_sync[N-1:0], din};

 `ifdef SYNTHESIS
  assign dout = dsync[N-1];

  `else // CDC metastable emulation

  genvar i;

  generate
  	for (i = 0; i < DW; i++) begin : cdc_emu
  		always_comb
				randcase
				1: dout[i] = d_sync[N-2][i];
				1: dout[i] = d_sync[N-1][i];
				endcase
  	end
  endgenerate
  `endif// SYNTHESIS

endmodule

`endif// __CDC_SYNC__