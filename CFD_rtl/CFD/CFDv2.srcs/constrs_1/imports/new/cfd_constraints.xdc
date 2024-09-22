
create_clock -period 10.000 -name clk_1 -waveform {0.000 5.000} [get_ports clk]
# set_input_jitter clk_1 0.001
set_input_delay -clock [get_clocks clk_1] -min -add_delay 0.000 [get_ports {sample_in[*]}]
set_input_delay -clock [get_clocks clk_1] -max -add_delay 0.000 [get_ports {sample_in[*]}]
set_input_delay -clock [get_clocks clk_1] -min -add_delay 0.000 [get_ports {sf[*]}]
set_input_delay -clock [get_clocks clk_1] -max -add_delay 0.000 [get_ports {sf[*]}]
set_input_delay -clock [get_clocks clk_1] -min -add_delay 0.000 [get_ports rst_p]
set_input_delay -clock [get_clocks clk_1] -max -add_delay 0.000 [get_ports rst_p]
set_input_delay -clock [get_clocks clk_1] -min -add_delay 0.000 [get_ports th_passthrough_in]
set_input_delay -clock [get_clocks clk_1] -max -add_delay 0.000 [get_ports th_passthrough_in]
set_output_delay -clock [get_clocks clk_1] -min -add_delay 0.000 [get_ports {data_out[*]}]
set_output_delay -clock [get_clocks clk_1] -max -add_delay 0.000 [get_ports {data_out[*]}]
set_output_delay -clock [get_clocks clk_1] -min -add_delay 0.000 [get_ports pulse_out]
set_output_delay -clock [get_clocks clk_1] -max -add_delay 0.000 [get_ports pulse_out]
set_output_delay -clock [get_clocks clk_1] -min -add_delay 0.000 [get_ports th_passthrough_out_vld]
set_output_delay -clock [get_clocks clk_1] -max -add_delay 0.000 [get_ports th_passthrough_out_vld]

