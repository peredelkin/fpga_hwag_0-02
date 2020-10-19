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
wire main_edge;

localparam PCNT_WIDTH = 24;
wire [PCNT_WIDTH-1:0] pcnt_out;
wire pcnt_ovf;

wire [PCNT_WIDTH-1:0] pcnt1_out;
wire [PCNT_WIDTH-1:0] pcnt2_out;
wire [PCNT_WIDTH-1:0] pcnt3_out;

wire gap_found = pcnt1_less_pcnt2 & pcnt3_less_pcnt2;

localparam TCNT_WIDTH = 6;
localparam [TCNT_WIDTH-1:0] tcnt_load = 2;
wire [TCNT_WIDTH-1:0] tcnt_out;
localparam [TCNT_WIDTH-1:0] tcnt_top = 57;

//детект фронтов
cap_edge input_capture (	.clk(clk),
									.ena(1'b1),
									.cap(cap),
									.srst(1'b0),
									.arst(rst),
									.rise(cap_rise), /*передний фронт*/
									.fall(cap_fall)); /*задний фронт*/
//выбор фронта
mult2to1 #(1) cap_edge_switch (	.sel(cap_edge_sel), /*0 = передний фронт, 1 = задний фронт*/
											.a(cap_rise),
											.b(cap_fall),
											.out(main_edge) );
//запуск таймера захвата периода
d_flip_flop #(1) dff_pcnt_start (.clk(clk),
											.ena(main_edge & ~pcnt_start),
											.d(1'b1),
											.srst(pcnt_ovf), /*остановка при OVF PCNT*/
											.arst(rst),
											.q(pcnt_start));
//счетчик периода
counter #(PCNT_WIDTH) pcnt (	.clk(clk),
										.ena(pcnt_start),
										.sel(1'b0),
										.sload(1'b0),
										.srst(main_edge),
										.arst(rst),
										.q(pcnt_out),
										.carry_out(pcnt_ovf));
//первый регистр захвата периода
d_flip_flop #(PCNT_WIDTH) pcnt1 (	.clk(clk),
												.ena(main_edge & ~tcnt_equal_top), /*игнорирование захвата в метке*/
												.d(pcnt_out),
												.srst(pcnt_ovf), /*сброс при OVF PCNT*/
												.arst(rst),
												.q(pcnt1_out));
//второй регистр захвата периода
d_flip_flop #(PCNT_WIDTH) pcnt2 (	.clk(clk),
												.ena(main_edge & ~tcnt_equal_top), /*игнорирование захвата в метке*/
												.d(pcnt1_out),
												.srst(pcnt_ovf), /*сброс при OVF PCNT*/
												.arst(rst),
												.q(pcnt2_out));
//третий регистр захвата периода
d_flip_flop #(PCNT_WIDTH) pcnt3 (	.clk(clk),
												.ena(main_edge & ~tcnt_equal_top), /*игнорирование захвата в метке*/
												.d(pcnt2_out),
												.srst(pcnt_ovf), /*сброс при OVF PCNT*/
												.arst(rst),
												.q(pcnt3_out));
//первая пара компараторов (pcnt1 < pcnt2/2)
comparator #(PCNT_WIDTH-1) pcnt1_comp_pcnt2 (.a(pcnt1_out[PCNT_WIDTH-2:0]),
															.b(pcnt2_out[PCNT_WIDTH-1:1]),
															.alb(pcnt1_less_pcnt2));
//вторая пара компараторов (pcnt3 < pcnt2/2)
comparator #(PCNT_WIDTH-1) pcnt3_comp_pcnt2 (.a(pcnt3_out[PCNT_WIDTH-2:0]),
															.b(pcnt2_out[PCNT_WIDTH-1:1]),
															.alb(pcnt3_less_pcnt2));
//триггер запуска генератора углов по условию: (pcnt3 < pcnt2/2 > pcnt1)
d_flip_flop #(1) dff_hwag_start (.clk(clk),
											.ena(main_edge & gap_found & ~hwag_start),
											.d(1'b1),
											.srst(~pcnt_start),
											.arst(rst),
											.q(hwag_start));
//счетчик зубов дпкв
counter #(TCNT_WIDTH) tcnt (	.clk(clk),
										.ena(main_edge & hwag_start),
										.sel(1'b0),
										.sload(~hwag_start),
										.d_load(tcnt_load),
										.srst((main_edge & tcnt_equal_top) | ~pcnt_start),
										.arst(rst),
										.q(tcnt_out));
//компаратор счетчика зубов
comparator #(TCNT_WIDTH) tcnt_comp_top (	.a(tcnt_out),
														.b(tcnt_top),
														.aeb(tcnt_equal_top));

endmodule

`endif