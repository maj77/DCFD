%% setup
clc; clear; close all;
format longG

f_adc = 10000;   % 10 KHz
T_adc = 1/f_adc; % 0.1 ms

amplitude = 500;
width_coeff = 1000;
stop = 0.1;
start = -0.1;
x = -0.01+start:T_adc:0.01+stop;

fxp_width = 12;
fxp_frac  = 6;

[pulse_fp, pulse_fxp] = gaussian_pulse(amplitude, width_coeff, ...
                                       x, fxp_width, fxp_frac);


%% plot waves
figure(1)
plot(x, pulse_fp);
hold on;
plot(x, pulse_fxp, 'r')


%% save wave to file
pulse_fp_transposed = pulse_fp';

%save("gaussian_pulse_double.txt", "pulse_fp_transposed", "-ascii");
fid = fopen("gaussian_pulse_double.txt", 'w');
fprintf(fid,'%3.10f \n',pulse_fp_transposed);
fclose(fid);
%save("gaussian_pulse_fxp_0_12_6.txt", "pulse_fxp", "-ascii");


