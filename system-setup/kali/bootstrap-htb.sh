#!/usr/bin/env bash
## =======================================================================================
# File:     htb-bootstrap.sh
# Author:   Cashiuus
# Created:  08-Apr-2020     Revised: 10-Apr-2020
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Run this script on new Kali images to automatically configure and
#           install packages needed for HackTheBox challenges. Spend your time
#           hacking and learning, not troubleshooting!
#
#
# Oneliner: wget -qO bootstrap-htb.sh https:://raw.githubusercontent.com/Cashiuus/penprep/master/system-setup/kali/bootstrap-htb.sh && bash bootstrap-htb.sh
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## =======[ EDIT THESE SETTINGS ]======= ##


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


CREATE_USER_DIRECTORIES=(git htb vpn)
CREATE_OPT_DIRECTORIES=()


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

function check_root() {
  if [[ $EUID -ne 0 ]]; then
    # If not root, check if sudo package is installed
    if [[ $(which sudo) ]]; then
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
      export SUDO="sudo"
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
sleep 3
exit
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

# =============================[ APT Packages ]================================ #
# Change the apt/sources.list repository listings to just a single entry:
echo -e "\n${GREEN}[*] ${RESET}Resetting Aptitude sources.list to the 2 preferred kali entries"
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
$SUDO export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y -q dist-upgrade
echo -e "\n${GREEN}[*] ${RESET}apt-get :: Installing core utilities"
$SUDO apt-get -y -qq install bash-completion build-essential curl locate gcc git \
  libssl-dev make net-tools openssl sudo tmux wget

$SUDO apt-get -y -qq install geany htop sysv-rc-conf

echo -e "\n${GREEN}[*] ${RESET}apt-get :: Installing commonly used htb tools"
$SUDO apt-get -y -qq install dirb dirbuster exploitdb libimage-exiftool-perl nikto \
  rdesktop responder shellter sqlmap windows-binaries


# Python
echo -e "\n${GREEN}[*] ${RESET}python :: Installing/Configuring Python"
$SUDO apt-get -y -qq install python python-dev python-pip virtualenv virtualenvwrapper
# Pillow depends
$SUDO apt-get -y -qq install libtiff5-dev libjpeg62-turbo-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libffi-dev zlib1g-dev

# lxml depends
$SUDO apt-get -y -qq install libxml2-dev libxslt1-dev zlib1g-dev

# Postgresql and psycopg2 depends
$SUDO apt-get -y -qq install libpq-dev

$SUDO pip install -q --upgrade pip
$SUDO pip install -q --upgrade setuptools
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
$SUDO pip install -q -r /tmp/requirements.txt


# =================[ Folder Structure ]================= #
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

mkdir -p ~/htb/boxes/
mkdir -p ~/htb/shells/


### Evil-WinRM install
echo -e "${GREEN}[*] ${RESET}Installing Evil-WinRM"
$SUDO apt-get -y -qq install rubygems
$SUDO gem install evil-winrm

### Python Impacket install
echo -e "${GREEN}[*] ${RESET}Installing Python Impacket collection"
cd ~/git
git clone https://github.com/SecureAuthCorp/impacket
cd impacket
$SUDO python setup.py install
# or $SUDO pip install . ?

### Additional git clones to grab
echo -e "${GREEN}[*] ${RESET}Grabbing Github projects that will be useful"
cd ~/git
git clone https://github.com/Tib3rius/AutoRecon
git clone https://github.com/danielmiessler/SecLists
git clone https://github.com/PowerShellMafia/PowerSploit
git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite PEASS


# Get common shells to use
echo -e "${GREEN}[*] ${RESET}Grabbing useful shells/backdoors"
cd ~/htb/shells/
git clone https://github.com/infodox/python-pty-shells
git clone https://github.com/epinna/weevely3
git clone https://github.com/eb3095/php-shell

# Init our rockyou wordlist
echo -e "${GREEN}[*] ${RESET}Decompressing the 'RockYou' wordlist"
$SUDO gunzip -d /usr/share/wordlists/rockyou.txt.gz


function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  $SUDO apt-get -qq clean
  $SUDO apt-get -qq autoremove
  $SUDO updatedb

  echo -e "\n${GREEN}============================================================${RESET}"
  echo -e "\n Your system has now been configured! Here is some useful information:\n"
  echo -e "  Directories:\t\t${HOME}/htb/boxes/"
  echo -e "  \t\t\t${HOME}/htb/shells/"
  echo -e "\n  Place VPN Files here:\t${HOME}/vpn/"
  echo -e "\n\n"
  echo -e "${GREEN}============================================================${RESET}"
  echo -e "\n"
  read -e -t 10 -p " Press ENTER to finish and close the script..." RESPONSE

  FINISH_TIME=$(date +%s)
  echo -e "${BLUE}[$(date +"%F %T")] ${GREEN}${APP_NAME} Completed Successfully ${RESET}-${ORANGE} (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)${RESET}\n"
}
# End of script
trap finish EXIT


## ===================================================================================== ##
## ==============================[  Help :: Core Notes ]================================ ##
#
## -=====[  Notable Commands  ]=====- ##
#
#

# sqlmap -r login.req --level 5 --risk 3





#tmux new -s HTB
# allows multiple windows with keyboard
# learn tmux shortcuts
## ==================================================================================== ##
