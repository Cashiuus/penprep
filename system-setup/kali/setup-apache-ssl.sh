#!/bin/bash
## =============================================================================
# File:     setup-apache-ssl.sh
#
# Author:   Cashiuus
# Created:  10-APR-2016 - - - - - - (Revised: 13-MAY-2016)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
# Purpose:
#
# Reference Tut:
#   https://www.linode.com/docs/security/ssl/ssl-apache2-debian-ubuntu/
#   apache2 docs: /usr/share/doc/apache2/README.Debian.gz
#	Apache Hardening: http://www.thegeekstuff.com/2011/03/apache-hardening
#
## =============================================================================
__version__="0.9"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
PURPLE="\033[01;35m"   #
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LOG_FILE="${APP_BASE}/debug.log"

## ========================================================================== ##
# ===============================[  BEGIN  ]================================== #

$SUDO apt-get -qq update
$SUDO apt-get -y -qq install apache2 openssl

# Enable headers mod for hardening
$SUDO a2enmod headers

# Edit the security file to reduce response Header information and add protections
echo -e "Edit the following config file to reduce response Header details and app protections..."
sleep 5s
file="/etc/apache2/conf-enabled/security.conf"
$SUDO nano /etc/apache2/conf-enabled/security.conf
# Change ServerTokens to "Minimal"
$SUDO sed -i 's|^ServerTokens.*|ServerTokens Minimal|g' "${file}"
# -- ServerSignature
$SUDO sed -i 's|^ServerSignature.*|ServerSignature Off|g' "${file}"

$SUDO sed -i 's|^#Header set X-Content-Type-Options.*|Header set X-Content-Type-Options: "nosniff"|g' "${file}"

$SUDO sed -i 's|^#Header set X-Frame-Options.*|Header set X-Frame-Options: "sameorigin"|g' "${file}"

# Enforce a strong cipherlist, as copied from: https://cipherli.st/
file=/etc/apache2/conf-enabled/harden-ssl.conf
cat << EOF > ${file}
<IfModule mod_ssl.c>
    SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
    SSLProtocol All -SSLv2 -SSLv3
    SSLHonorCipherOrder On

    Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    # Requires Apache >= 2.4
    SSLCompression off
    # SSLSessionTickets requires Apache >= 2.4.12 (current version is 2.4.18 in Kali)
    SSLSessionTickets off
    SSLUseStapling on
    SSLStaplingCache "shmcb:logs/stapling-cache(150000)"
</IfModule>
EOF

# Enable SSL for Apache
$SUDO a2enmod ssl

# Generate SSL certs
$SUDO mkdir /etc/apache2/ssl/ && cd /etc/apache2/ssl/
# Auto-generate, accepting defaults
echo -e '\n' | timeout 30 openssl req -x509 -nodes -days 365 -newkey rsa:2048  -keyout apache.key -out apache.crt
# Protect the files
$SUDO chmod 600 /etc/apache2/ssl/*

# enable SSL site
$SUDO a2ensite default-ssl
# select "default-ssl" at interactive prompt

# Configure Apache to use SSL
$SUDO nano /etc/apache2/sites-enabled/default-ssl.conf


# Look for the VirtualHost section for port 443, and modify it
# Below the line "ServerAdmin webmaster@localhost", add
    #ServerName 192.168.1.52:443
# Next, find the lines for the SSL Certificate configuration
    #SSLCertificateFile /etc/apache2/ssl/apache.crt
    #SSLCertificateKeyFile /etc/apache2/ssl/apache.key

# Finish
$SUDO systemctl restart apache2
