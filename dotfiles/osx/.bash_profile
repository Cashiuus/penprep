#
# Cashiuus - 09-JUN-2016
# Reference: https://github.com/mathiasbynens/dotfiles/blob/master/.bash_profile
#

# Add Homebrew `/usr/local/bin` to the $PATH
PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
#for file in ~/.{path,bash_prompt,exports,bash_aliases,functions}; do
for file in ~/.{bash_prompt,bash_aliases}; do
	[ -r "$file" ] && source "$file"
done;
unset file;

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;
# Append to the Bash history file, rather than overwriting it
shopt -s histappend;
# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
	source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null && [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
	complete -o default -o nospace -F _git g;
fi;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;


# Enable text colors on mac os
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Locate virtualenvwrapper binary
if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    export VENVWRAP=/usr/local/bin/virtualenvwrapper.sh
fi

if [ ! -z $VENVWRAP ]; then
    # virtualenvwrapper -------------------------------------------
    # make sure 'envs' directory exists; else create it
    [ -d $HOME/envs ] || mkdir -p $HOME/envs
    export WORKON_HOME=$HOME/envs
    source $VENVWRAP

    # virtualenv --------------------------------------------------
    export VIRTUALENV_USE_DISTRIBUTE=true

    # pip ---------------------------------------------------------
    export PIP_VIRTUALENV_BASE=$WORKON_HOME
    export PIP_REQUIRE_VIRTUALENV=false
    export PIP_RESPECT_VIRTUALENV=true
fi

. /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-completion.bash
. /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-prompt.sh

PATH=$PATH:/opt/metasploit-framework/bin
export PATH=$PATH:/opt/metasploit-framework/bin

################################################################################
#   BASH PROMPT                                                                #
################################################################################
# Set custom PS1 prompt (user@host:cwd $)
BLUE="\e[1;36m"
GREEN="\e[1;32m"
GRAY="\e[1;37m"
RESET="\e[0m"
#export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\] \$ "
#export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\e[0;37m\]\w\[\033[m\] \$ "
export PS1="\[${BLUE}\]\u\[${RESET}\]@\[${GREEN}\]\h:\[${GRAY}\]\w\[${RESET}\]\$ "

# Show git branch in PS1 when working in a git repository directory
function git-current-branch {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'
}
export PS1="\$(git-current-branch)$PS1"

# Establish virtualenv loading via venv files within project directories
check_virtualenv() {
    if [[ -e .venv ]]; then
        env=`cat .venv`
        if [[ "$env" != "${VIRTUAL_ENV##*/}" ]]; then
            echo "Found .venv in directory. Calling: workon ${env}"
            workon "$env"
        fi
    fi
}
# Call function directly in case opening directly into a directory
# (e.g. opening a new tab in Terminal)
check_virtualenv