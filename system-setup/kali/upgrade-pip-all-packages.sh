#!/bin/bash
## =======================================================================================
# File:     upgrade-pip-all-packages.sh
#
# Author:   Cashiuus
# Created:  27-Jan-2016
# Revised:  15-Jan-2017
#
# Purpose:  Take this one-liner and make it an alias, this script is for demo really.
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
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


# =============================[  BEGIN UPGRADES  ]================================ #
if [[ $(which pip) ]]; then
    pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs pip install -U
else
    echo -e "${YELLOW} [ERROR] Pip not found in PATH...${RESET}"
fi

