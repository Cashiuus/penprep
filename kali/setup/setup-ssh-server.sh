#!/bin/bash
## =============================================================================
# Filename: setup-ssh-server.sh
#
# Author:   Cashiuus
# Created:  01-Dec-2015 - (Revised: 11-Dec-2016)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
#
# Purpose:  Setup SSH Server on Kali Linux to non-default port
#           and also replacing original keys with new ones
#
# Thanks to:    https://www.lisenet.com/2013/openssh-server-installation-and-configuration-on-debian/
#               https://wiki.archlinux.org/index.php/SSH_keys
#               https://help.ubuntu.com/community/SSH/OpenSSH/Configuring
#
# NOTES:    - As of July 10, 2015, GNOME keyring cannot handle ECDSA and Ed25519 keys.
#             You must use another SSH agents or stick to RSA keys.
#           - Windows SSH PuTTY does not support ECDSA as of March, 2016.
## =============================================================================
__version__="1.2"
__author__='Cashiuus'
## ========[ TEXT COLORS ]=============== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
PURPLE="\033[01;35m"   # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS / DEFAULTS ]================ ##
SCRIPT_DIR=$(readlink -f $0)
APP_BASE=$(dirname ${SCRIPT_DIR})
DEBUG=true
LOG_FILE="${APP_BASE}/debug.log"
LINES=$(tput lines)
COLS=$(tput cols)

APP_SETTINGS="${HOME}/.config/kali-builder/settings.conf"
# ===============================[ Check Permissions ]============================== #
ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
## Exit if the script was not launched by root or through sudo
if [[ ${EUID} -ne 0 ]]; then
    echo "The script needs to run as sudo/root" && exit 1
fi

## ================================================================================ ##
# ============================[ Preparations / Settings ]=========================== #
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


function init_settings_ssh() {
    # if this line is not in the settings file, generate defaults
    if [[ ! ${SSH_SERVER_ADDRESS} ]]; then
        echo -e -n "${GREEN}[+] ${RESET}"
        read -r -e -p "Enter SSH Server IP (If unsure, just press enter): " -i "0.0.0.0" SSH_SERVER_ADDRESS
    fi

    if [[ ! ${SSH_SERVER_PORT} ]]; then
        echo -e -n "${GREEN}[+] ${RESET}"
        read -r -e -p "Enter SSH Server Port (Default: 22): " -i "22" SSH_SERVER_PORT
    fi

    [[ ${DEBUG} -eq 1 ]] && echo -e "${ORANGE}[DEBUG] Generating initial SSH defaults into settings file${RESET}"
    cat <<EOF >> "${APP_SETTINGS}"
# SSH Server Custom Configuration
SSH_SERVER_ADDRESS=${SSH_SERVER_ADDRESS}
SSH_SERVER_PORT=${SSH_SERVER_PORT}

SSH_AUTOSTART=true
ALLOW_ROOT_LOGIN=false
DO_PW_AUTH=true
DO_PUBKEY_AUTH=true

# Geoip based whitelist of source countries
# allowed to access this system's SSH service
DO_GEOIP=true
ALLOW_COUNTRIES="US AU"

# This just means script will backup old ssh keys, generate new, and show
# you an MD5 file comparison to verify the new keys are in fact, different keys.
DO_COMPARISON_MD5=true
EOF
    sleep 1s
    source "${APP_SETTINGS}"
    echo -e "${GREEN}[*] ${RESET}Reading SSH preferences from settings file, please wait..."
}


# Initialize configuration directory and settings file
init_settings
[[ ! ${SSH_SERVER_ADDRESS} ]] && init_settings_ssh


# Add our root login preference to our custom settings file if not already there
grep -q '^ALLOW_ROOT_LOGIN=' "${APP_SETTINGS}" 2>/dev/null \
    || echo "ALLOW_ROOT_LOGIN=${ALLOW_ROOT_LOGIN}" >> "${APP_SETTINGS}"

[[ "$ALLOW_ROOT_LOGIN" = false ]] \
    && echo -e "${YELLOW}[INFO] Root SSH Login set to disabled; Change sshd_config to enable.${RESET}"

# ===============================[  BEGIN  ]================================== #

echo -e "${GREEN}[*]${RESET} Running apt-get update & installing openssh-server..."
apt-get -qq update
apt-get -y -qq install openssh-server openssl

echo -e "${GREEN}[*]${RESET} Disabling SSH service while we reconfigure..."
update-rc.d -f ssh remove
update-rc.d -f ssh defaults

