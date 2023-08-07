`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 04.08.2023 18:27:21
// Design Name: CFD
// Module Name: interpolator
// Description: module performs linear interpolation
//////////////////////////////////////////////////////////////////////////////////


module interpolator #( 
        IN_WIDTH = 45,
        OUT_WIDTH = 3*IN_WIDTH
    )(
        input  logic                       clk              ,
        input  logic                       rst_p            ,
        input  logic signed [IN_WIDTH-1:0] sample_in_0      ,     // sample n-1, Q(1.32.12)
        input  logic signed [IN_WIDTH-1:0] sample_in_1      ,     // sample n,   Q(1.32.12)
        output logic signed [IN_WIDTH-1:0] samples_out [2:0]
    );
    
logic signed [  IN_WIDTH:0] samp_sub_res; // Q(1.33.12)
logic signed [  IN_WIDTH:0] samp_add_res; // Q(1.33.12)
logic signed [IN_WIDTH-1:0] interp_sample; // Q(1.32.12)

// [0] oldest sample, [1] interp sample, [2] newest sample
logic signed [IN_WIDTH-1:0] s_out_r [2:0]; 

always_comb begin
  samp_sub_res = sample_in_1 - sample_in_0; 
end

always_comb begin
  samp_add_res = sample_in_0 + (samp_sub_res >>> 1);
end

// saturate 1 MSB
sat #( .IN_WIDTH (IN_WIDTH+1),
       .OUT_WIDTH(IN_WIDTH  )
     )sat_comb_i(
       .data_i(samp_add_res ),
       .data_o(interp_sample)
    );

always_ff @(posedge clk) begin
  s_out_r[0] <= sample_in_0;
  s_out_r[1] <= interp_sample;
  s_out_r[2] <= sample_in_1;
end

assign samples_out = s_out_r;
 
endmodule
