#!/usr/bin/env bash
## =======================================================================================
# File:     file.sh
#
# Author:   Cashiuus
# Created:  09-Mar-2017     Revised:
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Describe script purpose
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#
#
#
#
#-[ Links/Credit ]------------------------------------------------------------------------
#
#
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## ==========[ TEXT COLORS ]========== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
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

# These can be used to know height (LINES) and width (COLS) of current terminal in script
LINES=$(tput lines)
COLS=$(tput cols)
HOST_ARCH=$(dpkg --print-architecture)      # (e.g. output: "amd64")
#INSTALL_USER="user1"

#======[ ROOT PRE-CHECK ]=======#
function install_sudo() {
  # If
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get, elevating to root..."

  su root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to su root${RESET}" && exit 1
  apt-get -y install sudo
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo pkg via apt-get${RESET}" && exit 1
  # Use stored USER value to add our originating user account to the sudoers group
  # TODO: Will this break if script run using sudo? Env var likely will be root if so...test this...
  #usermod -a -G sudo ${ACTUAL_USER}
  usermod -a -G sudo ${INSTALL_USER}
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "${YELLOW}[WARN] ${RESET}Now logging off to take effect. Restart this script after login!"
  sleep 4
  # First logout command will logout from su root elevation
  logout
  exit 1
}

