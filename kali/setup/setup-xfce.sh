#!/bin/bash
## =============================================================================
# File:     setup-xfce.sh
#
# Author:   Cashiuus
# Created:  01/25/2016
# Revised:  
#
# Purpose:  Perform a baseline setup of the xfce window manager to replace Gnome
#           This is a lightweight desktop designed to be low on resource use.
#
#
#
#   XFCE Site: http://www.xfce.org/
#   XFCE Debian Packaging Site: http://pkg-xfce.alioth.debian.org/
#
#
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
ENABLE_XFCE=true        # Thereby disabling Gnome as the default?

# =============================[      ]================================ #


function configure_panel_applications {
    # 1. Terminal
    cat << EOF > ~/.config/xfce4/panel/launcher-2/13684522758.desktop
[Desktop Entry]
Version=1.0
Type=Application
Exec=exo-open --launch TerminalEmulator
Icon=utilities-terminal
StartupNotify=true
Terminal=false
Categories=Utility;X-XFCE;X-Xfce-Toplevel;
OnlyShowIn=XFCE;
Name=Terminal Emulator
Comment=Use the command line
X-XFCE-Source=file:///usr/share/applications/exo-terminal-emulator.desktop
EOF

    # 2. Iceweasel Web Browser
    cat <<EOF > ~/.config/xfce4/panel/launcher-4/14470234761.desktop
[Desktop Entry]
Name=Iceweasel
Encoding=UTF-8
Exec=iceweasel %u
Icon=iceweasel
StartupNotify=true
Terminal=false
Comment=Browse the World Wide Web
GenericName=Web Browser
X-GNOME-FullName=Iceweasel Web Browser
X-MultipleArgs=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Iceweasel
X-XFCE-Source=file:///usr/share/applications/iceweasel.desktop
EOF

    # 3. Wireshark
    cat <<EOF > ~/.config/xfce4/panel/launcher-5/13684522587.desktop
[Desktop Entry]
Name=wireshark
Encoding=UTF-8
Exec=sh -c "wireshark"
Icon=wireshark
StartupNotify=false
Terminal=false
Type=Application
Categories=09-sniffing-spoofing;
X-Kali-Package=wireshark
X-XFCE-Source=file:///usr/share/applications/kali-wireshark.desktop
EOF

    # 4. Geany
    cat <<EOF > ~/.config/xfce4/panel/launcher-6/13684522859.desktop
[Desktop Entry]
Name=Geany
Encoding=UTF-8
Exec=geany %F
Icon=geany
StartupNotify=true
Terminal=false
Comment=A fast and lightweight IDE using GTK2
GenericName=Integrated Development Environment
Type=Application
Categories=GTK;Development;IDE;
MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/xml;text/html;text/css;text/x-sql;text/x-diff;
X-XFCE-Source=file:///usr/share/applications/geany.desktop
EOF

    # 5. Application Finder (Search)
    cat <<EOF > ~/.config/xfce4/panel/launcher-8/136845425410.desktop
[Desktop Entry]
Name=Application Finder
Exec=xfce4-appfinder
Icon=xfce4-appfinder
StartupNotify=true
Terminal=false
Type=Application
Categories=X-XFCE;Utility;c
Comment=Find and launch applications installed on your system
X-XFCE-Source=file:///usr/share/applications/xfce4-appfinder.desktop
EOF

    # 6. Burpsuite
    cat <<EOF > ~/.config/xfce4/panel/launcher-9/14470234962.desktop
[Desktop Entry]
Name=burpsuite
Encoding=UTF-8
Exec=sh -c "java -jar /usr/bin/burpsuite"
Icon=burpsuite
StartupNotify=false
Terminal=false
Type=Application
Categories=03-webapp-analysis;03-06-web-application-proxies;
X-Kali-Package=burpsuite
X-XFCE-Source=file:///usr/share/applications/kali-burpsuite.desktop
EOF

    xfconf-query -n -a -c xfce4-panel -p /panels -t int -s 0
    xfconf-query --create --channel xfce4-panel --property /panels/panel-0/plugin-ids \
      -t int -s 1  -t int -s 2  -t int -s 3  -t int -s 4  -t int -s 5  -t int -s 6  -t int -s 8  -t int -s 9 \
      -t int -s 10  -t int -s 11  -t int -s 13  -t int -s 15  -t int -s 16  -t int -s 17  -t int -s 19  -t int -s 20
    xfconf-query -n -c xfce4-panel -p /panels/panel-0/length -t int -s 100
    xfconf-query -n -c xfce4-panel -p /panels/panel-0/size -t int -s 30
    xfconf-query -n -c xfce4-panel -p /panels/panel-0/position -t string -s "p=6;x=0;y=0"
    xfconf-query -n -c xfce4-panel -p /panels/panel-0/position-locked -t bool -s true
    #=====[ PANEL COMPONENTS ]====== #
    ### Edit these later via GUI by typing: xfce4-settings-manager or xfce4-settings-editor
    # application menu
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-1 -t string -s applicationsmenu
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/show-tooltips -t bool -s true
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/show-button-title -t bool -s true
    # terminal
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-2 -t string -s launcher
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-2/items -t string -s "13684522758.desktop" -a
    # places
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-3/mount-open-volumes -t bool -s true
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-3 -t string -s places
    # wireshark
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-4 -t string -s launcher
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-4/items -t string -s "13684522587.desktop" -a
    # Burpsuite free
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-5 -t string -s launcher
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-5/items -t string -s "14470234962.desktop" -a
    # iceweasel
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-6 -t string -s launcher
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-6/items -t string -s "14470234761.desktop" -a
    # geany
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-8 -t string -s launcher
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-8/items -t string -s "13684522859.desktop" -a
    # search
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-9 -t string -s launcher
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-9/items -t string -s "136845425410.desktop" -a
    # tasklist (& separator - required for padding)
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-10 -t string -s tasklist
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/show-labels -t bool -s true
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/show-handle -t bool -s false
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-11 -t string -s separator
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/style -t int -s 0
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/expand -t bool -s true
    # systray
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-15 -t string -s systray
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-15/show-frame -t bool -s false
    # actions
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-16 -t string -s actions
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-16/appearance -t int -s 1
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-16/items -t string -s "+logout-dialog" -t string -s "-switch-user" -t string -s "-separator" -t string -s "-logout" -t string -s "+lock-screen" -t string -s "+hibernate" -t string -s "+suspend" -t string -s "+restart" -t string -s "+shutdown" -a
    # audio
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-13 -t string -s mixer
    # clock
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-17 -t string -s clock
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/show-frame -t bool -s false
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/mode -t int -s 2
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/digital-format -t string -s "%R, %Y-%m-%d"
    # pager / workspace
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-19 -t string -s pager
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-19/miniature-view -t bool -s true
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-19/rows -t int -s 1
    # Setup 3 workspaces
    xfconf-query -n -c xfwm4 -p /general/workspace_count -t int -s 3
    # Show Desktop toggle icon
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-20 -t string -s showdesktop


    # ============[ CONFIGURE GLOBAL SETTINGS ]=============== #
    #--- Theme options
    #xfconf-query -n -c xsettings -p /Net/ThemeName -s "Kali-X"
    #xfconf-query -n -c xsettings -p /Net/IconThemeName -s "Vibrancy-Kali"
    xfconf-query -n -c xsettings -p /Gtk/MenuImages -t bool -s true
    #xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/button-icon -t string -s "kali-menu"
    #--- Window management
    xfconf-query -n -c xfwm4 -p /general/snap_to_border -t bool -s true
    xfconf-query -n -c xfwm4 -p /general/snap_to_windows -t bool -s true
    xfconf-query -n -c xfwm4 -p /general/wrap_windows -t bool -s false
    xfconf-query -n -c xfwm4 -p /general/wrap_workspaces -t bool -s false
    xfconf-query -n -c xfwm4 -p /general/click_to_focus -t bool -s false
    xfconf-query -n -c xfwm4 -p /general/theme -t string -s "Blackbird"
    #--- Default System icons
    xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -t bool -s true
    xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-home -t bool -s true
    xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -t bool -s true
    xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -t bool -s true
    #--- Start and exit values
    xfconf-query -n -c xfce4-session -p /splash/Engine -t string -s ""
    xfconf-query -n -c xfce4-session -p /shutdown/LockScreen -t bool -s true
    xfconf-query -n -c xfce4-session -p /general/SaveOnExit -t bool -s false
    #--- App Finder
    xfconf-query -n -c xfce4-appfinder -p /last/pane-position -t int -s 248
    xfconf-query -n -c xfce4-appfinder -p /last/window-height -t int -s 742
    xfconf-query -n -c xfce4-appfinder -p /last/window-width -t int -s 648
    #--- Enable compositing
    xfconf-query -n -c xfwm4 -p /general/use_compositing -t bool -s true
    xfconf-query -n -c xfwm4 -p /general/frame_opacity -t int -s 85
}


