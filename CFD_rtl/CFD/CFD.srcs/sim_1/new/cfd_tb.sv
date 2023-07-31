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

localparam IN_WIDTH      = 32;
localparam PIPE_DLY      = 65;
localparam PULSE_SAMPLES = 801;
localparam CLK_HALF_T    = 5;
logic                clk                             ;
logic                rst_p                           ;
logic [IN_WIDTH-1:0] in_pulse_arr [PULSE_SAMPLES-1:0];
logic [IN_WIDTH-1:0] data_in                         ;
logic                pulse_out                       ;

initial begin
  $readmemh("D:/Studia_EiT/magisterskie/Praca_Magisterska/DCFD/CFD_rtl/CFD/gaussian_impulse.txt", in_pulse_arr);
end

initial
  clk <= 1'b0;
always
  #CLK_HALF_T clk <= ~clk;
  
initial begin
  rst_p <= 1'b1;
  #20 rst_p <= 1'b0;
end

initial begin
  for(int n=0; n<PULSE_SAMPLES; n=n+1) begin
    #CLK_HALF_T data_in <= in_pulse_arr[n];
  end
end

cfd #( .IN_WIDTH(IN_WIDTH),
       .PIPE_DLY(PIPE_DLY)
    )cfd_uut(
       .clk      (clk      ),
       .rst_p    (rst_p    ),
       .sample_in(data_in  ),
       .pulse_out(pulse_out)
    );

endmodule
