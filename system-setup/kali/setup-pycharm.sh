#!/usr/bin/env bash
## =======================================================================================
# File:     setup-pycharm.sh
#
# Author:   Cashiuus
# Created:  10-Dec-2016     Revised: 10-Aug-2017
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Download, setup pycharm, backup original pycharm settings if applicable,
#           and create a desktop launcher with pycharm icon.
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#
#   TODO:
#       - Get latest pycharm version programmatically rather than setting static constant
#       - Determine if there is a better way to backup older version settings files
#       -
#
#-[ Links/Credit ]------------------------------------------------------------------------
#
#   http://tutorialforlinux.com/2016/02/21/how-to-install-pycharm-python-ide-on-kali-linux-easy-guide/
#   Quickstart: http://tutorialforlinux.com/2014/09/14/debian-7-wheezy-how-to-quick-start-with-pycharm-python-ide-easy-guide/
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.2"
__author__="Cashiuus"
## ==========[ TEXT COLORS ]========== ##
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
PURPLE="\033[01;35m"    # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## =============[ CONSTANTS ]============== ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_ARGS=$@
DEBUG=true
LOG_FILE="${APP_BASE}/debug.log"
BACKUPS_PATH="${HOME}/Backups"
# TODO: Get latest pycharm version programmatically
PYCHARM_VERSION="2017.2"

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
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #

# Check that we have OpenJDK installed and operational
# Another way is to check if JAVA_HOME or another env variable exists
java -version >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
    echo -e "${YELLOW}[*] ${RESET}Java not found, attempting to install"
    $SUDO apt-get install openjdk-8-jdk || $SUDO apt-get -f install openjdk-8-jdk # Fix any dependency issues
else
    echo -e "${GREEN}[*]${RESET} Java detected, continuing with installation"
fi


# Save our preferences/settings before getting rid of old versions
echo -e "${GREEN}[*] ${RESET}Checking for previous versions to backup settings"
[[ ! -d "${BACKUPS_PATH}" ]] && mkdir -p "${BACKUPS_PATH}"
if [[ -d ${HOME}/.PyCharm2016.2 ]]; then
    cp ${HOME}/.PyCharm2016.2/config/settings.jar "${BACKUPS_PATH}/"
elif [[ -d ${HOME}/.PyCharm2017.2 ]]; then
    cp ${HOME}/.PyCharmCE2017.2/config/settings.jar "${BACKUPS_PATH}/"
fi


echo -e "${GREEN}[*] ${RESET}Downloading PyCharm package, please wait..."
cd /tmp

# TODO: Parse here for d/l link - http://www.jetbrains.com/pycharm/download/#section=linux
# http://www.jetbrains.com/pycharm/download/download-thanks.html?platform=linux&code=PCC
# https://download-cf.jetbrains.com/python/pycharm-community-2017.2.1.tar.gz
wget --no-verbose http://download.jetbrains.com/python/pycharm-community-${PYCHARM_VERSION}.tar.gz
#wget -q https://download-cf.jetbrains.com/python/pycharm-community-${PYCHARM_VERSION}.tar.gz
tar xzf pycharm-community-${PYCHARM_VERSION}.tar.gz

# TODO: Can we simply overwrite the files, or should we delete the old folder first?
$SUDO rm -rf /opt/pycharm-community/ 2>/dev/null

# Clean up the archive file
$SUDO rm /tmp/pycharm-community-${PYCHARM_VERSION}.tar.gz

# Move into permanent install path and then delete tmp files
$SUDO mkdir /opt/pycharm-community
$SUDO mv /tmp/pycharm-community/* /opt/pycharm-community/


# Create permanent symlinks so we can easily open pycharm going forward
echo -e "${GREEN}[*] ${RESET}Creating symlinks for PyCharm"
[[ ! -d /usr/local/bin ]] && $SUDO mkdir -p /usr/local/bin
[[ ! -f /usr/local/bin/pycharm ]] && $SUDO ln -s /opt/pycharm-community/bin/pycharm.sh /usr/local/bin/pycharm
[[ ! -f /usr/local/bin/inspect ]] && $SUDO ln -s /opt/pycharm-community/bin/inspect.sh /usr/local/bin/inspect


# This site mentions a server for a server key that will validate Professional versions licensing
#http://www.psudobyte.com/2016/05/install-pycharm-professional.html
#Server key = http://idea.qinxi1992.cn

# Copy the PyCharm Icon over to our default applications pool
###cp /opt/pycharm-community/bin/pycharm.png /usr/share/applications/

# Setup desktop icon if you wish
file="${HOME}/Desktop/pycharm.desktop"
if [[ ! -f "${file}" ]]; then
    cat <<EOF > ${HOME}/Desktop/pycharm.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Name=PyCharm
Encoding=UTF-8
Exec=/opt/pycharm-community/bin/pycharm.sh
Icon=/opt/pycharm-community/bin/pycharm.png
StartupNotify=false
Terminal=false
Type=Application
EOF
fi
chmod 0500 "${file}"


function finish {
    # Any script-termination routines go here, but function cannot be empty
    #clear
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}PyCharm Installer complete, goodbye!"
    # Redirect app output to log, sending both stdout and stderr (*NOTE: this will not parse color codes)
    # cmd_here 2>&1 | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT
