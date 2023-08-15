%% interpolation LUT
%  script creates 16bit values of given expression: 1/(a1+a2)
%  a1 and a2 are concatenated and used as memory adress.
%  For now format Q(1.2.3) is used for a1 and a2 which corresponds
%  to input values in range [-4.000 : 3.875]

%% clear workspace
clc; clear; close all;

%% init
ni = 3; % no. of integer bits of a1 and a2
nf = 3; % no. of fract bits 
range = 2^(ni-1);
a1 = -range:2^(-nf):range-2^(-nf);
a2 = a1';

%% LUT fxp
a1_fxp = fi(a1, 1, 6, 3);
a2_fxp = a1_fxp';
a1_fxp_hex = hex(a1_fxp');
a2_fxp_hex = hex(a2_fxp);
lut_fxp = fi(1./(a1+a2), 1 , 16, 11);
lut_fxp_unrolled = lut_fxp(:);
lut_fxp_hex = hex(lut_fxp_unrolled);

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
