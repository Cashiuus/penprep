#!/bin/bash
## =============================================================================
# File:     setup-python.sh
#
# Author:   Cashiuus
# Created:  10-Mar-2016  -  Revised: 27-Mar-2017
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:  Setup Python 2 & 3 in Kali Linux and specify default version.
#
# References:
#   http://www.extellisys.com/articles/python-on-debian-wheezy
## =============================================================================
__version__="1.0"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
PURPLE="\033[01;35m"   # Other
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
DEFAULT_VERSION="2"     # Set this to 3 for py3; Determines which is activated at the end
py2version="2.7"
py3version="3.5"

#======[ ROOT PRE-CHECK ]=======#
if [[ $EUID -ne 0 ]]; then
    if [[ $(dpkg-query -s sudo) ]]; then
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
echo -e "\n${GREEN}[*]-----------${RESET}[ ${PURPLE}PENPREP${RESET} - Setup-Python ]${GREEN}-----------[*]${RESET}"
echo -e "${GREEN}[*] ${PURPLE}[penprep]${RESET} Installing Python Dependencies"
$SUDO apt-get -y install build-essential python python-pip python-dev virtualenv \
    virtualenv-clone virtualenvwrapper

# Pillow depends
$SUDO apt-get -y install libtiff5-dev libjpeg62-turbo-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libffi-dev zlib1g-dev

# lxml depends
$SUDO apt-get -y install libxml2-dev libxslt1-dev zlib1g-dev

# Postgresql and psycopg2 depends
$SUDO apt-get -y install libpq-dev

# Scrapy depends
$SUDO apt-get -y install openssl libssl-dev


# =====[ Pip Setup ]===== #
$SUDO pip install --upgrade pip
# This method would be used on Windows
# Source: https://pip.pypa.io/en/stable/installing/#upgrading-pip
#python -m pip install --upgrade pip

# Install base pip files
file="/tmp/requirements.txt"
cat <<EOF > "${file}"
argparse
beautifulsoup4
colorama
dnspython
lxml
mechanize
netaddr
pefile
pep8
Pillow
psycopg2
pygeoip
python-Levenshtein
python-libnmap
requests
six
wheel
EOF
$SUDO pip install -r /tmp/requirements.txt

$SUDO pip install lxml --upgrade
#pip install argparse --upgrade

# Figure out which outdated $(pip list --oudated) pip packages are apt pkgs and which are not
# update the ones that are not so we don't break apt repo package installs.


# Install Python 3.x
if [ $INSTALL_PY3 == "true" ]; then
    echo -e "\n${GREEN}[*] ${PURPLE}[penprep]${RESET} Installing Python 3..."
    $SUDO apt-get -y -qq update
    # TODO: Are the "-all" and "-dev" necessary at this point?
    $SUDO apt-get -y install python3 python3-all python3-dev python3-pip

    # pip3 --version
    # Can also install pip packages on a per-user basis instead using: pip install --user <pkg>
    # NOTE: On kali, most base pip pkgs are already installed
    $SUDO pip3 install requests
fi



echo -e "\n${GREEN}[*] ${PURPLE}[penprep]${RESET} Creating Virtual Environments"
if [ ! -e /usr/local/bin/virtualenvwrapper.sh ]; then
    # apt-get package symlinking to where this file is expected to be
    $SUDO ln -s /usr/share/virtualenvwrapper/virtualenvwrapper.sh /usr/local/bin/virtualenvwrapper.sh
fi

source /usr/local/bin/virtualenvwrapper.sh

# Custom post-creation script for new envs to auto-install core pip packages
file="${WORKON_HOME}/postmkvirtualenv"
cat <<EOF > "${file}"
#!/usr/bin/env bash
pip install beautifulsoup4
pip install pep8
pip install requests
EOF

# Custom Django requirements file for quick Django setups
file="${WORKON_HOME}/django-requirements.txt"
cat <<EOF > "${file}"
cookiecutter
django
djang-debug-toolbar
django-environ
django-extensions
django-import-export
django-secure
psycopg2
pygraphviz
six
EOF

# Virtual Environment Setup - Python 3.5.x
if [[ $INSTALL_PY3 == "true" ]]; then
    #/usr/local/opt/python-${py3version}/bin/pyvenv env-${py3version}
    mkvirtualenv env-${py3version} -p /usr/bin/python${py3version}
    pip install --upgrade pip
    pip install setuptools
    deactivate
fi

# Virtual Environment Setup - Python 2.7.x
mkvirtualenv env-${py2version} -p /usr/bin/python${py2version}
pip install --upgrade pip
pip install setuptools
deactivate

# Add lines to shell dot-file if they aren't there
# Note: Prefer normal loading versus lazy loading here because lazy loading
# will not have tab completion until after you've run at least 1 command (e.g. workon <tab>)
# Source: https://virtualenvwrapper.readthedocs.io/en/latest/install.html
echo -e "\n${GREEN}[*] ${PURPLE}[penprep]${RESET}  Updating Shell dotfile for virtualenvwrapper - ${GREEN}${SHELL_FILE}${RESET}"
file=$SHELL_FILE
grep -q '^### Load Python Virtualenvwrapper' "${file}" 2>/dev/null \
    || echo '### Load Python Virtualenvwrapper Script helper' >> "${file}"

# TODO: Improve this regex
grep -q '^.*"/usr/local/bin/virtualenvwrapper.sh".*' "${file}" 2>/dev/null \
    || echo '[[ -s "/usr/local/bin/virtualenvwrapper.sh" ]] && source "/usr/local/bin/virtualenvwrapper.sh"' >> "${file}"
grep -q 'export WORKON_HOME=' "${file}" 2>/dev/null \
    || echo 'export WORKON_HOME=$HOME/.virtualenvs' >> "${file}"

source "${file}"

# Finally, activate the desired default
# TODO: This doesn't actually work because source and workon end with the script process
#   User will still have to manually do this themselves after script exits
echo -e "\n ${GREEN}-----------${RESET}[ ${PURPLE}PENPREP${RESET} - Setup Complete - Activating Environment ]${GREEN}-----------${RESET}"
if [[ $DEFAULT_VERSION == "3" ]]; then
    workon env-${py3version}
else
    workon env-${py2version}
fi


# Install or upgrade (-U) a package to ALL virtualenvs
#allvirtualenv pip install django
#allvirtualenv pip install -U django


# ---- virtualenwrapper helpers ------
#virtualenvwrapper_get_python_version


# new tool called autoenv that will auto-activate a virtualenv when you cd into a folder
# that contains a .env file
# Project:https://github.com/kennethreitz/autoenv



mkvirtualenv py3-scrapy -p /usr/bin/python${py3version}
pip install Scrapy
deactivate



function finish {
    # Any script-termination routines go here, but function cannot be empty
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
    echo -e "\t\t${GREEN}[*] ${RESET}Python Setup Complete!\n\n"
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"
    # Redirect app output to log, sending both stdout and stderr (*NOTE: this will not parse color codes)
    # cmd_here 2>&1 | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT
