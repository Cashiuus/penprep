#!/bin/bash


set -e

BASE_INSTALL_PATH="/opt/sliver"     # Default is /root/, but it's more common for installs to be in /opt/
LHOST="localhost"                   # can be "localhost", "127.0.0.1", or a public IP/FQDN
INSTALL_USER="root"                 # Service account for running sliver-server

SLIVER_GPG_KEY_ID=4449039C
SLIVER_SERVER='sliver-server_linux'
SLIVER_CLIENT='sliver-client_linux'


##  Sudo checker/init
## =================================== ##
function check_root() {
  if [[ $EUID -ne 0 ]]; then
    # If not root, check if sudo package is installed
    if [[ $(which sudo) ]]; then
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
      export SUDO="sudo"
      echo -e "${YELLOW}[WARN] This script leverages sudo for installation. Enter your password when prompted!${RESET}"
      sleep 1
      # Test to ensure this user is able to use sudo
      sudo -l >/dev/null
      if [[ $? -eq 1 ]]; then
        # sudo pkg is installed but current user is not in sudoers group to use it
        echo -e "${RED}[ERROR]${RESET} You are not able to use sudo. Running install to fix."
        read -r -t 5
        install_sudo
      fi
    else
      echo -e "${YELLOW}[WARN]${RESET} The 'sudo' package is not installed."
      echo -e "${YELLOW}[+]${RESET} Press any key to install it (*You'll be prompted to enter sudo password). Otherwise, manually cancel script now..."
      read -r -t 5
      install_sudo
    fi
  fi
}
check_root


function create_service_account() {
    # Usage: create_service_account sliver
    #
    if id -u "$1" >/dev/null 2>&1; then
        echo -e "[!] User already exists"
    else
        echo -e "[*] Creating new system user: $1"
        $SUDO addgroup --system "$1"
        $SUDO adduser --disabled-password --system --ingroup "$1" "$1"
    fi
}


function clean_sliver() {
    $SUDO systemctl stop sliver.service 2>/dev/null
    if [[ "${BASE_INSTALL_PATH}" == "/" ]] \
        || [[ "${BASE_INSTALL_PATH}" == "/opt" ]] \
        || [[ "${BASE_INSTALL_PATH}" == "/root" ]]; then
        # Should you srsly be using linux?
        echo -e "[!] Skipping deletion of base install path to avoid erasing things you likely care about"
    else
        $SUDO rm -rf "${BASE_INSTALL_PATH}"
    fi
    $SUDO rm /etc/systemd/system/sliver.service
    rm -rf "${HOME}/.sliver" 2>/dev/null
    rm -rf "${HOME}/.sliver-client" 2>/dev/null
    $SUDO rm -rf /root/.sliver 2>/dev/null
    $SUDO rm -rf /root/.sliver-client 2>/dev/null
    $SUDO rm /usr/local/bin/sliver 2>/dev/null
    echo -e "[*] Removed Sliver framework from your system. Run script again if you wish to re-install!"
    exit 0
}


function install_os_depends() {
    if [ -n "$(command -v yum)" ]
    then
        $SUDO yum -y install curl gcc gcc-c++ gnupg make mingw64-gcc
    fi

    if [ -n "$(command -v apt-get)" ]
    then
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -yqq \
            curl build-essential gpg \
            mingw-w64 binutils-mingw-w64 g++-mingw-w64
    fi

    # Curl
    if ! command -v curl &> /dev/null
    then
        echo "[!] curl could not be found"
        exit 1
    fi
    # Awk
    if ! command -v awk &> /dev/null
    then
        echo "[!] awk could not be found"
        exit 1
    fi
    # GPG
    if ! command -v gpg &> /dev/null
    then
        echo "[!] gpg could not be found"
        exit 1
    fi
}


function install_sliver_core() {
    $SUDO gpg --import <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=lxj2
-----END PGP PUBLIC KEY BLOCK-----
EOF

    #
    # Download and Unpack Sliver Server
    #
    [[ ! -d "${BASE_INSTALL_PATH}" ]] && $SUDO mkdir -p "${BASE_INSTALL_PATH}"
    cd "${BASE_INSTALL_PATH}"

    for URL in $ARTIFACTS; do
        if [[ "$URL" == *"$SLIVER_SERVER"* ]]; then
            echo "Downloading $URL"
            $SUDO curl --silent -L $URL --output $(basename $URL)
        fi
        if [[ "$URL" == *"$SLIVER_CLIENT"* ]]; then
            echo "Downloading $URL"
            $SUDO curl --silent -L $URL --output $(basename $URL)
        fi
    done

    echo "Verifying signatures ..."
    $SUDO gpg --default-key $SLIVER_GPG_KEY_ID --verify "${BASE_INSTALL_PATH}/$SLIVER_SERVER.sig" "${BASE_INSTALL_PATH}/$SLIVER_SERVER"
    $SUDO gpg --default-key $SLIVER_GPG_KEY_ID --verify "${BASE_INSTALL_PATH}/$SLIVER_CLIENT.sig" "${BASE_INSTALL_PATH}/$SLIVER_CLIENT"
}


