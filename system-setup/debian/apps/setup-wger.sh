#!/usr/bin/env bash
## =======================================================================================
# File:     file.sh
#
# Author:   Cashiuus
# Created:  09-Mar-2017     Revised:
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Describe script purpose
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#
#
#
#
#-[ Links/Credit ]------------------------------------------------------------------------
#
#	Setup: https://wger.readthedocs.io/en/latest/getting_started.html
#	Project: https://github.com/wger-project/wger
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1"
__author__="Cashiuus"
## ==========[ TEXT COLORS ]========== ##
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
## =============[ CONSTANTS ]============== ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_ARGS=$@
DEBUG=true
LOG_FILE="${APP_BASE}/debug.log"

# These can be used to know height (LINES) and width (COLS) of current terminal in script
LINES=$(tput lines)
COLS=$(tput cols)
HOST_ARCH=$(dpkg --print-architecture)      # (e.g. output: "amd64")
#INSTALL_USER="user1"

#======[ ROOT PRE-CHECK ]=======#
function install_sudo() {
  # If
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get, elevating to root..."

  su root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to su root${RESET}" && exit 1
  apt-get -y install sudo
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo pkg via apt-get${RESET}" && exit 1
  # Use stored USER value to add our originating user account to the sudoers group
  # TODO: Will this break if script run using sudo? Env var likely will be root if so...test this...
  #usermod -a -G sudo ${ACTUAL_USER}
  usermod -a -G sudo ${INSTALL_USER}
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "${YELLOW}[WARN] ${RESET}Now logging off to take effect. Restart this script after login!"
  sleep 4
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

  if [[ $EUID -ne 0 ]];then
    # If not root, check if sudo package is installed and leverage it
    # TODO: Will this work if current user doesn't have sudo rights, but sudo is already installed?
    if [[ $(dpkg-query -s sudo) ]];then
      export SUDO="sudo"
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
    else
      echo -e "${YELLOW}[WARN] ${RESET}The 'sudo' package is not installed. Press any key to install it (*must enter sudo password), or cancel now"
      read -r -t 10
      install_sudo
      # TODO: This error check necessary, since the function "install_sudo" exits 1 anyway?
      [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Please install sudo or run this as root. Exiting.${RESET}" && exit 1
    fi
  fi
}
check_root
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #


# ========================[  Development Install  ]======================== #
$SUDO apt-get -y install nodejs npm git \
	python-virtualenv python3-dev \
	zlib1g-dev libwebp-dev

# This pkg 'libjpeg8-dev' states obsolete and to install this instead:
$SUDO apt-get -y install libjpeg62-turbo-dev

# Symlink nodejs so that legacy calls from bower will still work
echo -e "[*] Symlinking nodejs to also shortcut at /usr/bin/node for bower compatibility"
$SUDO ln -s /usr/bin/nodejs /usr/bin/node



mkdir ~/git
cd ~/git
git clone https://github.com/wger-project/wger.git
cd wger

# TODO: Install mkvirtualenv wrapper
mkvirtualenv py3-wger -p /usr/bin/python3
# Upgrade pip inside virtualenv or you'll have errors with setuptools later
pip install --upgrade pip
pip install --upgrade setuptools
pip install --upgrade requests

# TODO: wger error, missing 'six' pkg so install it here to avoid issue later
pip install six

echo -e "[*] Virtualenv created, source wrapper then use command 'workon' to activate env"





# ========================[  Production Install  ]======================== #
# Ref: https://wger.readthedocs.io/en/latest/production.html


$SUDO adduser wger --disabled-password --gecos ""

$SUDO apt-get -y install apache2 libapache2-mod-wsgi-py3
$SUDO nano /etc/apache2/sites-available/wger.conf


file="/etc/apache2/sites-available/wger.conf"
$SUDO touch "${file}"
$SUDO chmod 0666 "${file}"
cat <<EOF > "${file}"
<Directory /home/wger/src>
    <Files wsgi.py>
        Require all granted
    </Files>
</Directory>


<VirtualHost *:80>
    WSGIDaemonProcess wger python-path=/home/wger/src python-home=/home/wger/venv
    WSGIProcessGroup wger
    WSGIScriptAlias / /home/wger/src/wger/wsgi.py

    Alias /static/ /home/wger/static/
    <Directory /home/wger/static>
        Require all granted
    </Directory>

    Alias /media/ /home/wger/media/
    <Directory /home/wger//media>
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/wger-error.log
    CustomLog ${APACHE_LOG_DIR}/wger-access.log combined
</VirtualHost>
EOF
$SUDO chmod 0644 "${file}"


# Set locale to avoid apache2 driver errors
export LANG='en_US.UTF-8'

# Activate the settings and disable apache’s default:
$SUDO a2dissite 000-default.conf
$SUDO a2ensite wger
$SUDO service apache2 reload


# =========[ Install Postgresql and create a database and a user ]==== #

$SUDO apt-get -y install postgresql
# Install dev server, specify current version
$SUDO apt-get -y install postgresql-server-dev-9.4

# Switch to postgres user and launch psql prompt
sudo -u postgres psql
echo "CREATE DATABASE wger;"
#psql wger -c "CREATE USER wger WITH PASSWORD ''";
#psql wger -c "GRANT ALL PRIVILEGES ON DATABASE wger to wger";
# NOTE: or change user later on
#psql -c "ALTER USER <user> 'newPassword'";

# Sudo over to this user, have to do it this way for users w/o a password
sudo -u wger bash

virtualenv --python python3 /home/wger/venv
source /home/wger/venv/bin/activate

# Upgrade pip inside virtualenv or you'll have errors with setuptools later
pip install --upgrade pip
pip install setuptools
pip install six

# Create folders for static resources and uploaded files.
cd ~
mkdir static
mkdir media
chmod o+w media

# Install the wger application
git clone https://github.com/wger-project/wger.git /home/wger/src
cd /home/wger/src
pip install -r requirements.txt
python setup.py develop
pip install psycopg2 # Only if using postgres
wger create_settings \
      --settings-path /home/wger/src/settings.py \
      --database-path /home/wger/db/database.sqlite


# Edit the settings file, change database path to postgresql
nano /home/wger/src/settings.py

# Database Engine: django.db.backends.postgresql_psycopg2
# MEDIA_ROOT: /home/wger/media
# STATIC_ROOT: /home/wger/static


# Run installer to download CSS and JS libraries, and also load initial data
wger bootstrap --settings-path /home/wger/src/settings.py --no-start-server

# Collect static resources (~900 files)
# TODO: Pipe \n to this command to accept the default, or pipe 'y' to it to say yes
python manage.py collectstatic


echo -e "[*] Wger app Default Login: admin/admin"
echo -e "[*] Wger app website: http://localhost/"
echo -e
echo -e "[*] NOTE: To use this publicly, change 'tos.html' and 'about.html' before use!"
echo -e

## ==================================================================================== ##
#
# Simple setup using Docker
#	docker run -ti --name wger.apache --publish 8000:80 wger/apache
#	http://localhost:8000 - login is admin/admin
#
#
#
#
#	WGER COMMANDS
# You can get a list of all available commands by calling wger without any arguments:
# Available tasks:
#	bootstrap               Performs all steps necessary to bootstrap the application
#	config_location         Returns the default location for the settings file and the data folder
#	create_or_reset_admin   Creates an admin user or resets the password for an existing one
#	create_settings         Creates a local settings file
#	load_fixtures           Loads all fixtures
#	migrate_db              Run all database migrations
#	start                   Start the application using django's built in webserver
#
# You can also get help on a specific command with wger --help <command>.

