### For Reference:
###     .bashrc         - Executes for all non-login BASH shells
###                       (e.g. scripts with #!/bin/bash)
###     .bash_profile   - Executes for all login BASH shells
###     .profile        - Executes for all login shells, not just BASH
###                        - File not read by BASH if .bash_profile or .bash_login exist
###                        - See Examples: /usr/share/doc/bash/examples/startup-files
###
### Ref: http://www.linuxfromscratch.org/blfs/view/stable/postlfs/profile.html
###
### ------------------------------------------------------------------------ ###

# if running bash
if [[ -n "$BASH_VERSION" ]]; then
    # include .bashrc if it exists
    if [[ -f "$HOME/.bashrc" ]]; then
        . "$HOME/.bashrc"
    fi
elif [[ "$SHELL" = "/usr/bin/zsh" ]]; then
    if [[ -f "$HOME/.zshrc" ]]; then
        . "$HOME/.zshrc"
    fi
fi
