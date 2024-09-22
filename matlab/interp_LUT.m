%% interpolation LUT
%  script creates 16bit values of given expression: 1/(a)
%  where a is sum of a1 and a2 and used as memory adress.
%  For now format Q(0.6.6) is used for a1 and a2 and Q(0.7.6) for a,
%  which corresponds to input values in range [0.0156 : 63.9844] with step = 0.0156
%  Output format is Q(0.8.7)

%% clear workspace
clc; clear; close all;

%% Initialize a, where a=a1+a2
% Q(0.7.6) ->_ _ _ _ _ _ _ ._  _  _  _  _  _
%            6 5 4 3 2 1 0 -1 -2 -3 -4 -5 -6       
%             000000.000001 = 2^-6 -> 0.015625

a1i = 6;
a1f = 6;
a2i = a1i;
a2f = a1f;

ni     = max(a1i, a2i);  % no. of integer bits of a1 and a2
ni_sum = ni+1;           % a1+a2 sum integer bits
nf     = max(a1f, a2f);  % no. of fract bits common for a, a1, a2

range  = 2^(ni_sum); 
step   = 2^(-nf);

a      = step:step:range-step; % a1=0 and a2=0 should be handled in verilog!


%% calculate FXP formats for 1/(a)
%
%
%
numerator_sel = 1;
if numerator_sel
    an = 1; %numerator_integer CONST
    bn = a1f; %numerator_fract   CONST
else
    an = a1i; %numerator_integer CONST
    bn = a1f; %numerator_fract   CONST
end
ad = ni_sum; %denominator_integer 
bd = nf;     %denominator_fract

r_int   = an + bd;
r_fract = ceil(log2(pow2(ad+bn) - pow2(bn-bd)));
extd_fract = r_fract+2;

bitwidth = r_int + r_fract;
bitwidth_extd = r_int + extd_fract;
%% Calculate LUT(1/a) values
% a_fxp   = fi(a, 0, 12, 6); % Q (0.6.6)

lut_fxp          = fi(1./a, 0, r_int+r_fract, r_fract);
lut_fxp_ext_frac = fi(1./a, 0, r_int+extd_fract, extd_fract);
lut_flp          = 1./a;

lut_fxp_data = lut_fxp.data;
lut_diff     = lut_flp - lut_fxp_data;


lut_flp_slope           = lut_flp(2:end) - lut_flp(1:end-1); % probably same as diff(lut_flp);
lut_flp_slope_mag_order = floor(log10(abs(lut_flp_slope)));


%% plot lut flp-fxp diff
figure(5);
hold("on");
title_str = sprintf("lut(1/a) flp - fxp Q(0.%d.%d)", r_int, r_fract);
title(title_str);
stairs(a, lut_diff, "x","LineWidth", 1);
legend("diff=FLP-FXP (double prec.)");
xlabel_str = sprintf("adres w formacie Q(0.%d.%d)", ni_sum, nf);
xlabel(xlabel_str);
ylabel("wartość różnicy w double prec");

%% plot lut fxp-fxp_extd diff
lut_extd_diff = lut_fxp_data - lut_fxp_ext_frac.data;

figure(6);
hold("on");
title_str = sprintf("lut(1/a) fxp Q(0.%d.%d) - fxp Q(0.%d.%d)", r_int, r_fract, r_int, extd_fract);
title(title_str);
stairs(a, lut_extd_diff, "x","LineWidth", 1);
legend("diff=FXP-FXP_{extd}");
xlabel_str = sprintf("adres w formacie Q(0.%d.%d)", ni_sum, nf);
xlabel(xlabel_str);
ylabel("wartość różnicy w double prec");

%% plot lut flp-fxp_extd diff
lut_extd_vs_flp_diff = lut_flp - lut_fxp_ext_frac.data; 

figure(7);
hold("on");
title_str = sprintf("lut(1/a) flp - fxp Q(0.%d.%d)", r_int, extd_fract);
title(title_str);
stairs(a, lut_extd_vs_flp_diff, "x","LineWidth", 1);
legend("diff=FLP-FXP_{extd}");
xlabel_str = sprintf("adres w formacie Q(0.%d.%d)", ni_sum, nf);
xlabel(xlabel_str);
ylabel("wartość różnicy double prec");

%% plot lut_slope
figure(1);
hold("on");
title("Pochodna LUT FLP");
stairs(lut_flp_slope(1:end), "o", "LineWidth", 1);
xlabel("Numer elementu wektora");
ylabel("Różnica");

%% plot magnitude orders of lut_slope
figure(2);
hold("on");
title("Rząd wielkości pochodnej LUT FLP");
stairs(lut_flp_slope_mag_order, "o", "LineWidth", 1);
xlabel("Numer elementu wektora");
ylabel("Wartość rzędu wielkości");

%% plot a1
figure(3);
hold("on");
title("stairs(a)");
stairs(a, "LineWidth", 1);
legend("a");
xlabel("Numer elementu wektora");
ylabel_str = sprintf("Wartość wektora w Q(0.%d.%d)", ni_sum, nf);
ylabel(ylabel_str);

%% plot lut fxp vs lut flp
figure(4);
hold("on");
title("lut(1/a) fxp vs flp");
stairs(a, lut_flp, "o", "LineWidth", 1);
stairs(a, lut_fxp, "x","LineWidth", 1);
legend_str1 = "FLP LUT (double prec.)";
legend_str2 = sprintf("FXP LUT Q(0.%d.%d)", r_int, r_fract);
legend(legend_str1, legend_str2);
xlabel_str = sprintf("adres w formacie Q(0.%d.%d)", ni_sum, nf);
xlabel(xlabel_str);
ylabel("Wartości LUT");


%% plot a1 vs lut

figure(1);
hold("on")
stairs(a1);
stairs(lut);
legend("a [flp]", "lut data [flp]");

%%
a_fxp     = fi(a, 0, ni_sum+nf, nf);
addresses = a_fxp.bin;
lut_vals  = lut_fxp;


addr_file_str = sprintf("generated_data/LUT_ADDR_NEW_Q_0_%d_%d.txt", ni_sum, nf);
addr_file = fopen(addr_file_str, "w");
fprintf(addr_file, '%c', addresses);
fclose(addr_file);

val_file_str = sprintf("generated_data/LUT_VALS_NEW_Q_0_%d_%d.txt", r_int, r_fract);
val_file = fopen(val_file_str, "w");
fprintf(val_file, '%c', lut_vals.hex);
fclose(val_file);

%%
figure(1);
hold("on");
plot(lut_vals);
plot(1./a1);
stairs(lut_vals.data-(1./a1));
legend("lut data", "1/a", "diff");