#!/usr/bin/env bash
## =============================================================================
# File:     setup-Ghostwriter.sh
# Author:   Cashiuus
# Created:  20-Oct-2020     Revised:
#
##-[ Info ]---------------------------------------------------------------------
# Purpose:  Get up and running with the Ghostwriter project management 
#           tool, by SpecterOps. It runs within docker-compose and is 
#           built on Python Django, website-driven.
#
#
# Notes:
#
#
##-[ Links/Credit ]-------------------------------------------------------------
# * https://posts.specterops.io/introducing-ghostwriter-part-1-61e7bd014aff
# * https://ghostwriter.wiki/
# * https://github.com/GhostManager/Ghostwriter
#
##-[ Copyright ]----------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =============================================================================
__version__="0.1"
__author__="Cashiuus"
## =======[ EDIT THESE SETTINGS ]======= ##
PREFERRED_ENV="production.yml"
PROJECT_HOME="${HOME}/git/Ghostwriter"

## ==========[  TEXT COLORS  ]============= ##
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
## =============[  CONSTANTS  ]============= ##
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
## ==========================[ END :: LOAD FILES ]========================== ##

##  Functions
## =================================== ##




##  Running Main
## =================================== ##

echo -e "${ORANGE} + -- -- -- --=[${RESET}  ${APP_NAME}  ${ORANGE}]=-- -- -- -- +${RESET}"
echo -e "${BLUE}\tAuthor:  ${RESET}${__author__}"
echo -e "${BLUE}\tVersion: ${RESET}${__version__}"
echo -e "${ORANGE} + -- --=[ https://github.com/cashiuus ${RESET}"
echo -e
echo -e

# NOTE: The instructions say to use this one-liner: git clone https://github.com/GhostManager/Ghostwriter.git && cd Ghostwriter && mkdir .envs && cp -r .envs_template/.* .envs && docker-compose -f local.yml up -d
# However, it did not work for me on Debian 10, because the recursive copy of .envs fails
# and for some weird reason is copying the entire 'Ghostwriter' directory instead of the .envs_template directory
# For this reason, I broke up the steps in order to resolve this issue and ensure files are copied.


echo -e "[*] Pulling down the Ghostwriter project repository from Github"
cd ~ && mkdir git
git clone https://github.com/GhostManager/Ghostwriter.git && cd Ghostwriter && mkdir .envs
[[ $? -ne 0 ]] && \
  echo -e "[ERROR] Unable to clone git project and create dir. Check and try again." && \
  exit 1

# Copy the .envs_template/ subdirs into .envs/
# This doesn't work on Debian 10: `cp -r ./.envs_template/.* ./.envs/`

# This way does work in bash
shopt -s dotglob
cp -r .envs_template/* .envs/



# ======[ Handle Production Preferences ]======== #
if [[ "${PREFERRED_ENV}" = "production.yml" ]]; then
  
  
  # Verify we have python and django so we can generate a secret key for prod
  [[ $(which python3) ]] || install_python_django
  MY_VIRTUALENV=$(workon | grep django-py)
  workon "${MY_VIRTUALENV}"
  
  # TODO: check that python and django are installed before we can do this:
  NEW_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
  # -------------------------------------
  # Other options for generating random keys:
  # base64 /dev/urandom | head -c50
  # tr -dc 'a-z0-9!@#$%^&*(-_=+)' < /dev/urandom | head -c50
  # python -c 'import random; print("".join([random.choice("abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)") for i in range(50)]))'
  # -------------------------------------
  
  file="${PROJECT_HOME}/.envs/.production/.django"
  #if [[ grep -q '^DJANGO_SECRET_KEY=changeme' "${file}"  ]]; then
  sed -i 's/^DJANGO_SECRET_KEY=changeme.*/DJANGO_SECRET_KEY='${NEW_KEY}'/' "${file}"
  
  echo -e "${GREEN}[+]${RESET} The production settings file will now open."
  echo -e "${GREEN}[+]${RESET} Review and update all settings. Once saved, proceed with script"
  xdg-open "${file}" || echo -e "${YELLOW}[WARN] Error opening settings file. May need to edit separately."
  pause
  # Deploy to production
  docker-compose -f "${PREFERRED_ENV}" stop
  docker-compose -f "${PREFERRED_ENV}" rm -f
  docker-compose -f "${PREFERRED_ENV}" build
fi

# Build the initial image
echo -e "[*] Building the docker image and all dependencies, this will take awhile..."
docker-compose -f "${PREFERRED_ENV}" up -d


# Load the initial fixtures
echo -e "[*] Populating the database with initial seed data, termed by Django as fixtures"
echo -e "[*] This initial data typically includes items like severity categories used as choices in drop-down menus"
docker-compose -f "${PREFERRED_ENV}" run --rm django /seed_data


#docker-compose -f ${PREFERRED_ENV} run --rm django python manage.py migrate
#docker-compose -f ${PREFERRED_ENV} run --rm django python manage.py makemigration
#docker-compose -f ${PREFERRED_ENV} run --rm django python manage.py migrate
#docker-compose -f ${PREFERRED_ENV} run --rm django python manage.py createsuperuser
#docker-compose -f ${PREFERRED_ENV} down --rmi all
#docker-compose -f ${PREFERRED_ENV} up -d


# Create Django users
echo -e "[*] You will now create a superuser/admin for logging into the web app"
echo -e "[NOTE] Django is case sensitive, so use all lowercase in your username to avoid later confusion"
docker-compose -f ${PREFERRED_ENV} run --rm django python manage.py createsuperuser




# Launch the application and start to use it
cd ~/git/Ghostwriter/
docker-compose -f local.yml up -d


firefox 'http://10.0.0.202:8000/admin' &




# Updating Your Container
# Run these four commands stop the container, delete it, build a new container with the latest code, and start the container:
docker-compose -f local.yml stop; docker-compose -f local.yml rm -f; docker-compose -f local.yml build; docker-compose -f local.yml up -d




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
