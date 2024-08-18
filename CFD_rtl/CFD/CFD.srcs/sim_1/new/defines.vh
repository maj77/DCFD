`ifndef DEFINES
`define DEFINES
//////////////////////////////////////////////////////////////////////////////////
// Company: AGH
// Engineer: Marcin Maj
// 
// Create Date: 13.07.2024 20:26:20
// Design Name: 
// Module Name: none
// Description: File contains parameters
// 
//////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////////////////////////
parameter IN_WIDTH               = 12;
parameter PIPE_DLY               = 142; // delay of 120 samples, new sample every 1 cfd clock
parameter FPGA_CLOCKS_PER_SAMPLE = 1;
parameter PULSE_SAMPLES          = 2201;
parameter CLK_HALF_T             = 5;      // ns
parameter CLK_SER_HALF_T         = 1.67;
parameter ADC_PERIOD_NS          = 16;
parameter SCALE_FACTOR_WIDTH     = 12;

`endif