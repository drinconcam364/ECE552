read_liberty stdcells.lib
read_verilog FDPMAC_mapped.v
link_design FDPMAC
read_sdc constraints.sdc
report_checks -path_delay max -digits 4
report_wns
report_tns
