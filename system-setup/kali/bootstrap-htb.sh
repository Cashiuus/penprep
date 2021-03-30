#!/usr/bin/env bash
## =======================================================================================
# File:     htb-bootstrap.sh
# Author:   Cashiuus
# Created:  08-Apr-2020     Revised: 29-Mar-2021
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Run this script on new Kali images to automatically configure and
#           install packages needed for HackTheBox challenges. Spend your time
#           hacking and learning, not troubleshooting!
#
#
# Oneliner: wget -qO bootstrap-htb.sh https://raw.githubusercontent.com/Cashiuus/penprep/master/system-setup/kali/bootstrap-htb.sh && bash bootstrap-htb.sh
#
# Shorter: curl -sSL https://raw.githubusercontent.com/Cashiuus/penprep/master/system-setup/kali/bootstrap-htb.sh | bash
#
#
##-[ Changelog ]-----------------------------------------------------------------------
#   2020-12-27: Removed python 2 from setup completely, as python 3 is the default now
#
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="2.0.0"
__author__="Cashiuus"
## ==========[ TEXT COLORS ]============= ##
# [http://misc.flogisoft.com/bash/tip_colors_and_formatting]
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
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
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LINES=$(tput lines)
COLS=$(tput cols)
HOST_ARCH=$(dpkg --print-architecture)      # (e.g. output: "amd64")

## =======[ EDIT THESE SETTINGS ]======= ##
VPN_BASE_DIR="${HOME}/vpn"
HTB_BASE_DIR="${HOME}/htb"
CREATE_USER_DIRECTORIES=(burpsuite git go msf-scripts tools vpn)  # Subdirectories of $HOME/
CREATE_OPT_DIRECTORIES=()                                         # Subdirectories of /opt/
# HTB folder package -- don't delete existing, but you can add more dirs to these
# Some script routines rely on placing certain git repo's into these subdirs
CREATE_HTB_DIRS=(boxes credentials notebooks privesc pivoting shells transfers wordlists)
CREATE_HTB_BOX_SUBDIRS=(scans loot)                               # Future use
HTB_BOXES="${HTB_BASE_DIR}/boxes"             # Our challenge boxes artifacts as we go
HTB_NOTES="${HTB_BASE_DIR}/notebooks"         # Our challenge boxes artifacts as we go
HTB_PIVOTING="${HTB_BASE_DIR}/pivoting"       # Resources for pivoting/c2
HTB_PRIVESC="${HTB_BASE_DIR}/privesc"         # Privesc tools for both Linux and Windows
HTB_SHELLS="${HTB_BASE_DIR}/shells"           # Various shells we can use (or created along the way)
HTB_TRANSFERS="${HTB_BASE_DIR}/transfers"     # Everything in one place for file transfers
BURPSUITE_CONFIG_DIR="${HOME}/burpsuite"      # Burpsuite configs, libs, extensions, etc in one place


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
  echo -e "${BLUE}---------------------------------------------------${RESET}"
}
print_banner
echo -e "\n${BLUE}[$(date +"%F %T")] ${RESET}Giving Kali a tune-up, please wait..."

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
# =============================[ Setup VM Tools ]================================ #
# https://github.com/vmware/open-vm-tools
if [[ ! $(which vmware-toolbox-cmd) ]]; then
  echo -e "\n${YELLOW}[WARN] Now installing vm-tools. This will require a reboot. Re-run script after reboot...${RESET}"
  sleep 2
  $SUDO apt-get -y -qq install open-vm-tools-desktop fuse
  echo -e "${YELLOW}[WARN] Rebooting in 5 seconds, type CTRL+C to cancel..."
  sleep 5
  $SUDO reboot
fi

# ===========================[ Bash History Sizes ]============================== #
file="${HOME}/.bashrc"
sed -i 's/^HISTSIZE=.*/HISTSIZE=90000/' "${file}"
sed -i 's/^HISTFILESIZE=.*/HISTFILESIZE=9999/' "${file}"

if [[ ${GDMSESSION} == 'lightdm-xsession' ]]; then
  # Increasing terminal history scrolling limit
  file="${HOME}/.config/qterminal.org/qterminal.ini"
  [[ -s "${file}" ]] && sed -i 's/^HistoryLimitedTo=.*/HistoryLimitedTo=30000/' "${file}"
fi

# =============================[ APT Packages ]================================ #
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

echo -e "\n${GREEN}[*] ${RESET}Issuing apt-get update and dist-upgrade, please wait..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get -qq update
$SUDO apt-get -y -q -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" dist-upgrade

echo -e "\n${GREEN}[*] ${RESET}apt-get :: Installing core utilities"
$SUDO apt-get -y -qq install bash-completion build-essential curl dos2unix locate \
  gcc geany git golang gzip jq libssl-dev make net-tools openssl openvpn \
  powershell tmux wget unzip xclip

