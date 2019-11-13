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

echo -e "${GREEN}[*] ${RESET}Updating system..."
apt-get -qq update
# Increase idle delay which locks the screen (default is 300s)
gsettings set org.gnome.desktop.session idle-delay 0

# if update fails due to KEYEXPIRED errors, remove the list file and update again
# rm -rf /var/lib/apt/lists
# apt-get update
# apt-get install -y kali-archive-keyring


if [[ -e "/etc/vmware-tools" ]]; then
  echo -e "${GREEN}[*] ${RESET}VMware Tools is already installed"
elif $(dmidecode | grep -iq vmware); then
  echo -e "\n${GREEN}-----------${RESET}[ Installing Open VM Desktop Tools ]${GREEN}-----------${RESET}"
  apt-get -y install make
  apt-get -y install open-vm-tools-desktop fuse
elif $(dmidecode | grep -iq virtualbox); then
  echo -e "\n${GREEN}-----------${RESET}[ Installing VirtualBox VM Tools ]${GREEN}-----------${RESET}"
  apt-get -y install virtualbox-guest-x11 virtualbox-guest-utils virtualbox-guest-dkms
fi


# -==[ Old CD-ROM VMware Tools method ]==-
# NOTE: it mounts to /media/cdrom0/

# NOTE: g0tmi1k's vmware tools script routine
#if [ -e "/etc/vmware-tools" ]; then
  #echo -e '\n'$RED'[!]'$RESET' VMware Tools is already installed. Skipping...' 1>&2
#if (dmidecode | grep -iq vmware); then
  #mkdir -p /mnt/cdrom/
  #umount -f /mnt/cdrom 2>/dev/null
  #sleep 2
  #mount -o ro /dev/cdrom /mnt/cdrom 2>/dev/null; _mount=$?   # This will only check the first CD drive (if there are multiple bays)
  #sleep 2
  #file=$(find /mnt/cdrom/ -maxdepth 1 -type f -name 'VMwareTools-*.tar.gz' -print -quit)
  #([[ "$_mount" == 0 && -z "$file" ]]) && echo -e ' '$RED'[!]'$RESET' Incorrect CD/ISO mounted' 1>&2
  #if [[ "$_mount" == 0 && -n "$file" ]]; then             # If there is a CD in (and its right!), try to install native Guest Additions
    #echo -e $YELLOW'[i]'$RESET' Patching & using "native VMware tools"'
    #apt-get -y -qq install gcc make "linux-headers-$(uname -r)" git
    #git clone git://github.com/rasa/vmware-tools-patches.git /tmp/vmware-tools-patches
    #cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp/vmware-tools-patches/downloads/
    #pushd /tmp/vmware-tools-patches/ >/dev/null
    #bash untar-and-patch-and-compile.sh
    #popd >/dev/null
    ##cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp/
    ##tar -zxf /tmp/VMwareTools-* -C /tmp/
    ##pushd /tmp/vmware-tools-distrib/ >/dev/null
    ##echo -e '\n' | timeout 300 perl vmware-install.pl       # Press ENTER for all the default options, wait for 5 minutes to try and install else just quit
    ##popd >/dev/null
    #umount -f /mnt/cdrom 2>/dev/null
  #else                                                       # The fallback is 'open vm tools' ~ http://open-vm-tools.sourceforge.net/about.php
    #echo -e ' '$RED'[!]'$RESET' VMware Tools CD/ISO isnt mounted' 1>&2
    #echo -e $YELLOW'[i]'$RESET' Skipping "Native VMware Tools", switching to "Open VM Tools" instead'
    #apt-get -y -qq install open-vm-toolbox
  #fi
