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

//модуль вычитания со сдигом для модуля двоичного деления
module integer_shift_subtraction #(parameter WIDTH=1) (
input wire d,
input wire clk,
input wire rst,
input wire ena,
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
	.arst(rst),
	.q(remainder_q));
	
isub #(WIDTH+1) sub
(	.a({1'b0,minuend}),
	.b({1'b0,divider}),
	.out({sub_q,difference}));
	
mult2to1 #(WIDTH) mult
(	.sel(sub_q),
	.a(difference),
	.b(minuend),
	.out(remainder));
	
endmodule

`endif