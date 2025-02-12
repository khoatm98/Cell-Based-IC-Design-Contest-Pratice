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


/* 
module ImgROM (
   output [7:0] Q;
   input CLK;
   input CEN;
   input [13:0] A;
);
 */

/* 
module ResultSRAM (
   output [7:0] Q;
   input CLK;
   input CEN;
   input WEN;
   input [13:0] A;
   input [7:0] D;
); 
*/

wire  [7:0] 	ROM_Q_w;
wire  			ROM_CEN_w;
wire  [13:0] 	ROM_A_w;

wire  [7:0] 	RAM_Q_w;
wire  			RAM_CEN_w;
wire  			RAM_WEN_w;
wire  [13:0] 	RAM_A_w;
wire  [ 7:0] 	RAM_D_w;


ImgROM u_ImgROM (.Q(ROM_Q_w), .CLK(CLK), .CEN(ROM_CEN_w), .A(ROM_A_w));
ResultSRAM u_ResultSRAM (.Q(RAM_Q_w), .CLK(CLK), .CEN(RAM_CEN_w), .WEN(RAM_WEN_w), .A(RAM_A_w), .D(RAM_D_w));


endmodule


