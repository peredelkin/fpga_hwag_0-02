`timescale 1us/1us

`include "hwag.sv"

module test();

reg clk;
reg rst;
reg cap;

hwag_core hwag(.clk(clk),.rst(rst),.cap(cap),.cap_edge_sel(1'b1));

always #1 clk <= ~clk;
always #2 rst <= 1'b0;
always #128 cap <= ~cap;

//integer ssram_i;

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test);

    //for(ssram_i = 0; ssram_i < 64; ssram_i = ssram_i + 1) begin
    //    $dumpvars(1, hwag0.ssram_out[ssram_i]);
    //end
    
    clk <= 1'b0;
    rst <= 1'b1;
    cap <= 1'b0;
    
    #2048 $finish();
end
endmodule
