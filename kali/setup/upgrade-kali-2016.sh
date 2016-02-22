#!/bin/bash
## =============================================================================
# File:     upgrade-kali-2016.sh
#
# Author:   Cashiuus
# Created:  01/25/2016
# Revised:
#
# Purpose:  Perform the steps necessary to upgrade Kali
#
## =============================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##


# ============================[ PREPARE ]================================ #
apt-get -y install htop

# ============================[ BEGIN ]================================ #
START_TIME=$(date +%s)
# Adjust timeout before starting because lock screen has caused issues during upgrade
gsettings set org.gnome.desktop.session idle-delay 0
# Change the apt/sources.list repository listings to just a single entry:
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list
apt-get update
apt-get -y dist-upgrade

FINISH_TIME=$(date +%s)
echo -e "${GREEN} [*] Upgrade Completed Successfully ${YELLOW} --( Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes )--\n${RESET}"

### Install Open VM Tools
read -n 1 -t 5 -p "[+] Install Open VM Tools? [Y,n]: " -e response
echo
case $response in
    [Yy]* ) install_vm_tools;;
esac

read -n 1 -t 10 -p "[+] Okay to Reboot System now? [y,N]: " -e response
echo
case $response in
    [Yy]* ) reboot;;
    [Nn]* ) exit 0;;
esac


function install_vm_tools {
    apt-get update
    apt-get -y install open-vm-tools-desktop fuse
}


function finish {
    # Script exit cleanup routines
    apt-get clean
    apt-get autoremove
}
trap finish EXIT
