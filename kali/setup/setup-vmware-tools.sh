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

echo -e "\n ${GREEN}-----------${RESET}[ Fixing Kali Repositories ]${GREEN}-----------${RESET}"
file=/etc/apt/sources.list; [ -e $file ] && cp -n $file $file.bkup
grep -q 'sana main non-free contrib' $file 2>/dev/null || echo "deb http://http.kali.org/kali sana main non-free contrib" >> $file
grep -q 'sana/updates main contrib non-free' $file 2>/dev/null || echo "deb http://security.kali.org/kali-security kali/updates main contrib non-free" >> $file
# Update once more in case repositories were invalid
apt-get -qq update

if [ -e "/etc/vmware-tools" ]; then
	echo -e '[*] VMware Tools is already installed'
elif $(dmidecode | grep -iq vmware); then
    echo -e "\n ${GREEN}-----------${RESET}[ Installing Linux Headers ]${GREEN}-----------${RESET}"
	apt-get -y -qq install linux-headers-$(uname -r)
	#ln -s /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/
	# TODO? Pause and ask user if CD is mounted with timeout defaulting to proceed
	# Copy vmware tarball from cd to Desktop
	cp -n /media/cdrom0/VMwareTools-* /tmp/
	cd /tmp/
	tar -xf VMwareTools-*.tar.gz
	cd vmware-tools-distrib
	# Run the installer for a maximum of 300 seconds, kill if not finished by then
	echo -e "\n ${GREEN}-----------${RESET}[ Running VMware Tools Installer ]${GREEN}-----------${RESET}"
	echo -e '\n' | timeout 300 perl vmware-install.pl
	/usr/bin/vmware-user
fi
