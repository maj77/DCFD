`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.07.2023 14:36:34
// Design Name: 
// Module Name: scaler_tb
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


module scaler_tb();

localparam INPUT_WIDTH  = 32;
localparam SCALE_FACTOR = 12'b1100_1100_1101; // exact 0.8
localparam SCALE_WIDTH  = $bits(SCALE_FACTOR);
localparam OUTPUT_WIDTH = INPUT_WIDTH + SCALE_WIDTH;


logic clk;
logic rst_p;
logic [ INPUT_WIDTH-1:0] sample_in;
logic [OUTPUT_WIDTH-1:0] sample_out;
logic [ INPUT_WIDTH-1:0] sample_out_int;

logic [ INPUT_WIDTH-1:0] test_val_in;
logic [OUTPUT_WIDTH-1:0] test_val_out;
logic [ INPUT_WIDTH-1:0] test_val_out_int;

real test_val_f;
real scale_factor_f;
real result_check_f;
real result_f;
real temp;

scaler #(.INPUT_WIDTH (INPUT_WIDTH ),
         .SCALE_WIDTH (SCALE_WIDTH ),
         .OUTPUT_WIDTH(OUTPUT_WIDTH),
         .SCALE_FACTOR(SCALE_FACTOR)
       ) scaler_i (
         .clk   (clk       ),
         .rst_p (rst_p     ),
         .data_i(sample_in ),
         .data_o(sample_out)
       );

// clock T=10ns, 100MHz
initial
  clk <= 1'b0;
always
  #5 clk <= ~clk;

// reset
initial begin
  #0 rst_p <= 1'b1;
  #5 rst_p <= 1'b0;
end

always @(posedge clk) begin
  sample_in <= 32'd51253;
end

always @(posedge clk) begin
  test_val_f <= 51253;
  scale_factor_f <= 0.8;
  result_check_f <= test_val_f * scale_factor_f;
  result_f <= real'(sample_out)/(2**SCALE_WIDTH);
end

assign sample_out_int = sample_out[OUTPUT_WIDTH-1:SCALE_WIDTH];
endmodule
