#!/bin/bash
## =============================================================================
# File:     setup-gnome.sh
#
# Author:   Cashiuus
# Created:  11/27/2015  - Revised:  01/30/2016
#
# Purpose:  Configure GNOME settings on fresh Kali 2.x install
#
## =============================================================================
__version__="0.3"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
# SYSTEM-WIDE:  /usr/share/gnome-shell/extensions/
# PER-USER:     ${HOME}/.local/share/gnome-shell/extensions/
EXTENSION_PATH="/usr/share/gnome-shell/extensions"

# =============================[      ]================================ #
# Disable idle timeout to screensaver
gsettings set org.gnome.desktop.session idle-delay 0

# =========== [ Disable Package Updater Notifications ] =============== #
if [[ $(which gnome-shell) ]]; then
    # Disable notification package updater
    echo -e "\n${GREEN}[*]${RESET} Disabling notification ${GREEN}package updater${RESET} service"
    export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
    dconf write /org/gnome/settings-daemon/plugins/updates/active false
    dconf write /org/gnome/desktop/notifications/application/gpk-update-viewer/active false
    timeout 5 killall -w /usr/lib/apt/methods/http >/dev/null 2>&1
else
  USING_GNOME=0
fi

# ====[ Nautilus ]==== #
gsettings set org.gnome.nautilus.desktop home-icon-visible true                   # Default: false
gsettings set org.gnome.nautilus.desktop font "'Cantrell 9'"                      # Default: <blank>
gsettings set org.gnome.nautilus.preferences show-hidden-files true               # Default: false
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'    # Default: icon-view
gsettings set org.gnome.nautilus.preferences enable-recursive-search false        # Default: true
#gsettings set org.gnome.nautilus.icon-view thumbnail-size                        # Default: 64
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small'             # Default: 'standard'

gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'type', 'date_modified']"
gsettings set org.gnome.nautilus.list-view default-column-order "['name', 'date_modified', 'size', 'type']"
gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'             # Default: 'small'
gsettings set org.gnome.nautilus.list-view use-tree-view true                     # Default: false
gsettings set org.gnome.nautilus.preferences sort-directories-first true          # Default: false
gsettings set org.gnome.nautilus.window-state sidebar-width 188                   # Default: 188
gsettings set org.gnome.nautilus.window-state start-with-sidebar true             # Default: true
gsettings set org.gnome.nautilus.window-state maximized false                     # Default: false

# ====[ Gedit ]==== #
gsettings set org.gnome.gedit.preferences.editor display-line-numbers true
gsettings set org.gnome.gedit.preferences.editor editor-font "'Monospace 10'"
gsettings set org.gnome.gedit.preferences.editor insert-spaces true
gsettings set org.gnome.gedit.preferences.editor right-margin-position 90
gsettings set org.gnome.gedit.preferences.editor tabs-size 4                      # Default: uint32 8
gsettings set org.gnome.gedit.preferences.editor create-backup-copy false
gsettings set org.gnome.gedit.preferences.editor auto-save false
gsettings set org.gnome.gedit.preferences.editor scheme 'classic'
gsettings set org.gnome.gedit.preferences.editor ensure-trailing-newline true
gsettings set org.gnome.gedit.preferences.editor auto-indent true                 # Default: false
gsettings set org.gnome.gedit.preferences.editor syntax-highlighting true
gsettings set org.gnome.gedit.preferences.ui bottom-panel-visible true            # Default: false
gsettings set org.gnome.gedit.preferences.ui toolbar-visible true
gsettings set org.gnome.gedit.state.window side-panel-size 150                    # Default: 200



# ========================== [ 3rd Party Extensions ] =============================== #
echo -e "\n${GREEN}[*]${RESET} Configuring 3rd Party GNOME Extensions..."
[[ ! -d "/usr/share/gnome-shell/extensions/" ]] && mkdir -p "/usr/share/gnome-shell/extensions/"

