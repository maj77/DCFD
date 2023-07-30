`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 29.07.2023 09:50:55
// Module Name: scaler
// Description: module performs multiplication by constant fractional value
//              in range (0;1)
// 
//////////////////////////////////////////////////////////////////////////////////


module scaler #( SCALE_FACTOR = 12'b1100_1100_1101       , // default scaling by 0.8
                 IN_WIDTH     = 32                       , // a = Q(0.n.m)
                 SCALE_WIDTH  = $bits(SCALE_FACTOR)      , // b = Q(0.p.q)
                 OUTPUT_WIDTH = IN_WIDTH + SCALE_WIDTH  // c = a*b = Q(0.n+p,m+q)
              )(
                 input                     clk,
                 input                     rst_p,
                 input  [    IN_WIDTH-1:0] data_i,
                 output [OUTPUT_WIDTH-1:0] data_o
              );

logic [ SCALE_WIDTH-1:0] sf;
logic [OUTPUT_WIDTH-1:0] scaled_sample;

assign sf = SCALE_FACTOR; //Q(0.0.12)

always_ff @(posedge clk) begin
  if(rst_p)
    scaled_sample <= 0;
  else
    scaled_sample <= data_i * sf;  
end

assign data_o = scaled_sample; //Q(0.32.12)

endmodule
