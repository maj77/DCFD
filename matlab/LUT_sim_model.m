function [address, out_val] = LUT_sim_model(sample_in1, sample_in2, ...
                                   sample_in_width, sample_in_fract, ...
                                   out_width, out_fract)
%LUT_SIM_MODEL Summary of this function goes here
%   Detailed explanation goes here

%% init
ni = sample_in_width-sample_in_fract; % no. of integer bits of a1 and a2
nf = sample_in_fract;                 % no. of fract bits 
range = 2^(ni-1);
a1 = 2^(-nf):2^(-nf):2*range;
a2 = a1;

%% create LUT adresses
a1_fxp = fi(a1, 0, sample_in_width, sample_in_fract)';
a2_fxp = fi(a2, 0, sample_in_width, sample_in_fract)';

a1_bin = bin(a1_fxp);
size(a1_fxp)
size(a1_bin)
a2_bin = bin(a2_fxp);
addr_range = size(a2_bin, 1);
addresses = dec2bin(zeros(addr_range, 1),2*sample_in_width);

iter = 1;
for n = 1:size(a1,2)
  for m = 1:size(a2,1)
    addresses(iter,1:sample_in_width) = bin(a1_fxp(n,:));
    addresses(iter,sample_in_width+1:2*sample_in_width) = bin(a2_fxp(m,:));
    iter = iter + 1;
  end
end


%% convert input data to fixed point adresses
samp1 = fi(sample_in1, 0, sample_in_width, sample_in_fract);
samp2 = fi(sample_in2, 0, sample_in_width, sample_in_fract);


% concat addresses
address = strcat(bin(samp1),bin(samp2));
out_val = fi(1./(abs(sample_in1)+abs(sample_in2)), 0, out_width, out_fract);
end

