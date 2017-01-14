#!/bin/bash
## =============================================================================
# File:     setup-kali-base.sh
#
# Author:   Cashiuus
# Created:  27-Jan-2016  - Revised: 12-Dec-2016
#
# Purpose:  Setup bare bones kali with reasonable default options & packages
#           This script will not perform actions that require reboot (e.g. vm-tools)
#
## =============================================================================
__version__="0.3"
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
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/kali-builder/settings.conf"

GIT_BASE_DIR="/opt/git"
GIT_DEV_DIR="${HOME}/git"
# Set of custom directories to create within ~ and /opt/
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
sleep 4

# =============================[ Setup VM Tools ]================================ #
# (Re-)configure hostname
echo -e -n "${GREEN}[+]${RESET} "
read -r -t 10 -p "Enter new hostname or just press enter : " -e response
echo -e
if [[ $response != "" ]]; then
    hostname $response
    echo "$response" > /etc/hostname
fi

# https://github.com/vmware/open-vm-tools
if [[ ! $(which vmware-toolbox-cmd) ]]; then
  echo -e "${YELLOW}[-] Now installing vm-tools. This will require a reboot. Re-run script after reboot...${RESET}"
  sleep 4
  $SUDO apt-get -y install open-vm-tools-desktop fuse
  $SUDO reboot
fi

# =============================[ APT Packages ]================================ #
# Change the apt/sources.list repository listings to just a single entry:
echo "# kali-rolling" > /etc/apt/sources.list
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list
echo "deb-src http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y dist-upgrade
$SUDO apt-get -y install build-essential curl locate sudo gcc git git-core make
$SUDO apt-get -y install htop sysv-rc-conf

# Extra base load
$SUDO apt-get -y install armitage arp-scan beef-xss dirb dirbuster exploitdb \
    kali-linux-pwtools kali-linux-sdr kali-linux-top10 kali-linux-voip kali-linux-web \
    kali-linux-wireless mitmproxy nikto openssh-server openssl proxychains rdesktop responder \
    screen shellter sqlmap tmux tshark vlan whatweb wifite windows-binaries wpscan yersinia


# TODO: Still need this?
# Add dpkg for opposing architecture "dpkg --add-architecture amd64

# =============================[ System Configurations]================================ #

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



# Nautilus user bookmarks - modify this file: /etc/xdg/user-dirs.conf



# TODO: Look into Nemo file manager :: apt-get install nemo
# If you want to continue using Nautilus for drawing your desktop icons:
#   Show all the startup apps:
#   sudo sed -i 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/nemo-autostart.desktop

# Then, uncheck the item under Startup Applications that says:
#   Files
#   Start Nemo desktop at login

# Optional add-ons: sudo apt-get install nemo-compare nemo-dropbox nemo-media-columns nemo-pastebin nemo-seahorse nemo-share nemo-emblems nemo-image-converter nemo-audio-tab







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



# =====[ Metasploit ]===== #
# Another one is msfdb reinit to re-run initialization
msfdb init
mv /usr/share/metasploit-framework/config/database.yml ~/.msf4/database.yml


cat << EOF > ~/.msf4/msfconsole.rc
db_connect -y /root/.msf4/database.yml
spool /root/.msf4/logs/console.log
setg TimestampOutput true
setg VERBOSE true
setg LHOST 0.0.0.0
setg LPORT 443
EOF



function configure_bash_systemwide() {
    file=/etc/bash.bashrc
    grep -q "cdspell" "${file}" \
        || echo "shopt -sq cdspell" >> "${file}"            # Spell check 'cd' commands
    grep -q "autocd" "${file}" \
        || echo "shopt -s autocd" >> "${file}"              # So you don't have to 'cd' before a folder

    # TODO: Test to see if this sed works
    grep -q "checkwinsize" "${file}" \
        || echo "shopt -sq checkwinsize" >> "${file}"       # Wrap lines correctly after resizing
    sed -i 's/^shopt -sq? checkwinsize/shopt -sq checkwinsize/' "${file}"

    grep -q "nocaseglob" "${file}" \
        || echo "shopt -sq nocaseglob" >> "${file}"         # Case insensitive pathname expansion
    grep -q "HISTSIZE" "${file}" \
        || echo "HISTSIZE=10000" >> "${file}"               # Bash history (memory scroll back)
    sed -i 's/^HISTSIZE=.*/HISTSIZE=10000/' "${file}"
    grep -q "HISTFILESIZE" "${file}" \
        || echo "HISTFILESIZE=10000" >> "${file}"           # Bash history (file .bash_history)
    sed -i 's/^HISTFILESIZE=.*/HISTFILESIZE=10000/' "${file}"

    # If last line of file not blank, add a blank spacer line
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


function install_bash_completion() {
    apt -y -qq install bash-completion
    file=/etc/bash.bashrc
    sed -i '/# enable bash completion in/,+7{/enable bash completion/!s/^#//}' "${file}"

}


# TODO: Test these for bugs
configure_bash_systemwide
install_bash_completion


# ====[ Install default interfaces config ]======
file=/etc/network/interfaces
# TODO: add check if iface eth0 is already present
cat <<EOF >> "${file}"
allow-hotplug eth0
auto eth0
iface eth0 inet dhcp
#iface eth0 inet static
#    address 192.168.
#    netmask 255.255.255.0
#    broadcast .0.255
#    gateway
#    network
EOF


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
  echo -e "${GREEN}[*] Kali Base Setup Completed Successfully ${YELLOW} --( Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes )--\n${RESET}"
  echo -e "${YELLOW}[*] NOTE: ${RESET}If you have font errors after update, run: apt --reinstall install fonts-cantarell"
}
# End of script
trap finish EXIT

