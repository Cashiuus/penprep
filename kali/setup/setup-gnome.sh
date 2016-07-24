#!/bin/bash
## =============================================================================
# File:     setup-gnome.sh
#
# Author:   Cashiuus
# Created:  11/27/2015  - Revised:  23-JUL-2016
#
# Purpose:  Configure GNOME settings on fresh Kali 2016.1 install
#
## =============================================================================
__version__="1.0"
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
echo -e "${GREEN}[*] ${PURPLE}[penprep]${RESET} Beginning GNOME Setup, please wait..."
apt-get -qq update
apt-get -y install gconf-editor

# Disable idle timeout to screensaver
xset s 0 0
xset s off
gsettings set org.gnome.desktop.session idle-delay 0

# ===[ RAM check ]=== #
if [[ "$(free -m | grep -i Mem | awk '{print $2}')" < 2048 ]]; then
  echo -e "\n${RED}[!] ${RED}You have 2GB or less RAM and you're using GNOME${RESET}"
  echo -e "${YELLOW}[i]${RESET} ${YELLOW}Might want to use XFCE instead${RESET}..."
  sleep 15s
fi

# ===[ Disable notification package updater ]=== #
if [[ $(which gnome-shell) ]]; then
  echo -e "\n\n${GREEN}[*]${RESET} Disabling notification ${GREEN}package updater${RESET} service"
  export DISPLAY=:0.0
  dconf write /org/gnome/settings-daemon/plugins/updates/active false
  dconf write /org/gnome/desktop/notifications/application/gpk-update-viewer/active false
  timeout 5 killall -w /usr/lib/apt/methods/http >/dev/null 2>&1
else
  USING_GNOME=0
fi


# ====[ Nautilus ]==== #
echo -e "${GREEN}[*]${RESET} Configuring Nautilus gsettings"
gsettings set org.gnome.nautilus.desktop home-icon-visible true                   # Default: false
gsettings set org.gnome.nautilus.desktop font "'Cantrell 9'"                      # Default: <blank>
gsettings set org.gnome.nautilus.preferences show-hidden-files true               # Default: false
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'    # Default: icon-view

# No such key as of July 23, 2016
#gsettings set org.gnome.nautilus.preferences enable-recursive-search false        # Default: true

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
echo -e "${GREEN}[*]${RESET} Configuring Gedit gsettings"
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

# ====[ Configure - Default GNOME Terminal ]==== #
gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_type transparent
gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_darkness 0.97



# ==============================[ GNOME Core Settings ]====================================== #
echo -e "${GREEN}[*]${RESET} Configuring GNOME core gsettings"

# Disable tracker service
gsettings set org.freedesktop.Tracker.Miner.Files crawling-interval -2
gsettings set org.freedesktop.Tracker.Miner.Files enable-monitors false

# Modify the default "favorite apps"
gsettings set org.gnome.shell favorite-apps \
    "['gnome-terminal.desktop', 'org.gnome.Nautilus.desktop', 'firefox-esr.desktop', 'kali-burpsuite.desktop', 'kali-armitage.desktop', 'kali-msfconsole.desktop', 'kali-maltego.desktop', 'kali-beef.desktop', 'kali-faraday.desktop', 'geany.desktop']"

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


# ========================== [ 3rd Party Extensions ] =============================== #
echo -e "\n${GREEN}[*]${RESET} Configuring 3rd Party GNOME Extensions..."

[[ ! -d "/usr/share/gnome-shell/extensions/" ]] && mkdir -p "/usr/share/gnome-shell/extensions"

# ====[ Ext: TaskBar ]==== #
if [[ ! -d "/usr/share/gnome-shell/extensions/TaskBar@zpydr/" ]]; then
  echo -e "${GREEN}[*]${RESET} Installing GNOME Extension: ${BLUE}TaskBar${RESET}"
  git clone -q https://github.com/zpydr/gnome-shell-extension-taskbar.git /usr/share/gnome-shell/extensions/TaskBar@zpydr/
fi

