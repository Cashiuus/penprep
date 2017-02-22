#!/bin/bash
## =============================================================================
# File:     setup-gophish.sh
#
# Author:   Cashiuus
# Created:  02/04/2016
# Revised:
#
# Purpose:
# Project: https://github.com/gophish/gophish
# User Guide: http://getgophish.com/documentation/Gophish%20User%20Guide.pdf
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
ENABLE_HTTPS=true

# =============================[      ]================================ #
apt-get -y install golang
[[ ! -d ~/workspace ]] && mkdir -p ~/workspace
cd ~/workspace
file="${HOME}/.bashrc"
grep -q 'GOPATH="\${HOME}/workspace"' "${file}" || echo 'export GOPATH="${HOME}/workspace"' >> "${file}"

source "${HOME}/.bashrc"

#cat <<EOF >
## Go Lang PATH support
#export GOPATH="${HOME}/workspace"
#EOF

go get github.com/gophish/gophish
cd ~/workspace/src/github.com/gophish/gophish
go build


function enable_tls() {
    echo -e "[*] Configuring TLS for enabling HTTPS Gophish Web Server"
    filedir="${HOME}/workspace/src/github.com/gophish/gophish"
    file="${HOME}/workspace/src/github.com/gophish/gophish/config.json"

    # Generate a Certificate to enable TLS
    apt-get -y install openssl-server
    openssl req -newkey rsa:2048 -nodes -keyout "${filedir}/gophish.key" -x509 -days 365 -out "${filedir}/gophish.crt"

    #"use_tls" : true,
    #"cert_path" : "gophish.crt",
    #"key_path" : "gophish.key"

    # TODO: Make this better, but for now, just open the config.json for manual editing
    nano "${file}"
}

# Modify settings if you wish - config.json
#admin_server.listen_url


[[ $ENABLE_HTTPS ]] && enable_tls

cd ~/workspace/src/github.com/gophish/gophish
#TODO: gophish doesn't fork to background properly
./gophish &

if [[ $? -eq 0 ]]; then
    echo -e "[*] Default User: admin"
    echo -e "[*] Default Pass: gophish"
    [[ $ENABLE_HTTPS ]] && https://localhost:3333 & || http://localhost:3333 &
else
    echo -e "[ERROR] Something went wrong. so lame."
    exit 1
fi




function finish {
    # Any script-termination routines go here
    clear
}
# End of script
trap finish EXIT


# ================[ Gophish Templates/Landing Pages Available Variables ]====================
#   {{.FirstName}}  The target’s first name
#   {{.LastName}}   The target’s last name
#   {{.Position}}   The target’s position
#   {{.From}}       The spoofed sender
#   {{.TrackingURL}} The URL to the tracking handler
#   {{.Tracker}}    An alias for <img src=”{{.TrackingUrl}}”/>
#   {{.URL}}        The phishing URL
# ============================================================================================





# ================[ Expression Cheat Sheet ]=============================
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





# ==================[ GUIDES ]======================

# Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
# Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
