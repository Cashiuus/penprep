#!/usr/bin/env bash
## =======================================================================================
# File:     setup-kali-base.sh
# Author:   Cashiuus
# Created:  27-Jan-2016  - Revised: 19-Apr-2017
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Setup bare bones kali with reasonable default options & packages
#           This script will perform a required reboot if vm-tools is not installed.
#
#
# Notes:
#   - Setup defaults to DHCP networking with boilerplate text in 'interfaces' file.
#
#-[ Links/Credit ]------------------------------------------------------------------------
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="1.0"
__author__="Cashiuus"
## ==========[ TEXT COLORS ]============= ##
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
PURPLE="\033[01;35m"    # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## =============[ CONSTANTS ]============= ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_ARGS=$@
DEBUG=false
LOG_FILE="${APP_BASE}/debug.log"

## =======[ EDIT THESE SETTINGS ]======= ##
# Modify these setting to your liking to fit your directory style
GIT_BASE_DIR="/opt/git"
GIT_DEV_DIR="${HOME}/git"
# Set of custom directories to create within ~ and /opt/
# "~/git/" is for git projects that you don't want in /opt/git/
# "~/git-dev/" is for your own git development projects
CREATE_USER_DIRECTORIES=(Backups engagements git git-dev pendrop .virtualenvs workspace)
CREATE_OPT_DIRECTORIES=(git pentest)


## =============================[ Load Helpers ]============================= ##
if [[ -s "${APP_BASE}/../common.sh" ]]; then
    source "${APP_BASE}/../common.sh"
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source common :: success${RESET}"
else
    echo -e "${RED} [ERROR]${RESET} common.sh functions file is missing."
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source common :: fail${RESET}"
    exit 1
fi
## ========================================================================== ##


# ==========================[  BEGIN APPLICATION  ]=========================== #
xset s 0 0
xset s off

# Adjust timeout before starting because lock screen has caused issues during upgrade
gsettings set org.gnome.desktop.session idle-delay 0


function print_banner() {
    echo -e "\n${BLUE}=============[  ${RESET}${BOLD}Kali 2017 Base Pentest Installer  ${RESET}${BLUE}]=============${RESET}"
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
# TODO: Need to also update /etc/hosts to avoid host lookup errors later.
#echo -e -n "${GREEN}[+]${RESET}"
#read -e -t 10 -p " Enter new hostname or just press enter : " RESPONSE
#echo -e
#if [[ $RESPONSE != "" ]]; then
#    $SUDO hostname $RESPONSE
#    echo "$response" > /etc/hostname
#fi

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
echo -e "${GREEN}[*] ${RESET}Resetting sources.list to the 2 preferred kali entries"
if [[ $SUDO ]]; then
  echo "# kali-rolling" | $SUDO tee /etc/apt/sources.list
  echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
else
  echo "# kali-rolling" > /etc/apt/sources.list
  echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
fi

echo -e "${GREEN}[*] ${RESET}Issuing apt-get update and dist-upgrade, please wait..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y upgrade
# TODO: Skipping for now because XFCE dist upgrade causes black screen of death loops
$SUDO apt-get -y -q dist-upgrade
$SUDO apt-get -y install bash-completion build-essential curl locate gcc git make net-tools sudo
# Extra Packages - Utilities
$SUDO apt-get -y install geany htop sysv-rc-conf

# Kali metapackages we want installed in case they already aren't
$SUDO apt-get -y install kali-linux-pwtools kali-linux-sdr kali-linux-top10 \
  kali-linux-voip kali-linux-web kali-linux-wireless

# Extra packages - just in case they are missing
$SUDO apt-get -y install armitage arp-scan beef-xss dirb dirbuster exploitdb \
  mitmproxy nikto openssh-server openssl proxychains rdesktop responder \
  screen shellter sqlmap swftools tmux tshark vlan whatweb wifite windows-binaries \
  wpscan yersinia zsh


# =============================[ System Configurations]================================ #
# Configure Static IP
#read -n 5 -p "[+] Enter static IP Address or just press enter for DHCP : " -e response
#if [[ $response != "" ]]; then
#    # do stuff
#   ip addr add ${response}/24 dev eth0 2>/dev/null
#fi


if [[ ${GDMSESSION} == 'default' ]]; then
  echo -e "${GREEN}[*] ${RESET}Reconfiguring GNOME and related app settings"
  # ====[ Configure - Top bar ]==== #
  gsettings set org.gnome.desktop.datetime automatic-timezone true
  gsettings set org.gnome.desktop.interface clock-show-date true                    # Default: false
  gsettings set org.gnome.desktop.interface clock-format '12h'                      # Default: 24h
  gsettings set org.gnome.desktop.interface toolbar-icons-size 'small'              # Default: 'large'

  # ====[ Configure - Default GNOME Terminal ]==== #
  gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_type transparent
  gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_darkness 0.95

  # ====[ Configure - Nautilus ]==== #
  gsettings set org.gnome.nautilus.desktop home-icon-visible true                   # Default: false
  dconf write /org/gnome/nautilus/preferences/show-hidden-files true
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
  gsettings set org.gnome.nautilus.preferences search-view 'list-view'              # Default: 'icon-view'
  gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small'             # Choices: small, standard,
  gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'type', 'date_modified']"
  gsettings set org.gnome.nautilus.list-view default-column-order "['name', 'date_modified', 'size', 'type']"
  gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'             # Default: 'standard'
  gsettings set org.gnome.nautilus.list-view use-tree-view true                     # Default: false
  # This setting no longer exists
  #gsettings set org.gnome.nautilus.preferences sort-directories-first true          # Default: false
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

  # ====[ Configure - Default GNOME Terminal ]==== #
  gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_type transparent
  gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_darkness 0.95

  # Modify the default "favorite apps"
  gsettings set org.gnome.shell favorite-apps \
    "['org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'firefox-esr.desktop', 'kali-burpsuite.desktop', 'kali-armitage.desktop', 'kali-msfconsole.desktop', 'kali-maltego.desktop', 'kali-beef.desktop', 'kali-faraday.desktop', 'geany.desktop']"