# ====[ Ext: TaskBar ]==== #
if [[ ! -d "/usr/share/gnome-shell/extensions/TaskBar@zpydr/" ]]; then
  git clone -q https://github.com/zpydr/gnome-shell-extension-taskbar.git /usr/share/gnome-shell/extensions/TaskBar@zpydr/
fi

# ====[ Ext: Frippery ]==== #
function enable_frippery() {
  #mkdir -p ~/.local/share/gnome-shell/extensions/
  # GNOME 3.14 -> frippery-0.9.5
  #FRIPPERY_VERSION="gnome-shell-frippery-0.9.5.tgz"
  # GNOME 3.18 -> frippery-3.18.2
  FRIPPERY_VERSION="gnome-shell-frippery-3.18.2.tgz"
  timeout 300 curl --progress -k -L -f "http://frippery.org/extensions/${FRIPPERY_VERSION}" > /tmp/frippery.tgz
  tar -zxf /tmp/frippery.tgz -C ~/
}
enable_frippery

# ====[ Ext: Icon Hider ]==== #
function enable_icon_hider() {
  filedir="/usr/share/gnome-shell/extensions/icon-hider@kalnitsky.org/"
  if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    git clone -q https://github.com/ikalnitsky/gnome-shell-extension-icon-hider.git /usr/share/gnome-shell/extensions/icon-hider@kalnitsky.org/
  fi
}
enable_icon_hider

# ====[ Ext: Drop-Down-Terminal ]==== #
function enable_ext_dropdown_terminal() {
  # Ext: https://extensions.gnome.org/extension/442/drop-down-terminal/
  # Default toggle shortcut: ~ (key above left tab)
  # ALT + ~   Cycle between applications
  filedir="/usr/share/gnome-shell/extensions/show-ip@sgaraud.github.com"
  if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    git clone https://github.com/zzrough/gs-extensions-drop-down-terminal /usr/share/gnome-shell/extensions/drop-down-terminal@gs-extensions.zzrough.org
  fi
}

#function enable_ext_show_ip() {
  # Ext: https://extensions.gnome.org/extension/941/show-ip/
  filedir="/usr/share/gnome-shell/extensions/show-ip@sgaraud.github.com"
  if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    /usr/share/gnome-shell/extensions/show-ip@sgaraud.github.com

#}


#function enable_skype_ext() {
  # Ext: https://extensions.gnome.org/extension/696/skype-integration/
  # Git: https://github.com/chrisss404/gnome-shell-ext-SkypeNotification
#}

function enable_extensions() {
  # TODO: "Removable drive menu" , "drop-down-terminal" , "Workspaces-to-dock"
  # Removed from below list: "Panel_Favorites@rmy.pobox.com"
  for EXTENSION in "alternate-tab@gnome-shell-extensions.gcampax.github.com" "drive-menu@gnome-shell-extensions.gcampax.github.com" "TaskBar@zpydr" "Bottom_Panel@rmy.pobox.com" "Move_Clock@rmy.pobox.com" "icon-hider@kalnitsky.org"; do
    GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed 's_^.\(.*\).$_\1_')
    echo "${GNOME_EXTENSIONS}" | grep -q "${EXTENSION}" || gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}, '${EXTENSION}']"
  done

  for EXTENSION in "dash-to-dock@micxgx.gmail.com" "workspace-indicator@gnome-shell-extensions.gcampax.github.com"; do
    GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed "s_^.\(.*\).\$_\1_; s_, '${EXTENSION}'__")
    gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}]"
  done
}
enable_extensions


# ====[ Ext: Dash-to-Dock settings ]==== #
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true        # Set dock to use full height
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'      # Set dock to the right
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true           # Set dock always visible

