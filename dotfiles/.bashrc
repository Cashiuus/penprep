### ~/.bashrc: executed by bash(1) for non-login shells.
### For Reference:
###     .bashrc         Executes for all non-login BASH shells
###                     (e.g. scripts with #!/bin/bash)
###     .bash_profile   Executes for all login BASH shells
###     .profile        Executes for all login shells, not just BASH
###
### Refs:
#       http://www.linuxfromscratch.org/blfs/view/stable/postlfs/profile.html
###
### ------------------------------------------------------------------------ ###

### If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

#### Load the shell dotfiles, and then some:
##       * ~/.path can be used to extend `$PATH`.
##       * ~/.extra can be used for other settings you don’t want to commit.
#if [[ -f "${HOME}/.dotfiles/bash/.bash_profile" ]]; then
    #source "${HOME}/.dotfiles/bash/.bash_profile"
#elif [[ -f "${HOME}/.bash_profile" ]]; then
    #source "${HOME}/.bash_profile"
#fi

### Enable the ssh-agent handler that helps with ssh keys
if [[ -s "${HOME}/.dotfiles/bash/.bash_sshagent" ]]; then
    source "${HOME}/.dotfiles/bash/.bash_sshagent"
elif [[ -s "${HOME}/.bash_sshagent" ]]; then
    source "${HOME}/.bash_sshagent"
fi

### ----------[ MISC CONFIGS ]---------- ###
### Don't try to complete if it's empty, helpful with performance
shopt -s no_empty_cmd_completion
### check the window size after each command and, if necessary,
### update the values of LINES and COLUMNS.
shopt -sq checkwinsize
### If set, the pattern "**" used in a pathname expansion context will
### match all files and zero or more directories and subdirectories.
shopt -s globstar

### ----------[ HISTORY CONFIGS ]---------- ###
### Store command history as one line, regardless if input as multi-line
shopt -s cmdhist
### Append history so that multiple terminals will not overwrite each other
shopt -s histappend
### Don't overwrite GNU Midnight Commander's setting of `ignorespace'.
#export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
### Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
### For setting history length see HISTSIZE and HISTFILESIZE
# HISTSIZE (Default: 1000) For memory scrollback
HISTSIZE=90000
# HISTFILESIZE (Default: 2000) For history file (e.g. bash_history)
HISTFILESIZE=9000
# Include timestamps in history log
export HISTTIMEFORMAT="%F %T "


### set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

### make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

### ----------[ COLORS & PROMPTS ]---------- ###
### set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

### Enable a colored prompt
force_color_prompt=yes
# Enable gcc colours, available since gcc 4.9.0
export GCC_COLORS=1

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1="${debian_chroot:+($debian_chroot)}\[\033[31m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[36m\]\w\[\033[m\]\$ "
else
    PS1="${debian_chroot:+($debian_chroot)}\u@\h:\w\$ "
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac
export PS1

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

### Set a default editor
export EDITOR=nano

### Loading .bash_prompt customization here based on advice online
[[ -s "$HOME/.bash_prompt" ]] && source "$HOME/.bash_prompt"

### Load RVM to PATH for scripting
#TODO: Not sure which of these lines is correct
#[[ -d "${HOME}/.rvm" ]] && export PATH="${HOME}/.rvm/bin:$PATH"
# This line loads rvm and ensures that scripts can call 'rvm' in them
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# RVM Loading for Kali and will override the previous line
[[ -s "/etc/profile.d/rvm.sh" ]] && source "/etc/profile.d/rvm.sh"

### Load Python Virtualenvwrapper Script helper
[[ -s "/usr/local/bin/virtualenvwrapper.sh" ]] && source "/usr/local/bin/virtualenvwrapper.sh"
[[ -d "${HOME}/.virtualenvs" ]] && export WORKON_HOME="${HOME}/.virtualenvs"

# NVM preloading & bash completions
[[ -d "${HOME}/.nvm" ]] && export NVM_DIR="${HOME}/.nvm"
[[ -s "${NVM_DIR}/nvm.sh" ]] && . "${NVM_DIR}/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"

# Go Lang PATH support
# NOTE: in kali, GOROOT is /usr/lib/go, while on everywhere else it's /usr/local/go
[[ -d "${HOME}/go" ]] && export GOPATH="${HOME}/go" && export GOBIN="${HOME}/go/bin"
export GOROOT=/usr/lib/go
#export GOROOT=/usr/local/go

# Go support
PATH=$GOPATH/bin:$GOROOT/bin:$PATH
# set PATH so it includes user's local bin, python now uses by default
PATH=$HOME/.local/bin:/snap/bin:$PATH
