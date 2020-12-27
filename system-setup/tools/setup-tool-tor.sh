#!/usr/bin/env bash
## =======================================================================================
# File:     setup-tool-tor.sh
# Author:   Cashiuus
# Created:  09-Oct-2020     Revised:
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Describe script purpose
#
#
# Notes:
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


$SUDO echo 'deb https://deb.torproject.org/torproject.org stretch main' > /etc/apt/sources.list.d/tor.list
$SUDO echo 'deb-src https://deb.torproject.org/torproject.org stretch main' >> /etc/apt/sources.list.d/tor.list

wget -O- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | sudo apt-key add -

$SUDO apt-get -qq update

$SUDO apt-get -y install tor deb.torproject.org-keyring






## ========================================================================== ##
