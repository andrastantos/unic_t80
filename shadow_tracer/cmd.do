#create_project -name TTT -pn GW1NR-LV9QN88C6/I5 -device_version C
#set_device GW1NR-LV9QN88C6/I5 -device_version C
set_device -h
set_device GW1NR-LV9QN88C6/I5 -name GW1NR-9C

add_file ../T80.vhd
add_file ../T80_ALU.vhd
add_file ../T80_MCode.vhd
add_file ../T80_Pack.vhd
add_file ../T80_Reg.vhd
add_file ../T80a.vhd
add_file shadow_tracer.sv
add_file shadow_tracer.cst
add_file shadow_tracer.sdc
add_file shadow_tracer.rao

set_option -verilog_std sysv2017
set_option -gen_text_timing_rpt 1
set_option -use_sspi_as_gpio 1
set_option -use_mspi_as_gpio 1

set_option -top_module shadow_tracer_top

set_option -output_base_name unic_t80
set_option -print_all_synthesis_warning 1

set_option -gen_text_timing_rpt 1
set_option -gen_verilog_sim_netlist 1
set_option -show_all_warn 1
set_option -rpt_auto_place_io_info 1

run all