elif [[ ${GDMSESSION} == 'lightdm-xsession' ]]; then
  echo -e "${YELLOW}[INFO]${RESET} Light Desktop Manager detected, skipping GNOME tweaks..."
  dconf write /org/gnome/nautilus/preferences/show-hidden-files true
  # Configure Thunar File Browser
  xfconf-query -n -c thunar -p /last-show-hidden -t bool -s true
  xfconf-query -n -c thunar -p /last-details-view-column-widths -t string -s "50,133,50,50,178,50,50,73,70"
  xfconf-query -n -c thunar -p /last-view -t string -s "ThunarDetailsView"

  # Configure XFCE4 Terminal defaults in its config file
  file="${HOME}/.config/xfce4/terminal/terminalrc"
  if [[ -s "${file}" ]]; then
    # TODO: Not sure if this file is present on a vanilla install and/or if
    # these 'scrolling' settings were only present because I had tweaked them.
    sed -i 's/^ScrollingLines=.*/ScrollingLines=9000/' "${file}"
    sed -i 's/^ScrollingOnOutput=.*/ScrollingOnOutput=FALSE/' "${file}"
    echo "FontName=Monospace 11" >> "${file}"
    echo "BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT" >> "${file}"
    echo "BackgroundDarkness=0.970000" >> "${file}"
  else
    mkdir -p "${HOME}/.config/xfce4/terminal/"
    cat <<EOF > "${file}"


EOF
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
echo -e "${GREEN}[*] ${RESET}Initializing Metasploit"
msfdb init
sleep 3s

# NOTE: Another method of init is doing: msfdb reinit
# NOTE: Another method of loading a metasploit config .yml file:
#   $SUDO sh -c "echo export MSF_DATABASE_CONFIG=/opt/metasploit-framework/config/database.yml >> /etc/profile"

echo -e "${GREEN}[*] ${RESET} Moving MSF config file to '~/.msf4/database.yml'"
mv /usr/share/metasploit-framework/config/database.yml ${HOME}/.msf4/database.yml

cat << EOF > ~/.msf4/msfconsole.rc
# Disabling this because I believe msf locates the .yml file automatically in this path.
#db_connect -y ${HOME}/.msf4/database.yml
spool ${HOME}/.msf4/logs/console.log

load auto_add_route
load alias
alias del rm
alias handler use exploit/multi/handler

setg LHOST 0.0.0.0
setg LPORT 443

setg TimestampOutput true
setg VERBOSE true
setg ExitOnSession false
setg EnableStageEncoding true

