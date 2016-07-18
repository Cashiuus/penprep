#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: setup-vmware-tools.sh       (Update: 17-Jan-2015) #
#-Author------------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-License-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#  Credit: https://github.com/g0tmi1k/os-scripts/             #
#-Notes-------------------------------------------------------#
#                                                             #
#  Usage: curl -L http://j.mp/kali-vmtools | bash             #
#                                                             #
#                                                             #
# Before running script, click "Install VMware Tools"         #
# from VMware menu to mount the CD                            #
#                                                             #
#-------------------------------------------------------------#
GREEN="\033[01;32m"    # Success
RESET="\033[00m"       # Normal


apt-get -qq update
# Increase idle delay which locks the screen (default is 300s)
gsettings set org.gnome.desktop.session idle-delay 0

# if update fails due to KEYEXPIRED errors, remove the list file and update again
# rm -rf /var/lib/apt/lists
# apt-get update
# apt-get install -y kali-archive-keyring


if [ -e "/etc/vmware-tools" ]; then
	echo -e '[*] VMware Tools is already installed'
elif $(dmidecode | grep -iq vmware); then
    echo -e "\n${GREEN}-----------${RESET}[ Installing Open VM Desktop Tools ]${GREEN}-----------${RESET}"
	apt-get -y install make
	apt-get -y install open-vm-tools-desktop fuse
elif $(dmidecode | grep -iq virtualbox): then
    echo -e "\n${GREEN}-----------${RESET}[ Installing VirtualBox VM Tools ]${GREEN}-----------${RESET}"
    apt-get -y install virtualbox-guest-x11
fi
