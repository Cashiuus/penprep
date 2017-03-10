#!/usr/bin/env bash
## =======================================================================================
# File:     setup-geany.sh
#
# Author:   Cashiuus
# Created:  10-Oct-2015     Revised:  09-Mar-2017
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Configure Geany settings on fresh linux install
#
#
#-[ Notes ]-------------------------------------------------------------------------------
#
#
#   TODO:
#       - App shortcut is at: /usr/share/applications/geany.desktop, add to favorites?
#
#-[ Links/Credit ]------------------------------------------------------------------------
#
#
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="1.5"
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
BACKUPS_DIR="${HOME}/Backups/geany"
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
$SUDO apt-get -y install python-pip geany
$SUDO pip install flake8 pep8-naming

if [[ $(dconf read /org/gnome/gnome-panel/layout/object-id-list) ]]; then
    # NOTE: Debian 8 default install has no "gnome-panel" key folder
    # Skipping the 'else' clause for now because if the key isn't there, writing fails

    [[ "$DEBUG" = true ]] && echo -e "${ORANGE}[DEBUG] gnome-panel object-id-list exists, modifying...${RESET}"

    $SUDO dconf load /org/gnome/gnome-panel/layout/objects/geany/ << EOF
[instance-config]
location='/usr/share/applications/geany.desktop'

[/]
object-iid='PanelInternalFactory::Launcher'
pack-index=3
pack-type='start'
toplevel-id='top-panel'
EOF

    $SUDO dconf write /org/gnome/gnome-panel/layout/object-id-list "$($SUDO dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'geany']/")"

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
    sed -i 's/^.*editor_font=.*/editor_font=Monospace\ 10/' "${file}"
    sed -i 's/^.*sidebar_pos=.*/sidebar_pos=1/' "${file}"
    sed -i 's/^.*check_detect_indent=.*/check_detect_indent=true/' "${file}"
    sed -i 's/^.*detect_indent_width=.*/detect_indent_width=true/' "${file}"
    sed -i 's/^.*pref_editor_tab_width=.*/pref_editor_tab_width=4/' "${file}"       # Python encourages width: 4
    sed -i 's/^.*indent_type=.*/indent_type=2/' "${file}"
    sed -i 's/^.*autocomplete_doc_words=.*/autocomplete_doc_words=true/' "${file}"
    sed -i 's/^.*completion_drops_rest_of_word=.*/completion_drops_rest_of_word=true/' "${file}"
    sed -i 's/^.*tab_order_beside=.*/tab_order_beside=true/' "${file}"
    sed -i 's/^.*show_indent_guide=.*/show_indent_guide=true/' "${file}"
    sed -i 's/^.*long_line_column=.*/long_line_column=90/' "${file}"                # Originally 72, g0tmi1k uses 48
    sed -i 's/^.*line_wrapping=.*/line_wrapping=true/' "${file}"
    sed -i 's/^.*line_break_column=.*/line_break_column=90/' "${file}"
    sed -i 's/^.*pref_editor_newline_strip=.*/pref_editor_newline_strip=true/' "${file}"
    sed -i 's/^.*pref_editor_ensure_convert_line_endings=.*/pref_editor_ensure_convert_line_endings=true/' "${file}"
    sed -i 's/^.*pref_editor_replace_tabs=.*/pref_editor_replace_tabs=true/' "${file}"
    sed -i 's/^.*pref_editor_trail_space=.*/pref_editor_trail_space=true/' "${file}"
    sed -i 's/^.*pref_toolbar_append_to_menu=.*/pref_toolbar_append_to_menu=true/' "${file}"
    sed -i 's/^.*pref_toolbar_use_gtk_default_style=.*/pref_toolbar_use_gtk_default_style=false/' "${file}"
    sed -i 's/^.*pref_toolbar_use_gtk_default_icon=.*/pref_toolbar_use_gtk_default_icon=false/' "${file}"
    sed -i 's/^.*pref_toolbar_icon_size=.*/pref_toolbar_icon_size=2/' "${file}"
    sed -i 's/^.*treeview_position=.*/treeview_position=744/' "${file}"
    sed -i 's/^.*msgwindow_position=.*/msgwindow_position=405/' "${file}"
    sed -i 's/^.*pref_search_hide_find_dialog=.*/pref_search_hide_find_dialog=true/' "${file}"

    #pref_template_developer=
    #pref_template_mail=
    #pref_template_initial=

    #sed -i 's#^.*project_file_path=.*#project_file_path=/root/#' "${file}"
    #grep -q '^custom_commands=sort;' "${file}" || sed -i 's/\[geany\]/[geany]\ncustom_commands=sort;/' "${file}"
