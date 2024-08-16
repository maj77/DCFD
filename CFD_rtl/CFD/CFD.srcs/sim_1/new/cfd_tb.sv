`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: AGH <3
// Engineer: Marcin Maj
// Create Date: 29.07.2023 17:55:12
// Module Name: cfd_tb
// /////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module cfd_tb();
`include "defines.vh"
`include "test_vectors.vh"

// params below included from helpers.vh
//localparam IN_WIDTH      = 16;
//localparam PIPE_DLY      = 120;
//localparam PULSE_SAMPLES = 2201; //801; //32;
//localparam CLK_HALF_T    = 5;
//localparam ADC_PERIOD_NS = 100;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CFD CONNECTIONS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
logic                clk                              ;
logic                clk_ser                          ;
logic                rst_p                            ;
// logic [IN_WIDTH-1:0] in_pulse_arr  [PULSE_SAMPLES-1:0];
// logic [IN_WIDTH-1:0] threshold_arr [PULSE_SAMPLES-1:0];
logic [IN_WIDTH-1:0] data_in                          ;
logic                pulse_out                        ;
logic                data_vld_in                      ;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TESTBENCH SIGNALS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
logic [IN_WIDTH-1:0] max_arr_val;
logic [IN_WIDTH-1:0] max_val_arr_idx;
int                  scaled_val_idx;
logic                th_matlab_samp_inserted; // threshold sample from matlab
logic                th_verilog_samp_inserted; // threshold sample calculated in verilog tb, val=0.8*wave_max_amplitude


// `include "helpers.vh"


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LOAD TEST VECTORS - deprecated
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// vivado executes from different location than source files 
// string path     = "D:/Studia_EiT/Magisterskie/Praca_Magisterska/DCFD/python_scripts/TV/PROCESSED_TV/amplitude_1_.txt";
// string path_th  = "D:/Studia_EiT/Magisterskie/Praca_Magisterska/DCFD/python_scripts/TV/PROCESSED_TV/amplitude_1_threshold_sample_.txt";


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GENERATE CLOCK & RESET
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
initial
  clk = 1'b0;
always
  #CLK_HALF_T clk = ~clk;

initial begin
  rst_p = 1'b1;
  #20 rst_p = 1'b0;
end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FEED WAVES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int wave_no=0;
event amp_test_end;
initial begin : feed_samples
  int sample_no;
  //--------------------------------------------------------------------------------------------------------------------
  // AMPLITUDE SWEEP WAVES
  //--------------------------------------------------------------------------------------------------------------------
  data_in = '{default:0};
  th_matlab_samp_inserted  = 0;
  
  $display("[INFO] Starting simulation with parameters:\n");
  $display("       PIPE_DLY = %d", PIPE_DLY);
  $display("       ADC_PERIOD_NS = %d", ADC_PERIOD_NS);

  @(negedge rst_p);
  repeat(20) @(posedge clk); // allign to rising edges of clock
  for(wave_no=0; wave_no<AMP_SWEEP_LEN; wave_no=wave_no+1) begin : feed_amp_samples
    $display("[INFO] @%f Passing amplitude sweep wave: %s, wave no: %d", $realtime, amp_testname.name, wave_no);
    for(sample_no=0; sample_no<PULSE_SAMPLES; sample_no=sample_no+1) begin
      data_in                   = amplitude_sweep_waves[wave_no][sample_no];
      if ($isunknown(data_in)) begin // IEEE Std 1800-2017 function
        $display("[ERROR] @%f Found X's in data_in vector! Stopping simulation...\n", $realtime);
        $stop();
      end
      th_matlab_samp_inserted   = amplitude_sweep_thresholds[wave_no][sample_no]; 
      #(2*CLK_HALF_T);
    end
    amp_testname = amp_testname.next;
    // $stop();
  end
  ->amp_test_end;
  amp_testname = amp_testname.first;
  #(100*2*CLK_HALF_T); // wait 100clks then finish sim
  $finish();

  //--------------------------------------------------------------------------------------------------------------------
  // WIDTH SWEEP WAVES
  //--------------------------------------------------------------------------------------------------------------------
  #(100*CLK_HALF_T) 
  for(int wave_no=0; wave_no<WIDTH_SWEEP_LEN; wave_no=wave_no+1) begin : feed_width_samples
    $display("[INFO] @%f Passing width sweep wave: %s, wave no: %d", $realtime, width_testname.name, wave_no);

    for(sample_no=0; sample_no<PULSE_SAMPLES; sample_no=sample_no+1) begin
      data_in                   = width_sweep_waves[wave_no][sample_no];
      th_matlab_samp_inserted   = width_sweep_thresholds[wave_no][sample_no]; 
      #(2*CLK_HALF_T);
    end
  end
  width_testname = width_testname.next;
  $finish();
