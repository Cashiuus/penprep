#
## =============[ Constants ]============== ##
#APP_PATH=$(readlink -f $0)
#APP_BASE=$(dirname "${APP_PATH}")
#APP_NAME=$(basename "${APP_PATH}")
LINES=$(tput lines)
COLS=$(tput cols)
## =============[ Default Settings ]============== ##
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_SETTINGS_DIR=$(dirname ${APP_SETTINGS})
# Can specify the user account for installation scripts, but not needed.
INSTALL_USER=${USER}

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
## ========================================================================== ##


## ===============[  START :: INIT/PROJECT SETUP FUNCTIONS  ]=============== ##
function init_settings() {
  #
  #
  #
  #
  #
  if [[ ! -f "${APP_SETTINGS}" ]]; then
    mkdir -p $(dirname ${APP_SETTINGS})
    echo -e "${GREEN}[*]${RESET} Creating personal settings file"
    cat <<EOF > "${APP_SETTINGS}"
### PERSONAL SYSTEM BUILD SETTINGS ###
#
#

EOF
  else
    echo -e "${GREEN}[*]${RESET} Reading from settings file, please wait..."
    source "${APP_SETTINGS}"
    [[ ${DEBUG} -eq 1 ]] && echo -e "${ORANGE}[DEBUG] App Settings Path: ${APP_SETTINGS}${RESET}"
  fi
}
# ==================[  END :: INIT/PROJECT SETUP FUNCTIONS  ]================== #




# ==================[  START :: ROOT/SUDO CHECK FUNCTIONS  ]================== #
# Env variables
#   The standard env var is $USER. This is regular user in normal state/root in sudo state
#     CURRENT_USER=${USER}
#   This would only be run if within sudo state
#     ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
#
#
function install_sudo() {
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get..."
  echo -e "\n${GREEN}[INPUT]${RESET} Enter root password below"
  su -c "apt-get -y install sudo" root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo via apt-get${RESET}" && exit 1

  echo -e "${GREEN}[INPUT]${RESET} Adding user ${BLUE}${INSTALL_USER}${RESET} to sudo group. Enter root password below"
  su -c "usermod -a -G sudo ${INSTALL_USER}" root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "\n\n${YELLOW}[WARN]${RESET} Rebooting system to take effect!"
  echo -e "${YELLOW}[INFO]${RESET} Restart this script after login!\n\n"
  sleep 5s
  su -c "init 6" root
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
      sudo -l
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

function check_root_old() {
  ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
  #
  # Check if current user is root. If not and sudo is installed, $SUDO can be used.
  #
  #
  if [[ $EUID -ne 0 ]];then
    if [[ $(dpkg-query -s sudo) ]];then
      export SUDO="sudo"
      # $SUDO - run commands with this prefix now to account for either scenario.
    else
      echo "Please install sudo or run this as root."
      exit 1
    fi
  fi
}

function check_root_kali() {
  if [[ $EUID -ne 0 ]]; then
    if [[ $(dpkg-query -s sudo) ]]; then
      export SUDO="sudo"
      # $SUDO - run commands with this prefix now to account for either scenario.
    else
      echo "Please install sudo or run this as root."
      exit 1
    fi
  fi
}
# ===================[  END :: ROOT/SUDO CHECK FUNCTIONS  ]=================== #







# --------- All functions below this line need to be verified ---------------


# =====================[  START :: STYLING/FORMATTING  ]===================== #
function print_banner() {
  #
  #   argv1 = title text of banner
  #   argv2 = program version number
  #

  length=${#1}


  echo -e "\n${BLUE}===================[  ${RESET}${BOLD}$1  ${RESET}${BLUE}]===================${RESET}\n"


  echo -e "${BLUE}================================<${RESET} version: ${__version__} ${BLUE}>================================${RESET}\n"
}


function center_text() {
  width=$(tput cols)
  height=$(tput lines)
  str="$1"
  length=${#str}
  clear
  tput cup $((height / 2)) $(((width / 2) - (length / 2)))
  echo -e "$str"

}
# ======================[  END :: STYLING/FORMATTING  ]====================== #



# ============================[  START :: XFCE  ]============================ #
function xfce4_default_layout() {
  # Copy default xfce4 desktop layout folder shell over

  cp -R "${APP_BASE}"/config/includes/. "${BUILD_DIR}/config/includes.chroot/"
}
# =============================[  END :: XFCE  ]============================= #





# =============================[  START :: GIT  ]============================= #
function install_git() {
  #TODO: Function to clone git repo
  CLONE_PATH='/opt/git'

  git clone -q ${1} || echo -e '[ERROR] Problem cloning ${1}'
}

# ==============================[  END :: GIT  ]============================== #





function version () {
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

function version_check () {
  # Compare to versions and return 0 if newer, 1 if older
  #
  # In this case, I'm checking the installed version of OpenSSH
  #
  # Usage: version_check 7.5 6.5 (or) version_check $openssh_version 6.5
  #

  if [ $(version $1) -ge $(version $2) ]; then
    echo "$1 is newer than $2" >/dev/null
    return 0
  elif [ $(version $1) -lt $(version $2) ]; then
    echo "$1 is older than $2" >/dev/null
    return 1
  fi
}

function md5_compare() {
  # Compare MD5 Hash of 2 files
  #
  # Usage: md5_compare <file1> <file2>
  #
  echo -e "\t-- ${RED}OLD KEYS${RESET} --"
  #openssl md5 /etc/ssh/insecure_original_kali_keys/ssh_host_*
  openssl md5 ${1}
  echo -e "\n\t-- ${GREEN}NEW KEYS${RESET} --"
  #openssl md5 /etc/ssh/ssh_host_*
  openssl md5 ${2}
  echo -e "\n\n"
  sleep 10
}
