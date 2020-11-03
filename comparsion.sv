`ifndef COMPARSION_SV
`define COMPARSION_SV

module comparator #(parameter WIDTH=1) (
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] b,
output reg agb,
output wire ageb,
output reg aeb,
output wire aleb,
output reg alb);

assign ageb = agb | aeb;
assign aleb = alb | aeb;

always @(*) begin
	if(a > b) agb <= 1'b1;
	else agb <= 1'b0;

	if(a == b) aeb <= 1'b1;
	else aeb <= 1'b0;
	
	if(a < b) alb <= 1'b1;
	else alb <= 1'b0;
end

endmodule

module set_reset_comparator #(parameter WIDTH=1) (
input wire [WIDTH-1:0] set_data,
input wire [WIDTH-1:0] reset_data,
input wire [WIDTH-1:0] data_compare,
input wire clk,
input wire rst,
output wire out
);

comparator #(24) set_comp
(   .a(data_compare),
    .b(set_data),
    .aeb(set_comp_out));

comparator #(24) reset_comp
(   .a(data_compare),
    .b(reset_data),
    .aeb(reset_comp_out));
    
d_flip_flop #(1) d_ff_out 
(   .clk(clk),
    .ena(set_comp_out),
    .sload(1'b0),
    .d(1'b1),
    .srst(reset_comp_out),
    .arst(rst),
    .q(out));
    
endmodule

`endif
