`ifndef COUNT_SV
`define COUNT_SV

`include "flipflop.sv"
`include "math.sv"
`include "mult_demult.sv"

module counter #(parameter WIDTH=8) (
input wire clk,
input wire ena,
input wire sel,
input wire sload,
input wire [WIDTH-1:0] d_load,
input wire srst,
input wire arst,
output wire [WIDTH-1:0] q,
output wire carry_out);

wire [WIDTH-1:0] add_out;
wire [WIDTH-1:0] sub_out;
wire [WIDTH-1:0] add_mult_sub_out;
wire [WIDTH-1:0] load_mult_add_sub_out;

wire add_carry;
wire sub_carry;

assign carry_out = (add_carry & ~sel) | (sub_carry & sel);

localparam [WIDTH-1:0] add_sub_const = 1;

mult2to1 #(WIDTH) mult0 (.sel(sload),.a(add_mult_sub_out),.b(d_load),.out(load_mult_add_sub_out) );
d_flip_flop #(WIDTH) dff0 (.clk(clk),.ena(ena | sload),.d(load_mult_add_sub_out),.srst(srst),.arst(arst),.q(q) );
add #(WIDTH) add0 (.a(q),.b(add_sub_const),.out({add_carry,add_out}) );
sub #(WIDTH) sub0 (.a(q),.b(add_sub_const),.out({sub_carry,sub_out}) );
mult2to1 #(WIDTH) mult1 (.sel(sel),.a(add_out),.b(sub_out),.out(add_mult_sub_out) );

endmodule

`endif