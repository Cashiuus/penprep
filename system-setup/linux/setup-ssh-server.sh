#!/usr/bin/env bash
## =======================================================================================
# File:     setup-ssh-server.sh
# Author:   Cashiuus
# Created:  01-Dec-2015 - (Revised: 27-Dec-2020)
#
##-[ Info ]-------------------------------------------------------------------------------
#
# Purpose:  Setup SSH Server on Kali Linux to non-default port
#           and also replacing original keys with new ones
#
# NOTES:  - As of July 10, 2015, GNOME keyring cannot handle ECDSA and Ed25519 keys.
#           You must use another SSH agents or stick to RSA keys.
#         - Windows SSH PuTTY does not support ECDSA as of March, 2016.
#
#
##-[ Links/Credit ]-----------------------------------------------------------------------
#
# Thanks to:  https://www.lisenet.com/2013/openssh-server-installation-and-configuration-on-debian/
#             https://wiki.archlinux.org/index.php/SSH_keys
#             https://help.ubuntu.com/community/SSH/OpenSSH/Configuring
#
# SSH Hardening Guides:
#     http://docs.hardentheworld.org/Applications/OpenSSH/
#     http://dev-sec.io/features.html
#
##-[ Copyright ]--------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="1.4"
__author__='Cashiuus'
## =============[ CONSTANTS ]============= ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_ARGS=$@
LINES=$(tput lines)
COLS=$(tput cols)
HOST_ARCH=$(dpkg --print-architecture)      # (e.g. output: "amd64")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
LOG_FILE="${APP_BASE}/debug.log"
DEBUG=false
DO_LOGGING=false

LOCAL_IP=$(hostname -I | cut -d ' ' -f1)


## ===========================[ START :: LOADING ]=========================== ##
[[ "$DEBUG" = true ]] && echo -e "\n${GREEN}[$(date +"%F %T")] ${RESET}Start :: Beginning script execution\n\n" | tee -a "${LOG_FILE}"

if [[ -s "${APP_BASE}/../common.sh" ]]; then
  source "${APP_BASE}/../common.sh"
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: load/source files :: success${RESET}" | tee -a "${LOG_FILE}"
else
  echo -e "${RED}[ERROR]${RESET} common.sh functions file is missing."
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: load/source files :: fail${RESET}" | tee -a "${LOG_FILE}"
  exit 1
fi

# Check root/sudo if we can run this script
check_root
# Initialize configuration directory and settings file
init_settings
print_banner "Penprep Build Engine :: SSH Server Setup" $__version__

if [[ "$LOCAL_IP" ]]; then
  echo -e "${GREEN}[*] ${RESET}Local Server IP appears to be : ${BLUE}${LOCAL_IP}${RESET} : in case you want to enter it below"
fi
if [[ ! ${SSH_SERVER_ADDRESS} ]]; then
  # If these aren't in the settings file, generate defaults
  echo -e -n "${GREEN}[+] ${RESET}"
  read -r -e -p "Enter SSH Server IP (If unsure, just press ENTER): " -i "0.0.0.0" SSH_SERVER_ADDRESS

  if [[ ! ${SSH_SERVER_PORT} ]]; then
    echo -e -n "${GREEN}[+] ${RESET}"
    read -r -e -p "Enter SSH Server Port (Default: 22): " -i "22" SSH_SERVER_PORT
  fi

  [[ ${DEBUG} -eq 1 ]] && echo -e "${ORANGE}[DEBUG]${RESET} Generating initial SSH defaults into settings file${RESET}" | tee -a "${LOG_FILE}"
  cat <<EOF >> "${APP_SETTINGS}"
### [SSH Server Configuration]
SSH_SERVER_ADDRESS="${SSH_SERVER_ADDRESS}"
SSH_SERVER_PORT=${SSH_SERVER_PORT}
SSH_USER_DIR="\${HOME}/.ssh"
SSH_AUTH_KEYS_FILE="\${SSH_USER_DIR}/authorized_keys"

ENABLE_IPV6=false
SSH_SERVER_ADDRESS_IPV6='::'

SSH_AUTOSTART=true
ALLOW_ROOT_LOGIN=false
DO_PW_AUTH=true
DO_PUBKEY_AUTH=true

# Enable Geoip-based whitelist of source countries
# allowed to access this system's SSH service.
DO_GEOIP=true
ALLOW_COUNTRIES="US AU"

