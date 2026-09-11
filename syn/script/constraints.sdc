create_clock -name hclk -period 10 [get_ports HCLK]
create_clock -name pclk -period 20 [get_ports PCLK]
create_clock -name sclk -period 40 [get_ports SCLK]

set_clock_uncertainty -setup 1 [get_clocks HCLK]
set_clock_uncertainty -setup 2 [get_clocks PCLK]
set_clock_uncertainty -setup 4 [get_clocks SCLK]

set_input_delay -clock clk1 -max 6 [all_inputs]
set_input_delay -clock clk2 -max 12 [all_inputs]
set_input_delay -clock clk3 -max 24 [all_inputs]

set_input_delay -clock clk -min 4 [all_inputs]
set_input_delay -clock clk -min 8 [all_inputs]
set_input_delay -clock clk -min 16 [all_inputs]

set_output_delay -clock clk -min 4 [all_outputs]
set_output_delay -clock clk -min 8 [all_outputs]
set_output_delay -clock clk -min 16 [all_outputs]

set_output_delay -clock clk -max 6 [all_outputs]
set_output_delay -clock clk -max 12 [all_outputs]
set_output_delay -clock clk -max 24 [all_outputs]

set_clock_groups -asynchronous -group [get_clocks HCLK] -group [get_clocks PCLK] -group [get_clocks SCLK]
