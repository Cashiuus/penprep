#!/usr/bin/env bash
## =======================================================================================
# File:     htb-bootstrap.sh
# Author:   Cashiuus
# Created:  08-Apr-2020     Revised: 14-Apr-2020
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Run this script on new Kali images to automatically configure and
#           install packages needed for HackTheBox challenges. Spend your time
#           hacking and learning, not troubleshooting!
#
#
# Oneliner: wget -qO bootstrap-htb.sh https://raw.githubusercontent.com/Cashiuus/penprep/master/system-setup/kali/bootstrap-htb.sh && bash bootstrap-htb.sh
#
# Shorter: curl -sSL https://raw.githubusercontent.com/Cashiuus/penprep/master/system-setup/kali/bootstrap-htb.sh | bash
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="1.0"
__author__="Cashiuus"
## =======[ EDIT THESE SETTINGS ]======= ##

CREATE_USER_DIRECTORIES=(git htb vpn)
CREATE_OPT_DIRECTORIES=()
VPN_BASE_DIR="${HOME}/vpn"

## ==========[ TEXT COLORS ]============= ##
# [http://misc.flogisoft.com/bash/tip_colors_and_formatting]
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
ORANGE="\033[38;5;208m" # Debugging
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## =============[ CONSTANTS ]============= ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LINES=$(tput lines)
COLS=$(tput cols)
HOST_ARCH=$(dpkg --print-architecture)      # (e.g. output: "amd64")

## ========================================================================== ##
# ================================[  BEGIN  ]================================ #
function install_sudo() {
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get..."
  echo -e "\n${GREEN}[INPUT]${RESET} Enter root password below"
  su -c "apt-get -y install sudo" root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo via apt-get${RESET}" && exit 1

  echo -e "\n${GREEN}[INPUT]${RESET} Adding user ${BLUE}${INSTALL_USER}${RESET} to sudo group. Enter root password below"
  su -c "usermod -a -G sudo ${INSTALL_USER}" root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "\n\n${YELLOW}[WARN]${RESET} Rebooting system to take effect!"
  echo -e "${YELLOW}[INFO]${RESET} Restart this script after login!\n\n"
  sleep 5s
  su -c "init 6" root
  exit 0
}


function print_banner() {
  clear
  cat << "EOF"

               . - ' - .
          _ - '          ' - _
      ▓ |                      | ▓
      ▓ |  --- '               | ▓
      ▓ |  |                   | ▓
      ▓ |  |              .    | ▓
      ▓ |               .;;............ ..
      ▓ |  |          .::;;::::::::::::..
      ▓ |  |           ':;;:::::::::::: . .
      ▓ |  |             ':    | ▓
      ▓ |  |                   | ▓
      ▓ :   '                  : ▓
       ▓ \   '     TMC        / ▓
        ▓ \   '              / ▓
         ▓ \   '            / ▓
          ▓ `\            /` ▓
            ▓ `\        /` ▓
              ▓ `\    /` ▓
                 ▓ \/ ▓
                   ▀▀
EOF
  echo -e "\n\n${BLUE}. . . . ${RESET}${BOLD}HackTheBox Base Kali Bootstrapper  ${RESET}${BLUE}. . . .${RESET}"
  echo -e "${BLUE}---------------------------------------------------${RESET}"
}
print_banner
echo -e "\n${BLUE}[$(date +"%F %T")] ${RESET}Giving Kali a tune-up, please wait..."

