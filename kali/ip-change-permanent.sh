#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: ipchange.sh                   (Update: 09-10-2015 #
#-Author------------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#                                                             #
# Credited: https://github.com/noureddin/bash-scripts/blob/master/admin_scripts/staticip
#
# Usage: script.sh [no args | ip | reset]
#        ipchange.sh 192.168.1.70                             #
#-------------------------------------------------------------#
GREEN="\033[01;32m"    # Success
RESET="\033[00m"       # Normal
YELLOW="\033[01;33m"   # Warnings/Information



if [ "$1" == "reset" ] ; then
	mv /etc/network/interfaces.reset /etc/network/interfaces
	echo -e "${GREEN}[*] ${RESET}Reset Successfully"
	/etc/init.d/networking restart
	exit 0
elif [[ "$1" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	new_iaddr=$1
else
	echo -e "${YELLOW}[-] ${RESET}No IP Adress given, so just saving current info as a reset file"
	echo -e "	Usage: ${0} [ip | reset]\n"
fi

# Collect current network details
gateway=`route -n | grep 'UG[ \t]' | awk '{print $2}'`
iface=`route -n | grep 'UG[ \t]' | awk '{print $8}'`
iln=`ifconfig $iface | grep inet\ addr`
# e.g. iln=          inet addr:192.168.80.133  Bcast:192.168.80.255  Mask:255.255.255.0
echo -e "${GREEN}[*] ${RESET}Using Interface: ${iface}"
echo -e "${GREEN}[*] ${RESET}Current Gateway is: ${gateway}"
for i in $iln ; do
	if [ "${i:0:5}" == "addr:" ] ; then
		iaddr=${i:5}
	elif [ "${i:0:6}" == "Bcast:" ] ; then
		bcast=${i:6}
	elif [ "${i:0:5}" == "Mask:" ] ; then
		mask=${i:5}
	fi
done
network=`/sbin/route -n | grep $iface | grep $mask | grep -v ^0 | awk '{print $1}'`

# Check if a new IP Address was given and set it here
if [ -v new_iaddr ]; then
	iaddr=$new_iaddr
	echo "[*] New IP was given and is now saved; New IP: ${iaddr}"
fi

# Create a reset file and populate with the current network details
file=/etc/network/interfaces
mv /etc/network/interfaces /etc/network/interfaces.reset
cat /etc/network/interfaces.reset | while read line ; do
	if [ "$line" != "# The loopback network interface" ] && [ -z $d ] ; then
		echo "${line}" >> /etc/network/interfaces
	elif [ "$line" == "# The loopback network interface" ] ; then
		d=1
		echo "${line}" >> /etc/network/interfaces
	elif [ "${line:0:2}" != "# " ] && [ $d -eq 1 ] ; then
		d=2
		cat <<EOF >> /etc/network/interfaces
auto lo
iface lo inet loopback

iface $iface inet static
address $iaddr
netmask $mask
gateway $gateway
network $network
broadcast $bcast
EOF
	elif [ $d -eq 2 ]; then
		# At this point, we have new config in, need to exclude old config
		[[ "${line}" == "auto lo" ]] && continue
		[[ "${line}" == "iface lo inet loopback" ]] && continue
		echo -e "First part of each line ${line:0:5}"
		if [ "${line:0:5}" == "iface" ]; then
			echo "[DEBUG] Found an interface with d=2 on line: ${line}"
			if [[ "$line" == *"$iface"* ]]; then
				# Found the existing interface
				d=3
			elif [ "${line:0:8}" != "iface lo" ]; then
				# This must be info for a different interface
				echo "${line}" >> /etc/network/interfaces
			fi
		else
			# This must be a non-iface line or lines for a diff iface
			echo "${line}" >> /etc/network/interfaces
		fi
		
	elif [ $d -eq 3 ]; then
		# Handle the old config and skip lines until we find a blank line
		if [ "${line}" == "" ]; then
			d=4
		fi
		continue
	elif [ $d -eq 4 ]; then
		# Old interface config now passed, copy anything left in file
		echo "${line}" >> /etc/network/interfaces
		continue
	fi
	echo -e "d is ${d} - line: ${line}"
done
/etc/init.d/networking restart
