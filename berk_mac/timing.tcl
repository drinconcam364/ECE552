read_liberty stdcells.lib
read_verilog Berk_MAC_wrapper_mapped.v
link_design Berk_MAC_wrapper
read_sdc constraints.sdc
report_checks -path_delay max -digits 4
report_wns
report_tns
