%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title:       gaussian_pulse_generator
% Description: Main script for generating input waves for CFD
% Author:      Marcin Maj
% Date:        05.05.24
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% setup
clc; clear; close all;
format longG

f_adc = 1e4;     % 10 kHz
T_adc = 1/f_adc; % actually it's not used as ADC period, instead it is used to set number of waveform samples%
%T_adc = 10*1e-9; % 10 ns
%no_of_samples = 22001;


fxp_width = 12;
fxp_frac  = 0;
fxp_frac_int = 0;


% 12 bits -> max decimal value = 4095 Q(0.12.0) and ~63.98 in Q(0.6.6)
amplitude_max   = 2^(fxp_width-fxp_frac_int); % max value that can be saved on 12 bits
amplitude_min   = 2^3;

% 1 bit = 1 decimal = 0.015625 in Q(0.6.6)
epsilon         = 2^(-fxp_frac_int);
epsilon_mult    = 10;           % max epsilon = epsilon*epsilon_mult 
wave_signed     = 0;
amp_step        = 200;
width_coeff_max = 5000;
width_coeff_min = 1000;
width_step      = 100;
stop            = 0.1;
start           = -0.1;

THRESHOLD = 0.8;

x = -0.01+start:T_adc:0.01+stop;
%x = -T_adc*no_of_samples:100*T_adc:T_adc*no_of_samples;
x_size = size(x,2);

%% generate pulses

% amplitude sweep
amplitude_sweep_arr = zeros(1,x_size);
amplitude_sweep_arr_fxp = fi(zeros(1,x_size), wave_signed, fxp_width+wave_signed, fxp_frac_int); % actual format is Q (0.6.6) but for further calculations this array 
                                                                                                 % must be signed, so dummy bit which will be unused was added.

j = 1;
for amplitude = amplitude_min:amp_step:amplitude_max
    [amplitude_sweep_arr(j,:), amplitude_sweep_arr_fxp(j,:)]  = gaussian_pulse( ...
        amplitude, width_coeff_min, x, fxp_width, fxp_frac_int);
    j = j+1;
end

% width sweep
width_sweep_arr = zeros(1,x_size);
width_sweep_arr_fxp = fi(zeros(1,x_size), 1, fxp_width+1, fxp_frac_int);
j = 1;
for width_coeff = width_coeff_min:width_step:width_coeff_max
    [width_sweep_arr(j,:), width_sweep_arr_fxp(j,:)]  = gaussian_pulse( ...
        amplitude, width_coeff, x, fxp_width, fxp_frac_int);
    j = j+1;
end
%%
figure(1);
hold("on");
for n=1:1:82
    plot(amplitude_sweep_arr(n,:))
end

%% find index of threshold sample
clc;
%TODO: THIS CODE SHOULD BE REFACTORIZED

amplitude_sweep_arr_threshold  = zeros(1,x_size);
amp_threshold_idx_arr          = zeros(1,size(amplitude_sweep_arr_fxp,1));
amplitude_sweep_arr_threshold2 = zeros(1,x_size);
amp_threshold_idx_arr2         = zeros(1,size(amplitude_sweep_arr_fxp,1));


width_sweep_arr_threshold     = zeros(1,x_size);
width_threshold_idx_arr = zeros(1,size(amplitude_sweep_arr_fxp,1));

fail = 0;

% find index using epsilon equal to minimum fxp value (2^-fxp_frac)
% if no matching value found then extend 
for i = 1:1:size(amplitude_sweep_arr_fxp,1)
    vect = amplitude_sweep_arr_fxp(i,:);
    max_val = max(vect);
    threshold_val = max_val*THRESHOLD;
    threshold_idx = find(vect<=threshold_val+epsilon & vect>=threshold_val-epsilon);
    if size(threshold_idx) > 0
        amplitude_sweep_arr_threshold(i,threshold_idx(1)) = 1; %amplitude_max; %vect(threshold_idx(1));
        amp_threshold_idx_arr(i) = threshold_idx(1); % for debugging
    else
        % searching failed, search with extended epsilon:
        for ii = 1:1:epsilon_mult
            threshold_idx = find(vect<=threshold_val+ii*epsilon & vect>=threshold_val-ii*epsilon);
            if size(threshold_idx) > 0
%                 fprintf("success! found index for i = %d, ii = %d\n", i, ii);
%                 fprintf("epsilon value is %f\n", ii*epsilon);
%                 fprintf("index value = %d\n", threshold_idx(1));
%                 fprintf("max val = %f\ntheoretical threshold val = %f\nfound threshold val = %f\n", max_val, threshold_val, vect(1,threshold_idx(1)));
%                 fprintf("\n")
                amplitude_sweep_arr_threshold(i,threshold_idx(1)) = 1; %amplitude_max;
                amp_threshold_idx_arr(i) = threshold_idx(1);
                fail = 0;
                break
            else
                fail = 1;
            end
        end
        if fail == 1
            fprintf("[AMPLITUDE] FAILED AT i = %d\n", i);
        end
    end
end
if fail == 0
      fprintf("[AMPLITUDE] PASS \n");
end

[amplitude_sweep_arr_threshold2, amp_threshold_idx_arr2] = calc_thresholds(amplitude_sweep_arr_threshold, THRESHOLD, epsilon);

