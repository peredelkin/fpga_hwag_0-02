`ifndef HWAG_SV
`define HWAG_SV

`include "capture.sv"
`include "count.sv"
`include "comparsion.sv"

module hwag_core(
input wire clk,
input wire rst,
input wire cap,
input wire cap_edge_sel
);

/*передний фронт захвата дпкв*/
wire cap_rise;
/*задний фронт захвата дпкв*/
wire cap_fall;
/*выбранный фронт захвата дпкв*/
wire main_edge;

/*разрядность счетчика захвата дпкв*/
localparam PCNT_WIDTH = 24;
/*выход счечтка захвата дпкв*/
wire [PCNT_WIDTH-1:0] pcnt_out;
/*сигнал переполнения счетчика захвата дпкв*/
wire pcnt_ovf;

/*захват периода с игнорированием метки*/
wire pcnt123_ena = main_edge & ~tcnt_equal_top;
/*выходы регистров захвата дпкв*/
wire [PCNT_WIDTH-1:0] pcnt1_out;
wire [PCNT_WIDTH-1:0] pcnt2_out;
wire [PCNT_WIDTH-1:0] pcnt3_out;

/*метка найдена (pcnt1 < pcnt2/2 > pcnt3)*/
wire gap_found = pcnt1_less_pcnt2 & pcnt3_less_pcnt2;
/*метка во время нормального зуба*/
wire gap_drn_normal_tooth = hwag_start & pcnt1_less_pcnt & ~tcnt_equal_top;
/*разрешение запуска генератора углов*/
wire hwag_ena = main_edge & gap_found & ~hwag_start;

/*разрядность счетчика зубов шкива коленвала*/
localparam TCNT_WIDTH = 6;
/*значение счетчка зубов в момент синхронизации*/
localparam [TCNT_WIDTH-1:0] tcnt_load = 2;
/*выход счетчка зубов шкава коленвала*/
wire [TCNT_WIDTH-1:0] tcnt_out;
/*количество зубов шкива коленвала = ((60 - 2) - 1) */
localparam [TCNT_WIDTH-1:0] tcnt_top = 57;
/*сброс счетчика зубов при достижении top*/
wire tcnt_srst = main_edge & tcnt_equal_top;


/*сброс триггера запуска счетчка периода захвата  дпкв*/
wire pcnt_start_srst = pcnt_ovf | gap_drn_normal_tooth;

//детект фронтов
cap_edge input_capture 
(   .clk(clk),
    .ena(1'b1),
    .cap(cap),
    .srst(1'b0),
    .arst(rst),
    .rise(cap_rise),
    .fall(cap_fall));
    
//выбор фронта
mult2to1 #(1) cap_edge_switch 
(   .sel(cap_edge_sel), /*0 = передний фронт, 1 = задний фронт*/
    .a(cap_rise),
    .b(cap_fall),
    .out(main_edge) );
    
//запуск счетчика захвата периода
d_flip_flop #(1) dff_pcnt_start 
(   .clk(clk),
    .ena(main_edge & ~pcnt_start),
    .d(1'b1),
    .srst(pcnt_start_srst),
    .arst(rst),
    .q(pcnt_start));
    
//счетчик захвата периода
counter #(PCNT_WIDTH) pcnt 
(   .clk(clk),
    .ena(pcnt_start),
    .sel(1'b0),
    .sload(1'b0),
    .srst(main_edge),
    .arst(rst),
    .q(pcnt_out),
    .carry_out(pcnt_ovf));
    
//первый регистр захвата периода
d_flip_flop #(PCNT_WIDTH) pcnt1 
(   .clk(clk),
    .ena(pcnt123_ena),
    .d(pcnt_out),
    .srst(~pcnt_start),
    .arst(rst),
    .q(pcnt1_out));
    
//второй регистр захвата периода
d_flip_flop #(PCNT_WIDTH) pcnt2 
(   .clk(clk),
    .ena(pcnt123_ena),
    .d(pcnt1_out),
    .srst(~pcnt_start),
    .arst(rst),
    .q(pcnt2_out));
    
//третий регистр захвата периода
d_flip_flop #(PCNT_WIDTH) pcnt3 
(   .clk(clk),
    .ena(pcnt123_ena),
    .d(pcnt2_out),
    .srst(~pcnt_start),
    .arst(rst),
    .q(pcnt3_out));
    
//первый компаратор поиска метки (pcnt1 < pcnt2/2)
comparator #(PCNT_WIDTH-1) pcnt1_comp_pcnt2 
(   .a(pcnt1_out[PCNT_WIDTH-2:0]),
    .b(pcnt2_out[PCNT_WIDTH-1:1]),
    .alb(pcnt1_less_pcnt2));
    
//второй компаратор поиска метки (pcnt3 < pcnt2/2)
comparator #(PCNT_WIDTH-1) pcnt3_comp_pcnt2 
(   .a(pcnt3_out[PCNT_WIDTH-2:0]),
    .b(pcnt2_out[PCNT_WIDTH-1:1]),
    .alb(pcnt3_less_pcnt2));
    
//компаратор проверки метки (pcnt1 < pcnt/2) (!) не прикручен
comparator #(PCNT_WIDTH-1) pcnt1_comp_pcnt 
(   .a(pcnt1_out[PCNT_WIDTH-2:0]),
    .b(pcnt_out[PCNT_WIDTH-1:1]),
    .alb(pcnt1_less_pcnt));
    
//триггер запуска генератора углов
d_flip_flop #(1) dff_hwag_start 
(   .clk(clk),
    .ena(hwag_ena),
    .d(1'b1),
    .srst(~pcnt_start),
    .arst(rst),
    .q(hwag_start));
    
//счетчик зубов дпкв
counter #(TCNT_WIDTH) tcnt 
(   .clk(clk),
    .ena(main_edge & hwag_start),
    .sel(1'b0),
    .sload(~hwag_start),
    .d_load(tcnt_load),
    .srst(~pcnt_start | tcnt_srst),
    .arst(rst),
    .q(tcnt_out));
    
//компаратор счетчика зубов
comparator #(TCNT_WIDTH) tcnt_comp_top 
(   .a(tcnt_out),
    .b(tcnt_top),
    .aeb(tcnt_equal_top));

endmodule

`endif