# Script will backup old ssh keys, generate new, and show
# you an MD5 file comparison to verify the new keys are in
# fact, different keys.
DO_COMPARISON_MD5=true
EOF
  sleep 1s
  echo -e "${GREEN}[*]${RESET} Reading SSH preferences from settings file, please wait..."
  source "${APP_SETTINGS}"
  sleep 1s
fi

# Add our root login preference to our custom settings file if not already there
grep -q '^ALLOW_ROOT_LOGIN=' "${APP_SETTINGS}" 2>/dev/null \
  || echo "ALLOW_ROOT_LOGIN=${ALLOW_ROOT_LOGIN}" >> "${APP_SETTINGS}"

[[ "$ALLOW_ROOT_LOGIN" = false ]] \
  && echo -e "${GREEN}[*] ${YELLOW}[INFO] Root SSH Login set to disabled; Change sshd_config to enable.${RESET}"
## ============================[ END :: LOADING ]]============================ ##


# ============================[  BEGIN INSTALL  ]=============================== #

echo -e "${GREEN}[*]${RESET} Disabling SSH service while we reconfigure..."
$SUDO systemctl stop ssh.service >/dev/null 2>&1
$SUDO systemctl disable ssh.service >/dev/null 2>&1

echo -e "${GREEN}[*]${RESET} Running apt-get update & installing openssh-server..."
$SUDO apt-get -qq update
$SUDO apt-get -y -qq install openssh-server openssl
# Get the currently-installed version of openssh-server
tmp=$(dpkg -s openssh-server | grep "^Version" | cut -d ":" -f3)
OPENSSH_VERSION="${tmp:0:3}"

# Move the default ssh host keys to backup folder
cd /etc/ssh
[[ ${DEBUG} -eq 1 ]] && echo -e "${ORANGE}[DEBUG]${RESET} Moving original host keys to backup directory" | tee -a "${LOG_FILE}"
[[ ! -d insecure_original_keys ]] && $SUDO mkdir insecure_original_keys
$SUDO mv ssh_host_* insecure_original_keys/


# ===============================[  SSH Server Setup  ]================================== #

# Call version check to test if installed version is at least 6.5 or newer (-o)
version_check $OPENSSH_VERSION 6.5

# TODO: Ask user if they also want to implement a password
if [[ $? == 0 ]]; then
  #echo -e "${GREEN}[*]${RESET} Newer OpenSSH Version detected (Installed Version: $OPENSSH_VERSION)"
  echo -e "${GREEN}[*]${RESET} Proceeding with new SSH key-pair format"

  #TODO: -o fails for this key type: ssh-keygen -b 4096 -t rsa1 -o -f /etc/ssh/ssh_host_key -P ""
  # We don't need this rsa1 key, it's for SSH protocol version 1
  #ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P "" >/dev/null
  $SUDO ssh-keygen -b 4096 -t rsa -o -f /etc/ssh/ssh_host_rsa_key -P "" >/dev/null
  $SUDO ssh-keygen -b 1024 -t dsa -o -f /etc/ssh/ssh_host_dsa_key -P "" >/dev/null
  $SUDO ssh-keygen -b 521 -t ecdsa -o -f /etc/ssh/ssh_host_ecdsa_key -P "" >/dev/null
  $SUDO ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -P "" >/dev/null
else
  echo -e "${YELLOW}[INFO]${RESET} OpenSSH Version is older than v6.5, Proceeding with PEM server key format"
  #$SUDO ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P "" >/dev/null
  $SUDO ssh-keygen -b 4096 -t rsa -f /etc/ssh/ssh_host_rsa_key -P "" >/dev/null
  $SUDO ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key -P "" >/dev/null
  $SUDO ssh-keygen -b 521 -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P "" >/dev/null
fi

# Change/Protect server file permissions?
# NOTE: These perms are based on how openssh-server installs them by default in /etc/ssh/
# chmod 0755 /etc/ssh
# chmod 0644 /etc/ssh/*.pub
# chmod 0644 /etc/ssh/ssh_config
# chmod 0644 /etc/ssh/sshd_config
# chmod 0600 /etc/ssh/id_rsa


