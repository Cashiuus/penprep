#!/bin/bash
## =============================================================================
# File:     setup-rvm.sh
#
# Author:   Cashiuus
# Created:  23-JUN-2016 - - - - - - (Revised: )
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Install the Ruby Version Manager (RVM) platform
#
# Ref: http://rvm.io/
## ========================================================================== ##
__version__="0.9"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
PURPLE="\033[01;35m"   # Other
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LOG_FILE="${APP_BASE}/debug.log"
# These can be used to know height (LINES) and width (COLS) of current terminal in script
LINES=$(tput lines)
COLS=$(tput cols)

#======[ ROOT PRE-CHECK ]=======#
if [[ $EUID -ne 0 ]];then
    if [[ $(dpkg-query -s sudo) ]];then
        export SUDO="sudo"
        # $SUDO - run commands with this prefix now to account for either scenario.
    else
        echo "Please install sudo or run this as root."
        exit 1
    fi
fi
## ========================================================================== ##
# ===============================[  BEGIN  ]================================== #

# Get signing key for the RVM distribution
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
# or: gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3


# Install RVM stable with Ruby
# backslash before curl is to prevent misbehaving if it's aliased with ~/.curlrc
\curl -sSL https://get.rvm.io | bash -s stable

# Add user to group rvm
# If user already exists: usermod -a -G rvm $USER
# If user doesn't yet exist: useradd -G rvm [username]

source /etc/profile.d/rvm.sh
#source ~/.rvm/scripts/rvm

# Fix Gnome terminal to play nice with RVM and launch as a login shell
gconftool-2 --set --type boolean /apps/gnome-terminal/profiles/Default/login_shell true

# Install the latest default version
rvm install ruby-head

ruby -v
rvm list known

echo -e "[*] Type: rvm install <version> - and install Ruby versions you need"
echo -e "[*] Type: rvm use <version> - to start using one now"