function check_root() {
  if [[ $EUID -ne 0 ]]; then
    # If not root, check if sudo package is installed
    if [[ $(which sudo) ]]; then
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
      export SUDO="sudo"
      echo -e "${YELLOW}[WARN] This script leverages sudo for installation. Enter your password when prompted!${RESET}"
      sleep 1
      # Test to ensure this user is able to use sudo
      sudo -l >/dev/null
      if [[ $? -eq 1 ]]; then
        # sudo pkg is installed but current user is not in sudoers group to use it
        echo -e "${RED}[ERROR]${RESET} You are not able to use sudo. Running install to fix."
        read -r -t 5
        install_sudo
      fi
    else
      echo -e "${YELLOW}[WARN]${RESET} The 'sudo' package is not installed."
      echo -e "${YELLOW}[+]${RESET} Press any key to install it (*You'll be prompted to enter sudo password). Otherwise, manually cancel script now..."
      read -r -t 5
      install_sudo
    fi
  fi
}
check_root
# =============================[ Setup VM Tools ]================================ #
# https://github.com/vmware/open-vm-tools
if [[ ! $(which vmware-toolbox-cmd) ]]; then
  echo -e "\n${YELLOW}[WARN] Now installing vm-tools. This will require a reboot. Re-run script after reboot...${RESET}"
  sleep 2
  $SUDO apt-get -y -qq install open-vm-tools-desktop fuse
  echo -e "${YELLOW}[WARN] Rebooting in 5 seconds, type CTRL+C to cancel..."
  sleep 5
  $SUDO reboot
fi

# ===========================[ Bash History Sizes ]============================== #
file="${HOME}/.bashrc"
sed -i 's/^HISTSIZE=.*/HISTSIZE=9000/' "${file}"
sed -i 's/^HISTFILESIZE=.*/HISTFILESIZE=9000/' "${file}"

if [[ ${GDMSESSION} == 'lightdm-xsession' ]]; then
  # Increasing terminal history scrolling limit
  file="${HOME}/.config/qterminal.org/qterminal.ini"
  [[ -s "${file}" ]] && sed -i 's/^HistoryLimitedTo=.*/HistoryLimitedTo=30000/' "${file}"
fi

# =============================[ APT Packages ]================================ #
# Change the apt/sources.list repository listings to just a single entry:
echo -e "\n${GREEN}[*] ${RESET}Resetting Aptitude sources.list to the 2 preferred kali entries"
file=/etc/apt/sources.list
[[ -e "${file}" ]] && $SUDO cp -n $file{,.bkup}
if [[ $SUDO ]]; then
  echo "# kali-rolling" | $SUDO tee /etc/apt/sources.list
  echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
else
  echo "# kali-rolling" > /etc/apt/sources.list
  echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
fi

echo -e "\n${GREEN}[*] ${RESET}Issuing apt-get update and dist-upgrade, please wait..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y -q -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" dist-upgrade

echo -e "\n${GREEN}[*] ${RESET}apt-get :: Installing core utilities"
$SUDO apt-get -y -qq install bash-completion build-essential curl locate gcc geany git \
  libssl-dev make net-tools openssl openvpn tmux wget

$SUDO apt-get -y -qq install geany htop sysv-rc-conf

echo -e "\n${GREEN}[*] ${RESET}apt-get :: Installing commonly used HTB tools"
$SUDO apt-get -y -qq install dirb dirbuster exploitdb libimage-exiftool-perl nikto \
  rdesktop responder shellter sqlmap windows-binaries

# Python
echo -e "\n${GREEN}[*] ${RESET}python :: Installing/Configuring Python"
$SUDO apt-get -y -qq install python python-dev python-setuptools virtualenv virtualenvwrapper || \
  echo -e "${YELLOW}[ERROR] Errors occurred installing Python 2.x, you may have issues${RESET}" \
  && sleep 2
# Currently issues with python-pip package so it's separate in case it fails
$SUDO apt-get -y -qq install python-pip

# Python 3
$SUDO apt-get -y -qq install python3 python3-dev python3-pip python3-setuptools || \
  echo -e "${YELLOW}[ERROR] Errors occurred installing Python 3.x, you may have issues${RESET}" \
  && sleep 2

# Pillow depends
$SUDO apt-get -y -qq install libtiff5-dev libjpeg62-turbo-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libffi-dev zlib1g-dev
# lxml depends
$SUDO apt-get -y -qq install libxml2-dev libxslt1-dev zlib1g-dev
# Postgresql and psycopg2 depends
$SUDO apt-get -y -qq install libpq-dev

