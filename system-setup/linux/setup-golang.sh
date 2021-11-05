#!/usr/bin/env bash
## =======================================================================================
# File:     setup-golang.sh
# Author:   Cashiuus
# Created:  20-Jun-2021     Revised:
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  My preferred approach is to:
#               1. install the standard golang for the OS you are on (apt-get, etc)
#               2. Use that base golang install to "go get" newer versions (1.16)
#               3. Use the newer versions to install and run all my tools (go1.16.5 cmd)
#
#           This prevents me from having to install tools in all different ways
#           (e.g. go get amass versus snap install amass)
#
#
# Notes:
#           Golang installation best practices:
#             *
#             * GOPATH - installed apps will go here
#             * Dotfiles/Path:
#               * Append GOPATH to your PATH in your .bashrc/.zshrc file
#               * Goal being you have go apps (amass, etc) in your path both
#                 interactively in terminal, and also accessible within scripts
#
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#   * https://golang.org/doc/manage-install
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## ==========[ TEXT COLORS ]============= ##
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

## =======[ EDIT THESE SETTINGS ]======= ##
GO_LATEST_VERSION=$(curl -s https://golang.org/VERSION?m=text)

function check_root() {
  if [[ $EUID -ne 0 ]]; then
    # If not root, check if sudo package is installed
    if [[ $(which sudo) ]]; then
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
      export SUDO="sudo"
      echo -e "\n${YELLOW}[WARN] This script leverages sudo for installation. Enter your password when prompted!${RESET}"
      sleep 1
      # Test to ensure this user is able to use sudo
      sudo -l >/dev/null
      if [[ $? -eq 1 ]]; then
        # sudo pkg is installed but current user is not in sudoers group to use it
        echo -e "${RED}[ERROR]${RESET} You are not able to use sudo. Running install to fix."
        read -r -t 5
        install_sudo
      fi
    else
      echo -e "${YELLOW}[WARN]${RESET} The 'sudo' package is not installed."
      echo -e "${YELLOW}[+]${RESET} Press any key to install it (*You'll be prompted to enter sudo password). Otherwise, manually cancel script now..."
      read -r -t 5
      install_sudo
    fi
  fi
}
check_root

function program_exists() {
  #
  # Usage: if program_exists go; then
  #
  # Check if a program is not installed (use -n to check the opposite way)
  if [[ "$(command -v $1 2>&1)" ]]; then
  #if [[ $(command -v go &>/dev/null) ]]; then
    return 1
  else
    return 0
  fi
}
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #

if [[ program_exists go ]]; then
    GO_VERSION=$(go version | cut -d " " -f 3)
    echo -e "[*] Go is already installed, found version: $GO_VERSION"
fi

# --[ OS Check ]--
OS_TYPE=$(lsb_release -sd | awk '{print $1}')
echo -e "${GREEN}[*] Your current OS:${RESET} $OS_TYPE"
if [[ "$OS_TYPE" = "Kali" || "$OS_TYPE" = "Debian" ]]; then
    # As of now, Kali is 1.16 and Debian 1.15
  $SUDO apt-get -y install git golang
elif [[ "$OS_TYPE" = "Ubuntu" ]]; then
    # As of now, Ubuntu is 1.13
  $SUDO apt-get -y install git golang
else
  echo -e "${RED}[ERR]${RESET} OS Not recognized or unsupported. Exiting script!"
  exit 1
fi


# Ensure path is correct to successfully finish install
# You will want to make sure to put these variables into your dotfiles!
# NOTE: kali installs Go 1.16 with GOROOT actually at /usr/lib/go-1.16/
if [[ "$OS_TYPE" = "Kali" ]]; then
  export GOROOT=/usr/lib/go
else
  export GOROOT=/usr/local/go
fi
export GOPATH="${HOME}/go"
export PATH=$GOROOT:$GOPATH:$PATH:$HOME/.local/bin


# Once we have a standard Go install, we can install newer versions if needed
#go get golang.org/dl/go1.17
go get golang.org/dl/"$GO_LATEST_VERSION"
go"$GO_LATEST_VERSION" download


# NOTE: These newer version golang binaries are in same dir as all installed tools, $HOME/go/bin
echo -e "====================================="
echo -e "  OS go install root: `go env GOROOT`"
echo -e "  OS go install bin: `whereis go`"
echo -e ""
echo -e "  Latest go install root: `$GO_LATEST_VERSION env GOROOT`"
echo -e "  Latest go install bin: `whereis $GO_LATEST_VERSION`"
echo -e "\n\n"
echo -e "====================================="

[[ $(command -v updatedb 2>/dev/null) ]] && $SUDO updatedb


# TODO: Resolve best practice here. Change symlink, or just use full go1.17 to use newer version?

# original symlink setup by apt-get, may need to restore original go in future
#$SUDO ln -s /usr/lib/go-1.15/bin/go /usr/bin/go


# We could possibly change the symlink...
#$SUDO rm -rf /usr/bin/go
#$SUDO ln -s ${HOME}/go/bin/${GO_LATEST_VERSION} /usr/bin/go



exit 0


## ========================================================================== ##



# To install addtl versions of Go, just `go get` like any compiled app
#go get golang.org/dl/go1.10.16

# To run commands with this newer version, append version to any command
#go1.10.16 version
#go1.10.16 env GOROOT

