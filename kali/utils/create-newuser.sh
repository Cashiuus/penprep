#!/bin/bash
# ==============================================================================
# File:     create-newuser.sh
#
# Author:   Cashiuus
# Created:  17-Jan-2016 - - - - - - (Revised: 13-MAY-2016)
#
# Purpose:  Quick script to setup a new user account with sudo privs so
#           I don't have to remember the appropriate way of doing it.
#
# NOTE:     Useful file for customizations may be in /etc/adduser.conf
## ========================================================================== ##
__version__="1.0"
__author__='Cashiuus'
SCRIPT_DIR=$(dirname $0)
## ===============[ Text Colors ]================ ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## ========================================================================== ##
# ===============================[  BEGIN  ]================================== #
apt-get -qq update
apt-get -y install sudo
echo -e "Enter new username: "
read NEW_USER_NAME
[[ ${NEW_UESR_NAME} == '' ]] && echo -e "Invalid, Try Again" && exit 1
# -m = create user's home directories if they do not exist. Files in /etc/skel will be copied
useradd -m ${NEW_USER_NAME}
passwd
echo -e "${GREEN}[*]${RESET} Adding user to sudoers..."
usermod -a -G sudo ${NEW_USER_NAME}
[[ $? -eq 0 ]] && echo -e "${GREEN}[*]${RESET} User ${BLUE}${NEW_USER_NAME}${RESET} has been successfully setup"
chsh -s /bin/bash ${NEW_USER_NAME}
