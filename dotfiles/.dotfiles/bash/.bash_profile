### For Reference:
###     .bashrc         - Executes for all non-login BASH shells
###                       (e.g. scripts with #!/bin/bash)
###     .bash_profile   - Executes for all login BASH shells
###     .profile        - Executes for all login shells, not just BASH
###
###
### Standard dotfiles file permissions are: 0644
### ------------------------------------------------------------------------ ###

### Load RVM into a shell session & make scripts available
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# RVM Loading for Kali
[[ -s "/etc/profile.d/rvm.sh" ]] && source "/etc/profile.d/rvm.sh"


### Initial Custom Prompt
export PS1="\[\033[31m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[36m\]\w\[\033[m\]\$ "


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


### Load custom dotfiles
[[ -s "$HOME/.dotfiles/bash/.bash_aliases" ]] && source "$HOME/.dotfiles/bash/.bash_aliases"
[[ -s "$HOME/.dotfiles/bash/.bash_prompt" ]] && source "$HOME/.dotfiles/bash/.bash_prompt"
[[ -s "$HOME/.dotfiles/bash/.bash_sshagent" ]] && source "$HOME/.dotfiles/bash/.bash_sshagent"
[[ -s "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"
[[ -s "$HOME/.bash_sshagent" ]] && source "$HOME/.bash_sshagent"

