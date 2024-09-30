module Bicubic (
input CLK,
input RST,
input [6:0] V0,
input [6:0] H0,
input [4:0] SW,
input [4:0] SH,
input [5:0] TW,
input [5:0] TH,
output reg DONE);

ImgROM u_ImgROM (.Q(), .CLK(), .CEN(), .A());
ResultSRAM u_ResultSRAM (.Q(), .CLK(), .CEN(), .WEN(), .A(), .D());


endmodule


