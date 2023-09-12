%% interpolation LUT
%  script creates 16bit values of given expression: 1/(a1+a2)
%  a1 and a2 are concatenated and used as memory adress.
%  For now format Q(0.3.3) is used for a1 and a2 which corresponds
%  to input values in range [0.125 : 8]

%% clear workspace
clc; clear; close all;

%% init
ni = 3; % no. of integer bits of a1 and a2
nf = 3; % no. of fract bits 
range = 2^(ni-1);
a1 = 2^(-nf):2^(-nf):2*range;
a2 = a1';

%% LUT fxp unsigned
a1_fxp = fi(a1, 0, 6, 3); % if I want unsigned values: fi(abs(data), 0, total_bits, fract_bits)
a2_fxp = a1_fxp'; % transposing to later get every combination of [a1,a2] concat

a1_fxp_hex = hex(a1_fxp');
a2_fxp_hex = hex(a2_fxp);

lut_fxp = fi(1./(a1+a2), 0 , 16, 11); % Q(5.11)
lut_fxp_unrolled = lut_fxp(:);
lut_fxp_hex = hex(lut_fxp_unrolled);

lut_fxp2 = fi(1./(a1+a2), 0 , 12, 6); % Q(0.6.6)
lut_fxp2_unrolled = lut_fxp2(:);
lut_fxp2_hex = hex(lut_fxp2_unrolled);

lut_fxp3 = fi(1./(a1_fxp+a2_fxp), 0 , 16, 11);
lut_fxp3_unrolled = lut_fxp3(:);
lut_fxp3_hex = hex(lut_fxp3_unrolled);

addr_range = size(lut_fxp_hex, 1);
addresses = dec2hex(zeros(addr_range, 1),12);

iter = 1;
for n = 1:size(a1,2)
  for m = 1:size(a2,1)
    addresses(iter,1:6) = dec2bin(hex2dec(a1_fxp_hex(n,:)),6);
    addresses(iter,7:12) = dec2bin(hex2dec(a2_fxp_hex(m,:)),6);
    iter = iter + 1;
  end
end

concat_arr = generate_lut_matrix(a1_fxp, a2_fxp, lut_fxp);
% TODO2: create checker which will calculate this: 1/(concat_arr(n1,m1)+concat_arr(n2,m2))
%        and compare results with the contents of array

%% plot fxp values
figure;
subplot(1,2,1);
plot(lut_fxp_unrolled,"o");
title("lut values in Q(0.5.11)");

subplot(1,2,2);
plot(lut_fxp2_unrolled,"o");
title("lut values in Q(0.6.6)");