#!/usr/bin/env bash
## =======================================================================================
# File:     setup-python.sh
#
# Author:   Cashiuus
# Created:  10-Mar-2016  -  Revised: 17-Feb-2025
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Setup Python 2 & 3 in Kali Linux and specify default version.
#           Updated version now places priority to Python 3, as v2 is EOL.
#
# Tested on: Kali Linux 2016-2020, Debian 8, 9, 10
#
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="4.0"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
ORANGE="\033[38;5;208m" # Debugging
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## =========[ CONSTANTS ]================ ##
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LOG_FILE="${APP_BASE}/debug.log"
# --------------- #
py2version="2.7"
py3version="3"             # Kali is 3.13, while Debian is 3.7, so being generic here
DEFAULT_VERSION="3"        # Determines which is set to default (2 or 3)
DEFAULT_PY3_ENV="default-py3"
DEFAULT_PY2_ENV="default-py2"

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

# Determine user's active shell to update the correct resource file
if [[ "${SHELL}" == "/usr/bin/zsh" ]]; then
    SHELL_FILE=~/.zshrc
elif [[ "${SHELL}" == "/bin/bash" ]]; then
    SHELL_FILE=~/.bashrc
else
    # Just in case I add other shells in the future
    SHELL_FILE=~/.bashrc
fi

# ==========================[  Python 3  ]============================= #
echo -e "\n${GREEN}[*]-----------${RESET}[ ${PURPLE}PENPREP${RESET} - Setup-Python ]${GREEN}-----------[*]${RESET}"
echo -e "${BLUE}\tAuthor:  ${RESET}${__author__}"
echo -e "${BLUE}\tVersion: ${RESET}${__version__}"

if [[ $# -eq 0 ]]; then
    # Setup python 3 by default, default to skipping python 2.
    install_python3
    exit 0
fi

if [[ "$1" != "3."* ]]; then
    echo -e "[ERR] You passed an invalid argument for a python version to install"
    echo -e "[*] Try a version string like 3.11.1"
    exit 1
fi

# If these aren't in the settings file, generate defaults
#~ echo -e -n "${GREEN}[+] ${RESET}"
#~ read -e -t 5 -i "N" -p " Do you want to also configure Python 2, even though it is now deprecated? [y,N] : " RESPONSE
#~ echo -e
#~ case $RESPONSE in
  #~ [Yy]* ) install_python2;;
#~ esac


function setup_alternatives() {
    # Utilize Linux's built-in feature of quick-switching between a program's versions
    $SUDO update-alternatives --install /usr/bin/python python /usr/bin/python${py3version} 1
    $SUDO update-alternatives --install /usr/bin/python python /usr/bin/python${py2version} 2
    if [[ $DEFAULT_VERSION == "3" ]]; then
            $SUDO update-alternatives --set python /usr/bin/python${py3version}
    else
            $SUDO update-alternatives --set python /usr/bin/python${py2version}
    fi
    echo -e "${GREEN}[*]${RESET} Your python version will be output below. Verify it is correct..."
    echo -n "${GREEN}[*]${RESET} Default Python is now: "
    python -V
    echo -e "${GREEN}[*]${RESET} If inccorrect, type: ${ORANGE}sudo update-alternatives --config python${RESET}"
    echo -e "    and select desired python version"
    sleep 5s

}
# Can possibly use in future, but for now, avoid using this system
# It isn't reliable bc many apt packages still expect python 2 during
# install/uninstall, specifically for python library packages.
#setup_alternatives


function install_python3_version {
    #
    #   This function accepts input of the python version number to try to install
    #       install_python3_version "3.10.6"
    #
    #echo -e "${ORANGE}[DBG]${RESET} The version you wish to install is below. Verify it is correct..."
    #VERSION='3.9.13'
    #V_SHORT='3.9'
    VERSION="${1}"
    V_SHORT=$(echo ${VERSION} | cut -d "." -f1-2)
    echo -e "${GREEN}[*]${RESET} Attempting install of version ${VERSION} / ${V_SHORT}"
    sleep 1s
    #$SUDO apt-get -qq update
    echo -e "${GREEN}[*]${RESET} Installing apt-get dependencies..."
    $SUDO apt-get -y install build-essential curl zlib1g-dev libncurses5-dev \
        libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev \
        libffi-dev libbz2-dev
    cd /tmp
    echo -e "${GREEN}[*]${RESET} Downloading Python installer package.."
    curl -O https://www.python.org/ftp/python/${VERSION}/Python-${VERSION}.tar.xz
    tar -xf Python-${VERSION}.tar.xz
    cd Python-${VERSION}
    echo -e "${GREEN}[*]${RESET} Running initial configure prep..."
    ./configure --enable-optimizations
    # Start build, specify number of cores in your processor
    PROCS=$(nproc)
    make -j ${PROCS}
    # Install it, don't use `make install` as it'll overwrite
    # the default system `python3` binary.
    echo -e "${GREEN}[*]${RESET} Installing this Python version into /usr/local/bin (altinstall)"
    $SUDO make altinstall
    # Version check to ensure it installed
    echo -e -n "${GREEN}[*]${RESET} System Python version: "
    python${V_SHORT} --version
    echo -e
    # NOTE: Altinstall means these will create binaries in /usr/local/bin/python3.x
    echo -e -n "${GREEN}[*]${RESET} Recently installed version: "
    /usr/local/bin/python${V_SHORT} --version
    echo -e
    #mkvirtualenv base-${VERSION} -p /usr/bin/python${V_SHORT}
    echo -e "${GREEN}[*]${RESET} Finished, look for this to be installed at /usr/local/bin/"
}
#install_python3_version "3.9.16"
#install_python3_version "3.10.9"
#install_python3_version "3.11.1"

# Install the version passed to script as an arg
install_python3_version "${1}"




function finish {
    #
    # Any script-termination routines go here, but function cannot be empty
    #

    #echo -e "${GREEN}===== Update-Alternatives Listing =====${RESET}"
    #update-alternatives --list python

    echo -e ""
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
    echo -e "\n${GREEN}[*]${RESET} Python system setup is now complete!"
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, Goodbye!"
    echo -e ""
}
# End of script
trap finish EXIT




## ===================================================================================== ##
## =====================[ Python Setup Code Help :: Core Notes ]======================= ##
#
# Virtualenvs
#----------------
# List all existing: `workon <tab><tab>`
#
# Install or upgrade (-U) a package to ALL virtualenvs
#allvirtualenv pip install django
#allvirtualenv pip install -U django


# ---- virtualenwrapper helpers ------
#virtualenvwrapper_get_python_version

# new tool called autoenv that will auto-activate a virtualenv when you cd into a folder
# that contains a .env file
# Project:https://github.com/kennethreitz/autoenv


# Can also install pip packages on a per-user basis
# instead using: pip install --user <pkg>
# NOTE: On kali, most base pip pkgs are already installed, some as apt pkgs
#$SUDO pip3 install requests

# =====[ Pip Setup ]===== #
#$SUDO pip install --upgrade pip
# This method would be used on Windows
# Source: https://pip.pypa.io/en/stable/installing/#upgrading-pip
#python -m pip install --upgrade pip

# Figure out which outdated $(pip list --oudated) pip packages are
# apt pkgs and which are not. Update the ones that are not so we
# don't break apt repo package installs.

#$SUDO pip install --upgrade lxml
#pip install --upgrade argparse
## ===================================================================================== ##
