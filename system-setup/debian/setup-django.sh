#!/usr/bin/env bash
## =======================================================================================
# File:     setup-django.sh
# Author:   Cashiuus
# Created:  05-Oct-2020     Revised: 11-Oct-2020
#
##-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Install Python Django, cookiecutter, and postgresql
#		    to fully support a dev server environment.
#
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="0.1.0"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
ORANGE="\033[38;5;208m" # Debugging
PURPLE="\033[01;35m"    # Other
GREY="\e[90m"           # Subdued Text
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## =========[ CONSTANTS ]================ ##
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
## =======[ EDIT THESE SETTINGS ]======= ##
py3version="3.7"

## =============================================================================




# Install dependencies
$SUDO apt-get -y install graphviz




echo -e "{GREEN}[*] ${PURPLE}[penprep]${RESET} Creating a virtualenv for Django..."
mkvirtualenv django-py37 -p /usr/bin/python${py3version}
if [[ $? -eq 0 ]] && [[ -e "${WORKON_HOME}/django-requirements.txt" ]]; then
	echo -e "{GREEN}[*] ${PURPLE}[penprep]${RESET} Creating a virtualenv for Django..."
	pip install -r "${WORKON_HOME}/django-requirements.txt"
fi
deactivate






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
psycopg2
pygraphviz
six
EOF





# This'll create your new project in your ~/git/ directory
cd ~/git
pip install cookiecutter
cookiecutter https://github.com/pydanny/cookiecutter-django


# For timezone, default is UTC, but can type in "EST"
# Cloud provider is for serving static/media files. 
# If you choose None, make sure to choose "y" for Whitenoise later.

# Postgres Version: Choose 12



# Install Postgresql


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
pg_ctlcluster 12 main start










