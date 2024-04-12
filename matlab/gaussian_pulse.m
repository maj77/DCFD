function [pulse_fp, pulse_fxp] = gaussian_pulse(amplitude, width_coeff, x, ...
                                                width, frac)
%GAUSSIAN_PULSE calculate gaussian impulse of given amplitude
%   x           - time domain samples
%   amplitude   - amplitude of pulse
%   width_coeff - width coefficient (should be positive value), 
%                 pulse gets wider when coefficient gets smaller

pulse_fp = amplitude.*exp(-width_coeff.*x.^2);
pulse_fxp = fi(pulse_fp, 0, width, frac);

end

