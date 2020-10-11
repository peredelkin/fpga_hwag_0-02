`ifndef CAPTURE_SV
`define CAPTURE_SV

module cap_edge(
input wire clk,
input wire ena,
input wire cap,
input wire srst,
input wire arst,
output wire rise,
output wire fall);

wire [1:0] dff_cap_out;
assign rise = dff_cap_out[0] & ~dff_cap_out[1];
assign fall = dff_cap_out[1] & ~dff_cap_out[0];

d_flip_flop #(2) dff_cap (.clk(clk),.ena(ena),.d({dff_cap_out[0],cap}),.srst(srst),.arst(arst),.q(dff_cap_out));

endmodule

`endif