%% clear workspace
clc; clear; close all;

%% generate random samples
pos_samples = rand(1,100);
neg_samples = -rand(1,100);

%% Initialize variables
T = 16;
T_width = ceil(log2(T))+1;
lut_out_width = 16;
lut_out_fract = 11;
samp_in_width = 12;
samp_in_fract = 12;
out_int = 4;
out_fract = 4;
out_width = out_fract + out_int;

%% LUT
lut_in_width = 6;
lut_in_fract = 3;
[addr, val] = LUT_sim_model(neg_samples,pos_samples, lut_in_width, ...
                            lut_in_fract, lut_out_width, lut_out_fract);



%% calculate zero-cross time
clc; close;

[wave,t,wave2,t2] = generate_wave(-10,10);
wave_in = wave2;
figure(1)
hold('on')
plot(t2, wave2, "rx",'MarkerSize',20)
plot(t, wave, "bo");
% wave = [neg_samples; pos_samples];
% wave_in = wave(:,1)'; 
% wave = [-0.5822 0.4229];
[clocks, clocks_fxp] = zero_cross(wave_in, T, T_width, samp_in_width, ...
                        samp_in_fract, lut_out_width, lut_out_fract, ...
                        out_width, out_fract, out_int);

% display(["wave:", wave(:,1)'])
% display(clocks)
% display(clocks_fxp)

%% 
hold on
plot(t2, wave2, "bo");
plot(t,wave, "m.")
plot(t2(3727),wave2(3727), "r*")