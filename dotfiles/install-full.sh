#!/bin/bash
## =============================================================================
# File:     install-full.sh
#
# Author:   Cashiuus
# Created:  20-FEB-2016  - (Revised: 11-Dec-2016)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:
#
#
## =============================================================================
__version__="1.1"
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
BACKUPS_DIR="${HOME}/Backups/dotfiles"

# =============================[   MAIN   ]================================ #
# Backup core existing dotfiles first
mkdir -p "${BACKUPS_DIR}"

# Enable copying/moving of hidden files
shopt -s dotglob

for file in .bashrc .bash_profile .profile; do
    echo -e "${GREEN}[*] ${RESET}Moving original files to backup folder"
    mv "${HOME}/${file}" "${BACKUPS_DIR}/" 2>/dev/null || echo -e "${YELLOW}[NOTE] ${RESET}No original ${file} found."
done

# Copy all files over
cp -R .dotfiles/* "${DOTFILES_DIR}/"

echo -e "${GREEN}[*] ${RESET}Creating dotfile symlinks..."
for file in .bashrc .bash_profile .profile; do
    echo -e "${GREEN}[*] ${RESET}Creating symlink for ${file} in Home directory"
    ln -s "${APP_BASE}/${file}" "${HOME}/${file}"
done
