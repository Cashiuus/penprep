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
VPN_CLIENT_CONF="${HOME}/vpn-setup/client1.conf"
SSH_CLIENT_KEY="${HOME}/.ssh/id_rsa"
# =============================[      ]================================ #

# Locate the client .ovpn file
if [[ ! ${VPN_CLIENT_CONF} ]]; then
    echo -e "${YELLOW}[WARN] ${RESET} VPN Client file not found. Locate and edit script settings."
    echo -e "${YELLOW}[WARN] ${RESET} Crawling setup directory, is file listed below?"
    for entry in $(dirname ${VPN_CLIENT_CONF}); do
        echo "${entry}"
    done
    echo -e ''
    exit 1
fi


# Get IP from stored var, script argument, or ask user to type it in.
if [[ $DEST_IP == '' ]]; then
    if [[ $1 ]]; then
        DEST_IP=$1
    else
        read -r -e -p "[+] Please enter Destination IP: " DEST_IP
    fi
fi

# Serve files
if [[ ! ${SSH_CLIENT_KEY} ]]; then
    tar czv "${VPN_CLIENT_CONF}" | ncat --send-only "${DEST_IP}"
else
    # Add ssl?
    tar czv "${VPN_CLIENT_CONF} ${SSH_CLIENT_KEY}" | ncat --send-only "${DEST_IP}"
fi
# Listener
#ncat -l | tar xzv
