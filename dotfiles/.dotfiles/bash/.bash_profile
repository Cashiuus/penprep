### For Reference:
###     .bashrc         - Executes for all non-login BASH shells
###                       (e.g. scripts with #!/bin/bash)
###     .bash_profile   - Executes for all login BASH shells
###     .profile        - Executes for all login shells, not just BASH
###
### Ref: http://www.linuxfromscratch.org/blfs/view/stable/postlfs/profile.html
### NOTE: Default dotfiles file permissions are: 0644
### ------------------------------------------------------------------------ ###

if [[ -f "$HOME/.dotfiles/bash/.bash_aliases" ]]; then
    [[ -s "$HOME/.dotfiles/bash/.bash_aliases" ]] && source "$HOME/.dotfiles/bash/.bash_aliases"
    [[ -s "$HOME/.dotfiles/bash/.bash_prompt" ]] && source "$HOME/.dotfiles/bash/.bash_prompt"
    [[ -s "$HOME/.dotfiles/bash/.bash_sshagent" ]] && source "$HOME/.dotfiles/bash/.bash_sshagent"
else
    [[ -s "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"
    [[ -s "$HOME/.bash_prompt" ]] && source "$HOME/.bash_prompt"
    [[ -s "$HOME/.bash_sshagent" ]] && source "$HOME/.bash_sshagent"
fi

### Load RVM into a shell session & make scripts available
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# RVM Loading for Kali
[[ -s "/etc/profile.d/rvm.sh" ]] && source "/etc/profile.d/rvm.sh"

### Initial Custom Prompt
export PS1="\[\033[31m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[36m\]\w\[\033[m\]\$ "

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

[[ -s "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
