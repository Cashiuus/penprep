#!/usr/bin/env bash
## =======================================================================================
# File:     debian-updater.sh
#
# Author:   Cashiuus
# Created:  09-Mar-2017     Revised: 10-Apr-2017
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Basic update script you can place into cron for scheduled system updates.
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#
# Place this script in /etc/cron.weekly, ensure it is owned by root & has exec perms
#   e.g. chown root:root /etc/cron.weekly/updater.sh
#        chmod 700 /etc/cron.weekly/updater.sh
#
# To run weekly, place into /etc/cron.weekly/
# To run daily, place into /etc/cron.daily/
#
#-[ Links/Credit ]------------------------------------------------------------------------
#
#	https://github.com/rsreese/debian-update-script
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## ==========[ TEXT COLORS ]========== ##
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
## =============[ CONSTANTS ]============== ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_ARGS=$@
DEBUG=true
LOG_FILE="${APP_BASE}/debug.log"
# These can be used to know height (LINES) and width (COLS) of current terminal in script
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
function pause() {
  # Simple function to pause a script mid-stride
  #
  local dummy
  read -s -r -p "Press any key to continue..." -n 1 dummy
}


function asksure() {
  ###
  # Usage:
  #   if asksure; then
  #        echo "Okay, performing rm -rf / then, master...."
  #   else
  #        echo "Pfff..."
  #   fi
  ###
  echo -n "Are you sure (Y/N)? "
  while read -r -n 1 -s answer; do
    if [[ $answer = [YyNn] ]]; then
      [[ $answer = [Yy] ]] && retval=0
      [[ $answer = [Nn] ]] && retval=1
      break
    fi
  done
  echo # just a final linefeed, optics...
  return $retval
}

export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y -q dist-upgrade
$SUDO apt-get -y --purge autoremove
$SUDO apt-get -y clean
$SUDO updatedb
logger debian-updater.sh ran successfully. Rebooting system.
$SUDO init 6
exit 0
## ===================================================================================== ##
# List of Actions:
# Shell script to update Debian system via APT.
# Backup systems and send the backups to remote systems
# MySQL backup
# Encrypted backups available
# System information like disc usage, network traffic
# Log file output from syslog






