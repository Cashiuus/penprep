#!/usr/bin/env bash
## =============================================================================
# File:     install-simple.sh
#
# Author:   Cashiuus
# Created:  02/20/2016  - (Revised: 11-Dec-2016)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Simply copy existing dotfiles into ${HOME} dir w/o any fancy symlinking.
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

# Backup core existing dotfiles first
for file in .bashrc .bash_profile .profile; do
    if [[ -e ${file} ]]; then
        [[ ! -d "${BACKUPS_DIR}" ]] && mkdir -p "${BACKUPS_DIR}"
        echo -e "${GREEN}[*] ${RESET}Moving original ${RED}${file}${RESET} to:" \
            "${YELLOW}${BACKUPS_DIR}${RESET}"
        mv "${HOME}/${file}" "${BACKUPS_DIR}/" >/dev/null 1>&2
    fi
done


echo -e "${GREEN}[*] ${RESET}Copying our git dotfiles to HOME directory..."
cp .bashrc "${HOME}/"
cp .profile "${HOME}/"
cp -R "${APP_BASE}"/.dotfiles/bash/* "${HOME}"

# Copy nano dotfiles
mkdir -p "${HOME}/.dotfiles/nano/"
cp .nanorc "${HOME}/"
cp -R "${APP_BASE}"/.dotfiles/nano/* "${HOME}/.dotfiles/nano/"


#for file in .bash_aliases .bash_profile .bash_prompt .bash_sshagent; do
#    cp "${APP_BASE}/.dotfiles/bash/${file}" "${HOME}/"
#    echo -e "${GREEN}[*] ${file} copied to HOME"
#done
echo -e "${GREEN}[*] ${RESET}Finished simple dotfiles install, goodbye!"
exit 0



# Another way to install by using git cloning
#git clone --depth=1 https://github.com/<user>/dotfiles
