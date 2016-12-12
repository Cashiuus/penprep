#
# =============[ Constants ]============== #
#APP_PATH=$(readlink -f $0)
#APP_BASE=$(dirname "${APP_PATH}")
#APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/kali-builder/settings.conf"

# ===============================[ Check Permissions ]============================== #
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
