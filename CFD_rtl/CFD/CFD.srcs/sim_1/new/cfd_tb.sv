`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.07.2023 17:55:12
// Design Name: 
// Module Name: cfd_tb
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


module cfd_tb();

localparam IN_WIDTH      = 12;
localparam PIPE_DLY      = 16;
localparam PULSE_SAMPLES = 801;
localparam CLK_HALF_T    = 5;
localparam ADC_PERIOD_NS = 100;

logic                clk                             ;
logic                rst_p                           ;
logic [IN_WIDTH-1:0] in_pulse_arr [PULSE_SAMPLES-1:0];
logic [IN_WIDTH-1:0] data_in                         ;
logic                pulse_out                       ;
logic                data_vld_in                     ;


initial begin
  $readmemh("D:/Studia_EiT/magisterskie/Praca_Magisterska/DCFD/CFD_rtl/CFD/gaussian_impulse_12b.txt", in_pulse_arr);
end

initial
  clk = 1'b0;
always
  #CLK_HALF_T clk = ~clk;
  
initial begin
  rst_p = 1'b1;
  #20 rst_p = 1'b0;
end

initial begin
  data_in = '{default:0};
  @(negedge rst_p);
  @(posedge clk); // allign to rising edges of clock
  for(int n=0; n<PULSE_SAMPLES; n=n+1) begin
    data_in = in_pulse_arr[n];
    data_vld_in = 1'b1;
    #(2*CLK_HALF_T);
    data_vld_in = 1'b0;    
    #(2*CLK_HALF_T); 
  end
  #(100*CLK_HALF_T) $finish();
end

cfd #( .IN_WIDTH     (IN_WIDTH     ),
       .PIPE_DLY     (PIPE_DLY     ),
       .ADC_PERIOD_NS(ADC_PERIOD_NS)
    )cfd_uut(
       .clk          (clk        ),
       .rst_p        (rst_p      ),
       .sample_vld_in(data_vld_in),
       .sample_in    (data_in    ),
       .pulse_out    (pulse_out  )
    );

endmodule
