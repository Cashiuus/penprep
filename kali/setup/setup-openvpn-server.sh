#!/bin/bash
## =============================================================================
# Filename: setup-openvpn-server.sh
#
# Author:   cashiuus - cashiuus@gmail.com
# Created:      -   (Revised: 17-Jan-2016)
#
# MIT License ~ http://opensource.org/licenses/MIT
#-[ Notes ]---------------------------------------------------------------------
#
# Purpose:  Setup OpenVPN Server and prep all certs needed.
#           Uses the newer easy-rsa3 version to generate
#           the certificate package.
#           Lastly, we merge all client certs into a
#           singular embedded client config file.
#
# OpenVPN Hardening Cheat Sheet: http://darizotas.blogspot.com/2014/04/openvpn-hardening-cheat-sheet.html
## =============================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
SCRIPT_DIR=$(readlink -f $0)
APP_BASE=$(dirname ${SCRIPT_DIR})
VPN_PREP_DIR="${HOME}/vpn-setup"
VPN_SERVER=''
VPN_PORT='1194'
VPN_PROTOCOL='udp'
VPN_SUBNET="10.9.8.0"
CLIENT_NAME="client1"
# ===============================[ Check Permissions ]============================== #
ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
## Exit if the script was not launched by root or through sudo
if [[ ${EUID} -ne 0 ]]; then
    echo "The script needs to run as sudo/root" && exit 1
fi
# ==================================[ Begin Script ]================================= #
sudo apt-get install openvpn openssl -y

if [[ $(which openvpn) ]]; then
    #service openvpn stop
    systemctl stop openvpn
    openvpn --version
    sleep 2
fi

if [[ -f "${APP_BASE}/../config/mybuilds.conf" ]]; then
    # If custom config is present, use it for VPN server specs
    source "${APP_BASE}/../config/mybuilds.conf"
elif [[ $VPN_SERVER == '' ]]; then
    echo -e "${YELLOW}[ERROR] << Invalid VPN Server >> Missing VPN Server variable"
    echo -e -n "${GREEN}[+] ${RESET}"
    read -p "Enter OpenVPN Server IP: " -e VPN_SERVER
    echo -e
fi

filedir="${HOME}/git/easy-rsa"
if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    cd "${filedir}"
    git clone git://github.com/OpenVPN/easy-rsa
fi

