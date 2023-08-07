`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.08.2023 18:23:09
// Design Name: 
// Module Name: serializer_tb
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


module serializer_tb();

localparam DATA_WIDTH = 8;
 
logic                         clk;
logic                         clk_ser; // frequency should be 1.5clk
logic                         rst_p;
logic signed [DATA_WIDTH-1:0] data_in [2:0];
logic signed [DATA_WIDTH-1:0] data_out;

// paraller data clock
initial
  clk = 1'b0;
always
  #5 clk = ~clk;

// serial data clock
initial
  clk_ser = 1'b0;
always
  #1.67 clk_ser = ~clk_ser; // 5/3=1.67

// reset
initial
  rst_p = 1'b1;
always
  #15 rst_p = 1'b0;
  
initial begin
      data_in = '{default:0};
  #15 data_in = {{8'hAA}, {8'hBB}, {8'hCC}};
  #5  data_in = '{default:0};
  #1  data_in = {{8'hDE}, {8'hAD}, {8'hAA}};
  #5  data_in = '{default:0};
end

serializer #(
  .DATA_WIDTH(DATA_WIDTH)
)serializer_uut(
  .clk_par (clk     ),
  .clk_ser (clk_ser ),
  .rst_p   (rst_p   ),
  .data_in (data_in ),
  .data_out(data_out)
);


endmodule
