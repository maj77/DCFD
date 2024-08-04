%% interpolation LUT
%  script creates 16bit values of given expression: 1/(a1+a2)
%  a1 and a2 are concatenated and used as memory adress.
%  For now format Q(0.6.6) is used for a1 and a2 which corresponds
%  to input values in range [0 : 64] with step = 0.0156
%  Sum of a1+a2 is taken as address, format is Q(0.7.6) which can cover
%  values in range [0:128)

%% clear workspace
clc; clear; close all;

%% Initialize a1 and a2
% Q(0.7.6) ->_ _ _ _ _ _ _ ._  _  _  _  _  _
%            6 5 4 3 2 1 0 -1 -2 -3 -4 -5 -6       
%             000000.000001 = 2^-6 -> 0.015625

ni    = 6; % no. of integer bits of a1 and a2
nf    = 6; % no. of fract bits 
range = 2^(ni-1);
step  = 2^(-nf);
a1    = step:step:2*range; % a1=0 and a2=0 should be handled in verilog!
a2    = 0:step:2*range-step;

%% Calculate LUT values
a1_fxp  = fi(a1, 0, 12, 6);           % Q (0.6.6)
lut_fxp = fi(1./a1, 0, 13, 6);        % Q (0.7.6)
lut     = 1./a1;

%%
addresses = a1_fxp.bin;
lut_vals  = lut_fxp;
LUT = [a1_fxp.data; lut_vals];
addresses_flp = 1./(a1+a2);

addr_file = fopen("generated_data/LUT_ADDR_NEW_Q_0_6_6.txt", "w");
fprintf(addr_file, '%c', addresses);
fclose(addr_file);

val_file = fopen("generated_data/LUT_VALS_NEW_Q_0_13_6.txt", "w");
fprintf(val_file, '%c', lut_vals.hex);
fclose(val_file);

%%
figure(1);
hold("on");
plot(lut_vals);
plot(1./a1);
stairs(lut_vals.data-(1./a1));
legend("lut data", "1/a", "diff");