# Move the default Kali keys to backup folder
cd /etc/ssh
if [[ ! -d insecure_original_kali_keys ]]; then
    mkdir insecure_original_kali_keys
    mv ssh_host_* insecure_original_kali_keys/
fi

# Wipe clean any ssh keys in root profile, leaving authorized_keys file intact
[[ ! -d "${HOME}/.ssh" ]] && mkdir -p "${HOME}/.ssh"

# TODO: Sure we want to do this? What about when running this on pre-existing systems?
#find "${HOME}/.ssh/" -type f ! -name authorized_keys -delete 2>/dev/null

# Get the currently-installed version of openssh-server
tmp=$(dpkg -s openssh-server | grep "^Version" | cut -d ":" -f3)
openssh_version="${tmp:0:3}"

function version () {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

function version_check () {
    # Check the installed version of OpenSSH and return
    if [ $(version $1) -ge $(version $2) ]; then
        echo "$1 is newer than $2" >/dev/null
        return 0
    elif [ $(version $1) -lt $(version $2) ]; then
        echo "$1 is older than $2" >/dev/null
        return 1
    fi
}

# Call version check to test if installed version is at least 6.5 or newer (-o)
# TODO: Ask user if they also want to implement a password
version_check $ver 6.5
if [ $? == 0 ]; then
    echo -e "${GREEN}[*] ${RESET}Newer OpenSSH Version detected, proceeding with new key format"

    #TODO: -o fails for this key type: ssh-keygen -b 4096 -t rsa1 -o -f /etc/ssh/ssh_host_key -P ""
    # We don't need this rsa1 key, it's for SSH protocol version 1
    #ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P "" >/dev/null
    ssh-keygen -b 4096 -t rsa -o -f /etc/ssh/ssh_host_rsa_key -P "" >/dev/null
    ssh-keygen -b 1024 -t dsa -o -f /etc/ssh/ssh_host_dsa_key -P "" >/dev/null
    ssh-keygen -b 521 -t ecdsa -o -f /etc/ssh/ssh_host_ecdsa_key -P "" >/dev/null
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -P "" >/dev/null
else
    echo -e "[-] OpenSSH Version is older than v6.5, Proceeding with PEM key format"
    #ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P "" >/dev/null
    ssh-keygen -b 4096 -t rsa -f /etc/ssh/ssh_host_rsa_key -P "" >/dev/null
    ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key -P "" >/dev/null
    ssh-keygen -b 521 -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P "" >/dev/null
fi

# Change/Protect server file permissions?
# chmod 0755 /etc/ssh
# chmod 0644 /etc/ssh/*.pub
# chmod 0644 /etc/ssh/ssh_config
# chmod 0644 /etc/ssh/sshd_config
# chmod 0600 /etc/ssh/id_rsa based on how openssh-server installs them by default in /etc/ssh/

# Generate personal key pair
ssh-keygen -b 4096 -t rsa -f "${HOME}/.ssh/id_rsa" -P "" >/dev/null

# Protect files
chmod 0700 "${HOME}/.ssh"
chmod 0644 "${HOME}/.ssh/id_rsa.pub"
chmod 0400 "${HOME}/.ssh/id_rsa"


function md5_compare() {
    # Compare MD5 to ensure new key is different from original
    echo -e "\n${GREEN}[*] ${RESET}Compare the MD5 Hashes below to ensure new key is, in fact, new!"
    echo -e "\t-- ${RED}OLD KEYS${RESET} --"
    openssl md5 /etc/ssh/insecure_original_kali_keys/ssh_host_*
    echo -e "\n\t-- ${GREEN}NEW KEYS${RESET} --"
    openssl md5 /etc/ssh/ssh_host_*
    sleep 10
}
[[ "${DO_COMPARISON_MD5}" = true ]] && md5_compare


# Copy Public key to auth file; Private key goes to client
# TODO: May need to insert this at the top, and append existing keys below it
# to avoid old key being read first if this key is replacing an existing entry
file="${HOME}/.ssh/authorized_keys"
cat "${HOME}/.ssh/id_rsa.pub" >> "${file}"

#{ cat "${file}"; cat "${HOME}/.ssh/id_rsa.pub" } > "${file}"


# NOTE: authorized_keys file should be set to 644 according to google, which is never wrong ever amirite?
chmod 644 "${file}"

# Configure the MOTD banner message remote users see, 2 versions below
# Create ASCII Art: http://patorjk.com/software/taag/
if [[ -f "${APP_BASE}/../../config/motd" ]]; then
    echo -e "[*] Found 'motd' file in penprep/config/motd, using that!"
    cp "${APP_BASE}/../../config/motd" /etc/motd
else
    cat <<EOF > /etc/motd
###########################++++++++++###########################
#             Welcome to the Secure Shell Server               #
#               All Connections are Monitored                  #
#           Do Not Probe for Vulns -- Play nice ;)             #
#                                                              #
#      DISCONNECT NOW IF YOU ARE NOT AN AUTHORIZED USER        #
###########################++++++++++###########################
EOF
fi

# TODO: Create a user specifically for ssh so we aren't connecting as root
#   This would also require SSH certificates setup to be performed from this user
#   or copied to their $HOME
#apt-get -y install sudo
#useradd -m sshuser
#paswd sshuser
#usermod -a -G sudo sshuser



# ===========================[ SSHD CONFIG TWEAKS ] =============================== #
#   Ref: http://man.openbsd.org/sshd_config

file=/etc/ssh/sshd_config; [[ -e $file ]] && cp -n $file{,.bkup}

# ==[ Server IP Address
if [[ "${SSH_SERVER_ADDRESS}" ]]; then
    sed -i "s/^#\?ListenAddress .*/ListenAddress ${SSH_SERVER_ADDRESS}/" "${file}"
fi
# ==[ SSH Server Port to non-default
sed -i "s/^#\?Port.*/Port ${SSH_SERVER_PORT}/" "${file}"

# Enable RootLogin
# As of OpenSSH 7.0, the default for PermitRootLogin has changed from 'yes' to 'prohibit-password'
if [[ "$ALLOW_ROOT_LOGIN" = true ]]; then
    sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/g' "${file}"
elif [[ "$ALLOW_ROOT_LOGIN" = false ]]; then
    sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/g' "${file}"
fi

if [[ "$DO_PUBKEY_AUTH" = true ]]; then
    # -- Enable Public Key Logins
    sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "${file}"
    sed -i 's|^#\?AuthorizedKeysFile.*|AuthorizedKeysFile  %h/.ssh/authorized_keys|' "${file}"

    # -- Disable Password Logins if using Pub Key Auth - default is commented yes
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "${file}"
    #sed -i -e 's|\(PasswordAuthentication\) no|\1 yes|' "${file}"
else
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/' "${file}"
fi

if [[ "$DO_PW_AUTH" = true ]]; then
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "${file}"
    # only need to modify if it's uncommented, default is no
    sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "${file}"
fi


# Host Keys
# -- All are same, but put a '#' in front of: HostKey /etc/ssh/ssh_host_ed25519_key
#sed -i 's|^HostKey /etc/ssh/ssh_host_ed25519_key|#HostKey /etc/ssh/ssh_host_ed25519_key|' "${file}"

# -- Server Key Bits (Default: 1024)
sed -i -e 's|\(ServerKeyBits\) 1024|\1 2048|' "${file}"

# -- Login Grace Time (Default: 120)
sed -i 's/^LoginGraceTime.*/LoginGraceTime 30/' "${file}"


# ==[ X11 Forwarding - not changing this from its default of 10 for now
#sed -i 's/X11Forwarding.*/X11Forwarding no/' >> "${file}"
#sed -i 's/^X11DisplayOffset.*/X11DisplayOffset 15/' "${file}"


# Find "Banner" in file and change to motd if not already
# Orig: #Banner /etc/issue.net
# *NOTE: When using '/' for paths in sed, use a different delimiter, such as # or |
# *NOTE: You can specify 'none' here to have it not print anything on login - Banner "none"
sed -i 's|^#\?Banner /etc/issue.*|Banner /etc/motd|' "${file}"

# ==[ Ciphers - https://cipherli.st/
# -- https://stribika.github.io/2015/01/04/secure-secure-shell.html
grep -q '^KexAlgorithms ' "${file}" 2>/dev/null \
    || echo "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" >> "${file}"

grep -q '^Ciphers ' "${file}" 2>/dev/null \
    || echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" >> "${file}"

grep -q '^MACs ' "${file}" 2>/dev/null \
    || echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com" >> "${file}"


# ==[ Add Inactivty Timeouts
# ClientAliveInterval = after x seconds, ssh server will send msg to client asking for response.
#   Default is 0, server will not send a message to the client to check.
#echo "\nClientAliveInterval 600\nClientAliveCountMax 3" >> "${file}"
#sed -i 's|^ClientAliveInterval.*|ClientAliveInterval 600|' "${file}"

# ClientAliveCountMax = total no. of checkalive msgs sent by ssh server w/o getting response from client.
#   Default is 3
sed -i 's|^ClientAliveCountMax.*|ClientAliveCountMax 3|' "${file}"


# ==[ Add Whitelist and Blacklist of Users
#grep -q '^AllowUsers ' "${file}" 2>/dev/null || echo "\nAllowUsers newuser newuser2" >> "${file}"
#grep -q '^DenyUsers ' "${file}" 2>/dev/null || echo "\nDenyUsers root apache cvs" >> "${file}"
#grep -q '^AllowGroups ' "${file}" 2>/dev/null || echo "\nAllowGroups sysadmin" >> "${file}"
#grep -q '^DenyGroups ' "${file}" 2>/dev/null || echo "\nDenyGroups root" >> "${file}"
#grep -q '^PrintLastLog ' "${file}" 2>/dev/null || echo "\nPrintLastLog yes" >> "${file}"
## ========================================================================== ##




# -==[ OpenSSH Client Hardened Template ]==-
file=/etc/ssh/openssh_client.template
cat <<EOF > "${file}"
### OpenSSH Hardened Client Template
# https://cipherli.st/
# https://stribika.github.io/2015/01/04/secure-secure-shell.html
HashKnownHosts yes
Host github.com
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-128-etm@openssh.com,hmac-sha2-512
Host *
  ConnectTimeout 30
  KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
  MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com
  Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
  ServerAliveInterval 10
  ControlMaster auto
  ControlPersist yes
  ControlPath ~/.ssh/socket-%r@%h:%p
EOF


# ============[ IPTABLES ]============== #
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
    apt-get -y install geoip-bin geoip-database
    # Test it out
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Performing a test lookup with command 'geoiplookup 8.8.8.8' now...${RESET}"
    [[ "$DEBUG" = true ]] && geoiplookup 8.8.8.8
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Did it work? Press any key to continue...${RESET}"
    [[ "$DEBUG" = true ]] && read

    # Create script that will check IPs and return True or False
    [[ ! -d "/usr/local/bin" ]] && mkdir -vp "/usr/local/bin" >/dev/null 2>&1
    file="/usr/local/bin/sshfilter.sh"
    cat <<EOF > "${file}"
#!/bin/bash

# Credit to: http://www.axllent.org/docs/view/ssh-geoip/
# UPPERCASE space-separated country codes to ACCEPT
ALLOW_COUNTRIES=\"${ALLOW_COUNTRIES}\"

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
    chmod 775 "${file}"

    # Set the default to deny all
    grep -q "sshd: ALL" "${file}" 2>/dev/null || echo "sshd: ALL" >> /etc/hosts.deny
    # Set the filter script to determine which hosts are allowed
    grep -q "sshd: ALL: aclexec .*" "${file}" 2>/dev/null \
        || echo "sshd: ALL: aclexec /usr/local/bin/sshfilter.sh %a" >> /etc/hosts.allow

    # Test it out
    [[ "$DEBUG" = true ]] \
        && echo -e "${ORANGE}[DEBUG] Testing sshfilter.ssh - DENY's should show in /var/log/messages${RESET}"
    [[ "$DEBUG" = true ]] && /usr/local/bin/sshfilter.sh "175.198.198.78"

    file=/usr/local/bin/geoip-updater.sh
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
    chmod +x "${file}"
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
systemctl start ssh >/dev/null 2>&1
[[ "$SSH_AUTOSTART" = true ]] && systemctl enable ssh >/dev/null 2>&1


echo -e "\n${GREEN}============================================================${RESET}"
echo -e "\tSSH SERVER IP:\t${SSH_SERVER_ADDRESS}"
echo -e "\tSSH Port:\t${SSH_SERVER_PORT}"
echo -e "\tAutostart:\t$SSH_AUTOSTART"
echo -e "\tRoot Login:\t$ALLOW_ROOT_LOGIN"
echo -e "\tPubkey Auth:\t$DO_PUBKEY_AUTH"
echo -e "\tPW Auth:\t$DO_PW_AUTH"
echo -e "${GREEN}============================================================${RESET}"


function finish {
    # Any script-termination routines go here, but function cannot be empty
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT

# ================================[ SSH NOTES ]===================================
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

# Connect to SSH Server
#ssh -24x -i "${HOME}/.ssh/my_key" root@$SSH_SERVER_ADDRESS -p $SSH_SERVER_PORT

# Check for any Invalid User Login Attempts
#cat /var/log/auth.log | grep "Invalid user" | cut -d " " -f 1-3,6-11 | uniq | sort
