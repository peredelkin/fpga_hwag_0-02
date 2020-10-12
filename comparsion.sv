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

`endif