#!/usr/bin/env bash
## =======================================================================================
# File:     backup-linux.sh
# Author:   Cashiuus
# Created:  11-Oct-2020     Revised:
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Do a comprehensive backup of all critical files, while attempting to avoid
#           many of the linux backend dirs/files that we don't need to retain.
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

## ==========[  TEXT COLORS  ]============= ##
# [http://misc.flogisoft.com/bash/tip_colors_and_formatting]
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
ORANGE="\033[38;5;208m" # Debugging
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## =============[  CONSTANTS  ]============= ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LINES=$(tput lines)
COLS=$(tput cols)
HOST_ARCH=$(dpkg --print-architecture)      # (e.g. output: "amd64")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
LOG_FILE="${APP_BASE}/debug.log"
DEBUG=true
DO_LOGGING=false

## =======[ EDIT THESE SETTINGS ]======= ##
BACKUP_NAME="Backup-$HOSTNAME-$(date +"%F %T")"




## =========================[ START :: LOAD FILES ]========================= ##
if [[ -s "${APP_BASE}/../common.sh" ]]; then
    source "${APP_BASE}/../common.sh"
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source files :: success${RESET}"
else
    echo -e "${RED} [ERROR]${RESET} common.sh functions file is missing."
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source files :: fail${RESET}"
    exit 1
fi
## ==========================[ END :: LOAD FILES ]========================== ##

## ========================================================================== ##
# =========================[ :: HELPER FUNCTIONS :: ]======================== #
function pause() {
  # Simple function to pause a script mid-stride
  #
  local dummy
  read -s -r -p "Press any key to continue..." -n 1 dummy
}


function asksure() {
  ###
  # Usage:
  #   if asksure; then
  #        echo "Okay, performing rm -rf / then, master...."
  #   else
  #        echo "Awww, why not :("
  #   fi
  ###
  echo -n "Are you sure (Y/N)? "
  while read -r -n 1 -s answer; do
    if [[ $answer = [YyNn] ]]; then
      [[ $answer = [Yy] ]] && retval=0
      [[ $answer = [Nn] ]] && retval=1
      break
    fi
  done
  echo
  return $retval
}

## ========================================================================== ##
# ================================[  BEGIN  ]================================ #

echo -e "${ORANGE} + -- -- -- --=[${RESET}  ${APP_NAME}  ${ORANGE}]=-- -- -- -- +${RESET}"
echo -e "${BLUE}\tAuthor:  ${RESET}${__author__}"
echo -e "${BLUE}\tVersion: ${RESET}${__version__}"
echo -e "${ORANGE} + -- --=[ https://github.com/cashiuus ${RESET}"
echo -e
echo -e


## =============[  Prepare for Backup  ]============= ##

echo -e "${GREEN}[*]${RESET} Scanning your system for files over 1 GB in size."
echo -e "   This will take awhile..."

# Need to put this list for end user to see in script output, but also place into
# either a variable or a file for exclusion/inclusion in the backup command later.
# TODO: Also, need to exclude `/proc/kcore` from results.
file="/tmp/largefiles.txt"
find / -size +1G 2>/dev/null | tee "${file}"
pause


echo -e "   If any are found, you will be prompted to exit this script to delete them."
echo -e "   Then, once you done that, run this script again."


if [[ $EUID -ne 0 ]]; then
  echo -e "${GREEN}[+]${RESET} You must su root for this to work properly, doing so now"
  su root
fi

cd /


# Start the backup process
tar -cpzf /opt/"${BACKUP_NAME}".tar.gz --one-file-system \
  --exclude=/opt/"${BACKUP_NAME}".tar.gz \
  --exclude=/bin \
  --exclude=/boot \
  --exclude=/dev \
  --exclude=/lib \
  --exclude=/lib32 \
  --exclude=/lib64 \
  --exclude=/media \
  --exclude=/proc \
  --exclude=/run \
  --exclude=/sbin \
  --exclude=/srv \
  --exclude=/sys \
  --exclude=/tmp \
  --exclude=/usr/bin \
  --exclude=/usr/include \
  --exclude=/usr/lib \
  --exclude=/usr/lib32 \
  --exclude=/usr/lib64 \
  --exclude=/usr/sbin \
  --exclude=/usr/share \
  --exclude=/usr/src \
  --exclude=/var/cache \
  --exclude=/var/lib \
  --exclude=/var/log \
  --exclude=/var/tmp \
  --exclude=/root/.gvfs \
  --exclude=/root/.cache \
  --exclude=/root/.local/share/Trash \
  --exclude=/home/*/.gvfs \
  --exclude=/home/*/.cache \
  --exclude=/home/*/.local/share/Trash \
  --exclude=/home/*/.npm \
  --exclude=/home/*/.nvm \
  /

[[ $? -ne 0 ]] \
  && echo -e "${YELLOW}[ERROR] Tar backup failed for some reason, try again.${RESET}" \
  && exit 1



echo -e "${GREEN}[*]${RESET} Backup complete. Go copy off: /opt/${BACKUP_NAME}.tar.gz"





function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
  echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"

  FINISH_TIME=$(date +%s)
  echo -e "${BLUE} -=[ Penbuilder${RESET} :: ${BLUE}$APP_NAME ${BLUE}]=- ${GREEN}Completed Successfully ${RESET}-${ORANGE} (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)${RESET}\n"
}
# End of script
trap finish EXIT


## ===================================================================================== ##
## ============================[  :: Core Notes ::  ]============================== ##
#
#
#
## -=====[  Find & Delete Large Files  ]=====- ##
#   It is worth mentioning, you should avoid using `xargs` if possible in scripts
#
#
#   # Find files of specified file extension only and delete them
#   find -type f \( -name "*zip" -o -name "*tar" -o -name "*gz" \) -size +1M -delete
#
#   # if your version of find doesn't support -delete, do this instead:
#   find -type f \( -name "*zip" -o -name "*tar" -o -name "*gz" \) -size +1M -exec /bin/rm {} +
#
#
#
#
# Here's a way to use tar and show a progress bar:
#
#tar cf - /folder-with-big-files -P | pv -s $(du -sb /folder-with-big-files | awk '{print $1}') | gzip > big-files.tar.gz
#
#
#
#

###
#
#   c - create new backup archives
#   v - verbose
#   p - preserve permissions of the files put in the archives
#   z - use gzip for the compression
#
#   --one-file-system
#     The "problem" with this option is that if you want to
#     include /boot and /home or other partitions, you have
#     to then manually include them or they will be skipped
#     Take a look at `lsblk` beforehand to determine if there
#     are other partitions you DO want to keep included.
#
# Here's a way to use tar and show a progress bar:
#
#tar cf - /folder-with-big-files -P | pv -s $(du -sb /folder-with-big-files | awk '{print $1}') | gzip > big-files.tar.gz
#
#
#
#
# Create archive of directory, but exclude the ".local" subdirectory
#cd /
#tar --exclude=.local -zc root -f /tmp/kali-builder-2016-2.tar.gz

# Create archive of dirs. for several users
#su root
#cd /
#tar --exclude=.local --exclude=.java --exclude=.rvm -zc root -f /tmp/backup-kali-64bit-root.tar.gz
#cd /home
#tar --exclude=.local --exclude=.java -zc  -f /tmp/backup-kali-64bit-cashiuus.tar.gz

# Another way of archiving an entire directory
#tar --exclude=.local -c root/ | gzip > /tmp/kali-backup.tar.gz
#tar --exclude=.local -c root/ | bzip2 > /tmp/kali-backup.tar.bz

## ==================================================================================== ##
