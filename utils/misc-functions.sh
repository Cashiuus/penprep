


function install_vpn_helper_script() {
  echo -e "${GREEN}[*] ${RESET}Installing VPN helper script to ${VPN_BASE_DIR}/vpn-helper.sh"
  file="${VPN_BASE_DIR}/vpn-helper.sh"
  #touch "${file}"
  cat <<EOF > "${file}"
#!/bin/bash

VPN_BASE_DIR="\${HOME}/vpn"
GREEN="\\033[01;32m"
YELLOW="\\033[01;33m"
RESET="\\033[00m"

if [[ ! -s "\${VPN_BASE_DIR}/vpn-helper.conf" ]]; then
    echo -e "\n\n\${GREEN}[+] \${RESET}First time running? Find your .ovpn file in this list below:"
    echo -e "-----------------------[ \${HOME}/vpn/ ]-----------------------"
    ls -al "\${VPN_BASE_DIR}"
    echo -e "---------------------------------------------------------------"
    echo -e -n "\${YELLOW}[+]\${RESET}"
    read -e -p " Enter full path to your OpenVPN '.ovpn' file here: " RESPONSE
    while [[ ! -s "\${RESPONSE}" ]]; do
        echo -e -n "\${YELLOW}[-]\${RESET}"
        read -e -p " You've provided an invalid file, try again: " RESPONSE
    done
    echo "OVPN_FILE=\${RESPONSE}" > "\${VPN_BASE_DIR}/vpn-helper.conf"
else
    echo -e "\${GREEN}[*] \${RESET}Config file exists! If not correct, edit \${VPN_BASE_DIR}/vpn-helper.conf"
fi

echo -e "\n\${GREEN}[*] \${RESET}Ensuring your VPN config file is secured with proper permissions"
chmod 0600 "\${VPN_BASE_DIR}/vpn-helper.conf"
. "\${VPN_BASE_DIR}/vpn-helper.conf"

echo -e "\${GREEN}[*] \${RESET}Prep done, now launching OpenVPN with chosen .ovpn config"
openvpn --config "\${OVPN_FILE}" \\
    --script-security 2
EOF
chmod u+x "${file}"

}






function validate_port() {
  # We don't want to allow an unusable port
  if [ $sshport -lt 0 -o $sshport -gt 65535 ]; then
    echo "Bad port number, must be between 0 and 65535."
    exit 1
  fi
}





function check_version_java() {
  ###
  #   Check the installed/active version of java
  #
  #   Usage: check_version_java
  #
  ###
  if type -p java; then
    echo found java executable in PATH
    _java=java
  elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo found java executable in JAVA_HOME
    _java="$JAVA_HOME/bin/java"
  else
    echo "no java"
  fi

  if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo version "$version"
    if [[ "$version" > "1.5" ]]; then
      echo version is more than 1.5
    else
      echo version is less than 1.5
    fi
  fi
}


function make_tmp_dir() {
  # <doc:make_tmp_dir> {{{
  #
  # This function taken from a vmware tool install helper to securely
  # create temp files. (installer.sh)
  #
  # Usage: make_tmp_dir dirname prefix
  #
  # Required Variables:
  #
  #   dirname
  #   prefix
  #
  # Return value: null
  #
  # </doc:make_tmp_dir> }}}

  local dirname="$1" # OUT
  local prefix="$2"  # IN
  local tmp
  local serial
  local loop

  tmp="${TMPDIR:-/tmp}"

  # Don't overwrite existing user data
  # -> Create a directory with a name that didn't exist before
  #
  # This may never succeed (if we are racing with a malicious process), but at
  # least it is secure
  serial=0
  loop='yes'
  while [ "$loop" = 'yes' ]; do
  # Check the validity of the temporary directory. We do this in the loop
  # because it can change over time
  if [ ! -d "$tmp" ]; then
    echo 'Error: "'"$tmp"'" is not a directory.'
    echo
    exit 1
  fi
  if [ ! -w "$tmp" -o ! -x "$tmp" ]; then
    echo 'Error: "'"$tmp"'" should be writable and executable.'
    echo
    exit 1
  fi

  # Be secure
  # -> Don't give write access to other users (so that they can not use this
  # directory to launch a symlink attack)
  if mkdir -m 0755 "$tmp"'/'"$prefix$serial" >/dev/null 2>&1; then
    loop='no'
  else
    serial=`expr $serial + 1`
    serial_mod=`expr $serial % 200`
    if [ "$serial_mod" = '0' ]; then
      echo 'Warning: The "'"$tmp"'" directory may be under attack.'
      echo
    fi
  fi
  done

  eval "$dirname"'="$tmp"'"'"'/'"'"'"$prefix$serial"'
}


function is_process_alive() {
  # Checks if the given pid represents a live process.
  # Returns 0 if the pid is a live process, 1 otherwise
  #
  # Usage: is_process_alive 29833
  #   [[ $? -eq 0 ]] && echo -e "Process is alive"

  local pid="$1" # IN
  ps -p $pid | grep $pid > /dev/null 2>&1
}
