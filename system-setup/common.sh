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

### SYSTEM SHAPING VARIABLES
# Can specify the user account for installation scripts, but not needed.
INSTALL_USER=${USER}
LSB_RELEASE=$(lsb_release -cs)

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


# Determine user's active shell to update the correct resource file
if [[ "${SHELL}" == "/usr/bin/zsh" ]]; then
    SHELL_FILE=~/.zshrc
elif [[ "${SHELL}" == "/bin/bash" ]]; then
    SHELL_FILE=~/.bashrc
else
    # Just in case I add other shells in the future
    SHELL_FILE=~/.bashrc
fi
## ========================================================================== ##














##  START :: INIT/PROJECT SETUP FUNCTIONS
# ============================================================================ #
function init_settings() {
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



#   START :: ROOT/SUDO CHECK FUNCTIONS
# ============================================================================ #
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
      echo -e "[ERROR] Please install sudo or run this as root."
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
      echo -e "[ERROR] Please install sudo or run this as root."
      exit 1
    fi
  fi
}

##	Functions :: Core Utility Helpers
# ============================================================================ #
function pause() {
  # Simple function to pause a script mid-stride
  #
  local dummy
  read -s -r -p "Press any key to continue..." -n 1 dummy
}


function asksure() {
  ###
  # Usage:
  #   if asksure; then
  #        echo "Okay, performing rm -rf / then, master...."
  #   else
  #        echo "Awww, why not :("
  #   fi
  ###
  echo -n "Are you sure (Y/N)? "
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




#   MAIN EXECUTION
# ============================================================================ #

# main initial actions to run now that this is a leveraged common place
check_root




#   Function :: Python 3 Install/Setup
# ============================================================================ #
function install_python3() {
    
    PY3_VERSION="3"             # Kali is 3.8, while Debian is 3.7, so being generic here
    DEFAULT_VERSION="3"        # Determines which is set to default (2 or 3)
    DEFAULT_PY3_ENV="default-py3"
    
    $SUDO apt-get -y -qq update

    # Core programming environment dependency files
    $SUDO apt-get -y install build-essential libssl-dev libffi-dev

    echo -e "\n${GREEN}[*]${RESET} Installing/Configuring Python 3"
    # Core python 3 & virtual env support
    $SUDO apt-get -y install python3 python3-all python3-dev \
        python3-pip python3-setuptools python3-venv python3-virtualenv \
        virtualenvwrapper

    # lxml depends (xml library)
    $SUDO apt-get -y install libxml2-dev libxslt1-dev zlib1g-dev

    # Postgresql and psycopg2 depends (db library)
    $SUDO apt-get -y install libpq-dev

    # Pillow depends (image library)
    $SUDO apt-get -y install libtiff5-dev libjpeg62-turbo-dev \
        libfreetype6-dev liblcms2-dev libwebp-dev libffi-dev zlib1g-dev

    # Scrapy depends (scraping library)
    $SUDO apt-get -y install openssl libssl-dev

    echo -e "\n${GREEN}[*]${RESET} Creating Virtual Environments"
    if [ ! -e /usr/local/bin/virtualenvwrapper.sh ]; then
        # apt-get package symlinking to where this file is expected to be
        $SUDO ln -s /usr/share/virtualenvwrapper/virtualenvwrapper.sh /usr/local/bin/virtualenvwrapper.sh
    fi

    source /usr/local/bin/virtualenvwrapper.sh
    # When you run this, its first-run auto-creates our default
    # virtualenv directory at: `$HOME/.virtualenvs/`

    # Custom post-creation script for ALL new envs to auto-install
    # core pip packages
    file="${WORKON_HOME}/postmkvirtualenv"
    cat <<EOF > "${file}"
#!/usr/bin/env bash
pip install beautifulsoup4
pip install pep8
pip install requests
EOF

    # Virtual Environment Setup - Python 3.x
    echo -e "\n${GREEN}[*]${RESET} Creating a Python 3 standard virtualenv"
    mkvirtualenv "${DEFAULT_PY3_ENV}" -p /usr/bin/python${PY3_VERSION}
    if [[ $? -eq 0 ]]; then
        pip install --upgrade pip
        pip install --upgrade setuptools
        deactivate
    fi


    # ======[  Pip Packages  ]======== #

    # Install baseline set of system-wide pip packages
    file="/tmp/requirements.txt"
    cat <<EOF > "${file}"
argparse
beautifulsoup4
colorama
dnspython
future
lxml
mechanize
netaddr
pefile
pep8
Pillow
psycopg2
pygeoip
pylnk3
python-Levenshtein
python-libnmap
requests
six
wheel
EOF

    echo -e "\n${GREEN}[*]${RESET} Installing baseline pip pkgs for Python 3"
    pip3 install -r /tmp/requirements.txt


    # =========================[  Virtualenvwrapper  ]========================= #
    # Add lines to shell dotfile if they aren't there
    # Note: Prefer normal loading versus lazy loading here because lazy loading
    # will not have tab completion until after you've run at least 1 command (e.g. workon <tab>)
    # Source: https://virtualenvwrapper.readthedocs.io/en/latest/install.html
    echo -e "\n${GREEN}[*]${RESET} Updating your dotfile for virtualenvwrapper at: ${GREEN}${SHELL_FILE}${RESET}"
    file="$SHELL_FILE"
    grep -q '^### Load Python Virtualenvwrapper' "${file}" 2>/dev/null \
        || echo '### Load Python Virtualenvwrapper Script helper' >> "${file}"

    # TODO: Improve this regex
    grep -q '^.*"/usr/local/bin/virtualenvwrapper.sh".*' "${file}" 2>/dev/null \
        || echo '[[ -s "/usr/local/bin/virtualenvwrapper.sh" ]] && source "/usr/local/bin/virtualenvwrapper.sh"' >> "${file}"
    grep -q 'export WORKON_HOME=' "${file}" 2>/dev/null \
        || echo 'export WORKON_HOME=$HOME/.virtualenvs' >> "${file}"
    source "${file}"


}


#   Function :: Python 2 Install/Setup
# ============================================================================ #
function install_python2() {

    PY2_VERSION="2.7"
    DEFAULT_PY2_ENV="default-py2"

    $SUDO apt-get -y -qq update
    echo -e "\n${GREEN}[*]${RESET} Installing/Configuring Python 2"
    $SUDO apt-get -y install python python-dev \
        python-setuptools virtualenv

    $SUDO apt-get -y install python-pip
    [[ "$?" -eq 0 ]] && PIP2_SUCCESSFUL=true
    
    if [[ ${PIP2_SUCCESSFUL} = true ]]; then
        echo -e "\n${GREEN}[*]${RESET} Installing baseline pip pkgs for Python 2"
        pip install -r /tmp/requirements.txt
    fi
    
    # Virtual Environment Setup - Python 2.7.x
    echo -e "\n${GREEN}[*]${RESET} Creating a Python 2 standard virtualenv"
    mkvirtualenv "${DEFAULT_PY2_ENV}" -p /usr/bin/python${PY2_VERSION}
    pip install --upgrade pip
    pip install --upgrade setuptools
    deactivate

}



#   Function :: Python Django Install/Setup
# ============================================================================ #
function install_python_django() {


    install_python3
    
    # Install dependencies
    $SUDO apt-get -y install graphviz

    # Custom Django requirements file for quick Django setups
    file="${WORKON_HOME}/django-requirements.txt"
    cat <<EOF > "${file}"
cookiecutter
django
django-debug-toolbar
django-environ
django-extensions
django-import-export
django-secure
Jinja2
psycopg2
pygraphviz
six
EOF


    echo -e "${GREEN}[*]${RESET} Creating a virtualenv for Django..."
    mkvirtualenv django-py3 -p /usr/bin/python3
    if [[ $? -eq 0 ]] && [[ -e "${WORKON_HOME}/django-requirements.txt" ]]; then
        echo -e "${GREEN}[*]${RESET} Creating a virtualenv for Django..."
        pip install -r "${WORKON_HOME}/django-requirements.txt"
    fi
    deactivate

}



#   Function :: Install Cookiecutter project template for Django projects
# ============================================================================ #
function install_cookiecutter() {


    # This'll create your new project in your ~/git/ directory
    cd ~/git
    pip install cookiecutter
    cookiecutter https://github.com/pydanny/cookiecutter-django
    
    # For timezone, default is UTC, but can type in "EST"
    # Cloud provider is for serving static/media files. 
    # If you choose None, make sure to choose "y" for Whitenoise later.

    # Postgres Version: Choose 12

}



#   Function :: Postgresql DB Install/Setup (typically for Django prod)
# ============================================================================ #
function install_postgresql() {
    # Install Postgresql -- atm it'll be version 12; this must match cookiecutter choices


    # Create the file repository configuration:
    $SUDO sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

    # Import the repository signing key:
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

    # Update the package lists:
    $SUDO apt-get update

    # Install the latest version of PostgreSQL.
    # If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':
    $SUDO apt-get -y install postgresql-12


    #Success. You can now start the database server using:
    #pg_ctlcluster 12 main start


}





# --------- All functions below this line need to be verified ---------------


function test_networking() {
  $SUDO apt-get -qq update
  if [[ "$?" -ne 0 ]]; then
    echo -e "${RED} [ERROR]${RESET} Network issues preventing apt-get. Check and try again."
    exit 1
  fi
}

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
  $SUDO openssl md5 ${1}
  echo -e "\n\t-- ${GREEN}NEW KEYS${RESET} --"
  #openssl md5 /etc/ssh/ssh_host_*
  $SUDO openssl md5 ${2}
  echo -e "\n\n"
  sleep 10
}
