#!/bin/bash
## =================================================================================
# File:     setup-xfce.sh
#
# Author:   Cashiuus
# Created:  25-JAN-2016         (Synced with g0tmi1k's kali-rolling.sh: 09-APR-2016)
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
## =================================================================================
__version__="0.8"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
ENABLE_XFCE=true              # Thereby disabling Gnome as the default?
BROWSER_SHORTCUT="iceweasel"  # Use "iceweasel" or "firefox"?
EDITOR_SHORTCUT="geany"       # Use "geany" or "gedit" for panel shortcut icon?


# =============================[  FUNCTIONS ]================================ #

function configure_panel_applications {
  apt-get -y install burpsuite metasploit-framework wireshark

  ln -sf /usr/share/applications/exo-terminal-emulator.desktop ~/.config/xfce4/panel/launcher-2/exo-terminal-emulator.desktop
  ln -sf /usr/share/applications/kali-wireshark.desktop    ~/.config/xfce4/panel/launcher-4/kali-wireshark.desktop
  if [[ "$BROWSER_SHORTCUT}" == "firefox" ]]; then
    ln -sf /usr/share/applications/firefox-esr.desktop     ~/.config/xfce4/panel/launcher-5/browser.desktop
  else
    ln -sf /usr/share/applications/iceweasel.desktop       ~/.config/xfce4/panel/launcher-5/browser.desktop
  fi
  ln -sf /usr/share/applications/kali-burpsuite.desktop    ~/.config/xfce4/panel/launcher-6/kali-burpsuite.desktop
  ln -sf /usr/share/applications/kali-msfconsole.desktop   ~/.config/xfce4/panel/launcher-7/kali-msfconsole.desktop
  if [[ "$EDITOR_SHORTCUT}" == "gedit" ]]; then
    ln -sf /usr/share/applications/org.gnome.gedit.desktop ~/.config/xfce4/panel/launcher-8/textedit.desktop
  else
    ln -sf /usr/share/applications/geany.desktop           ~/.config/xfce4/panel/launcher-8/textedit.desktop
  fi
  ln -sf /usr/share/applications/xfce4-appfinder.desktop   ~/.config/xfce4/panel/launcher-9/xfce4-appfinder.desktop
  # My preferred order: Terminal, Iceweasel, Wireshark, Geany, Appfinder (search), Burp,

  xfconf-query -n -a -c xfce4-panel -p /panels -t int -s 0
  xfconf-query --create --channel xfce4-panel --property /panels/panel-0/plugin-ids \
    -t int -s 1   -t int -s 2   -t int -s 3   -t int -s 4   -t int -s 5   -t int -s 6   -t int -s 7 \
    -t int -s 8   -t int -s 9   -t int -s 10  -t int -s 11  -t int -s 13  -t int -s 15  -t int -s 16 \
    -t int -s 17  -t int -s 19  -t int -s 20
  xfconf-query -n -c xfce4-panel -p /panels/panel-0/length -t int -s 100
  xfconf-query -n -c xfce4-panel -p /panels/panel-0/size -t int -s 30
  xfconf-query -n -c xfce4-panel -p /panels/panel-0/position -t string -s "p=6;x=0;y=0"
  xfconf-query -n -c xfce4-panel -p /panels/panel-0/position-locked -t bool -s true
  #=====[ PANEL COMPONENTS ]====== #
  ### Edit these later via GUI by typing: xfce4-settings-manager or xfce4-settings-editor

  xfconf-query -n -c xfce4-panel -p /plugins/plugin-1 -t string -s applicationsmenu     # application menu
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-2 -t string -s launcher             # terminal   ID: exo-terminal-emulator
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-3 -t string -s places               # places
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-4 -t string -s launcher             # wireshark  ID: kali-wireshark
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-5 -t string -s launcher             # firefox    ID: firefox-esr
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-6 -t string -s launcher             # burpsuite  ID: kali-burpsuite
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-7 -t string -s launcher             # msf        ID: kali-msfconsole
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-8 -t string -s launcher             # gedit      ID: org.gnome.gedit.desktop
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-9 -t string -s launcher             # search     ID: xfce4-appfinder
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-10 -t string -s tasklist
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-11 -t string -s separator
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-13 -t string -s mixer               # audio
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-15 -t string -s systray
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-16 -t string -s actions
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-17 -t string -s clock
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-19 -t string -s pager
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-20 -t string -s showdesktop

  # application menu
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/show-tooltips -t bool -s true
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/show-button-title -t bool -s true
  #--- terminal
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-2/items -t string -s "exo-terminal-emulator.desktop" -a
  #--- places
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-3/mount-open-volumes -t bool -s true
  #--- wireshark
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-4/items -t string -s "kali-wireshark.desktop" -a
  #--- browser - either firefox or iceweasel
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-5/items -t string -s "browser.desktop" -a
  #--- Burpsuite free
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-6/items -t string -s "kali-burpsuite.desktop" -a
  #--- metasploit
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-7/items -t string -s "kali-msfconsole.desktop" -a
  #--- geany/gedit/atom
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-8/items -t string -s "textedit.desktop" -a
  #--- search
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-9/items -t string -s "xfce4-appfinder.desktop" -a
  # iceweasel
  #xfconf-query -n -c xfce4-panel -p /plugins/plugin-6 -t string -s launcher
  #xfconf-query -n -c xfce4-panel -p /plugins/plugin-6/items -t string -s "14470234761.desktop" -a
  # geany
  #xfconf-query -n -c xfce4-panel -p /plugins/plugin-8 -t string -s launcher
  #xfconf-query -n -c xfce4-panel -p /plugins/plugin-8/items -t string -s "13684522859.desktop" -a

  # tasklist (& separator - required for padding)
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/show-labels -t bool -s true
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/show-handle -t bool -s false
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/style -t int -s 0
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/expand -t bool -s true
  # systray
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-15/show-frame -t bool -s false
  # actions
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-16/appearance -t int -s 1
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-16/items \
    -t string -s "+logout-dialog" -t string -s "-switch-user" -t string -s "-separator" \
    -t string -s "-logout" -t string -s "+lock-screen" -t string -s "+hibernate" \
    -t string -s "+suspend" -t string -s "+restart" -t string -s "+shutdown" -a
  #--- clock
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/show-frame -t bool -s false
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/mode -t int -s 2
  #xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/digital-format -t string -s "%R, %Y-%m-%d"
  #--- pager / workspace
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-19/miniature-view -t bool -s true
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-19/rows -t int -s 1
  #--- Setup 3 workspaces
  xfconf-query -n -c xfwm4 -p /general/workspace_count -t int -s 3

  # ============[ CONFIGURE GLOBAL SETTINGS ]=============== #
  #--- Theme options
  xfconf-query -n -c xsettings -p /Net/ThemeName -s "Kali-X"
  xfconf-query -n -c xsettings -p /Net/IconThemeName -s "Vibrancy-Kali"
  xfconf-query -n -c xsettings -p /Gtk/MenuImages -t bool -s true
  xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/button-icon -t string -s "kali-menu"
  #--- Window management
  xfconf-query -n -c xfwm4 -p /general/snap_to_border -t bool -s true
  xfconf-query -n -c xfwm4 -p /general/snap_to_windows -t bool -s true
  xfconf-query -n -c xfwm4 -p /general/wrap_windows -t bool -s false
  xfconf-query -n -c xfwm4 -p /general/wrap_workspaces -t bool -s false
  xfconf-query -n -c xfwm4 -p /general/click_to_focus -t bool -s false
  #xfconf-query -n -c xfwm4 -p /general/theme -t string -s "Blackbird"

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


function xfce_setup_thunar {
  xfconf-query -n -c thunar -p /last-details-view-column-widths -t string -s "50,133,50,50,178,50,50,73,70"
  xfconf-query -n -c thunar -p /last-view -t string -s "ThunarDetailsView"

  #--- Configure Thunar - file browser (need to re-login for effect)
  mkdir -p ~/.config/Thunar/
  file=~/.config/Thunar/thunarrc
  ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
  sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' "${file}" 2>/dev/null \
    || echo -e "[Configuration]\nLastShowHidden=TRUE" > "${file}"
}



function xfce_fix_defaults {
  # ==============[ Menu Customization ]=========== #
  #--- Remove Mail Reader from menu
  file=/usr/share/applications/exo-mail-reader.desktop
  sed -i 's/^NotShowIn=*/NotShowIn=XFCE;/; s/^OnlyShowIn=XFCE;/OnlyShowIn=/' "${file}"
  grep -q "NotShowIn=XFCE" "${file}" || echo "NotShowIn=XFCE;" >> "${file}"

  #--- XFCE fixes for default applications
  mkdir -p ~/.local/share/applications/
  file=~/.local/share/applications/mimeapps.list; [ -e "${file}" ] && cp -n $file{,.bkup}

  [ ! -e "${file}" ] && echo '[Added Associations]' > "${file}"
  ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"

  #--- Firefox
  for VALUE in http https; do
    sed -i 's#^x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-web-browser.desktop#' "${file}"
    grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null \
      || echo 'x-scheme-handler/'${VALUE}'=exo-web-browser.desktop' >> "${file}"
  done

  #--- Thunar
  for VALUE in file trash; do
    sed -i 's#x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-file-manager.desktop#' "${file}"
    grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null \
      || echo 'x-scheme-handler/'${VALUE}'=exo-file-manager.desktop' >> "${file}"
  done

  file=~/.config/xfce4/helpers.rc; [[ -e "${file}" ]] && cp -n $file{,.bkup}
  ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
  sed -i 's#^FileManager=.*#FileManager=Thunar#' "${file}" 2>/dev/null
  grep -q '^FileManager=Thunar' "${file}" 2>/dev/null \
    || echo 'FileManager=Thunar' >> "${file}"

  #--- Disable user folders in home folder
  file=/etc/xdg/user-dirs.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
  sed -i 's/^XDG_/#XDG_/g; s/^#XDG_DESKTOP/XDG_DESKTOP/g;' "${file}"
  sed -i 's/^enable=.*/enable=False/' "${file}"

  # Leaving the "Templates" directory intact but removing all folders listed below
  find ~/ -maxdepth 1 -mindepth 1 -type d \
    \( -name 'Documents' -o -name 'Music' -o -name 'Pictures' -o -name 'Public' -o -name 'Videos' \) -empty -delete
  apt-get -y -qq install xdg-user-dirs
  xdg-user-dirs-update

  #--- XFCE fixes for Iceweasel
  file=~/.config/xfce4/helpers.rc
  sed -i 's#^WebBrowser=.*#WebBrowser=iceweasel#' "${file}"
  grep -q '^WebBrowser=iceweasel' "${file}" 2>/dev/null || echo 'WebBrowser=iceweasel' >> "${file}"
}


function setup_shortcuts {
  cat <<EOF > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml \
    || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="custom" type="empty">
      <property name="XF86Display" type="string" value="xfce4-display-settings --minimal"/>
      <property name="&lt;Alt&gt;F2" type="string" value="xfrun4"/>
      <property name="&lt;Primary&gt;space" type="string" value="xfce4-appfinder"/>
      <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>
      <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="string" value="xflock4"/>
      <property name="&lt;Primary&gt;Escape" type="string" value="xfdesktop --menu"/>
      <property name="&lt;Super&gt;p" type="string" value="xfce4-display-settings --minimal"/>
      <property name="override" type="bool" value="true"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Alt&gt;&lt;Control&gt;End" type="string" value="move_window_next_workspace_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;Home" type="string" value="move_window_prev_workspace_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_1" type="string" value="move_window_workspace_1_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_2" type="string" value="move_window_workspace_2_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_3" type="string" value="move_window_workspace_3_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_4" type="string" value="move_window_workspace_4_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_5" type="string" value="move_window_workspace_5_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_6" type="string" value="move_window_workspace_6_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_7" type="string" value="move_window_workspace_7_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_8" type="string" value="move_window_workspace_8_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_9" type="string" value="move_window_workspace_9_key"/>
      <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="string" value="cycle_reverse_windows_key"/>
      <property name="&lt;Alt&gt;Delete" type="string" value="del_workspace_key"/>
      <property name="&lt;Alt&gt;F10" type="string" value="maximize_window_key"/>
      <property name="&lt;Alt&gt;F11" type="string" value="fullscreen_key"/>
      <property name="&lt;Alt&gt;F12" type="string" value="above_key"/>
      <property name="&lt;Alt&gt;F4" type="string" value="close_window_key"/>
      <property name="&lt;Alt&gt;F6" type="string" value="stick_window_key"/>
      <property name="&lt;Alt&gt;F7" type="string" value="move_window_key"/>
      <property name="&lt;Alt&gt;F8" type="string" value="resize_window_key"/>
      <property name="&lt;Alt&gt;F9" type="string" value="hide_window_key"/>
      <property name="&lt;Alt&gt;Insert" type="string" value="add_workspace_key"/>
      <property name="&lt;Alt&gt;space" type="string" value="popup_menu_key"/>
      <property name="&lt;Alt&gt;Tab" type="string" value="cycle_windows_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;d" type="string" value="show_desktop_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;Down" type="string" value="down_workspace_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;Left" type="string" value="left_workspace_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;Right" type="string" value="right_workspace_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;Up" type="string" value="up_workspace_key"/>
      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="string" value="move_window_left_key"/>
      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="string" value="move_window_right_key"/>
      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="string" value="move_window_up_key"/>
      <property name="&lt;Control&gt;F1" type="string" value="workspace_1_key"/>
      <property name="&lt;Control&gt;F10" type="string" value="workspace_10_key"/>
      <property name="&lt;Control&gt;F11" type="string" value="workspace_11_key"/>
      <property name="&lt;Control&gt;F12" type="string" value="workspace_12_key"/>
      <property name="&lt;Control&gt;F2" type="string" value="workspace_2_key"/>
      <property name="&lt;Control&gt;F3" type="string" value="workspace_3_key"/>
      <property name="&lt;Control&gt;F4" type="string" value="workspace_4_key"/>
      <property name="&lt;Control&gt;F5" type="string" value="workspace_5_key"/>
      <property name="&lt;Control&gt;F6" type="string" value="workspace_6_key"/>
      <property name="&lt;Control&gt;F7" type="string" value="workspace_7_key"/>
      <property name="&lt;Control&gt;F8" type="string" value="workspace_8_key"/>
      <property name="&lt;Control&gt;F9" type="string" value="workspace_9_key"/>
      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Down" type="string" value="lower_window_key"/>
      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Up" type="string" value="raise_window_key"/>
      <property name="&lt;Super&gt;Tab" type="string" value="switch_window_key"/>
      <property name="Down" type="string" value="down_key"/>
      <property name="Escape" type="string" value="cancel_key"/>
      <property name="Left" type="string" value="left_key"/>
      <property name="Right" type="string" value="right_key"/>
      <property name="Up" type="string" value="up_key"/>
      <property name="override" type="bool" value="true"/>
      <property name="&lt;Super&gt;Left" type="string" value="tile_left_key"/>
      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
      <property name="&lt;Super&gt;Up" type="string" value="maximize_window_key"/>
    </property>
  </property>
  <property name="providers" type="array">
    <value type="string" value="xfwm4"/>
    <value type="string" value="commands"/>
  </property>
</channel>
EOF
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
  echo "xfce4-session" > "${file}"

  #--- Remove any old sessions
  rm -f ~/.cache/sessions/*
  #--- Reload XFCE
  /usr/bin/xfdesktop --reload 2>/dev/null &

}



function setup_themes {
  echo -e "${GREEN}[*]${RESET} Setting up Themes and Wallpapers..."
  #--- axiom / axiomd (May 18 2010) XFCE4 theme ~ http://xfce-look.org/content/show.php/axiom+xfwm?content=90145
  mkdir -p ~/.themes/
  #timeout 300 curl --progress -k -L -f "http://xfce-look.org/CONTENT/content-files/90145-axiom.tar.gz" > /tmp/axiom.tar.gz \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading axiom.tar.gz" 1>&2    #***!!! hardcoded path!
  timeout 300 curl --progress -k -L -f "https://dl.opendesktop.org/api/files/download/id/1461767736/90145-axiom.tar.gz" > /tmp/axiom.tar.gz \
    || echo -e "${RED}[WARN]${RESET} Issue downloading axiom.tar.gz from xfce-look.org" 1>&2
  tar -zxf /tmp/axiom.tar.gz -C ~/.themes/
  xfconf-query -n -c xsettings -p /Net/ThemeName -s "axiomd"
  xfconf-query -n -c xsettings -p /Net/IconThemeName -s "Vibrancy-Kali-Dark"
  #--- Get new desktop wallpaper      (All are #***!!! hardcoded paths!)
  mkdir -p /usr/share/wallpapers/
  echo -n '[1/10]'; timeout 30 curl --progress -k -L -f "https://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_A.png" > /usr/share/wallpapers/kali_blue_3d_a.png \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_blue_3d_a.png" 1>&2
  echo -n '[2/10]'; timeout 30 curl --progress -k -L -f "https://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_B.png" > /usr/share/wallpapers/kali_blue_3d_b.png \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_blue_3d_b.png" 1>&2
  echo -n '[3/10]'; timeout 30 curl --progress -k -L -f "https://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_G.png" > /usr/share/wallpapers/kali_black_honeycomb.png \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_black_honeycomb.png" 1>&2
  echo -n '[4/10]'; timeout 30 curl --progress -k -L -f "https://lh5.googleusercontent.com/-CW1-qRVBiqc/U7ARd2T9LCI/AAAAAAAAAGw/oantfR6owSg/w1920-h1080/vzex.png" > /usr/share/wallpapers/kali_blue_splat.png \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_blue_splat.png" 1>&2
  echo -n '[5/10]'; timeout 30 curl --progress -k -L -f "http://wallpaperstock.net/kali-linux_wallpapers_39530_1920x1080.jpg" > /usr/share/wallpapers/kali-linux_wallpapers_39530.png \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali-linux_wallpapers_39530.png" 1>&2
  echo -n '[6/10]'; timeout 30 curl --progress -k -L -f "http://em3rgency.com/wp-content/uploads/2012/12/Kali-Linux-faded-no-Dragon-small-text.png" > /usr/share/wallpapers/kali_black_clean.png \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_black_clean.png" 1>&2
  #echo -n '[7/10]'; timeout 30 curl --progress -k -L -f "http://www.hdwallpapers.im/download/kali_linux-wallpaper.jpg" > /usr/share/wallpapers/kali_black_stripes.jpg \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_black_stripes.jpg" 1>&2
  echo -n '[8/10]'; timeout 30 curl --progress -k -L -f "http://fc01.deviantart.net/fs71/f/2011/118/e/3/bt___edb_wallpaper_by_xxdigipxx-d3f4nxv.png" > /usr/share/wallpapers/kali_bt_edb.jpg \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_bt_edb.jpg" 1>&2
  echo -n '[9/10]'; timeout 30 curl --progress -k -L -f "http://pre07.deviantart.net/58d1/th/pre/i/2015/223/4/8/kali_2_0_alternate_wallpaper_by_xxdigipxx-d95800s.png" > /usr/share/wallpapers/kali_2_0_alternate_wallpaper.png \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_2_0_alternate_wallpaper.png" 1>&2
  echo -n '[10/10]'; timeout 30 curl --progress -k -L -f "http://pre01.deviantart.net/4210/th/pre/i/2015/195/3/d/kali_2_0__personal__wp_by_xxdigipxx-d91c8dq.png" > /usr/share/wallpapers/kali_2_0_personal.png \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_2_0_personal.png" 1>&2
  _TMP="$(find /usr/share/wallpapers/ -maxdepth 1 -type f -name 'kali_*' | xargs -n1 file | grep -i 'HTML\|empty' | cut -d ':' -f1)"
  for FILE in $(echo ${_TMP}); do rm -f "${FILE}"; done
  #--- Kali 1 (Wallpaper)
  [ -e "/usr/share/wallpapers/kali_default-1440x900.jpg" ] \
    && ln -sf /usr/share/wallpapers/kali/contents/images/1440x900.png /usr/share/wallpapers/kali_default-1440x900.jpg
  #--- Kali 2 (Login)
  [ -e "/usr/share/gnome-shell/theme/KaliLogin.png" ] \
    && cp -f /usr/share/gnome-shell/theme/KaliLogin.png /usr/share/wallpapers/KaliLogin2.0-login.jpg
  #--- Kali 2 & Rolling (Wallpaper)
  [ -e "/usr/share/images/desktop-base/kali-wallpaper_1920x1080.png" ] \
    && ln -sf /usr/share/images/desktop-base/kali-wallpaper_1920x1080.png /usr/share/wallpapers/kali_default2.0-1920x1080.jpg

  #--- New wallpaper & add to startup (so its random each login)
  file=/usr/local/bin/rand-wallpaper
  cat <<EOF > "${file}" || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

wallpaper="\$(shuf -n1 -e \$(find /usr/share/wallpapers/ -maxdepth 1 -name 'kali_*'))"

/usr/bin/xfconf-query -n -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -t bool -s true
/usr/bin/xfconf-query -n -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -t string -s "\${wallpaper}"  # XFCE - Desktop wallpaper

#[[ $(which gnome-shell) ]] \
#  && dconf write /org/gnome/desktop/background/picture-uri "'file://\${wallpaper}'"                             # GNOME - Desktop wallpaper

/usr/bin/dconf write /org/gnome/desktop/screensaver/picture-uri "'file://\${wallpaper}'"                         # Change lock wallpaper (before swipe) - kali 2 & rolling
#cp -f "\${wallpaper}" /usr/share/gnome-shell/theme/KaliLogin.png                                                # Change login wallpaper (after swipe) - kali 2

/usr/bin/xfdesktop --reload 2>/dev/null &
EOF
  chmod -f 0500 "${file}"
  #--- Run now
  bash "${file}"
  #--- Add to startup
  mkdir -p ~/.config/autostart/
  file=~/.config/autostart/wallpaper.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
  cat <<EOF > "${file}" || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/rand-wallpaper
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=wallpaper
EOF
}



function set_terminator_default {
  #--- Configure terminator
  mkdir -p ~/.config/terminator/
  file=~/.config/terminator/config; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}" || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
[global_config]
  enabled_plugins = TerminalShot, LaunchpadCodeURLHandler, APTURLHandler, LaunchpadBugURLHandler
[keybindings]
[profiles]
  [[default]]
    background_darkness = 0.9
    scroll_on_output = False
    copy_on_selection = True
    background_type = transparent
    scrollback_infinite = True
    show_titlebar = False
[layouts]
  [[default]]
    [[[child1]]]
      type = Terminal
      parent = window0
    [[[window0]]]
      type = Window
      parent = ""
[plugins]
EOF
  #--- Set terminator for XFCE's default
  if [[ $(which terminator) ]]; then
    mkdir -p ~/.config/xfce4/
    file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
    ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
    sed -i 's_^TerminalEmulator=.*_TerminalEmulator=debian-x-terminal-emulator_' "${file}" 2>/dev/null \
      || echo -e 'TerminalEmulator=debian-x-terminal-emulator' >> "${file}"
  fi
}


## =============================[ MAIN ]================================== ##
# Disable idle timeout to screensaver
gsettings set org.gnome.desktop.session idle-delay 0
echo -e "${GREEN}[*]${RESET} Installing xfce from apt-get..."
apt-get -y -qq install curl terminator xfce4 xfce4-mount-plugin xfce4-notifyd \
    xfce4-places-plugin xfce4-battery-plugin

# Create directory structure
mkdir -p ~/.config/xfce4/{desktop,menu,panel,xfconf,xfwm4}/
mkdir -p ~/.config/xfce4/panel/launcher-{2,4,5,6,7,8,9}/
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/

echo -e "${GREEN}[*]${RESET} Beginning XFCE4 Setup..."
setup_shortcuts
configure_panel_applications
xfce_setup_thunar
xfce_fix_defaults

# If true, run function to enable xfce as the new default window manager
[[ $ENABLE_XFCE ]] && enable_xfce

# Themes & Wallpapers
setup_themes

# 3rd Party Application Setup
set_terminator_default

#--- Disable tracker
#tracker-control -r || echo -e "${RED}[-]${RESET} Tracker-control not found"
#mkdir -p ~/.config/autostart/
#rm -f ~/.config/autostart/tracker-*.desktop
#rm -f /etc/xdg/autostart/tracker-*.desktop
exit 0
