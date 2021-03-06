#!/usr/bin/env bash
## =======================================================================================
# File:     setup-zsh-tmux.sh
#
# Author:   Cashiuus
# Created:  10-DEC-2016 - - - - - - (Revised: )
#
#-[ Notes ]---------------------------------------------------------------------
# Purpose:
#
#
#-[ References ]--------------------------------------------------------------------------
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
PURPLE="\033[01;35m"   # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_ARGS=$@
DEBUG=true
LOG_FILE="${APP_BASE}/debug.log"
# These can be used to know height (LINES) and width (COLS) of current terminal in script
LINES=$(tput lines)
COLS=$(tput cols)

#======[ ROOT PRE-CHECK ]=======#
function check_root() {
    if [[ $EUID -ne 0 ]];then
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            # $SUDO - run commands with this prefix now to account for either scenario.
        else
            echo "Please install sudo or run this as root."
            exit 1
        fi
    fi
}
is_root
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #


function install_zsh() {

    ##### Install ZSH & Oh-My-ZSH - root user.
    # Note:  'Open terminal here', will not work with ZSH. Make sure to have tmux already installed
    echo -e "\n${GREEN}[*]${RESET} Installing ${GREEN}ZSH${RESET} & ${GREEN}Oh-My-ZSH${RESET}"
    apt -y -qq install zsh git curl \
      || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
    # Setup oh-my-zsh
    timeout 300 curl --progress -k -L -f "https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh" | zsh

    # Configure zsh
    file=~/.zshrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/zsh/zshrc
    ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
    grep -q 'interactivecomments' "${file}" 2>/dev/null \
      || echo 'setopt interactivecomments' >> "${file}"
    grep -q 'ignoreeof' "${file}" 2>/dev/null \
      || echo 'setopt ignoreeof' >> "${file}"
    grep -q 'correctall' "${file}" 2>/dev/null \
      || echo 'setopt correctall' >> "${file}"
    grep -q 'globdots' "${file}" 2>/dev/null \
      || echo 'setopt globdots' >> "${file}"
    grep -q '.bash_aliases' "${file}" 2>/dev/null \
      || echo 'source $HOME/.bash_aliases' >> "${file}"
    grep -q '/usr/bin/tmux' "${file}" 2>/dev/null \
      || echo '#if ([[ -z "$TMUX" && -n "$SSH_CONNECTION" ]]); then /usr/bin/tmux attach || /usr/bin/tmux new; fi' >> "${file}"   # If not already in tmux and via SSH
    #--- Configure zsh (themes) ~ https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
    sed -i 's/ZSH_THEME=.*/ZSH_THEME="mh"/' "${file}"   # Other themes: mh, jreese,   alanpeabody,   candy,   terminalparty, kardan,   nicoulaj, sunaku
    #--- Configure oh-my-zsh
    sed -i 's/plugins=(.*)/plugins=(git git-extras tmux dirhistory python pip)/' "${file}"
    #--- Set zsh as default shell (current user)
    chsh -s "$(which zsh)"
}

function install_tmux() {
    ##### Install tmux - all users
    (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}tmux${RESET} ~ multiplex virtual consoles"
    apt -y -qq install tmux \
      || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
    file=~/.tmux.conf; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/tmux.conf
    #--- Configure tmux
    cat <<EOF > "${file}" \
        || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#-Settings---------------------------------------------------------------------
## Make it like screen (use CTRL+a)
unbind C-b
set -g prefix C-a

## Pane switching (SHIFT+ARROWS)
bind-key -n S-Left select-pane -L
bind-key -n S-Right select-pane -R
bind-key -n S-Up select-pane -U
bind-key -n S-Down select-pane -D

## Windows switching (ALT+ARROWS)
bind-key -n M-Left  previous-window
bind-key -n M-Right next-window

## Windows re-ording (SHIFT+ALT+ARROWS)
bind-key -n M-S-Left swap-window -t -1
bind-key -n M-S-Right swap-window -t +1

## Activity Monitoring
setw -g monitor-activity on
set -g visual-activity on

## Set defaults
set -g default-terminal screen-256color
set -g history-limit 5000

## Default windows titles
set -g set-titles on
set -g set-titles-string '#(whoami)@#H - #I:#W'

## Last window switch
bind-key C-a last-window

## Reload settings (CTRL+a -> r)
unbind r
bind r source-file /etc/tmux.conf

## Load custom sources
#source ~/.bashrc   #(issues if you use /bin/bash & Debian)

EOF
    [ -e /bin/zsh ] \
        && echo -e '## Use ZSH as default shell\nset-option -g default-shell /bin/zsh\n' >> "${file}"
    cat <<EOF >> "${file}"
## Show tmux messages for longer
set -g display-time 3000

## Status bar is redrawn every minute
set -g status-interval 60


#-Theme------------------------------------------------------------------------
## Default colours
set -g status-bg black
set -g status-fg white

## Left hand side
set -g status-left-length '34'
set -g status-left '#[fg=green,bold]#(whoami)#[default]@#[fg=yellow,dim]#H #[fg=green,dim][#[fg=yellow]#(cut -d " " -f 1-3 /proc/loadavg)#[fg=green,dim]]'

## Inactive windows in status bar
set-window-option -g window-status-format '#[fg=red,dim]#I#[fg=grey,dim]:#[default,dim]#W#[fg=grey,dim]'

## Current or active window in status bar
#set-window-option -g window-status-current-format '#[bg=white,fg=red]#I#[bg=white,fg=grey]:#[bg=white,fg=black]#W#[fg=dim]#F'
set-window-option -g window-status-current-format '#[fg=red,bold](#[fg=white,bold]#I#[fg=red,dim]:#[fg=white,bold]#W#[fg=red,bold])'

## Right hand side
set -g status-right '#[fg=green][#[fg=yellow]%Y-%m-%d #[fg=white]%H:%M#[fg=green]]'
EOF
    #--- Setup alias
    file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
    ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
    grep -q '^alias tmux' "${file}" 2>/dev/null \
      || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n' >> "${file}"    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
    #--- Apply new alias
    source "${file}" || source ~/.zshrc

}




