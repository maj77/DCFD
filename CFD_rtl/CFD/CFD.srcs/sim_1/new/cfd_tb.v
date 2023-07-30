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
localparam PIPE_DLY      = 10;
localparam PULSE_SAMPLES = 801;

logic [IN_WIDTH-1:0] in_pulse_arr [PULSE_SAMPLES-1:0];
logic [IN_WIDTH-1:0] test_arr     [13:0];

initial begin
  $readmemh("D:/Studia_EiT/magisterskie/Praca_Magisterska/CFD_rtl/CFD/gaussian_impulse.txt", in_pulse_arr);
  $readmemh("D:/Studia_EiT/magisterskie/Praca_Magisterska/CFD_rtl/CFD/gaussimpulse.txt", test_arr);
end

endmodule