# ====[ Ext: TaskBar (Global) ]==== #
# Schema: https://github.com/zpydr/gnome-shell-extension-taskbar/blob/master/schemas/org.gnome.shell.extensions.TaskBar.gschema.xml
dconf write /org/gnome/shell/extensions/TaskBar/first-start false
dconf write /org/gnome/shell/extensions/TaskBar/bottom-panel true
dconf write /org/gnome/shell/extensions/TaskBar/bottom-panel-original-background-color "'rgba(57,59,63,0.49647887323943662)'"
dconf write /org/gnome/shell/extensions/TaskBar/display-favorites true
dconf write /org/gnome/shell/extensions/TaskBar/position-desktop-button 0
dconf write /org/gnome/shell/extensions/TaskBar/position-favorites 1
dconf write /org/gnome/shell/extensions/TaskBar/position-appview-button 2
dconf write /org/gnome/shell/extensions/TaskBar/position-workspace-button 3
dconf write /org/gnome/shell/extensions/TaskBar/position-tasks 4
dconf write /org/gnome/shell/extensions/TaskBar/position-max-right 4
dconf write /org/gnome/shell/extensions/TaskBar/position-bottom-box 0           # 0=left, 1=center, 2=right
dconf write /org/gnome/shell/extensions/TaskBar/icon-size-bottom 27             # Default: 22, bottom panel height
dconf write /org/gnome/shell/extensions/TaskBar/scroll-workspaces "'standard'"  # Default: 'standard', choices: 'off', 'invert'
# Separators between groups - true or false
dconf write /org/gnome/shell/extensions/TaskBar/separator-two true
dconf write /org/gnome/shell/extensions/TaskBar/separator-three true
dconf write /org/gnome/shell/extensions/TaskBar/separator-four true
dconf write /org/gnome/shell/extensions/TaskBar/separator-five true
# Space between each grouping on left and right sides
dconf write /org/gnome/shell/extensions/TaskBar/separator-left-appview 5
dconf write /org/gnome/shell/extensions/TaskBar/separator-right-appview 0
dconf write /org/gnome/shell/extensions/TaskBar/separator-left-box-main 5
dconf write /org/gnome/shell/extensions/TaskBar/separator-right-box-main 0
dconf write /org/gnome/shell/extensions/TaskBar/separator-left-desktop 5
dconf write /org/gnome/shell/extensions/TaskBar/separator-right-desktop 10
dconf write /org/gnome/shell/extensions/TaskBar/separator-left-favorites 0
dconf write /org/gnome/shell/extensions/TaskBar/separator-right-favorites 0
dconf write /org/gnome/shell/extensions/TaskBar/separator-left-tasks 5
dconf write /org/gnome/shell/extensions/TaskBar/separator-right-tasks 0
dconf write /org/gnome/shell/extensions/TaskBar/separator-left-workspaces 20
dconf write /org/gnome/shell/extensions/TaskBar/separator-right-workspaces 20

dconf write /org/gnome/shell/extensions/TaskBar/appview-button-icon "'/usr/share/gnome-shell/extensions/TaskBar@zpydr/images/appview-button-default.svg'"
dconf write /org/gnome/shell/extensions/TaskBar/desktop-button-icon "'/usr/share/gnome-shell/extensions/TaskBar@zpydr/images/desktop-button-default.png'"
dconf write /org/gnome/shell/extensions/TaskBar/tray-button-icon "'/usr/share/gnome-shell/extensions/TaskBar@zpydr/images/bottom-panel-tray-button.svg'"




function install_extension_showip() {
  # Reference: http://bernaerts.dyndns.org/linux/76-gnome/283-gnome-shell-install-extension-command-line-script
  # Another method for installing GNOME extensions
  # 1. Get extension ID
  GNOME_VERSION='3.18'
  # TODO: Get this ID dynamically?
  EXTENSION_ID='941'
  # 2. Get extension description for the download URL & UUID
  wget --header='Accept-Encoding:none' -O /tmp/extension.txt "https://extensions.gnome.org/extension-info/?pk=${EXTENSION_ID}&shell_version=${GNOME_VERSION}"

  # 3. Download the extension into our desired path

  # 4. Enable extension in gsettings if not already enabled

}





# ==============================[ GNOME Core Settings ]====================================== #
# Disable tracker service
gsettings set org.freedesktop.Tracker.Miner.Files crawling-interval -2
gsettings set org.freedesktop.Tracker.Miner.Files enable-monitors false