$SUDO apt-get -y -qq install geany htop sysv-rc-conf tree

echo -e "\n${GREEN}[*] ${RESET}apt-get :: Installing commonly used HTB tools"
$SUDO apt-get -y -qq install dirb dirbuster exploitdb flameshot \
  libimage-exiftool-perl neo4j nikto rdesktop responder seclists \
  shellter sqlmap windows-binaries

# Python 3
$SUDO apt-get -y -qq install python3 python3-dev python3-pip python3-setuptools || \
  echo -e "${YELLOW}[ERROR] Errors occurred installing Python 3.x, you may have issues${RESET}" \
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
file="/tmp/requirements.txt"
cat <<EOF > "${file}"
argparse
beautifulsoup4
colorama
dnspython
future
htbclient
lxml
mechanize
netaddr
pefile
pep8
Pillow
psycopg2
pygeoip
python-Levenshtein
python-libnmap
requests
six
wheel
EOF

$SUDO python3 -m pip install -q -r /tmp/requirements.txt

# -- Create Directory Structure -------------------------------------------------
function asksure() {
  ###
  # Usage:
  #   if asksure; then
  #        echo "Okay, performing rm -rf / then, master...."
  #   else
  #        echo "Awww, why not :("
  #   fi
  ###
  echo -n "$1 (Y/N): "
  while read -r -n 1 -s answer; do
    if [[ $answer = [YyNn] ]]; then
      [[ $answer = [Yy] ]] && retval=0
      [[ $answer = [Nn] ]] && retval=1
      break
    fi
  done
  echo
  return $retval
}

if asksure "Is this install for a pro/specific named lab?"; then
  read -r -e -p "Enter simple one-word name for the lab: " HTB_LAB_NAME
fi
if [[ $HTB_LAB_NAME != "" ]]; then
  echo -e "${GREEN}[*] ${RESET} Okay, your parent HackTheBox directory will be: ${ORANGE}htb-${HTB_LAB_NAME}${RESET}"
  HTB_DIRNAME_FORMATTED="${HTB_BASE_DIR}-${HTB_LAB_NAME}"
  sleep 1s
else
  HTB_DIRNAME_FORMATTED="${HTB_BASE_DIR}"
fi

count=0
while [ "x${CREATE_USER_DIRECTORIES[count]}" != "x" ]; do
    count=$(( $count + 1 ))
done

# Create folders in ~
echo -e "${GREEN}[*]${RESET} Creating ${count} directories in current user's ${GREEN}HOME${RESET} directory path"
for dir in ${CREATE_USER_DIRECTORIES[@]}; do
    mkdir -p "${HOME}/${dir}"
done

count=0
while [ "x${CREATE_OPT_DIRECTORIES[count]}" != "x" ]; do
    count=$(( $count + 1 ))
done

# Create folders in /opt
if [ $count -ge 1 ]; then
  echo -e "${GREEN}[*]${RESET} Creating ${count} directories in /opt/ path"
  for dir in ${CREATE_OPT_DIRECTORIES[@]}; do
      mkdir -p "/opt/${dir}"
  done
fi

#mkdir -p ~/htb/{boxes,credentials,shells,privesc,wordlists}
# Create core subdirs in our HTB BASE DIR
echo -e "${GREEN}[*]${RESET} Creating ${GREEN}HTB${RESET} core subdirectories"
for dir in ${CREATE_HTB_DIRS[@]}; do
    mkdir -p "${HTB_BASE_DIR}/${dir}"
done


# -- Various Extra Tools -------------------------------------------------------
if [[ ! -d "${HOME}/git/penprep" ]]; then
  cd "${HOME}/git" && git clone https://github.com/cashiuus/penprep
fi

### Evil-WinRM install
echo -e "\n${GREEN}[*] ${RESET}Installing Evil-WinRM"
$SUDO apt-get -y -qq install rubygems
$SUDO gem install evil-winrm

# Get common shells to use
echo -e "\n${GREEN}[*] ${RESET}Grabbing useful shells/backdoors"
cd "${HTB_SHELLS}"
git clone https://github.com/infodox/python-pty-shells
git clone https://github.com/epinna/weevely3
git clone https://github.com/eb3095/php-shell

echo -e "\n${GREEN}[*] ${RESET}Grabbing useful privilege escalation scanners"
cd "${HTB_PRIVESC}"
git clone https://github.com/pentestmonkey/windows-privesc-check
git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite peass
git clone https://github.com/etc5had0w/suider
git clone https://github.com/rasta-mouse/Sherlock
git clone https://github.com/rasta-mouse/Watson
git clone https://github.com/AonCyberLabs/Windows-Exploit-Suggester
git clone https://github.com/gentilkiwi/mimikatz
git clone https://github.com/skelsec/pypykatz
git clone https://github.com/AlessandroZ/BeRoot
git clone https://github.com/enjoiz/Privesc Privesc-PS