# ====[ Ext: Frippery ]==== #
function enable_frippery() {
  echo -e "${GREEN}[*]${RESET} Installing GNOME Extension: ${BLUE}Frippery${RESET}"
  #mkdir -p ~/.local/share/gnome-shell/extensions/
  # GNOME 3.14 -> frippery-0.9.5
  #FRIPPERY_VERSION="gnome-shell-frippery-0.9.5.tgz"
  # GNOME 3.18 -> frippery-3.18.2
  FRIPPERY_VERSION="gnome-shell-frippery-3.18.2.tgz"
  timeout 300 curl --progress -k -L -f "http://frippery.org/extensions/${FRIPPERY_VERSION}" > /tmp/frippery.tgz
  tar -zxf /tmp/frippery.tgz -C ~/
}


# ====[ Ext: Icon Hider ]==== #
function enable_icon_hider() {
  echo -e "${GREEN}[*]${RESET} Installing GNOME Extension: ${BLUE}Icon Hider${RESET}"
  filedir="/usr/share/gnome-shell/extensions/icon-hider@kalnitsky.org/"
  if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    git clone -q https://github.com/ikalnitsky/gnome-shell-extension-icon-hider.git /usr/share/gnome-shell/extensions/icon-hider@kalnitsky.org/
  fi
}



# ====[ Ext: Drop-Down-Terminal ]==== #
function enable_ext_dropdown_terminal() {
  # Ext: https://extensions.gnome.org/extension/442/drop-down-terminal/
  # Default toggle shortcut: ~ (key above left tab)
  # ALT + ~   Cycle between applications
  echo -e "${GREEN}[*]${RESET} Installing GNOME Extension: ${BLUE}Drop-Down-Terminal${RESET} (Tap ~ to toggle)"
  filedir="/usr/share/gnome-shell/extensions/drop-down-terminal@gs-extensions.zzrough.org"
  if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    git clone https://github.com/zzrough/gs-extensions-drop-down-terminal /usr/share/gnome-shell/extensions/drop-down-terminal@gs-extensions.zzrough.org
  fi
}


function enable_ext_show_ip() {
  # Ext: https://extensions.gnome.org/extension/941/show-ip/
  echo -e "${GREEN}[*]${RESET} Installing GNOME Extension: ${BLUE}Show-IP${RESET}"
  filedir="/usr/share/gnome-shell/extensions/show-ip@sgaraud.github.com"
  if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    git clone https://github.com/sgaraud/gnome-extension-show-ip "${filedir}"
  fi
}


function install_gnome_extension() {
  # Usage: install_gnome_extension <ID>

  # Reference: http://bernaerts.dyndns.org/linux/76-gnome/283-gnome-shell-install-extension-command-line-script
  # Another method for installing GNOME extensions
  # 1. Get extension ID
  GNOME_VERSION='3.18'
  #EXTENSION_ID='941'
  EXTENSION_ID=$1

  GNOME_SITE="https://extensions.gnome.org"
  # 2. Get extension description for the download URL & UUID
  wget --header='Accept-Encoding:none' -O /tmp/extension.txt "https://extensions.gnome.org/extension-info/?pk=${EXTENSION_ID}&shell_version=${GNOME_VERSION}"

  EXTENSION_UUID=$(cat /tmp/extension.txt | grep "uuid" | sed 's/^.*uuid[\": ]*\([^\"]*\).*$/\1/')
  EXTENSION_URL=$(cat /tmp/extension.txt | grep "download_url" | sed 's/^.*download_url[\": ]*\([^\"]*\).*$/\1/')

  echo -e "${GREEN}[*]${RESET} Installing Extension ${BLUE}${EXTENSION_UUID}${RESET} by retrieving from portal"

  # 3. Download the extension into our desired path
  if [[ "$EXTENSION_URL" != "" ]]; then
    wget --header='Accept-Encoding:none' -O /tmp/extension.zip "${GNOME_SITE}${EXTENSION_URL}"
    mkdir -p "${EXTENSION_PATH}/${EXTENSION_UUID}"
    unzip /tmp/extension.zip -d "${EXTENSION_PATH}/${EXTENSION_UUID}"


    # 4. Enable extension in gsettings if not already enabled
    # check if extension is already enabled
    EXTENSION_LIST=$(gsettings get org.gnome.shell enabled-extensions | sed 's/^.\(.*\).$/\1/')
    EXTENSION_ENABLED=$(echo ${EXTENSION_LIST} | grep ${EXTENSION_UUID})
    if [[ "$EXTENSION_ENABLED" = "" ]]; then
      # enable extension
      gsettings set org.gnome.shell enabled-extensions "[${EXTENSION_LIST},'${EXTENSION_UUID}']"
      echo "Extension with ID ${EXTENSION_ID} has been enabled. Restart Gnome Shell to take effect."

      # Not a valid dconf on first run
      #dconf write /org/gnome/shell/extensions/show-ip/last-device 'eth0'
      dconf write /org/gnome/shell/extensions/show-ip/public false
    fi
  else
    # extension is not available
    echo "Extension with ID ${EXTENSION_ID} is not available for Gnome Shell ${GNOME_VERSION}."
  fi
}
install_gnome_extension '941'


