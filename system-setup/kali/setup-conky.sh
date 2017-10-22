#!/usr/bin/env bash
## =======================================================================================
# File:     setup-conky.sh
#
# Author:   Cashiuus
# Created:  27-Jan-2016          Revised:    23-Aug-2017
#
#-[ Usage ]-------------------------------------------------------------------------------
# Purpose:  Setup conky monitor dashboard on desktop with pre-configured style
#
#-[ Notes/Links ]-------------------------------------------------------------------------
#   Source Code of Conky Variables: https://github.com/brndnmtthws/conky/blob/master/doc/variables.xml
#   Ref: http://forums.opensuse.org/english/get-technical-help-here/how-faq-forums/unreviewed-how-faq/464737-easy-configuring-conky-conkyconf.html
#
#   Conky Colors:   https://en.wikipedia.org/wiki/X11_color_names
#                   http://www.graphviz.org/doc/info/colors.html
## =======================================================================================
__version__="1.4"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
PURPLE="\033[01;35m"    # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## =========[ CONSTANTS ]================ ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_ARGS=$@
DEBUG=false
LOG_FILE="${APP_BASE}/debug.log"

USE_OLD_CONKY=0
OLD_CONKY_CONF="${HOME}/.conkyrc"
NEW_CONKY_CONF="${HOME}/.config/conky/conky.conf"

LSB_RELEASE=$(lsb_release -cs)
CONKY_VERSION=$(dpkg-query -f '${Version}' -W conky)

#======[ ROOT PRE-CHECK ]=======#
function check_root() {
    if [[ $EUID -ne 0 ]];then
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            # $SUDO - run commands with this prefix now to account for either scenario.
        else
            echo -e "${RED}[ERROR] Please install sudo or run this as root. Exiting.${RESET}"
            exit 1
        fi
    fi
}
check_root

# =============================[ Install & Setup ]================================ #


if [[ ${LSB_RELEASE} == 'jessie' ]]; then
  file=/etc/apt/sources.list.d/backports.list
  if [[ ! -e "${file}" ]]; then
    $SUDO sh -c "echo ### Debian Jessie Backports > ${file}"
    $SUDO sh -c "echo deb http://httpredir.debian.org/debian jessie-backports main contrib non-free >> ${file}"
  fi
  # This is how you can see a list of all installed backports:
  #   dpkg-query -W | grep ~bpo
  # View list of all potential packages:
  #   apt-cache policy <pkg>
  
  export DEBIAN_FRONTEND=noninteractive
  echo -e "${GREEN}[*]${RESET} Checking for and removing pre-existing conky installs..."
  $SUDO apt-get -y remove --purge conky conky-std
  echo -e "${GREEN}[*]${RESET} Installing latest Conky pkg using backports repo..."
  $SUDO apt-get -y -t jessie-backports install conky
fi


# ----- XFCE Installs - Enable Compositing -------
if [[ ${GDMSESSION} == 'lightdm-xsession' ]]; then
    # NOTE: Another env var that could be used is: XDG_CURRENT_DESKTOP=XFCE
  echo -e "${YELLOW}[INFO]${RESET} ${GDMSESSION} detected, skipping GNOME tweaks..."
  # NOTE: Don't need sudo for these commands, actually didn't seem to fix 
  #       conky when I used sudo, but conky went transparent after running
  #       these as user without sudo.
  xfconf-query -n -c xfwm4 -p /general/use_compositing -t bool -s true
  xfconf-query -n -c xfwm4 -p /general/frame_opacity -t int -s 85
fi


# -----------------------------------
# NOTE: Debian 8 "jessie" still uses conky 1.9, unless you enable unstable "sid" distro instead.
# Conky < 1.9 uses old config style we are used to using
# Conky >= 1.10 uses new Lua-based configuration style


