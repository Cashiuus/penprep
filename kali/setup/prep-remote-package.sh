#!/bin/bash
## =============================================================================
# File:     prep-remote-package.sh
#
# Author:   Cashiuus
# Created:  27-JAN-2016 - - - - - - (Revised: 13-MAY-2016)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Bundle up a configuration package as a tarball and send to DEST_IP
#
#
## ========================================================================== ##
__version__="1.0"
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
file1="${HOME}/vpn-setup/client1.conf"
file2="${HOME}/.ssh/id_rsa"
# =============================[      ]================================ #

# Get IP from stored var, script argument, or ask user to type it in.
if [[ $DEST_IP == '' ]]; then
    if [[ $1 ]]; then
        DEST_IP=$1
    else
        read -p "[+] Please enter Destination IP: " -e DEST_IP
        echo -e ""
    fi
fi
# Add ssl?
tar czv "${file1} ${file2}" | ncat --send-only "${DEST_IP}"

# Listener
#ncat -l | tar xzv