# Install base pip files
file="/tmp/requirements.txt"
cat <<EOF > "${file}"
argparse
beautifulsoup4
colorama
dnspython
lxml
mechanize
netaddr
pefile
pep8
Pillow
psycopg2
pygeoip
python-Levenshtein
python-libnmap
requests
six
wheel
EOF
# In this case, we do not need to SUDO here
python -m pip install -q -r /tmp/requirements.txt

python3 -m pip install -q -r /tmp/requirements.txt


# =================[ Desktop Display Customizations ]================= #
if [[ ${GDMSESSION} == 'lightdm-xsession' ]]; then
  # Thunar file manager settings - make hidden files visible
  xfconf-query -n -c thunar -p /last-show-hidden -t bool -s true

  # Add quick launcher apps to top left
  mkdir -p ~/.config/xfce4/panel/launcher-{8,9,10,11}
  # Firefox
  ln -sf /usr/share/applications/firefox-esr.desktop ~/.config/xfce4/panel/launcher-8/browser.desktop
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-8 -t string -s launcher
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-8/items -t string -s "browser.desktop" -a
  # Burpsuite
  ln -sf /usr/share/applications/kali-burpsuite.desktop ~/.config/xfce4/panel/launcher-9/kali-burpsuite.desktop
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-9 -t string -s launcher
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-9/items -t string -s "kali-burpsuite.desktop" -a
  # Cherrytree
  ln -sf /usr/share/applications/cherrytree.desktop ~/.config/xfce4/panel/launcher-10/cherrytree.desktop
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-10 -t string -s launcher
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/items -t string -s "cherrytree.desktop" -a
  # Geany text editor / IDE
  ln -sf /usr/share/applications/geany.desktop ~/.config/xfce4/panel/launcher-11/geany.desktop
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-11 -t string -s launcher
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/items -t string -s "geany.desktop" -a

  xfconf-query -n -c xfce4-panel -p /plugins/plugin-12 -t string -s separator

fi


# ======================[ Folder Structure ]====================== #
echo -e "${GREEN}[*] ${RESET}Creating extra directories for our HackTheBox setup"
count=0
while [ "x${CREATE_USER_DIRECTORIES[count]}" != "x" ]; do
    count=$(( $count + 1 ))
done

# Create folders in ~
echo -e "${GREEN}[*]${RESET} Creating ${count} directories in current user's ${GREEN}HOME${RESET} directory path"
for dir in ${CREATE_USER_DIRECTORIES[@]}; do
    mkdir -p "${HOME}/${dir}"
done

count=0
while [ "x${CREATE_OPT_DIRECTORIES[count]}" != "x" ]; do
    count=$(( $count + 1 ))
done

# Create folders in /opt
#echo -e "${GREEN}[*]${RESET} Creating ${count} directories in /opt/ path"
for dir in ${CREATE_OPT_DIRECTORIES[@]}; do
    mkdir -p "/opt/${dir}"
done

mkdir -p ~/htb/{boxes,shells}


### Evil-WinRM install
echo -e "\n${GREEN}[*] ${RESET}Installing Evil-WinRM"
$SUDO apt-get -y -qq install rubygems
$SUDO gem install evil-winrm

### Python Impacket install
echo -e "\n${GREEN}[*] ${RESET}Installing Python Impacket collection"
cd ~/git
git clone https://github.com/SecureAuthCorp/impacket
cd impacket
$SUDO python setup.py install
$SUDO python3 setup.py install
# or $SUDO pip install . ?

### Additional git clones to grab
echo -e "\n${GREEN}[*] ${RESET}Grabbing Github projects that will be useful"
cd ~/git
git clone https://github.com/Tib3rius/AutoRecon
git clone https://github.com/danielmiessler/SecLists
git clone https://github.com/PowerShellMafia/PowerSploit
git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite PEASS


