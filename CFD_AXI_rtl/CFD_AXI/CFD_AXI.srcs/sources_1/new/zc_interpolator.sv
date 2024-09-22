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
  FPGA_CLOCKS_PER_SAMPLE = 16, // 100ns clock period
  RAW_IN_WIDTH  = 12,
  IN_WIDTH      = 25,
  IN_FRACT      = 12,
  OUT_WIDTH     = 16,
  OUT_FRACT     = 8
)(
  // data ports
  input  logic                        clk,
  input  logic                        rst_p,
  input  logic signed [ IN_WIDTH-1:0] sample_in_0, // a1 on block diagram, Q(1.12.12)
  input  logic signed [ IN_WIDTH-1:0] sample_in_1, // a2 on block diagram, Q(1.12.12)
  output logic        [OUT_WIDTH-1:0] result,
  output logic                        result_vld,
  output logic                        result_vld_d
);                                  

localparam PERIOD_WIDTH    = 7; // HARDCODED AS IN MATLAB, $clog2(FPGA_ADC_CLKS_RATIO); // [BUG MONITOR] possible bugs if PERIOD_WIDTH changes?
localparam ABS_IN_WIDTH    = IN_WIDTH - 1;
localparam ABS_IN_FRACT    = IN_FRACT;

localparam LUT_ADDR_WIDTH  = 12;
localparam LUT_DATA_WIDTH  = 7+6; //8+7;
localparam LUT_FRACT_WIDTH = 6;

localparam MULT_1_WIDTH     = PERIOD_WIDTH + ABS_IN_WIDTH;
localparam MULT_1_SAT_WIDTH = MULT_1_WIDTH - ABS_IN_FRACT + 1; // = 20 TODO: CHANGE IT
localparam MULT_1_SCALED_WIDTH = OUT_WIDTH; //LUT_DATA_WIDTH+2; 

localparam MULT_2_WIDTH     = LUT_DATA_WIDTH + MULT_1_SCALED_WIDTH;
localparam MULT_2_SAT_WIDTH = MULT_2_WIDTH - OUT_FRACT + 1; // TODO: check if works correctly, equal to 20 if mult2width=28 and out_fract=8

localparam ADDR_SAT_BITS   = 6;
localparam SAT_ADDR_WIDTH  = ABS_IN_WIDTH-ADDR_SAT_BITS;


 
logic [PERIOD_WIDTH-1:0] T_adc;       // Q(0.7.0) will change if ADC_PERIOD changes
logic [ABS_IN_WIDTH-1:0] samp_0_abs;  // Q(0.12.12)
logic [ABS_IN_WIDTH-1:0] samp_1_abs;  // Q(0.12.12)

logic  [       MULT_1_WIDTH-1:0] mult_1_result;   // Q(0.19.12)
logic  [   MULT_1_SAT_WIDTH-1:0] mult_1_sat;      // Q(0.8.12) <- double check if it is correct comment
logic  [MULT_1_SCALED_WIDTH-1:0] mult_1_scaled;   // Q(0.8.8)

logic  [SAT_ADDR_WIDTH-1:0] addr0_sat;
logic  [SAT_ADDR_WIDTH-1:0] addr1_sat;
logic  [LUT_ADDR_WIDTH-1:0] a1;
logic  [LUT_ADDR_WIDTH-1:0] a2;
logic  [LUT_DATA_WIDTH-1:0] lut_data;

logic [    MULT_2_WIDTH-1:0] mult_2_result; // Q(0.15.14)
logic [MULT_2_SAT_WIDTH-1:0] mult_2_sat;    // probably Q(0.8.19), needs to be double checked
logic [         OUT_WIDTH:0] result_rnd;    // probably: [Q(0.9.8), additional 1 MSB for handling rounding overflow], needs to be double checked
logic [       OUT_WIDTH-1:0] result_r;

logic [  LUT_ADDR_WIDTH:0] samp_sum;
logic [LUT_ADDR_WIDTH-1:0] lut_addr;

logic       zero_cross_pulse;
logic [1:0] zero_cross_pulse_d;


//
// initial ABS calc
//
assign samp_0_abs = sample_in_0 < 0 ? ~sample_in_0 + 1'b1 : sample_in_0;  // expected 1MSB truncation
assign samp_1_abs = sample_in_1 < 0 ? ~sample_in_1 + 1'b1 : sample_in_1;  // Q(0.12.12)

