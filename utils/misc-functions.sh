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
