#!/usr/bin/env bash
## =============================================================================
# File:     file.sh
# Author:   Cashiuus
# Created:  20-Jan-2022     Revised:
#
##-[ Info ]---------------------------------------------------------------------
# Purpose:  Describe script purpose
#
#
#
##-[ Links/Credit ]-------------------------------------------------------------
#
#
##-[ Copyright ]----------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =============================================================================
__version__="0.0.1"
__author__="Cashiuus"
## =======[ EDIT THESE SETTINGS ]======= ##


## ==========[  TEXT COLORS  ]============= ##
# [http://misc.flogisoft.com/bash/tip_colors_and_formatting]
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
RESET="\033[00m"        # Normal
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings (some terminals its yellow)
RED="\033[01;31m"       # Errors
BLUE="\033[01;34m"      # Headings
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Normal fg color, but bold
ORANGE="\033[38;5;208m" # Debugging
BGRED="\033[41m"        # BG Red
BGPURPLE="\033[45m"     # BG Purple
BGYELLOW="\033[43m"     # BG Yellow
BGBLUE="\033[104m"      # White font with blue background (could also use 44)
## =============[  CONSTANTS  ]============= ##
TDATE=$(date +%Y-%m-%d)
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LINES=$(tput lines)
COLS=$(tput cols)
LOG_FILE="${APP_BASE}/debug.log"
DEBUG=false
DO_LOGGING=false


##  Load Config/Settings File(s)
## =================================== ##
if [[ -s "${APP_BASE}/../common.sh" ]]; then
    source "${APP_BASE}/../common.sh"
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source files :: success${RESET}"
else
    echo -e "${RED} [ERROR]${RESET} common.sh functions file is missing."
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: source files :: fail${RESET}"
    #exit 1
fi


##  Functions/Utilities
## =================================== ##
function echo_prompter() {
  PROMPT="${PROMPT}"
  echo -e "$PROMPT $@"
}

function print() {
  echo -e "${GREEN}[*]${RESET} $1"
}

function print_error() {
  echo -e "${RED}[ERR]${RESET} $1"
}

function print_debug() {
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DBG]${RESET} $1"
}

function check_error() {
  # Run this following a statement. If it failed, return 1, else return 0 (successful)
  #   Usage:  check_error <description of what was attempted>
  #           check_error "Python core installation"
  #           if check_error "stuff"; do # now do stuff that asserts it failed
  if [[ "$?" -eq 0 ]]; then
    print_debug "successful, no errors"
  else
    # Something failed, exit.
    print_error "$1 failed to execute correctly"
    print_debug "$1 failed to execute correctly"
  fi
}

function check_error_exit() {
  # Immediately following any statement, do this to check it was successful, exit if failed
  #   Usage:  check_error <description of what was attempted>
  #           check_error_exit "Python core installation"
  if [[ "$?" -eq 0 ]]; then
    print_debug "successful, no errors"
  else
    # Something failed, exit.
    print_debug "$1 failed. Check and try again"
    #echo -e "$@, exiting." >&2
    exit 1
  fi
}

function help_menu {
  echo -e "\n$APP_NAME - $__version__"
  echo -e "\nUsage: `readlink -f $0` [ARGS]"
  echo -e "\t-i,\t--input FILE    Input file to use"
  echo -e "\t-o,\t--output FILE   Output file to save as"
  echo -e "\n\n"
}

function is_installed() {
  # Check if a program is installed (use -n to check the opposite way)
  #
  #   Usage: if program_exists go; then
  #
  if [[ "$(command -v $1 2>&1)" ]]; then
    # command exists/is installed, so return true
    return 1
  else
    return 0
  fi
}

function install_pkgs() {
  # Install the array of packages provided as $1
  #   Usage: install_pkgs ${pkg_list[@]}
  #   Array: declare -a pkg_list=(gcc git curl make wget)


}



##  Running Main
## =================================== ##
echo -e "${ORANGE} + -- -- -- --=[${RESET}  ${APP_NAME}  ${ORANGE}]=-- -- -- -- +${RESET}"
echo -e "${BLUE}\tAuthor:  ${RESET}${__author__}"
echo -e "${BLUE}\tVersion: ${RESET}${__version__}"
echo -e "${ORANGE} + --=[  https://github.com/cashiuus  ]=-- +${RESET}"
echo -e
echo -e

##  Script Arguments
## ================= ##
while [[ "${#}" -gt 0 && ."${1}" == .-* ]]; do
  opt="${1}";
  shift;
  case "$(echo ${opt} | tr '[:upper:]' '[:lower:]')" in
    -|-- ) break 2;;
    -i|--input)         infile="$1";    shift;; # Shift extra bc it's actually 2 args
    -o|--output)        outfile="$1";   shift;; # Shift extra bc it's actually 2 args
    -update|--update )  update=true;;
    -burp|--burp )      burpPro=true;;

    *) echo -e "${RED}[ERROR]${RESET} Unknown argument passed: ${RED}${opt}${RESET}" 1>&2 \
      && help_menu && exit 1;;
  esac
done

#  Check Internet Connection
echo -e "${GREEN}[*]${RESET} Checking Internet access"
for i in {1..4}; do ping -c 1 -W ${i} google.com &>/dev/null && break; done
if [[ "$?" -ne 0 ]]; then
  for i in {1..4}; do ping -c 1 -W ${i} 8.8.8.8 &/dev/null && break; done
  if [[ "$?" -eq 0 ]]; then
    echo -e "${RED}[ERROR]${RESET} Internet partially working, DNS is failing, check resolv.conf"
    exit 1
  else
    echo -e "${RED}[ERROR]${RESET} Internet is completely down, check IP config or router"
    exit 1
  fi
fi












