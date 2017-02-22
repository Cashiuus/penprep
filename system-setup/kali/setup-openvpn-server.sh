#!/usr/bin/env bash
## =======================================================================================
# File:     setup-openvpn-server.sh
#
# Author:   Cashiuus
# Created:  12-NOV-2015   -   (Revised: 15-Jan-2017)
#
#-[ Usage ]-------------------------------------------------------------------------------
#
#   ./setup-openvpn-server.sh
#
# Purpose:  Setup OpenVPN Server and prep all certs needed.
#           Uses the newer easy-rsa3 version to generate
#           the certificate package.
#           Lastly, we merge all client certs into a
#           singular embedded client config file.
#-[ Notes ]-------------------------------------------------------------------------------
#
#   TODO:
#       - Update entire script for sudo handling for other platforms (e.g. Debian 8)
#
#-[ References ]----------------------------------------------------------------
#   - OpenVPN Hardening Cheat Sheet: http://darizotas.blogspot.com/2014/04/openvpn-hardening-cheat-sheet.html
#
#-[ Copyright ]-----------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =============================================================================
__version__="1.21"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
PURPLE="\033[01;35m"   # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS / DEFAULTS ]================ ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
DEBUG=false
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
LOG_FILE="${APP_BASE}/debug.log"

#======[ ROOT PRE-CHECK ]=======#
function check_root() {
    if [[ $EUID -ne 0 ]];then
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            # $SUDO - run commands with this prefix now to account for either scenario.
        else
            echo -e "${RED}[ERROR] Please install sudo or run this as root. Exiting.${RESET}"
            exit 1
        fi
    fi
}
check_root
# ============================[ Preparations / Settings ]=========================== #
function init_settings() {
    ###
    # Initialize standard configuration or prepare if first-run.
    #
    ###
    if [[ ! -f "${APP_SETTINGS}" ]]; then
        mkdir -p $(dirname ${APP_SETTINGS})
        echo -e "${GREEN}[*] ${RESET}Creating configuration directory"
        echo -e "${GREEN}[*] ${RESET}Creating initial settings file"
        cat <<EOF > "${APP_SETTINGS}"
### KALI PERSONAL BUILD SETTINGS

EOF
    fi

    echo -e "[*] Reading from settings file, please wait..."
    source "${APP_SETTINGS}"
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] App Settings Path: ${APP_SETTINGS}${RESET}"
}


function init_settings_openvpn() {
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Generating initial VPN defaults into settings file${RESET}"
    cat <<EOF >> "${APP_SETTINGS}"
# VPN Custom Configuration
VPN_PREP_DIR="\${HOME}/vpn-setup"

VPN_SERVER=''
VPN_PORT='1194'
VPN_PROTOCOL='udp'
VPN_SUBNET="10.9.8.0"
# An array of clients, you may add more below to create additional openvpn clients' packages.
CLIENT_NAME[0]="client1"
EOF

    source "${APP_SETTINGS}"
}


# Initialize configuration directory and settings file
init_settings

# If our VPN server variable is not defined, assert this is a first-run & generate defaults
[[ ! ${VPN_SERVER} ]] && init_settings_openvpn


