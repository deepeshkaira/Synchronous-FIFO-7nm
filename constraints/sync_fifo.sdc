# ASAP7 units: 1 ps for time and 1 fF for capacitance.
create_clock -name clk -period 10000.000 [get_ports clk]

set_clock_uncertainty 100.000 [get_clocks clk]
set_clock_transition 20.000 [get_clocks clk]

set_input_delay 1000.000 -clock [get_clocks clk] [get_ports {en_i wr_en_i rd_en_i folded_history_i[*]}]

set_output_delay 1000.000 -clock [get_clocks clk] [get_ports {read_data_o[*] fifo_full_o fifo_empty_o}]

set_input_transition 50.000 [get_ports {rst_n en_i wr_en_i rd_en_i folded_history_i[*]}]

# 5 fF assumed load on each output bit.
set_load 5.000 [all_outputs]

# Asynchronous reset is excluded from synchronous data timing.
set_false_path -from [get_ports rst_n]
