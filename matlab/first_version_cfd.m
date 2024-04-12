clc; close all; clear;

% initial params
f = 5;          % center freq
BW = 0.6;       % bandwidth
delay = 0.2;    
scale = 0.85;   % threshold, % of max signal value
amplitude = 1023;  % rescale amplitude of pulse
resolution = 1e-2;

% generate time domain
tc = gauspuls('cutoff',f,BW,[],-100); 
t = -tc : resolution : tc;            
t2 = -tc : resolution : (1+delay)*tc;

% generate signial which will be shifted
[~,~,ye] = gauspuls(t,f,BW);
ye = amplitude.*ye;

% create shifted and original pulses
t2_size = size(t2);
t_size = size(t);
shifted_pulse = [zeros(1,t2_size(2)-t_size(2)), ye];
[~,~,original_pulse] = gauspuls(t2,f,BW);  % regenerate original pulse on wider time domain
original_pulse = amplitude.*original_pulse;

% create scaled pulse
negative_pulse_scaled = -scale.*original_pulse;

% final pulse (zero crossing)
zero_cross_pulse = shifted_pulse + negative_pulse_scaled;

[~,pulse_len] = size(shifted_pulse);
zc_pulse = zeros(1,pulse_len);

for n = 1:pulse_len
    if (n>10)
        for i = 1:10
            zc_pulse(n-i) = zc_pulse(n-i) + shifted_pulse(n-i) + negative_pulse_scaled(n-i);
        end
    end
end

temp = size(original_pulse);
x = 1:1:temp(2);

hold on
plot(x,original_pulse,x,shifted_pulse,x,negative_pulse_scaled, ...
     x,zero_cross_pulse);
title('Zero cross impulse');
xlabel('Sample number');
ylabel('Voltage [mV]');
legend('Original pulse','Shifted pulse', 'Negative and scaled', 'Zero cross')
%plot(t2,shifted_pulse,t2,zero_corss_pulse);
%legend('Original pulse','Zero cross')

%plot(t2,zc_pulse)
