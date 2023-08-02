# @lang=tcl @ts=8

set script_path [file dirname [file normalize [info script]]]

read_vhdl -golden  -pragma_ignore {}  -version 2008 {$script_path/modmult_sc.vhd}

set_elaborate_option -golden -vhdl_generic {mpwid=4}

elaborate -golden

compile -golden

set_mode mv

read_sva -version {sv2012} {$script_path/modmult_sc.sva}

check -verbose -all [get_checks]