function check_root() {

  # There is an env var that is $USER. This is regular user if in normal state, root in sudo state
  #   CURRENT_USER=${USER}
  #   ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
   # This would only be run if within sudo state
   # This variable serves as the original user when in a sudo state

  if [[ $EUID -ne 0 ]];then
    # If not root, check if sudo package is installed and leverage it
    # TODO: Will this work if current user doesn't have sudo rights, but sudo is already installed?
    if [[ $(dpkg-query -s sudo) ]];then
      export SUDO="sudo"
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
    else
      echo -e "${YELLOW}[WARN] ${RESET}The 'sudo' package is not installed. Press any key to install it (*must enter sudo password), or cancel now"
      read -r -t 10
      install_sudo
      # TODO: This error check necessary, since the function "install_sudo" exits 1 anyway?
      [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Please install sudo or run this as root. Exiting.${RESET}" && exit 1
    fi
  fi
}
check_root
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #













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


function check_version_java() {
  ###
  #   Check the installed/active version of java
  #
  #   Usage: check_version_java
  #
  ###
  if type -p java; then
    echo found java executable in PATH
    _java=java
  elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo found java executable in JAVA_HOME
    _java="$JAVA_HOME/bin/java"
  else
    echo "no java"
  fi

  if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo version "$version"
    if [[ "$version" > "1.5" ]]; then
      echo version is more than 1.5
    else
      echo version is less than 1.5
    fi
  fi
}


function make_tmp_dir() {
  # <doc:make_tmp_dir> {{{
  #
  # This function taken from a vmware tool install helper to securely
  # create temp files. (installer.sh)
  #
  # Usage: make_tmp_dir dirname prefix
  #
  # Required Variables:
  #
  #   dirname
  #   prefix
  #
  # Return value: null
  #
  # </doc:make_tmp_dir> }}}

  local dirname="$1" # OUT
  local prefix="$2"  # IN
  local tmp
  local serial
  local loop

  tmp="${TMPDIR:-/tmp}"

  # Don't overwrite existing user data
  # -> Create a directory with a name that didn't exist before
  #
  # This may never succeed (if we are racing with a malicious process), but at
  # least it is secure
  serial=0
  loop='yes'
  while [ "$loop" = 'yes' ]; do
  # Check the validity of the temporary directory. We do this in the loop
  # because it can change over time
  if [ ! -d "$tmp" ]; then
    echo 'Error: "'"$tmp"'" is not a directory.'
    echo
    exit 1
  fi
  if [ ! -w "$tmp" -o ! -x "$tmp" ]; then
    echo 'Error: "'"$tmp"'" should be writable and executable.'
    echo
    exit 1
  fi

  # Be secure
  # -> Don't give write access to other users (so that they can not use this
  # directory to launch a symlink attack)
  if mkdir -m 0755 "$tmp"'/'"$prefix$serial" >/dev/null 2>&1; then
    loop='no'
  else
    serial=`expr $serial + 1`
    serial_mod=`expr $serial % 200`
    if [ "$serial_mod" = '0' ]; then
      echo 'Warning: The "'"$tmp"'" directory may be under attack.'
      echo
    fi
  fi
  done

  eval "$dirname"'="$tmp"'"'"'/'"'"'"$prefix$serial"'
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


function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
  echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"

  FINISH_TIME=$(date +%s)
  echo -e "${GREEN}[*] Kali Base Setup Completed Successfully ${YELLOW} --(Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)--\n${RESET}"
}
# End of script
trap finish EXIT


## ==================================================================================== ##
## =====================[ Template File Code Help :: Scripting ]======================= ##
#
## =================[ BASH GUIDES ]=================== #
# Google's Shell Styleguide: https://google.github.io/styleguide/shell.xml
# Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
# Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
#
# Shell Script Development Helper Projects
#   https://github.com/alebcay/awesome-shell#shell-script-development
#   https://github.com/jmcantrell/bashful
#   https://github.com/lingtalfi/bashmanager
#
#
# Debugging BASH scripts
#
#   Run the script with debug mode enabled:
#       bash -x script.sh
#
#
# =============[ Styleguide Recommendations ]============ #
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
# -===[ set options ]===-
#
# set -e
# set -o pipefail  # Bashism
#
# =========[ Expression Cheat Sheet ]========= #
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
# -======[ Booleans ]======-
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
# -====[ Output Suppression/Redirection ]====-
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
# ============[ Variables ]===============
#
#   var1="stuff"
#   readonly var1       Make variable readonly
#   declare -r var1     Another way to make it readonly
#   unset var1          Delete var1
#
#
# =========[ Loops ]========
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
# ===============[   ARRAYS  (Index starts at [0])   ]==================
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
#
# -=====[ cp (copy) ]=====-
#   cp [OPTION]... SOURCE...DIRECTORY
#       -a          archive. same as -dR --preserve=all
#       -b          make a backup of each existing destination file
#       -n          --no-clobber, Do not overwrite an existing file
#       -R, -r      recursively copy all files and subdirectories
#       -u          --update, copy only when SOURCE file is newer than DEST file
#       -f          --force, force the copy
#       -l          --link, hard link the files instead of copying
#       -s          --symbolic-link, make symbolic links instead of copying
#
#       --preserve[=ATTR_LIST]          Preserve specified attributes (Default: mode,ownership,timestamps)
#                                       If possible, addtl attributes: context, links, xattr, all
#       --no-preserve[=ATTR_LIST]       Don't preserve
#       --strip-trailing-slashes        remove trailing slashes from any sources arguments
#       -Z                              Set SELinux security context of dest file to default type
#
# Copy all files in current folder to $HOME/, preserving attributes, used in copying dotfiles
# TODO: Did this work? or does it fail like recent cp/mv operations have showed requiring setglobopt's
#       cp -a . $HOME/
#
# -=====[ ECHO/PRINTF Commands ]=====-
#   echo -n         Print without a newline
#
# Run echo and cat commands through sudo (notice the single quotes)
# sudo sh -c 'echo "strings here" >> /path/to/file'
#
# Pipe user input into a script to automate its input execution; this'll hit enter for all inputs
# echo -e '\n' | timeout 300 perl vmware-install.pl
#
#
#
# ===============[ READ / READLINE Commands ]=============== #
#   Ref: http://wiki.bash-hackers.org/commands/builtin/read
#
#   The read command reads a line of input and separates the line into individual words using the IFS
#   inter field separator. Each word in the line is stored in a variable from left to right. If there
#   are fewer variables than words, then all remaining words are stored in the last variable. If there
#   are more variables than words, then all remaining variables are set to NULL. If no variable is
#   specified, it uses the default variable REPLY.
#
#   read [-ers] [-u <FD>] [-t <TIMEOUT>] [-p <PROMPT>] [-a <ARRAY>] [-n <NCHARS>] [-d <DELIM>] [-i <TEXT>] [<NAME...>]
#
#   -p ""       Instead of echoing text, provide it right in the "prompt" argument
#               *NOTE: Typically, there is no newline, so you may need to follow
#                      this with an "echo" statement to output a newline.
#   -n #        read returns after reading # chars
#   -t #        read will timeout after TIMEOUT seconds. Only from a Terminal
#               (or) you can use the shell timeout variable TMOUT.
#   -s          Silent mode. Characters are not echoed coming from a Terminal (useful for passwords)
#   -r          Raw input; Backslash does not act as an escape character
#               *NOTE: According to wiki, you should ALWAYS use -r
#   -a ANAME    words are assigned sequentially to the array variable ANAME
#                   You can also set individual array elements: read 'MYARRAY[5]' - quotes important
#                   without them, path expansion can break the script!
#   -d DELIM    recognize DELIM as data-end, instead of the default <newline>
#   -u FD       read input from File Descriptor FD
#
#   *NOTE: User must hit enter or what they type will not be stored, including if timeout
#          triggers before user presses enter so be sure to include enough time for user.
#
#   *NOTE: If you specify -e, the 'readline' package is used and the remaining below params are available.
#   -e      On interactive shells, tells it to use BASH's readline interface to read the data
#   -i ""   Specify a default value. If user hits ENTER, this value is saved
#
#  -= RETURN STATUSES =-
#   0       no error
#   2       invalid options
#   >128    timeout
#   !=0     invalid fd supplied to -u
#   !=0     end-of-file reached
#
#  -= EXAMPLES =-
# Ask for a path with a default value
#   read -r -e -p "Enter the path to the file: " -i "/usr/local/etc/" FILEPATH
#
# Ask for a path with a default value and 5-second timeout - TODO: this work?
#   read -e -r -n 5 -p "Enter the path to the file: " -i "/usr/local/etc/" FILEPATH
#
# A "press any key to continue..." solution like pause in MS-DOS
#   function pause() {
#       local dummy
#       read -s -r -p "Press any key to continue..." -n 1 dummy
#   }
#
#
# -==[ TOUCH ]==-
#touch
#touch "$file" 2>/dev/null || { echo "Cannot write to $file" >&2; exit 1; }
#
#
#
#
#
#
# -==[ TIMEOUT ] ==-
#
# Launch executables from within a script and set a timeout so it also exits
#   timeout 10 python /opt/sickrage/SickBeard.py
#
#
#
#
#
# ===============[ STRING Parsing/Handling ]=============== #
# -==[ GREP ]==-
#
#
#
#
#
#
#
# -==[ SED ]==-
# NOTE: When using '/' for paths in sed, use a different delimiter, such as # or |
#
#sed -i 's/^.*editor_font=.*/editor_font=Monospace\ 10/' "${file}"
#sed -i 's|^.*editor_font=.*|editor_font=Monospace\ 10|' "${file}"
#
#
#
# Parsing a simple date/time string
#   datetime="2008:07:04 00:34:45"
#   IFS=": " read -r year month day hour minute second <<< "$datetime"
#
#
#
# Remove leading whitespace only
#   str_cleaned="$(echo -e "${str_original}" | sed -e 's/^[[:space:]]*//')"
# Remove trailing whitespace only
#   str_cleaned="$(echo -e "${str_original}" | sed -e 's/[[:space:]]*$//')"
# Remove both leading and trailing whitespace
#   str_cleaned="$(echo -e "${str_original}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
#
# Or if BASH supports it, you can do whitespace removing this way (instead of using 'echo -e'):
#   str_cleaned="$(sed -e 's/[[:space:]]*$//' <<<${FOO})"
#
#
#
#
### ==================================================================================== ##
## ================[ Template File Code Help :: Create Files Recipes ]================== ##
#
### Workaround to create files within scripts and still use $SUDO
# TODO: Will this still work if the target file already exists?
#   file="/etc/systemd/system/sickrage.service"
#   # Create file and set permissions so that we can build it
#   $SUDO touch "${file}"
#   $SUDO chmod -f 0666 "${file}"
#   $SUDO cat <<EOF > "${file}"
#   #File content here
#   #here
#
#   #and here
#   EOF
#   # Now set appropriate permissions (u:rx,g:rx,a:rx)
#   $SUDO chmod -f 0555 "${file}"
#
#
# -==[ Parse/Read a config file using whitelisting ]==-
#
#   CONFIG_FILE="/path/here"
#   # Declare a whitelist
#   CONFIG_SYNTAX="^\s*#|^\s*$|^[a-zA-Z_]+='[^']*'$"
#   # Check if file contains something we don't want
#   if egrep -q -v "${CONFIG_SYNTAX}" "$CONFIG_PATH"; then
#       echo "Error parsing config file ${CONFIG_PATH}." >&2
#       echo "The following lines in the configfile do not fit the syntax:" >&2
#       egrep -vn "${CONFIG_SYNTAX}" "$CONFIG_PATH"
#       exit 5
#   fi
#   # Otherwise go on and source it:
#   source "${CONFIG_FILE}"
#
#
#
## ==================================================================================== ##
## ===============[ Template File Code Help :: Miscellaneous Examples ]================ ##
#
# List the most recently updated file matching the pattern
#   ls -t setup-*.sh | head -n 1
# Or we can run the file returned from this pattern
#   java -Xmx4G "$(ls -t setup-*.sh | head -n 1)"