# TODO: Modify the default "favorite apps"
gsettings set org.gnome.shell favorite-apps "['iceweasel.desktop', 'gnome-terminal.desktop', 'org.gnome.Nautilus.desktop', 'kali-burpsuite.desktop', 'kali-armitage.desktop', 'kali-msfconsole.desktop', 'kali-maltego.desktop', 'kali-beef.desktop', 'kali-faraday.desktop', 'geany.desktop']"

# ====[ GNOME Desktop Settings ]==== #
gsettings set org.gnome.desktop.background show-desktop-icons true
gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false
gsettings set org.gnome.desktop.wm.preferences titlebar-font "'Droid Bold 10'"    # Default: 'Cantarell Bold 11'

# Workspaces
gsettings set org.gnome.shell.overrides dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 3
# Top bar
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.datetime automatic-timezone true
gsettings set org.gnome.desktop.interface clock-format '12h'                      # Default: 24h
gsettings set org.gnome.desktop.interface toolbar-icons-size 'small'              # Default: 'large'

# Privacy
gsettings set org.gnome.desktop.privacy hide-identity true                        # Default: false




function finish {
  # Any script-termination routines go here
  rm -f /tmp/extension.txt
  rm -f /tmp/extension.zip

  clear
  gnome-shell --replace &
}
# End of script
trap finish EXIT

# ===============================[ GNOME Executables ]=============================== #
# gnome-help                  Get a GUI help menu to learn more about gnome
# gnome-control-center
# gnome-disk-image-mounter
# gnome-disks
# gnome-screenshot
# gnome-shell-extension-prefs
# gnome-shell-extension-tool
# gnome-system-log
# gnome-system-monitor
# gnome-terminal
# gnome-text-editor
# gnome-tweak-tool
# gnome-www-browser
#
# ===============================[ GNOME Tips & Help ]=============================== #
# Get version info
#dpkg -l gnome-shell            # e.g. 3.18.1-1

# ==========[ GNOME Extensions ]=============
# Help: http://bernaerts.dyndns.org/linux/76-gnome/283-gnome-shell-install-extension-command-line-script
#
# GNOME Extensions will reside in one of two paths:
#     SYSTEM-WIDE:  /usr/share/gnome-shell/extensions/
#     PER-USER:     ${HOME}/.local/share/gnome-shell/extensions/
#
# Get extension info directly from site using this URI structure (JSON response):
#     https://extensions.gnome.org/extension-info/?pk=extension-id&shell_version=gnome-shell-version
# Ex: https://extensions.gnome.org/extension-info/?pk=112&shell_version=3.4
#
# The json response will contain: "download_url": "/download-extension/removeaccesibility@lomegor.shell-extension.zip?version_tag=2847",
# Use that to download the extension and install it, like below:
# wget -O /tmp/extension.zip "https:extensions.gnome.org/download-extension/removeaccesibility@lomegor.shell-extension.zip?version_tag=2847"
# mkdir -p "/usr/share/gnome-shell/extensions/removeaccesibility@lomegor"
# unzip /tmp/extension.zip -d "/usr/share/gnome-shell/extensions/removeaccesibility@lomegor"





# Kali 2016 Default Enabled Extensions (via: gsettings get org.gnome.shell enabled-extensions)
# ['apps-menu@gnome-shell-extensions.gcampax.github.com', 'places-menu@gnome-shell-extensions.gcampax.github.com', 'workspace-indicator@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com', 'ProxySwitcher@flannaghan.com', 'EasyScreenCast@iacopodeenosee.gmail.com', 'refresh-wifi@kgshank.net', 'user-theme@gnome-shell-extensions.gcampax.github.com']

# Kali 2016 Default Favorites (via: gsettings get org.gnome.shell favorite-apps)
# ['iceweasel.desktop', 'gnome-terminal.desktop', 'org.gnome.Nautilus.desktop', 'kali-msfconsole.desktop', 'kali-armitage.desktop', 'kali-burpsuite.desktop', 'kali-maltego.desktop', 'kali-beef.desktop', 'kali-faraday.desktop', 'leafpad.desktop', 'gnome-tweak-tool.desktop']
