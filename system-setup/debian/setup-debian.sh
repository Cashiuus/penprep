#!/usr/bin/env bash
## =======================================================================================
# File:     setup-debian.sh
# Author:   Cashiuus
# Created:  15-Jan-2016         Revised:  10-May-2017
#
#-[ Info ]-------------------------------------------------------------------------------
#- Purpose:  Setup a fresh Debian 8 server, typically within a Virtual Machine.
#
#
#- Notes:
#     1.  Below, set the constant "INSTALL_USER" to your primary account you are using
#         If you don't, it'll default to 'user1'
#
#
#-[ Links/Credit ]------------------------------------------------------------------------
#   - http://www.debiantutorials.com/
#   - Help: http://www.pontikis.net/blog/debian-wheezy-web-server-setup
#   - Tutorial: https://www.digitalocean.com/community/tutorials/initial-server-setup-with-debian-8
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="1.2"
__author__="Cashiuus"

## ============[ CONSTANTS ]================ ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"

## ============[ CONSTANTS ]================ ##

LSB_RELEASE=$(lsb_release -cs)

## =========================[ START :: LOAD FILES ]========================= ##
if [[ -s "${APP_BASE}/../common.sh" ]]; then
  source "${APP_BASE}/../common.sh"
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source files :: success${RESET}"
else
  echo -e "${RED} [ERROR]${RESET} common.sh functions file is missing."
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source files :: fail${RESET}"
  exit 1
fi
## ==========================[ END :: LOAD FILES ]========================== ##

# Check root/sudo rights and fix it before continuing
check_root

echo -e "${GREEN}[*]${RESET} Debian Release: ${ORANGE}$(lsb_release -cs)${RESET}"
# Try update first, because much of the script is useless without networking.
$SUDO apt-get -qq update
if [[ "$?" -ne 0 ]]; then
  echo -e "${RED} [ERROR]${RESET} Network issues preventing apt-get. Check and try again."
  exit 1
fi
## ========================================================================== ##
function pause() {
  # Simple function to pause a script mid-stride
  #
  local dummy
  read -s -r -p "Press any key to continue..." -n 1 dummy
  echo -e ""
}

# ================================[  BEGIN  ]================================ #
# -==  Setup VM Tools  ==- #
# https://github.com/vmware/open-vm-tools
if [[ ! $(which vmware-toolbox-cmd) ]]; then
  echo -e "${YELLOW}[-] Now installing vm-tools. This will require a reboot. Re-run script after...${RESET}"
  sleep 4
  $SUDO apt-get -y install open-vm-tools-desktop fuse
  $SUDO reboot
fi

# Increase idle delay which locks the screen (default is 300s)
$SUDO gsettings set org.gnome.desktop.session idle-delay 0

# -==   APT   ==- #
# https://wiki.debian.org/SourcesList
# Only modify the sources.list if we are on a 'jessie' system, else stick with defaults
if [[ ${LSB_RELEASE} == 'jessie' ]]; then
  echo -e "\n${GREEN}[*]${RESET} Setting sources.list to standard entries"
  if [[ $SUDO ]]; then
    echo "# Debian 8 Jessie" | $SUDO tee /etc/apt/sources.list
    echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
    echo "deb-src http://httpredir.debian.org/debian jessie main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

    echo "deb http://httpredir.debian.org/debian jessie-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
    echo "deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

    echo "deb http://security.debian.org/ jessie/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
    echo "deb-src http://security.debian.org/ jessie/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  else
    echo "# Debian 8 Jessie" > /etc/apt/sources.list
    echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list
    echo "deb-src http://httpredir.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list

    echo "deb http://httpredir.debian.org/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list
    echo "deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list

    echo "deb http://security.debian.org/ jessie/updates main contrib non-free" >> /etc/apt/sources.list
    echo "deb-src http://security.debian.org/ jessie/updates main contrib non-free" >> /etc/apt/sources.list
  fi
