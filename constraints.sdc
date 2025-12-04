# constraints.sdc

# 1. Target clock (500 MHz → 2.0 ns)
create_clock -name clk -period 2.0 [get_ports clk]

# 2. Jitter/skew modelling
set_clock_uncertainty 0.05 [get_clocks clk]

# 3. Input arrival times
set_input_delay 0.2 -clock clk [all_inputs]

# 4. Output required times
set_output_delay 0.2 -clock clk [all_outputs]

# 5. Asynchronous reset = not timed
set_false_path -from [get_ports rst_n]
