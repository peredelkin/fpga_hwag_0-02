`ifndef DAC_SV
`define DAC_SV

`include "count.sv"

module sine_cos(clk, reset, en, sine, cos);
  input clk, reset, en;
  output [7:0] sine,cos;
  reg [7:0] sine_r, cos_r;
  
  initial begin
	sine_r <= 0;
	cos_r <= 0;
  end
  
  assign      sine = sine_r + {cos_r[7], cos_r[7], cos_r[7], cos_r[7:3]};
  assign      cos  = cos_r - {sine[7], sine[7], sine[7], sine[7:3]};
  always@(posedge clk,negedge reset)
    begin
        if (!reset) begin
            sine_r <= 0;
            cos_r <= 120;
        end else begin
            if (en) begin
                sine_r <= sine;
                cos_r <= cos;
            end
        end
    end
endmodule

module dac #(parameter WIDTH=8) (clk,ena,data,out);

input wire clk,ena;
input wire [WIDTH-1:0] data;
output reg out;

//test
counter #(18) cnt_0 (.clk(clk),.ena(1'b1),.sel(1'b0),.carry_out(cnt_carry));

wire [7:0] sin_out;
wire [7:0] usin_out = sin_out + 8'd127;
sine_cos sin_cos0 (.clk(clk), .reset(ena), .en(cnt_carry),.sine(sin_out));
//test end

reg [WIDTH-1:0] integrator;
reg [WIDTH:0] add_data;

initial begin
    out <= 0;
    add_data <= 0;
    integrator <= 0;
end

always @(*) begin
    add_data = usin_out + integrator; //data
end

always @(posedge clk) begin
	if(ena) begin
		integrator <= add_data;
		out <= ~add_data[WIDTH];
	end
end

endmodule

`endif