#!/usr/bin python
#
#
#


# Add the official Repos to the Aptitude sources list
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
echo "deb http://download.skype.com/linux/repos/debian/ stable non-free" >> /etc/apt/sources.list

# Add the Google GPG Key
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# Install the Debian Multimedia keyring
dpkg -i debian-multimedia-keyring_2010.12.26_all.deb

# Execute apt-get update, then install Google Chrome & Skype
apt-get update
apt-get install google-chrome-stable
apt-get install skype

# Set up new user account...'m' flag has it setup home directory for the new account
useradd -m chromeuser

# sux is a wrapper to 'su' that transfers your X credentials to the target user
sux chromeuser google-chrome