# TODO: Determine currently-installed Conky version rather than guessing
if [[ ${USE_OLD_CONKY} -eq 1 ]]; then
  # If we've set this variable to 1, we want old conky.
  echo -e "${GREEN}[*]${RESET} Performing setup of OLD version Conky..."
  if [[ ! -e "${OLD_CONKY_CONF}" ]]; then
    cat <<EOF > "${OLD_CONKY_CONF}"
background yes
gap_x 5
gap_y 30

# -----[ Window Size & Position ]----- #
alignment bottom_right

border_width 1
draw_borders no
draw_outline no
draw_graph_borders yes
draw_shades yes

uppercase no

use_xft yes
xftalpha 0.9
xftfont DejaVu Sans Mono:size=8
override_utf8_locale no

default_color white

own_window yes
own_window_type normal
own_window_transparent no
own_window_colour black
own_window_argb_visual yes
own_window_argb_value 50
own_window_hints undecorated,below,sticky,skip_taskbar,skip_pager

double_buffer yes
no_buffers yes

out_to_console no
out_to_stderr no
extra_newline no

use_spacer none
show_graph_scale no
show_graph_range no

# --[ PROCESS CONFIGURATIONS ]-- #
update_interval 2.0
total_run_times 0
cpu_avg_samples 2
net_avg_samples 2

# --[ TEXT LAYOUT ]-- #
TEXT
\${color green}SYSTEM: \$nodename (\$machine)\${hr 1}\${color}
Uptime: \$alignr\$uptime
CPU: \${alignr}\${freq_g} GHz
Processes: \${alignr}\$processes (\$running_processes running)
Load: \${alignr}\$loadavg
\${cpugraph 20}
Ram \${alignr}\$mem / \$memmax (\$memperc%)
\${membar 4}
Swap \${alignr}\$swap / \$swapmax (\$swapperc%)
\${swapbar 4}
Highest CPU \${alignr} CPU% MEM%
\${top name 1}\$alignr\${top cpu 1}\${top mem 1}

Highest MEM \${alignr} CPU% MEM%
\${top_mem name 1}\${alignr}\${top_mem cpu 1}\${top_mem mem 1}

\${color green}FILESYSTEMS\${hr 1}\${color}
Root \${alignc}\${fs_used /} / \${fs_size /}\${alignr}\${fs_used_perc /}%
\${fs_bar 4 /}

\${color yellow}NETWORK \${hr 1}\${color}
\${if_up eth0}\${color white}LAN: eth0 (\${addr eth0})
Down\${color}: \${downspeed eth0}KB/s \${color white}Up\${color}: \${upspeed eth0}KB/s
\${downspeedgraph eth0 10,80 99cc33 006600} \${alignr}\${upspeedgraph eth0 10,80 ffcc00 ff0000}
\${endif}

\${color green}CUSTOM ALIASES \${hr 1}\${color}
bashload \${alignr}update-kali
myip \${alignr}timer
open <file> \${alignr}openports
workon <project> \${alignr}webserv
EOF
  fi
else
  filedir="${HOME}/.config/conky"
  [[ ! -d "${filedir}" ]] && mkdir -p "${filedir}"
  cat <<EOF > "${NEW_CONKY_CONF}"
conky.config = {
    -- References: 
    --    https://wiki.archlinux.org/index.php/conky
    --    https://github.com/brndnmtthws/conky/wiki/Configuration-Settings
    gap_x = 12,
    gap_y = 35,
    alignment = 'bottom_right',
    minimum_width = 200,
    maximum_width = 250,

    font = 'monospace:size=8',
    default_color = 'white',
    use_xft = true,
    xftalpha = 0.9,
    override_utf8_locale = false,

    border_width = 1,
    draw_borders = false,
    draw_outline = false,
    draw_graph_borders = true,
    draw_shades = true,

    background = false,
    double_buffer = true,

    own_window = true,
    own_window_argb_value = 50,
    own_window_argb_visual = true,
    own_window_class = 'conky-semi',
    own_window_colour = 'black',
    own_window_type = 'normal',
    own_window_transparent = false,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',

    out_to_console = false,
    out_to_stderr = false,
    extra_newline = false,
    uppercase = false,
    use_spacer = 'right',
    show_graph_scale = false,
    show_graph_range = false,

    update_interval = 2.0,
    total_run_times = 0,
    cpu_avg_samples = 2,
    net_avg_samples = 2,

    color1 = 'B9EAFA',
};

