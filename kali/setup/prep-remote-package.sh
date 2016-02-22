#!/bin/bash
## =============================================================================
# File:
#
# Author:   Cashiuus
# Created:  01/27/2016
# Revised:
#
# Purpose:
#
## =============================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
DEST_IP=''

# =============================[      ]================================ #


file1="${HOME}/vpn-setup/client1.conf"
file2="${HOME}/.ssh/id_rsa"

# Direct Send
tar czv "${file1} ${file2}" | ncat --send-only "${DEST_IP}"

# Listener
#ncat -l | tar xzv








function finish {
    # Any script-termination routines go here, but function cannot be empty
    clear
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
#   [[ $? -eq 0 ]]    Previous command was successful
#   [[ ! $? -eq 0 ]]    Previous command NOT successful
#

# --- TOUCH
#touch
#touch "$file" 2>/dev/null || { echo "Cannot write to $file" >&2; exit 1; }

### ---[ READ ]---###
#   -p ""   Instead of echoing text, provide it right in the "prompt" argument
#               *NOTE: Typically, there is no newline, so you may need to follow
#               this with an "echo" statement to output a newline.
#   -e      Specify variable response is stored in. Arg can be anywhere,
#           but variable is always at the end of the statement
#   -n #    Number of seconds to wait for a response before continuing automatically
#   -i ""   Specify a default value. If user hits ENTER or doesn't respond, this value is saved
#

#Ask for a path with a default value
#read -p "Enter the path to the file: " -i "/usr/local/etc/" -e FILEPATH





# ==================[ BASH GUIDES ]====================== #

# Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
# Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
