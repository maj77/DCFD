`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.09.2023 18:54:19
// Design Name: 
// Module Name: zc_interpolator_tb
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


module zc_interpolator_tb();

localparam DATA_IN_WIDTH  = 25;
localparam DATA_OUT_WIDTH = 16;
localparam PULSE_SAMPLES  = 866;
localparam ADC_PERIOD_NS  = 100;
localparam CLK_PERIOD_NS  = 3.3;

logic                             clk                               ;
logic                             rst_p                             ;
logic        [ DATA_IN_WIDTH-1:0] in_pulse_arr   [PULSE_SAMPLES-1:0];
logic signed [ DATA_IN_WIDTH-1:0] sample_0                          ;
logic signed [ DATA_IN_WIDTH-1:0] sample_1                          ;
logic signed [DATA_OUT_WIDTH-1:0] result                            ;
logic                             zc_pulse                          ;


initial begin
  $readmemh("D:/Studia_EiT/magisterskie/Praca_Magisterska/DCFD/matlab/generated_data/Zero_cross_gaussian_signal_25b_s_12i_12f.txt", in_pulse_arr);
end

initial
  clk <= 1'b0;
always
  #CLK_PERIOD_NS clk <= ~clk;
  
initial begin
  rst_p <= 1'b1;
  #20 rst_p <= 1'b0;
end

initial begin
     sample_0 = '{default:0};
     sample_1 = '{default:0};
 #20 sample_1 = in_pulse_arr[0];
 #5  
     for (int n=0; n<PULSE_SAMPLES-1; n=n+1) begin
       #ADC_PERIOD_NS
       sample_0 = in_pulse_arr[n];
       sample_1 = in_pulse_arr[n+1];
     end
end

zc_interpolator #(
  .IN_WIDTH     ( DATA_IN_WIDTH),
  .OUT_WIDTH    (DATA_OUT_WIDTH),
  .ADC_PERIOD_NS( ADC_PERIOD_NS)
)zc_interpolator_uut(
  .clk        (clk     ),
  .rst_p      (rst_p   ),
  .sample_in_0(sample_0),
  .sample_in_1(sample_1),
  .result     (result  ),
  .result_vld (zc_pulse) 
);
   

endmodule
