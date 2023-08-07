`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.08.2023 20:03:01
// Design Name: 
// Module Name: interpolator_tb
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


module interpolator_tb();

localparam DATA_WIDTH    = 32;
localparam PULSE_SAMPLES = 801;

logic                         clk                               ;
logic                         rst_p                             ;
logic signed [DATA_WIDTH-1:0] sample_0                          ;
logic signed [DATA_WIDTH-1:0] sample_1                          ;
logic signed [DATA_WIDTH-1:0] result_samples [2:0]              ;
logic        [DATA_WIDTH-1:0] in_pulse_arr   [PULSE_SAMPLES-1:0];

initial begin
  $readmemh("D:/Studia_EiT/magisterskie/Praca_Magisterska/DCFD/CFD_rtl/CFD/gaussian_impulse.txt", in_pulse_arr);
end

initial
  clk <= 1'b0;
always
  #5 clk <= ~clk;
  
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
       #10
       sample_0 = in_pulse_arr[n];
       sample_1 = in_pulse_arr[n+1];
     end
end

interpolator #(
  .IN_WIDTH(DATA_WIDTH)
)interpolator_uut(
  .clk        (clk           ),
  .rst_p      (rst_p         ),
  .sample_in_0(sample_0      ),
  .sample_in_1(sample_1      ),
  .samples_out(result_samples)
);
   

endmodule
