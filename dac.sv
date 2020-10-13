`ifndef DAC_SV
`define DAC_SV

module dac #(parameter WIDTH=8) (clk,ena,data,out);

input wire clk,ena;
input wire [WIDTH-1:0] data;
output reg out;

reg [WIDTH-1:0] integrator;
reg [WIDTH:0] add_data;

initial begin
    out <= 0;
    add_data <= 0;
    integrator <= 0;
end

always @(*) begin
    add_data = data + integrator;
end

always @(posedge clk) begin
	if(ena) begin
		integrator <= add_data;
		out <= ~add_data[WIDTH];
	end
end

endmodule

`endif