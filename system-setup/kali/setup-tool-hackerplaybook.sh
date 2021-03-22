#!/bin/bash

# Setup Kali based on the book "The Hacker Playbook"




# Change default password on root
passwd

# Update the core image
apt-get -qq -y update && apt-get -y dist-upgrade

# Turn on MSF
service postgresql start
service Metasploit start

# Enable logging for msfconsole, *very verbose
echo "spool/root/.msf4/msf_console.log" > root/.msf4/msfconsole.rc

# Install the DISCOVER scripts
cd /opt
git clone https://github.com/leebaird/discover.git
cd discover/
./setup.sh

# Install SMBEXEC
cd /opt
git clone https://github.com/brav0hax/smbexec.git
cd smbexec
./install.sh
# Choose option #1 to install into /opt/
./install.sh
# Then, choose option 4 (to compile binaries)

# Install VEIL FRAMEWORK
cd /opt
git clone https://github.com/Veil-Framework/Veil
cd Veil
./Install.sh

# Download and save WCE binaries
mkdir -p ~/binaries && cd ~/binaries/
# ? current version ?
wget http://www.ampliasecurity.com/research/wce_v1_4beta_universal.zip
unzip -d ./wce wce_v1_4beta_universal.zip

# Download and save MIMIKATZ
cd ~/binaries/
wget http://blog.gentilkiwi.com/downloads/mimikatz_trunk.zip
unzip -d ./mimikatz mimikatz_trunk.zip

# Save some online custom password lists
mkdir -p ~/lists/ && cd ~/lists/
# Download other lists via browser if needed, such as this one
# https://mega.co.nz/#!3VZiEJ4L!TitrTiiwygI2I_7V2bRWBH6rOqlcJ14tSjss2qR5dqo
#gzip -d crackstation_human_only.txt.gz

wget http://downloads.skullsecurity.org/passwords/rockyou.txt.bz2
bzip2 -d rockyou.txt.bz2

# Portswigger Burp
# It's already installed in /usr/bin/burpsuite via apt-get install burpsuite


# PEEPINGTOM
# This app takes snapshots of websites
cd /opt
git clone https://bitbucket.org/LaNMaSteR53/peepingtom
cd ./peepingtom
wget https://gist.github.com/nopslider/5984316/raw/423b02c53d225fe8dfb4e2df9a20bc800cc78e2c/gnmap.pl

wget https://phantomjs.googlecode.com/files/phantomjs1.9.2-linux-i686.tar.bz2
tar xvjf phantomjs-1.9.2-linux-i686.tar.bz2
cp ./phantomjs-1.9.2-linux-i686/bin/phantomjs .


# Add custom Nmap NSE script
cd /usr/share/nmap/scripts/
wget https://raw.github.com/hdm/scan-tools/master/nse/banner-plus.nse

# POWERSPLOIT
cd /opt
git clone https://github.com/mattifestation/PowerSploit
cd PowerSploit
wget https://raw.github.com/obscuresec/random/master/StartListener.py
wget https://raw.github.com/darkoperator/powershell_scripts/master/ps_encoder.py

# RESPONDER
cd /opt
git clone https://github.com/SpiderLabs/Responder

# BYPASS UAC
cd /opt
wget http://www.secmaniac.com/files/bypassuac.zip
unzip bypassuac.zip

# BeEF
apt-get install beef-xss


# SecLists
cd /opt
git clone https://github.com/danielmiessler/SecLists

# Firefox Addons
# Get these via browser
# http://addons.mozilla.org/en-US/firefox/addon/web-developer/
# http://addons.mozilla.org/en-US/firefox/addon/tamper-data/
# http://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/
# http://addons.mozilla.org/en-US/firefox/addon/user-agent-switcher/