##  End of Script & Capture CTRL+C
## =================================== ##
function ctrl_c() {
  # Capture pressing CTRL+C during script execution to exit gracefully
  #     Usage:     trap ctrl_c INT
  echo -e "${GREEN}[*]${RESET} CTRL+C was pressed -- Shutting down..."
  trap finish EXIT
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
  echo -e "${BLUE}[ Penbuilder${RESET} :: ${BLUE}$APP_NAME ${BLUE}]${RESET} Completed Successfully - ${ORANGE}(Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)${RESET}\n"
}
# End of script
trap finish EXIT


## ===================================================================================== ##
## =====================[ Template File Code Help :: Core Notes ]======================= ##
#
#
# Recipes for sed/grep
#$SUDO sed -i -E 's/^socks4\s+127.0.0.1\s+9050/#socks4 127.0.0.1 9050/' "${file}"
#
#  grep -q "socks 127.0.0.1 1080" "${file}" 2>/dev/null \
#    || $SUDO sh -c "echo socks4 127.0.0.1 1080 >> ${file}" \
#    && $SUDO sh -c "echo socks5 127.0.0.1 1090 >> ${file}"
#
#
#
#
#
## -=====[  BASH/Scripting GUIDES  ]=====- ##
#   - https://lug.fh-swf.de/vim/vim-bash/StyleGuideShell.en.pdf
#   - Google's Shell Styleguide: https://google.github.io/styleguide/shell.xml
#   - Using Exit Codes: http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/
#   - Writing Robust BASH Scripts: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
#   - Foolproof your Bash Script: https://www.tothenew.com/blog/foolproof-your-bash-script-some-best-practices/
#
# -------------------------------
# Shell Script Development Helper Projects
#   https://github.com/alebcay/awesome-shell#shell-script-development
#   https://github.com/jmcantrell/bashful
#   https://github.com/lingtalfi/bashmanager
#
# ---------------------------------------------------------
## =============[ Debugging BASH scripts/cmds ]============= ##
#
#   * Run the script with debug mode enabled:     bash -x script.sh
#
#   * Syntax check/dry run script:                bash -n script.sh
#
#   * Debug a command (sudo apt-get install strace):  strace <cmd> <args>
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
## =============[ Run a Script from Inside a Script ]============= ##
# URL: https://www.tothenew.com/blog/foolproof-your-bash-script-some-best-practices/
#
#   Method: Sourcing - sub-scripts run in the same process, if they error, whole thing exits
#           However, this method allows the parent to access variables inside the subscripts
#             Ex:     . ./second-script.sh
#
#   Method: Simple execution - sub-scripts run as child process, cannot access/modify existing variables
#           This method allows you to store and act on return status of the subscript also
#             Ex:     ./second-script.sh
#                 or
#                     OUTPUT1=$(./second.sh)
#                     STATUS1=$? && echo $OUTPUT1
#
#   Method: execution with access to variables - call in subshells; separate processes, exit doesn't affect parent.
#           This method, subscripts can access existing variables from parent, but cannot modify them.
#             Ex:     (. ./second-script.sh)
#
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
#
#
#
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
#
## -=====[  cp (copy)  ]=====-
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
# ---= Copy Hidden Files/Directories =--- Testing performed on Debian 10 (man cp shows GNU coreutils 8.30)
#
# Issue:  On Debian 10, by default, this does not work and copies parent
#     directory instead of .envs_template/ subdir:
#       cd ~/git/Ghostwriter && cp -r .envs_templates/.* .envs
#
#     The reason is this asterisk also include copying ".envs_templates/.." !! mind blown!
#     Until I find a better way, you just can't copy dirs that start with '.' this way.
#     Instead, just do it like this:
#       # Enable copying/moving of hidden files
#       shopt -s dotglob
#       # Now issue the wildcard copy
#       cp -r .envs_template/* .envs/
#
# (or)    cp -r .envs_template/{.local,.production} .envs/
#
#

## -=====[  ECHO/PRINTF  ]=====-
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
## -=====[  READ / READLINE  ]=====-
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
#
# -==[  TIMEOUT  ] ==-
#
# Launch executables from within a script and set a timeout so it also exits
#   timeout 10 python /opt/sickrage/SickBeard.py
#
#
#
# -==[  TOUCH  ]==-
#touch
#touch "$file" 2>/dev/null || { echo "Cannot write to $file" >&2; exit 1; }
#
#
#
#
## =======================[  STRING Parsing/Handling  ]======================= #
# -==[  GREP  ]==-
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
### =================================================================================== ###
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
# -=====[  Parse/Read a config file using whitelisting  ]=====-
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
#
#
#
#
# Create a desktop shortcut
#   Method #1: If a .desktop file already exists. Make it executable to avoid a warning popup
#     cp /usr/share/applications/geany.desktop ~/Desktop/
#     chmod +x ~/Desktop/geany.desktop
#
#   Method #2: Create one from scratch and point to a shell script and an icon
#     # Copy the PyCharm Icon over to our default applications pool
#     cp /opt/pycharm-community/bin/pycharm.png /usr/share/applications/
#
#     # Setup desktop icon if you wish
#     file="${HOME}/Desktop/pycharm.desktop"
#     if [[ ! -f "${file}" ]]; then
#       cat <<EOF > ${HOME}/Desktop/pycharm.desktop
##!/usr/bin/env xdg-open
#[Desktop Entry]
#Name=PyCharm
#Encoding=UTF-8
#Exec=/opt/pycharm-community/bin/pycharm.sh
# Point this to /usr/share/applications/ or just point to it within its product bundle path
#Icon=/opt/pycharm-community/bin/pycharm.png
#StartupNotify=false
#Terminal=false
#Type=Application
#EOF
#     fi
#     chmod +x "${file}"
#
#
#
## ==================================================================================== ##