end

always @(posedge th_matlab_samp_inserted) begin : report_th_samp
    $display("[INFO] @%f THRESHOLD SAMPLE INSERTED AT TIME %f [ns]", $realtime, $realtime());
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHECK ZERO-CROSS PULSE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//TODO: wrap it into task
bit cfd_zc;
bit passth_zc;
integer zc_diff_clks = 0;
integer zc_diff_clks_arr[$];
always @(posedge pulse_out) begin : catch_cfd_zc_vld
  cfd_zc = 1;
  // $display("[DEBUG] pulse_out posedge event at %f [ns]", $realtime());
end
always @(posedge th_passthrough_out_vld) begin : catch_tb_zc_vld
  passth_zc = 1;
  // $display("[DEBUG] th_passth_out_vld posedge event at %f [ns]", $realtime());
end
always @(zc_diff_clks) begin
  // $display("[DEBUG] zc_clk_diffs changed at %f [ns]", $realtime());
end

always @(posedge passth_zc, posedge cfd_zc) begin : calc_zc_diffs
  #1; // to overcome race condition
  // $display("[DEBUG] cfd_zc = %d, passth_zc = %d at time: %f [ns]", cfd_zc, passth_zc, $realtime());
  if (cfd_zc === 1 && passth_zc === 0) begin
    // zc_diff_clks = 0; 
    do begin
      @(posedge clk);
      if (passth_zc != 1) begin
        zc_diff_clks = zc_diff_clks + 1;
      end
    end while(passth_zc != 1);
    cfd_zc    = 0;
    passth_zc = 0; 
    $display("[INFO] @%f Difference between cfd zc pulse and passthrough zc pulse is: %d [clocks], cfd pulse first\n\n", $realtime, zc_diff_clks);
  end else if (cfd_zc === 0 && passth_zc === 1) begin
    // zc_diff_clks = 0;
    do begin
      @(posedge clk);
      if (cfd_zc != 1) begin 
        zc_diff_clks = zc_diff_clks - 1;
      end
    end while(cfd_zc != 1);
    cfd_zc    = 0;
    passth_zc = 0;
    $display("[INFO] @%f Difference between cfd zc pulse and passthrough zc pulse is: %d [clocks], passth pulse first\n\n", $realtime, zc_diff_clks);
  end else begin
    cfd_zc       = 0;
    passth_zc    = 0;
    $display("[INFO] @%f CFD ZC PULSE AND PASSTHROUGH ZC PULSE OCCURED AT THE SAME TIME: 0 [clocks]\n\n", $realtime);
  end
  #(CLK_HALF_T) zc_diff_clks = 0; // delay to get this signal visible on waves
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// COMPARE RESULT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
logic signed [cfd_uut.ZC_OUT_WIDTH-1:0] amp_sweep_rtl_results [AMP_SWEEP_LEN-1:0]; // RTL results are in Q(0.8.8) format for now
logic signed [  cfd_uut.ZC_OUT_WIDTH:0] result_diff_arr       [AMP_SWEEP_LEN-1:0];
logic signed [  cfd_uut.ZC_OUT_WIDTH:0] result_diff;
logic        [cfd_uut.ZC_OUT_WIDTH-1:0] rtl_result; 
logic        [cfd_uut.ZC_OUT_WIDTH-1:0] matlab_result;
// logic signed [cfd_uut.ZC_OUT_WIDTH-1:0] 
integer failed_wave_nums [$];

