#!/bin/bash
## =============================================================================
# File:     setup-artillery.sh
#
# Author:   Cashiuus
# Created:  01/27/2016
# Revised:
#
# Purpose:
#
## =============================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##


# =============================[      ]================================ #

cd ~/git
git clone https://github.com/BinaryDefense/artillery
cd artillery
sudo python setup.py
cd /var/artillery
#sudo nano config

# =============================[ Artillery Config ]================================ #



MONITOR_FOLDERS="/var/www","/etc/"

MONITOR_FREQUENCY="60"

SSH_DEFAULT_PORT_CHECK="ON"

EXCLUDE=""

# Dirs/Files active due to "apt-get install unattended-upgrades":
#   /etc/apt/apt.conf.d/
#   /etc/pm/sleep.d/
#   /etc/rc0.d/K01unattended-upgrades
#   /etc/init.d/.depend.start
#   /etc/init.d/unattended-upgrades


HONEYPOT_BAN="OFF"

HONEYPOT_AUTOACCEPT="ON"

# Ports to spawn honeypot for
PORTS="135,445,22,1433,3389,8080,21,5900,25,53,110,1723,1337,10000,5800,44443"

EMAIL_ALERTS="OFF"

SMTP_USERNAME=""

SMTP_PASSWORD=""

ALERT_USER_EMAIL="user@whatever.com"

SMTP_FROM="Artillery Incident"

SMTP_ADDRESS="smtp.gmail.com"

SMTP_PORT="587"

# 600 = 10 minutes
EMAIL_FREQUENCY="600"

SSH_BRUTE_MONITOR="ON"

SSH_BRUTE_ATTEMPTS="4"

FTP_BRUTE_MONITOR="OFF"

FTP_BRUTE_ATTEMPTS="4"

ANTI_DOS_PORTS="80,443"

# Enable or disable checking for insecure root permissions in web server directory
ROOT_CHECK="ON"

# If using a remote, change to REMOTE
SYSLOG_TYPE="LOCAL"

SYSLOG_REMOTE_HOST="192.168.0.1"

SYSLOG_REMOTE_PORT="514"

# Wipe banlist after so long and start fresh
RECYCLE_IPS="OFF"

# Interval to wipe and start fresh - Default: 7 days
ARTILLERY_REFRESH="604800"

# Pull feeds from other sources
SOURCE_FEEDS="ON"





function finish {
    # Any script-termination routines go here, but function cannot be empty
    clear
}
# End of script
trap finish EXIT

# ================[ Expression Cheat Sheet ]==================================
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
#   [[ $? -eq 0 ]]    Previous command was successful
#   [[ ! $? -eq 0 ]]    Previous command NOT successful
#

# --- TOUCH
#touch
#touch "$file" 2>/dev/null || { echo "Cannot write to $file" >&2; exit 1; }

### ---[ READ ]---###
#   -p ""   Instead of echoing text, provide it right in the "prompt" argument
#               *NOTE: Typically, there is no newline, so you may need to follow
#               this with an "echo" statement to output a newline.
#   -e      Specify variable response is stored in. Arg can be anywhere,
#           but variable is always at the end of the statement
#   -n #    Number of seconds to wait for a response before continuing automatically
#   -i ""   Specify a default value. If user hits ENTER or doesn't respond, this value is saved
#

#Ask for a path with a default value
#read -p "Enter the path to the file: " -i "/usr/local/etc/" -e FILEPATH





# ==================[ BASH GUIDES ]====================== #

# Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
# Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