function check_setting() {
    ###
    # Check a setting and determine if its value is valid.
    #
    ###
    if [[ $1 = '' ]]; then
        [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Setting Invalid: $1${RESET}"

    fi
}


# Check VPN Server IP Address and prompt for input
if [[ ! $VPN_SERVER ]]; then
    echo -e "\n${YELLOW}[ERROR] Invalid VPN Server: Missing VPN Server IP Adress variable"
    echo -e -n "${GREEN}[+] ${RESET}"
    read -r -p "Enter OpenVPN Server IP: " -e VPN_SERVER
    # Write to settings file
    echo -e "# VPN Custom Configuration" >> "${APP_SETTINGS}"
    echo "VPN_SERVER=${VPN_SERVER}" >> "${APP_SETTINGS}"
fi


# ==================================[ Begin Script ]================================= #
$SUDO apt-get -y install openvpn openssl

# If openvpn is currently running, stop the service first
if [[ $(which openvpn) ]]; then
    #service openvpn stop
    systemctl stop openvpn
    #openvpn --version
    sleep 2
fi


# -==[ Setup Easy-RSA Package ]==-
filedir="${HOME}/git/easy-rsa"
if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    cd "${filedir}"
    git clone git://github.com/OpenVPN/easy-rsa
fi

[[ ! -d "${VPN_PREP_DIR}" ]] && mkdir -p "${VPN_PREP_DIR}"
# Copy Easy-rsa3 directly into the setup folder
# Cannot use "*" within quotes, because inside quotes, special chars do not expand
cp -R "${filedir}"/easy-rsa/easyrsa3/* "${VPN_PREP_DIR}"
cd "${VPN_PREP_DIR}"

# NOTE: Can't find a use for vars because you can't control cert output paths, only pki path
#mv vars.example vars


# ===============================[ Initialize PKI Infra ]============================== #
function new_pki {
    ###
    #   Function to initialize a new PKI structure for signing certs. If one exists, will prompt
    #   to either keep existing or clear and start new.
    ###
    # Clean
    echo -e "${GREEN}[*]${RESET} Initializing a new PKI system within the specified directory path."
    cd "${VPN_PREP_DIR}"
    ./easyrsa init-pki
    # Result:
        # [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] New PKI Dir: ${VPN_PREP_DIR}/pki

    # Build CA
    ./easyrsa build-ca
    # Result:
        # [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] CA Cert now at: ${VPN_PREP_DIR}/pki/ca.crt

    # If CA not successfully built, halt setup
    [[ $? -ne 0 ]] && echo -e "${YELLOW}[-] ERROR: CA not successfully built, did you enter a password?${RESET}" && exit 1
}


if [[ -f "${VPN_PREP_DIR}/pki/ca.crt" ]]; then
    echo -e "\n${YELLOW} [*] PKI Structure already exists!${RESET}"
    read -n 5 -i "N" -p " [+] Purge PKI and start fresh? [y,N]: " -e response
    echo -e
    case $response in
        [Yy]* ) new_pki;;
    esac
else
    [[ ! -d "${VPN_PREP_DIR}/pki" ]] && new_pki
fi


# -==[ OpenVPN Server Key ]==-
# Build Server Key, if one of the key/crt is missing (in case you accidentally forgot to confirm the crt)
if [[ ! -f "${VPN_PREP_DIR}/pki/private/server.key" || ! -f "${VPN_PREP_DIR}/pki/issued/server.crt" ]]; then
    cd "${VPN_PREP_DIR}"
    echo -e "${GREEN}[*]${RESET} Generating Server Key"
    ./easyrsa gen-req server nopass
    # Result:
    #   Keypair and certificate request completed. Your files are:
    #   request:    ${VPN_PREP_DIR}/pki/reqs/server.req
    #   key:        ${VPN_PREP_DIR}/pki/private/server.key

    # Sign Server Key with CA
    echo -e "${GREEN}[*]${RESET} Sign Server Certificate; Enter CA Passphrase below"
    ./easyrsa sign-req server server
    # Result:
    #   Certificate created at: ${VPN_PREP_DIR}/pki/issued/server.crt
    cp -u pki/private/server.key /etc/openvpn/
    cp -u pki/issued/server.crt /etc/openvpn/
fi

# -==[ OpenVPN Server DH Key ]==-
if [[ ! -f "${VPN_PREP_DIR}/dhparam.pem" ]]; then
    if [[ "$DEBUG" = true ]]; then
        echo -e "${ORANGE}[DEBUG] Debug is enabled, so skipping DH key generation${RESET}"
    else
        echo -e "${GREEN}[*]${RESET} Generating Diffie Hellman Key"
        openssl dhparam -out dhparam.pem 4096
    fi
fi

# ===[ Build Static HMAC Key that prevents certain DoS attacks ]===
if [[ ! -f "${VPN_PREP_DIR}/ta.key" ]]; then
    echo -e "${GREEN}[*]${RESET} Generating HMAC Key"
    /usr/sbin/openvpn --genkey --secret ta.key
fi


# ===[ CLIENT KEY-PAIR Creation ]===
for i in "${CLIENT_NAME[@]}"; do
    # Build Client Key, if it doesn't already exist
    if [[ ! -f "${VPN_PREP_DIR}/pki/private/${i}.key" ]]; then
        echo -e "${GREEN}[*]${RESET} Generating Client Certificate/Key Pair for: ${i}"
        ./easyrsa gen-req "${i}" nopass
        sleep 3
        echo -e "${GREEN}[*]${RESET} Sign Client Certificate; Enter CA Passphrase below"
        ./easyrsa sign-req client "${i}"

        [[ $? -ne 0 ]] && echo -e "${RED}[ERROR] ${RESET}Failed to sign client cert. Restart and try again." && exit 1
        # No password on agents, or we have to come up with a complex solution for
        # entering the password when agent boots up.
        #       see: https://bbs.archlinux.org/viewtopic.php?id=150440
        #
        # Result:
        #   Keypair and certificate request completed. Your files are:
        #       request:    ${VPN_PREP_DIR}/pki/reqs/client1.req
        #       key:        ${VPN_PREP_DIR}/pki/private/client1.key
        # -----------------------[ BUILD CLIENT OVPN FILE - merge.sh ]----------------------------- #
        echo -e "${GREEN}[*]${RESET} Building Client conf/ovpn File"
        ca="${VPN_PREP_DIR}/pki/ca.crt"
        cert="${VPN_PREP_DIR}/pki/issued/${i}.crt"
        key="${VPN_PREP_DIR}/pki/private/${i}.key"
        tlsauth="${VPN_PREP_DIR}/ta.key"

        # Generate client base config
        cd "${VPN_PREP_DIR}"
        file="${i}.conf"
        cat << EOF > "${file}"
client
dev tun
proto ${VPN_PROTOCOL}
# remote server IP
remote $VPN_SERVER $VPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
comp-lzo
# Increase to verb 4 for troubleshooting only
verb 3
mute 20
EOF

        #   Delete pre-existing entries to keys and certs first
        sed -i \
        -e '/ca .*'$ca'/d'  \
        -e '/cert .*'$cert'/d' \
        -e '/key .*'$key'/d' \
        -e '/tls-auth .*'$tlsauth'/d' $file

        #   Add keys and certs inline
        echo "key-direction 1" >> $file

        echo "<ca>" >> $file
        awk /BEGIN/,/END/ < $ca >> $file
        echo "</ca>" >> $file

        echo "<cert>" >> $file
        awk /BEGIN/,/END/ < $cert >> $file
        echo "</cert>" >> $file

        echo "<key>" >> $file
        awk /BEGIN/,/END/ < $key >> $file
        echo "</key>" >> $file

        echo "<tls-auth>" >> $file
        awk /BEGIN/,/END/ < $tlsauth >> $file
        echo "</tls-auth>" >> $file
    else
        echo -e "${RED}[-] ERROR:${RESET} This client (${i}) already has an issued key pair."
        echo -e "${RED}[-]${RESET} To make a new request, you must first revoke the original with:"
        echo -e "${RED}[-]${RESET}\t${GREEN}./easyrsa revoke <cert_name>${RESET}"
        echo -e "\n${RED}[-]${RESET} Then, you may also need to manually delete this client's \".crt, .key, and .req\" files.\n\n"
        echo -e "${YELLOW}[*]${RESET} Proceeding with OpenVPN Server setup process."
    fi

    # Generate client-specific "CCD" configs
    #[[ ! -d "/etc/openvpn/ccd" ]] && mkdir -p /etc/openvpn/ccd
    #file="/etc/openvpn/ccd/${i}"
    #cat <<EOF > "${file}"
# This file ensures the client-specific settings
# The file's name must equal the Common Name of its certificate
# First, we give the client a set IP that never changes
#ifconfig-push 10.9.8.1 10.9.8.2

# If we want, we can enable backend routes on the client
# To enable this, you first place "route 192.158.1.0 255.255.255.0"
# into the server.conf, then uncomment the line below.
# This will give that subnet access to the VPN and vice versa. Only works if routing,
# not bridging...e.g. using "dev tun" and "server" directives.
#iroute 192.168.1.0 255.255.255.0
#EOF

# -==[ End of Client Configs creation ]==-
done



# Generate the server configuration file
file="/etc/openvpn/server.conf"
cat <<EOF > "${file}"
daemon
dev tun
port $VPN_PORT
# FWIW: TCP is more reliable than UDP if behind a proxy
proto ${VPN_PROTOCOL}
tls-server
# --Certs--
# HMAC Protection, Server is 0, Client is 1
tls-auth ta.key 0
ca ca.crt
cert server.crt
key server.key
dh dhparam.pem
# VPN Subnet to use; Gateway being 10.9.8.1
server ${VPN_SUBNET} 255.255.255.0

# Maintain a record of IP associations. If a client goes down
# it will reconnect and be given the same IP address
# *NOTE: This setting conflicts with 'duplicate-cn' and is disabled during testing
#ifconfig-pool-persist ipp.txt

# Redirect clients' default gateway, bypassing dhcp server issues
push "redirect-gateway def1 bypass-dhcp"
# Disabling this for now
#push "dhcp-option DNS 8.8.8.8"

### Client Settings
client-to-client
duplicate-cn
max-clients 3
# Push Routes to Client

# Client-specific configs or certificates
#client-config-dir ccd

# Compression, copy to client config also
comp-lzo

# Cipher entries must be copied to the client config as well
cipher AES-256-CBC

# keepalive causes ping-like messages to be sent back
# and forth over the link so that each side knows when
# the other side has gone down. 10 120 = ping every 10 seconds
# assume that remote peer is down if no ping received during
# a 120-second time period.
keepalive 10 120
user nobody
group nogroup
persist-key
persist-tun

# Output a short status file showing current connections, each minute
status openvpn-status.log
log-append /var/log/openvpn.log
verb 4
mute 20

# *UNTESTED* --TLS CIPHERS-- (Avoid DES)
# Below are TLS 1.2 & require OpenVPN 2.3.3+
#tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384
# Below are TLS 1.0 & require OpenVPN 2.3.2 or lower
#tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA
EOF


# Copy all server keys to /etc/openvpn/ if they've been updated
echo -e "${GREEN}[*]${RESET} Moving Server Certificate Files to /etc/openvpn/"
cd "${VPN_PREP_DIR}"
cp -u ./{dhparam.pem,ta.key} /etc/openvpn/
cp -u pki/ca.crt /etc/openvpn/

# Make sure all cert/key files are set to 644
chmod 644 /etc/openvpn/{ca.crt,server.crt,server.key,ta.key,dhparam.pem}

# Harden the keys
#chmod 600 /etc/openvpn/server.key
#chmod 600 /etc/openvpn/ta.key

# Enable IP Forwarding
echo -e "${GREEN}[*]${RESET} Configuring IP Forwarding and Firewall Exceptions"
echo 1 > /proc/sys/net/ipv4/ip_forward
# Make it permanent
file="/etc/sysctl.conf"
sed -i 's|^#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' "${file}"

# TODO: ipv6 line in same file needs uncommented for IPv6 packet forwarding
# #net.ipv6.conf.all.forwarding=1


# Base Firewall Configuration to ensure success
#iptables -A FORWARD -i eth0 -o tap0 -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A FORWARD -s "{$VPN_SUBNET}/24" -o eth0 -j ACCEPT
# Only enable the line below if you wish client traffic to have Internet access
# This may be insecure if the client is in a sensitive area that shouldn't have this.
#iptables -t nat -A POSTROUTING -s "${VPN_SUBNET}/24" -o eth0 -j MASQUERADE


# Finish
cd ~
echo -e "${GREEN}[*]${RESET} Restarting OpenVPN Service to Initialize VPN Server"
#service openvpn restart
systemctl start openvpn
sleep 5s
[[ $? -ne 0 ]] && systemctl reload openvpn

echo -e -n "\n${YELLOW}[+] Enable OpenVPN for Autostart:${RESET}"
read -r -p " [Y,n]: " -i "y" -e response
echo -e ""
case $response in
    [Yy]* ) systemctl enable openvpn;;
esac

# TODO: Ensure Apache is not bound to port 443 (ssl) or server cannot bind to port 443
# NOTE: Disable SSL anytime with command: a2dismod ssl; service apache2 restart
sleep 3s
echo -e "${GREEN}[*]${RESET} Netstat of VPN Server - is port ${VPN_PORT} listening?"
netstat -nutlap | grep "${VPN_PORT}"
sleep 5s

echo -e "\n${GREEN}============================================================${RESET}"
echo -e "\tVPN SERVER:\t${VPN_SERVER}"
echo -e "\tVPN Port:\t${VPN_PORT}/${VPN_PROTOCOL}"
echo -e "\tClient(s):\t${CLIENT_NAME[@]}"
echo -e "\tClient Conf(s):\t${VPN_PREP_DIR}/"
echo -e "${GREEN}============================================================${RESET}"
echo -e "\t\t${GREEN}[*]${RESET} OpenVPN Setup Complete!\n\n"


function finish {
    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
    echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." | tee -a "${LOG_FILE}"
    # Redirect app output to log, sending both stdout and stderr (*NOTE: this will not parse color codes)
    # cmd_here 2>&1 | tee -a "${LOG_FILE}"
}
# End of script
trap finish EXIT



# =========================[ RELEASE NOTES / CHANGES ] ======================
#   OpenVPN 2.4 removed tls-remote option. Current setups using that option
#     will fail to work. Update your configuration to use verify-x509-name
#     instead.
