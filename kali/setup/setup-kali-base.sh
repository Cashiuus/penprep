#!/bin/bash
## =============================================================================
# File:     setup-kali-base.sh
#
# Author:   Cashiuus - @cashiuus
# Created:  27-Jan-2016  - Revised: 24-JUL-2016
#
# Purpose:  Setup bare bones kali with reasonable default options & packages
#           This script will not perform actions that require reboot (e.g. vm-tools)
#
## =============================================================================
__version__="0.2"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
START_TIME=$(date +%s)
SCRIPT_DIR=$(readlink -f $0)
APP_BASE=$(dirname ${SCRIPT_DIR})

GIT_BASE_DIR="/opt/git"
GIT_DEV_DIR="${HOME}/git"

CREATE_USER_DIRECTORIES=(engagements git pendrop .virtualenvs workspace)
CREATE_OPT_DIRECTORIES=(git pentest)


# =============================[  BEGIN APPLICATION  ]================================ #
# Adjust timeout before starting because lock screen has caused issues during upgrade
xset s 0 0
xset s off
gsettings set org.gnome.desktop.session idle-delay 0


function print_banner() {
    echo -e "\n${BLUE}=============[  ${RESET}${BOLD}Kali 2016 Base Pentest Installer  ${RESET}${BLUE}]=============${RESET}"
    cat /etc/os-release
    cat /proc/version
    uname -a
    lsb_release -a
    echo -e "${BLUE}=======================<${RESET} version: ${__version__} ${BLUE}>=======================\n${RESET}"
}
print_banner

# =============================[ APT Packages ]================================ #
# Change the apt/sources.list repository listings to just a single entry:
echo "# kali-rolling" > /etc/apt/sources.list
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list
echo "deb-src http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list
#export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y dist-upgrade
apt-get -y install build-essential curl locate sudo gcc git make
apt-get -y install htop sysv-rc-conf

# TODO: Still need this?
# Add dpkg for opposing architecture "dpkg --add-architecture amd64

# =============================[ System Setup]================================ #

# (Re-)configure hostname
read -n 5 -p "[+] Enter new hostname or just press enter : " -e response
echo -e
if [[ $response != "" ]]; then
    hostname $response
fi

# Configure Static IP
#read -n 5 -p "[+] Enter static IP Address or just press enter for DHCP : " -e response
#if [[ $response != "" ]]; then
#    # do stuff
#   ip addr add ${response}/24 dev eth0 2>/dev/null
#fi


if [[ ${GDMSESSION} == 'default' ]]; then
  # ====[ Configure - Nautilus ]==== #
  dconf write /org/gnome/nautilus/preferences/show-hidden-files true
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
  gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small'
  #gsettings set org.gnome.nautilus.icon-view thumbnail-size 64
  gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'type', 'date_modified']"
  gsettings set org.gnome.nautilus.list-view default-column-order "['name', 'date_modified', 'size', 'type']"
  gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'             # Default: 'small'
  gsettings set org.gnome.nautilus.list-view use-tree-view true                     # Default: false
  gsettings set org.gnome.nautilus.preferences sort-directories-first true          # Default: false
  gsettings set org.gnome.nautilus.window-state sidebar-width 188                   # Default: 188
  gsettings set org.gnome.nautilus.window-state start-with-sidebar true             # Default: true
  gsettings set org.gnome.nautilus.window-state maximized false                     # Default: false

  # ====[ Configure - Gedit ]==== #
  echo -e "${GREEN}[*]${RESET} Configuring Gedit gsettings"
  gsettings set org.gnome.gedit.preferences.editor display-line-numbers true
  gsettings set org.gnome.gedit.preferences.editor editor-font "'Monospace 10'"
  gsettings set org.gnome.gedit.preferences.editor insert-spaces true
  gsettings set org.gnome.gedit.preferences.editor right-margin-position 90
  gsettings set org.gnome.gedit.preferences.editor tabs-size 4                      # Default: uint32 8
  gsettings set org.gnome.gedit.preferences.editor create-backup-copy false
  gsettings set org.gnome.gedit.preferences.editor auto-save false
  gsettings set org.gnome.gedit.preferences.editor scheme 'classic'
  gsettings set org.gnome.gedit.preferences.editor ensure-trailing-newline true
  gsettings set org.gnome.gedit.preferences.editor auto-indent true                 # Default: false
  gsettings set org.gnome.gedit.preferences.editor syntax-highlighting true
  gsettings set org.gnome.gedit.preferences.ui bottom-panel-visible true            # Default: false
  gsettings set org.gnome.gedit.preferences.ui toolbar-visible true
  gsettings set org.gnome.gedit.state.window side-panel-size 150                    # Default: 200

  # Modify the default "favorite apps"
  gsettings set org.gnome.shell favorite-apps \
    "['gnome-terminal.desktop', 'org.gnome.Nautilus.desktop', 'firefox-esr.desktop', 'kali-burpsuite.desktop', 'kali-armitage.desktop', 'kali-msfconsole.desktop', 'kali-maltego.desktop', 'kali-beef.desktop', 'kali-faraday.desktop', 'geany.desktop']"

