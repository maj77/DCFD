`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 22.03.2024 13:05:10
// Design Name: CFD
// Module Name: scaler
// Description: behavioral module performs multiplication by constant fractional value
//              in range (0;1)
// 
//////////////////////////////////////////////////////////////////////////////////

module scaler_behav #( 
      SCALE_FACTOR = 0.8
    )(
       input  logic clk,
       input  logic rst_p,
       input  real  data_i,
       output real  data_o
    );

real scaled_sample;
real sf;

assign sf = SCALE_FACTOR;

always_ff @(posedge clk) begin
  if(rst_p)
    scaled_sample <= 0;
  else
    scaled_sample <= data_i * sf;  
end

assign data_o = scaled_sample;
endmodule