else
    # TODO: Change this so that it works under sudo as well.

    # If no file exists, create one in the system default location
    # New users will use this file as part of geany's first-run routine,
    # so putting it here is better than putting in users home folder (think /etc/skel)
    file="/usr/share/geany/geany.conf"
    cd /usr/share/geany
    [[ $? -ne 0 ]] && echo -e "${RED}[ERROR] Geany package not installed. Check problem and try again${RESET}" && exit 1
    $SUDO touch "${file}" || echo -e "${RED}[ERROR] Failed to create new file${RESET}" && echo "" > "${file}"
    cat << EOF > "${file}"
[geany]
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
msgwindow_position=405
treeview_position=744
tab_pos_sidebar=2
# Sidebar Position: 0=left, 1=right
sidebar_pos=1
tab_pos_editor=2
show_indent_guide=false
show_white_space=false
show_line_endings=false
show_markers_margin=true
show_linenumber_margin=true
long_line_enabled=true
long_line_type=0
long_line_column=99
long_line_color=#1036F3
symbolcompletion_max_height=10
symbolcompletion_min_chars=4
complete_snippets=true
auto_complete_symbols=true
auto_close_xml_tags=true
use_folding=true
line_wrapping=true
line_break_column=99
auto_continue_multiline=true
pref_editor_disable_dnd=false
pref_editor_smart_home_key=true
pref_editor_newline_strip=true
pref_editor_new_line=true
pref_editor_ensure_convert_line_endings=true
pref_editor_replace_tabs=true
pref_editor_trail_space=true
pref_toolbar_show=true
pref_toolbar_append_to_menu=true
pref_toolbar_use_gtk_default_style=false
pref_toolbar_use_gtk_default_icon=false
pref_toolbar_icon_style=0
pref_toolbar_icon_size=2
pref_template_version=0.1
pref_template_year=%Y
pref_template_date=%Y-%m-%d
pref_template_datetime=%d.%m.%Y %H:%M:%S %Z
default_eol_character=2

[tools]
terminal_cmd=x-terminal-emulator -e "/bin/sh %c"
browser_cmd=sensible-browser
grep_cmd=grep

EOF
fi

# Build Commands
# File-dependent build commands go in their own file for each filetype
filedir="${HOME}/.config/geany/filedefs"
[[ ! -d "${filedir}" ]] && mkdir -p "${filedir}"
file="${filedir}/filetypes.python"
cat << EOF > "${file}"
[build-menu]
FT_01_LB=Check
FT_01_CM=flake8 --show-source "%f"
FT_01_WD=
error_regex=([^:]+):([0-9]+):([0-9:]+)? .*
FT_00_LB=Py_Compile
FT_00_CM=python -m py_compile "%f"
FT_00_WD=
EOF

# Add custom config for flake8 checking, exclude noisy Error Codes
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

# Add other files to filetype coloring config
file="${HOME}/.config/geany/filetype_extensions.conf"
[[ ! -f "${file}" ]] && cp "/usr/share/geany/filetype_extensions.conf" "${file}"
sed -i 's/^C=\*\.c;\*\.h.*;/C=*.c;*.h;*.nasl;/' "${file}"
sed -i 's/^Sh=\*\.sh;configure;.*/Sh=*.sh;configure;configure.in;configure.in.in;configure.ac;*.ksh;*.mksh;*.zsh;*.ash;*.bash;*.m4;PKGBUILD;*profile;*.bash*;/' "${file}"

# Geany -> Tools -> Plugin Manger -> Save Actions -> HTML Characters: Enabled. Split Windows: Enabled. Save Actions: Enabled. -> Preferences -> Backup Copy -> Enable -> Directory to save backup files in: /root/Backups/geany/.
#Directory levels to include in the backup destination: 5 -> Apply -> Ok -> Ok
$SUDO sed -i 's#^.*active_plugins.*#active_plugins=/usr/lib/geany/htmlchars.so;/usr/lib/geany/saveactions.so;/usr/lib/geany/splitwindow.so;#' "${file}"


function enable_geany_backups {
    mkdir -p "${BACKUPS_DIR}"
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
backup_dir=${BACKUPS_DIR}
EOF
}

enable_geany_backups


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

exit 0