echo -e "\n${GREEN}[*] ${RESET}Loading a bunch of additional tools into /opt/..."
cd /opt
$SUDO git clone https://github.com/BloodHoundAD/BloodHound
$SUDO git clone https://github.com/cobbr/Covenant
$SUDO git clone https://github.com/leebaird/discover
$SUDO git clone https://github.com/elceef/dnstwist
$SUDO git clone https://github.com/TheWover/donut
$SUDO git clone https://github.com/GhostPack/Seatbelt
$SUDO git clone https://github.com/byt3bl33d3r/SprayingToolkit
$SUDO git clone https://github.com/samratashok/ADModule
$SUDO git clone https://github.com/samratashok/nishang
$SUDO git clone https://github.com/DominicBreuker/pspy
$SUDO git clone https://github.com/PowerShellMafia/PowerSploit
$SUDO git clone https://github.com/NetSPI/PowerUpSQL
$SUDO git clone https://github.com/abatchy17/WindowsExploits
$SUDO git clone https://github.com/21y4d/nmapAutomator

$SUDO python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git
if [[ ! $(which autorecon) ]]; then
  cd /opt/
  $SUDO git clone https://github.com/Tib3rius/AutoRecon
  cd AutoRecon
  # TODO: Better to use a virtualenv, but only if it's easy for
  # users to auto-activate it anytime they want to use AutoRecon
  $SUDO python3 -m pip install -r requirements.txt
  $SUDO ln -s /opt/AutoRecon/src/autorecon/autorecon.py local/bin/autorecon
  # TODO: which symlink option is better? If i put it local, do i still need sudo?
  #ln -s /opt/AutoRecon/src/autorecon/autorecon.py "${HOME}/.local/bin/autorecon"
fi


# Custom nmap nse script to run CVE checks
cd /tmp/
# NOTE: This repo has another "http-vulners-regex.nse" you can read up on
$SUDO git clone https://github.com/vulnersCom/nmap-vulners
$SUDO cp /tmp/nmap-vulners/vulners.nse /usr/share/nmap/scripts/
# Usage: nmap -sV --script vulners --script-args mincvss=7

# Run this after we've imported all new nse scripts to load them
$SUDO nmap --script-updatedb


### Python Impacket install
echo -e "\n${GREEN}[*] ${RESET}Installing Python Impacket collection"
cd /opt/
$SUDO git clone https://github.com/SecureAuthCorp/impacket
cd impacket
$SUDO python3 setup.py install


# -- Singular web director for file transfers ----------------------------------

echo -e "${GREEN}[*] ${RESET} Consolidating all our goodies in one place for file transfers (nc, mimi, privesc, etc)"
cd "${HTB_TRANSFERS}"
cp "/usr/share/windows-binaries/nc.exe" ./
cp "/usr/share/windows-binaries/wget.exe" ./
cp "/usr/share/windows-resources/mimikatz/x64/mimikatz.exe" ./
cp "${HTB_PRIVESC}/peass/linPEAS/linpeas.sh" ./
cp "${HTB_PRIVESC}/peass/winPEAS/winPEASexe/binaries/x86/Release/winPEASx86.exe" ./
cp "${HTB_PRIVESC}/peass/winPEAS/winPEASexe/binaries/x64/Release/winPEASx64.exe" ./
cp "${HTB_PRIVESC}/Windows-Exploit-Suggester/windows-exploit-suggester.py" ./
cp "${HTB_PRIVESC}/Sherlock/Sherlock.ps1" ./
cp "/opt/PowerSploit/Privesc/PowerUp.ps1" ./
cp "/opt/PowerSploit/Privesc/Privesc.psd1" ./
cp "/opt/PowerSploit/Privesc/Privesc.psm1" ./
cp "/opt/PowerSploit/Recon/PowerView.ps1" ./
cp "/opt/PowerSploit/AntivirusBypass/Find-AVSignature.ps1" ./
cp "/opt/ADModule/Import-ActiveDirectory.ps1" ./
cp "/opt/ADModule/Microsoft.ActiveDirectory.Management.dll" ./



# -- Burpsuite -----------------------------------------------------------------
mkdir -p "${BURPSUITE_CONFIG_DIR}"/{configs,libs,extensions,projects}
cd "${BURPSUITE_CONFIG_DIR}/libs"
echo -e "${GREEN}[*] ${RESET}Centralizing burpsuite configs, extensions, libs, etc. into ${BURPSUITE_CONFIG_DIR}"
jython_url='https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.2/jython-standalone-2.7.2.jar'
curl -SL "${jython_url}" -o jython-2.7.2.jar

