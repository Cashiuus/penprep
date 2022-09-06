#!/usr/bin/env bash
## =======================================================================================
# File:     setup-ssh-server.sh
# Author:   Cashiuus
# Created:  01-Dec-2015 - (Revised: 27-Dec-2020)
## =======================================================================================

## ==========[  TEXT COLORS  ]============= ##
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
ORANGE="\033[38;5;208m" # Debugging
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal




echo -e -n "${GREEN}[+] ${RESET}"
read -r -e -p "Enter filename for your SSH key (For default of id_rsa, just press ENTER): " -i "id_rsa" SSH_KEY_FILENAME

  
echo -e "${GREEN}[*]${RESET} Generating SSH key, saving it to: ${HOME}/.ssh/"
ssh-keygen -b 4096 -t rsa -f "${HOME}/.ssh/${SSH_KEY_FILENAME}" -P "" >/dev/null

#chmod 0700 "${HOME}/.ssh"
chmod 0644 "${HOME}/.ssh/${SSH_KEY_FILENAME}.pub"
chmod 0400 "${HOME}/.ssh/${SSH_KEY_FILENAME}"


# Take this, put your public key into the remote server's authorized_keys file, and you can SSH in.
if [[ $(which thunar) ]]; then
	thunar ~/.ssh &
fi

exit 0
