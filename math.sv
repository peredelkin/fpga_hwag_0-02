`ifndef MATH_SV
`define MATH_SV

module iadd #(parameter WIDTH=1) (
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] b,
output reg [WIDTH:0] out );

always @(*) begin
	out = a + b;
end

endmodule

module isub #(parameter WIDTH=1) (
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] b,
output reg [WIDTH:0] out );

always @(*) begin
	out = a - b;
end

endmodule

//модуль вычитания со сдигом для модуля целочисленного деления
module integer_shift_sub #(parameter WIDTH=1) (
input wire d,
input wire clk,
input wire rst,
input wire ena,
input wire start,
input wire [WIDTH-1:0] divider,
output wire[WIDTH-1:0] remainder,
output wire q );

wire [WIDTH-1:0] difference;
wire [WIDTH-1:0] minuend = {remainder_q[WIDTH-2:0],d};
wire [WIDTH-2:0] remainder_q;
wire [WIDTH-2:0] remainder_d = remainder[WIDTH-2:0];
wire sub_q;
not(q,sub_q);

d_flip_flop #(WIDTH-1) d_remainder
(	.clk(clk),
	.ena(ena),
	.d(remainder_d),
	.srst(~start),
	.arst(rst),
	.q(remainder_q));
	
isub #(WIDTH) sub
(	.a({minuend}),
	.b({divider}),
	.out({sub_q,difference}));
	
mult2to1 #(WIDTH) mult
(	.sel(sub_q),
	.a(difference),
	.b(minuend),
	.out(remainder));
	
endmodule

//модуль целочисленного деления
module integer_div #(parameter WIDTH=1) (
input wire clk,
input wire rst,
input wire start,
input wire [WIDTH-1:0] dividend,
input wire [WIDTH-1:0] divider,
output wire[WIDTH-1:0] remainder,
output wire[WIDTH-1:0] result,
output wire rdy);

wire [WIDTH-1:0] dividend_q;
wire result_d;
assign result = {dividend_q[WIDTH-2:0],result_d};

localparam CNT_WIDTH = $clog2(WIDTH);
localparam [CNT_WIDTH-1:0] CNT_TOP = WIDTH - 1;

counter #(CNT_WIDTH) step_count
(	.clk(clk),
	.ena(~rdy & start),
	.sel(1'b1),
	.sload(~start),
	.d_load(CNT_TOP),
	.arst(rst),
	.carry_out(rdy));

d_flip_flop #(WIDTH) d_dividend 
(	.clk(clk),
	.ena(~rdy),
	.sload(~start),
	.d_load(dividend),
	.d(result),
	.arst(rst),
	.q(dividend_q));
                                                
integer_shift_sub #(WIDTH) shift_sub
(	.d(dividend_q[WIDTH-1]),
	.clk(clk),
	.rst(rst),
	.ena(~rdy),
	.start(start),
	.divider(divider),
	.remainder(remainder),
	.q(result_d));

endmodule

`endif