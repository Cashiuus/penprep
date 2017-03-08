#!/bin/bash
## =============================================================================
# File:     setup-kali-base.sh
#
# Author:   Cashiuus
# Created:  27-Jan-2016  - Revised: 21-Feb-2017
#
# Purpose:  Setup bare bones kali with reasonable default options & packages
#           This script will perform a required reboot if vm-tools is not installed.
#
## =============================================================================
__version__="0.4"
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
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"

## =======[ EDIT THESE SETTINGS ]======= ##
# Modify these setting to your liking to fit your directory style
GIT_BASE_DIR="/opt/git"
GIT_DEV_DIR="${HOME}/git"
# Set of custom directories to create within ~ and /opt/
# "~/git/" is for git projects that you don't want in /opt/git/
# "~/git-dev/" is for your own git development projects
CREATE_USER_DIRECTORIES=(Backups engagements git git-dev pendrop .virtualenvs workspace)
CREATE_OPT_DIRECTORIES=(git pentest)


# =============================[  BEGIN APPLICATION  ]================================ #
xset s 0 0
xset s off

# Adjust timeout before starting because lock screen has caused issues during upgrade
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
# https://github.com/vmware/open-vm-tools
if [[ ! $(which vmware-toolbox-cmd) ]]; then
  echo -e "${YELLOW}[INFO] Now installing vm-tools. This will require a reboot. Re-run script after reboot...${RESET}"
  sleep 4
  $SUDO apt-get -y install open-vm-tools-desktop fuse
  $SUDO reboot
fi


# (Re-)configure hostname
echo -e -n "${GREEN}[+]${RESET}"
read -e -t 10 -p " Enter new hostname or just press enter : " RESPONSE
echo -e
if [[ $RESPONSE != "" ]]; then
    $SUDO hostname $RESPONSE
    echo "$response" > /etc/hostname
fi

# =============================[ Dotfiles ]================================ #
if [[ -d "${APP_BASE}/../../dotfiles" ]]; then
  echo -e -n "${GREEN}[+]${RESET}"
  read -e -t 5 -i "Y" -p " Perform simple install of dotfiles? [Y,n] : " RESPONSE
  echo -e

  case $response in
    [Yy]* ) source "${APP_BASE}/../../dotfiles/install_simple.sh";;
  esac
  #if [[ $RESPONSE == "Y" ]]; then
  #  source "${APP_BASE}/../../dotfiles/install_simple.sh"
  #fi
fi

# =============================[ APT Packages ]================================ #
# Change the apt/sources.list repository listings to just a single entry:
echo -e "${GREEN}[*] ${RESET}Restting sources.list to the 2 preferred kali entries"
echo "\n# kali-rolling" | $SUDO tee /etc/apt/sources.list
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

echo -e "${GREEN}[*] ${RESET}Issuing apt-get update and dist-upgrade, please wait..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y dist-upgrade
$SUDO apt-get -y install build-essential curl locate sudo gcc git make
$SUDO apt-get -y install htop sysv-rc-conf

# Kali metapackages we want installed in case they already aren't
$SUDO apt-get -y install kali-linux-pwtools kali-linux-sdr kali-linux-top10 \
  kali-linux-voip kali-linux-web kali-linux-wireless

# Extra packages - just in case they are missing
$SUDO apt-get -y install armitage arp-scan beef-xss dirb dirbuster exploitdb \
  mitmproxy nikto openssh-server openssl proxychains rdesktop responder \
  screen shellter sqlmap tmux tshark vlan whatweb wifite windows-binaries wpscan yersinia zsh

# =============================[ System Configurations]================================ #
# Configure Static IP
#read -n 5 -p "[+] Enter static IP Address or just press enter for DHCP : " -e response
#if [[ $response != "" ]]; then
#    # do stuff
#   ip addr add ${response}/24 dev eth0 2>/dev/null
#fi


