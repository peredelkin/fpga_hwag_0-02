`ifndef HWAG_SV
`define HWAG_SV

`include "capture.sv"
`include "count.sv"
`include "comparsion.sv"

module hwag_core(
input wire clk,
input wire rst,
input wire cap,
input wire cap_edge_sel
);

wire cap_rise;
wire cap_fall;
wire cap_edge_out;

localparam PCNT_WIDTH = 24;
localparam [PCNT_WIDTH-1:0] pcnt_load = 0;
wire [PCNT_WIDTH-1:0] pcnt_out;
wire pcnt_carry_out;

wire [PCNT_WIDTH-1:0] pcnt1_out;
wire [PCNT_WIDTH-1:0] pcnt2_out;
wire [PCNT_WIDTH-1:0] pcnt3_out;

wire gap_found = pcnt1_less_pcnt2 & pcnt3_less_pcnt2;

localparam TCNT_WIDTH = 6;
localparam [TCNT_WIDTH-1:0] tcnt_load = 2;
wire [TCNT_WIDTH-1:0] tcnt_out;
localparam [TCNT_WIDTH-1:0] tcnt_top = 57;

cap_edge input_capture (	.clk(clk),
									.ena(1'b1),
									.cap(cap),
									.srst(1'b0),
									.arst(rst),
									.rise(cap_rise),
									.fall(cap_fall));
									
mult2to1 #(1) cap_edge_switch (	.sel(cap_edge_sel),
											.a(cap_rise),
											.b(cap_fall),
											.out(cap_edge_out) );

d_flip_flop #(1) dff_pcnt_start (.clk(clk),
											.ena(cap_edge_out & ~pcnt_start),
											.d(1'b1),
											.srst(pcnt_carry_out),
											.arst(rst),
											.q(pcnt_start));
											
counter #(PCNT_WIDTH) pcnt (	.clk(clk),
										.ena(pcnt_start),
										.sel(1'b0),
										.sload(1'b0),
										.d_load(pcnt_load),
										.srst(cap_edge_out),
										.arst(rst),
										.q(pcnt_out),
										.carry_out(pcnt_carry_out));
										
d_flip_flop #(PCNT_WIDTH) pcnt1 (	.clk(clk),
												.ena(cap_edge_out & ~tcnt_equal_top),
												.d(pcnt_out),
												.srst(1'b0),
												.arst(rst),
												.q(pcnt1_out));
												
d_flip_flop #(PCNT_WIDTH) pcnt2 (	.clk(clk),
												.ena(cap_edge_out & ~tcnt_equal_top),
												.d(pcnt1_out),
												.srst(1'b0),
												.arst(rst),
												.q(pcnt2_out));
												
d_flip_flop #(PCNT_WIDTH) pcnt3 (	.clk(clk),
												.ena(cap_edge_out & ~tcnt_equal_top),
												.d(pcnt2_out),
												.srst(1'b0),
												.arst(rst),
												.q(pcnt3_out));
												
comparator #(PCNT_WIDTH-1) pcnt1_comp_pcnt2 (.a(pcnt1_out[PCNT_WIDTH-2:0]),
															.b(pcnt2_out[PCNT_WIDTH-1:1]),
															.alb(pcnt1_less_pcnt2));
															
comparator #(PCNT_WIDTH-1) pcnt3_comp_pcnt2 (.a(pcnt3_out[PCNT_WIDTH-2:0]),
															.b(pcnt2_out[PCNT_WIDTH-1:1]),
															.alb(pcnt3_less_pcnt2));

d_flip_flop #(1) dff_hwag_start (.clk(clk),
											.ena(cap_edge_out & gap_found & ~hwag_start),
											.d(1'b1),
											.srst(1'b0),
											.arst(rst),
											.q(hwag_start));

counter #(TCNT_WIDTH) tcnt (	.clk(clk),
										.ena(cap_edge_out & hwag_start),
										.sel(1'b0),
										.sload(~hwag_start),
										.d_load(tcnt_load),
										.srst((cap_edge_out & tcnt_equal_top) | ~pcnt_start),
										.arst(rst),
										.q(tcnt_out),
										.carry_out(tcnt_carry_out));

comparator #(TCNT_WIDTH) tcnt_comp_top (	.a(tcnt_out),
														.b(tcnt_top),
														.aeb(tcnt_equal_top));

endmodule

`endif