function [clocks, clocks_fxp_fract, clocks_fxp] = zero_cross(wave, T_i, T_width, ...
                                    samp_in_signed, samp_in_width, samp_in_fract, ....
                                    lut_out_width, lut_out_fract, ...
                                    out_width, out_fract, out_int, ...
                                    DEBUG_EN)
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

neg_sample_idx = 0;
pos_sample_idx = 0;
% search for two samples with opposite sign samples
for n=1:1:n_wave_samples-1
    if (wave_internal(n)<0 && wave_internal(n+1)>=0)
        %disp(["n = ", n])
        %disp(["n+1 = ", n+1])
        negative_sample = wave_internal(n);
        positive_sample = wave_internal(n+1);
        neg_sample_idx = n;
        pos_sample_idx = n+1;
        break;
    end
end
%display([["positive sample:", positive_sample]; ...
%        ["negative sample:", negative_sample]])
%% ------------ fxp calculations ------------
% ------ convert input data to fxp ------
T = fi(T_i, 0, T_width, 0);
neg_sample = fi(abs(negative_sample), samp_in_signed, samp_in_width, samp_in_fract);
pos_sample = fi(positive_sample, samp_in_signed, samp_in_width, samp_in_fract);

% ------ first multiplication ------
first_mult = T*neg_sample;
first_mult_sat = fi(first_mult, 0, 16, 8); % Q(0.8.7) for now it will remain hardcoded

% ------ LUT calculations ------
lut_expr = fi(1 / (abs(negative_sample) + positive_sample), 0, ...
              lut_out_width, lut_out_fract);
%disp("Theoretical lut value")
%disp(lut_expr)

% ------ second multiplication ------
% mult_expr = fi(abs(negative_sample)*T, 0 , mult_width, mult_fract);
second_mult = first_mult_sat*lut_expr;

%display("---- ZERO CROSS INFO ----");
% display(wave);
clocks_fxp_int  = fi(second_mult, 0, out_width, 0);
clocks_fxp_temp = fi(second_mult, 0, out_width, out_fract);

% tmp and int arrays made signed
clocks_fxp_temp_scaled = fi(clocks_fxp_temp, 1, out_width+out_fract+1, out_fract);
clocks_fxp_int_scaled  = fi(clocks_fxp_int, 1, out_width+out_fract+1, out_fract);

% if (clocks_fxp_temp_scaled.data==clocks_fxp_temp_scaled.data) % THAT ALWAYS RETURNS 0, WHY?
%     display("[POTENTIAL BUG/ERROR] clocks_fxp_temp_scaled is the same as clocks_fxp_temp_scaled")
%     display(clocks_fxp_temp_scaled)
%     display(clocks_fxp_int_scaled)
% end

clocks_fxp = fi(clocks_fxp_temp, 0, out_int+out_fract, out_fract);
clocks_fxp_scaled = abs(clocks_fxp_int_scaled - clocks_fxp_temp_scaled);
clocks_fxp_fract = fi(clocks_fxp_scaled, 0, out_int+out_fract, out_fract);

if (DEBUG_EN)
    fprintf("[DEBUG] neg_sample=%f\n", negative_sample);
    fprintf("[DEBUG] neg_sample_idx=%f\n", neg_sample_idx);
    fprintf("[DEBUG] pos_sample=%f\n", positive_sample);
    fprintf("[DEBUG] pos_sample_idx=%f\n", pos_sample_idx);
    fprintf("[DEBUG] T=%f\n", T);
    fprintf("[DEBUG] first_mult=%f\n", first_mult);
    fprintf("[DEBUG] first_mult_sat=%f\n", first_mult_sat);
    fprintf("[DEBUG] lut_expr=%f\n", lut_expr);
    fprintf("[DEBUG] second_mult=%f (technically it's result in full range)\n", second_mult);

%    fprintf("[DEBUG] clocks_fxp_temp=%f (result scaled to Q(0.%d.%d)\n", clocks_fxp_temp, out_width, out_fract);
%    fprintf("[DEBUG] clocks_fxp_int_scaled=%f (result scaled to Q(0.%d.%d)\n", clocks_fxp_int_scaled, out_width+out_fract, out_fract);
%    fprintf("[DEBUG] clocks_fxp_temp_scaled=%f (result scaled to Q(0.%d.%d)\n", clocks_fxp_temp_scaled, out_width+out_fract, out_fract);
%    fprintf("[DEBUG] clocks_fxp_scaled=%f (result scaled to Q(0.%d.%d)\n", clocks_fxp_scaled, out_width+out_fract, out_fract);
    fprintf("[DEBUG] clocks_fxp_fract=%f (result scaled to Q(0.%d.%d)\n", clocks_fxp_fract, out_int, out_fract);
    fprintf("[DEBUG] [RESULT] clocks_fxp=%f (result scaled to Q(0.%d.%d)\n\n\n", clocks_fxp, out_int, out_fract);
end
%% ------------ flp calculations ------------
clocks = abs(negative_sample)*T_i/(positive_sample+abs(negative_sample));
%display(clocks);
end