# Get common shells to use
echo -e "\n${GREEN}[*] ${RESET}Grabbing useful shells/backdoors"
cd ~/htb/shells/
git clone https://github.com/infodox/python-pty-shells
git clone https://github.com/epinna/weevely3
git clone https://github.com/eb3095/php-shell

# Init our rockyou wordlist
echo -e "\n${GREEN}[*] ${RESET}Decompressing the 'RockYou' wordlist"
$SUDO gunzip -d /usr/share/wordlists/rockyou.txt.gz


echo -e "${GREEN}[*] ${RESET}Installing VPN helper script to ~/vpn/vpn-helper.sh"
file="${VPN_BASE_DIR}/vpn-helper.sh"
#touch "${file}"
cat <<EOF > "${file}"
#!/bin/bash

VPN_BASE_DIR="\${HOME}/vpn"
GREEN="\\033[01;32m"
YELLOW="\\033[01;33m"
RESET="\\033[00m"

if [[ ! -s "\${VPN_BASE_DIR}/vpn-helper.conf" ]]; then
    echo -e "\n\n\${GREEN}[+] \${RESET}First time running? Find your .ovpn file in this list below:"
    echo -e "-----------------------[ \${HOME}/vpn/ ]-----------------------"
    ls -al "\${VPN_BASE_DIR}"
    echo -e "---------------------------------------------------------------"
    echo -e -n "\${YELLOW}[+]\${RESET}"
    read -e -p " Enter full path to your OpenVPN '.ovpn' file here: " RESPONSE
    while [[ ! -s "\${RESPONSE}" ]]; do
        echo -e -n "\${YELLOW}[-]\${RESET}"
        read -e -p " You've provided an invalid file, try again: " RESPONSE
    done
    echo "OVPN_FILE=\${RESPONSE}" > "\${VPN_BASE_DIR}/vpn-helper.conf"
else
    echo -e "\${GREEN}[*] \${RESET}Config file exists! If not correct, edit \${VPN_BASE_DIR}/vpn-helper.conf"
fi

echo -e "\n\${GREEN}[*] \${RESET}Ensuring your VPN config file is secured with proper permissions"
chmod 0600 "\${VPN_BASE_DIR}/vpn-helper.conf"
. "\${VPN_BASE_DIR}/vpn-helper.conf"

echo -e "\${GREEN}[*] \${RESET}Prep done, now launching OpenVPN with chosen .ovpn config"
openvpn --config "\${OVPN_FILE}" \\
    --script-security 2
EOF
chmod u+x "${file}"



function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  echo -e "${GREEN}[*] ${RESET}Cleaning up system and updating locate db"
  $SUDO apt-get -qq clean
  $SUDO apt-get -qq autoremove
  $SUDO updatedb

  echo -e "\n${GREEN}============================================================${RESET}"
  echo -e "\n Your system has now been configured! Here is some useful information:\n"
  echo -e "  Directories:\t\t${HOME}/htb/boxes/"
  echo -e "  \t\t\t${HOME}/htb/shells/"
  echo -e "\n  Place VPN Files here:\t${HOME}/vpn/"
  echo -e "  VPN Helper Script:\t${HOME}/vpn/vpn-helper.sh"
  echo -e "\n\n"
  echo -e "${GREEN}============================================================${RESET}"
  echo -e -n "\n${GREEN}[+]${RESET}Setup is complete. Please ${ORANGE}REBOOT${RESET} for desktop settings to take effect."
  sleep 10

  FINISH_TIME=$(date +%s)
  echo -e "\n${BLUE}[$(date +"%F %T")] ${GREEN}${APP_NAME} Completed Successfully ${RESET}-${ORANGE} (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)${RESET}\n"
}
# End of script
trap finish EXIT


## =================================================================================== ##
## =============================[  Help :: Core Notes ]=============================== ##
#
## =================================================================================== ##
