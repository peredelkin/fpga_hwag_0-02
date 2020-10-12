`ifndef FLIPFLOP_SV
`define FLIPFLOP_SV

module d_flip_flop #(parameter WIDTH=1) (
input wire clk,
input wire ena,
input wire sload,
input wire [WIDTH-1:0] d_load,
input wire [WIDTH-1:0] d,
input wire srst,
input wire arst,
output reg [WIDTH-1:0] q );

always @(posedge clk,posedge arst) begin
				if(arst) begin
					q <= 0;
	end else if(srst) begin
					q <= 0;
	end else if(sload) begin
					q <= d_load;
	end else if(ena) begin
					q <= d;
	end
end

endmodule

`endif