if [[ "${DO_COMPARISON_MD5}" = true ]]; then
  echo -e "${GREEN}[*]${RESET} Compare the MD5 Hashes below to ensure new key is, in fact, new!"
  sleep 2s
  md5_compare /etc/ssh/insecure_original_kali_keys/ssh_host_* /etc/ssh/ssh_host_*
fi

# ===============================[  SSH CLIENT SETUP  ]================================== #
# Prepare our ssh client directory
cd ~
[[ ! -d "${HOME}/.ssh" ]] && mkdir -p "${HOME}/.ssh"

# TODO: Sure we want to do this? What about when running this on pre-existing systems?
# Wipe clean any ssh keys in root profile, leaving authorized_keys file intact
#find "${HOME}/.ssh/" -type f ! -name authorized_keys -delete 2>/dev/null

# Generate personal key pair (can also add -a 6000 to iterate the hash function for increased strength)
echo -e "${GREEN}[*]${RESET} Generating client SSH keys, saving to: ${HOME}/.ssh/"
ssh-keygen -b 4096 -t rsa -f "${HOME}/.ssh/id_rsa" -P "" >/dev/null

# Protect user files
[[ ${DEBUG} -eq 1 ]] && echo -e "${ORANGE}[DEBUG]${RESET} chmod :: Setting permissions on client keys" | tee -a "${LOG_FILE}"
chmod 0700 "${HOME}/.ssh"
chmod 0644 "${HOME}/.ssh/id_rsa.pub"
chmod 0400 "${HOME}/.ssh/id_rsa"

# Copy user's new public key to authorized_keys file
# Print both files to tmp file, backup orig
if [[ -e "${SSH_AUTH_KEYS_FILE}" ]]; then
  cp -n "${SSH_AUTH_KEYS_FILE}"{,.bkup}
  cat "${SSH_USER_DIR}/id_rsa.pub" "${SSH_AUTH_KEYS_FILE}" > "${SSH_USER_DIR}/auth.tmp"
else
  cat "${SSH_USER_DIR}/id_rsa.pub" > "${SSH_USER_DIR}/auth.tmp"
fi
# Move auth keys file to its desired location
mv "${SSH_USER_DIR}/auth.tmp" "${SSH_AUTH_KEYS_FILE}"
# NOTE: authorized_keys file should be set to 644 according to google,
# which is never wrong ever amirite?
chmod 644 "${SSH_AUTH_KEYS_FILE}"


# TODO: Create a user specifically for ssh so we aren't connecting as root
#   This would also require SSH certificates setup to be performed from this user
#   or copied to their $HOME so move this before client setup in this script.
#useradd -m sshuser
#paswd sshuser
#usermod -a -G sudo sshuser


# ===========================[ SSHD CONFIG TWEAKS ] =============================== #
#   Ref: http://man.openbsd.org/sshd_config

file="/etc/ssh/sshd_config"
[[ -e $file ]] && $SUDO cp -n $file{,.bkup}

# -==[ SSH Server IP Address
if [[ "${SSH_SERVER_ADDRESS}" ]]; then
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for ListenAddress ${RESET}" | tee -a "${LOG_FILE}"
  $SUDO sed -i "s/^#\?ListenAddress [0-9].*/ListenAddress ${SSH_SERVER_ADDRESS}/" "${file}"
fi

# -==[ IPv6 enable/disable
# TODO: Implications of disabling IPv6? Security risk here if we use iptables/filtering
# against ipv4 while leaving ipv6 completely open to attack.
#if [[ "$ENABLE_IPV6" = true ]]; then
  #[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for ListenAddress ipv6 true ${RESET}" | tee -a "${LOG_FILE}"
  #$SUDO sed -i "s/^#\?ListenAddress ::.*/ListenAddress ${SSH_SERVER_ADDRESS_IPV6}/" "${file}"
#else
# $SUDO sed -i 's/^#\?ListenAddress ::.*/#ListenAddress ::/' "${file}"
# [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for ListenAddress ipv6 false ${RESET}" | tee -a "${LOG_FILE}"
#fi

