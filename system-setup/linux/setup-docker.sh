#!/usr/bin/env bash
## =======================================================================================
# File:     setup-docker.sh
#
# Author:   Cashiuus
# Created:  09-Mar-2017     Revised: 16-Jan-2022
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Install and configure Docker
#     using official repositories. After install, adds user to
#     docker group, starts service, and sets it to autostart.
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#
#
# - Docker Docs:
#     - https://docs.docker.com/engine/install/debian/
#     - https://docs.docker.com/compose/install/
#
# - Troubleshooting:
#     - https://docs.docker.com/engine/installation/linux/linux-postinstall/#kernel-compatibility
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.2.2"
__author__="Cashiuus"
## =============[ CONSTANTS ]============== ##
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
DEBUG=false
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
  #        echo "Pfff..."
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
  echo # just a final linefeed, optics...
  return $retval
}


function is_process_alive() {
  # Checks if the given pid represents a live process.
  # Returns 0 if the pid is a live process, 1 otherwise
  #
  # Usage: is_process_alive 29833
  #   [[ $? -eq 0 ]] && echo -e "Process is alive"

  local pid="$1" # IN
  ps -p $pid | grep $pid > /dev/null 2>&1
}
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #
# NOTE: Docker only works on 64-bit Linux

$SUDO apt-get -qq update
$SUDO apt-get remove --purge docker
# Full list of apps to remove: docker docker-engine docker.io containerd runc
# This one may fail so running them separately
$SUDO apt-get remove --purge docker-engine

# Contents of previous installations may be in /var/lib/docker/


# ========[  Setup the Docker repository ]========== #
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y install apt-transport-https ca-certificates \
  curl gnupg gnupg-agent jq lsb-release software-properties-common



# Set up the stable repository. You always need the stable repository,
# even if you want to install builds from the edge or test repositories
# as well. To add the edge or test repository, add the word edge or test
# (or both) after the word stable in the commands below.

OS=$(. /etc/os-release; echo "$ID")

