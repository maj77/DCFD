`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.08.2023 10:59:34
// Design Name: 
// Module Name: sat_tb
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


module sat_tb();

localparam IN_WIDTH = 8;
localparam OUT_WIDTH = 7;

logic                 clk;
logic [ IN_WIDTH-1:0] data_i;
logic [OUT_WIDTH-1:0] data_o;


sat #( .IN_WIDTH(IN_WIDTH),
       .OUT_WIDTH(OUT_WIDTH)
     )sat_uut(
       .data_i(data_i),
       .data_o(data_o)
     );

initial begin
  data_i = 8'b0110_1110;
  #5 data_i = 8'b1110_1110;
  #5 data_i = 8'b1000_1110;
  #5 data_i = 8'b1100_0100;
  #5 data_i = 8'b0111_1111;
end

endmodule
