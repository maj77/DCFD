%% CFD calculations
clc; clear; close all;

amplitude = 200;
delay_samples = 65;
x = -4:0.01:4;

%val = [0 0 1 2 4 6 8 7 6 2 1 0 0];
val = gaussian_pulse(amplitude,0.3,x);
tmp = zeros(1, delay_samples);
val_delayed = [tmp, val];
val_extd = [val, tmp];
val_scaled = [val*0.8, tmp];
zero_cross_val =  val_delayed - val_scaled;

val_size = size(val_extd);
pulse = zeros(1,val_size(2));

for k = 2:val_size(2)
    if (zero_cross_val(k-1) < 0 && zero_cross_val(k) > 0)
        pulse(k:end) = amplitude;
        break;
    end
end

%% plots
zc_len = size(zero_cross_val);
time_extd = 1:1:zc_len(2);
hold on
plot(time_extd,val_extd,'c-*',time_extd,val_delayed,'b-o', ...
    time_extd,zero_cross_val,'g-o', time_extd, pulse, 'r-+', ...
    time_extd, val_scaled, 'g-+');
legend('original', 'original delayed', 'zero cross val', 'zero cross pulse')

%% create fxp represantation of input impulse
val_fxp = fi(val, 0, 32, 0);
val_fxp_hex = hex(val_fxp);

%% INTERPOLATION
zc_len = size(zero_cross_val);
time_extd = 1:1:zc_len(2);

t = 0.5;
zc_val_1 = zero_cross_val(1:865);
zc_val_2 = zero_cross_val(2:866);

lerp = zc_val_1 + t*(zc_val_2-zc_val_1);


interpolated = zeros(1,866+855);
for n=1:865
    interpolated(2*n-1) = zero_cross_val(n);
    interpolated(2*n)   = lerp(n);
end
interp_len = size(interpolated);
time2 = 1:1:interp_len(2);


%plot(time_extd(1:865), zero_cross_val(1:865), time_extd(1:865), lerp);
%legend('zero cross pulse', 'interpolation pulse');
plotyy(time2, interpolated,time_extd, zero_cross_val);