function install_sliver_client() {
    install_os_depends
    install_sliver_core
    if test -f "${BASE_INSTALL_PATH}/$SLIVER_CLIENT"; then
        $SUDO chmod 755 "${BASE_INSTALL_PATH}/$SLIVER_CLIENT"
        $SUDO cp "${BASE_INSTALL_PATH}/$SLIVER_CLIENT" /usr/local/bin/sliver
        $SUDO chmod 755 /usr/local/bin/sliver
    else
        exit 3
    fi

    if [[ ! -d "${HOME}/.sliver-client/configs" ]]; then
        mkdir -p "${HOME}/.sliver-client/configs"
        $SUDO chown -R "$USER":"$USER" "${HOME}/.sliver-client/"
    fi
    $SUDO updatedb 2>/dev/null
    echo -e "[*] Sliver client install is complete. Run using 'sliver', goodbye!"
    exit 0
}



##  Running Main
## =================================== ##
ARTIFACTS=$(curl -s "https://api.github.com/repos/BishopFox/sliver/releases/latest" | awk -F '"' '/browser_download_url/{print $4}')

case "$1" in
    clean) clean_sliver;;
    remove) clean_sliver;;
    client) install_sliver_client;;    # Will install normal but no service & copy client to $HOME
esac
# ------------------------


# -- Server/Full install portion is here and below
install_os_depends
install_sliver_core

# Install a sliver service account, if applicable
create_service_account "${INSTALL_USER}"

if test -f "${BASE_INSTALL_PATH}/$SLIVER_SERVER"; then
    $SUDO mv "${BASE_INSTALL_PATH}/$SLIVER_SERVER" "${BASE_INSTALL_PATH}/sliver-server"
    $SUDO chmod 755 "${BASE_INSTALL_PATH}/sliver-server"
    $SUDO "${BASE_INSTALL_PATH}/sliver-server" unpack --force
else
    exit 3
fi

# systemd
echo "[*] Configuring systemd service ..."
file="/etc/systemd/system/sliver.service"
cat > /tmp/sliver.service <<-EOF
[Unit]
Description=Sliver Server Daemon
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=3
User=${INSTALL_USER}
ExecStart=${BASE_INSTALL_PATH}/sliver-server daemon --lhost 127.0.0.1

[Install]
WantedBy=multi-user.target
EOF
$SUDO mv /tmp/sliver.service "${file}"
$SUDO chown root:root /etc/systemd/system/sliver.service
$SUDO chmod 644 /etc/systemd/system/sliver.service
$SUDO systemctl daemon-reload
$SUDO systemctl start sliver
#$SUDO systemctl enable sliver

# Set perms for the install dir
$SUDO chown -R "$INSTALL_USER":"$INSTALL_USER" "${BASE_INSTALL_PATH}"

# Also fully setup the client on full installs
install_sliver_client

# Generate local configs
if [[ "$EUID" -eq 0 ]]; then
    echo "[*] Generating operator configs for [root] ..."
    mkdir -p "/root/.sliver-client/configs"
    $SUDO "${BASE_INSTALL_PATH}/sliver-server" operator --name root --lhost "$LHOST" --save "${HOME}/.sliver-client/configs"
    $SUDO chown -R root:root "/root/.sliver-client/"
fi

USER_DIRS=(/home/*)
for USER_DIR in "${USER_DIRS[@]}"; do
    USER=$(basename $USER_DIR)
    if id -u $USER >/dev/null 2>&1; then
        echo "[*] Generating operator configs for [$USER]..."
        mkdir -p "$USER_DIR/.sliver-client/configs"
        "${BASE_INSTALL_PATH}/sliver-server" operator --name "$USER" --lhost "$LHOST" --save "$USER_DIR/.sliver-client/configs"
        $SUDO chown -R "$USER":"$USER" "$USER_DIR/.sliver-client/"
    fi
done


echo -e "[*] Sliver framework install is complete. Run using 'sliver', goodbye!"
exit 0
