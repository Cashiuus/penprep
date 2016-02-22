#!/bin/bash
## =============================================================================
# File:     install.sh
#
# Author:   Cashiuus
# Created:  02/20/2016  - (Revised: )
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:
#
#
## =============================================================================
__version__="0.1"
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
DOTFILES_DIR="${HOME}/.dotfiles"
BACKUPS_DIR="${DOTFILES_DIR}/backup"


# =============================[      ]================================ #

# Backup core existing dotfiles first
mkdir -p "${BACKUPS_DIR}"

for file in .bashrc .bash_profile .profile; do
    echo -e "${GREEN}[*] ${RESET}Moving original files to backup folder"
    mv "${HOME}/${file}" "${BACKUPS_DIR}/" || echo -e "${YELLOW}[NOTE] ${RESET}No original ${file} found."
done

cp -R .dotfiles/* "${DOTFILES_DIR}/"

for file in .bashrc .bash_profile .profile; do
    echo -e "${GREEN}[*] ${RESET}Creating symlink for ${file} in Home directory"
    ln -s "${APP_BASE}/${file}" "${HOME}/${file}"
done

function finish {
    # Any script-termination routines go here, but function cannot be empty
    source ~/.bashrc
}
# End of script
trap finish EXIT
