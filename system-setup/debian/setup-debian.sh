#!/usr/bin/env bash
## =======================================================================================
# File:     setup-debian.sh
# Author:   Cashiuus
# Created:  15-Jan-2016         Revised:  28-Dec-2020
#
#-[ Info ]-------------------------------------------------------------------------------
#- Purpose:  Setup a fresh Debian 8 server, typically within a Virtual Machine.
#
#
#- Notes:
#     1.  Below, set the constant "INSTALL_USER" to your primary account you are using
#         If you don't, it'll default to 'user1'
#
#  Changes:
#       - 2020-12-28 v1.4: Settings for gnome-terminal, now default in Deb 10
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
__version__="1.4"
__author__="Cashiuus"

## ============[ CONSTANTS ]================ ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
DEBUG=true
## ============[ CONSTANTS ]================ ##

LSB_RELEASE=$(lsb_release -cs)
# buster = Debian 10.x

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

echo -e "${GREEN}[*]${RESET} Debian Release: ${ORANGE}${LSB_RELEASE}${RESET}\n"
$SUDO apt-get -qq update
if [[ "$?" -ne 0 ]]; then
  echo -e "${RED} [ERROR]${RESET} Network issues preventing apt-get. Check and try again."
  exit 1
fi

function collect_system_details() {

  # Determine default terminal
  T=$(update-alternatives --list x-terminal-emulator | head -n 1 | cut -d "." -f1 | cut -d "/" -f4)
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: f: collect_system_details :: update alternatives output = ${T}${RESET}"
  if [[ "$T" = "gnome-terminal" ]]; then
    DEFAULT_TERMINAL="gnome-terminal"
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: f: collect_system_details :: 1 DEFAULT_TERMINAL = ${DEFAULT_TERMINAL}${RESET}"
    return
  elif [[ "$T" = "xfce4-terminal" ]]; then
    DEFAULT_TERMINAL="xfce4-terminal"
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: f: collect_system_details :: 2 DEFAULT_TERMINAL = ${DEFAULT_TERMINAL}${RESET}"
    return
  elif [[ -z "$T" ]]; then
    # our default terminal has to be found another way
    DEFAULT_TERMINAL="xfce4-terminal"
  else
    # handle all other possible outcomes for now by grabbing env, likely 'xterm-256color'
    DEFAULT_TERMINAL=$TERM
  fi

  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: f: collect_system_details :: else DEFAULT_TERMINAL = ${DEFAULT_TERMINAL}${RESET}"


}
collect_system_details

## ========================================================================== ##
# ================================[  BEGIN  ]================================ #
# -==  Setup VM Tools  ==- #
# https://github.com/vmware/open-vm-tools
SYSMANUF=$($SUDO dmidecode -s system-manufacturer)
SYSPRODUCT=$($SUDO dmidecode -s system-product-name)
if [[ $SYSMANUF == "Xen" ]] || [[ $SYSMANUF == "VMware, Inc." ]] || [[ $SYSPRODUCT == "VirtualBox" ]]; then
  if [[ ! $(which vmware-toolbox-cmd) ]]; then
    echo -e "${YELLOW}[ INFO ] Now installing vm-tools. This will require a reboot. Re-run script after...${RESET}"
    sleep 4
    $SUDO apt-get -y install open-vm-tools-desktop fuse
    $SUDO reboot
  else
    echo -e "${GREEN}[*]${RESET} VM Tools already seem to be installed, moving along..."
  fi
else
  echo -e "${GREEN}[*]${RESET} It looks like your system is bare hardware, skipping vm-tools install..."
fi
# Increase idle delay which locks the screen (default is 300s)
# Don't need sudo for this command, user-specific setting
gsettings set org.gnome.desktop.session idle-delay 0

# -==   APT   ==- #
# https://wiki.debian.org/SourcesList
echo -e "\n${GREEN}[*]${RESET} Setting sources.list to standard entries"
if [[ $SUDO ]]; then
  echo "# Debian - ${LSB_RELEASE}" | $SUDO tee /etc/apt/sources.list
  echo "deb http://httpredir.debian.org/debian ${LSB_RELEASE} main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian ${LSB_RELEASE} main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb http://httpredir.debian.org/debian ${LSB_RELEASE}-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian ${LSB_RELEASE}-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb http://security.debian.org/ ${LSB_RELEASE}/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://security.debian.org/ ${LSB_RELEASE}/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
else
  echo "# Debian - ${LSB_RELEASE}" > /etc/apt/sources.list
  echo "deb http://httpredir.debian.org/debian ${LSB_RELEASE} main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian ${LSB_RELEASE} main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://httpredir.debian.org/debian ${LSB_RELEASE}-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian ${LSB_RELEASE}-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://security.debian.org/ ${LSB_RELEASE}/updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://security.debian.org/ ${LSB_RELEASE}/updates main contrib non-free" >> /etc/apt/sources.list
