#!/bin/bash
# ==============================================================================
# File:     conky-colorize-cpu.sh
#
# Conky Conf Ex: ${alignr} ${execpi 6 /usr/bin/sensors | grep 0: | paste -s | cut -c16-19 | xargs ~/Scripts/colorize_CPU.sh}°C ${color}
#               Define the color2-4 in the conky.conf file als
#
# Ref: http://paulscomputernotes.blogspot.com/2012/08/color-coded-conky.html
# ==============================================================================
COOL=70
WARM=90

if [[ $1 -lt $COOL ]]; then
    echo "\${color2}"$1
elif [[ $1 -gt $WARM ]]; then
    echo "\${color4}"$1
else
    echo "\${color3}"$1
fi
exit 0
