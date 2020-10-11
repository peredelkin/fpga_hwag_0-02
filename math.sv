`ifndef MATH_SV
`define MATH_SV

module add #(parameter WIDTH=1) (
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] b,
output reg [WIDTH:0] out );

always @(*) begin
	out = a + b;
end

endmodule

module sub #(parameter WIDTH=1) (
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] b,
output reg [WIDTH:0] out );

always @(*) begin
	out = a - b;
end

endmodule

`endif