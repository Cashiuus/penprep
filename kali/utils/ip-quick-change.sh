#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: ipchange.sh                   (Update: 09-10-2015 #
#-Author------------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#                                                             #
#
# Usage: ip-quick-change.sh <ip>
#        ipchange.sh 192.168.1.70                             #
#-------------------------------------------------------------#
GREEN="\033[01;32m"    # Success
RESET="\033[00m"       # Normal
YELLOW="\033[01;33m"   # Warnings/Information



if [[ "$1" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	iaddr=$1
else
	echo -e "${YELLOW}[-] ${RESET}No IP Adress given, so just saving current info as a reset file"
	echo -e "	Usage: ${0} <ip>\n"
	exit 1
fi

# Collect current network details
gateway=`route -n | grep 'UG[ \t]' | awk '{print $2}'`
iface=`route -n | grep 'UG[ \t]' | awk '{print $8}'`
iln=`ifconfig $iface | grep inet\ addr`
# e.g. iln=          inet addr:192.168.80.133  Bcast:192.168.80.255  Mask:255.255.255.0

for i in $iln ; do
	if [ "${i:0:6}" == "Bcast:" ] ; then
		bcast=${i:6}
	elif [ "${i:0:5}" == "Mask:" ] ; then
		mask=${i:5}
	fi
done

ifconfig $iface $iaddr netmask $mask broadcast $bcast
file=/etc/resolv.conf
if (grep -q "${gateway}" "${file}"); then
	echo "gateway already in resolv file"
else
	[ -e "${file}" ] && cp -n $file{,.bkup}
	echo "nameserver ${gateway}" >> "${file}"
fi
echo -e "${GREEN}[*] ${RESET}New IP Address: ${iaddr}"
echo -e "${GREEN}[*] ${RESET}Using Interface: ${iface}"
echo -e "${GREEN}[*] ${RESET}Current Gateway is: ${gateway}"