//
// MULT_1 PATH
//
assign T_adc = FPGA_CLOCKS_PER_SAMPLE; // Q(0.7.0)
always_ff @(posedge clk) begin : mult_1_ff
  if (rst_p) begin
    mult_1_result              <= '{default:0};
  end else begin
    // [IMPORTANT] if derivative of input wave is negative around zero then older samp should be in numerator, otherwise newer sample 
    mult_1_result              <= T_adc * samp_0_abs; // Q(0.19.12)
  end
end

// saturate
assign mult_1_sat = |mult_1_result[MULT_1_WIDTH-1:MULT_1_SAT_WIDTH] ? '1 : mult_1_result[MULT_1_SAT_WIDTH-1:0]; // Q(0.8.12)
// truncate LSB's
assign mult_1_scaled = mult_1_sat[MULT_1_SAT_WIDTH-1:MULT_1_SAT_WIDTH-MULT_1_SCALED_WIDTH]; // Q(0.8.8) 

//
// LUT PATH
//
assign addr0_sat = |samp_0_abs[ABS_IN_WIDTH-1:SAT_ADDR_WIDTH] ? '1 : samp_0_abs[SAT_ADDR_WIDTH-1:0]; // Q(0.6.12)
assign addr1_sat = |samp_1_abs[ABS_IN_WIDTH-1:SAT_ADDR_WIDTH] ? '1 : samp_1_abs[SAT_ADDR_WIDTH-1:0]; // Q(0.6.12)

always_comb begin : round_addr_c
  // [WARNING] no overflow handling
  // [INFO] rounding to match matlab behaviour
  a1 = addr0_sat[SAT_ADDR_WIDTH-1:6] + addr0_sat[5]; // Q(0.6.6)
  a2 = addr1_sat[SAT_ADDR_WIDTH-1:6] + addr1_sat[5]; // Q(0.6.6)
end

// TIMING VIOLATION, NEED TO REGISTER THIS PROCESS!
always_comb begin : calc_and_sat_samp_sum_c
  samp_sum = a1+a2; // Q(0.7.6)
  lut_addr = (samp_sum[LUT_ADDR_WIDTH]==1'b1) ? '1 : samp_sum; // Q(0.7.6) -> Q(0.6.6)
end

LUT #(
  .ADDR_WIDTH(LUT_ADDR_WIDTH),
  .DATA_WIDTH(LUT_DATA_WIDTH)
)i_lut(
  .clk    (clk     ),
  .rst_p  (rst_p   ),
  .address(lut_addr), // Q(0.6.6)
  .data_o (lut_data)  // Q(0.7.6)
);

//
// MULT_2 PATH
//
always_ff @(posedge clk) begin : mult_2_ff
  if (rst_p) begin
    mult_2_result               <=  '{default:0};
  end else begin
    mult_2_result               <= lut_data*mult_1_scaled; // on block diagram this flip flop is after rounding Q(0.15.14)
  end
end

// saturate
assign mult_2_sat = |mult_2_result[MULT_2_WIDTH-1:MULT_2_SAT_WIDTH] ? '1 : mult_2_result[MULT_2_SAT_WIDTH-1:0]; // Q(0.8.14)
// round
assign result_rnd = mult_2_sat[MULT_2_SAT_WIDTH-1:MULT_2_SAT_WIDTH-OUT_WIDTH] + mult_2_sat[MULT_2_SAT_WIDTH-OUT_WIDTH-1]; // Q(0.9.8)
// handle rounding overflow
// assign result = result_rnd[OUT_WIDTH] ? '1 : result_rnd[OUT_WIDTH-1:0]; // Q(0.8.8)
always_ff @(posedge clk) begin : result_ff
  if (rst_p) begin
    result_r <= '0;
  end else begin
    result_r <= result_rnd[OUT_WIDTH] ? '1 : result_rnd[OUT_WIDTH-1:0]; // Q(0.8.8)
  end
end
assign result = result_r;

//
// ZERO CROSS PULSE GENERATOR
//
always_ff @(posedge clk) begin
  if (rst_p) begin
    zero_cross_pulse   <= 1'b0;
    zero_cross_pulse_d <= 1'b0;
  end else begin
    if (sample_in_0 < 0 && sample_in_1 >= 0) begin 
      zero_cross_pulse <= 1'b1;
    end else begin
      zero_cross_pulse <= 1'b0;
    end
    zero_cross_pulse_d[0] <= zero_cross_pulse; // allign pulse with result
    zero_cross_pulse_d[1] <= zero_cross_pulse_d[0];
  end
end

assign result_vld = zero_cross_pulse_d[0]; // to allign with control FSM
assign result_vld_d = zero_cross_pulse_d[1];

endmodule