conky.text = [[
\${color green}SYSTEM: \$nodename (\$machine)\${hr 1}\${color}
\${color1}Uptime: \${color}\${alignr}\$uptime
\${color1}CPU:\${color} \${freq_g} GHz \${alignr}\${color1}Load: \${color}\${loadavg}
\${color1}Processes:\${color} \$processes (\$running_processes running)
\${cpugraph 20,240 000000 white}
\${color1}Ram \${alignr}\$mem / \$memmax (\$memperc%)\${color}
\${membar 4}
\${color1}Swap \${alignr}\$swap / \$swapmax (\$swapperc%)\${color}
\${swapbar 4}
\${color green}PROCESSES\${hr 1}\${color}
\${color1}Highest CPU       PID     CPU%    MEM%\${color}
\${top name 1} \${top pid 1}  \${top cpu 1}  \${top mem 1}
\${top name 2} \${top pid 2}  \${top cpu 2}  \${top mem 2}
\${top name 3} \${top pid 3}  \${top cpu 3}  \${top mem 3}

\${color1}Highest MEM       PID     CPU%    MEM%\${color}
\${top_mem name 1} \${top_mem pid 1}  \${top_mem cpu 1}  \${top_mem mem 1}
\${top_mem name 2} \${top_mem pid 2}  \${top_mem cpu 2}  \${top_mem mem 2}
\${top_mem name 3} \${top_mem pid 3}  \${top_mem cpu 3}  \${top_mem mem 3}

\${color green}FILESYSTEMS\${hr 1}\${color}
Root \${alignc}\${fs_used /} / \${fs_size /}\${alignr}\${fs_used_perc /}%
\${fs_bar 4 /}

\${color green}NETWORK \${hr 1}\${color}
\${if_up eth0}\${color white}LAN: eth0 (\${addr eth0})
\${downspeedgraph eth0 10,80 99cc33 006600} \${alignr}\${upspeedgraph eth0 10,80 ffcc00 ff0000}
Down\${color}: \${downspeed eth0}KB/s \${alignr}\${color white}Up\${color}: \${upspeed eth0}KB/s
\${endif}\${if_up wlan0}\${color white}LAN: wlan0 (\${addr wlan0})
\${downspeedgraph wlan0 10,80 99cc33 006600} \${alignr}\${upspeedgraph wlan0 10,80 ffcc00 ff0000}
Down\${color}: \${downspeed wlan0}KB/s \${alignr}\${color white}Up\${color}: \${upspeed wlan0}KB/s
\${endif}
\${color1}Inbound \${alignr}Local Service/Port\${color}
\$color \${tcp_portmon 1 32767 rhost 0} \${alignr}\${tcp_portmon 1 32767 lservice 0}
\$color \${tcp_portmon 1 32767 rhost 1} \${alignr}\${tcp_portmon 1 32767 lservice 1}
\$color \${tcp_portmon 1 32767 rhost 2} \${alignr}\${tcp_portmon 1 32767 lservice 2}
\${color1}Outbound \${alignr}Remote Service/Port\${color}
\$color \${tcp_portmon 32768 61000 rhost 0} \${alignr}\${tcp_portmon 32768 61000 rservice 0}
\$color \${tcp_portmon 32768 61000 rhost 1} \${alignr}\${tcp_portmon 32768 61000 rservice 1}
\$color \${tcp_portmon 32768 61000 rhost 2} \${alignr}\${tcp_portmon 32768 61000 rservice 2}
\${color green}CUSTOM ALIASES \${hr 1}\${color}
bashload \${alignr}update-kali
myip \${alignr}timer
open <file> \${alignr}openports
workon <project> \${alignr}webserv
]]
EOF

fi


