#
# =============[ Constants ]============== #
#APP_PATH=$(readlink -f $0)
#APP_BASE=$(dirname "${APP_PATH}")
#APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
INSTALL_USER=''   # Can specify the user account for installation scripts, but not needed.
LINES=$(tput lines)
COLS=$(tput cols)
# ============================================================================ #



# =================[  START :: INIT/PROJECT SETUP FUNCTIONS  ]================= #
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
### PERSONAL BUILD SETTINGS
#
#

SSH_SERVER_IP="0.0.0.0"
SSH_SERVER_PORT=22
EOF
    fi
    echo -e "${GREEN}[*]${RESET} Reading from settings file, please wait..."
    source "${APP_SETTINGS}"
    [[ ${DEBUG} -eq 1 ]] && echo -e "${ORANGE}[DEBUG] App Settings Path: ${APP_SETTINGS}${RESET}"
}
# ==================[  END :: INIT/PROJECT SETUP FUNCTIONS  ]================== #




# ==================[  START :: ROOT/SUDO CHECK FUNCTIONS  ]================== #
function install_sudo() {
  # If
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get, elevating to root..."

  # TODO: Fix this method of su root
  su root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to su root${RESET}" && exit 1
  apt-get -y install sudo
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo via apt-get${RESET}" && exit 1
  # Use stored USER value to add our originating user account to the sudoers group
  # TODO: Will this break if script run using sudo? Env var likely will be root if so...test this...
  #usermod -a -G sudo ${ACTUAL_USER}
  usermod -a -G sudo ${INSTALL_USER}
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "${YELLOW}[WARN] ${RESET}Now logging off to take effect. Restart this script after login!"
  sleep 4
  # TODO: Fix this, "exit" is preferred over "logout" but don't want to exit script
  # First logout command will logout from su root elevation
  logout
  exit 1
}

function check_root() {

  # There is an env var that is $USER. This is regular user if in normal state, root in sudo state
  #   CURRENT_USER=${USER}
  #   ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
   # This would only be run if within sudo state
   # This variable serves as the original user when in a sudo state

  if [[ $EUID -ne 0 ]]; then
    # If not root, check if sudo package is installed and leverage it
    # TODO: Will this work if current user doesn't have sudo rights, but sudo is already installed?
    if [[ $(dpkg-query -s sudo) ]]; then
      export SUDO="sudo"
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
    else
      echo -e "${YELLOW}[WARN]${RESET} The 'sudo' package is not installed."
      echo -e "${YELLOW}[+]${RESET} Press any key to install it (*You'll be prompted to enter sudo password). Otherwise, manually cancel script now..."
      read -r -t 10
      install_sudo
      # TODO: This error check necessary, since the function "install_sudo" exits 1 anyway?
      [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Please install sudo or run this as root. Exiting.${RESET}" && exit 1
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
# ===================[  END :: ROOT/SUDO CHECK FUNCTIONS  ]=================== #









# --------- All functions below this line need to be verified ---------------



# =====================[  START :: STYLING/FORMATTING  ]===================== #
function print_banner() {
    #
    #   argv1 = title text of banner
    #   argv2 = program version number
    #

    length=${#1}


    echo -e "\n${BLUE}===================[  ${RESET}${BOLD}$1  ${RESET}${BLUE}]===================${RESET}"


    echo -e "${BLUE}===========================<${RESET} version: ${__version__} ${BLUE}>===========================\n${RESET}"
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
# =====================[  END :: STYLING/FORMATTING  ]===================== #



# ============================[  START :: XFCE  ]============================ #
function xfce4_default_layout() {
    # Copy default xfce4 desktop layout folder shell over

    cp -R "${APP_BASE}"/config/includes/. "${BUILD_DIR}/config/includes.chroot/"
}
# =============================[  END :: XFCE  ]============================= #



function install_git() {
    #TODO: Function to clone git repo
    CLONE_PATH='/opt/git'

    git clone -q ${1} || echo -e '[ERROR] Problem cloning ${1}'
}
