`ifndef MULT_DEMULT_SV
`define MULT_DEMULT_SV

module mult2to1 #(parameter WIDTH=1) (
input wire sel,
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] b,
output reg [WIDTH-1:0] out );

always @(*) begin
	if(sel) begin
		out <= b;
	end else begin
		out <= a;
	end
end

endmodule

`endif