if (amplitude_sweep_arr_threshold2 == amplitude_sweep_arr_threshold)
    display("[INFO] DUPA");
end


%%
fail = 0; % reset flag
for i = 1:1:size(width_sweep_arr_fxp,1)
    vect = width_sweep_arr_fxp(i,:);
    max_val = max(vect);
    threshold_val = max_val*THRESHOLD;
    threshold_idx = find(vect<=threshold_val+epsilon & vect>=threshold_val-epsilon);
    if size(threshold_idx) > 0
        width_sweep_arr_threshold(i,threshold_idx(1)) = 1; %amplitude_max; %vect(threshold_idx(1));
        width_threshold_idx_arr(i) = threshold_idx(1);
    else
        % searching failed, search with extended epsilon:
        for ii = 1:1:epsilon_mult
            threshold_idx = find(vect<=threshold_val+ii*epsilon & vect>=threshold_val-ii*epsilon);
            if size(threshold_idx) > 0
%                  fprintf("success! found index for i = %d, ii = %d\n", i, ii);
%                  fprintf("epsilon value is %f\n", ii*epsilon);
%                  fprintf("index value = %d\n", threshold_idx(1));
%                  fprintf("max val = %f\ntheoretical threshold val = %f\nfound threshold val = %f\n", max_val, threshold_val, vect(1,threshold_idx(1)));
%                  fprintf("\n")
                width_sweep_arr_threshold(i,threshold_idx(1)) = 1; %amplitude_max;
                width_threshold_idx_arr(i) = threshold_idx(1);
                fail = 0;
                break
            else
                fail = 1;
            end
        end
        if fail==1
            fprintf("[WIDTH] FAILED AT i = %d\n", i);
        end
    end
end
if fail == 0
    fprintf("[WIDTH] PASS \n");
end

%% CALCULATE DELAYS

scaled_amp_wave   = 0.8.*amplitude_sweep_arr_fxp;
scaled_width_wave = 0.8.*width_sweep_arr_fxp;

[~, amplitude_threshold_samp_number] = max(amplitude_sweep_arr_threshold, [], 2);
[~, width_threshold_samp_number]     = max(width_sweep_arr_threshold, [], 2);

[~, amplitude_scaled_wave_max_val_samp_number] = max(amplitude_sweep_arr_fxp, [], 2);
[~, width_scaled_wave_max_val_samp_number]     = max(width_sweep_arr_fxp, [], 2);

AMPLIDUDE_DELAYS = amplitude_scaled_wave_max_val_samp_number - amplitude_threshold_samp_number;
WIDTH_DELAYS     = width_scaled_wave_max_val_samp_number - width_threshold_samp_number;

%% save amplitude sweep files: data + threshold sample

% save waves, each wave to separate file
j = 1;
for amplitude = amplitude_min:amp_step:amplitude_max
    fid = fopen("TV/amplitude_" +j+"_" + num2str(amplitude,'%04.f') + "_.txt", 'w');
    amplitude_sweep_arr_fxp_hex = hex(amplitude_sweep_arr_fxp(j,:)); % Q (0.12.0)
    fprintf(fid,'%c',amplitude_sweep_arr_fxp_hex); 
    fclose(fid);
    j = j + 1;
end

% save threshold files, each vector to separate file
j = 1;
for amplitude = amplitude_min:amp_step:amplitude_max
    fid = fopen("TV/amplitude_"+j+"_" + num2str(amplitude,'%04.f') + "_threshold_sample_.txt", 'w');
    amplitude_sweep_arr_threshold_bin = dec2bin(amplitude_sweep_arr_threshold(j,:)); % Q (0.1.0)
    fprintf(fid,'%c',amplitude_sweep_arr_threshold_bin);
    fclose(fid);
    j = j + 1;
end

%% save results file
% save each result to separate file
clc;
j = 1;
for amplitude = amplitude_min:amp_step:amplitude_max
    fid = fopen("TV/amplitude_" +j+"_" + num2str(amplitude,'%04.f') + "_result_.txt", 'w');
    result_bin = hex(clocks_fxp_arr(1,j)); % Q (0.4.4)
    fprintf(fid,'%c', result_bin);
    j = j + 1;
    fclose(fid);
end    

   
%% save width sweep files
j = 1;
for width_coeff = width_coeff_min:width_step:width_coeff_max
    width_sweep_arr_fxp_hex = hex(width_sweep_arr_fxp(j,:));
    width_sweep_arr_threshold_bin = dec2bin(width_sweep_arr_threshold(j,:));
    fid = fopen("TV/width_" +j+"_" + num2str(width_coeff, '%04.f') + "_.txt", 'w');
    fprintf(fid,'%c',width_sweep_arr_fxp_hex);
    fclose(fid);

    fid = fopen("TV/width_" +j+"_" + num2str(width_coeff, '%04.f') + "_threshold_sample_.txt", 'w');
    fprintf(fid,'%c',width_sweep_arr_threshold_bin);
    fclose(fid);
    j = j+1;
end

%% save wave to file
%pulse_fp_transposed = amplitude_sweep_arr(1,:)';

%save("gaussian_pulse_double.txt", "pulse_fp_transposed", "-ascii");
%save("gaussian_pulse_fxp_0_12_6.txt", "pulse_fxp", "-ascii");