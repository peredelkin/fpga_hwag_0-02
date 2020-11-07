`ifndef HWAG_SV
`define HWAG_SV

`include "capture.sv"
`include "count.sv"
`include "comparsion.sv"

module hwag_core
(
clk,
rst,
cap,
cam,
cap_edge_sel,
second_edge,
hwag_start,
acnt_out
);


/*вход тактирования модуля*/
input wire clk;
/*вход асинхронного сброса*/
input wire rst;
/*вход сигнала дпкв*/
input wire cap;
/*вход сигнала дпрв*/
input wire cam;
/*передний фронт захвата дпкв*/
wire cap_rise;
/*задний фронт захвата дпкв*/
wire cap_fall;
/*выбор фронта захвата дпкв*/
input wire cap_edge_sel;
/*основной фронт захвата дпкв*/
wire main_edge;
/*второй фронт захвата дпкв*/
output wire second_edge;
/*выход работы генератора углов*/
output wire hwag_start;

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

//детект фронтов дпкв
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
    
//второй фронт
d_flip_flop #(1) dff_second_edge 
(   .clk(clk),
    .ena(pcnt_start),
    .d(main_edge),
    .srst(pcnt_start_srst),
    .arst(rst),
    .q(second_edge));
    
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
    
//компаратор проверки метки (pcnt1 < pcnt/2)
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

//получение периода угла
wire [21:0] scnt_load = pcnt1_out >> 6;

//выход счетчика периода угла
wire [21:0] scnt_out;

//счет scnt
wire scnt_ena = hwag_start & ~tckc_ovf;

counter #(22) scnt 
(   .clk(clk),
    .ena(scnt_ena),
    .sel(1'b1),
    .sload(scnt_ovf | second_edge),
    .d_load(scnt_load),
    .srst(1'b0),
    .arst(rst),
    .q(scnt_out),
    .carry_out(scnt_ovf));
    
wire [18:0] tckc_load;

//выбор количества углов на зубе
mult2to1 #(19) tckc_sel 
(   .sel(tcnt_equal_top),
    .a(19'd64),
    .b(19'd192),
    .out(tckc_load));

//выход счетчика углов на зубе
wire [18:0] tckc_out;

//счет tckc
wire tckc_ena = scnt_ena & scnt_ovf;
    
counter #(19) tckc 
(   .clk(clk),
    .ena(tckc_ena),
    .sel(1'b1),
    .sload(second_edge),
    .d_load(tckc_load),
    .srst(1'b0),
    .arst(rst),
    .q(tckc_out),
    .carry_out(tckc_ovf));

//получение угла сдвигом номера зуба
wire [23:0] acnt_load = tcnt_out << 6;

//выход счетчика углов
output wire [23:0] acnt_out;

//сигналы счета от генератора углов
wire acnt_hwag_count = tckc_ena & hwag_start;
//сигналы загрузки от генератора углов
wire acnt_hwag_load = second_edge & hwag_start;

//счет acnt
wire acnt_ena = acnt_hwag_count & ~acnt_equal_top;
//загрузка acnt
wire acnt_sload = ~hwag_start | acnt_hwag_load;
//сброс acnt
wire acnt_srst = (acnt_hwag_count & acnt_equal_top) | ~pcnt_start;

//синхронизированный c tcnt счетчик углов
counter #(24) acnt 
(   .clk(clk),
    .ena(acnt_ena),
    .sel(1'b0),
    .sload(acnt_sload),
    .d_load(acnt_load),
    .srst(acnt_srst),
    .arst(rst),
    .q(acnt_out));
    
//компаратор счетчика углов
comparator #(24) acnt_comp_top 
(   .a(acnt_out),
    .b(24'd3839),
    .aeb(acnt_equal_top));

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//проверка дпрв (cam)

//захват дпрв
d_flip_flop #(1) cam_capture
(   .clk(clk),
    .ena(main_edge),
    .sload(1'b0),
    .d(cam),
    .srst(1'b0),
    .arst(rst),
    .q(cam_out));

//детект фронтов дпрв
cap_edge cam_edge_capture 
(   .clk(clk),
    .ena(1'b1),
    .cap(cam_out),
    .srst(1'b0),
    .arst(rst),
    .rise(cam_rise),
    .fall(cam_fall));

//захват позици заднего фронта дпрв
wire [TCNT_WIDTH-1:0] cam_fall_point;
d_flip_flop #(TCNT_WIDTH) cap_cam_fall_point 
(   .clk(clk),
    .ena(cam_fall),
    .sload(1'b0),
    .d(tcnt_out),
    .srst(~hwag_start),
    .arst(rst),
    .q(cam_fall_point));

//захват позиции переднего фронта дпрв
wire [TCNT_WIDTH-1:0] cam_rise_point;
d_flip_flop #(TCNT_WIDTH) cap_cam_rise_point
(   .clk(clk),
    .ena(cam_rise),
    .sload(1'b0),
    .d(tcnt_out),
    .srst(~hwag_start),
    .arst(rst),
    .q(cam_rise_point));
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

endmodule

module hwag
(
clk,
rst,
cap,
cam,
second_edge,
hwag_start
);

input wire clk;
input wire rst;
input wire cap;
input wire cam;
output wire second_edge;
output wire hwag_start;

wire [23:0] acnt_out;
wire [23:0] acnt2_out;

//главное ядро генератора углов
hwag_core hwag_core0
(   .clk(clk),
    .rst(rst),
    .cap(cap),
    .cam(cam),
    .cap_edge_sel(1'b1),
    .second_edge(second_edge),
    .hwag_start(hwag_start),
    .acnt_out(acnt_out)
);

wire acnt2_ena = hwag_start & ~acnt_e_acnt2;
wire acnt2_sload = ~hwag_start;
wire acnt2_srst = acnt2_e_top & ~acnt_e_acnt2;

//второй ведущий счетчик
counter #(24) acnt2 
(   .clk(clk),
    .ena(acnt2_ena),
    .sel(1'b0),
    .sload(acnt2_sload),
    .d_load(acnt_out),
    .srst(acnt2_srst),
    .arst(rst),
    .q(acnt2_out));

//компаратор отставания
comparator #(24) acnt_e_acnt2_comp 
(   .a(acnt_out),
    .b(acnt2_out),
    .aeb(acnt_e_acnt2));

//компаратор сброса счета  
comparator #(24) acnt2_e_top_comp 
(   .a(acnt2_out),
    .b(24'd3839),
    .aeb(acnt2_e_top));
    
//=====================
wire [23:0] acnt3_out;
wire [23:0] acnt3_start;

mult2to1 #(24) acnt3_start_sel
(   .sel(cam),
    .a(24'd3839 - 24'd2688),
    .b(24'd7679 - 24'd2688),
    .out(acnt3_start));
    
wire [23:0] acnt3_reload = 24'd7679;
wire [23:0] acnt3_d_load;

mult2to1 #(24) acnt3_d_load_sel
(   .sel(hwag_start),
    .a(acnt3_start),
    .b(acnt3_reload),
    .out(acnt3_d_load));
    
wire acnt3_ena = acnt2_ena;
wire acnt3_sload = tcnt3_ovf | ~hwag_start;

counter #(24) acnt3 
(   .clk(clk),
    .ena(acnt3_ena),
    .sel(1'b1),
    .sload(acnt3_sload),
    .d_load(acnt3_d_load),
    .srst(1'b0),
    .arst(rst),
    .q(acnt3_out),
    .carry_out(tcnt3_ovf));
    
set_reset_comparator #(24) set_reset_comp0
(   .set_data(24'd128),
    .reset_data(24'd0),
    .data_compare(acnt3_out),
    .clk(clk),
    .ena(~hwag_start),
    .input_rst(rst),
    .output_rst(rst | ~hwag_start),
    .out(out0_out)
);

wire ign1_out = out0_out;// | out1_out;

//=====================
wire [23:0] acnt4_out;
wire [23:0] acnt4_start;

mult2to1 #(24) acnt4_start_sel
(   .sel(~cam),
    .a(24'd3839 - 24'd2688),
    .b(24'd7679 - 24'd2688),
    .out(acnt4_start));
    
wire [23:0] acnt4_reload = 24'd7679;
wire [23:0] acnt4_d_load;

mult2to1 #(24) acnt4_d_load_sel
(   .sel(hwag_start),
    .a(acnt4_start),
    .b(acnt4_reload),
    .out(acnt4_d_load));
    
wire acnt4_ena = acnt2_ena;
wire acnt4_sload = tcnt4_ovf | ~hwag_start;

counter #(24) acnt4 
(   .clk(clk),
    .ena(acnt4_ena),
    .sel(1'b1),
    .sload(acnt4_sload),
    .d_load(acnt4_d_load),
    .srst(1'b0),
    .arst(rst),
    .q(acnt4_out),
    .carry_out(tcnt4_ovf));
    
set_reset_comparator #(24) set_reset_comp1
(   .set_data(24'd128),
    .reset_data(24'd0),
    .data_compare(acnt4_out),
    .clk(clk),
    .ena(~hwag_start),
    .input_rst(rst),
    .output_rst(rst | ~hwag_start),
    .out(out1_out)
);

wire ign4_out = out1_out;// | out0_out;

//=====================
wire [23:0] acnt5_out;
wire [23:0] acnt5_start;

mult2to1 #(24) acnt5_start_sel
(   .sel(cam),
    .a(24'd3839 - 24'd768),
    .b(24'd7679 - 24'd768),
    .out(acnt5_start));
    
wire [23:0] acnt5_reload = 24'd7679;
wire [23:0] acnt5_d_load;

mult2to1 #(24) acnt5_d_load_sel
(   .sel(hwag_start),
    .a(acnt5_start),
    .b(acnt5_reload),
    .out(acnt5_d_load));
    
wire acnt5_ena = acnt2_ena;
wire acnt5_sload = tcnt5_ovf | ~hwag_start;

counter #(24) acnt5 
(   .clk(clk),
    .ena(acnt5_ena),
    .sel(1'b1),
    .sload(acnt5_sload),
    .d_load(acnt5_d_load),
    .srst(1'b0),
    .arst(rst),
    .q(acnt5_out),
    .carry_out(tcnt5_ovf));
    
set_reset_comparator #(24) set_reset_comp2
(   .set_data(24'd128),
    .reset_data(24'd0),
    .data_compare(acnt5_out),
    .clk(clk),
    .ena(~hwag_start),
    .input_rst(rst),
    .output_rst(rst | ~hwag_start),
    .out(out2_out)
);

wire ign3_out = out2_out;// | out3_out;

//=====================
wire [23:0] acnt6_out;
wire [23:0] acnt6_start;

mult2to1 #(24) acnt6_start_sel
(   .sel(~cam),
    .a(24'd3839 - 24'd768),
    .b(24'd7679 - 24'd768),
    .out(acnt6_start));
    
wire [23:0] acnt6_reload = 24'd7679;
wire [23:0] acnt6_d_load;

mult2to1 #(24) acnt6_d_load_sel
(   .sel(hwag_start),
    .a(acnt6_start),
    .b(acnt6_reload),
    .out(acnt6_d_load));
    
wire acnt6_ena = acnt2_ena;
wire acnt6_sload = tcnt6_ovf | ~hwag_start;

counter #(24) acnt6 
(   .clk(clk),
    .ena(acnt6_ena),
    .sel(1'b1),
    .sload(acnt6_sload),
    .d_load(acnt6_d_load),
    .srst(1'b0),
    .arst(rst),
    .q(acnt6_out),
    .carry_out(tcnt6_ovf));
    
set_reset_comparator #(24) set_reset_comp3
(   .set_data(24'd128),
    .reset_data(24'd0),
    .data_compare(acnt6_out),
    .clk(clk),
    .ena(~hwag_start),
    .input_rst(rst),
    .output_rst(rst | ~hwag_start),
    .out(out3_out)
);

wire ign2_out = out3_out;// | out2_out;

endmodule

`endif