localparam MATLAB_OUT_FRACT = 8;
localparam MATLAB_OUT_INT   = 8;
// compare results from matlab against rtl results
// [13.08.24] INFO: Matlab samples are in Q(0.8.8) format
//                  RTL samples are in Q(0.8.8) format
initial begin : result_comparator
  integer      i                     = 0;
  real         zc_rtl_result_real    = 0;
  real         zc_matlab_result_real = 0;
  real signed  zc_diff_real          = 0;
  forever begin 
    @(posedge pulse_out);
    amp_sweep_rtl_results[i] = cfd_uut.zc_result;
    rtl_result               = cfd_uut.zc_result;
    matlab_result            = amplitude_sweep_results[i];
    result_diff_arr[i]       = matlab_result - cfd_uut.zc_result;
    result_diff              = matlab_result - cfd_uut.zc_result;

    zc_rtl_result_real    = cfd_uut.zc_result;
    zc_rtl_result_real    = zc_rtl_result_real / (2**cfd_uut.ZC_OUT_FRACT);
    zc_matlab_result_real = amplitude_sweep_results[i];
    zc_matlab_result_real = zc_matlab_result_real / (2**MATLAB_OUT_FRACT);
    zc_diff_real          = zc_matlab_result_real - zc_rtl_result_real; //cresult_diff[i] / (2**cfd_uut.ZC_OUT_FRACT);

    $display("[INFO] @%f RTL result is:           %H [fxp Q(0.8.8)]", $realtime, amp_sweep_rtl_results[i]);
    $display("[INFO] @%f Matlab result is:        %H [fxp Q(0.8.8)]",  $realtime,amplitude_sweep_results[i]);
    $display("[INFO] @%f Difference:              %H [fxp Q(0.8.8)]\n", $realtime, result_diff_arr[i]);

    $display("[INFO] @%f RTL result is:    %f [real]", $realtime, zc_rtl_result_real);
    $display("[INFO] @%f Matlab result is: %f [real]", $realtime, zc_matlab_result_real);
    $display("[INFO] @%f Difference:       %f [real]\n", $realtime, zc_diff_real);
    if (zc_diff_real != 0) begin
      failed_wave_nums.push_back(wave_no);
    end
    i = i + 1;
  end
end

initial begin : report_failed_amp_waves
  real result_diff_real;
  integer failed_wave_no;
  wait(amp_test_end.triggered);

  if(failed_wave_nums.size() != 0) begin
    $display("[INFO] Failed waves: ");
    foreach (failed_wave_nums[i]) begin
      failed_wave_no = failed_wave_nums[i];
      result_diff_real = result_diff_arr[failed_wave_no]; 
      result_diff_real = result_diff_real / (2**cfd_uut.ZC_OUT_FRACT);
      $display("\t Amplitude sweep wave number: %d, difference: %f [real], difference %x [fxp Q(0.8.8)]", failed_wave_nums[i], result_diff_real, result_diff_arr[failed_wave_no]);
    end
    $display("\n\n");
  end else begin
    $display("[INFO] 0 fails, test PASSED succesfully :)\n\n");
  end
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Tested module instance
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
cfd #( .IN_WIDTH     (IN_WIDTH     ),
       .PIPE_DLY     (PIPE_DLY     ),
       .ADC_PERIOD_NS(ADC_PERIOD_NS)
)cfd_uut(
       .clk               (clk           ),
       .rst_p             (rst_p         ),
       .time_start        (1'bz          ),
       .th_passthrough_in (th_matlab_samp_inserted),
       .sample_vld_in     (data_vld_in   ),
       .sample_in         (data_in       ),
       .pulse_out         (pulse_out     ),
       .th_passthrough_out_vld(th_passthrough_out_vld)
    );

endmodule


