# @lang=tcl @ts=8

set script_path [file dirname [file normalize [info script]]]

read_vhdl -golden  -pragma_ignore {}  -version 2008 {$script_path/modmult.vhd}
read_vhdl -golden  -pragma_ignore {}  -version 2008 {$script_path/rsacypher.vhd}

set_elaborate_option -golden -vhdl_generic {keysize=4}

elaborate -golden

compile -golden

set_mode mv

read_sva -version {sv2012} {$script_path/rsacypher.sva}

check -verbose -all [get_checks]
