#!/usr/bin/env bash
## =============================================================================
# File:     copy-local-templates-to-git.sh
# Author:   Cashiuus
# Created:  20-Feb-2016  - Revised: 09-May-2017
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Copy Geany IDE templates from local .config to git repo for syncing.
#
#
## =============================================================================
__version__="1.2"
__author__="Cashiuus"
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
RESET="\033[00m"        # Normal
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")

GEANY_TEMPLATES="${APP_BASE}/../templates/geany"
GEANY_INSTALLED_TEMPLATES_DIR="${HOME}/.config/geany/templates/files"


function copy_geany_templates_to_git() {
    if [[ -d "${GEANY_TEMPLATES}" ]]; then
        cp -ur "${GEANY_INSTALLED_TEMPLATES_DIR}"/* "${GEANY_TEMPLATES}/"
        echo -e "${GREEN}[*]${RESET} Geany File Templates have been copied into git repo for syncing."
    else
        echo -e "${RED}[ERROR]${RESET} Error with templates location, check script and try again."
    fi
}
# Copy over our custom code template files
copy_geany_templates_to_git

#cp -u ~/.config/geany/templates/files/* "${APP_BASE}/../templates/geany/"
