`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.06.2024 20:40:20
// Design Name: 
// Module Name: moving_avg_tb
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


module moving_avg_tb();

localparam DATA_WIDTH  = 24;
localparam NO_AVG_SAMP = 4;

logic clk;
logic rst_n;
logic [DATA_WIDTH-1:0] data_in;
logic [DATA_WIDTH+NO_AVG_SAMP-1:0] averaged_samp;


initial begin
    rst_n = 1'b0;
    #10 rst_n = 1'b1;
end

initial
  clk = 1'b0;
always
  #5 clk = ~clk;

initial
    data_in = 24'd1;
//always @(posedge clk)
//    data_in = data_in + 24'd1;

moving_average #(
    .DATA_WIDTH (DATA_WIDTH ),
    .NO_AVG_SAMP(NO_AVG_SAMP)
) UUT_moving_avg (
    .clk     (clk          ),
    .rst_n   (rst_n        ),
    .data_in (data_in      ),
    .data_out(averaged_samp)
);

endmodule
