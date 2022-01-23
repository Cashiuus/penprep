#!/usr/bin/env bash
## =======================================================================================
# File:     file.sh
# Author:   Cashiuus
# Created:  20-Jan-2022     Revised:
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Describe script purpose
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
APP_PATH=$(readlink -f $0)              # Absolute path and filename
APP_BASE=$(dirname "${APP_PATH}")       # Absolute path to directory
APP_NAME=$(basename "${APP_PATH}")      # Filename with extension


## ========================================================================== ##
# ================================[  BEGIN  ]================================ #


echo -e "app path: ${APP_PATH}"
echo -e "app base: ${APP_BASE}"
echo -e "app name: ${APP_NAME}"




## ========================================================================== ##
