`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AGH <3
// Engineer: Marcin Maj
// Create Date: 29.07.2023 17:55:12
// Module Name: cfd_tb
// 
//////////////////////////////////////////////////////////////////////////////////



module cfd_tb();
`include "defines.vh"
`include "test_vectors.vh"

// params below included from helpers.vh
//localparam IN_WIDTH      = 16;
//localparam PIPE_DLY      = 120;
//localparam PULSE_SAMPLES = 2201; //801; //32;
//localparam CLK_HALF_T    = 5;
//localparam ADC_PERIOD_NS = 100;

//import "DPI-C" function string scandir(string path);

////////////////////////////////////////////////////////////
// CFD CONNECTIONS
////////////////////////////////////////////////////////////
logic                clk                              ;
logic                clk_ser                          ;
logic                rst_p                            ;
logic [IN_WIDTH-1:0] in_pulse_arr  [PULSE_SAMPLES-1:0];
logic [IN_WIDTH-1:0] threshold_arr [PULSE_SAMPLES-1:0];
logic [IN_WIDTH-1:0] data_in                          ;
logic                pulse_out                        ;
logic                data_vld_in                      ;

////////////////////////////////////////////////////////////
// TESTBENCH SIGNALS
////////////////////////////////////////////////////////////
logic [IN_WIDTH-1:0] max_arr_val;
logic [IN_WIDTH-1:0] max_val_arr_idx;
int                  scaled_val_idx;
logic                th_matlab_samp_inserted; // threshold sample from matlab
logic                th_verilog_samp_inserted; // threshold sample calculated in verilog tb, val=0.8*wave_max_amplitude


// `include "helpers.vh"


////////////////////////////////////////////////////////////
// LOAD TEST VECTORS
////////////////////////////////////////////////////////////
// vivado executes from different location than source files 
string path     = "D:/Studia_EiT/Magisterskie/Praca_Magisterska/DCFD/python_scripts/TV/PROCESSED_TV/amplitude_1_.txt";
string path_th  = "D:/Studia_EiT/Magisterskie/Praca_Magisterska/DCFD/python_scripts/TV/PROCESSED_TV/amplitude_1_threshold_sample_.txt";


////////////////////////////////////////////////////////////
// GENERATE CLOCK & RESET
////////////////////////////////////////////////////////////
initial
  clk = 1'b0;
always
  #CLK_HALF_T clk = ~clk;

initial begin
  rst_p = 1'b1;
  #20 rst_p = 1'b0;
end


////////////////////////////////////////////////////////////
// FEED WAVES
////////////////////////////////////////////////////////////
initial begin
  data_in = '{default:0};
  th_matlab_samp_inserted  = 0;
  
  $display("[INFO] Starting simulation with parameters:\n");
  $display("       PIPE_DLY = %d", PIPE_DLY);
  $display("       ADC_PERIOD_NS = %d", ADC_PERIOD_NS);

  @(negedge rst_p);
  repeat(20) @(posedge clk); // allign to rising edges of clock
  for(int wave_no=0; wave_no<AMP_SWEEP_LEN; wave_no=wave_no+1) begin
    amp_testname = amp_testname.next;
    $display("[INFO] Passing amplitude sweep wave: %s, wave no: %d", amp_testname.name, wave_no);
    for(int sample=0; sample<PULSE_SAMPLES; sample=sample+1) begin
      data_in                   = amplitude_sweep_waves[wave_no][sample];
      th_matlab_samp_inserted   = amplitude_sweep_thresholds[wave_no][sample]; 
      #(2*CLK_HALF_T);
    end
  end
  
  amp_testname = amp_testname.first;

  #(100*CLK_HALF_T) 
  for(int wave_no=0; wave_no<WIDTH_SWEEP_LEN; wave_no=wave_no+1) begin
    width_testname = width_testname.next;
   $display("[INFO] Passing width sweep wave: %s, wave no: %d", width_testname.name, wave_no);
    for(int sample=0; sample<PULSE_SAMPLES; sample=sample+1) begin
      data_in                   = width_sweep_waves[wave_no][sample];
      th_matlab_samp_inserted   = width_sweep_thresholds[wave_no][sample]; 
      #(2*CLK_HALF_T);
    end
  end
  $finish();
end

always @(posedge th_matlab_samp_inserted) begin
    $display("[INFO] THRESHOLD SAMPLE INSERTED AT TIME %f [ns]", $realtime());
end

////////////////////////////////////////////////////////////
// CHECK ZERO-CROSS PULSE
////////////////////////////////////////////////////////////
//TODO: wrap it into task
bit cfd_zc;
bit passth_zc;
integer zc_diff_clks;
integer zc_diff_clks_arr[$];
always @(posedge pulse_out) begin : catch_cfd_zc_vld
  cfd_zc = 1;
end
always @(posedge th_passthrough_out_vld) begin : catch_tb_zc_vld
  passth_zc = 1;
end
always @(passth_zc, cfd_zc) begin
  if (cfd_zc === 1 && passth_zc === 0) begin
    zc_diff_clks = 0; 
    do begin
      @(posedge clk) zc_diff_clks = zc_diff_clks + 1;
    end while(passth_zc != 1);
    cfd_zc    = 0;
    passth_zc = 0; 
    $display("[INFO] Difference between cfd zc pulse and passthrough zc pulse is: %d [clocks]", zc_diff_clks);
  end 
  else if (cfd_zc === 0 && passth_zc === 1) begin
    zc_diff_clks = 0;
    do begin
      @(posedge clk) zc_diff_clks = zc_diff_clks + 1;
    end while(cfd_zc != 1);
    cfd_zc    = 0;
    passth_zc = 0;
    $display("[INFO] Difference between cfd zc pulse and passthrough zc pulse is: %d [clocks]", zc_diff_clks);
  end else begin
    zc_diff_clks = 0;
    cfd_zc       = 0;
    passth_zc    = 0;
    $display("[INFO] CFD ZC PULSE AND PASSTHROUGH ZC PULSE OCCURED AT THE SAME TIME: 0 [clocks]");
  end
end

////////////////////////////////////////////////////////////
// Tested module instance
////////////////////////////////////////////////////////////
cfd #( .IN_WIDTH     (IN_WIDTH     ),
       .PIPE_DLY     (PIPE_DLY     ),
       .ADC_PERIOD_NS(ADC_PERIOD_NS)
)cfd_uut(
       .clk               (clk           ),
       .clk_ser           (clk_ser       ),
       .rst_p             (rst_p         ),
       .th_passthrough_in (th_matlab_samp_inserted),
       .sample_vld_in     (data_vld_in   ),
       .sample_in         (data_in       ),
       .pulse_out         (pulse_out     ),
       .th_passthrough_out_vld(th_passthrough_out_vld)
    );

endmodule


