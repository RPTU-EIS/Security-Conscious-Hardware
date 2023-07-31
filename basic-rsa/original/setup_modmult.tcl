# @lang=tcl @ts=8

read_vhdl -golden  -pragma_ignore {}  -version 2008 { /import/home/deutschmann/Security/Security-Conscious-Hardware/basic-rsa/original/modmult.vhd }

set_elaborate_option -golden -vhdl_generic {mpwid=4}

elaborate -golden

read_sva -version {sv2012} {/import/home/deutschmann/Security/Security-Conscious-Hardware/basic-rsa/original/modmult.sva}

check -verbose -all [get_checks]
