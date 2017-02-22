#!/usr/bin/env bash
## =============================================================================
# File:     geany-copy-templates.sh
#
# Author:   Cashiuus
# Created:  02/20/2016  - (Revised: 21-Feb-2017)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Simply copy existing dotfiles into ${HOME} dir w/o any fancy symlinking.
#
#
## =============================================================================
__version__="1.1"
__author__="Cashiuus"
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")


cp -u ~/.config/geany/templates/files/file.sh "${APP_BASE}/geany/"
cp -u ~/.config/geany/templates/files/main.py "${APP_BASE}/geany/"
