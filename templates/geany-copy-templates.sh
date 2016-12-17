#!/usr/bin/env bash
## =============================================================================
# File:     geany-copy-templates.sh
#
# Author:   Cashiuus
# Created:  02/20/2016  - (Revised: 16-Dec-2016)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Simply copy existing dotfiles into ${HOME} dir w/o any fancy symlinking.
#
#
## =============================================================================
SCRIPT_DIR=$(readlink -f $0)
APP_BASE=$(dirname ${SCRIPT_DIR})


cp -u ~/.config/geany/templates/files/a.sh ./
cp -u ~/.config/geany/templates/files/main.py ./
