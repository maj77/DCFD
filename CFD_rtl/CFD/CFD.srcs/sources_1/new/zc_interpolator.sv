`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 13.08.2023 10:38:59
// Design Name: CFD
// Module Name: zc_interpolator
// Description: 
//////////////////////////////////////////////////////////////////////////////////


module zc_interpolator #(
  ADC_PERIOD_NS = 100, // 100ns clock period
  IN_WIDTH      = 25,
  IN_FRACT      = 12,
  OUT_WIDTH     = 16,
  OUT_FRACT     = 8
)(
  input  logic                        clk,
  input  logic                        rst_p,
  input  logic signed [ IN_WIDTH-1:0] sample_in_0, // a1 on block diagram
  input  logic signed [ IN_WIDTH-1:0] sample_in_1, // a2 on block diagram
  output logic        [OUT_WIDTH-1:0] result,
  output logic                        result_vld
);

localparam PERIOD_WIDTH    = $clog2(ADC_PERIOD_NS);
localparam ABS_IN_WIDTH    = IN_WIDTH-1;
localparam ABS_IN_FRACT    = IN_FRACT;

localparam LUT_ADDR_WIDTH  = 6;
localparam LUT_DATA_WIDTH  = 16;
localparam LUT_FRACT_WIDTH = 8;

localparam MULT_1_WIDTH     = PERIOD_WIDTH + ABS_IN_WIDTH;
localparam MULT_1_SAT_WIDTH = MULT_1_WIDTH - ABS_IN_FRACT + 1;

localparam MULT_2_WIDTH     = 2*LUT_DATA_WIDTH;
localparam MULT_2_SAT_WIDTH = MULT_2_WIDTH - 5; // TODO: figure out how to get rid of this magic number

localparam ADDR_SAT_BITS   = 9;
localparam SAT_ADDR_WIDTH  = ABS_IN_WIDTH-ADDR_SAT_BITS;



logic [PERIOD_WIDTH-1:0] T_adc;
logic [ABS_IN_WIDTH-1:0] samp_0_abs;
logic [ABS_IN_WIDTH-1:0] samp_1_abs;

logic  [    MULT_1_WIDTH-1:0] mult_1_result;
logic  [MULT_1_SAT_WIDTH-1:0] mult_1_sat;      // Q(0.8.12)
logic  [  LUT_DATA_WIDTH-1:0] mult_1_scaled;   // Q(0.8.8)

logic  [SAT_ADDR_WIDTH-1:0] addr0_sat;
logic  [SAT_ADDR_WIDTH-1:0] addr1_sat;
logic  [LUT_ADDR_WIDTH-1:0] a1;
logic  [LUT_ADDR_WIDTH-1:0] a2;
logic  [LUT_DATA_WIDTH-1:0] lut_data;

logic [    MULT_2_WIDTH-1:0] mult_2_result; // Q(0.13.19)
logic [MULT_2_SAT_WIDTH-1:0] mult_2_sat;    // Q(0.8.19)
logic [         OUT_WIDTH:0] result_rnd;    // Q(0.9.8), additional 1 MSB for handling rounding overflow

logic zero_cross_pulse;
logic zero_cross_pulse_d;


//
// initial ABS calc
//
assign samp_0_abs = sample_in_0 < 0 ? ~sample_in_0 + 1'b1 : sample_in_0;  // expected 1MSB truncation
assign samp_1_abs = sample_in_1 < 0 ? ~sample_in_1 + 1'b1 : sample_in_1; 


//
// MULT_1 PATH
//
assign T_adc = ADC_PERIOD_NS;
always_ff @(posedge clk) begin
  mult_1_result <= T_adc * samp_0_abs;
end

// sat 11 bits
assign mult_1_sat = |mult_1_result[MULT_1_WIDTH-1:MULT_1_SAT_WIDTH] ? '1 : mult_1_result[MULT_1_SAT_WIDTH-1:0]; // Q(0.8.12)

// truncate 4 LSB's
assign mult_1_scaled = mult_1_sat[MULT_1_SAT_WIDTH-1:MULT_1_SAT_WIDTH-LUT_DATA_WIDTH]; // Q(0.8.8) 


//
// LUT PATH
//
assign addr0_sat = |samp_0_abs[ABS_IN_WIDTH-1:SAT_ADDR_WIDTH] ? '1 : samp_0_abs[SAT_ADDR_WIDTH-1:0]; // Q(0.3.12)
assign addr1_sat = |samp_1_abs[ABS_IN_WIDTH-1:SAT_ADDR_WIDTH] ? '1 : samp_1_abs[SAT_ADDR_WIDTH-1:0]; // Q(0.3.12)

// TODO: check if rounding gives better results
always_comb begin : trunc_addr_c
  a1 = addr0_sat[SAT_ADDR_WIDTH-1:9];
  a2 = addr1_sat[SAT_ADDR_WIDTH-1:9];
end

LUT #(
  .ADDR_WIDTH(LUT_ADDR_WIDTH),
  .DATA_WIDTH(LUT_DATA_WIDTH)
)i_lut(
  .clk   (clk     ),
  .rst_p (rst_p   ),
  .a1    (a1      ),
  .a2    (a2      ),
  .data_o(lut_data)
);


//
// MULT_2 PATH
//
always_ff @(posedge clk) begin
  mult_2_result <= lut_data*mult_1_scaled;
end

// sat 5 MSB's
assign mult_2_sat = |mult_2_result[MULT_2_WIDTH-1:MULT_2_SAT_WIDTH] ? '1 : mult_2_result[MULT_2_SAT_WIDTH-1:0]; // Q(0.8.19)
// round to 8 bits fract
assign result_rnd = mult_2_sat[MULT_2_SAT_WIDTH-1:MULT_2_SAT_WIDTH-OUT_WIDTH] + mult_2_sat[MULT_2_SAT_WIDTH-OUT_WIDTH-1]; // Q(0.9.8)
// handle rounding overflow
assign result = result_rnd[OUT_WIDTH] ? '1 : result_rnd[OUT_WIDTH-1:0]; // Q(0.8.8)

//
// ZERO CROSS PULSE GENERATOR
//
always_ff @(posedge clk) begin
  if (sample_in_0 < 0 && sample_in_1 > 0) begin 
    zero_cross_pulse <= 1'b1;
  end else begin
    zero_cross_pulse <= 1'b0;
  end
  zero_cross_pulse_d <= zero_cross_pulse;
end

assign result_vld = zero_cross_pulse_d;

endmodule
