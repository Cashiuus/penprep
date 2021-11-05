#!/usr/bin/env bash
## =======================================================================================
# File:     setup-vscode.sh
# Author:   Cashiuus
# Created:  12-Oct-2021     Revised:
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Setup VSCode
#
#
# Notes:
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#
#       https://computingforgeeks.com/how-to-install-visual-studio-code-on-kali-linux/
#       https://code.visualstudio.com/docs/setup/linux
#
#
#
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## =======[ EDIT THESE SETTINGS ]======= ##


## ==========[ TEXT COLORS ]============= ##
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



#======[ ROOT PRE-CHECK ]=======#
function install_sudo() {
  # If
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get, elevating to root..."

  su root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to su root${RESET}" && exit 1
  apt-get -y install sudo
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo pkg via apt-get${RESET}" && exit 1
  # Use stored USER value to add our originating user account to the sudoers group
  # TODO: Will this break if script run using sudo? Env var likely will be root if so...test this...
  #usermod -a -G sudo ${ACTUAL_USER}
  usermod -a -G sudo ${INSTALL_USER}
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "${YELLOW}[WARN] ${RESET}Now logging off to take effect. Restart this script after login!"
  sleep 4
  # First logout command will logout from su root elevation
  logout
  exit 1
}

function check_root() {

  # There is an env var that is $USER. This is regular user if in normal state, root in sudo state
  #   CURRENT_USER=${USER}
  #   ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
       # This would only be run if within sudo state
       # This variable serves as the original user when in a sudo state

  if [[ $EUID -ne 0 ]];then
    # If not root, check if sudo package is installed and leverage it
    # TODO: Will this work if current user doesn't have sudo rights, but sudo is already installed?
    if [[ $(dpkg-query -s sudo) ]];then
      export SUDO="sudo"
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
    else
      echo -e "${YELLOW}[WARN] ${RESET}The 'sudo' package is not installed. Press any key to install it (*must enter sudo password), or cancel now"
      read -r -t 10
      install_sudo
      # TODO: This error check necessary, since the function "install_sudo" exits 1 anyway?
      [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Please install sudo or run this as root. Exiting.${RESET}" && exit 1
    fi
  fi
}
check_root
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #



$SUDO apt -qq update
$SUDO apt -y install curl gpg software-properties-common apt-transport-https

file="/etc/apt/sources.list.d/vscode.list"
if [[ ! -f "${file}" ]]; then
    #curl -sSL https://packages.microsoft.com/keys/microsoft.asc | $SUDO apt-key add
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    $SUDO install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    $SUDO sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -rf packages.microsoft.gpg
    #echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | $SUDO tee /etc/apt/sources.list.d/vscode.list
fi

$SUDO apt -qq update
$SUDO apt -y install code       # or code-insiders









## ========================================================================== ##