if [[ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
  if [[ $OS == "kali" ]];then
    #curl -fsSL https://download.docker.com/linux/debian/gpg | $SUDO apt-key add -
    curl -fsSL https://download.docker.com/linux/debian/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    $SUDO chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg
    echo -e "${GREEN}[*]${RESET} Adding docker repository"
    #$SUDO add-apt-repository \
    #"deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID_LIKE") \
    #buster \
    #stable"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    buster stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
  else
    #curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | $SUDO apt-key add -
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    $SUDO chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg
    echo -e "${GREEN}[*]${RESET} Adding docker repository"
    #$SUDO add-apt-repository \
    #"deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    #$(lsb_release -cs) \
    #stable"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi
fi
# Verify key via: sudo apt-key fingerprint

if [[ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
  echo -e "${RED}[ERR]${RESET} Failed to setup docker gpg keyring. Check and try again!"
  exit 1
fi


### Install Docker Engine

# If you don't specify a version, it will install the latest release
#   List available versions:  apt-cache madison docker-ce
#   Better:           $(apt-cache madison docker-ce | cut -d '|' -f2)
#   Specify Install Version:  "sudo apt-get -y install docker-ce=18.06.1~ce~3-0~debian"
echo -e "${GREEN}[*]${RESET} Installing Docker-CE via apt-get..."
$SUDO apt-get -qq update
$SUDO apt-get -y install docker-ce docker-ce-cli containerd.io


# How to list available versions if you require a specific docker version on a production system
#apt-cache madison docker-ce
# Output: docker-ce | 17.06.0~ce-0~debian | https://download.docker.com/linux/debian jessie/stable amd64 Packages
# Install a specific version
#sudo apt-get install docker-ce=<VERSION_STRING>


# ==================================================================== #
#                       Install Docker Compose
# ==================================================================== #

# Download the release binary from their Github releases
# Site: https://github.com/docker/compose/releases
$SUDO curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$SUDO chmod +x /usr/local/bin/docker-compose
# If /usr/local/bin isn't typically in your path, you can symlink it
#$SUDO ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Setup bash/zsh completions
# Place the completion script in /etc/bash_completion.d/
echo -e "${GREEN}[*]${RESET} Your current shell is $SHELL_NAME. Adding docker completions for it now."
if [[ "$SHELL_NAME" == "bash" ]]; then
  $SUDO curl -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
elif [[ "$SHELL_NAME" == "zsh" ]]; then
  mkdir -p ~/.zsh/completion > /dev/null
  curl \
    -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/zsh/_docker-compose \
    -o ~/.zsh/completion/_docker-compose
  # Add this dir to your fpath
  grep -q '^fpath=' "${SHELL_FILE}" 2>/dev/null \
    || echo 'fpath=(~/.zsh/completion $fpath)' >> "${SHELL_FILE}"
  grep -q '^autoload -Uz' "${SHELL_FILE}" 2>/dev/null \
    || echo 'autoload -Uz compinit && compinit -i' >> "${SHELL_FILE}"
  # reload your shell
  #exec $SHELL -l
fi


### =========[ Manage Docker as a Non-Root User ]======== ###
# Ref: https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
# You must do these steps on a Debian system, or docker commands will fail due to permissions

# Create group 'docker' -- may already exist
echo -e "${GREEN}[*]${RESET} Configuring user ${ORANGE}${USER}${RESET} into the docker group"
$SUDO groupadd docker 2>/dev/null
# Add current user to group 'docker'
$SUDO usermod -aG docker $USER
newgrp docker

echo -e "${GREEN}[*]${RESET} User has been added to to the docker group"
echo -e "${GREEN}[*]${RESET} Logout and back in. Then, you should be able to run 'docker run hello-world' and 'docker info' without sudo"
sleep 5s

# If you ran 'sudo docker run ...' before adding non-root capability, you
# will now need to fix the default ~/.docker/ directory permissions
if [[ $EUID -ne 0 ]]; then
  if [[ -d "$HOME/.docker" ]]; then
    $SUDO chown "$USER":"$USER" /home/"$USER"/.docker -R
    $SUDO chmod g+rwx "$HOME/.docker" -R
  fi
else
  echo -e "${YELLOW}[WARN]${RESET} You are already root, skipping permissions changes"
fi

# Start the service
echo -e "${GREEN}[*]${RESET} Starting Docker daemon service"
$SUDO systemctl start docker.service
#$SUDO systemctl start containerd.service
# Set it for autostart
echo -e "${GREEN}[*]${RESET} Setting Docker service to autostart on boot"
$SUDO systemctl enable docker.service
#$SUDO systemctl enable containerd.service

# Default Ubuntu container for testing
#docker run -it ubuntu bash

# Customize Docker daemon (e.g. add HTTP proxy, different directory, etc.)
# Ref: https://docs.docker.com/engine/admin/systemd/


# Verify it's working
echo -e "\n\n${GREEN}[*]${RESET} Docker installation complete. After script ends, verify it was successful by logging out and back in for group to take effect. Then, run: docker run hello-world."


function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
  echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..."

  FINISH_TIME=$(date +%s)
  echo -e "${BLUE} -=[ Penbuilder${RESET} :: ${BLUE}$APP_NAME ${BLUE}]=- ${GREEN}Completed Successfully ${RESET}-${ORANGE} (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)${RESET}\n"
}
# End of script
trap finish EXIT


## ===================================================================================== ##
## =========================[ File Code Help :: Core Notes ]============================ ##
#
# Enable the backports repository
#echo -e "${GREEN}[*]${RESET} Creating backports repo file in /sources.list.d/"
#file=/etc/apt/sources.list.d/backports.list
#[[ ! -s "${file}" ]]; then
# $SUDO sh -c "echo deb http://httpredir.debian.org/debian jessie-backports main contrib non-free > ${file}"
#fi
## =========[    ]========= ##

## ==================================================================================== ##

## =================[  ]=================== ##

## ==================================================================================== ##