elif [[ ${LSB_RELEASE} == 'stretch' ]]; then
  echo -e "\n${GREEN}[*]${RESET} Setting sources.list to standard entries"
  if [[ $SUDO ]]; then
    echo "# Debian 9 Stretch" | $SUDO tee /etc/apt/sources.list
    echo "deb http://httpredir.debian.org/debian stretch main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
    echo "deb-src http://httpredir.debian.org/debian stretch main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

    echo "deb http://httpredir.debian.org/debian stretch-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
    echo "deb-src http://httpredir.debian.org/debian stretch-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

    echo "deb http://security.debian.org/ stretch/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
    echo "deb-src http://security.debian.org/ stretch/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  else
    echo "# Debian 9 Stretch" > /etc/apt/sources.list
    echo "deb http://httpredir.debian.org/debian stretch main contrib non-free" >> /etc/apt/sources.list
    echo "deb-src http://httpredir.debian.org/debian stretch main contrib non-free" >> /etc/apt/sources.list

    echo "deb http://httpredir.debian.org/debian stretch-updates main contrib non-free" >> /etc/apt/sources.list
    echo "deb-src http://httpredir.debian.org/debian stretch-updates main contrib non-free" >> /etc/apt/sources.list

    echo "deb http://security.debian.org/ stretch/updates main contrib non-free" >> /etc/apt/sources.list
    echo "deb-src http://security.debian.org/ stretch/updates main contrib non-free" >> /etc/apt/sources.list
  fi
fi


echo -e "${GREEN}[*]${RESET} Performing apt-get update, please wait..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update

# -== Gnome & XFCE default tweaks ==- #
# xfce4-settings-editor will show settings in GUI window

# Configure XFCE4 Terminal defaults in its config file
file="${HOME}/.config/xfce4/terminal/terminalrc"
if [[ -s "${file}" ]]; then
  # TODO: Not sure if this file is present on a vanilla install and/or if
  # these 'scrolling' settings were only present because I had tweaked them.
  sed -i 's/^ScrollingLines=.*/ScrollingLines=9000/' "${file}"
  sed -i 's/^ScrollingOnOutput=.*/ScrollingOnOutput=FALSE/' "${file}"
  echo "FontName=Monospace 11" >> "${file}"
  echo "BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT" >> "${file}"
  echo "BackgroundDarkness=0.970000" >> "${file}"
fi

# Setup 3 workspaces (Default: 4)
xfconf-query -n -c xfwm4 -p /general/workspace_count -t int -s 3

function xfce_setup_thunar {
  # Thunar file explorer (need to re-login for effect)
  # xfconf-query apparently doesn't require sudo, settings must be user-scope stored
  xfconf-query -n -c thunar -p /last-show-hidden -t bool -s true
  xfconf-query -n -c thunar -p /last-details-view-column-widths -t string -s "50,133,50,50,178,50,50,73,70"
  xfconf-query -n -c thunar -p /last-view -t string -s "ThunarDetailsView"

  mkdir -p ~/.config/Thunar/
  file=~/.config/Thunar/thunarrc
  ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
  sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' "${file}" 2>/dev/null \
    || echo -e "[Configuration]\nLastShowHidden=TRUE" > "${file}"
}
xfce_setup_thunar

#$SUDO gsettings set org.gnome.settings-daemon.plugins.power sleep-display-ac 0
#$SUDO gsettings set org.gnome.settings-daemon.plugins.power sleep-display-battery 0

# Launch xscreensaver settings to auto-generate the config file we need to edit
echo -e "${GREEN}[*]${RESET} Launching and fixing ${GREEN}xscreensaver${RESET}, please wait..."
timeout 3 xscreensaver-demo >/dev/null 2>&1
# Modify the ~/.xscreensaver file to disable screensaver from default "random"
file=~/.xscreensaver
sed -i "s/^mode.*/mode:         off/" "${file}"


echo -e "${GREEN}[*]${RESET} Performing a distro upgrade and installing core pkgs..."
$SUDO apt-get -qy upgrade
$SUDO apt-get -qy dist-upgrade

$SUDO apt-get -y install build-essential gcc git make screen
$SUDO apt-get -y install geany unrar

# Optional remote access services
$SUDO apt-get -y install openvpn openssl openssh-server

# Install disk usage analyzers we may need to isolate disk space issues
# baobab = Disk Usage Analyzer - Menu shortcut will show up under Applications -> SYSTEM
$SUDO apt-get -y install baobab

# Initializing them disabled to prevent insecure remote services to be cautious
$SUDO systemctl stop ssh.service || $SUDO service ssh stop
$SUDO systemctl disable ssh.service || $SUDO service ssh disable

$SUDO systemctl stop exim4.service || $SUDO service exim4 stop
$SUDO systemctl disable exim4.service || $SUDO service exim4 disable

$SUDO systemctl stop apache2.service || $SUDO service apache2 stop
$SUDO systemctl disable apache2.service || $SUDO service apache2.disable