function enable_ext_taskwarrior() {
  # Ext: https://extensions.gnome.org/extension/1052/taskwarrior-integration/
  # Git: https://github.com/sgaraud/gnome-extension-taskwarrior
  echo -e "${GREEN}[*]${RESET} Installing GNOME Extension: ${BLUE}Show-IP${RESET}"
  filedir="/usr/share/gnome-shell/extensions/taskwarrior-integration@sgaraud.github.com"
  if [[ ! -d "${filedir}" ]]; then
    mkdir -p "${filedir}"
    git clone https://github.com/sgaraud/gnome-extension-taskwarrior "${filedir}"
  fi
}


function enable_skype_ext() {
  # Ext: https://extensions.gnome.org/extension/696/skype-integration/
  # Git: https://github.com/chrisss404/gnome-shell-ext-SkypeNotification
  echo -e "${GREEN}[*]${RESET} Installing GNOME Extension: ${BLUE}Skype-Integration${RESET}"
}


# Setup the Extensions - Comment ones you don't want to setup
enable_frippery
enable_icon_hider
enable_ext_dropdown_terminal
#enable_ext_show_ip
#enable_skype_ext


function enable_extensions() {
  # Removed from below list: "Panel_Favorites@rmy.pobox.com"
  echo -e "${GREEN}[*]${RESET} Enabling the installed extensions..."
  for EXTENSION in "alternate-tab@gnome-shell-extensions.gcampax.github.com" "drive-menu@gnome-shell-extensions.gcampax.github.com" "TaskBar@zpydr" "Bottom_Panel@rmy.pobox.com" "Move_Clock@rmy.pobox.com" "icon-hider@kalnitsky.org" "drop-down-terminal@gs-extensions.zzrough.org"; do
    GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed 's_^.\(.*\).$_\1_')
    echo "${GNOME_EXTENSIONS}" | grep -q "${EXTENSION}" || gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}, '${EXTENSION}']"
  done

  for EXTENSION in "dash-to-dock@micxgx.gmail.com" "workspace-indicator@gnome-shell-extensions.gcampax.github.com"; do
    GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed "s_^.\(.*\).\$_\1_; s_, '${EXTENSION}'__")
    gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}]"
  done
}
enable_extensions


echo -e "${GREEN}[*]${RESET} Configuring GNOME 3rd Party Extension gsettings..."

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



function finish {
  # Any script-termination routines go here
  rm -f /tmp/extension.txt
  rm -f /tmp/extension.zip
  echo -e "${GREEN}[*]${RESET} GNOME Setup Complete. Restart to take effect, as 'gnome-shell --replace' doesn't completely work."
  #gnome-shell --replace &
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

# ===========[ gsettings ]==============
# gsettings [--schemadir SCHEMADIR] COMMAND [ARGS..]
#
# gsettings list-keys org.gnome.shell
# gsettings list-children org.gnome.shell
#
# Get a list of keys or key values
# gconftool-2 -a /apps/gnome-terminal/profiles/Default
# gconftool-2 --get /apps/gnome-terminal/profiles/Default/background_color
#
# Dump your current terminal preferences
# gconftool-2 --dump '/apps/gnome-terminal' > gnome-terminal-conf.xml
# Modify the file, then load it back into settings
# gconftool-2 --load gnome-terminal-conf.xml
#
# Kali 2016 Default Enabled Extensions (via: gsettings get org.gnome.shell enabled-extensions)
# ['apps-menu@gnome-shell-extensions.gcampax.github.com', 'places-menu@gnome-shell-extensions.gcampax.github.com', 'workspace-indicator@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com', 'ProxySwitcher@flannaghan.com', 'EasyScreenCast@iacopodeenosee.gmail.com', 'refresh-wifi@kgshank.net', 'user-theme@gnome-shell-extensions.gcampax.github.com']

# Kali 2016 Default Favorites (via: gsettings get org.gnome.shell favorite-apps)