EOF


function configure_bash_systemwide() {
  ### BASH HISTORY DIRECTIVES
  #   HISTSIZE              Bash command history (Default: 500)
  #   HISTFILESIZE          No. lines the .bash_history file will contain max (Default: 500)
  #   HISTFILE              Change history file (rarely used)
  #   HISTTIMEFORMAT        Enable timestamps with each history entry
  #                           (e.g. HISTTIMEFORMAT="%h %d %H:%M:S ")
  #   shopt -s histappend   Append to .bash_history instead of overwrite every session
  #   HISTCONTROL           Control how commands are saved or filtered to history
  #                           export HISTCONTROL=ignoredups:erasedups
  #   HISTIGNORE            Patterns to decide which commands to save/ignoredups
  #                           Ex1: Don't save ls,ps,history cmds: HISTIGNORE="ls:ps:history"
  #                           Ex2: Don't save cmds starting with 's': HISTIGNORE="s*"
  #   shopt -s cmdhist      Store multi-line commands in history as one entry.

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


# ==========[ Configure GIT ]=========== #

echo -e "${GREEN}[+]${RESET} Now setting up Git, you will be prompted to enter your name for commits."


# Git Aliases Ref: https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases
# Other settings/standard alias helpers
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status

# Create custom unstage alias - Type: git unstage fileA (same as: git reset HEAD -- fileA)
git config --global alias.unstage 'reset HEAD --'

# Show the last commit (Type: git last)
git config --global alias.last 'log -1 HEAD'

# My Custom Git Aliases
# TODO: Test if this works correctly, it should simply add --recursive to every clone
# The reason for --recursive is for git projects with submodules, which don't clone by default
git config --global alias.clone 'clone --recursive'


# Other alias ideas:
#   https://majewsky.wordpress.com/2010/11/29/tip-of-the-day-dont-remember-git-clone-urls/

# Git short status
git config --global alias.s 'status -s'


# ===================================[ FINISH ]====================================== #
function finish() {
  echo -e "\n\n${GREEN}[*]${RESET} ${GREEN}Cleaning${RESET} the aptitude pkg system"
  #--- Clean package manager
  echo -e "\n\n${GREEN}[*] ${RESET}Issuing apt clean and purge for all removed pkgs"
  for FILE in clean autoremove; do $SUDO apt -y -qq "${FILE}"; done
  # Removed -y -qq from this for testing, believe important dependencies are being removed here.
  $SUDO apt -y purge $(dpkg -l | tail -n +6 | egrep -v '^(h|i)i' | awk '{print $2}')   # Purged packages
  #--- Reset folder location
  cd ~/ &>/dev/null
  #--- Remove any history files (as they could contain sensitive info)
  history -c 2>/dev/null
  for i in $(cut -d: -f6 /etc/passwd | sort -u); do
    [ -e "${i}" ] && find "${i}" -type f -name '.*_history' -delete
  done
  echo -e "\n\n${GREEN}[+]${RESET} ${GREEN}Updating${RESET} the locate database"
  $SUDO updatedb

  FINISH_TIME=$(date +%s)
  echo -e
  echo -e "${YELLOW}[INFO] Misc Notes:${RESET}"
  echo -e "\t${YELLOW}[+]${RESET} Change passwords!"
  echo -e "\t${YELLOW}[+]${RESET} Setup Git: add your ~/.gitconfig and .gitexcludes files"
  echo -e "\t${YELLOW}[+]${RESET} Setup SSH: add your ~/.ssh/config file & any keys"
  echo -e "\t${YELLOW}[+]${RESET} Backup: Take Snapshot if in a VM!"
  echo -e "\t${YELLOW}[+]${RESET} Reboot System when able!"
  echo -e
  echo -e "${YELLOW}[INFO] Troubleshooting:${RESET}"
  echo -e "\t${YELLOW}[+]${RESET} If you have font errors after dist-upgrade, run: apt --reinstall install fonts-cantarell\n"
  #echo -e "\t${YELLOW}[+]${RESET} "
  echo -e
  echo -e "${BLUE} -=[ Penbuilder${RESET} :: ${BLUE}$APP_NAME ${BLUE}]=- ${GREEN}Completed Successfully ${RESET}-${ORANGE} (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)${RESET}\n"
}
# End of script
trap finish EXIT

