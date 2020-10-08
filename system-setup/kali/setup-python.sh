#!/usr/bin/env bash
## =======================================================================================
# File:     setup-python.sh
#
# Author:   Cashiuus
# Created:  10-Mar-2016  -  Revised: 11-Oct-2020
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
__version__="2.0"
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
py3version="3.7"
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

$SUDO apt-get -y -qq update

# Core programming environment dependency files
$SUDO apt-get -y install build-essential libssl-dev libffi-dev

echo -e "\n${GREEN}[*]${RESET} Installing/Configuring Python 3"
# Core python 3 & virtual env support
$SUDO apt-get -y install python3 python3-all python3-dev \
	python3-pip python3-setuptools python3-venv python3-virtualenv \
	virtualenvwrapper

# lxml depends (xml library)
$SUDO apt-get -y install libxml2-dev libxslt1-dev zlib1g-dev

# Postgresql and psycopg2 depends (db library)
$SUDO apt-get -y install libpq-dev

# Pillow depends (image library)
$SUDO apt-get -y install libtiff5-dev libjpeg62-turbo-dev \
	libfreetype6-dev liblcms2-dev libwebp-dev libffi-dev zlib1g-dev

# Scrapy depends (scraping library)
$SUDO apt-get -y install openssl libssl-dev

echo -e "\n${GREEN}[*]${RESET} Creating Virtual Environments"
if [ ! -e /usr/local/bin/virtualenvwrapper.sh ]; then
    # apt-get package symlinking to where this file is expected to be
    $SUDO ln -s /usr/share/virtualenvwrapper/virtualenvwrapper.sh /usr/local/bin/virtualenvwrapper.sh
fi

source /usr/local/bin/virtualenvwrapper.sh
# When you run this, its first-run auto-creates our default
# virtualenv directory at: `$HOME/.virtualenvs/`

# Custom post-creation script for ALL new envs to auto-install 
# core pip packages
file="${WORKON_HOME}/postmkvirtualenv"
cat <<EOF > "${file}"
#!/usr/bin/env bash
pip install beautifulsoup4
pip install pep8
pip install requests
EOF

# Virtual Environment Setup - Python 3.x
echo -e "\n${GREEN}[*]${RESET} Creating a Python 3 standard virtualenv"
mkvirtualenv ${DEFAULT_PY3_ENV} -p /usr/bin/python${py3version}
if [[ $? -eq 0 ]]; then
	pip install --upgrade pip
	pip install --upgrade setuptools
	deactivate
fi


# ==========================[  Python 2  ]============================= #
echo -e "\n${GREEN}[*]${RESET} Installing/Configuring Python 2"
$SUDO apt-get -y install python python-dev python-pip \
	python-setuptools virtualenv

# Virtual Environment Setup - Python 2.7.x
echo -e "\n${GREEN}[*]${RESET} Creating a Python 2 standard virtualenv"
mkvirtualenv ${DEFAULT_PY2_ENV} -p /usr/bin/python${py2version}
pip install --upgrade pip
pip install --upgrade setuptools
deactivate



# ==========================[  Pip Packages  ]========================== #

# Install baseline set of system-wide pip packages
file="/tmp/requirements.txt"
cat <<EOF > "${file}"
argparse
beautifulsoup4
colorama
dnspython
future
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

echo -e "\n${GREEN}[*]${RESET} Installing baseline pip pkgs for Python 2"
pip install -r /tmp/requirements.txt
echo -e "\n${GREEN}[*]${RESET} Installing baseline pip pkgs for Python 3"
pip3 install -r /tmp/requirements.txt


# =========================[  Virtualenvwrapper  ]========================= #
# Add lines to shell dotfile if they aren't there
# Note: Prefer normal loading versus lazy loading here because lazy loading
# will not have tab completion until after you've run at least 1 command (e.g. workon <tab>)
# Source: https://virtualenvwrapper.readthedocs.io/en/latest/install.html
echo -e "\n${GREEN}[*]${RESET} Updating your dotfile for virtualenvwrapper at: ${GREEN}${SHELL_FILE}${RESET}"
file=$SHELL_FILE
grep -q '^### Load Python Virtualenvwrapper' "${file}" 2>/dev/null \
    || echo '### Load Python Virtualenvwrapper Script helper' >> "${file}"

# TODO: Improve this regex
grep -q '^.*"/usr/local/bin/virtualenvwrapper.sh".*' "${file}" 2>/dev/null \
    || echo '[[ -s "/usr/local/bin/virtualenvwrapper.sh" ]] && source "/usr/local/bin/virtualenvwrapper.sh"' >> "${file}"
grep -q 'export WORKON_HOME=' "${file}" 2>/dev/null \
    || echo 'export WORKON_HOME=$HOME/.virtualenvs' >> "${file}"
source "${file}"


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


# ========================[  Python 3.9  ]=========================== #
# In case it's needed
function install_python39 {
	#
	#
	#
	echo -e "${GREEN}[*]${RESET} Your python version will be output below. Verify it is correct..."
	VERSION='3.9.0'
	V_SHORT='3.9'
	#$SUDO apt-get -qq update
	$SUDO apt-get -y install build-essential curl zlib1g-dev libncurses5-dev \
		libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev \
		libffi-dev libbz2-dev
	cd /tmp
	curl -O https://www.python.org/ftp/python/${VERSION}/Python-${VERSION}.tar.xz
	tar -xf Python-${VERSION}.tar.xz
	cd Python-${VERSION}
	./configure --enable-optimizations
	# Start build, specify number of cores in your processor
	PROCS=$(nproc)
	make -j ${PROCS}
	# Install it, don't use `make install` as it'll overwrite
	# the default system `python3` binary.
	$SUDO make altinstall
	# Version check to ensure it installed
	echo -n "${GREEN}[*]${RESET} Python version check: "
	python${V_SHORT} --version
	mkvirtualenv default-${VERSION} -p /usr/bin/python${V_SHORT}
}
#install_python39


function finish {
    #
    # Any script-termination routines go here, but function cannot be empty
    #
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
    echo -e "\n${GREEN}[*]${RESET} Python system setup is now complete!"
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, Goodbye!"
    echo -e ""
}
# End of script
trap finish EXIT




## ===================================================================================== ##
## =====================[ Template File Code Help :: Core Notes ]======================= ##
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
