//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.10 
//Created Time: 2024-05-05 17:54:11
create_clock -name CLK -period 37 -waveform {0 18.5} [get_ports {CLK27}]
