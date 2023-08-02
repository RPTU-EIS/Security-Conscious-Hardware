# @lang=tcl @ts=8

set script_path [file dirname [file normalize [info script]]]

read_vhdl -golden  -pragma_ignore {}  -version 2008 {$script_path/modmult_sc.vhd}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/modmult_sc_miter.sv}

set_elaborate_option -golden -verilog_parameter {mpwid=32}

elaborate -golden

compile -golden

set_mode mv

read_sva -version {sv2012} {$script_path/modmult_sc_upec_dit.sva}

check -verbose -all [get_checks]
