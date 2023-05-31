# @lang=tcl @ts=8

set script_path [file dirname [file normalize [info script]]]

read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/cf_math_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/rvfi_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/riscv_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/ariane_dm_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/ariane_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/cv64a6_imafdc_sv39_config_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/lzc.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/serdiv.sv}

elaborate -golden

compile -golden