# =========================[ MAIN PROGRAM ROUTINE ]===================================#
install_zsh
install_tmux


# ====================================================================================#







pause() {
  local dummy
  read -s -r -p "Press any key to continue..." -n 1 dummy
}

asksure() {
    ### using it
    #if asksure; then
        #echo "Okay, performing rm -rf / then, master...."
    #else
        #echo "Pfff..."
    #fi
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


make_tmp_dir() {
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

is_process_alive() {
  # Checks if the given pid represents a live process.
  # Returns 0 if the pid is a live process, 1 otherwise
  #
  # Usage: is_process_alive 29833
  #   [[ $? -eq 0 ]] && echo -e "Process is alive"

  local pid="$1" # IN
  ps -p $pid | grep $pid > /dev/null 2>&1
}



function finish {
    # Any script-termination routines go here, but function cannot be empty
    clear
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"
    # Redirect app output to log, sending both stdout and stderr (*NOTE: this will not parse color codes)
    # cmd_here 2>&1 | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT
## ========================================================================== ##
## ======================[ Template File Code Help ]========================= ##
#
## ============[ BASH GUIDES ]============= #
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
# =============[ Styleguide Recommendations ]============ #
#   line length =   80
#   functions   =   lower-case with underscores, must use () after func, "function" optional, be consistent
#                   Place all functions at top below constants, don't hide exec code between functions
#                   A function called 'main' is required for scripts long enough to contain other functions
#   constants   =   UPPERCASE with underscores
#   read-only   =   Vars that are readonly - use 'readonly var' or 'declare -r var' to ensure
#   local vars  =   delcare and assign on separate lines
#
#   return vals =   Always check return values and give informative return values
#
# =============[ ECHO/PRINTF Commands ]============ #
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
# -==[ Output Suppression/Redirection ]==-
#   >/dev/null 1>&2         Supress all output (1), including errors (2)
#
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
#read -r -e -p "Enter the path to the file: " -i "/usr/local/etc/" FILEPATH
#
# Ask for a path with a default value and 5-second timeout - TODO: this work?
#   read -e -r -n 5 -p "Enter the path to the file: " -i "/usr/local/etc/" FILEPATH
#
# A "press any key to continue..." solution like pause in MSDOS
#pause() {
#  local dummy
#  read -s -r -p "Press any key to continue..." -n 1 dummy
#}
#
# Parsing a simple date/time string
#datetime="2008:07:04 00:34:45"
#IFS=": " read -r year month day hour minute second <<< "$datetime"
#
#
#
# -==[ TOUCH ]==-
#touch
#touch "$file" 2>/dev/null || { echo "Cannot write to $file" >&2; exit 1; }

# -==[ SED ]==-
# NOTE: When using '/' for paths in sed, use a different delimiter, such as # or |
#
#sed -i 's/^.*editor_font=.*/editor_font=Monospace\ 10/' "${file}"
#sed -i 's|^.*editor_font=.*|editor_font=Monospace\ 10|' "${file}"
#
#
#
# -==[ Parse/Read a config file using whitelisting ]==-
#
#CONFIG_FILE="/path/here"
# Declare a whitelist
#CONFIG_SYNTAX="^\s*#|^\s*$|^[a-zA-Z_]+='[^']*'$"
# Check if file contains something we don't want
#if egrep -q -v "${CONFIG_SYNTAX}" "$CONFIG_PATH"; then
#  echo "Error parsing config file ${CONFIG_PATH}." >&2
#  echo "The following lines in the configfile do not fit the syntax:" >&2
#  egrep -vn "${CONFIG_SYNTAX}" "$CONFIG_PATH"
#  exit 5
#fi
# otherwise go on and source it:
#source "${CONFIG_FILE}"
#
#
#
#
## ======================[ Template File Code Help ]========================= ##
#
# ============[ Variables ]===============
#
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
# ==============[ Booleans ]==================
# The below examples are all ways you can check booleans
#bool=true
#if [ "$bool" = true ]; then
#if [ "$bool" = "true" ]; then
#
#if [[ "$bool" = true ]]; then
#if [[ "$bool" = "true" ]]; then
#if [[ "$bool" == true ]]; then
#if [[ "$bool" == "true" ]]; then
#
#if test "$bool" = true; then
#if test "$bool" = "true"; then

