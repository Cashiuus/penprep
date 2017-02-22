#!/bin/bash
# setup-ipv6.sh
#
# HE: https://tunnelbroker.net/
# Help: https://chronos-tachyon.net/reference/debian-ipv6-and-hurricane-electric.html
# Test IPv6 Connectivity: http://docs.menandmice.com/display/MM/How+to+test+IPv6+connectivity
#
#
#192.168.1.0 - fe80:0:0:0:0:0:c0a8:100/120
#192.168.1.1 - 0:0:0:0:0:ffff:c0a8:101
#192.168.1.255 - 0:0:0:0:0:ffff:c0a8:1ff


# Possibly, you can install gogoc, which is a ipv6 tunnel broker client
#apt-get install gogoc
# Another is called miredo to support IPv6 tunneling through NATs
# Miredo is a Teredo client, encapsulating IPv6 packets into UDP/IPv4 datagrams
# to allow hosts behind NAT devices to access the IPv6 Internet.
#apt-get install miredo



# ----------------------------------------------------
#   Static Native Configuration if ISP Supports IPv6
# ------------------------------------------------------

# Add this to the /etc/network/interfaces file
auto he-ipv6
iface eth0 inet6 static
    # This must be a public-facing IP, not a NAT'ed IP
    address 
    netmask 64
    gateway 












# Add this to the /etc/network/interfaces file
auto he-ipv6
iface he-ipv6 inet6 v4tunnel
	address 2001:470:70:90f::2
	netmask 64
	endpoint 216.66.80.162
	local 71.162.202.12
	ttl 255
	gateway 2001:470:70:90f::1

# Restart networking and you'll have a new interface running
service networking restart
sleep 5
ifconfig


# For tunneling, I ensured that IPv6 is enabled on the ActionTech router
# but i'm still not able to connect to http://ipv6.google.com
echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
#2001:4860:4860::8844

# Verify IPv6 Networking
ip -6 route show


# Determine the IPv6 Address of a target host
host -t AAAA ipv6.google.com

# Ping that target using either hostname or IPv6 address from above
ping6 -c 4 ipv6.google.com

