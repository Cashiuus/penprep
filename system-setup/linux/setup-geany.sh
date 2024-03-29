#!/usr/bin/env bash
## =======================================================================================
# File:     setup-geany.sh
#
# Author:   Cashiuus
# Created:  10-Oct-2015     Revised:  24-Jan-2022
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Install Geany IDE tool, configure custom settings, and copy in templates.
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#   Latest Change:  Fixed underscore invisible bug in versions < 1.37
#       - 2020-12-28 - Added network interface code for ifaces like 'ens32' to work
#       - 2021-04-05 - Bugfix for the *.txt filetype styling additional conf file
#
##-[ Changelog ]-----------------------------------------------------------------------
#
# 2022-01-24: Added enabling 2 plugins and more custom settings to geany.conf
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="1.8.4"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Warnings/Information
RED="\033[01;31m"       # Issues/Errors
BLUE="\033[01;34m"      # Heading
PURPLE="\033[01;35m"    # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"      # Highlight
RESET="\033[00m"        # Normal
## ============[ CONSTANTS ]================ ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)          # Previously "${SCRIPT_DIR}"
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
APP_SETTINGS="${HOME}/.config/penbuilder/settings.conf"
APP_ARGS=$@
DEBUG=false
LOG_FILE="${APP_BASE}/debug.log"

BACKUPS_PATH="${HOME}/Backups/geany"
GEANY_TEMPLATES="${APP_BASE}/../../templates/geany"


#======[ ROOT PRE-CHECK ]=======#
function install_sudo() {
  # If
  [[ ${INSTALL_USER} ]] || INSTALL_USER=${USER}
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] Running 'install_sudo' function${RESET}"
  echo -e "${GREEN}[*]${RESET} Now installing 'sudo' package via apt-get, elevating to root..."

  su root
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to su root${RESET}" && exit 1
  apt-get -y install sudo
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to install sudo pkg via apt-get${RESET}" && exit 1
  # Use stored USER value to add our originating user account to the sudoers group
  # TODO: Will this break if script run using sudo? Env var likely will be root if so...test this...
  #usermod -a -G sudo ${ACTUAL_USER}
  usermod -a -G sudo ${INSTALL_USER}
  [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Unable to add original user to sudoers${RESET}" && exit 1

  echo -e "${YELLOW}[WARN] ${RESET}Now logging off to take effect. Restart this script after login!"
  sleep 4
  # First logout command will logout from su root elevation
  logout
  exit 1
}

function check_root() {

  # There is an env var that is $USER. This is regular user if in normal state, root in sudo state
  #   CURRENT_USER=${USER}
  #   ACTUAL_USER=$(env | grep SUDO_USER | cut -d= -f 2)
       # This would only be run if within sudo state
       # This variable serves as the original user when in a sudo state

  if [[ $EUID -ne 0 ]];then
    # If not root, check if sudo package is installed and leverage it
    # TODO: Will this work if current user doesn't have sudo rights, but sudo is already installed?
    if [[ $(dpkg-query -s sudo) ]];then
      export SUDO="sudo"
      # This accounts for both root and sudo. If normal user, it'll use sudo.
      # If you run script as root, $SUDO is blank and script will soldier on.
    else
      echo -e "${YELLOW}[WARN] ${RESET}The 'sudo' package is not installed. Press any key to install it (*must enter sudo password), or cancel now"
      read -r -t 10
      install_sudo
      # TODO: This error check necessary, since the function "install_sudo" exits 1 anyway?
      [[ $? -eq 1 ]] && echo -e "${RED}[ERROR] Please install sudo or run this as root. Exiting.${RESET}" && exit 1
    fi
  fi
}
check_root
## ========================================================================== ##
# ================================[  BEGIN  ]================================ #
$SUDO apt-get -qq update
$SUDO apt-get -y install geany python3-pip
$SUDO apt-get -y install flake8 pycodestyle shellcheck
$SUDO apt-get -y install python3-flake8 python3-pep8-naming
# Use shellcheck with Geany by simply clicking on Build -> Lint and it shows syntax errors


# Unbuntu requires an icon pkg that is not on Kali, nor required
os=$(cat /etc/os-release | grep '^ID=' | cut -d '=' -f2)
if [[ $os == "ubuntu" ]]; then
  $SUDO apt-get -y install yaru-theme-icon
fi


