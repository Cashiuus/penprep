#!/bin/bash
## =============================================================================
# File:
#
# Author:   Cashiuus
# Created:  03/10/2016  - (Revised: )
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
LOG_FILE="${APP_BASE}/debug.log"

#======[ ROOT PRE-CHECK ]=======#
if [[ $EUID -ne 0 ]];then
    if [[ $(dpkg-query -s sudo) ]];then
        export SUDO="sudo"
        # $SUDO - run commands with this prefix now to account for either scenario.
    else
        echo "Please install sudo or run this as root."
        exit 1
    fi
fi
# =============================[      ]================================ #













function finish {
    # Any script-termination routines go here, but function cannot be empty
    clear
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"
    # Redirect app output to log, sending both stdout and stderr (*NOTE: this will not parse color codes)
    # cmd_here 2>&1 | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT

# ================[ Expression Cheat Sheet ]==================================
#
#   -d      file exists and is a directory
#   -e      file exists
#   -f      file exists and is a regular file
#   -h      file exists and is a symbolic link
#   -s      file exists and size greater than zero
#   -r      file exists and has read permission
#   -w      file exists and write permission granted
#   -x      file exists and execute permission granted
#   -z      file is size zero (empty)
#   [[ $? -eq 0 ]]      Previous command was successful
#   [[ $? -ne 0 ]]      Previous command NOT successful
#
# ====[ READ ]==== #
#   -p ""   Instead of echoing text, provide it right in the "prompt" argument
#               *NOTE: Typically, there is no newline, so you may need to follow
#               this with an "echo" statement to output a newline.
#   -e      Specify variable response is stored in. Arg can be anywhere,
#           but variable is always at the end of the statement
#   -n #    Number of seconds to wait for a response before continuing automatically
#   -i ""   Specify a default value. If user hits ENTER or doesn't respond, this value is saved
#
# Ask for a path with a default value
#read -p "Enter the path to the file: " -i "/usr/local/etc/" -e FILEPATH

# ====[ TOUCH ]==== #
#touch
#touch "$file" 2>/dev/null || { echo "Cannot write to $file" >&2; exit 1; }

# ====[ SED ]==== #
#sed -i 's/^.*editor_font=.*/editor_font=Monospace\ 10/' "${file}"
#sed -i 's|^.*editor_font=.*|editor_font=Monospace\ 10|' "${file}"

# ==================[ BASH GUIDES ]====================== #
# Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
# Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
