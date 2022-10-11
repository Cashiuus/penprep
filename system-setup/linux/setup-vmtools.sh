#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: setup-vmware-tools.sh       (Update: 17-Jan-2015) #
#-Author------------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-License-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#  Credit: https://github.com/g0tmi1k/os-scripts/             #
#-Notes-------------------------------------------------------#
#                                                             #
#  Usage: curl -L http://bit.ly/install-vmtools | bash        #
#                                                             #
#                                                             #
#                                                             #
#-------------------------------------------------------------#



##  Functions
## =================================== ##
function install_sudo() {
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get..."
  echo -e "\n${GREEN}[INPUT]${RESET} Enter root password below"
  su -c "apt-get -y install sudo" root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo via apt-get${RESET}" && exit 1

  echo -e "${GREEN}[INPUT]${RESET} Adding user ${BLUE}${INSTALL_USER}${RESET} to sudo group. Enter root password below"
  su -c "/usr/sbin/usermod -a -G sudo ${INSTALL_USER}" root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "\n\n${YELLOW}[WARN]${RESET} Rebooting system to take effect!"
  echo -e "${YELLOW}[INFO]${RESET} Restart this script after login!\n\n"
  sleep 5s
  su -c "/sbin/init 6" root
  exit 0
}

function check_root() {
  if [[ $EUID -ne 0 ]]; then
    # If not root, check if sudo package is installed
    if [[ $(which sudo) ]]; then
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
      export SUDO="sudo"
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

function install_vmtools() {
        local SYSMANUF=$($SUDO dmidecode -s system-manufacturer)
        local SYSPRODUCT=$($SUDO dmidecode -s system-product-name)
        if [[ $SYSMANUF == "Xen" ]] || [[ $SYSMANUF == "VMware, Inc." ]] || [[ $SYSPRODUCT == "VirtualBox" ]]; then
                # https://github.com/vmware/open-vm-tools
                if [[ ! $(which vmware-toolbox-cmd) ]]; then
                  echo -e "${YELLOW}[INFO] Now installing vm-tools. This will require a reboot. Re-run script after reboot...${RESET}"
                  sleep 4
                  $SUDO apt-get -y install open-vm-tools-desktop fuse
                  $SUDO reboot
                else
                        echo -e "${GREEN}[*]${RESET} VM Tools appears to already be installed. All done."
                fi
        fi
}


##  Running Main
## =================================== ##

check_root
install_vmtools
exit 0





###
# troubleshooting steps
systemctl stop run-vmblock\\x2dfuse.mount
killall -q -w vmtoolsd

systemctl start run-vmblock\\x2dfuse.mount
systemctl enable run-vmblock\\x2dfuse.mount

vmware-user-suid-wrapper vmtoolsd -n vmusr 2>/dev/null
vmtoolsd -b /var/run/vmroot 2>/dev/null
