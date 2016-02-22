### For Reference:
###     .bashrc         - Executes for all non-login BASH shells 
###                         (e.g. scripts with #!/bin/bash)
###     .bash_profile   - Executes for all login BASH shells
###     .profile        - Executes for all login shells, not just BASH
### Ref: http://www.linuxfromscratch.org/blfs/view/stable/postlfs/profile.html
### 

#if [[ "${SHELL}" == "/bin/bash" ]]; then
#    [[ -s "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
#fi

### Controls write-access to terminal; 'n' disallows write access
#mesg y
