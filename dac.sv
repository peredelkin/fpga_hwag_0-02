`ifndef DAC_SV
`define DAC_SV

module dac #(parameter WIDTH=8) (clk,ena,data,out);

input wire clk,ena;
input wire [WIDTH-1:0] data;
output reg out;

reg [WIDTH-1:0] input_data;
reg [WIDTH-1:0] integrator;
reg [WIDTH:0] add_data;

initial begin
    out <= 0;
    add_data <= 0;
    integrator <= 0;
	 input_data <= 0;
end

always @(*) begin
    add_data = input_data + integrator;
end

always @(posedge clk) begin
	if(ena) begin
		input_data <= data;
		integrator <= add_data;
		out <= ~add_data[WIDTH];
	end
end

endmodule

`endif