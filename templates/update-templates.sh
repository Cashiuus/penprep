#!/usr/bin/env bash
## =============================================================================
# File:     update-templates.sh
#
# Author:   Cashiuus
# Created:  16-Oct-2020
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Simply copy/update my sync'ed templates onto current system.
#
#
## =============================================================================
__version__="1.2"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
SCRIPT_DIR=$(readlink -f $0)
APP_BASE=$(dirname ${SCRIPT_DIR})
BACKUPS_DIR="${HOME}/Backups/dotfiles"


# =============================[ BEGIN ]================================ #
cd "${APP_BASE}"

# Enable copying/moving of hidden files
shopt -s dotglob

echo -e "${GREEN}[*] ${RESET}Copying templates over now.."

# Geany IDE/Editor templates
dir="${HOME}/.config/geany/templates/files"
mkdir -p "${dir}"
cp "${APP_BASE}"/geany/* "${dir}/"

echo -e "${GREEN}[*] ${RESET}Finished copying, goodbye!"
exit 0
