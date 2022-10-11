#
## =============[ Constants ]============== ##
#APP_PATH=$(readlink -f $0)
#APP_BASE=$(dirname "${APP_PATH}")
#APP_NAME=$(basename "${APP_PATH}")
## =============[ Default Settings ]============== ##
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_SETTINGS_DIR=$(dirname ${APP_SETTINGS})

### SYSTEM SHAPING VARIABLES
LINES=$(tput lines)
COLS=$(tput cols)
# Can specify the user account for installation scripts, but not needed.
INSTALL_USER=${USER}
LSB_RELEASE=$(lsb_release -cs)
ETH_INTERFACE=$(ip link | awk -F: '$0 ~ "eth|ens"{print $2;getline}' | sed -e 's/^[[:space:]]*//')
#WLAN_INTERFACE=$(ip link | awk -F: '$0 ~ "wl"{print $2;getline}' | sed -e 's/^[[:space:]]*//')
#TUN_INTERFACE=$(ip link | awk -F: '$0 ~ "tun"{print $2;getline}' | sed -e 's/^[[:space:]]*//')

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
    SHELL_NAME="zsh"
    SHELL_FILE=~/.zshrc
elif [[ "${SHELL}" == "/usr/local/bin/zsh" ]]; then
    SHELL_NAME="zsh"
    SHELL_FILE=~/.zshrc
elif [[ "${SHELL}" == "/bin/bash" ]]; then
    SHELL_NAME="bash"
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

##  Functions :: Core Utility Helpers
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


function time_elapsed() {
    # Usage: runtime <START_TIME> <END_TIME>
    delta=$(( $2 - $1 ))
    if [[ $delta -lt 0 ]]; then
        echo -e "[ERR] Invalid parameters resulted in negative number, did you pass args backwards?"
        return
    fi
    #echo -e "[*] raw delta: $delta"
    hrs=$(( $delta / 3600 ))
    minutes=$(( (( $delta - (( $hrs * 3600 )) )) / 60 ))
    #echo -e "[*] raw minutes: $minutes"
    #echo -e "[*] raw hours: $hrs"
    days=0
    while [[ $hrs -gt 24 ]]; do
        ((hrs-=24))
        ((days+=1))
    done
    if [[ $days -ge 1 ]]; then
        echo -e "[*] Total Time Elapsed: $days days, $hrs hours, $minutes minutes"
    else
        echo -e "[*] Total time elapsed: $hrs hours, $minutes minutes"
    fi
}


function make_tmp_dir() {
    # <doc:make_tmp_dir> {{{
    #
    # This function taken from a vmware tool install helper to securely
    # create temp files. (installer.sh)
    #
    # Usage: make_tmp_dir dirname prefix
    #
    # Required Variables:
    #
    #   dirname
    #   prefix
    #
    # Return value: null
    #
    # </doc:make_tmp_dir> }}}

    local dirname="$1" # OUT
    local prefix="$2"  # IN
    local tmp
    local serial
    local loop

    tmp="${TMPDIR:-/tmp}"

    # Don't overwrite existing user data
    # -> Create a directory with a name that didn't exist before
    #
    # This may never succeed (if we are racing with a malicious process), but at
    # least it is secure
    serial=0
    loop='yes'
    while [ "$loop" = 'yes' ]; do
    # Check the validity of the temporary directory. We do this in the loop
    # because it can change over time
    if [ ! -d "$tmp" ]; then
      echo 'Error: "'"$tmp"'" is not a directory.'
      echo
      exit 1
    fi
    if [ ! -w "$tmp" -o ! -x "$tmp" ]; then
      echo 'Error: "'"$tmp"'" should be writable and executable.'
      echo
      exit 1
    fi

    # Be secure
    # -> Don't give write access to other users (so that they can not use this
    # directory to launch a symlink attack)
    if mkdir -m 0755 "$tmp"'/'"$prefix$serial" >/dev/null 2>&1; then
      loop='no'
    else
      serial=`expr $serial + 1`
      serial_mod=`expr $serial % 200`
      if [ "$serial_mod" = '0' ]; then
        echo 'Warning: The "'"$tmp"'" directory may be under attack.'
        echo
      fi
    fi
    done

    eval "$dirname"'="$tmp"'"'"'/'"'"'"$prefix$serial"'
}


function is_process_alive() {
  # Checks if the given pid represents a live process.
  # Returns 0 if the pid is a live process, 1 otherwise
  #
  # Usage: is_process_alive 29833
  #   [[ $? -eq 0 ]] && echo -e "Process is alive"

  local pid="$1" # IN
  ps -p $pid | grep $pid > /dev/null 2>&1
}


