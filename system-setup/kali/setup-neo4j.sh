#!/usr/bin/env bash
## =======================================================================================
# File:     setup-neo4j.sh
#
# Author:   Cashiuus
# Revised:
# Created:  26-Jan-2017
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Add the repository in order to install and setup the Neo4j graphing tool.
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#   - Neo4j 3.x and greater requires Java 8, which does not come with the Neo4j package.
#
#
#
#-[ Links/Credit ]------------------------------------------------------------------------
#   - Neo4j Latest release is 3.1.1 - https://neo4j.com/download/community-edition/
#   - Debian notes - https://debian.neo4j.org/
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
PURPLE="\033[01;35m"    # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## ============[ CONSTANTS ]================ ##
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
#INSTALL_USER="user1"

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




wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -
echo 'deb https://debian.neo4j.org/repo stable/' | $SUDO tee /etc/apt/sources.list.d/neo4j.list
$SUDO apt-get -qq update
$SUDO apt-get -y install neo4j










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


function check_version_java() {
    ###
    #   Check the installed/active version of java
    #
    #   Usage: check_version_java
    #
    ###
    if type -p java; then
        echo found java executable in PATH
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
        echo found java executable in JAVA_HOME
        _java="$JAVA_HOME/bin/java"
    else
        echo "no java"
    fi

    if [[ "$_java" ]]; then
        version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo version "$version"
        if [[ "$version" > "1.5" ]]; then
            echo version is more than 1.5
        else
            echo version is less than 1.5
        fi
    fi
}


function make_tmp_dir() {
    # <doc:make_tmp_dir> {{{
    #
    # This function taken from a vmware tool install helper to securely
    # create temp files. (installer.sh)
    #
    # Usage: make_tmp_dir dirname prefix
    #
    # Required Variables:
    #
    #   dirname
    #   prefix
    #
    # Return value: null
    #
    # </doc:make_tmp_dir> }}}

    local dirname="$1" # OUT
    local prefix="$2"  # IN
    local tmp
    local serial
    local loop

    tmp="${TMPDIR:-/tmp}"

    # Don't overwrite existing user data
    # -> Create a directory with a name that didn't exist before
    #
    # This may never succeed (if we are racing with a malicious process), but at
    # least it is secure
    serial=0
    loop='yes'
    while [ "$loop" = 'yes' ]; do
    # Check the validity of the temporary directory. We do this in the loop
    # because it can change over time
    if [ ! -d "$tmp" ]; then
      echo 'Error: "'"$tmp"'" is not a directory.'
      echo
      exit 1
    fi
    if [ ! -w "$tmp" -o ! -x "$tmp" ]; then
      echo 'Error: "'"$tmp"'" should be writable and executable.'
      echo
      exit 1
    fi

    # Be secure
    # -> Don't give write access to other users (so that they can not use this
    # directory to launch a symlink attack)
    if mkdir -m 0755 "$tmp"'/'"$prefix$serial" >/dev/null 2>&1; then
      loop='no'
    else
      serial=`expr $serial + 1`
      serial_mod=`expr $serial % 200`
      if [ "$serial_mod" = '0' ]; then
        echo 'Warning: The "'"$tmp"'" directory may be under attack.'
        echo
      fi
    fi
    done

    eval "$dirname"'="$tmp"'"'"'/'"'"'"$prefix$serial"'
}


function is_process_alive() {
  # Checks if the given pid represents a live process.
  # Returns 0 if the pid is a live process, 1 otherwise
  #
  # Usage: is_process_alive 29833
  #   [[ $? -eq 0 ]] && echo -e "Process is alive"

  local pid="$1" # IN
  ps -p $pid | grep $pid > /dev/null 2>&1
}


function finish {
    ###
    # finish function
    # Any script-termination routines go here, but function cannot be empty
    #
    ###
    clear
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"
    # Redirect app output to log, sending both stdout and stderr
    # *NOTE: This method will not parse color codes, therefore fails color output
    # cmd_here 2>&1 | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT


## ==================================================================================== ##
## =================================[ Misc Notes ]===================================== ##
#
#By default you will install the latest Neo4j version. The repository also contains older versions. You can list the available versions with this command:

#   apt-cache madison neo4j

# To install a specific version:

#   sudo apt-get install neo4j=2.2.5
