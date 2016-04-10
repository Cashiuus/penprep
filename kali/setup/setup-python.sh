#!/bin/bash
## =============================================================================
# File:     setup-python.sh
#
# Author:   Cashiuus
# Created:  03/10/2016  - (Revised: )
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:
#
#   References:
#       http://www.extellisys.com/articles/python-on-debian-wheezy
## =============================================================================
__version__="0.9"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LOG_FILE="${APP_BASE}/debug.log"
# --------------- #
INSTALL_PY3="true"
DEFAULT_VERSION="2"     # Set to 3 for py3; Determines which is activated at the end
py2version="2.7"
py3version="3.5"

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

# Determine active shell to update the correct resource file
if [[ "${SHELL}" == "/usr/bin/zsh" ]]; then
  SHELL_FILE=~/.zshrc
else
  SHELL_FILE=~/.bashrc
fi

# Pre-requisites
echo -e "\n ${GREEN}-----------${RESET}[ Installing Python Dependencies ]${GREEN}-----------${RESET}"
apt-get install -y -qq build-essential python python-pip virtualenvwrapper

# Install base pip files
file="/tmp/requirements.txt"
cat <<EOF > "${file}"
argparse
beautifulsoup4
colorama
django
dnspython
lxml
mechanize
netaddr
pefile
pep8
Pillow
python-Levenshtein
python-libnmap
requests
EOF
pip install -r /tmp/requirements.txt

# TODO: kali comes with some pip packages already on it and they are from apt-get packages
#pip install pip --upgrade
#pip install argparse --upgrade

# Figure out which outdated $(pip list --oudated) pip packages are apt pkgs and which are not
# update the ones that are not so we don't break apt repo package installs.


# Install Python 3.x
if [ $INSTALL_PY3 == "true" ]; then
  echo -e "${GREEN}[*]${RESET} Installing Python 3..."
  apt-get -y -qq install python3
fi


echo -e "\n ${GREEN}-----------${RESET}[ Creating Virtual Environments ]${GREEN}-----------${RESET}"
if [ ! -e /usr/local/bin/virtualenvwrapper.sh ]; then
  # apt-get package symlinking to where this file is expected to be
  ln -s /usr/share/virtualenvwrapper/virtualenvwrapper.sh /usr/local/bin/virtualenvwrapper.sh
fi
source /usr/local/bin/virtualenvwrapper.sh

# Custom post-creation script for new envs to auto-install core pip packages
file="${WORKON_HOME}/postmkvirtualenv"
cat <<EOF > "${file}"
#!/usr/bin/env bash
pip install argparse
pip install pep8
pip install requests
EOF

# Virtual Environment Setup - Python 3.5.x
if [ $INSTALL_PY3 == "true" ]; then
  #/usr/local/opt/python-${py3version}/bin/pyvenv env-${py3version}
  mkvirtualenv env-${py3version} -p /usr/bin/python${py3version}
fi

# Virtual Environment Setup - Python 2.7.x
mkvirtualenv env-${py2version} -p /usr/bin/python${py2version}

# Add lines to shell dot-file if they aren't there
echo -e "\n ${GREEN}-----------${RESET}[ Updating Shell Startup - ${SHELL_FILE} ]${GREEN}-----------${RESET}"
file=$SHELL_FILE
grep -q '^### Load Python Virtualenvwrapper' "${file}" 2>/dev/null \
  || echo '### Load Python Virtualenvwrapper Script helper' >> "${file}"
grep -q '^[[ -e "/usr/local/bin/virtualenvwrapper.sh"' "${file}" 2>/dev/null \
  || echo '[[ -e /usr/local/bin/virtualenvwrapper.sh ]] && source "/usr/local/bin/virtualenvwrapper.sh"' >> "${file}"
grep -q '^export WORKON_HOME=$HOME/.virtualenvs' "${file}" 2>/dev/null \
  || echo 'export WORKON_HOME=$HOME/.virtualenvs' >> "${file}"

source "${file}"

# Finally, activate the desired default
echo -e "\n ${GREEN}-----------${RESET}[ Setup Complete - Activating Environment ]${GREEN}-----------${RESET}"
if [ $DEFAULT_VERSION == "3" ]; then
  workon env-${py3version}
else
  workon env-${py2version}
fi

# Install or upgrade a package to ALL virtualenvs
#allvirtualenv pip install django
#allvirtualenv pip install -U django
