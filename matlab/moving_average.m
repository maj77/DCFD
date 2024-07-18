function [wave_avg] = moving_average(wave_in, n_samples_avg)
%MOVING_AVERAGE calculates moving average from wave_in
%   n_samples_avg - number of samples from which average value is taken

signal_len = size(wave_in,2);
wave_temp = zeros(1, signal_len);

for n=1:1:signal_len-n_samples_avg
    wave_temp(n) = fi(sum(wave_in(1,[n:n+n_samples_avg])), 1, 24, 12);
    wave_temp(n) = fi(wave_temp(n)/n_samples_avg, 1, 24, 12);
end

wave_avg = wave_temp;
end

