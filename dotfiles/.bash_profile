### For Reference:
###     .bashrc         - Executes for all non-login BASH shells
###                         (e.g. scripts with #!/bin/bash)
###     .bash_profile   - Executes for all login BASH shells
###     .profile        - Executes for all login shells, not just BASH
### Ref: http://www.linuxfromscratch.org/blfs/view/stable/postlfs/profile.html
###

### Load the configs that affect login shells
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile"

if [[ -f "$HOME/.dotfiles/bash/.bash_aliases" ]]; then
    [[ -s "$HOME/.dotfiles/bash/.bash_aliases" ]] && source "$HOME/.dotfiles/bash/.bash_aliases"
    [[ -s "$HOME/.dotfiles/bash/.bash_prompt" ]] && source "$HOME/.dotfiles/bash/.bash_prompt"
else
    [[ -s "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"
    [[ -s "$HOME/.bash_prompt" ]] && source "$HOME/.bash_prompt"
fi

### Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

### Initial Custom Prompt
export PS1="\[\033[31m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[36m\]\w\[\033[m\]\$ "
