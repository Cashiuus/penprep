#!/bin/bash


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



##  Running Main
## =================================== ##

if [[ ! -d "/opt/Postman" ]]; then
    cd /tmp
    curl -SL "https://dl.pstmn.io/download/latest/linux64" -o postman.tar.gz
    tar -xvf postman.tar.gz
    $SUDO mv Postman /opt/
fi
# You could also install via snap: snap install postman


[[ ! -d "${HOME}/.local/share/applications" ]] && mkdir -p "${HOME}/.local/share/applications"
file1="${HOME}/.local/share/applications/Postman.desktop"
cat <<EOF > "${file1}"
[Desktop Entry]
Encoding=UTF-8
Name=Postman
Exec=/opt/Postman/app/Postman %U
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;
EOF
chmod u+x "${file1}"

# Copy desktop shortcut to the desktop, unless we are on a remote server
# w/o a desktop
if [[ -d "${HOME}/Desktop" ]]; then
  file2="${HOME}/Desktop/Postman.desktop"
  [[ ! -f "${file2}" ]] && \
    cp "${file1}" "${file2}" 2>/dev/null
  chmod u+x "${file2}" 2>/dev/null
fi

echo -e "[*] Postman setup is finished!"
