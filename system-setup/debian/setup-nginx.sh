#!/usr/bin/env bash
## =======================================================================================
# File:     setup-nginx.sh
# Author:   Cashiuus
# Created:  09-May-2017     Revised:
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Describe script purpose
#
#
# Notes:
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#
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
$SUDO apt-get -qq update
$SUDO apt-get -y -t jessie-backports install nginx


$SUDO cp -R /etc/nginx /etc/nginx.backup

cd /etc/nginx
$SUDO rm fastcgi.conf
$SUDO rm fastcgi_params
$SUDO rm mime.types

# Add in all our custom settings and files here
$SUDO mkdir -p /etc/nginx/global/server



# Finally, symlink the default to enabled so that all unrecognized domains get 444 response
$SUDO ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

echo -e "${GREEN}[*]${RESET} Testing config, review results below and then press any key to continue..."
$SUDO nginx -t
pause


$SUDO systemctl reload nginx.service


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


## ===================================================================================== ##
## =====================[ Template File Code Help :: Core Notes ]======================= ##
#
## -=====[  BASH/Scripting GUIDES  ]=====- ##
#   - https://lug.fh-swf.de/vim/vim-bash/StyleGuideShell.en.pdf
#   - Google's Shell Styleguide: https://google.github.io/styleguide/shell.xml
#   - Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
#   - Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
#
# -------------------------------
# Shell Script Development Helper Projects
#   https://github.com/alebcay/awesome-shell#shell-script-development
#   https://github.com/jmcantrell/bashful
#   https://github.com/lingtalfi/bashmanager
#
# ---------------------------------------------------------
## =============[ Debugging BASH scripts ]============= ##
#
#   Run the script with debug mode enabled:
#       bash -x script.sh
#
#
## =============[ Styleguide Recommendations ]============= ##
#   line length =   80 (I'm using 90-100 though)
#   functions   =   lower-case with underscores, must use () after func, "function" optional, be consistent
#                   Place all functions at top below constants, don't hide exec code between functions
#                   A function called 'main' is required for scripts long enough to contain other functions
#   constants   =   UPPERCASE with underscores
#   read-only   =   Vars that are readonly - use 'readonly var' or 'declare -r var' to ensure
#   local vars  =   delcare and assign on separate lines
#
#   return vals =   Always check return values and give informative return values
#
#
#
## =============[ Colorize Output ]============= ##
#   *NOTE: Formatting generally works, but Blink does not work on xfce4 terminals.
#
#   Code    Description
#   1         Bold/Bright
#   2         Dim
#   3         Underlined
#   5         Blink
#   7         Reverse (invert fg and bg)
#   8         Hidden




## -===[ set options ]===- ##
#
# set -e
# set -o pipefail  # Bashism
#
## =========[  Expressions/Wildcards  ]========= ##
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
#   [[ $var_string ]]   true if var contains a string, false if null or empty
#
#
## -======[  Booleans  ]======- ##
# The below examples are all ways you can check booleans
#   bool=true
#   if [ "$bool" = true ]; then
#   if [ "$bool" = "true" ]; then
#
#   if [[ "$bool" = true ]]; then
#   if [[ "$bool" = "true" ]]; then
#   if [[ "$bool" == true ]]; then
#   if [[ "$bool" == "true" ]]; then
#
#   if test "$bool" = true; then
#   if test "$bool" = "true"; then
#
#
#
## -====[  Output Suppression/Redirection  ]====- ##
#   >/dev/null 1>&2         Supress all output (1), including errors (2)
#
#   Replace or Append content to files that require sudo privilege to modify:
#       echo "alpha" | sudo tee /etc/some/important/file
#       echo "bravo" | sudo tee -a /etc/some/important/file
#
#
# Redirect app output to log, sending both stdout and stderr
# *NOTE: This method will not parse color codes, therefore fails color output
# cmd_here 2>&1 | tee -a "${LOG_FILE}"
#
#
#
#
## -=====[  Variables  ]=====-
#
#   var1="stuff"
#   readonly var1       Make variable readonly
#   declare -r var1     Another way to make it readonly
#   unset var1          Delete var1
#
#
## -=====[  Loops  ]=====-
#   For, While, Until, Select
#
#   For x in ___; do        done
#
#
#   Infinite loop within a script will cause it to be persistent until CTRL+C
#       while true; do
#           :
#       done
#
## -=====[  ARRAYS (Index starts at [0])  ]=====-
# Create arrays
#   declare -a MYARRAY=(val1 val2 val3...)
#   files=( "/etc/passwd" "/etc/group" "/etc/hosts" )
#   limits=( 10, 20, 26, 39, 48)
#
# Print all items in an array; prints them space-separated, unles you do the \n method below
#   printf "%s\n" "${array[@]}" (or) "${array[*]}"
#   printf "%s\n" "${files[@]}"
#   printf "%s\n" "${limits[@]}"
#   echo -e "${array[@]}"
#
# Loop through an array
#   array=( one two three )
#   for i in "${array[@]}"
#   do
#       echo $i
#   done
#
#
#
## ==================================================================================== ##
## =================[ Template File Code Help :: Built-in Commands ]=================== ##
#
# Nginx Commands
#	
#
# 	Test the configuration
#		sudo nginx -t
# 	Restart nginx
#		sudo /etc/init.d/nginx reload
#
#
# Backup nginx existing config
#	sudo mv /etc/nginx /etc/nginx.backup
#
# Nginx Directory Structure
#	.
#	|- conf.d
#	|- global
#		|- server
#	|- sites-available
#	|- sites-enabled	
#
#
#
# Recommend nginx site structure
#	|- yourdomain1.com
#		|- cache
#		|- logs
#		|- public
#	|- yourdomain2.com
#		|- cache
#		|- logs
#		|- public
#
#
#
## ==================================================================================== ##