# Plugins - https://github.com/geany/geany-plugins
$SUDO apt-get -y install geany-plugins  # pkg doesn't exist in Kali OS, so run this by itself

if [[ "$?" -ne 0 ]]; then
  echo -e "${GREEN}[*]${RESET} Building geany-plugins from scratch, please wait..."
  # Potential Dependencies for some plugins - if you do a manual make/configure type install
  # Markdown
  cd /opt
  $SUDO git clone https://github.com/geany/geany-plugins
  if [[ "$?" -ne 0 ]]; then
    echo -e "[ERR] Failed to clone geany-plugins, skipping"
  else
    cd geany_plugins
    $SUDO apt-get -y install libwebkit2gtk-4.0-dev
    $SUDO apt-get -y install automake autopoint
    $SUDO ./autogen.sh
    make
    $SUDO make install
  fi
fi

# =============================[ CONFIGURE GEANY ]================================ #
$SUDO timeout 5 geany >/dev/null 2>&1
sleep 3s
filedir="${HOME}/.config/geany"
[[ ! -d "${filedir}" ]] && mkdir -p "${filedir}"
file="${HOME}/.config/geany/geany.conf"
# Geany now only writes its config after a 'clean' quit, so need to handle this condition.
if [[ -e "${file}" ]]; then
  cp -n $file{,.bkup}
  #sed -i 's/^.*editor_font=.*/editor_font=Monospace\ 10/' "${file}"

  # - Pref UI Section: General


  sed -i 's/^beep_on_errors=.*/beep_on_errors=false/' "${file}"
  sed -i 's/^sidebar_pos=.*/sidebar_pos=1/' "${file}"
  sed -i 's/^sidebar_page=.*/sidebar_page=1/' "${file}"
  sed -i 's/^tab_order_beside=.*/tab_order_beside=true/' "${file}"
  sed -i 's/^check_detect_indent=.*/check_detect_indent=true/' "${file}"
  sed -i 's/^detect_indent_width=.*/detect_indent_width=true/' "${file}"
  sed -i 's/^editor_font=.*/editor_font=Fira Code 10/' "${file}"
  sed -i 's/^pref_editor_tab_width=.*/pref_editor_tab_width=4/' "${file}"
  sed -i 's/^indent_type=.*/indent_type=2/' "${file}"
  sed -i 's/^show_indent_guide=.*/show_indent_guide=true/' "${file}"
  sed -i 's/^show_linenumber_margin=.*/show_linenumber_margin=true/' "${file}"
  sed -i 's/^show_markers_margin=.*/show_markers_margin=true/' "${file}"
  sed -i 's/^long_line_enabled=.*/long_line_enabled=true/' "${file}"
  sed -i 's/^line_wrapping=.*/line_wrapping=true/' "${file}"
  sed -i 's/^long_line_column=.*/long_line_column=90/' "${file}"
  sed -i 's/^long_line_color=.*/long_line_color=#C2EBC2/' "${file}"
  sed -i 's/^line_break_column=.*/line_break_column=90/' "${file}"
  sed -i 's/^auto_close_xml_tags=.*/auto_close_xml_tags=true/' "${file}"
  sed -i 's/^auto_complete_symbols=.*/auto_complete_symbols=true/' "${file}"
  sed -i 's/^autocomplete_doc_words=.*/autocomplete_doc_words=true/' "${file}"
  sed -i 's/^completion_drops_rest_of_word=.*/completion_drops_rest_of_word=true/' "${file}"
  sed -i 's/^pref_editor_newline_strip=.*/pref_editor_newline_strip=true/' "${file}"
  sed -i 's/^pref_editor_ensure_convert_line_endings=.*/pref_editor_ensure_convert_line_endings=true/' "${file}"
  sed -i 's/^pref_editor_replace_tabs=.*/pref_editor_replace_tabs=true/' "${file}"
  sed -i 's/^pref_editor_trail_space=.*/pref_editor_trail_space=true/' "${file}"

  # Plugins section of geany.conf
  sed -i 's/^load_plugins=.*/load_plugins=true/' "${file}"
  sed -i 's/^active_plugins=.*/active_plugins=/usr/lib/x86_64-linux-gnu/geany/filebrowser.so;/usr/lib/x86_64-linux-gnu/geany/splitwindow.so;/' "${file}"

  #sed -i 's/^pref_toolbar_append_to_menu=.*/pref_toolbar_append_to_menu=true/' "${file}"
  #sed -i 's/^pref_toolbar_use_gtk_default_style=.*/pref_toolbar_use_gtk_default_style=false/' "${file}"
  #sed -i 's/^pref_toolbar_use_gtk_default_icon=.*/pref_toolbar_use_gtk_default_icon=false/' "${file}"
  #sed -i 's/^pref_toolbar_icon_size=.*/pref_toolbar_icon_size=2/' "${file}"
  #sed -i 's/^treeview_position=.*/treeview_position=744/' "${file}"
  #sed -i 's/^msgwindow_position=.*/msgwindow_position=40/' "${file}"
  #sed -i 's/^pref_search_hide_find_dialog=.*/pref_search_hide_find_dialog=true/' "${file}"

  #pref_template_developer=$YOUR_NAME
  #pref_template_mail=$YOUR_EMAIL
  #pref_template_initial=

  #sed -i 's#^.*project_file_path=.*#project_file_path=/#' "${file}"
  #grep -q '^custom_commands=sort;' "${file}" \
  #  || sed -i 's/\[geany\]/[geany]\ncustom_commands=sort;/' "${file}"
