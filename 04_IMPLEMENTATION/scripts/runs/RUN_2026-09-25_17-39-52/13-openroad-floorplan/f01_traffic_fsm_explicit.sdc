###############################################################################
# Created by write_sdc
###############################################################################
current_design f01_traffic_fsm_explicit
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 10.0000 [get_ports {clk}]
set_input_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {ena}]
set_input_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {night_mode}]
set_input_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {rst_n}]
set_output_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {uo_out[0]}]
set_output_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {uo_out[1]}]
set_output_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {uo_out[2]}]
set_output_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {uo_out[3]}]
set_output_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {uo_out[4]}]
set_output_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {uo_out[5]}]
set_output_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {uo_out[6]}]
set_output_delay 1.0000 -clock [get_clocks {clk}] -add_delay [get_ports {uo_out[7]}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
