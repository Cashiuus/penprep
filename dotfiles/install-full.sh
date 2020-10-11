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




# Add this to the beginning of our system-wide profile file 
# at /etc/profile for reference purposes.

file="/etc/profile"
TEMP_STRING=""
cat <<EOF > "${TEMP_STRING}"
# For BASH: Read down the appropriate column. Executes A, then B, then C, etc.
# The B1, B2, B3 means it executes only the first of those files found.  (A)
# or (B2) means it is normally sourced by (read by and included in) the
# primary file, in this case A or B2.
#
# +---------------------------------+-------+-----+------------+
# |                                 | Interactive | non-Inter. |
# +---------------------------------+-------+-----+------------+
# |                                 | login |    non-login     |
# +---------------------------------+-------+-----+------------+
# |                                 |       |     |            |
# |   ALL USERS:                    |       |     |            |
# +---------------------------------+-------+-----+------------+
# |BASH_ENV                         |       |     |     A      | not interactive or login
# |                                 |       |     |            |
# +---------------------------------+-------+-----+------------+
# |/etc/profile                     |   A   |     |            | set PATH & PS1, & call following:
# +---------------------------------+-------+-----+------------+
# |/etc/bash.bashrc                 |  (A)  |  A  |            | Better PS1 + command-not-found 
# +---------------------------------+-------+-----+------------+
# |/etc/profile.d/bash_completion.sh|  (A)  |     |            |
# +---------------------------------+-------+-----+------------+
# |/etc/profile.d/vte-2.91.sh       |  (A)  |     |            | Virt. Terminal Emulator
# |/etc/profile.d/vte.sh            |  (A)  |     |            |
# +---------------------------------+-------+-----+------------+
# |                                 |       |     |            |
# |   A SPECIFIC USER:              |       |     |            |
# +---------------------------------+-------+-----+------------+
# |~/.bash_profile    (bash only)   |   B1  |     |            | (doesn't currently exist) 
# +---------------------------------+-------+-----+------------+
# |~/.bash_login      (bash only)   |   B2  |     |            | (didn't exist) **
# +---------------------------------+-------+-----+------------+
# |~/.profile         (all shells)  |   B3  |     |            | (doesn't currently exist)
# +---------------------------------+-------+-----+------------+
# |~/.bashrc          (bash only)   |  (B2) |  B  |            | colorizes bash: su=red, other_users=green
# +---------------------------------+-------+-----+------------+
# |                                 |       |     |            |
# +---------------------------------+-------+-----+------------+
# |~/.bash_logout                   |    C  |     |            |
# +---------------------------------+-------+-----+------------+
#
# ** (sources !/.bashrc to colorize login, for when booting into non-gui)
EOF








