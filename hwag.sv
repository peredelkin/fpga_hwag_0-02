`ifndef HWAG_SV
`define HWAG_SV

`include "capture.sv"
`include "count.sv"

module hwag_core(
input wire clk,
input wire rst,
input wire cap,
input wire cap_edge_sel
);

localparam PCNT_WIDTH = 8;

wire cap_rise;
wire cap_fall;
wire cap_edge_out;
wire [PCNT_WIDTH-1:0] pcnt_out;
wire pcnt_carry_out;
wire [PCNT_WIDTH-1:0] pcnt1_out;
wire [PCNT_WIDTH-1:0] pcnt2_out;
wire [PCNT_WIDTH-1:0] pcnt3_out;

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

counter #(PCNT_WIDTH) pcnt (	.clk(clk),
										.ena(1'b1),
										.sel(1'b0),
										.sload(1'b0),
										.d_load(8'd0),
										.srst(cap_edge_out),
										.arst(rst),
										.q(pcnt_out),
										.carry_out(pcnt_carry_out));
										
d_flip_flop #(PCNT_WIDTH) pcnt1 (	.clk(clk),
												.ena(cap_edge_out),
												.d(pcnt_out),
												.srst(1'b0),
												.arst(rst),
												.q(pcnt1_out));
												
d_flip_flop #(PCNT_WIDTH) pcnt2 (	.clk(clk),
												.ena(cap_edge_out),
												.d(pcnt1_out),
												.srst(1'b0),
												.arst(rst),
												.q(pcnt2_out));
												
d_flip_flop #(PCNT_WIDTH) pcnt3 (	.clk(clk),
												.ena(cap_edge_out),
												.d(pcnt2_out),
												.srst(1'b0),
												.arst(rst),
												.q(pcnt3_out));

endmodule

`endif