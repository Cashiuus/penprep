#!/usr/bin/env bash
## =======================================================================================
# File:     setup.sh
# Author:   Cashiuus
# Created:  09-May-2017     Revised: 28-Jul-2021
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Setup our linux environment so that thermo-recon works.
#
#
# Notes:
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#
#   EyeWitness Setup: https://github.com/FortyNorthSecurity/EyeWitness/blob/master/Python/setup/setup.sh
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.2"
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
LOG_FILE="${APP_BASE}/debug.log"
DEBUG=true
DO_LOGGING=false


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
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #

echo '${GREEN}[*]${RESET} Installing OS Dependencies'
$SUDO apt-get -qq update

# --[ OS Check ]--
OS_TYPE=$(lsb_release -sd | awk '{print 1}')
echo -e "${GREEN}[*]${RESET} Your current OS: $OS_TYPE"
if [[ "$OS_TYPE" = "Kali" || "$OS_TYPE" = "Debian" ]]; then
  $SUDO apt-get -y install cmake firefox-esr python3 python3-pip python-netaddr \
    python3-dev tesseract-ocr xvfb x11utils
  $SUDO apt-get -y install eyewitness
elif [[ "$OS_TYPE" = "Ubuntu" ]]; then
  $SUDO apt-get -y install cmake firefox python3 python3-pip python-netaddr \
  python3-dev tesseract-ocr x11utils
elif [[ "$OS_TYPE" = "Alpine" ]]; then
  # Here are the basics for Alpine. Ref the setup link at top for full setup.
  $SUDO apk update
  $SUDO apk add cmake firefox python3 python3-dev py-netaddr py-pip xvfb
else
  echo -e "${RED}[ERR]${RESET} OS Not recognized or unsupported. Exiting script!"
  exit 1
fi


echo '${GREEN}[*] Installing Python Modules${RESET}'
pip3 install --upgrade pip
python3 -m pip install fuzzywuzzy
python3 -m pip install selenium --upgrade
python3 -m pip install python-Levenshtein
python3 -m pip install pyvirtualdisplay
python3 -m pip install netaddr


if [[ ! "$OS_TYPE" = "Kali" && ! "$OS_TYPE" = "Debian" ]]; then
  mkdir -p ~/git && cd ~/git
  git clone https://github.com/FortyNorthSecurity/EyeWitness
  # symlinks must specify full paths, don't use '.'
  ln -s "${HOME}/git/EyeWitness/Python/EyeWitness.py" "${HOME}/.local/bin/eyewitness"
fi

# I've noticed personally that geckodriver version 0.19 is buggy and will often fail
# due to a bind port failure error (can see this error in geckodriver.log file)
# Let's update to a better version. version 0.26 works with Firefox version >59.
#   Reference: https://github.com/FortyNorthSecurity/EyeWitness/blob/master/setup/setup.sh
cd /tmp
if [ ${HOST_ARCH} == 'amd64' ]; then
  wget https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-linux64.tar.gz
  tar -xvf geckodriver-v0.26.0-linux64.tar.gz
  rm geckodriver-v0.26.0-linux64.tar.gz
else
  wget https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-linux32.tar.gz
  tar -xvf geckodriver-v0.26.0-linux32.tar.gz
  rm geckodriver-v0.26.0-linux32.tar.gz
fi

$SUDO mv geckodriver /usr/sbin/
if [ -e /usr/bin/geckodriver ]; then
  $SUDO rm /usr/bin/geckodriver
fi
$SUDO ln -s /usr/sbin/geckodriver /usr/bin/geckodriver

## ==================================================================================== ##



