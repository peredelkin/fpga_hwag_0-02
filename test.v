`timescale 1us/1us

`include "hwag.sv"
`include "dac.sv"

module clk_phase_shift(clk,rst,out1,out2,out3);

input wire clk,rst;

output reg out1,out2,out3;

initial begin
out1 <= 0;
out2 <= 0;
out3 <= 0;
end

wire [1:0] cnt_out;

counter #(2) cnt (.clk(clk),.ena(1'b1),.sel(1'b0),.sload(1'b0),.d_load(2'd0),.srst(cnt_out[1]),.arst(rst),.q(cnt_out),.carry_out(cnt_carry));


always @(posedge clk) begin
    case (cnt_out)
    0: begin out1 <= 1'b1; out2 <= 1'b0; out3 <= 1'b0; end
    1: begin out1 <= 1'b0; out2 <= 1'b1; out3 <= 1'b0; end
    2: begin out1 <= 1'b0; out2 <= 1'b0; out3 <= 1'b1; end
    endcase
end

endmodule

module test();

reg clk,rst,vr,cam,cam_phase;

reg [7:0] scnt;
reg [7:0] scnt_top;
reg [7:0] tckc;
reg [7:0] tckc_top;
reg [7:0] tcnt;

hwag_core hwag(.clk(clk),.rst(rst),.cap(vr),.cap_edge_sel(1'b1));

dac #(6) dac0 (.clk(clk),.ena(ena_out1),.data(tckc),.out(dac_out1));
dac #(6) dac1 (.clk(clk),.ena(ena_out2),.data(tckc + 8'd21),.out(dac_out2));
dac #(6) dac2 (.clk(clk),.ena(ena_out3),.data(tckc + 8'd42),.out(dac_out3));

clk_phase_shift clk_shift (.clk(clk),.rst(rst),.out1(ena_out1),.out2(ena_out2),.out3(ena_out3));

always @(posedge clk) begin
    if(scnt == scnt_top) begin
        scnt <= 8'd0;
        if(tckc == tckc_top) begin
            tckc <= 8'd0;
            vr <= 1'b0;
            if(tcnt == 57) begin
                tcnt <= 8'd0;
                scnt_top <= scnt_top + 8'd1;
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
always #1 rst <= 1'b0;

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
    scnt_top <= 8'd63;
    tckc <= 8'd0;
    tckc_top <= 8'd63;
    tcnt <= 8'd53;
    cam <= 1'b1;
    cam_phase <= 1'b0;
    
    #20000 $finish();
end
endmodule