function xfce_fix_defaults {
    # ==============[ Menu Customization ]===========
    # Remove Mail Reader from menu
    file=/usr/share/applications/exo-mail-reader.desktop
    sed -i 's/^NotShowIn=*/NotShowIn=XFCE;/; s/^OnlyShowIn=XFCE;/OnlyShowIn=/' "${file}"
    grep -q "NotShowIn=XFCE" "${file}" || echo "NotShowIn=XFCE;" >> "${file}"
    
    #--- Disable user folders
    apt-get -y -qq install xdg-user-dirs
    xdg-user-dirs-update
    file=/etc/xdg/user-dirs.conf
    sed -i 's/^enable=.*/enable=False/' "${file}"
    # Leaving the "Templates" directory intact but removing all folders listed below
    find ~/ -maxdepth 1 -mindepth 1 \( -name 'Documents' -o -name 'Music' -o -name 'Pictures' -o -name 'Public' -o -name 'Videos' \) -type d -empty -delete
    xdg-user-dirs-update

    #--- XFCE fixes for default applications
    mkdir -p ~/.local/share/applications/
    file=~/.local/share/applications/mimeapps.list; [ -e "${file}" ] && cp -n $file{,.bkup}

    [ ! -e "${file}" ] && echo '[Added Associations]' > "${file}"
    ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
    for VALUE in file trash; do
      sed -i 's#x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-file-manager.desktop#' "${file}"
      grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null || echo 'x-scheme-handler/'${VALUE}'=exo-file-manager.desktop' >> "${file}"
    done
    for VALUE in http https; do
      sed -i 's#^x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-web-browser.desktop#' "${file}"
      grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null || echo 'x-scheme-handler/'${VALUE}'=exo-web-browser.desktop' >> "${file}"
    done
    [[ $(tail -n 1 "${file}") != "" ]] && echo >> "${file}"
    file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
    sed -i 's#^FileManager=.*#FileManager=Thunar#' "${file}" 2>/dev/null
    grep -q '^FileManager=Thunar' "${file}" 2>/dev/null || echo 'FileManager=Thunar' >> "${file}"
    #--- Configure file browser - Thunar (need to re-login for effect)
    mkdir -p ~/.config/Thunar/
    file=~/.config/Thunar/thunarrc; [ -e "${file}" ] && cp -n $file{,.bkup}
    ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
    sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' "${file}" 2>/dev/null || echo -e "[Configuration]\nLastShowHidden=TRUE" > ~/.config/Thunar/thunarrc;

    --- XFCE fixes for GNOME Terminator (We do this later)
    mkdir -p ~/.local/share/xfce4/helpers/
    file=~/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
    sed -i 's#^X-XFCE-CommandsWithParameter=.*#X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"#' "${file}" 2>/dev/null || cat <<EOF > "${file}"
[Desktop Entry]
NoDisplay=true
Version=1.0
Encoding=UTF-8
Type=X-XFCE-Helper
X-XFCE-Category=TerminalEmulator
X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"
Icon=terminator
Name=terminator
X-XFCE-Commands=/usr/bin/terminator
EOF
    file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
    sed -i 's#^TerminalEmulator=.*#TerminalEmulator=custom-TerminalEmulator#' "${file}"
    grep -q '^TerminalEmulator=custom-TerminalEmulator' "${file}" 2>/dev/null || echo 'TerminalEmulator=custom-TerminalEmulator' >> "${file}"
    #--- XFCE fixes for Iceweasel
    file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
    sed -i 's#^WebBrowser=.*#WebBrowser=iceweasel#' "${file}"
    grep -q '^WebBrowser=iceweasel' "${file}" 2>/dev/null || echo 'WebBrowser=iceweasel' >> "${file}"

    #--- Fix GNOME keyring issue
    file=/etc/xdg/autostart/gnome-keyring-pkcs11.desktop;   #[ -e "${file}" ] && cp -n $file{,.bkup}
    grep -q "XFCE" "${file}" || sed -i 's/^OnlyShowIn=*/OnlyShowIn=XFCE;/' "${file}"
    
}


