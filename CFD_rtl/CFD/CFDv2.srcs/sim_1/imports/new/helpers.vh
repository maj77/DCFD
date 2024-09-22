//////////////////////////////////////////////////////////////////////////////////
// Company: AGH
// Engineer: Marcin Maj
// 
// Create Date: 13.04.2024 20:26:20
// Design Name: 
// Module Name: helpers
// Description: File contains useful tasks, functions
// 
//////////////////////////////////////////////////////////////////////////////////
// `ifndef HELPERS
// `define HELPERS
// `include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// TYPEDEFS
//////////////////////////////////////////////////////////////////////////////////
// typedef logic [IN_WIDTH-1:0] array_t [PULSE_SAMPLES-1:0];

//////////////////////////////////////////////////////////////////////////////////
// TASKS
//////////////////////////////////////////////////////////////////////////////////
task feed_all_amp_waves(input integer samp_delay_clks);
    integer delay;
  begin
    if(samp_delay_clks<1) begin
        delay = 1;
    end else begin
        delay = samp_delay_clks;
    end
    for(int wave_no=0; wave_no<AMP_SWEEP_LEN-1; wave_no=wave_no+1) begin
      for(int sample=0; sample<PULSE_SAMPLES-1; sample=sample+1) begin
        data_in                   = amp_sweep_waves[wave_no][sample];
        th_matlab_samp_inserted   = amp_sweep_thresholds[wave_no][sample]; 
        #(2*CLK_HALF_T*delay);
      end
    end
  end 
endtask

task feed_all_width_waves(input integer samp_delay_clks);
    integer delay;
  begin
    if(samp_delay_clks<1) begin
        delay = 1;
    end else begin
        delay = samp_delay_clks;
    end
  
    for(int wave_no=0; wave_no<AMP_SWEEP_LEN-1; wave_no=wave_no+1) begin
      for(int sample=0; sample<PULSE_SAMPLES-1; sample=sample+1) begin
        data_in                   = width_sweep_waves[wave_no][sample];
        th_matlab_samp_inserted   = width_sweep_thresholds[wave_no][sample]; 
        #(2*CLK_HALF_T*delay);
      end
    end
  end 
endtask

//////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS
//////////////////////////////////////////////////////////////////////////////////
function logic [IN_WIDTH-1:0][1:0] get_max_val_idx (input logic [IN_WIDTH-1:0] arr [PULSE_SAMPLES-1:0]);
    static logic [IN_WIDTH-1:0] max_val = arr[0];
    static logic [IN_WIDTH-1:0] idx     = 0;
    for(int i=1; i<PULSE_SAMPLES; i=i+1) begin
        if(max_val < arr[i]) begin
            max_val = arr[i];
            idx     = i;
        end
    end
    return {max_val,idx};
endfunction

function int get_val_idx (input logic [IN_WIDTH-1:0] arr [PULSE_SAMPLES-1:0], input real scale);
       // function finds max*scale value and index of array containing it
    static logic [IN_WIDTH-1:0] max_val;
    static logic [IN_WIDTH-1:0] max_val_idx;
    static int idx;
    {max_val, max_val_idx} = get_max_val_idx(arr);
    for(int i=max_val_idx; i>0; i=i-1) begin
        if((max_val*scale)-5 < arr[i] && (max_val*scale)+5 >arr[i]) begin
            idx = i;
            $display("max val * scale = %f", max_val*scale);
            break;
        end
    end
    return idx;
endfunction

// function array_t gen_wave(input logic dummy);
//     static logic [IN_WIDTH-1:0] arr [PULSE_SAMPLES-1:0];
//     for(int i=0; i<PULSE_SAMPLES/2; i=i+1) begin
//         arr[i] = (i+1)*10;
//     end
//     for(int i=PULSE_SAMPLES/2; i<PULSE_SAMPLES; i=i+1) begin
//         arr[i] = arr[PULSE_SAMPLES-1-i];
//     end
// //    arr[30:16] = arr[0:14];
//     return arr;
// endfunction

// `endif