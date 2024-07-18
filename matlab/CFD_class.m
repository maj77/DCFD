classdef CFD_class
    %CFD_CLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % system properties
        T;
        T_width;
        lut_in_width;
        lut_in_fract;
        lut_out_width;
        lut_out_fract;
        samp_in_width; %zc module 
        samp_in_fract; %zc module
        out_int;
        out_fract;
        out_width;
        DELAY; % delay in samples
        SCALE;
        % --- waves ---
        original_wave;
        delayed_wave;
        scaled_wave;
        subtracted_wave;
        averaged_wave;
    end
    
    methods
        function obj = CFD_class(T, lut_in_width, lut_in_fract, ...
                                 lut_out_width,lut_out_fract, ...
                                 samp_in_width, samp_in_fract, ...
                                 out_int, out_fract, ...
                                 delay, scale)
            %CFD_CLASS Construct an instance of this class
            %   Initialize system parameters
            obj.T = T;
            obj.T_width = ceil(log2(T))+1;
            obj.lut_in_width = lut_in_width;
            obj.lut_in_fract = lut_in_fract;
            obj.lut_out_width = lut_out_width;
            obj.lut_out_fract = lut_out_fract;
            obj.samp_in_width = samp_in_width;
            obj.samp_in_fract = samp_in_fract;
            obj.out_int = out_int;
            obj.out_fract = out_fract;
            obj.out_width = out_int+out_fract;
            obj.DELAY = delay;
            obj.SCALE = scale;
        end
        
        function obj = set.original_wave(obj, wave)
            obj.original_wave = wave;
        end
        
        function obj = delay_wave(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.delayed_wave = [zeros(1,obj.DELAY), obj.original_wave];
        end

        function obj = scale_wave(obj)
            obj.scaled_wave = obj.original_wave*obj.SCALE;
        end

        function obj = subtract_wave(obj)
            obj.subtracted_wave = obj.delayed_wave-obj.scaled_wave;
        end

        function obj = average_wave(obj, n_samp_avg)
            wave_len = size(obj.subtracted_wave,2);
            wave_temp = zeros(1, wave_len);
            for n=1:1:wave_len-n_samp_avg
                wave_temp(n) = fi(sum(obj.subtracted_wave(1,[n:n+n_samp_avg])), 1, mavg_width, mavg_fract);
                wave_temp(n) = fi(wave_temp(n)/n_samp_avg, 1, mavg_width, mavg_fract);
            end
            obj.averaged_wave = wave_temp;
        end
s
        function val = get.original_wave(obj)
            val = obj.original_wave;
        end
        
        function val = get.delayed_wave(obj)
            val = obj.delay_wave;
        end
        
        function val = get.scaled_wave(obj)
            val = obj.scale_wave;
        end
        
        function val = get.subtracted_wave(obj)
            val = obj.subtracted_wave;
        end
    end
end

