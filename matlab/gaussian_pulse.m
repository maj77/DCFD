function [pulse] = gaussian_pulse(amplitude, width_coeff, x)
%GAUSSIAN_PULSE calculate gaussian impulse of given amplitude
%   x - domain
%   amplitude - amplitude
%   width_coeff - width coefficient (should be positive value)

pulse = amplitude.*exp(-width_coeff.*x.^2);
end