if [[ ${GDMSESSION} == 'default' ]]; then
  echo -e "${GREEN}[*] ${RESET}Reconfiguring GNOME and related app settings"

  # Top bar
  gsettings set org.gnome.desktop.interface clock-show-date true                    # Default: false

  # ====[ Configure - Default GNOME Terminal ]==== #
  gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_type transparent
  gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_darkness 0.95

  # ====[ Configure - Nautilus ]==== #
  gsettings set org.gnome.nautilus.desktop home-icon-visible true                   # Default: false
  dconf write /org/gnome/nautilus/preferences/show-hidden-files true
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
  gsettings set org.gnome.nautilus.preferences search-view 'list-view'              # Default: 'icon-view'
  gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small'             # Choices: small, standard,
  #gsettings set org.gnome.nautilus.icon-view thumbnail-size 54                      # Default: 64
  gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'type', 'date_modified']"
  gsettings set org.gnome.nautilus.list-view default-column-order "['name', 'date_modified', 'size', 'type']"
  gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'             # Default: 'standard'
  gsettings set org.gnome.nautilus.list-view use-tree-view true                     # Default: false
  gsettings set org.gnome.nautilus.preferences sort-directories-first true          # Default: false
  gsettings set org.gnome.nautilus.window-state sidebar-width 160                   # Default: 188
  gsettings set org.gnome.nautilus.window-state start-with-sidebar true             # Default: true
  gsettings set org.gnome.nautilus.window-state maximized false                     # Default: false

  # Find your mouse's back button by running: xev | grep ', button' and right-clicking in the black box
  #gsettings set org.gnome.nautilus.preferences mouse-back-button 8                  # Default: 8

  # ====[ Configure - Gedit ]==== #
  echo -e "${GREEN}[*]${RESET} Configuring Gedit gsettings"
  gsettings set org.gnome.gedit.preferences.editor auto-indent true                 # Default: false
  gsettings set org.gnome.gedit.preferences.editor auto-save false                  # Default: true
  gsettings set org.gnome.gedit.preferences.editor create-backup-copy false         # Default: true
  gsettings set org.gnome.gedit.preferences.editor display-line-numbers true        # Default: false
  gsettings set org.gnome.gedit.preferences.editor display-right-margin true        # Default: false
  gsettings set org.gnome.gedit.preferences.editor editor-font "'Monospace 10'"     # Default: Monospace 12
  gsettings set org.gnome.gedit.preferences.editor ensure-trailing-newline true     # Default: true
  gsettings set org.gnome.gedit.preferences.editor insert-spaces true               # Default: false
  gsettings set org.gnome.gedit.preferences.editor right-margin-position 90         # Default: 80
  gsettings set org.gnome.gedit.preferences.editor scheme 'classic'                 # Default: 'classic'
  gsettings set org.gnome.gedit.preferences.editor syntax-highlighting true         # Default: true
  gsettings set org.gnome.gedit.preferences.editor tabs-size 4                      # Default: 8
  gsettings set org.gnome.gedit.preferences.ui bottom-panel-visible true            # Default: false
  gsettings set org.gnome.gedit.preferences.ui side-panel-visible true              # Default: false
  gsettings set org.gnome.gedit.preferences.ui toolbar-visible true                 # Default: true
  gsettings set org.gnome.gedit.state.window side-panel-size 150                    # Default: 200

  # Modify the default "favorite apps"
  gsettings set org.gnome.shell favorite-apps \
    "['org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'firefox-esr.desktop', 'kali-burpsuite.desktop', 'kali-armitage.desktop', 'kali-msfconsole.desktop', 'kali-maltego.desktop', 'kali-beef.desktop', 'kali-faraday.desktop', 'geany.desktop']"

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
echo -e "${GREEN}[*] ${RESET}Creating extra directories for pentester setup"
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

# ===============[ Symlinks ]=============
echo -e "${GREEN}[*] ${RESET}Adding extra symlinks"
ln -s /usr/share/wordlists /wordlists



# =====[ Metasploit ]===== #
# Another one is msfdb reinit to re-run initialization
echo -e "${GREEN}[*] ${RESET}Initializing Metasploit and moving config to '~/.msf4/database.yml'"
msfdb init
mv /usr/share/metasploit-framework/config/database.yml ${HOME}/.msf4/database.yml

cat << EOF > ~/.msf4/msfconsole.rc
# Disabling this because I believe msf locates the .yml file automatically in this path.
#db_connect -y ${HOME}/.msf4/database.yml
spool ${HOME}/.msf4/logs/console.log
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
# TODO: add check if iface eth0 is already present & verify this is working correctly
grep -q '^auto eth0' "${file}" \
  || cat <<EOF >> "${file}"

allow-hotplug eth0
auto eth0
iface eth0 inet dhcp
#iface eth0 inet static
#    address 192.168.
#    netmask 255.255.255.0
#    broadcast .255
#    gateway
#    network
EOF


# ===================================[ FINISH ]====================================== #
function finish {
  echo -e "\n\n${GREEN}[*]${RESET} ${GREEN}Cleaning${RESET} the system"
  #--- Clean package manager
  echo -e "\n\n${GREEN}[*] ${RESET}Issuing apt clean and purge for all removed pkgs"
  for FILE in clean autoremove; do apt -y -qq "${FILE}"; done
  # Removed -y -qq from this for testing, believe important dependencies are being removed here.
  apt -y purge $(dpkg -l | tail -n +6 | egrep -v '^(h|i)i' | awk '{print $2}')   # Purged packages
  #--- Reset folder location
  cd ~/ &>/dev/null
  #--- Remove any history files (as they could contain sensitive info)
  history -c 2>/dev/null
  for i in $(cut -d: -f6 /etc/passwd | sort -u); do
    [ -e "${i}" ] && find "${i}" -type f -name '.*_history' -delete
  done
  echo -e "\n\n${GREEN}[+]${RESET} ${GREEN}Updating${RESET} the locate database"
  updatedb

  FINISH_TIME=$(date +%s)
  echo -e "${GREEN}[*] Kali Base Setup Completed Successfully ${YELLOW} --(Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)--\n${RESET}"
  echo -e "${YELLOW}[*] NOTE: ${RESET}If you have font errors after update, run: apt --reinstall install fonts-cantarell"
}
# End of script
trap finish EXIT