# =============================[ Custom Launcher Scripts ]================================ #

echo -e "${GREEN}[*] ${RESET}Adding conky-start script"
file="/usr/local/bin/conky-start"
[[ ! -d "/usr/local/bin" ]] && $SUDO mkdir -p "/usr/local/bin"
# Create file and make it readable so we can build it
$SUDO touch "${file}"
$SUDO chmod -f 0666 "${file}"
cat <<EOF > "${file}"
#!/bin/bash

$(which timeout) 10 $(which killall) -9 -q -w conky
$(which sleep) 10s
$(which conky) &
EOF
# Now make file launchable
#$SUDO chmod -f 0500 "${file}"
$SUDO chmod -f 0555 "${file}"

echo -e "${GREEN}[*]${RESET} Adding conky autostart file"
mkdir -p "${HOME}/.config/autostart"
file="${HOME}/.config/autostart/conkyscript.desktop"
cat <<EOF > "${file}"
[Desktop Entry]
Encoding=UTF-8
Name=conky
Type=Application
Exec=/usr/local/bin/conky-start
#Exec=conky -p 10 -d
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=false
Hidden=false
Comment=
EOF


# Launch it now
bash /usr/local/bin/conky-start >/dev/null 2>&1 &
echo -e "${GREEN}[*]${RESET} Conky install complete!"

# An easy way to force reload your conky config:
#$SUDO killall -SIGUSR1 conky



# =========[ Keyboard Shortcut (Alt+F2) to 'conky-refresh' ]======= #
#file="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
#if [[ -e "${file}" ]]; then
    #grep -q '<property name="&lt;Primary&gt;r" type="string" value="/usr/local/bin/conky-start"/>' "${file}" || sed -i 's#<property name=\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n        <property name="\&lt;Primary\&gt;r" type="string" value="/usr/local/bin/conky-refresh"/>#' "${file}"
#fi

# ===========================[ Conky with GNU Screen ]=============================== #
### TODO: Conky 1.10 and later uses Lua-based configurations
### TODO: It is possible to create a configuration to show basic specs at the bottom of a screen console session
# Info: https://github.com/brndnmtthws/conky/wiki/ConkyAndGnuScreen

#$SUDO apt-get -y install screen

# Check if conky was compiled with X11 support by parsing output of this command
#conky -v | grep "X11"



# ============================ [  NOTES  ] ================================= #
#
# Default config file path: $HOME/.conkyrc
# System config file: /etc/conky/conky.conf
# Package library path: /usr/lib/conky
#
# Color options: /usr/share/X11/rgb.txt and can also be in #RRGGBB format (hex).
#
#
#
#
# -===[ Version 1.10+ Lua Syntax ]===-
#
#   -- Comments start with a double dash in the conf file
#
#
#
#
#Usage: conky [OPTION]...
#conky is a system monitor that renders text on desktop or to own transparent
#window. Command line options will override configurations defined in config
#file.
#   -v, --version             version
#   -q, --quiet               quiet mode
#   -D, --debug               increase debugging output, ie. -DD for more debugging
#   -c, --config=FILE         config file to load
#   -C, --print-config        print the builtin default config to stdout
#                             e.g. 'conky -C > ~/.conkyrc' will create a new default config
#   -d, --daemonize           daemonize, fork to background
#   -h, --help                help
#   -a, --alignment=ALIGNMENT text alignment on screen, {top,bottom,middle}_{left,right,middle}
#   -f, --font=FONT           font to use
#   -X, --display=DISPLAY     X11 display to use
#   -o, --own-window          create own window to draw
#   -b, --double-buffer       double buffer (prevents flickering)
#   -w, --window-id=WIN_ID    window id to draw
#   -x X                      x position
#   -y Y                      y position
#   -t, --text=TEXT           text to render, remember single quotes, like -t '$uptime'
#   -u, --interval=SECS       update interval
#   -i COUNT                  number of times to update conky (and quit)
#   -p, --pause=SECS          pause for SECS seconds at startup before doing anything