fi
echo -e ""

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
  #sed -i 's/^ScrollingLines=.*/ScrollingLines=9000/' "${file}"
  sed -i 's/^ScrollingOnOutput=.*/ScrollingOnOutput=FALSE/' "${file}"
  #sed -i 's/^FontName=.*/FontName=Monospace 10/' "${file}" || \
    echo "FontName=Monospace 10" >> "${file}"
  #echo "BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT" >> "${file}"
  #echo "BackgroundDarkness=0.970000" >> "${file}"
fi


# --------------------
#   GNOME Terminal
# --------------------
#   TODO: Refactor every single thing that customizes a terminal.
# This is getting rediculous w/ distros not making up their minds
# about which terminal to default and where/how settings are saved.
#   List profiles: dconf list /org/gnome/terminal/legacy/profiles:/
#   Specify profile ID to get list of settings you can configure:
#       dconf list /org/gnome/terminal/legacy/profiles:/<id>
if [[ $(which gnome-terminal) ]]; then
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: gnome terminal tweaks :: begin${RESET}"
  #MYPROFILE=$(dconf list /org/gnome/terminal/legacy/profiles:/)
  MYPROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | cut -d "'" -f2)
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: gnome terminal :: MYPROFILE = $MYPROFILE ${RESET}"
  dconf write /org/gnome/terminal/legacy/profiles:/"${MYPROFILE}"/visible-name "'Default'"
  dconf write /org/gnome/terminal/legacy/profiles:/"${MYPROFILE}"/scrollback-unlimited true
  dconf write /org/gnome/terminal/legacy/profiles:/"${MYPROFILE}"/audible-bell false
  # These colors represent "Tango Dark" profile. Doesn't seem to be a setting for it by name.
  dconf write /org/gnome/terminal/legacy/profiles:/"${MYPROFILE}"/background-color "'rgb(46,52,54)'"
  dconf write /org/gnome/terminal/legacy/profiles:/"${MYPROFILE}"/foreground-color "'rgb(211,215,207)'"

  # Method 2: gconftool-2 *This did not work for me on Debian 10
  #   Get list of profiles: gconftool-2 --get /apps/gnome-terminal/profiles/global/profile_list
  #   Get list of settings: gconftool-2 -a "/apps/gnome-terminal/profiles/Default"
fi


# -------------------------
#   XFCE Tweaks continued
# -------------------------
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

#gsettings set org.gnome.settings-daemon.plugins.power sleep-display-ac 0
#gsettings set org.gnome.settings-daemon.plugins.power sleep-display-battery 0

# Launch xscreensaver settings to auto-generate the config file we need to edit
if [[ $(which xscreensaver) ]]; then
  echo -e "${GREEN}[*]${RESET} Launching and fixing ${GREEN}xscreensaver${RESET}, please wait..."
  timeout 3 xscreensaver-demo >/dev/null 2>&1
  # Modify the ~/.xscreensaver file to disable screensaver from default "random"
  file=~/.xscreensaver
  sed -i 's/^mode.*/mode:         off/' "${file}"
fi

echo -e "${GREEN}[*]${RESET} Performing a distro upgrade and installing core pkgs..."
$SUDO apt-get -qy upgrade
$SUDO apt-get -qy dist-upgrade

$SUDO apt-get -y install build-essential gcc git htop make mlocate screen strace
$SUDO apt-get -y install gconf-editor geany unrar

# Optional remote access services
$SUDO apt-get -y install openvpn openssl openssh-server

# Install disk usage analyzers we may need to isolate disk space issues
# baobab = Disk Usage Analyzer - Menu shortcut will show up under Applications -> SYSTEM
$SUDO apt-get -y install baobab

# Install libreoffice
$SUDO apt-get -y install libreoffice

# Initializing them disabled to prevent insecure remote services to be cautious
echo -e "${GREEN}[*]${RESET} Disabling several network services for security hardening (apache2, exim4, ssh, openvpn)"
$SUDO systemctl stop openvpn.service >/dev/null 2>&1 || $SUDO service openvpn stop >/dev/null 2>&1
$SUDO systemctl disable openvpn.service >/dev/null 2>&1 || $SUDO service openvpn disable >/dev/null 2>&1

$SUDO systemctl stop ssh.service >/dev/null 2>&1 || $SUDO service ssh stop >/dev/null 2>&1
$SUDO systemctl disable ssh.service >/dev/null 2>&1 || $SUDO service ssh disable >/dev/null 2>&1

$SUDO systemctl stop exim4.service >/dev/null 2>&1 || $SUDO service exim4 stop >/dev/null 2>&1
$SUDO systemctl disable exim4.service >/dev/null 2>&1 || $SUDO service exim4 disable >/dev/null 2>&1

$SUDO systemctl stop apache2.service >/dev/null 2>&1 || $SUDO service apache2 stop >/dev/null 2>&1
$SUDO systemctl disable apache2.service >/dev/null 2>&1 || $SUDO service apache2.disable >/dev/null 2>&1


