#
# =============[ Constants ]============== #
#APP_PATH=$(readlink -f $0)
#APP_BASE=$(dirname "${APP_PATH}")
#APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"

# These can be used to know height (LINES) and width (COLS) of current terminal in script
LINES=$(tput lines)
COLS=$(tput cols)

# -===[ Check Permissions ]===-
function check_root {
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

function init_settings() {
    #
    #
    #
    #
    #
    if [[ ! -f "${APP_SETTINGS}" ]]; then
        mkdir -p $(dirname ${APP_SETTINGS})
        echo -e "${GREEN}[*] ${RESET}Creating configuration directory"
        echo -e "${GREEN}[*] ${RESET}Creating initial settings file"
        cat <<EOF > "${APP_SETTINGS}"
### KALI PERSONAL BUILD SETTINGS
#
EOF
    fi
    echo -e "${GREEN}[*] ${RESET}Reading from settings file, please wait..."
    source "${APP_SETTINGS}"
    [[ ${DEBUG} -eq 1 ]] && echo -e "${ORANGE}[DEBUG] App Settings Path: ${APP_SETTINGS}${RESET}"
}



function xfce4_default_layout() {
    # Copy default xfce4 desktop layout folder shell over

    cp -R "${APP_BASE}"/config/includes/. "${BUILD_DIR}/config/includes.chroot/"
}



function install_git() {
    #TODO: Function to clone git repo
    CLONE_PATH='/opt/git'

    git clone -q ${1} || echo -e '[ERROR] Problem cloning ${1}'
}
