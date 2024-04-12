function [wave,t,wave2,t2] = generate_wave(start, stop)
        

f_adc = 10000;   % 10 KHz
T_adc = 1/f_adc; % 0.1 ms

t = -0.01+start:T_adc:0.01+stop;
t2 = t(2:10:end);

wave = sin(t);
wave2 = wave(2:10:end);

% figure(1)
% plot(t,wave)
% xlabel("czas [ms]");
% ylabel("amplituda");
% wave = amplitude*sin(domain);
end