elif [[ ${GDMSESSION} == 'lightdm-xsession' ]]; then
  echo -e "${YELLOW}[INFO]${RESET} Light Desktop Manager detected, skipping GNOME tweaks..."
  dconf write /org/gnome/nautilus/preferences/show-hidden-files true
  # Configure Thunar File Browser
  xfconf-query -n -c thunar -p /last-details-view-column-widths -t string -s "50,133,50,50,178,50,50,73,70"
  xfconf-query -n -c thunar -p /last-view -t string -s "ThunarDetailsView"
fi

# =============================[ Folder Structure ]================================ #
# Count number of folders we are creating
count=0
while [ "x${CREATE_USER_DIRECTORIES[count]}" != "x" ]; do
    count=$(( $count + 1 ))
done

# Create folders in ~
echo -e "${GREEN}[*]${RESET} Creating ${count} directories in HOME directory path..."
for dir in ${CREATE_USER_DIRECTORIES[@]}; do
    mkdir -p "${HOME}/${dir}"
done


count=0
while [ "x${CREATE_OPT_DIRECTORIES[count]}" != "x" ]; do
    count=$(( $count + 1 ))
done

# Create folders in /opt
echo -e "${GREEN}[*]${RESET} Creating ${count} directories in /opt/ path..."
for dir in ${CREATE_OPT_DIRECTORIES[@]}; do
    mkdir -p "/opt/${dir}"
done

# =============================[ Dotfiles ]================================ #
if [[ -d "${APP_BASE}../../dotfiles" ]]; then
  read -n 5 -i "Y" -p "[+] Perform simple install of dotfiles? [Y,n] : " -e response
  echo -e
  if [[ $response == "Y" ]]; then
    source "${APP_BASE}/../../install_simple.sh"
  fi
fi

# Configure /etc/skel shell dotfiles

# =============================[ Configure - SSH ]================================ #
# Configure SSH before Git in case we'd prefer to use SSH for git clones

# Configure SSH but don't necessarily make it autostart



# =============================[ Github/Git Repositories ]================================ #





# =====[ Fix an error with Fonts ]=======
# For some reason, mscorettfonts can be upgrade or installed with incorrect permissions
# Then, you will see errors in your /var/log/messages output indicating errors rendering fonts.
# This was noticed because after an updated on 01-Aug-2016, all window titles were hollow boxes
# indicating invalid characters after the update completed, and after reboot as well.
folder=/usr/share/fonts
chmod -R +rw $folder


# ===================================[ FINISH ]====================================== #
function finish {
  echo -e "\n\n${GREEN}[+]${RESET} ${GREEN}Cleaning${RESET} the system"
  #--- Clean package manager
  for FILE in clean autoremove; do apt -y -qq "${FILE}"; done
  # Removed -y -qq from this for testing, believe important dependencies are being removed here.
  apt purge $(dpkg -l | tail -n +6 | egrep -v '^(h|i)i' | awk '{print $2}')   # Purged packages
  #--- Update locate database
  updatedb
  #--- Reset folder location
  cd ~/ &>/dev/null
  #--- Remove any history files (as they could contain sensitive info)
  history -c 2>/dev/null
  for i in $(cut -d: -f6 /etc/passwd | sort -u); do
    [ -e "${i}" ] && find "${i}" -type f -name '.*_history' -delete
  done
  FINISH_TIME=$(date +%s)
  echo -e "${GREEN} [*] Kali Base Setup Completed Successfully ${YELLOW} --( Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes )--\n${RESET}"
}
# End of script
trap finish EXIT

# ================[ Expression Cheat Sheet ]==================================
#
#   -d      file exists and is a directory
#   -e      file exists
#   -f      file exists and is a regular file
#   -h      file exists and is a symbolic link
#   -s      file exists and size greater than zero
#   -r      file exists and has read permission
#   -w      file exists and write permission granted
#   -x      file exists and execute permission granted
#   -z      file is size zero (empty)
#   [[ $? -eq 0 ]]    Previous command was successful
#   [[ ! $? -eq 0 ]]    Previous command NOT successful
#

# --- TOUCH
#touch
#touch "$file" 2>/dev/null || { echo "Cannot write to $file" >&2; exit 1; }

### ---[ READ ]---###
#   -p ""   Instead of echoing text, provide it right in the "prompt" argument
#               *NOTE: Typically, there is no newline, so you may need to follow
#               this with an "echo" statement to output a newline.
#   -e      Specify variable response is stored in. Arg can be anywhere,
#           but variable is always at the end of the statement
#   -n #    Number of seconds to wait for a response before continuing automatically
#   -i ""   Specify a default value. If user hits ENTER or doesn't respond, this value is saved
#

#Ask for a path with a default value
#read -p "Enter the path to the file: " -i "/usr/local/etc/" -e FILEPATH


# ==================[ BASH GUIDES ]====================== #
# Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
# Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
