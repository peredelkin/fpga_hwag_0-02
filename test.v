`timescale 1us/1us

`include "hwag.sv"
`include "dac.sv"

module test();

reg clk,rst,vr,cam,cam_phase;

reg [7:0] scnt;
reg [7:0] scnt_top;
reg [7:0] tckc;
reg [7:0] tckc_top;
reg [7:0] tcnt;

hwag hwag0 (.clk(clk),.rst(rst),.cap(vr),.second_edge(second_edge),.hwag_start(hwag_start));


always @(posedge clk) begin
    if(scnt == scnt_top) begin
        scnt <= 8'd0;
        if(tckc == tckc_top) begin
            tckc <= 8'd0;
            vr <= 1'b0;
            if(tcnt == 57) begin
                tcnt <= 8'd0;
                tckc_top <= 8'd63;
            end else begin
                
                if(tcnt == 30) begin
                    cam_phase <= ~cam_phase;
                end
    
                if(cam_phase) begin
                    if(tcnt == 54) begin
                        cam <= 1'b0;
                    end
                    if(tcnt == 4) begin
                        cam <= 1'b1;
                    end
                end
                
                if(tcnt == 56) begin
                    tckc_top <= 8'd191;
                    
                    scnt_top <= scnt_top - 8'd1;
                end
                tcnt <= tcnt + 8'd1;
            end
        end else begin
            if(tckc == (tckc_top/2)) begin
                vr <= 1'b1;
            end
            tckc <= tckc + 8'd1;
        end
    end else begin
        scnt <= scnt + 8'd1;
    end
end

always #1 clk <= ~clk;
always #3 rst <= 1'b0;

//integer ssram_i;

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test);

    //for(ssram_i = 0; ssram_i < 64; ssram_i = ssram_i + 1) begin
    //    $dumpvars(1, hwag0.ssram_out[ssram_i]);
    //end
    
    clk <= 1'b0;
    rst <= 1'b1;
    
    vr <= 1'b0;
    scnt <= 8'd0;
    scnt_top <= 8'd31;
    tckc <= 8'd0;
    tckc_top <= 8'd63;
    tcnt <= 8'd53;
    cam <= 1'b1;
    cam_phase <= 1'b0;
    
    #1000000 $finish();
end
endmodule
