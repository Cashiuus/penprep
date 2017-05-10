#!/usr/bin/env bash
## =======================================================================================
# File:     setup-ansible.sh
# Author:   Cashiuus
# Created:  09-May-2017     Revised:
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Install Ansible and configure initial settings.
#
#
# Notes:
#     OS X - Install via the pip method.
#
#
#   Ansible by default manages machines over SSH.
#   Some modules and plugins have addtl requirements. For modules, these need to be 
#   satisfied on the 'target' machine, and should be listed in the module-specific docs.
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#   - http://ansible.com
#   - https://launchpad.net/~ansible/+archive/ubuntu/ansible
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## =======[ EDIT THESE SETTINGS ]======= ##


## ==========[ TEXT COLORS ]============= ##
# [http://misc.flogisoft.com/bash/tip_colors_and_formatting]
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
ORANGE="\033[38;5;208m" # Debugging
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## =============[ CONSTANTS ]============= ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LINES=$(tput lines)
COLS=$(tput cols)
HOST_ARCH=$(dpkg --print-architecture)      # (e.g. output: "amd64")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
LOG_FILE="${APP_BASE}/debug.log"
DEBUG=true
DO_LOGGING=false
## ========================================================================== ##
## =========================[ START :: LOAD FILES ]========================= ##
if [[ -s "${APP_BASE}/../common.sh" ]]; then
    source "${APP_BASE}/../common.sh"
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source files :: success${RESET}"
else
    echo -e "${RED} [ERROR]${RESET} common.sh functions file is missing."
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source files :: fail${RESET}"
    exit 1
fi
## ==========================[ END :: LOAD FILES ]]========================== ##

check_root

## ========================================================================== ##
# =======================[  START :: HELPER FUNCTIONS  ]====================== #
function pause() {
  # Simple function to pause a script mid-stride
  #
  local dummy
  read -s -r -p "Press any key to continue..." -n 1 dummy
}


function asksure() {
  ###
  # Usage:
  #   if asksure; then
  #        echo "Okay, performing rm -rf / then, master...."
  #   else
  #        echo "Awww, why not :("
  #   fi
  ###
  echo -n "Are you sure (Y/N)? "
  while read -r -n 1 -s answer; do
    if [[ $answer = [YyNn] ]]; then
      [[ $answer = [Yy] ]] && retval=0
      [[ $answer = [Nn] ]] && retval=1
      break
    fi
  done
  echo
  return $retval
}

## ========================================================================== ##
# ================================[  BEGIN  ]================================ #

export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y install software-properties-common

echo -e "\n\n${GREEN}[*]${RESET} Adding ansible repo, you may need to hit ENTER to confirm..."
$SUDO apt-add-repository ppa:ansible/ansible
# This will add a repo file in /sources.list.d/

# This tutorial says to use "xenial" - https://martinlanner.com/2016/10/07/install-ansible-on-debian-8-jessie/
# But official docs say to use "trusty" - https://docs.ansible.com/ansible/intro_installation.html

# Currently, the available versions are (viewed via: apt-cache policy ansible):
#   ansible "trusty" repo has version - 2.3.0.0
#   debian jessie-backports repo - 2.2.1.0--1
#   debian stable repo - 1.7.2

file=/etc/apt/sources.list.d/ansible-ansible-jessie.list
$SUDO sh -c "echo deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main > ${file}"


$SUDO apt-get -qq update
$SUDO apt-get -y install ansible



### Varnish - A fast caching mechanism for web applications
# Ref: http://webdev.passingphase.co.nz/blog/installing-varnish-4x-apache-debian-8-server-jessie-drupal-8
#apt-get install apt-transport-https
#curl https://repo.varnish-cache.org/GPG-key.txt | apt-key add -
#echo "deb https://repo.varnish-cache.org/debian/ jessie varnish-4.1"\
#    >> /etc/apt/sources.list.d/varnish-cache.list
#apt-get update
#apt-get install varnish



function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
  echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"

  FINISH_TIME=$(date +%s)
  echo -e "${BLUE} -=[ Penbuilder${RESET} :: ${BLUE}$APP_NAME ${BLUE}]=- ${GREEN}Completed Successfully ${RESET}-${ORANGE} (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)${RESET}\n"
}
# End of script
trap finish EXIT
## ==================================================================================== ##

# ========[ ansible commands ]===========
#	List of commands:
#	ansible, ansible-connection, ansible-console, ansible-doc
#	ansible-galaxy, ansible-playbook, ansible-pull, ansible-vault


# Ansible Vault
# 	http://docs.ansible.com/ansible/playbooks_vault.html



# -== Running a Playbook With Vault ==-
# To run a playbook that contains vault-encrypted data files, you must pass one of two flags. To specify the vault-password interactively:
#
#	ansible-playbook site.yml --ask-vault-pass
#
# This prompt will then be used to decrypt (in memory only) any vault encrypted files that are accessed. Currently this requires that all files be encrypted with the same password.
#
# Alternatively, passwords can be specified with a file or a script, the script version will require Ansible 1.7 or later. When using this flag, ensure permissions on the file are such that no one else can access your key and do not add your key to source control:
#
#	ansible-playbook site.yml --vault-password-file ~/.vault_pass.txt
#	ansible-playbook site.yml --vault-password-file ~/.vault_pass.py
# 
# The password should be a string stored as a single line in the file.

## ==================================================================================== ##