[[ ! -d "${VPN_PREP_DIR}" ]] && mkdir -p "${VPN_PREP_DIR}"
# Copy Easy-Rsa3 directly into the setup folder
# Cannot use "*" within quotes, because inside quotes, special chars do not expand
cp -R "${filedir}"/easy-rsa/easyrsa3/* "${VPN_PREP_DIR}"
cd "${VPN_PREP_DIR}"

# NOTE: Can't find a use for vars because you can't control cert output paths, only pki path
#mv vars.example vars


function new_pki {
    # Clean
    echo -e "${GREEN}[*]${RESET} Initializing a new PKI system within the specified directory path."
    cd "${VPN_PREP_DIR}"
    ./easyrsa init-pki
    # Result:
        # New PKI Dir: ${VPN_PREP_DIR}/pki

    # Build CA
    ./easyrsa build-ca
    # Result:
        # CA Cert now at: ${VPN_PREP_DIR}/pki/ca.crt
}

# ===============================[ Initialize PKI Infra ]============================== #
if [[ -f "${VPN_PREP_DIR}/pki/ca.crt" ]]; then
    echo -e "\n${YELLOW} [*] PKI Structure already exists!${RESET}"
    read -n 1 -p " [+] Purge PKI and start fresh? [y,N]: " -e response
    echo -e
    case $response in
        [Yy]* ) new_pki;;
    esac
else
    [[ ! -d "${VPN_PREP_DIR}/pki" ]] && new_pki
fi

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

# ===[ Build Server DH Key ]===
if [[ ! -f "${VPN_PREP_DIR}/dhparam.pem" ]]; then
    echo -e "${GREEN}[*]${RESET} Generating Diffie Hellman Key"
    openssl dhparam -out dhparam.pem 4096
fi

# ===[ Build Static HMAC Key that prevents certain DoS attacks ]===
if [[ ! -f "${VPN_PREP_DIR}/ta.key" ]]; then
    echo -e "${GREEN}[*]${RESET} Generating HMAC Key"
    /usr/sbin/openvpn --genkey --secret ta.key
fi


# ===[ CLIENT KEY PAIR ]===
if [[ ${CLIENT_NAME} == "client1" ]]; then
    echo -e "\n${YELLOW}[+] Default Client Cert Detected!${RESET}\n"
    echo -e "${YELLOW}[+] ${RESET}"
    read -t 10 -p "Keep this or specify a custom name [client1]:" -i "client1" -e CLIENT_NAME
    echo -e
fi


# Build Client Key, if it doesn't already exist (*Noticing a trend?!?)
if [[ ! -f "${VPN_PREP_DIR}/pki/private/${CLIENT_NAME}.key" ]]; then
    echo -e "${GREEN}[*]${RESET} Generating Client Certificate/Key Pair"
    ./easyrsa gen-req "${CLIENT_NAME}" nopass
    sleep 3
    echo -e "${GREEN}[*]${RESET} Sign Client Certificate; Enter CA Passphrase below"
    ./easyrsa sign-req client "${CLIENT_NAME}"
    # No password on agents, or we have to come up with a complex solution for
    # entering the password, see: https://bbs.archlinux.org/viewtopic.php?id=150440
    # Result:
    #   Keypair and certificate request completed. Your files are:
    #       request:    ${VPN_PREP_DIR}/pki/reqs/client1.req
    #       key:        ${VPN_PREP_DIR}/pki/private/client1.key
    # -----------------------[ BUILD CLIENT OVPN FILE - merge.sh ]----------------------------- #
    echo -e "${GREEN}[*]${RESET} Building Client conf/ovpn File"
    ca="${VPN_PREP_DIR}/pki/ca.crt"
    cert="${VPN_PREP_DIR}/pki/issued/${CLIENT_NAME}.crt"
    key="${VPN_PREP_DIR}/pki/private/${CLIENT_NAME}.key"
    tlsauth="${VPN_PREP_DIR}/ta.key"

    # Generate client base config
    cd "${VPN_PREP_DIR}"
    file="${CLIENT_NAME}.conf"
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
    echo -e "${RED}[-] ERROR:${RESET} This client (${CLIENT_NAME}) already has an issued key pair."
    echo -e "${RED}[-]${RESET} To make a new request, you must first revoke the original with:"
    echo -e "${RED}[-]${RESET}\t${GREEN}./easyrsa revoke <cert_name>${RESET}"
    echo -e "\n${RED}[-]${RESET} Then, you may also need to manually delete this client's \".crt, .key, and .req\" files.\n\n"
    echo -e "${YELLOW}[*]${RESET} Proceeding with OpenVPN Server setup process."
fi

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
push "dhcp-option DNS 8.8.8.8"

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
keepalive 10 120
user nobody
group nogroup
persist-key
persist-tun

# Output a short status file showing current connections, each minute
status openvpn-status.log
log-append /var/log/openvpn.log
verb 6
mute 20

# *UNTESTED* --TLS CIPHERS-- (Avoid DES)
# Below are TLS 1.2 & require OpenVPN 2.3.3+
#tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384
# Below are TLS 1.0 & require OpenVPN 2.3.2 or lower
#tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA
EOF

# Generate client-specific "CCD" configs
#[[ ! -d "/etc/openvpn/ccd" ]] && mkdir -p /etc/openvpn/ccd
#file="/etc/openvpn/ccd/${CLIENT_NAME}"
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


# Copy all server keys to /etc/openvpn/ if they've been updated
echo -e "${GREEN}[*]${RESET} Moving Server Certificate Files to /etc/openvpn/"
cd "${VPN_PREP_DIR}"
cp -u ./{dhparam.pem,ta.key} /etc/openvpn/
cp -u pki/ca.crt /etc/openvpn/

# Make sure all cert/key files are set to 644
chmod 644 /etc/openvpn/{ca.crt,server.crt,server.key,ta.key,dhparam.pem}

# Enable IP Forwarding
echo -e "${GREEN}[*]${RESET} Configuring IP Forwarding and Firewall Exceptions"
echo 1 > /proc/sys/net/ipv4/ip_forward
# Make it permanent
file="/etc/sysctl.conf"
sed -i 's|^#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' "${file}"

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
sleep 5


echo -e -n "\n${YELLOW}[+] Enable OpenVPN for Autostart:${RESET}"
read -n 1 -p " [Y,n]: " -i "y" -e response
echo -e ""
case $response in
    [Yy]* ) systemctl enable openvpn;;
esac

# Ensure Apache is not bound to port 443 (ssl) or server cannot bind to port 443
# NOTE: Disable SSL anytime with command: a2dismod ssl; service apache2 restart
echo -e "${GREEN}[*]${RESET} Netstat of VPN Server: "
netstat -nutlap | grep "${VPN_PORT}"
sleep 3

echo -e "\n${GREEN}============================================================${RESET}"
echo -e "\tVPN SERVER:\t${VPN_SERVER}"
echo -e "\tVPN Port:\t${VPN_PORT}/${VPN_PROTOCOL}"
echo -e "\tClient CN:\t${CLIENT_NAME}"
echo -e "\tClient Conf:\t${VPN_PREP_DIR}/${CLIENT_NAME}.conf"
echo -e "${GREEN}============================================================${RESET}"
echo -e "\t\t${GREEN}[*]${RESET} OpenVPN Setup Complete!\n\n"