# ====[ Create desktop shortcuts
function create_desktop_shortcut() {
  # Usage: create_desktop_shortcut <shortcut_source_path>
  if [[ -f "$1" ]]; then
    #local loc_dest=$(ls $1 | cut -d "/" -f5)
  local loc_dest=${1##*/}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: f: shortcuts :: loc_dest is ${loc_dest} ${RESET}"
    cp "${1}" "${HOME}/Desktop/$loc_dest"
    [[ "$?" -eq 0 ]] && chmod u+x "${HOME}/Desktop/$loc_dest"
  return 0
  else
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: f: shortcuts :: $1 is not a valid file ${RESET}"
    return 1
  fi
}

echo -e "${GREEN}[*]${RESET} Creating desktop shortcuts"
if [[ "$DEFAULT_TERMINAL" = "gnome-terminal" ]]; then
  create_desktop_shortcut "/usr/share/applications/exo-terminal-emulator.desktop"
  [[ "$?" -eq 1 ]] && create_desktop_shortcut "/usr/share/applications/gnome-terminal.desktop"
elif [[ "$DEFAULT_TERMINAL" = "xfce4-terminal" ]]; then
  create_desktop_shortcut "/usr/share/applications/xfce4-terminal.desktop"
fi
#cp /usr/share/applications/gnome-terminal.desktop ~/Desktop/gnome-terminal.desktop 2>/dev/null
#cp /usr/share/applications/xfce4-terminal.desktop ~/Desktop/xfce4-terminal.desktop 2>/dev/null
#chmod u+x ~/Desktop/gnome-terminal.desktop 2>/dev/null
#chmod u+x ~/Desktop/xfce4-terminal.desktop 2>/dev/null

create_desktop_shortcut "/usr/share/applications/firefox-esr.desktop"
create_desktop_shortcut "/usr/share/applications/geany.desktop"

#cp /usr/share/applications/firefox-esr.desktop ~/Desktop/ 2>/dev/null
#cp /usr/share/applications/geany.desktop ~/Desktop/geany.desktop 2>/dev/null
#chmod u+x ~/Desktop/firefox-esr.desktop 2>/dev/null
#chmod u+x ~/Desktop/geany.desktop 2>/dev/null



## -============[ Debian Jessie Backports Repository ]=============- #
echo -e "${GREEN}[*]${RESET} Installing Conky system status overlay tool..."
if [[ ${LSB_RELEASE} == 'jessie' ]]; then
  file=/etc/apt/sources.list.d/backports.list
  $SUDO sh -c "echo ### Debian Jessie Backports > ${file}"
  $SUDO sh -c "echo deb http://httpredir.debian.org/debian jessie-backports main contrib non-free >> ${file}"

  # This is how you can see a list of all installed backports:
  #   dpkg-query -W | grep ~bpo
  # View list of all potential packages:
  #   apt-cache policy <pkg>

  $SUDO apt-get -y -t jessie-backports install conky
else
  $SUDO apt-get -y install conky
fi


# -== Git global config settings ==- #
echo -e -n "\n${YELLOW}[ INPUT ]${RESET} Git global config :: Enter your name: "
read GIT_NAME
[[ ${GIT_NAME} ]] && git config --global user.name $GIT_NAME
echo -e -n "\n${YELLOW}[ INPUT ]${RESET} Git global config :: Enter your email: "
read GIT_EMAIL
[[ ${GIT_EMAIL} ]] && git config --global user.email $GIT_EMAIL
git config --global color.ui auto
# Setting the previously default of merge for git pulls, specify rebase on cli as needed
#   --rebase, --no-rebase, or --ff-only to override this global config default
git config --global pull.rebase false

echo -e "${GREEN}[*]${RESET} As of Oct 1, 2020, Git has changed default branch to 'main'"
echo -e "${GREEN}[*]${RESET} Therefore, setting your git config default branch to 'main' now"
git config --global init.defaultBranch main

function install_plank_desktop() {
  $SUDO apt-get -y install plank
  # Need to remove the default dock

  # Then, launch plank
  plank &

  # Open plank preferences
  #plank --preferences

}
#install_plank_desktop


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


# ====[ Remove Bloat ]======
#if [[ "$KEEP_LIBREOFFICE" = false ]]; then
#   echo -e "#{GREEN}[*] Removing LibreOffice packages first..."
#   $SUDO apt-get -qq remove --purge libreoffice*
#fi
#$SUDO apt-get -y remove libreoffice libreoffice-base
#$SUDO apt-get -y autoremove


# -==========================-[ Misc Debian Notes ]-==========================-#

# -==========-[ Setup Mounted Share - NAS ]-============-#
# Guide: https://wiki.ubuntu.com/MountWindowsSharesPermanently
#$SUDO apt-get -y install cifs-utils
#
# Create a new directory for the mounted share to reside
#$SUDO mkdir /media/musicshare
#
# Then, edit your fstab file to add a line for the share permissions
#$SUDO nano /etc/fstab
#
# After you save and close, remount everything to get it to mount
#$SUDO mount -a
#
# *NOTE: If you get a permission error, it's likely your share is
#        blocking you from accessing it as a guest
#
# ------------------------------------------------------------------------- #
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
#
# -------[ locate/updatedb ]-------------- #
# The locate command is part of the 'mlocate' package, not always installed by default
# Once you install mlocate, run the `sudo updatedb` command to build the database.
# The db is stored by default at: /var/lib/mlocate/mlocate.db
#
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