function setup_shortcuts {
    #--- Add keyboard shortcut (CTRL+SPACE) to open Application Finder
    file=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
    grep -q '<property name="&lt;Primary&gt;space" type="string" value="xfce4-appfinder"/>' "${file}" || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;space" type="string" value="xfce4-appfinder"/>#' "${file}"
    #--- Add keyboard shortcut (CTRL+ALT+t) to start a terminal window
    file=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
    grep -q '<property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>' "${file}" || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;\&lt;Alt\&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>#' "${file}"
    #--- Add keyboard shortcut (CTRL+r) to run __TODO
    #file=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
    #grep -q '<property name="&lt;Primary&gt;r" type="string" value="/usr/local/bin/__TODO"/>' "${file}" || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;r" type="string" value="/usr/local/bin/__TODO"/>#' "${file}"
}


function uninstall_gnome {
    # Do not do this until fully understanding how Kali manages logins and root
    aptitude purge `dpkg --get-selections | grep gnome | cut -f 1`
    aptitude -f install
    aptitude purge `dpkg --get-selections | grep deinstall | cut -f 1`
    aptitude -f install
}


function enable_xfce {
    mv -f /usr/bin/startx{,-gnome}
    ln -sf /usr/bin/startx{fce4,}

    #--- Set XFCE as default desktop manager
    file=~/.xsession; [ -e "${file}" ] && cp -n $file{,.bkup}
    echo xfce4-session > "${file}"

    #--- Remove any old sessions
    rm -f ~/.cache/sessions/*
    #--- Reload XFCE
    /usr/bin/xfdesktop --reload
}


## =============================[ MAIN ]================================== ##
# Disable idle timeout to screensaver
gsettings set org.gnome.desktop.session idle-delay 0

apt-get -y -qq install curl terminator xfce4 xfce-goodies xfce4-places-plugin

# Create directory structure
mkdir -p ~/.config/xfce4/{desktop,menu,panel,xfconf,xfwm4}/
mkdir -p ~/.config/xfce4/panel/launcher-{2,4,5,6,8,9}/
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/

configure_panel_applications
xfce_fix_defaults
setup_shortcuts
# If true, run function to enable xfce as the new default window manager
[[ $ENABLE_XFCE ]] && enable_xfce

#--- Disable tracker
tracker-control -r
mkdir -p ~/.config/autostart/
rm -f ~/.config/autostart/tracker-*.desktop
rm -f /etc/xdg/autostart/tracker-*.desktop
exit 0