# -==[ SSH Server Port to non-default
[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for Port ${RESET}" | tee -a "${LOG_FILE}"
$SUDO sed -i "s/^#\?Port.*/Port ${SSH_SERVER_PORT}/" "${file}"

# -==[ RootLogin
# As of OpenSSH 7.0, the default for PermitRootLogin has changed from 'yes' to 'prohibit-password'
if [[ "$ALLOW_ROOT_LOGIN" = true ]]; then
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for PermitRootLogin ${RESET}" | tee -a "${LOG_FILE}"
  $SUDO sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' "${file}"
fi

# -==[ PubkeyAuthentication
if [[ "$DO_PUBKEY_AUTH" = true ]]; then
  # -- Enable Public Key Logins
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for PubkeyAuthentication in DO_PUBKEY_AUTH${RESET}" | tee -a "${LOG_FILE}"
  $SUDO sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "${file}"
  #$SUDO sed -i 's/^#\?AuthorizedKeysFile.*/AuthorizedKeysFile  %h/.ssh/authorized_keys/' "${file}"

  # -- Disable Password Logins if using Pub Key Auth - default is commented yes
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for PasswordAuthentication in DO_PUBGKEY_AUTH ${RESET}" | tee -a "${LOG_FILE}"
  $SUDO sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "${file}"
  #$SUDO sed -i -e 's|\(PasswordAuthentication\) no|\1 yes|' "${file}"
#else
# $SUDO sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/' "${file}"
fi

# -==[ PasswordAuthentication
if [[ "$DO_PW_AUTH" = true ]]; then
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for PasswordAuthentication in DO_PW_AUTH ${RESET}" | tee -a "${LOG_FILE}"
  $SUDO sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "${file}"
  # only need to modify if it's uncommented, default is no
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for PermitEmptyPasswords in DO_PW_AUTH ${RESET}" | tee -a "${LOG_FILE}"
  $SUDO sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "${file}"
fi

# --= Max Auth Tries =--
# Default: #MaxAuthTries 6
[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for MaxAuthTries ${RESET}" | tee -a "${LOG_FILE}"
$SUDO sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "${file}"

# --= MaxSessions =--
# Default: #MaxSessions 10
[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for MaxSessions ${RESET}" | tee -a "${LOG_FILE}"
$SUDO sed -i 's/^#\?MaxSessions.*/MaxSessions 2/' "${file}"

# -==[ X11 Forwarding =--
[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for X11Forwarding ${RESET}" | tee -a "${LOG_FILE}"
$SUDO sed -i 's/^#\?X11Forwarding.*/X11Forwarding yes/' "${file}"
# X11DisplayOffset (Default: 10)))
$SUDO sed -i 's/^#\?X11DisplayOffset.*/X11DisplayOffset 10/' "${file}"
$SUDO sed -i 's/^#\?X11UseLocalhost.*/X11UseLocalhost no/' "${file}"

# -==[ Change LogLevel from default "INFO" to "VERBOSE"
[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for LogLevel ${RESET}" | tee -a "${LOG_FILE}"
$SUDO sed -i 's/^#\?LogLevel.*/LogLevel VERBOSE/' "${file}"

# ==[ Add Inactivty Timeouts
# ClientAliveInterval = after x seconds, ssh server will send msg to client asking for response.
#   Default is 0, server will not send a message to the client to check.
#echo "\nClientAliveInterval 600\nClientAliveCountMax 3" >> "${file}"
#sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 600/' "${file}"

# ClientAliveCountMax = total no. of checkalive msgs sent by ssh server w/o getting response from client.
#   Default: 3
#$SUDO sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 3/' "${file}"


# ==[ Ciphers =--
# -- Good ciphers to use link: https://www.ssh.com/ssh/sshd_config/
[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] grep :: in sshd_config for Ciphers ${RESET}" | tee -a "${LOG_FILE}"
grep -q '^Ciphers ' "${file}" 2>/dev/null \
  || $SUDO sh -c "echo Ciphers aes256-ctr,aes192-ctr,aes128-ctr >> ${file}"

grep -q '^HostKeyAlgorithms ' "${file}" 2>/dev/null \
  || $SUDO sh -c "echo HostKeyAlgorithms ecdsa-sha2-nistp521,ecdsa-sha2-nistp384,ecdsa-sha2-nistp256,ssh-rsa,ssh-dss >> ${file}"

grep -q '^KexAlgorithms ' "${file}" 2>/dev/null \
  || $SUDO sh -c "echo KexAlgorithms ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha256 >> ${file}"

grep -q '^MACs ' "${file}" 2>/dev/null \
  || $SUDO sh -c "echo MACs hmac-sha2-512,hmac-sha2-256 >> ${file}"

# -==[ Compression =--
# Only enable compression after authentication - default is delayed
[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] grep :: in sshd_config for Compression delayed ${RESET}" | tee -a "${LOG_FILE}"
grep -q '^#\?Compression delayed' "${file}" 2>/dev/null \
  || $SUDO sh -c "echo Compression delayed >> ${file}"


# ==[ Add Whitelist and Blacklist of Users
#grep -q '^AllowUsers ' "${file}" 2>/dev/null || echo "\nAllowUsers newuser newuser2" >> "${file}"
#grep -q '^DenyUsers ' "${file}" 2>/dev/null || echo "\nDenyUsers root apache cvs" >> "${file}"
#grep -q '^AllowGroups ' "${file}" 2>/dev/null || echo "\nAllowGroups sysadmin" >> "${file}"
#grep -q '^DenyGroups ' "${file}" 2>/dev/null || echo "\nDenyGroups root" >> "${file}"
#grep -q '^PrintLastLog ' "${file}" 2>/dev/null || echo "\nPrintLastLog yes" >> "${file}"

# You could disable TcpForwarding by default, but allow it for certain users
#AllowTcpForwarding no
#Match User foobar
#AllowTcpForwarding yes

## ========================================================================== ##


# Configure the MOTD banner message remote users see when they first connect (before login)
# Default: #Banner /etc/issue.net
# We configure it this way to suppress the default Banner sending our server /etc/issue
[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] sed :: in sshd_config for Banner, Motd ${RESET}" | tee -a "${LOG_FILE}"
$SUDO sed -i 's/^#\?Banner .*/Banner none/' "${file}"
$SUDO sed -i 's/^#\?PrintMotd .*/PrintMotd yes/' "${file}"
# Create ASCII Art: http://patorjk.com/software/taag/
if [[ -f "${APP_BASE}/../../includes/motd" ]]; then
  echo -e "${GREEEN}[*]${RESET} Found 'motd' file in penprep/config/motd, using that!"
  $SUDO cp "${APP_BASE}/../../includes/motd" /etc/motd
else
  file=/tmp/motd
  cat <<EOF > "${file}"
###########################++++++++++###########################
#             Welcome to the Secure Shell Server               #
#               All Connections are Monitored                  #
#           Do Not Probe for Vulns -- Play Nice ;)             #
#                                                              #
#      DISCONNECT NOW IF YOU ARE NOT AN AUTHORIZED USER        #
###########################++++++++++###########################
EOF
fi
$SUDO mv "${file}" /etc/motd


# -==[ OpenSSH Client Hardened Template ]==-
file=/tmp/openssh_client.template
cat <<EOF > "${file}"
### OpenSSH Hardened Client Template
# https://www.ssh.com/ssh/sshd_config
HashKnownHosts yes
Host github.com
    MACs hmac-sha2-512,hmac-sha2-256

#Github needs diffie-hellman-group-exchange-sha1 some of the time but not always.
#   KexAlgorithms ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha256

Host *
  ConnectTimeout 30
  KexAlgorithms ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha256
  MACs hmac-sha2-512,hmac-sha2-256
  Ciphers aes256-ctr,aes192-ctr,aes128-ctr
  ServerAliveInterval 10
  ControlMaster auto
  ControlPersist yes
  ControlPath ~/.ssh/socket-%r@%h:%p
  UseRoaming no
EOF
$SUDO mv "${file}" /etc/ssh/openssh_client.template


# ============[ IPTABLES ]============== #
#[[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] iptables :: Adding fw rules ${RESET}"
#iptables -A INPUT -p tcp --dport $SSH_SERVER_PORT -j ACCEPT


# ==========================[ GEOIP RESTRICTIONS INTEGRATION ]============================== #
# Credit to: http://www.axllent.org/docs/view/ssh-geoip/
# Valid DNS Servers: http://public-dns.info/nameservers.txt

function restrict_login_geoip() {
  #
  #   This function will setup the geoip database, download an updated .dat
  #   and proceed to setup functionality that will block SSH access from
  #   sources that are not in the list of approved countries
  #
  echo -e "${GREEN}[*] ${RESET}Setting up geoip integration for country-based restrictions..."
  $SUDO apt-get -y install geoip-bin geoip-database
  # Test it out
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Performing a test lookup with command 'geoiplookup 8.8.8.8' now...${RESET}" | tee -a "${LOG_FILE}"
  [[ "$DEBUG" = true ]] && geoiplookup 8.8.8.8
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Did it work? Press ENTER to continue...${RESET}" | tee -a "${LOG_FILE}"
  [[ "$DEBUG" = true ]] && read

  # Create script that will check IPs and return True or False
  [[ ! -d "/usr/local/bin" ]] && $SUDO mkdir -vp "/usr/local/bin" >/dev/null 2>&1

  file=/usr/local/bin/sshfilter.sh
  if [[ ! -e "${file}" ]]; then
    $SUDO touch "${file}"
    $SUDO chmod -f 0666 "${file}"
    cat <<EOF > "${file}"
#!/bin/bash

# Credit to: http://www.axllent.org/docs/view/ssh-geoip/
# UPPERCASE space-separated country codes to ACCEPT
ALLOW_COUNTRIES="${ALLOW_COUNTRIES}"

if [[ \$# -ne 1 ]]; then
  echo "Usage: \`basename \$0\` <ip>" 1>&2
  # Return 0 (True) in case of config issue
  exit 0
fi

COUNTRY=\`/usr/bin/geoiplookup \$1 | awk -F ": " '{ print \$2 }' | awk -F "," '{ print \$1 }' | head -n 1\`

# Not Found can occur if the IP address is RFC1918
[[ \$COUNTRY = "IP Address not found" || \$ALLOW_COUNTRIES =~ \$COUNTRY ]] && RESPONSE="ALLOW" || RESPONSE="DENY"

if [[ \$RESPONSE = "ALLOW" ]]; then
  exit 0
else
  logger "\$RESPONSE sshd connection from \$1 (\$COUNTRY)"
  exit 1
fi
EOF

    # Set the default to deny all
    grep -q "sshd: ALL" "${file}" 2>/dev/null \
      || $SUDO sh -c "echo sshd: ALL >> /etc/hosts.deny"
    # Set the filter script to determine which hosts are allowed
    grep -q "sshd: ALL: aclexec .*" "${file}" 2>/dev/null \
      || $SUDO sh -c "echo sshd: ALL: aclexec /usr/local/bin/sshfilter.sh %a >> /etc/hosts.allow"
  fi
  $SUDO chmod -f 0555 "${file}"
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] binary :: filter exe created at ${file} ${RESET}" | tee -a "${LOG_FILE}"

  # Test it out
  # TODO: Send these deny entries to a different log for processing?
  [[ "$DEBUG" = true ]] \
    && echo -e "${ORANGE}[DEBUG] Testing sshfilter.ssh - a DENY entry should output below (saved to: /var/log/messages)${RESET}" | tee -a "${LOG_FILE}"
  [[ "$DEBUG" = true ]] && /usr/local/bin/sshfilter.sh "175.198.198.78"
  [[ "$DEBUG" = true ]] && $SUDO tail /var/log/messages | grep ssh


  file=/usr/local/bin/geoip-updater.sh
  if [[ ! -e "${file}" ]]; then
    $SUDO touch "${file}"
    $SUDO chmod -f 0666 "${file}"
    cat <<EOF > "${file}"
#!/bin/bash

cd /tmp
wget -q https://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
if [[ -f GeoIP.dat.gz ]]; then
    gzip -d GeoIP.dat.gz
    rm -f /usr/share/GeoIP/GeoIP.dat
    mv -f GeoIP.dat /usr/share/GeoIP/GeoIP.dat
else
    echo -e "[ERROR] The GeoIP library could not be downloaded and updated"
fi
EOF
  fi
  $SUDO chmod -f 0555 "${file}"
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] binary :: geoip exe created at ${file} ${RESET}" | tee -a "${LOG_FILE}"

  # Setup a monthly cron job to keep your Geo-IP Database updated - 1st of month at Noon.
  # TODO: This method doesn't work for 'root' user
  #(crontab -l ; echo "00 12 1 * * ${file}") | crontab
  # Trying this version - crontab -l will exit 1 if file is empty
  crontab -l >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    crontab -l | { cat; echo "10 23 3 * 0 /usr/local/bin/geoip-updater.sh"; } | crontab -
  else
    echo "10 23 3 * 0 /usr/local/bin/geoip-updater.sh" | crontab -
  fi
}
[[ "$DO_GEOIP" = true ]] && restrict_login_geoip


# ===[ Restart SSH / Enable Autostart ]=== #
#service ssh restart
#update-rc.d -f ssh enable
$SUDO systemctl start ssh.service >/dev/null 2>&1
[[ "$SSH_AUTOSTART" = true ]] && $SUDO systemctl enable ssh.service >/dev/null 2>&1

echo -e "\n${GREEN}=================================================================${RESET}"
echo -e "  SSH SERVER IP:\t${SSH_SERVER_ADDRESS}"
echo -e "  SSH Port:\t${SSH_SERVER_PORT}"
echo -e "  Autostart:\t$SSH_AUTOSTART"
echo -e "  Root Login:\t$ALLOW_ROOT_LOGIN"
echo -e "  Pubkey Auth:\t$DO_PUBKEY_AUTH"
echo -e "  PW Auth:\t$DO_PW_AUTH"
echo -e "\n  Client Template:\t/etc/ssh/openssh_client.template"
echo -e "\n  Outputting listening ports below. Verify SSH service is running:\n"
# Display established ssh connections
ss -lutpn
#ss -o state established '(dport=:ssh or sport=:ssh)'
echo -e "\n${GREEN}-----------------------------------------------------------------${RESET}"
echo -e ""
echo -e " Next Steps:"
echo -e "   1. Copy off the client template file"
echo -e "   2. Copy off the newly-generated client ssh keypair, if using them"
echo -e "      from file paths: ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub"
echo -e "   3. If using an existing key, use ${ORANGE}\$ ssh-copy-id -i <mykey.pub> user@ip${RESET}"
echo -e "      to add your key to the ~/.ssh/authorized_keys file "
echo -e "      or manually copy it in via:"
echo -e "      ${ORANGE}\$ echo '<mykey.pub>' >> ~/.ssh/authorized_keys${RESET}"
echo -e "\n\n"
echo -e " Monitoring Tip:"
echo -e "    1. Check for any Invalid User Login Attempts"
echo -e "       ${ORANGE}\$ cat /var/log/auth.log | grep 'Invalid user' | cut -d ' ' -f 1-3,6-11 | uniq | sort${RESET}"
echo -e "\n${GREEN}=================================================================${RESET}\n"

function finish {
    # Any script-termination routines go here, but function cannot be empty
  echo -e "${GREEN}[*] ${RESET}Setup is now complete. Verify settings and that SSH server is functioning as desired. Goodbye!"
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}" | tee -a "${LOG_FILE}"
    [[ "$DEBUG" = true ]] && echo -e "\n${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait...\n\n" | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT

### ================================[ SSH NOTES ]=================================== ###
#
# ------------------------------------
#   Next Steps: Access SSH Server
# ------------------------------------
# After installing your ssh server, establish your access:
#
#   Method 1: Copy off newly-generated rsa key and use it to access this server
#     (remote server) copy ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub
#     Now, when you auth to this server and provide this key, it'll work because
#     it is already in the server's "authorized_keys" file.
#       $ ssh -i <private_key_file> user1@10.0.0.243
#
#   Method 2: Use pre-existing key for this new SSH server
#     # If you enabled publickey, and also left pw auth enabled, you have option to use an existing
#     # Connect to remote server using server's username and pw from your local system you have key.
#       $ ssh-copy-id -i <path_to_your_ssh_key> <user>@<target_ip> -p <port>
#       $ ssh-copy-id -i $HOME/.ssh/mykey.pub user1@10.0.0.243 -p 10022
#
#       # This will prompt you for that user's pw. Then, it will automatically copy your pub key to
#     # the server's "authorized_keys" file. You can now go into settings and disable password auth.
#     # NOTE: do '-n' if you want to do a dry run before actually installing your key on the server.
#
#
#   Method 3: Manually Copy Your SSH key to Server
#     # This is for if you can't use ssh-copy-id, and is common sense, but here for completeness of options.
#     # Either do method 1 and use the newly-generated key, or continue reading if you still want to use
#     # an existing key you already have on local system.
#       open/cat your existing public key and copy it.
#       paste it to "authorized_keys" file on remote server
#         $ echo '<pub_key_string>' >> ~/.ssh/authorized_keys
#
#     # Now, with your public key in the auth file, you can use private key from local to connect.
#         $ ssh -i <private_key_file> user1@10.0.0.243
#
#
#
# Additional Reading:
# * https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys
#
# -------------------------------
# Troubleshoot SSH Server
# -------------------------------
# if setup fails and service will not start
#   sudo /usr/sbin/sshd -d -p 22    # And you will see why it will not start
#
#
#
#
# -------------------------------
# Key generating
# -------------------------------
# ssh-keygen
#   -q                      Quiet mode
#   -b #                    No. of bits; RSA keys - min 1024, default is 2048
#                           DSA keys must be exactly 1024, as specified by FIPS 186-2
#                           ECDSA keys, elliptic curve sizes of 256, 384, or 521 bits
#                           Ed25519 uses a fixed bits length and -b will be ignored.
#   -f <output_keyfile>
#   -t                      [ dsa | ecdsa | ed25519 | rsa | rsa1 ]
#   -o                      SSH-Keygen will use the new OpenSSH format rather than PEM.
#   -P "<pw>"               Password for the key, -P "" makes it blank


# Generate default, unattended host keys for use in scripts by administrators
#   ssh-keygen -A

# Hash a "known_hosts" file. This replaces all hosts with hashed representations,
# orig file becomes "known_hosts.old" so be sure to remove it afterwards for security.
# Also, it will not hash already-hashed entries, so it's safe to run this over and over.
#   ssh-keygen -H -f <known_hosts_file>

# Generate with user information based on environment variables
#ssh-keygen -C "$(whoami)@$(hostname)-$(date -I)"

# Check for any Invalid User Login Attempts
#cat /var/log/auth.log | grep "Invalid user" | cut -d " " -f 1-3,6-11 | uniq | sort

# ------------------------------
# Addtl Settings Not Used
# ------------------------------
# -==[ SSH Host Keys
# All are same, but put a '#' in front of: HostKey /etc/ssh/ssh_host_ed25519_key
#$SUDO sed -i 's/^HostKey /etc/ssh/ssh_host_ed25519_key/#HostKey /etc/ssh/ssh_host_ed25519_key/' "${file}"

# -==[ ServerKeyBits (Default: 1024)
# This may have been removed in newest version
#$SUDO sed -i -e 's/\(ServerKeyBits\) 1024/\1 2048/' "${file}"

# -==[ LoginGraceTime (Default: 2m)
#   -- How long user has to authenticate after connecting before being kicked.
#$SUDO sed -i 's/^LoginGraceTime.*/LoginGraceTime 1m/' "${file}"
### ================================[  ]=================================== ###

### ================================[ Unused Functions ]=================================== ###
function setup_google_otp() {
    #   This goes beyond normal settings and brings in 2-FA
    #   Once configured, SSH access will require a private key and a Google OTP token.
    #
    $SUDO apt-get install libpam-google-authenticator


    # Configure a secret key for user
    google-authenticator


    # Edit the sshd_config fileas such:
    #ChallengeResponseAuthentication yes
    #PasswordAuthentication no
    #AuthenticationMethods publickey,keyboard-interactive
    #UsePAM yes
    #PubkeyAuthentication yes


    # Edit the PAM configuration to use Google Authentication
    # edit /etc/pam.d/sshd
    #replace this: @include common-auth
    #with this: auth required pam_google_authenticator.so
}
#setup_google_otp


function setup_ssh_over_tor() {
    #
    #   Create a hidden tor service and route SSH over it.
    #
    #
    #

    # Ensure that tor is setup and running

    # Bind only to localhost
    #ListenAddress 127.0.0.1:22

    # Create hidden service
    file=/etc/tor/torrc; [[ -e $file ]] && cp -n $file{,.bkup}
    $SUDO sed -i 's|^#HiddenServiceDir /var/lib/tor/other_hidden_service/|HiddenServiceDir /var/lib/tor/ssh|' "${file}"
    $SUDO sed #HiddenServicePort 22 127.0.0.1:22
    $SUDO sed -i 's|^#HiddenServicePort 22 127.0.0.1:22|HiddenServicePort 22 127.0.0.1:22|' "${file}"
    # Grab our TOR hostname to use from /var/lib/tor/ssh/hostname

    # Edit ssh_config (clients)
    #Host *.onion
        #ProxyCommand socat - SOCKS4A:localhost:%h:%p,socksport=9050

    # Might want to also be sure that 'socat' exists on the current system
}
#setup_ssh_over_tor
