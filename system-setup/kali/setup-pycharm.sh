#!/usr/bin/env bash
## =======================================================================================
# File:     setup-pycharm.sh
#
# Author:   Cashiuus
# Created:  10-Dec-2016     Revised: 10-Mar-2017
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
__version__="0.1"
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

# TODO: Get latest pycharm version programmatically
PYCHARM_VERSION="2016.3.2"

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
    apt-get install openjdk-8-jdk
    # Fix any dependency issues
    apt-get -f install
else
    echo -e "${GREEN}[*] ${RESET} Java detected, continuing with installation"
fi


# Save our preferences/settings before getting rid of old versions
[[ ! -d ${HOME}/Backups ]] && mkdir -p ${HOME}/Backups
if [[ -d ${HOME}/.PyCharm2016.2 ]]; then
    cp ${HOME}/.PyCharm2016.2/config/settings.jar ${HOME}/Backups/
elif [[ -d ${HOME}/.PyCharm2016.3 ]]; then
    cp ${HOME}/.PyCharmCE2016.3/config/settings.jar ${HOME}/Backups/
fi

# https://confluence.jetbrains.com/display/PYH/Previous+PyCharm+Releases
# https://www.jetbrains.com/pycharm/download/download-thanks.html?platform=linux
cd /tmp
wget --no-verbose http://download.jetbrains.com/python/pycharm-community-${PYCHARM_VERSION}.tar.gz
#wget -q https://download-cf.jetbrains.com/python/pycharm-community-${PYCHARM_VERSION}.tar.gz
tar xzf pycharm-community-${PYCHARM_VERSION}.tar.gz

rm /tmp/pycharm-community-${PYCHARM_VERSION}.tar.gz

# TODO: Can we simply overwrite the files, or should we delete the old folder first?
rm -rf /opt/pycharm-community/

# Move into permanent install path and then delete tmp files
mv /tmp/pycharm-community* /opt/pycharm-community


# Create permanent symlinks so we can easily open pycharm going forward
[[ ! -f /usr/local/bin/pycharm ]] && ln -s /opt/pycharm-community/bin/pycharm.sh /usr/local/bin/pycharm
[[ ! -f /usr/local/bin/inspect ]] && ln -s /opt/pycharm-community/bin/inspect.sh /usr/local/bin/inspect


# This site mentions a server for a server key that will validate Professional versions licensing
#http://www.psudobyte.com/2016/05/install-pycharm-professional.html
#Server key = http://idea.qinxi1992.cn

# Copy the PyCharm Icon over to our default applications pool
cp /opt/pycharm-community/bin/pycharm.png /usr/share/applications/

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
chmod +x "${file}"


function finish {
    # Any script-termination routines go here, but function cannot be empty
    #clear
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}Installer shutting down, please wait..." | tee -a "${LOG_FILE}"
    # Redirect app output to log, sending both stdout and stderr (*NOTE: this will not parse color codes)
    # cmd_here 2>&1 | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT

## ========================================================================== ##
## =====================[ Template File Syntax Help ]======================== ##

# Run echo and cat commands through sudo (notice the single quotes)
# sudo sh -c 'echo "strings here" >> /path/to/file'


# =========[ Expression Cheat Sheet ]=========
#
#   -d      file exists and is a directory
#   -e      file exists
#   -f      file exists and is a regular file
#   -h      file exists and is a symbolic link
#   -s      file exists and size greater than zero
#   -r      file exists and has read permission
#   -w      file exists and write permission granted
#   -x      file exists and execute permission granted
#   -z      file is size zero (empty)
#
#   $#      Number of arguments passed to script by user
#   $@      A list of available parameters (*avoid using this)
#   $?      The exit value of the command run before requesting this
#   $0      Name of the running script
#   $1..5   Arguments given to script by user
#   $$      Process ID of the currently-running shell the script is running in
#
#   [[ $? -eq 0 ]]      Previous command was successful
#   [[ $? -ne 0 ]]      Previous command NOT successful
#
#
# ====[ READ ]==== #
#   -p ""   Instead of echoing text, provide it right in the "prompt" argument
#               *NOTE: Typically, there is no newline, so you may need to follow
#               this with an "echo" statement to output a newline.
#   -e      Specify variable response is stored in. Arg can be anywhere,
#           but variable is always at the end of the statement
#   -n #    Number of seconds to wait for a response before continuing automatically
#   -i ""   Specify a default value. If user hits ENTER or doesn't respond, this value is saved
#
# Ask for a path with a default value
#   read -n 5 -p "Enter the path to the file: " -i "/usr/local/etc/" -e FILEPATH
#   echo -e ""

# ====[ TOUCH ]==== #
#touch
#touch "$file" 2>/dev/null || { echo "Cannot write to $file" >&2; exit 1; }

# ====[ SED ]==== #
#sed -i 's/^.*editor_font=.*/editor_font=Monospace\ 10/' "${file}"
#sed -i 's|^.*editor_font=.*|editor_font=Monospace\ 10|' "${file}"

# ==================[ BASH GUIDES ]====================== #
# Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
# Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
