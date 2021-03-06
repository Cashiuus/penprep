#!/usr/bin/env bash
## =======================================================================================
# File:     setup-firefox.sh
# Author:   Cashiuus
# Created:  10-Apr-2016   -   Revised:  15-May-2017
#
#-[ Info ]-------------------------------------------------------------------------------
# Purpose:  Setup and set First-Run Configuration Tweaks to Firefox web browser
#
#
# TODO:
#   1. Add the "Wappalyzer" extension
#
#-[ Links/Credit ]------------------------------------------------------------------------
#
#
#
#-[ Copyright ]---------------------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
## =======================================================================================
__version__="1.0"
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


# Launch it to generate first-run files
echo -e "\n${GREEN}[*]${RESET} Installing ${GREEN}Mozilla Firefox${RESET} web browser"
apt-get -y -qq install unzip curl firefox-esr

export DISPLAY=:0.0
timeout 10 firefox >/dev/null 2>&1
timeout 5 killall -9 -q -w firefox-esr >/dev/null

file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)
[ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/firefox-esr/pref/*.js
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
sed -i 's/^.network.proxy.socks_remote_dns.*/user_pref("network.proxy.socks_remote_dns", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("network.proxy.socks_remote_dns", true);' >> "${file}"
sed -i 's/^.browser.safebrowsing.enabled.*/user_pref("browser.safebrowsing.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.enabled", false);' >> "${file}"
sed -i 's/^.browser.safebrowsing.malware.enabled.*/user_pref("browser.safebrowsing.malware.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.malware.enabled", false);' >> "${file}"
sed -i 's/^.browser.safebrowsing.remoteLookups.enabled.*/user_pref("browser.safebrowsing.remoteLookups.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.remoteLookups.enabled", false);' >> "${file}"
sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.startup.page", 0);' >> "${file}"
sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("privacy.donottrackheader.enabled", true);' >> "${file}"
sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.showQuitWarning", true);' >> "${file}"
sed -i 's/^.*extensions.https_everywhere._observatory.popup_shown.*/user_pref("extensions.https_everywhere._observatory.popup_shown", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("extensions.https_everywhere._observatory.popup_shown", true);' >> "${file}"
sed -i 's/^.network.security.ports.banned.override/user_pref("network.security.ports.banned.override", "1-65455");' "${file}" 2>/dev/null \
  || echo 'user_pref("network.security.ports.banned.override", "1-65455");' >> "${file}"


### Replace the default Firefox Bookmarks
echo -e "${GREEN}[*]${RESET} Looking for bookmarks to backup first"
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'bookmarks.html' -print -quit)
[[ -e "${file}" ]] && cp -n $file{,.bkup}     #/etc/firefox-esr/profile/bookmarks.html
cat << EOF > "${file}"
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks Menu</H1>

<DL><p>
<DT><H3 ADD_DATE="1441055778" LAST_MODIFIED="1444162981" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar</H3>
    <DL><p>
        <DT><H3 ADD_DATE="1441327896" LAST_MODIFIED="1441327936">Kali</H3>
        <DL><p>
            <DT><A HREF="https://www.kali.org/">Kali Linux</A>
            <DT><A HREF="http://docs.kali.org/">Kali Docs</A>
            <DT><A HREF="http://tools.kali.org/">Kali Tools</A>
            <DT><A HREF="https://www.offensive-security.com/">Offensive Security</A>
        </DL><p>
        <DT><H3 ADD_DATE="1441327905" LAST_MODIFIED="1443235733">Local</H3>
        <DL><p>
            <DT><A HREF="http://localhost">Localhost</A>
            <DT><A HREF="https://127.0.0.1:8834/">Nessus</A>
            <DT><A HREF="http://127.0.0.1:3000/ui/panel">BeEF</A>
            <DT><A HREF="http://127.0.0.1/rips/">RIPS</A>
            <DT><A HREF="http://127.0.0.1:3004/">Dradis-Local</A>
            <DT><A HREF="http://127.0.0.1:8000/">Django</A>
            <DT><A HREF="http://127.0.0.1:5984/reports/_design/reports/index.html#/dashboard/ws/testing_home">Dashboard | Faraday</A>
            <DT><A HREF="http://localhost:9200/">ElasticSearch</A>
            <DT><A HREF="http://localhost:5601/">Kibana</A>
        </DL><p>
        <DT><H3 ADD_DATE="1441327947" LAST_MODIFIED="1441327958">Pentest</H3>
        <DL><p>
            <DT><A HREF="https://www.exploit-db.com/">Exploit-DB</A>
            <DT><A HREF="https://hackvertor.co.uk/public">HackVertor</A>
            <DT><A HREF="http://offset-db.com/">Offset-DB</A>
        </DL><p>
        <DT><H3 ADD_DATE="1441726295" LAST_MODIFIED="1441742317">Engagements</H3>
        <DL><p>
        </DL><p>
        <DT><H3 ADD_DATE="1444162963" LAST_MODIFIED="1444162965">Code</H3>
        <DL><p>
            <DT><A HREF="https://github.com/">Github</A>
        </DL><p>
        <DT><A HREF="http://whatismyipaddress.com/">MY IP</A>
    </DL><p>
</DL>
EOF

#--- Clear bookmark cache
find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -mindepth 1 -type f -name places.sqlite -delete
find /root/.mozilla/firefox/*.default*/bookmarkbackups/ -type f -delete

##### Setup Firefox plugins
echo -e "\n${GREEN}[*]${RESET} Installing ${GREEN}Firefox plugins${RESET} ~ Useful addons"

ffpath="$(find /root/.mozilla/firefox/*.default*/ -maxdepth 0 -mindepth 0 -type d -name '*.default*' -print -quit)/extensions"
[ "${ffpath}" == "/extensions" ] && echo -e ' '${RED}'[!]'${RESET}" Couldn't find the Firefox folder" 1>&2
mkdir -p "${ffpath}/"

# SQLite Manager
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/5817/addon-5817-latest.xpi?src=dp-btn-primary" -o "$ffpath/SQLiteManager@mrinalkant.blogspot.com.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'SQLite Manager'" 1>&2

# Adblock Plus
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/1865/addon-1865-latest.xpi?src=dp-btn-primary" -o "$ffpath/{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Adblock Plus'" 1>&2

# Cookies Manager+
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/92079/addon-92079-latest.xpi?src=dp-btn-primary" -o "$ffpath/{bb6bc1bb-f824-4702-90cd-35e2fb24f25d}.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Cookies Manager+'" 1>&2

# Firebug
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary" -o "$ffpath/firebug@software.joehewitt.com.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Firebug'" 1>&2

# FoxyProxy Basic
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/15023/addon-15023-latest.xpi?src=dp-btn-primary" -o "$ffpath/foxyproxy-basic@eric.h.jung.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'FoxyProxy Basic'" 1>&2

# User Agent Overrider
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/429678/addon-429678-latest.xpi?src=dp-btn-primary" -o "$ffpath/useragentoverrider@qixinglu.com.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'User Agent Overrider'" 1>&2

# HTTPS Everywhere
timeout 300 curl --progress -k -L -f "https://www.eff.org/files/https-everywhere-latest.xpi" -o "$ffpath/https-everywhere@eff.org.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'HTTPS Everywhere'" 1>&2

# Live HTTP Headers
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary" -o "$ffpath/{8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Live HTTP Headers'" 1>&2

# Tamper Data
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/966/addon-966-latest.xpi?src=dp-btn-primary" -o "$ffpath/{9c51bd27-6ed8-4000-a2bf-36cb95c0c947}.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Tamper Data'" 1>&2

# Disable Add-on Compatibility Checks
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/300254/addon-300254-latest.xpi?src=dp-btn-primary" -o "$ffpath/check-compatibility@dactyl.googlecode.com.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Disable Add-on Compatibility Checks'" 1>&2

# HackBar
timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/3899/addon-3899-latest.xpi?src=dp-btn-primary" -o "$ffpath/{F5DDF39C-9293-4d5e-9AA8-E04E6DD5E9B4}.xpi" || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'HackBar'" 1>&2


# -=== Installing extensions ===-
for FILE in $(find "${ffpath}" -maxdepth 1 -type f -name '*.xpi'); do
  d="$(basename "${FILE}" .xpi)"
  mkdir -p "${ffpath}/${d}/"
  unzip -q -o -d "${ffpath}/${d}/" "${FILE}"
  rm -f "${FILE}"
done

# -=== Enable Firefox addons/plugins/extensions ===-
timeout 15 firefox >/dev/null 2>&1   #firefox & sleep 15s; killall -q -w firefox >/dev/null
sleep 3s
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.sqlite' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [ ! -e "${file}" ] || [ -z "${file}" ]; then
  #echo -e ' '${RED}'[!]'${RESET}" Something went wrong enabling Firefox's extensions via method #1. Trying method #2..." 1>&2
  false
else
  echo -e " ${YELLOW}[i]${RESET} Enabled ${YELLOW}Firefox's extensions${RESET} (via method #1!)"
  apt-get install -y -qq sqlite3 || echo -e ' '${RED}'[!] Issue with apt-get'${RESET} 1>&2
  rm -f /tmp/firefox.sql; touch /tmp/firefox.sql
  echo "UPDATE 'main'.'addon' SET 'active' = 1, 'userDisabled' = 0;" > /tmp/firefox.sql    # Force them all!
  sqlite3 "${file}" < /tmp/firefox.sql      #fuser extensions.sqlite
fi
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.json' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [ ! -e "${file}" ] || [ -z "${file}" ]; then
  #echo -e ' '${RED}'[!]'${RESET}" Something went wrong enabling Firefox's extensions via method #2. Did method #1 also fail?" 1>&2
  false
else
  echo -e "${YELLOW}[INFO]${RESET} Enabled ${YELLOW}Firefox's extensions${RESET} (via method #2!)"
  sed -i 's/"active":false,/"active":true,/g' "${file}"                # Force them all!
  sed -i 's/"userDisabled":true,/"userDisabled":false,/g' "${file}"    # Force them all!
fi
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
[ ! -z "${file}" ] && sed -i '/extensions.installCache/d' "${file}"
timeout 5 firefox >/dev/null 2>&1   # For extensions that just work without restarting
sleep 3s
timeout 5 firefox >/dev/null 2>&1   # ...for (most) extensions, as they need firefox to restart
sleep 5s


#--- Configure HackBar
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'xulstore.json' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [ -e "${file}" ]; then
  sed -i 's/"hackBarToolbar":{"collapsed":".*"},/"hackBarToolbar":{"collapsed":"true"},/g' "${file}"                                   # Hide the bar on startup
  grep -q "hackBarToolbar" "${file}" 2>/dev/null || sed -i 's/"nav-bar"/"hackBarToolbar":{"collapsed":"true"},"nav-bar"/g' "${file}"   # Hide the bar on startup
fi
#--- Configure foxyproxy
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'foxyproxy.xml' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [ -z "${file}" ]; then
  echo -e ' '${RED}'[!]'${RESET}' Something went wrong with the FoxyProxy Firefox extension (did any extensions install?). Skipping...' 1>&2
elif [ -e "${file}" ]; then
  # localhost:8080
  grep -q 'localhost:8080' "${file}" 2>/dev/null || sed -i 's#<proxy name="Default"#<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy><proxy name="Default"#' "${file}"

  # localhost:8081 (socket5)
  grep -q 'localhost:8081' "${file}" 2>/dev/null || sed -i 's#<proxy name="Default"#<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy><proxy name="Default"#' "${file}"

  # No caching
  grep -q '"No Caching"' "${file}" 2>/dev/null   || sed -i 's#<proxy name="Default"#<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy><proxy name="Default"#' "${file}"
else
  echo -ne '<?xml version="1.0" encoding="UTF-8"?>\n<foxyproxy mode="disabled" selectedTabIndex="0" toolbaricon="true" toolsMenu="true" contextMenu="false" advancedMenus="false" previousMode="disabled" resetIconColors="true" useStatusBarPrefix="true" excludePatternsFromCycling="false" excludeDisabledFromCycling="false" ignoreProxyScheme="false" apiDisabled="false" proxyForVersionCheck=""><random includeDirect="false" includeDisabled="false"/><statusbar icon="true" text="false" left="options" middle="cycle" right="contextmenu" width="0"/><toolbar left="options" middle="cycle" right="contextmenu"/><logg enabled="false" maxSize="500" noURLs="false" header="&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;\n&lt;!DOCTYPE html PUBLIC &quot;-//W3C//DTD XHTML 1.0 Strict//EN&quot; &quot;http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd&quot;&gt;\n&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;&lt;head&gt;&lt;title&gt;&lt;/title&gt;&lt;link rel=&quot;icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;shortcut icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;stylesheet&quot; href=&quot;http://getfoxyproxy.org/styles/log.css&quot; type=&quot;text/css&quot;/&gt;&lt;/head&gt;&lt;body&gt;&lt;table class=&quot;log-table&quot;&gt;&lt;thead&gt;&lt;tr&gt;&lt;td class=&quot;heading&quot;&gt;${timestamp-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${url-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-notes-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-case-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-type-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-color-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pac-result-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${error-msg-heading}&lt;/td&gt;&lt;/tr&gt;&lt;/thead&gt;&lt;tfoot&gt;&lt;tr&gt;&lt;td/&gt;&lt;/tr&gt;&lt;/tfoot&gt;&lt;tbody&gt;" row="&lt;tr&gt;&lt;td class=&quot;timestamp&quot;&gt;${timestamp}&lt;/td&gt;&lt;td class=&quot;url&quot;&gt;&lt;a href=&quot;${url}&quot;&gt;${url}&lt;/a&gt;&lt;/td&gt;&lt;td class=&quot;proxy-name&quot;&gt;${proxy-name}&lt;/td&gt;&lt;td class=&quot;proxy-notes&quot;&gt;${proxy-notes}&lt;/td&gt;&lt;td class=&quot;pattern-name&quot;&gt;${pattern-name}&lt;/td&gt;&lt;td class=&quot;pattern&quot;&gt;${pattern}&lt;/td&gt;&lt;td class=&quot;pattern-case&quot;&gt;${pattern-case}&lt;/td&gt;&lt;td class=&quot;pattern-type&quot;&gt;${pattern-type}&lt;/td&gt;&lt;td class=&quot;pattern-color&quot;&gt;${pattern-color}&lt;/td&gt;&lt;td class=&quot;pac-result&quot;&gt;${pac-result}&lt;/td&gt;&lt;td class=&quot;error-msg&quot;&gt;${error-msg}&lt;/td&gt;&lt;/tr&gt;" footer="&lt;/tbody&gt;&lt;/table&gt;&lt;/body&gt;&lt;/html&gt;"/><warnings/><autoadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic AutoAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/><match enabled="true" name="" pattern="*You are not authorized to view this page*" isRegEx="false" isBlackList="false" isMultiLine="true" caseSensitive="false" fromSubscription="false"/></autoadd><quickadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic QuickAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></quickadd><defaultPrefs origPrefetch="null"/><proxies>' > "${file}"
  echo -ne '<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="Default" id="3377581719" notes="" fromSubscription="false" enabled="true" mode="direct" selectedTabIndex="0" lastresort="true" animatedIcons="false" includeInCycle="true" color="#0055E5" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="false" disableCache="false" clearCookiesBeforeUse="false" rejectCookies="false"><matches><match enabled="true" name="All" pattern="*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></matches><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password=""/></proxy>' >> "${file}"
  echo -e '</proxies></foxyproxy>' >> "${file}"
fi

#--- Wipe session (due to force close)
find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
#--- Remove old temp files
rm -f /tmp/firefox.sql

updatedb
apt-get clean
echo -e "${GREEN}[*]${RESET} Completed firefox install, goodbye!\n\n"
exit 0
