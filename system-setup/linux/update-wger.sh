#!/bin/bash


# Dedicated user was added via: sudo adduser wger --disabled-password --gecos ""




WGER_HOME=/home/wger/src

# Can change to the wger user via: sudo su wger


# 1. cd /home/wger/src
cd "${WGER_HOME}"

# 2. Become owner of the folder so we can update it
sudo chown -R user1 .
git pull


workon py3-wger


# 4. Check if there are now errors present, or if a migrate is necessary
python manage.py check
read

python manage.py migrate





# Bower - delete and refresh files
cd "${WGER_HOME}"
rm -rf wger/core/static/bower-components

# Note, you cannot install bower as a restricted user, so you have to log out for this piece

cd wger
npm install bower




sudo su wger
workon py3-wger
cd "${WGER_HOME}"
python manage.py bower install



# Clear the cache
python manage.py clear-cache -clear-all




