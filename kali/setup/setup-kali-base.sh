#!/bin/bash
## =============================================================================
# File:     setup-kali-base.sh
#
# Author:   Cashiuus - @cashiuus
# Created:  27-Jan-2016  - Revised: 21-Feb-2016
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

# TODO: Clean this up
source vfeed_install.sh

# =============================[  BEGIN APPLICATION  ]================================ #
# Adjust timeout before starting because lock screen has caused issues during upgrade
gsettings set org.gnome.desktop.session idle-delay 0


function print_banner() {
    echo -e "\n${BLUE}=============[  ${RESET}${BOLD}Kali 2016 Base Pentest Installer  ${RESET}${BLUE}]=============${RESET}"
    cat /etc/os-release
    cat /proc/version
    uname -a
    lsb_release -a
    echo -e "${BLUE}=====================<${RESET} version: ${__version__} ${BLUE}>=====================\n${RESET}"
}
print_banner

# =============================[ APT Packages ]================================ #
# Change the apt/sources.list repository listings to just a single entry:
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list
#export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y dist-upgrade
apt-get -y install build-essential locate sudo gcc git htop make sysv-rc-conf
apt-get -y autoremove

# Add dpkg for opposing architecture "dpkg --add-architecture amd64


# =============================[ System Setup]================================ #

# (Re-)configure hostname

# Configure Static IP





# ====[ Configure - Nautilus ]==== #

dconf write /org/gnome/nautilus/preferences/show-hidden-files true




# =============================[ Folder Structure ]================================ #

# Create folders in /opt
for ' '

# Create folders in ~
for 'git engagements pendrop .virtualenvs'; do





# =============================[ Dotfiles ]================================ #
# Configure /etc/skel shell dotfiles



# =============================[ Configure - SSH ]================================ #
# Configure SSH before Git in case we'd prefer to use SSH for git clones

# Configure SSH but don't necessarily make it autostart



# =============================[ Github/Git Repositories ]================================ #

# ===[ vFeed ]=== #
vfeed_install "${GIT_BASE_DIR}" || echo -e "${RED}[-]${RESET} Error installing vfeed"










FINISH_TIME=$(date +%s)
echo -e "${GREEN} [*] Kali Base Setup Completed Successfully ${YELLOW} --( Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes )--\n${RESET}"

echo -e "${GREEN}=========${RESET}[ OS Specs ]${GREEN}=========${RESET}"
cat /etc/os-release
cat /proc/version
uname -a
lsb_release -a
echo -e "${GREEN}=====================================${RESET}"




function finish {
    # Any script-termination routines go here, but function cannot be empty
    clear
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
