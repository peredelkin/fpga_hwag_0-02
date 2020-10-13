`ifndef DAC_SV
`define DAC_SV

module dac #(parameter WIDTH=8) (clk,data,out);

//test cnt
reg [23:0] data_test;
initial data_test <= 0;
//test cnt end

input wire clk;
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
    add_data = data_test[23:16] + integrator;
end

always @(posedge clk) begin
    integrator <= add_data;
    out <= add_data[WIDTH];
	 data_test <= data_test + 1'b1;
end

endmodule

`endif