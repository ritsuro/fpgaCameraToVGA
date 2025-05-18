# clock
create_clock -name clock_in_50mhz -period 20.000 [get_ports {CLOCK_50}]
create_clock -name CLOCK_VGA -period 20.000
derive_clock_uncertainty
# I/O
set_input_delay -clock { clock_in_50mhz } -max 4 [get_ports {RST_N}]
set_input_delay -clock { clock_in_50mhz } -min 1 [get_ports {RST_N}]

set_input_delay -clock { clock_in_50mhz } -max 4 [get_ports {BUTTON01}]
set_input_delay -clock { clock_in_50mhz } -min 1 [get_ports {BUTTON01}]

set_output_delay -clock { clock_in_50mhz } -max 4 [get_ports {LED[*]}]
set_output_delay -clock { clock_in_50mhz } -min 1 [get_ports {LED[*]}]

set_output_delay -clock { clock_in_50mhz } -max 4 [get_ports {CAMERA_XCLK CAMERA_SIO_C CAMERA_SIO_D}]
set_output_delay -clock { clock_in_50mhz } -min 1 [get_ports {CAMERA_XCLK CAMERA_SIO_C CAMERA_SIO_D}]

set_input_delay -clock { clock_in_50mhz } -max 4 [get_ports {CAMERA_SIO_D}]
set_input_delay -clock { clock_in_50mhz } -min 1 [get_ports {CAMERA_SIO_D}]

set_input_delay -clock { clock_in_50mhz } -max 4 [get_ports {CAMERA_PCLK CAMERA_V_SYNC CAMERA_HREF}]
set_input_delay -clock { clock_in_50mhz } -min 1 [get_ports {CAMERA_PCLK CAMERA_V_SYNC CAMERA_HREF}]

set_input_delay -clock { clock_in_50mhz } -max 4 [get_ports {CAMERA_D[*]}]
set_input_delay -clock { clock_in_50mhz } -min 1 [get_ports {CAMERA_D[*]}]

set_output_delay -clock { CLOCK_VGA } -max 4 [get_ports {VGA_R[*] VGA_G[*] VGA_B[*] VGA_H_SYNC VGA_V_SYNC}]
set_output_delay -clock { CLOCK_VGA } -min 1 [get_ports {VGA_R[*] VGA_G[*] VGA_B[*] VGA_H_SYNC VGA_V_SYNC}]