else
  # TODO: Test that this block works under sudo

  # If no file exists, create one in the system default location
  # New users will use this file as part of geany's first-run routine,
  # so putting it here is better than putting in users home folder (think /etc/skel)
  file="/usr/share/geany/geany.conf"
  tmpfile="/tmp/geany.conf"
  #$SUDO touch "${file}" || echo -e "${RED}[ERROR] Failed to create new file${RESET}" && $SUDO echo "" > "${file}"
  cat <<EOF > "${tmpfile}"
[geany]
beep_on_errors=false
check_detect_indent=true
detect_indent_width=true
use_tab_to_indent=true
pref_editor_tab_width=4
tab_order_beside=true
indent_mode=2
# Indent types: 0=spaces only, 1=tabs only, 2=both tabs & spaces
indent_type=2
autocomplete_doc_words=true
autocompletion_max_entries=10
completion_drops_rest_of_word=true
statusbar_template=line: %l / %L     col: %c     sel: %s     %w      %t      %mmode: %M      encoding: %e      filetype: %f      scope: %S
editor_font=Monospace 10
tagbar_font=Sans 9
msgwin_font=Sans 9
tab_pos_sidebar=2
# Sidebar Position: 0=left, 1=right
sidebar_pos=0
tab_pos_editor=2
show_indent_guide=false
show_white_space=false
show_line_endings=false
show_markers_margin=true
show_linenumber_margin=true
long_line_enabled=true
long_line_type=0
long_line_column=90
long_line_color=#1036F3
symbolcompletion_max_height=10
symbolcompletion_min_chars=4
complete_snippets=true
auto_complete_symbols=true
auto_close_xml_tags=true
use_folding=true
line_wrapping=true
line_break_column=90
auto_continue_multiline=true
pref_editor_disable_dnd=false
pref_editor_smart_home_key=true
pref_editor_newline_strip=true
pref_editor_new_line=true
pref_editor_ensure_convert_line_endings=true
pref_editor_replace_tabs=true
pref_editor_trail_space=true
pref_toolbar_show=true
pref_template_version=0.1
pref_template_year=%Y
pref_template_date=%Y-%m-%d
pref_template_datetime=%d.%m.%Y %H:%M:%S %Z
default_eol_character=2

[tools]
terminal_cmd=x-terminal-emulator -e "/bin/sh %c"
browser_cmd=firefox-esr %c
grep_cmd=grep

[plugins]
load_plugins=true
custom_plugin_path=
active_plugins=/usr/lib/x86_64-linux-gnu/geany/filebrowser.so;/usr/lib/x86_64-linux-gnu/geany/splitwindow.so;
EOF

  $SUDO mv "${tmpfile}" "${file}"
  # Files in this dir should be writeable to root, read-only to group and everyone else (0655)
  $SUDO chmod -f 0655 "${file}"
fi


