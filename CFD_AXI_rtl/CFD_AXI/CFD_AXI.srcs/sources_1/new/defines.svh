package defines_pkg;
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

// standalone cfd params
// parameter IN_WIDTH               = 12;
// parameter PIPE_DLY               = 142; // delay of 120 samples, new sample every 1 cfd clock
parameter PULSE_SAMPLES          = 2201;
parameter CLK_HALF_T             = 5;      // ns
// parameter CLK_SER_HALF_T         = 1.67;
// parameter FPGA_CLOCKS_PER_SAMPLE = 16; // this param tells how many fpga clocks are within one adc period
// parameter SCALE_FACTOR_WIDTH     = 12;

// axi cfd params
parameter CFD_RESULT_WIDTH           = 20;
parameter CFD_IN_WIDTH               = 12; 
parameter CFD_FPGA_CLOCKS_PER_SAMPLE = 1;
parameter CFD_PIPE_DLY               = 142;
parameter CFD_SCALE_FACTOR_WIDTH     = 12;

`define AXI_SIM 1

endpackage