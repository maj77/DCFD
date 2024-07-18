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
T             = 16;
T_width       = ceil(log2(T))+1;
lut_in_width  = 6;
lut_in_fract  = 3;
lut_out_width = 16;
lut_out_fract = 11;
samp_in_width = 12; %zc module 
samp_in_fract = 0; %zc module
out_int       = 4;
out_fract     = 4;
out_width     = out_fract + out_int;

DELAY = 120; % delay in samples
SCALE = 0.8;

%% use calss
cfd = CFD_class(T, lut_in_width, lut_in_fract, lut_out_width, lut_out_fract, ...
                samp_in_width, samp_in_fract, out_int, out_fract, DELAY, SCALE);
%%
cfd.original_wave = amplitude_sweep_arr_fxp(1,:);
cfd = cfd.delay_wave();
cfd = cfd.scale_wave();
cfd = cfd.subtract_wave();

res = cfd.subtracted_wave();
%% generate waves
testv = amplitude_sweep_arr_fxp(10,:); %amplitude_sweep_arr_fxp(7,:);
testv2 = amplitude_sweep_arr(1,:);
[dummy, max_amp_max_width_fxp]= gaussian_pulse(amplitude_max, width_coeff_max, x, fxp_width, fxp_frac);
%testv = double(max_amp_max_width_fxp);
%% delay, scale, subtract
wave_delayed     = [zeros(1,DELAY), testv]; % testv jest wziete z gassian_pulse_generator.m z sekcji playground
wave_in          = [testv, zeros(1,DELAY)];
wave_in2         = [testv2, zeros(1,DELAY)];
wave_delayed_flp = [zeros(1,DELAY), testv2];

no_of_samples = size(wave_in,2);
%t = linspace(0,no_of_samples,no_of_samples)*10;
t = 0:10:(no_of_samples-1)*10; % every sample each 10 ns
wave_scaled = wave_in*SCALE;

wave_sub  = wave_delayed-wave_scaled;
wave_sub2 = wave_scaled - wave_delayed;

wave_scaled_flp = wave_in2*SCALE;
wave_sub_flp = wave_scaled_flp - wave_delayed_flp;
%% calculate moving average from wave_sub

wave_avg  = zeros(1, size(wave_sub, 2));
wave_avg2 = zeros(1, size(wave_sub, 2));
for n=1:1:size(wave_sub,2)-2
    wave_avg(n) = fi(sum(wave_sub2(1,[n:n+1])), 1, 24, 12);
    wave_avg(n) = fi(wave_avg(n)/2, 1, 24, 12);
end

for n=1:1:size(wave_sub,2)-4
    wave_avg2(n) = fi(sum(wave_sub2(1,[n:n+3])), 1, 24, 12);
    wave_avg2(n) = fi(wave_avg2(n)/4, 1, 24, 12);
end
%%
max_amp_wave_fxp = amplitude_sweep_arr_fxp(1,:);
min_amp_wave_fxp = amplitude_sweep_arr_fxp(1,:);

figure(1)
hold('on');
stairs(max_amp_wave_fxp);
stairs(max_amp_max_width_fxp);
legend("lowest amplitude signal", "highest amplitude signal");


%% calculate zero-cross time
figure(1);
hold('on');
wave_zero = zeros(1, size(wave_sub, 2));

plot(t, wave_zero);
plot(t, wave_in, "k",'MarkerSize',20);
plot(t, wave_delayed, "r",'MarkerSize',10);
plot(t, wave_scaled, "b");
plot(t, wave_sub, "go");
%plot(t, wave_sub2, "ro");
legend("zero level", "original wave", "Delayed wave","Scaled wave", "subtraction wave");

% TODO: DOUBLE CHECK TIME SCALING - in verilog clk period is 10ns
xlabel("time [ns]") % 

ylabel("signal value Q(0.12.0)")
%legend("zero lvl","original wave", "delayed wave", "scaled wave", "zero-cross wave", "zero-cross wave2");

%%
wave_zero = zeros(1, size(wave_sub, 2));
figure(2);
hold('on');

plot(t, wave_zero);
stairs(t, wave_sub2, "r", "LineWidth",2);
%stairs(t, wave_avg, "b", "LineWidth",2);
%stairs(t, wave_avg2, "c", "LineWidth",2);
%plot(t, wave_sub_flp, "g");
stairs(t, wave_sub_flp, "g");

legend("zero level", "wave subtracted fxp", "wave subtracted flp")
%legend("zero level", "wave subtracted", "wave averaged 2 samples", "wave averaged 4 samples","wave subtracted floating point");

[clocks, clocks_fxp] = zero_cross(wave_sub, T, T_width, samp_in_width, ...
                        samp_in_fract, lut_out_width, lut_out_fract, ...
                        out_width, out_fract, out_int);

