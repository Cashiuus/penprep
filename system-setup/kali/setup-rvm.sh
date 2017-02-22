#!/usr/bin/env bash
# ==============================================================================
# File:     setup-rvm.sh
#
# Author:   Cashiuus
# Created:  23-JUN-2016     -     Revised: 23-DEC-2016
#
#-[ Usage ]---------------------------------------------------------------------
#   Install the Ruby Version Manager (RVM) platform
#
#
#-[ Notes/Links ]---------------------------------------------------------------
#   - http://rvm.io/
#
#-[ References ]----------------------------------------------------------------
#
#
#-[ Copyright ]-----------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
# ==============================================================================
__version__="1.0"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
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
apt-get -qq update
apt-get -y install curl

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
if [[ $(which gnome-shell) ]]; then
    gconftool-2 --set --type boolean /apps/gnome-terminal/profiles/Default/login_shell true
fi

# Install the latest stable version
rvm install ruby-head

ruby -v
rvm list known

echo -e "\n\n${GREEN}[*]${RESET} Type: rvm install <version> - and install Ruby versions you need"
echo -e "${GREEN}[*]${RESET} Type: rvm use <version> - to start using one now"
echo -e "${GREEN}[*]${RESET} Set a default: rvm use <version> --default\n\n"

# Kali-style -- add source line to .bashrc
file=$HOME/.bashrc
# TODO: Improve this regex
grep -q '"/etc/profile.d/rvm.sh\" .*' "${file}"  2>/dev/null \
    || echo '[[ -s "/etc/profile.d/rvm.sh" ]] && source "/etc/profile.d/rvm.sh"' >> "${file}"

source ~/.bashrc
exit 0

### Clean out all traces of RVM
# https://rvm.io/support/troubleshooting
##!/bin/bash
#/usr/bin/sudo rm -rf $HOME/.rvm $HOME/.rvmrc /etc/rvmrc /etc/profile.d/rvm.sh /usr/local/rvm /usr/local/bin/rvm
#/usr/bin/sudo /usr/sbin/groupdel rvm
#/bin/echo "RVM is removed. Please check all .bashrc|.bash_profile|.profile|.zshrc for RVM source lines and delete
#or comment out if this was a Per-User installation."
