function [clocks, clocks_fxp] = zero_cross(wave, T_i, T_width, ...
                                    samp_in_width, samp_in_fract, ....
                                    lut_out_width, lut_out_fract, ...
                                    out_width, out_fract, out_int)
% ZERO_CROSS implements zero cross module functionality, based on formula q=|a1|*T/(|a1|+|a2|) where:
%            q      - is numerator of q/T expression which is interpreded as fraction of LHC clock. 
%                     In which zero cross happend
%            T      - determines how many parts we divide the LHC clock period into
%            a1, a2 - input samples from ADC
%   wave       - input samples: one negative, one positive
%   T_i        - number of DCFD clocks within one LHC clock period
%   T_width    - number of bits used for storing T_i value
%   samp_in_width - total bits of input sample
%   samp_in_fract - fractional bits of input sample
%   int_bits   - integer bits of input data
%   fract_bits - number of bits in fractional part
%  

%% ------ initialization ------
n_wave_samples = max(size(wave));
wave_internal = wave;
negative_sample = 0; % a1 in rtl
positive_sample = 0; % a2 in rtl


% search for two samples with opposite sign samples
for n=1:1:n_wave_samples-1
    if (wave_internal(n)<0 && wave_internal(n+1)>=0)
        disp(["n = ", n])
        disp(["n+1 = ", n+1])
        negative_sample = wave_internal(n);
        positive_sample = wave_internal(n+1);
        break;
    end
end
display([["positive sample:", positive_sample]; ...
         ["negative sample:", negative_sample]])
%% ------------ fxp calculations ------------
% ------ convert input data to fxp ------
T = fi(T_i, 0, T_width, 0);
neg_sample = fi(abs(negative_sample), 0, samp_in_width, samp_in_fract);
pos_sample = fi(positive_sample, 0, samp_in_width, samp_in_fract);

% ------ first multiplication ------
first_mult = T*neg_sample;
first_mult_sat = fi(first_mult, 0, 16, 8); % for now it will remain hardcoded

% ------ LUT calculations ------
lut_expr = fi(1 / (abs(negative_sample) + positive_sample), 0, ...
              lut_out_width, lut_out_fract);
disp("Theoretical lut value")
disp(lut_expr)

% ------ second multiplication ------
% mult_expr = fi(abs(negative_sample)*T, 0 , mult_width, mult_fract);
second_mult = first_mult_sat*lut_expr;

display("---- ZERO CROSS INFO ----");
% display(wave);
clocks_fxp_int = fi(second_mult, 0, out_width, 0);
display(clocks_fxp_int)
clocks_fxp_temp = fi(second_mult, 0, out_width, out_fract);
display(clocks_fxp_temp)
clocks_fxp = fi(clocks_fxp_temp - clocks_fxp_int, 0, out_fract, out_fract);
display(clocks_fxp)
display("---- ---- ---- ---- ----")
%% ------------ flp calculations ------------
clocks = abs(negative_sample)*T_i/(positive_sample+abs(negative_sample));
display(clocks)
end