# Build Commands
# File-dependent build commands go in their own file for each filetype
filedir="${HOME}/.config/geany/filedefs"
[[ ! -d "${filedir}" ]] && mkdir -p "${filedir}"
file="${filedir}/filetypes.python"
cat << EOF > "${file}"
[build-menu]
FT_01_LB=Check
FT_01_CM=check_python_code "%f"
FT_01_WD=
error_regex=([^:]+):([0-9]+):([0-9:]+)? .*
FT_00_LB=Py_Compile
FT_00_CM=python3 -m py_compile "%f"
FT_00_WD=
EX_00_LB=_Execute
EX_00_CM=python3 "%f"
EX_00_WD=
EOF
# NOTE: I changed check command from this: FT_01_CM=flake8 --show-source "%f"  over to the helper script (11/20/2021)


# Custom file defs for syntax highlighting tweaks
#cp /usr/share/geany/filedefs/filetypes.sh ${filedir}/
#cp /usr/share/geany/filedefs/filetypes.python ${filedir}/

# TODO: Add this line to ~/.config/geany/filetype_extensions.conf
# Txt=*.txt;*.hlp;*.gny;*.log
# can't simply insert, need to find "^Tcl" and insert a line after it for this
# Create a standard style config for .txt files
file="${filedir}/filetypes.txt"
cat << EOF > "${file}"
[keywords]
primary=Note Warning Syntax Usage Examples Description References Installation

[settings]
extension=txt,log,gny,hlp
lexer_filetype=Python
EOF


# Add custom config for flake8 checking, exclude noisy Error Codes
# Help: https://wiki.geany.org/howtos/check_python_code
file="${HOME}/.config/flake8"
cat << EOF > "${file}"
# E***/W*** Codes are PEP8, F*** codes are PyFlakes,
# N8** codes are pep8-naming, C9** are McCabe complexity plugin
# See: http://pep8.readthedocs.org/en/latest/intro.html#error-codes
# See: https://www.python.org/dev/peps/pep-0008/
[flake8]
ignore = F403,E265,E266,E402
# ==[ Quick Reference of Codes to Disable ]== #
# E265 - block comment should start with a '# '
# E266 - too many leading '#' for block comment
# E402 - module level import not at top of file
# F403 - from module import *’ used; unable to detect undefined names
max-line-length = 90
exclude = tests/*,.git,__pycache
EOF


# check your python code helper script
dir="${HOME}/.local/bin"
file="${dir}/check_python_code"
[[ ! -d "${dir}" ]] && mkdir -p "${dir}"
cat << EOF > "${file}"
#!/bin/sh

#export PYTHONPATH="$PYTHONPATH:\${HOME}/.pylint.d"

echo "======  pycodestyle  ======"
pycodestyle \$1
echo "\n======  pyflakes  ======"
pyflakes \$1
echo "\n======  pylint  ======"
pylint --msg-template="{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}" --reports=n \$1
pylint -f parseable -r n \$1
EOF
chmod u+x "${file}"
echo -e "${GREEN}[*]${RESET} Python code check script helper has been added to ${HOME}/.local/bin/check_python_code"
echo -e "${GREEN}[*]${RESET} Ensure this path is in your PATH so it can be leveraged by Geany"



# Add other files to filetype coloring config
file="${HOME}/.config/geany/filetype_extensions.conf"
[[ ! -f "${file}" ]] && cp "/usr/share/geany/filetype_extensions.conf" "${file}"
sed -i 's/^C=\*\.c;\*\.h.*;/C=*.c;*.h;*.nasl;/' "${file}"
sed -i 's/^Sh=\*\.sh;configure;.*/Sh=*.sh;configure;configure.in;configure.in.in;configure.ac;*.ksh;*.mksh;*.zsh;*.ash;*.bash;*.m4;PKGBUILD;*profile;*.bash*;/' "${file}"

# Geany -> Tools -> Plugin Manger -> Save Actions -> HTML Characters: Enabled. Split Windows: Enabled. Save Actions: Enabled. -> Preferences -> Backup Copy -> Enable -> Directory to save backup files in: /root/Backups/geany/.
#Directory levels to include in the backup destination: 5 -> Apply -> Ok -> Ok
sed -i 's#^.*active_plugins.*#active_plugins=/usr/lib/geany/htmlchars.so;/usr/lib/geany/saveactions.so;/usr/lib/geany/splitwindow.so;#' "${file}"


