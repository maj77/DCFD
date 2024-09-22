`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2023 14:29:44
// Design Name: 
// Module Name: zc_interp_v2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module zc_interp_v2();

wire signed [ 5:0] a1, a2;
wire signed [11:0] res, res2;
real a1_int, a2_int;
integer res_int;

assign a1 = 6'h0C;
assign a2 = 6'h2F;
assign res = 1024/(a1+a2);
assign res2 = res>>10;

initial begin
  a1_int = 0.3;
  a2_int = 0.015;
  res_int = 1/(a1_int+a2_int);
end

endmodule
