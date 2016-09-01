#!/bin/bash
## =============================================================================
# File:     install-simple.sh
#
# Author:   Cashiuus
# Created:  02/20/2016  - (Revised: 17-July-2016)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Simply copy existing dotfiles into ${HOME} dir w/o any fancy symlinking.
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
BACKUPS_DIR="${HOME}/backup-dotfiles"


# =============================[ BEGIN ]================================ #
cd "${APP_BASE}"

# Backup core existing dotfiles first
mkdir -p "${BACKUPS_DIR}"

for file in .bashrc .bash_profile .profile; do
    echo -e "${GREEN}[*] ${RESET}Moving original files to backup folder"
    mv "${HOME}/${file}" "${BACKUPS_DIR}/" 2>/dev/null || echo -e "${YELLOW}[NOTE] ${RESET}No original ${file} found."
done

cp .bashrc "${HOME}/"
cp .profile "${HOME}/"
cp -R "${APP_BASE}"/.dotfiles/bash/* "${HOME}/"

for file in .bash_aliases .bash_profile .bash_prompt .bash_sshagent; do
    cp "${APP_BASE}/.dotfiles/bash/${file}" "${HOME}/"
    echo -e "${GREEN}[*] ${file} copied to HOME"
done

exit 0
