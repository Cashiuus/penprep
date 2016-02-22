#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: setup-python.sh             (Update: 17-Jan-2016) #
#-Author(s)---------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
# http://www.extellisys.com/articles/python-on-debian-wheezy
# If not root, must run 'make' commands as sudo
#
#-------------------------------------------------------------#

INSTALL_PY3="true"
DEFAULT_VERSION="2" # Set to 3 for py3; Determines which is activated at the end
py2version="2.7"
py3version="3.4"

## Text Colors
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal


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


# Install Python 3.4.x
if [ $INSTALL_PY3 == "true" ]; then
    apt-get -y -qq install python3
fi


echo -e "\n ${GREEN}-----------${RESET}[ Creating Virtual Environments ]${GREEN}-----------${RESET}"
if [ ! -e /usr/local/bin/virtualenvwrapper.sh ]; then
    # apt-get package symlinking to where this file is expected to be
    ln -s /usr/share/virtualenvwrapper/virtualenvwrapper.sh /usr/local/bin/virtualenvwrapper.sh
fi
source /usr/local/bin/virtualenvwrapper.sh

# Tweak the post-creation script for new envs to auto-install core apps
file=$WORKON_HOME/postmkvirtualenv
cat <<EOF > "${file}"
#!/usr/bin/env bash
pip install argparse
pip install pep8
pip install requests
EOF

# Virtual Environment Setup - Python 3.4.x
if [ $INSTALL_PY3 == "true" ]; then
    #/usr/local/opt/python-${py3version}/bin/pyvenv env-${py3version}
    mkvirtualenv env-${py3version} -p /usr/bin/python${py3version}
fi

# Virtual Environment Setup - Python 2.7.x
mkvirtualenv env-${py2version} -p /usr/bin/python${py2version}

# Add lines to shell dot-file if they aren't there
echo -e "\n ${GREEN}-----------${RESET}[ Updating Shell Startup - ${SHELL_FILE} ]${GREEN}-----------${RESET}"
file=$SHELL_FILE
grep -q '^### Load Python Virtualenvwrapper' "${file}" 2>/dev/null || echo '### Load Python Virtualenvwrapper Script helper' >> "${file}"
grep -q '^[[ -e "/usr/local/bin/virtualenvwrapper.sh"' "${file}" 2>/dev/null || echo '[[ -e /usr/local/bin/virtualenvwrapper.sh ]] && source "/usr/local/bin/virtualenvwrapper.sh"' >> "${file}"
grep -q '^export WORKON_HOME=$HOME/.virtualenvs' "${file}" 2>/dev/null || echo 'export WORKON_HOME=$HOME/.virtualenvs' >> "${file}"
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