cd "${BURPSUITE_CONFIG_DIR}/extensions"
git clone https://github.com/bit4woo/domain_hunter


# -- Golang & Tools ------------------------------------------------------------
### Go packages
if [[ $(which go) ]]; then
  GO_VERSION=$(go version | awk '{print $3}' | cut -d 'o' -f2)
  export PATH=$PATH:$HOME/go/bin
  go get github.com/ropnop/kerbrute

fi


# -- Wordlists -----------------------------------------------------------------
# Unzip the infamous rockyou wordlist
echo -e "\n${GREEN}[*] ${RESET}Decompressing the 'RockYou' wordlist"
cd /usr/share/wordlists/
$SUDO gunzip -d /usr/share/wordlists/rockyou.txt.gz 2>/dev/null
$SUDO ln -s /usr/share/seclists seclists 2>/dev/null



# -- Install Obsidian for Notetaking -------------------------------------------
function install_obsidian_appimage() {
  if [[ ! $(which obsidian) ]]; then
    cd /tmp/
    url='https://github.com/obsidianmd/obsidian-releases/releases/download/v0.11.9/Obsidian-0.11.9.AppImage'
    curl -SL "${url}" -o obsidian
    $SUDO mv /tmp/obsidian /usr/local/sbin/obsidian
    $SUDO chmod +x /usr/local/sbin/obsidian
    # First-run but don't create/open a vault yet
    $SUDO timeout 5 "/usr/local/sbin/obsidian --no-sandbox" >/dev/null 2>&1
  fi
  # Download and install templates we'll use with note and report writing
  if [[ ! -e /usr/share/pandoc/data/templates/eisvogel.latex ]]; then
    curl -SL 'https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/v2.0.0/Eisvogel-2.0.0.tar.gz' -o eisvogel.tar.gz
    tar -xvf eisvogel.tar.gz
    cp /tmp/eisvogel.latex "${HTB_NOTES}/"
    $SUDO cp /tmp/eisvogel.latex /usr/share/eisvogel.latex /usr/share/pandoc/data/templates/eisvogel.latex
  fi
  cd "${HOME}/git"
  git clone https://github.com/noraj/OSCP-Exam-Report-Template-Markdown
  cp "${HOME}/git/OSCP-Exam-Report-Template-Markdown/src/OSEP-exam-report-template_OS_v1.md" "${HTB_NOTES}/"

  # Install extras for this workflow
  $SUDO apt-get -y install evince pandoc p7zip-full texlive-full

  file="${HTB_NOTES}/generate-report.sh"
  if [[ ! -e "${file}" ]]; then
    cat <<EOF > "${file}"
#!/bin/bash

if [[ \$# -ne 2 ]]; then
  echo -e " Usage: \$0 <input.md> <output.pdf>"
  exit
fi

if [[ ! -e /usr/share/pandoc/data/templates/eisvogel.latex ]]; then
  echo -e "[ERROR] eisvogel.latex file missing, check and try again!"
  exit
fi

pandoc \$1 -o \$2 \
  --from markdown+yaml_metadata_block+raw_html \
  --template eisvogel \
  --table-of-contents \
  --toc-depth 6 \
  --number-sections \
  --top-level-division=chapter \
  --highlight-style tango


if [[ \$? -eq 0 ]]; then
  evince \$2
fi
EOF
    chmod u+x "${file}"
  fi
}
install_obsidian_appimage




# -- Desktop Display Tweaks ----------------------------------------------------
function desktop_tweaks() {
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

    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-12 -t string -s separator

  fi
}
desktop_tweaks




function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  echo -e "${GREEN}[*] ${RESET}Cleaning up system and updating locate db"
  $SUDO apt-get -qq clean
  $SUDO apt-get -qq autoremove
  $SUDO updatedb

  echo -e "\n${GREEN}============================================================${RESET}"
  echo -e "\n Your system has now been configured! Here is some useful information:\n"
  echo -e "  Directories:\t\t${HOME}/htb/boxes/"
  echo -e "  \t\t\t${HOME}/htb/shells/"
  echo -e "\n  Place VPN Files here:\t${HOME}/vpn/"
  echo -e "\n\n"
  echo -e "${GREEN}============================================================${RESET}"
  echo -e "\n${GREEN}[*]${RESET} Setup is complete. Please ${ORANGE}REBOOT${RESET} for desktop settings to take effect."
  sleep 10

  FINISH_TIME=$(date +%s)
  echo -e "${GREEN}[*] ${BLUE}${APP_NAME}${RESET} Completed Successfully - (Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)\n"
}
# End of script
trap finish EXIT


## =================================================================================== ##
## =============================[  Help :: Core Notes ]=============================== ##
#
## =================================================================================== ##
