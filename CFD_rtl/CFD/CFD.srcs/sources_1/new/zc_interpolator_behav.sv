`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2024 12:02:13
// Design Name: CFD
// Module Name: zc_interpolator_behav
// Description: behavioral model using division operator instead of LUT
//////////////////////////////////////////////////////////////////////////////////


module zc_interpolator_behav #(
  ADC_PERIOD_NS = 100, // 100ns clock period
  IN_WIDTH      = 25,
  IN_FRACT      = 12,
  OUT_WIDTH     = 16,
  OUT_FRACT     = 8
)(
  input  logic  clk,
  input  logic  rst_p,
  input  real  sample_in_0, // a1 on block diagram
  input  real  sample_in_1, // a2 on block diagram
  output real  result,
  output logic  result_vld
);

function abs (input real a);
  abs = (a<0) ? -a : a;
endfunction

real samp_0_abs, samp_1_abs;
real mult_1_result, mult_2_result;
real lut_data;

logic zero_cross_pulse;
logic zero_cross_pulse_d;

//
// initial ABS calc
//
assign samp_0_abs = (sample_in_0<0) ? -sample_in_0 : sample_in_0; //abs(sample_in_0);
assign samp_1_abs = (sample_in_1<0) ? -sample_in_1 : sample_in_1; //abs(sample_in_1);

//
// MULT_1 PATH
//
always_ff @(posedge clk) begin
  mult_1_result <= ADC_PERIOD_NS * samp_0_abs;
end

always_ff @(posedge clk) begin
  lut_data = 1/(samp_0_abs + samp_1_abs);
end

//
// MULT_2 PATH
//
always_ff @(posedge clk) begin
  mult_2_result <= lut_data*mult_1_result; // on block diagram this flip flop is after rounding
end

// handle rounding overflow
assign result = mult_2_result; // Q(0.8.8)

//
// ZERO CROSS PULSE GENERATOR
//
always_ff @(posedge clk) begin
  if (sample_in_0 < 0 && sample_in_1 > 0) begin 
    zero_cross_pulse <= 1'b1;
  end else begin
    zero_cross_pulse <= 1'b0;
  end
  zero_cross_pulse_d <= zero_cross_pulse; // allign pulse with result
end

assign result_vld = zero_cross_pulse_d;

endmodule