function finish {
    ###
    # finish function
    # Any script-termination routines go here, but function cannot be empty
    #
    ###
    clear
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"
    # Redirect app output to log, sending both stdout and stderr
    # *NOTE: This method will not parse color codes, therefore fails color output
    # cmd_here 2>&1 | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT




#   Functions :: OS & Patching
# ============================================================================ #

function get_os() {
	# Query various ways to identify the family and version of our OS for use with setup processes.
	#
	#	return debian 10
	#
  if [[ -f "/etc/os-release" ]]; then
		OS_FAMILY=$(cat /etc/os-release | egrep "^ID=" | cut -d "=" -f2)	# e.g. "debian"
		OS_VERSION=$(cat /etc/os-release | grep "VERSION_ID=" | cut -d "=" -f2 | cut -d '"' -f2)	# e.g. 10
  else
		OS_FAMILY=$(lsb_release -sd | awk '{print 1}')
		OS_VERSION=$(lsb_release -r | awk '{print $2}')
		# -- Ubuntu specific
		if [[ "$OS_VERSION" == "18."* || "20."* ]]; then
			echo -e "[*] OS is Ubuntu 18 or 20"
			return "$OS_FAMILY" "$OS_VERSION"
		fi
  fi
  echo -e "[Get OS] $OS_FAMILY $OS_VERSION\n"
  return "$OS_FAMILY" "$OS_VERSION"	# e.g. returns "debian" "10"
}


patch_system() {
  # Make sure all currently installed packages are updated.  This has the added benefit
  # that we update the package metadata for later installing new packages.

  if [ -x /usr/bin/apt-get -a -x /usr/bin/dpkg-query ]; then
    while ! $SUDO sudo add-apt-repository universe ; do
      echo "Error subscribing to universe repository, perhaps because a system update is running; will wait 30 seconds and try again." >&2
      sleep 30
    done
    while ! $SUDO apt-get -q -y update >/dev/null ; do
      echo "Error updating package metadata, perhaps because a system update is running; will wait 60 seconds and try again." >&2
      sleep 60
    done
    while ! $SUDO apt-get -q -y upgrade >/dev/null ; do
      echo "Error updating packages, perhaps because a system update is running; will wait 60 seconds and try again." >&2
      sleep 60
    done
      while ! $SUDO apt-get -q -y install lsb-release >/dev/null ; do
        echo "Error installing lsb-release, perhaps because a system update is running; will wait 60 seconds and try again." >&2
        sleep 60
      done
  elif [ -x /usr/bin/yum -a -x /bin/rpm ]; then
    $SUDO yum -q -e 0 makecache
    $SUDO yum -y -q -e 0 -y install deltarpm
    $SUDO yum -q -e 0 -y update
    $SUDO yum -y -q -e 0 -y install redhat-lsb-core yum-utils
    if [ -s /etc/redhat-release -a -s /etc/os-release ]; then
      . /etc/os-release
      if [ "$VERSION_ID" = "7" ]; then
        $SUDO yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
        if [ ! -e /etc/centos-release ]; then
          $SUDO yum -y install subscription-manager
          $SUDO subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"  --enable "rhel-ha-for-rhel-*-server-rpms"
        fi
      elif [ "$VERSION_ID" = "8" ]; then
        $SUDO yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
        if [ -e /etc/centos-release ]; then
          $SUDO dnf config-manager --set-enabled powertools
        else
          $SUDO yum -y install subscription-manager
          $SUDO subscription-manager repos --enable "codeready-builder-for-rhel-8-`/bin/arch`-rpms"
        fi
      fi
    fi
    $SUDO yum -q -e 0 makecache
  fi
}



function install_tool() {
  # Install a program.
  #   $1 holds the name of the executable we need
  #   $2 is one or more packages that can supply that executable
  #      (put preferred package names early in the list).
  #
  #   Usage:  install_tool <pkg_name>
  #           install_tool nc "netcat nc nmap-ncat"
  #           install_tool sha256sum "coreutils"
  ###

  binary="$1"
  echo "Installing package that contains $binary" >&2
  potential_packages="$2"

  if type -path "$binary" >/dev/null ; then
    echo "$binary executable is installed." >&2
  else
    if [ -x /usr/bin/apt-get -a -x /usr/bin/dpkg-query ]; then
      for one_package in $potential_packages ; do
        if ! type -path "$binary" >/dev/null ; then   #if a previous package was successfully able to install, don't try again.
          $SUDO apt-get -q -y install $one_package
        fi
      done
    elif [ -x /usr/bin/yum -a -x /bin/rpm ]; then
      #Yum takes care of the lock loop for us
      for one_package in $potential_packages ; do
        if ! type -path "$binary" >/dev/null ; then   #if a previous package was successfully able to install, don't try again.
          $SUDO yum -y -q -e 0 install $one_package
        fi
      done
    else
      fail "Neither (apt-get and dpkg-query) nor (yum, rpm, and yum-config-manager) is installed on the system"
    fi
  fi

  if type -path "$binary" >/dev/null ; then
    return 0
  else
    echo "WARNING: Unable to install $binary from a system package" >&2
    return 1
  fi
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
    $SUDO apt-get -y install python3 python3-dev \
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
lxml
mechanize
netaddr
pefile
pep8
Pillow
poetry
psycopg2
pygeoip
pylnk3
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
  $SUDO apt-get -y install python python2-dev \
    python-setuptools python2-setuptools-whl \
    virtualenv

  $SUDO apt-get -y install python-pip
  if [[ "$?" -eq 0 ]]; then
    PIP2_SUCCESSFUL=true
  else
    # Fallback method of installing pip:
    cd /tmp && wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
    $SUDO python2 get-pip.py
    python2 -m pip --version
  fi

  if [[ ${PIP2_SUCCESSFUL} = true ]]; then
    echo -e "\n${GREEN}[*]${RESET} Installing baseline pip pkgs for Python 2"
    pip install -r /tmp/requirements.txt
  else
    python2 -m pip install -r requirements.txt
  fi

  # Virtual Environment Setup - Python 2.7.x
  echo -e "\n${GREEN}[*]${RESET} Creating a Python 2 standard virtualenv"
  mkvirtualenv "${DEFAULT_PY2_ENV}" -p /usr/bin/python${PY2_VERSION}
  workon "${DEFAULT_PY2_ENV}"
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
    # Postgres Version: Choose 14

}



#   Function :: Postgresql DB Install/Setup (typically for Django prod)
# ============================================================================ #
function install_postgresql() {
    # Install Postgresql -- atm it'll be version 14; this must match cookiecutter choices
    # OLD: Create the file repository configuration:
    #$SUDO sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

    # Import the repository signing key:
    #wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

    # Update the package lists:
    $SUDO apt-get update

    # Install the latest version of PostgreSQL.
    # If you want a specific version, use 'postgresql-14' or similar instead of 'postgresql':
    $SUDO apt-get -y install postgresql-14


    #Success. You can now start the database server using:
    #pg_ctlcluster 14 main start

}





# --------- All functions below this line need to be verified ---------------


function test_networking() {
  $SUDO apt-get -qq update
  if [[ "$?" -ne 0 ]]; then
    echo -e "${RED}[ERROR]${RESET} Network issues preventing apt-get. Check and try again."
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


# args:
# input - $1
function to_lowercase() {
    #eval $invocation

    echo "$1" | tr '[:upper:]' '[:lower:]'
    return 0
}

# args:
# input - $1
function remove_trailing_slash() {
    #eval $invocation

    local input="${1:-}"
    echo "${input%/}"
    return 0
}

# args:
# input - $1
function remove_beginning_slash() {
    #eval $invocation

    local input="${1:-}"
    echo "${input#/}"
    return 0
}

# args:
# root_path - $1
# child_path - $2 - this parameter can be empty
function combine_paths() {
    eval $invocation

    # TODO: Consider making it work with any number of paths. For now:
    if [ ! -z "${3:-}" ]; then
        say_err "combine_paths: Function takes two parameters."
        return 1
    fi

    local root_path="$(remove_trailing_slash "$1")"
    local child_path="$(remove_beginning_slash "${2:-}")"
    say_verbose "combine_paths: root_path=$root_path"
    say_verbose "combine_paths: child_path=$child_path"
    echo "$root_path/$child_path"
    return 0
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

  if [[ $(version $1) -ge $(version $2) ]]; then
    echo "$1 is newer than $2" >/dev/null
    return 0
  elif [[ $(version $1) -lt $(version $2) ]]; then
    echo "$1 is older than $2" >/dev/null
    return 1
  fi
}

function check_version_java() {
    ###
    #   Check the installed/active version of java
    #
    #   Usage: check_version_java
    #
    ###
    if type -p java; then
        echo found java executable in PATH
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
        echo found java executable in JAVA_HOME
        _java="$JAVA_HOME/bin/java"
    else
        echo "no java"
    fi

    if [[ "$_java" ]]; then
        version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo version "$version"
        if [[ "$version" > "1.5" ]]; then
            echo version is more than 1.5
        else
            echo version is less than 1.5
        fi
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



check_sha256() {
  # Pass file and hash and verify it
  #   Usage: <file> <known_good_hash_to_verify>
  ##

  [[ $(which sha256sum) ]] || echo -e "[ERROR] sha256sum missing from system" && return

  if [ $(sha256sum $1 | awk '{print $1}') = $2 ]; then
    echo -e "[*] SHA256 hash matches what was provided!"
    retval=1
  else
    echo -e "[-] SHA256 hash DOES NOT match what was provided!"
    retval=0
  fi
  return $retval
}