# ====[ Remove Bloat ]======
#$SUDO apt-get -y remove --purge libreoffice libreoffice-base
#$SUDO apt-get -y autoremove


# ====[ Create desktop shortcuts -- just delete if you don't want them
cp /usr/share/applications/gnome-terminal.desktop ~/Desktop/gnome-terminal.desktop 2>/dev/null
cp /usr/share/applications/xfce4-terminal.desktop ~/Desktop/xfce4-terminal.desktop 2>/dev/null
cp /usr/share/applications/firefox-esr.desktop ~/Desktop/ 2>/dev/null
cp /usr/share/applications/geany.desktop ~/Desktop/geany.desktop 2>/dev/null
chmod u+x ~/Desktop/gnome-terminal.desktop 2>/dev/null
chmod u+x ~/Desktop/xfce4-terminal.desktop 2>/dev/null
chmod u+x ~/Desktop/firefox-esr.desktop 2>/dev/null
chmod u+x ~/Desktop/geany.desktop 2>/dev/null



## -============[ Debian Jessie Backports Repository ]=============- #

if [[ ${LSB_RELEASE} == 'jessie' ]]; then
  file=/etc/apt/sources.list.d/backports.list
  $SUDO sh -c "echo ### Debian Jessie Backports > ${file}"
  $SUDO sh -c "echo deb http://httpredir.debian.org/debian jessie-backports main contrib non-free >> ${file}"

  # This is how you can see a list of all installed backports:
  #   dpkg-query -W | grep ~bpo
  # View list of all potential packages:
  #   apt-cache policy <pkg>

  echo -e "${GREEN}[*]${RESET} Installing Conky pkg..."
  $SUDO apt-get -y -t jessie-backports install conky
fi


# -== Git global config settings ==- #
echo -e "${YELLOW}[INPUT]${RESET} Git global config :: Enter your name: "
read $RES
git config --global user.name $RES
echo -e "${YELLOW}[INPUT]${RESET} Git global config :: Enter your email: "
read $RES
git config --global user.email $RES
git config --global color.ui auto



function finish() {
  # Clean system
  echo -e "\n\n${GREEN}[*] ${RESET}Cleaning up the aptitude pkg system"
  $SUDO apt-get -y -qq clean && $SUDO apt-get -y -qq autoremove
  # Remove purged packages from system
  $SUDO apt-get -y -qq purge $(dpkg -l | tail -n +6 | egrep -v '^(h|i)i' | awk '{print $2}')
  cd ~/ &>/dev/null
  history -c 2>/dev/null

  echo -e "\n\n${GREEN}[*] ${RESET}Updating the locate database"
  $SUDO updatedb

  FINISH_TIME=$(date +%s)
  echo -e "${GREEN}[*] ${RESET}Base setup is now complete, goodbye!"
  echo -e "${GREEN}[*] (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)${RESET}"
}
trap finish EXIT


# -==========================-[ Misc Debian Notes ]-==========================-#
### How to turn off IPv6

# Append ipv6.disable=1 to the GRUB_CMDLINE_LINUX variable in /etc/default/grub.
# Run update-grub and reboot.
# or better,

# edit /etc/sysctl.conf and add those parameters to kernel. Also be sure
# to add extra lines for other network interfaces you want to disable IPv6.

#net.ipv6.conf.all.disable_ipv6 = 1
#net.ipv6.conf.default.disable_ipv6 = 1
#net.ipv6.conf.lo.disable_ipv6 = 1
#net.ipv6.conf.eth0.disable_ipv6 = 1

# After editing sysctl.conf, you should run sysctl -p to activate changes or reboot system.

# ============[ Xscreensaver ]============== #
#
# Settings are stored in one of three places:
#       ~/.xscreensaver file (primary)
#               - Settings changed through GUI are written to this file, never the other two.
#       or in the X resource database (secondary)
#
# System-wide defaults:
#       /usr/lib/X11/app-defaults/XScreenSaver
#
#
#
#       File Settings Syntax (*NOTE: Must reload xscreensaver for changes to take effect)
#               For the .xscreensaver file, you'd write it as: timeout: 5
#               For .Xdefaults file, you'd write as: xscreensaver.timeout: 5
#
# Reload the .Xdefaults file and Restart xscreensaver immediately:
#       xrdb < ~/.Xdefaults
#       xscreensaver-command -restart

