%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title:       CFD_sim_model
% Description: Matlab model of CFD, operates on FLP and FXP values
% Author:      Marcin Maj
% Date(circa): 12.09.23
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% clear workspace
clc; clear; close all;
%  for now you have to load testv from gaussian_pulse_generator.m

%% Initialize variables
T              = 1;
T_width        = 7; %ceil(log2(T))+1;
lut_in_width   = 12;
lut_in_fract   = 6;
lut_out_width  = 7+13;
lut_out_fract  = 13;
samp_in_width  = 25; %zc module 
samp_in_fract  = 12; %zc module
samp_in_signed = 1;
out_int        = 8;
out_fract      = 8;
out_width      = out_fract + out_int;

DELAY = 142; % delay in samples [IMPORTANT] KEEP IT ALLIGNED WITH RTL
SCALE = fi(0.8,0,12,12);

%% use calss
%cfd = CFD_class(T, lut_in_width, lut_in_fract, lut_out_width, lut_out_fract, ...
%                samp_in_width, samp_in_fract, out_int, out_fract, DELAY, SCALE);
%cfd.original_wave = amplitude_sweep_arr_fxp(1,:);
%cfd = cfd.delay_wave();
%cfd = cfd.scale_wave();
%cfd = cfd.subtract_wave();
%res = cfd.subtracted_wave();
%% delay, scale, subtract
wave_delayed     = [zeros(size(amplitude_sweep_arr_fxp,1),DELAY), amplitude_sweep_arr_fxp]; % testv jest wziete z gassian_pulse_generator.m z sekcji playground
wave_in          = [amplitude_sweep_arr_fxp, zeros(size(amplitude_sweep_arr_fxp,1),DELAY)];

wave_scaled = wave_in*SCALE;

wave_delayed_signed = fi(wave_delayed, 1, 25, 12);
wave_scaled_signed  = fi(wave_scaled, 1, 25, 12);

wave_sub  = wave_delayed - wave_scaled;
wave_sub_signed = fi(wave_delayed_signed - wave_scaled_signed, 1, 25, 12); % cut 1 MSB

% ------ test arrays ------
%wave_in2         = [testv2, zeros(size(amplitude_sweep_arr_fxp,1),DELAY)];
%wave_delayed_flp = [zeros(size(amplitude_sweep_arr_fxp,1),DELAY), testv2];
%wave_sub2 = wave_scaled - wave_delayed;
%wave_scaled_flp = wave_in2*SCALE;
%wave_sub_flp = wave_scaled_flp - wave_delayed_flp;

%% calculate moving average from wave_sub
% moving average
%wave_avg  = zeros(1, size(wave_sub, 2));
%wave_avg2 = zeros(1, size(wave_sub, 2));
%for n=1:1:size(wave_sub,2)-2
%    wave_avg(n) = fi(sum(wave_sub2(1,[n:n+1])), 1, 24, 12);
%    wave_avg(n) = fi(wave_avg(n)/2, 1, 24, 12);
%end
%
%for n=1:1:size(wave_sub,2)-4
%    wave_avg2(n) = fi(sum(wave_sub2(1,[n:n+3])), 1, 24, 12);
%    wave_avg2(n) = fi(wave_avg2(n)/4, 1, 24, 12);
%end

%% CALCULATE ZERO-CROSS TIME
clocks_arr           = zeros(1,size(wave_sub_signed,1));                                       % flp
clocks_fxp_fract_arr = fi(zeros(1,size(wave_sub_signed,1)), 0, out_int+out_fract, out_fract);  % Q(0.8.8)
clocks_fxp_arr       = fi(zeros(1,size(wave_sub_signed,1)), 0, out_int+out_fract, out_fract);  % Q(0.8.8)

DEBUG_EN = 0;
for wave_num=1:1:size(wave_sub_signed,1)
    [clocks, clocks_fxp_fract, clocks_fxp] = zero_cross(wave_sub_signed(wave_num,:), T, T_width, samp_in_signed, samp_in_width, ...
                            samp_in_fract, lut_out_width, lut_out_fract, ...
                            out_width, out_fract, out_int, DEBUG_EN);

    clocks_arr(wave_num)           = clocks;
    clocks_fxp_fract_arr(wave_num) = clocks_fxp_fract;
    clocks_fxp_arr(wave_num)       = clocks_fxp;
end

%%
plot(wave_sub_signed(7,:))
%%
clc
DEBUG_EN = 1;
wave_no  = 7; % same as in verilog testbench, in wave name wave number is written as wave_no+1
[clocks_temp, clocks_temp_fxp, ~] = zero_cross(wave_sub_signed(wave_no+1,:), T, T_width, samp_in_signed, samp_in_width, ...
                            samp_in_fract, lut_out_width, lut_out_fract, ...
                            out_width, out_fract, out_int, DEBUG_EN);
%% plot waves
figure(1);
hold('on');
wave_zero = zeros(1, size(wave_sub_signed, 2));
no_of_samples = size(wave_in,2);
%t = linspace(0,no_of_samples,no_of_samples)*10;
t = 0:10:(no_of_samples-1)*10; % every sample each 10 ns

plot(t, wave_zero);
plot(t, wave_in(5,:), "k",'MarkerSize',20);
plot(t, wave_delayed_signed(5,:), "r",'MarkerSize',10);
plot(t, wave_scaled_signed(5,:), "b");
plot(t, wave_sub_signed(5,:), "go");
%plot(t, wave_sub2, "ro");
legend("zero level", "original wave", "Delayed wave","Scaled wave", "subtraction wave");

% TODO: DOUBLE CHECK TIME SCALING - in verilog clk period is 10ns
xlabel("time [ns]") % 

ylabel("signal value Q(0.12.0)")
%legend("zero lvl","original wave", "delayed wave", "scaled wave", "zero-cross wave", "zero-cross wave2");