function enable_geany_backups {
    mkdir -p "${BACKUPS_PATH}"
    mkdir -p "${HOME}/.config/geany/plugins/saveactions"
    file="${HOME}/.config/geany/plugins/saveactions/saveactions.conf"
    [[ -e "${file}" ]] && cp -n $file{,.bkup}
    cat <<EOF > "${file}"
[saveactions]
enable_autosave=false
enable_instantsave=false
enable_backupcopy=true

[autosave]
print_messages=false
save_all=false
interval=300

[instantsave]
default_ft=None

[backupcopy]
dir_levels=5
time_fmt=%Y-%m-%d-%H-%M-%S
backup_dir=${BACKUPS_PATH}
EOF
}

enable_geany_backups


function fix_invisible_underscores() {
    # Geany introduced a weird bug where the default installation often ends up
    # so that underscores become invisible to eye. They are there, but blend in
    # with a white background. See: https://www.geany.org/documentation/faq/
    # Affects Geany versions prior to 1.37 (fixed in 1.37)
    # Get installed geany version output : "1.37"
    GEANY_VERSION=$(dpkg -s geany | grep -i version | cut -d ':' -f 2 | cut -d "." -f 1-2 | xargs echo)

    # fix by changing line height to add a little space above and below
    # problem is, this file doesn't exist until you open and edit from GUI
    # Tools -> Configuration Files -> filetypes.common
    # note: looks like we can copy it from usr share instead.
    #   [styling]
    #   line_height=1;1;
    file="${HOME}/.config/geany/filedefs/filetypes.common"
    cp /usr/share/geany/filedefs/filetypes.common "${file}"
    sed -i 's/^#~ line_height=0;0;/line_height=1;1;/' "${file}"
}
#fix_invisible_underscores



function geany_templates() {
    if [[ -d "${GEANY_TEMPLATES}" ]]; then
        GEANY_INSTALLED_TEMPLATES_DIR="${HOME}/.config/geany/templates/files"
        [[ ! -d "${GEANY_INSTALLED_TEMPLATES_DIR}" ]] && mkdir -p "${GEANY_INSTALLED_TEMPLATES_DIR}"
        cp -ur "${GEANY_TEMPLATES}"/* "${GEANY_INSTALLED_TEMPLATES_DIR}/"
        echo -e "${GREEN}[*]${RESET} Geany File Templates have been copied over, enjoy!"
    fi
}
# Copy over our custom code template files
geany_templates


echo -e "${GREEN}[*]${RESET} Installing custom Geany color themes"
cd /tmp
wget https://github.com/geany/geany-themes/archive/master.zip
unzip master.zip
cd geany-themes-master
./install.sh
cd ~


# Copy desktop shortcut to the desktop, unless we are on a remote server w/o a desktop
if [[ -d "${HOME}/Desktop" ]]; then
  file="${HOME}/Desktop/geany.desktop"
  [[ ! -f "${file}" ]] && \
    cp /usr/share/applications/geany.desktop "${HOME}/Desktop/" 2>/dev/null
  chmod u+x "${file}" 2>/dev/null
fi

echo -e "\n${GREEN}[*]${RESET} ${BOLD}NOTE:${RESET} If underscore characters are invisible, change font or adjust line height"
echo -e "${GREEN}[*]${RESET} Geany themes installed. Choose a theme from View -> Choose Color Theme"


function finish() {
  ###
  # finish function: Any script-termination routines go here, but function cannot be empty
  #
  ###
  #clear
  [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] :: function finish :: Script complete${RESET}"
  FINISH_TIME=$(date +%s)
  echo -e "${GREEN}[*] Penbuilder Setup :: $APP_NAME :: Completed Successfully ${YELLOW} --(Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes)--\n${RESET}"
  echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..."
  [[ "$DEBUG" = true ]] && echo -e "${GREEN}[$(date +"%F %T")] ${RESET}App Shutting down, please wait..." >> "${LOG_FILE}"
}
# End of script
trap finish EXIT

exit 0
## ===================================================================================== ##

## =====================[   Geany Plugins   ]======================= ##
# Install Plugins: https://plugins.geany.org/install.html
#
#
#   Addons            Collection of small utility helpers, Copy URI, bookmark list,
#                     task list, word highlight
#
#   Auto-Close        Auto close for code brackers and quotes
#
#   Code Navigation   Facilitates navigation across source files
#
#   Djynn             A PM type plugin, can sort lines, comments, keybindings, addtl settings
#
#
#
#   LaTeX Wizard      Generate latex files from an open file. Not easy to use.
#                     Tips: https://www.dedoimedo.com/computers/latex-lyx-tips.html



## ===================================================================================== ##
