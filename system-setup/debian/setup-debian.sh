#!/usr/bin/env bash
## =======================================================================================
# File:     setup-debian.sh
#
# Author:   Cashiuus
# Created:  15-Jan-2016		Revised:	31-Mar-2017
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Setup a fresh Debian 8 server, typically within a Virtual Machine.
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#
#	1. 	Below, set the constant "INSTALL_USER" to your primary account you are using
#		If you don't, it'll default to 'user1'
#
#
#-[ Links/Credit ]------------------------------------------------------------------------
#
# - http://www.debiantutorials.com/
# - Help: http://www.pontikis.net/blog/debian-wheezy-web-server-setup
# - Tutorial: https://www.digitalocean.com/community/tutorials/initial-server-setup-with-debian-8
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="1.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
PURPLE="\033[01;35m"    # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## ============[ CONSTANTS ]================ ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"

INSTALL_USER="user1"
## ============[ CONSTANTS ]================ ##


#======[ ROOT PRE-CHECK ]=======#
function install_sudo() {
    # If
    [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
    echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get, elevating to root..."

    su root
    [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to su root${RESET}" && exit 1
    apt-get -y install sudo
    [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo pkg via apt-get${RESET}" && exit 1
    # Use stored USER value to add our originating user account to the sudoers group
    # TODO: Will this break if script run using sudo? Env var likely will be root if so...test this...
    #usermod -a -G sudo ${ACTUAL_USER}
    usermod -a -G sudo ${INSTALL_USER}
    [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

    echo -e "${YELLOW}[WARN] ${RESET}Now logging off to take effect. Restart this script after login!"
    sleep 4
    # First logout command will logout from su root elevation
    logout
    exit 1
}

function check_root() {

    # There is an env var that is $USER. This is regular user if in normal state, root in sudo state
    #   CURRENT_USER=${USER}
    #   ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
         # This would only be run if within sudo state
         # This variable serves as the original user when in a sudo state

    if [[ $EUID -ne 0 ]];then
        # If not root, check if sudo package is installed and leverage it
        # TODO: Will this work if current user doesn't have sudo rights, but sudo is already installed?
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            # This accounts for both root and sudo. If normal user, it'll use sudo.
            # If you run script as root, $SUDO is blank and script will soldier on.
        else
            echo -e "${YELLOW}[WARN] ${RESET}The 'sudo' package is not installed. Press any key to install it (*must enter sudo password), or cancel now"
            read -r -t 10
            install_sudo
            # TODO: This error check necessary, since the function "install_sudo" exits 1 anyway?
            [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Please install sudo or run this as root. Exiting.${RESET}" && exit 1
        fi
    fi
}
check_root
## ========================================================================== ##
function configure_bash_systemwide() {
	echo -e "[*] Configuring systemwide BASH history settings"
    file=/etc/bash.bashrc
	
    grep -q "HISTSIZE" "${file}" \
        || echo "HISTSIZE=10000" >> "${file}"               # Bash history (memory scroll back)
    sed -i 's/^HISTSIZE=.*/HISTSIZE=10000/' "${file}"
    grep -q "HISTFILESIZE" "${file}" \
        || echo "HISTFILESIZE=10000" >> "${file}"           # Bash history (file .bash_history)
    sed -i 's/^HISTFILESIZE=.*/HISTFILESIZE=10000/' "${file}"

    # If last line of file is not blank, add a blank spacer line
    ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
    sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' "${file}"
    grep -q '^force_color_prompt' "${file}" 2>/dev/null \
      || echo 'force_color_prompt=yes' >> "${file}"
    sed -i 's#PS1='"'"'.*'"'"'#PS1='"'"'${debian_chroot:+($debian_chroot)}\\[\\033\[01;31m\\]\\u@\\h\\\[\\033\[00m\\]:\\[\\033\[01;34m\\]\\w\\[\\033\[00m\\]\\$ '"'"'#' "${file}"
    grep -q "^export LS_OPTIONS='--color=auto'" "${file}" 2>/dev/null \
      || echo "export LS_OPTIONS='--color=auto'" >> "${file}"

    # All other users that are made afterwards
    file=/etc/skel/.bashrc
    sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' "${file}"
}
# ================================[  BEGIN  ]================================ #
echo -e ""
# =========================[ Setup VM Tools ]============================ #
# https://github.com/vmware/open-vm-tools
if [[ ! $(which vmware-toolbox-cmd) ]]; then
  echo -e "${YELLOW}[-] Now installing vm-tools. This will require a reboot. Re-run script after...${RESET}"
  sleep 4
  $SUDO apt-get -y install open-vm-tools-desktop fuse
  $SUDO reboot
fi

# =============================[   APT   ]================================ #
# https://wiki.debian.org/SourcesList
echo -e "\n${GREEN}[*]${RESET} Setting sources.list to standard entries"
if [[ $SUDO ]]; then
  echo "# Debian Jessie" | $SUDO tee /etc/apt/sources.list
  echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian jessie main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

  echo "deb http://httpredir.debian.org/debian jessie-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

  echo "deb http://security.debian.org/ jessie/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://security.debian.org/ jessie/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
	# Backports repo for newer pkgs
	echo "" | $SUDO tee -a /etc/apt/sources.list
	echo "# Backports Repository" | $SUDO tee -a /etc/apt/sources.list
	echo "deb http://httpredir.debian.org/debian jessie-backports main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
else
  echo "# Debian Jessie" > /etc/apt/sources.list
  echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list

  echo "deb http://httpredir.debian.org/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list

  echo "deb http://security.debian.org/ jessie/updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://security.debian.org/ jessie/updates main contrib non-free" >> /etc/apt/sources.list
	# Backports repo for newer pkgs
	echo "" >> /etc/apt/sources.list
	echo "# Backports Repository" >> /etc/apt/sources.list
	echo "deb http://httpredir.debian.org/debian jessie-backports main contrib non-free" >> /etc/apt/sources.list
fi


echo -e "${GREEN}[*]${RESET} Performing apt-get update, please wait..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
if [[ "$?" -ne 0 ]]; then
  echo -e "${RED} [ERROR]${RESET} Network issues preventing apt-get. Check and try again."
  exit 1
fi

# Increase idle delay which locks the screen (default is 300s)
$SUDO gsettings set org.gnome.desktop.session idle-delay 0
#$SUDO gsettings set org.gnome.settings-daemon.plugins.power sleep-display-ac 0 
#$SUDO gsettings set org.gnome.settings-daemon.plugins.power sleep-display-battery 0 


# Launch xscreensaver settings to auto-generate the config file we need to edit
echo -e "${GREEN}[*]${RESET} Launching and fixing ${GREEN}xscreensaver${RESET}, please wait..."
timeout 3 xscreensaver-demo >/dev/null 2>&1

# Modify the ~/.xscreensaver file to disable screensaver from default "random"
file=~/.xscreensaver
sed -i "s/^mode.*/mode:		off/" "${file}"


echo -e "${GREEN}[*]${RESET} Performing a distro upgrade and installing core pkgs..."
$SUDO apt-get -qy upgrade
$SUDO apt-get -qy dist-upgrade

$SUDO apt-get -y install make gcc git build-essential
$SUDO apt-get -y install conky geany unrar

# Optional remote access services
$SUDO apt-get -y install openvpn openssl openssh-server

# Install disk usage analyzers we may need to isolate disk space issues
# baobab = Disk Usage Analyzer - Menu shortcut will show up under Applications -> SYSTEM
$SUDO apt-get -y install baobab

# Initializing them disabled to prevent insecure remote ssh sever to be cautious
$SUDO systemctl stop ssh.service
$SUDO systemctl disable ssh.service

$SUDO systemctl stop exim4.service
$SUDO systemctl disable exim4.service

# ====[ Remove Bloat ]======
#$SUDO apt-get -y remove libreoffice libreoffice-base
#$SUDO apt-get -y autoremove


# Create desktop shortcuts -- just delete if you don't want them
cp /usr/share/applications/xfce4-terminal.desktop ~/Desktop/xfce4-terminal.desktop
cp /usr/share/applications/geany.desktop ~/Desktop/geany.desktop
chmod +x ~/Desktop/xfce4-terminal.desktop
chmod +x ~/Desktop/geany.desktop



# =============[ CONKY via Backports Repo ]===============
# This is how you can see a list of all installed backports:
#	dpkg-query -W | grep ~bpo

echo -e "${GREEN}[*]${RESET} Installing Conky pkg..."
$SUDO apt-get -y -t jessie-backports install conky










function pause() {
  # Simple function to pause a script mid-stride
  #
  local dummy
  read -s -r -p "Press any key to continue..." -n 1 dummy
}


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


# -==========================-[ Misc Notes ]-==========================-#
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
#	~/.xscreensaver file (primary)
#		- Settings changed through GUI are written to this file, never the other two.
#	or in the X resource database (secondary)
#
# System-wide defaults:
#	/usr/lib/X11/app-defaults/XScreenSaver
#
#
#
#	File Settings Syntax (*NOTE: Must reload xscreensaver for changes to take effect)
#		For the .xscreensaver file, you'd write it as: timeout: 5
#		For .Xdefaults file, you'd write as: xscreensaver.timeout: 5
#
# Reload the .Xdefaults file and Restart xscreensaver immediately:
#	xrdb < ~/.Xdefaults
#	xscreensaver-command -restart

