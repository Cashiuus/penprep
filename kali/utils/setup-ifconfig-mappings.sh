#!/bin/bash

# Examples: /usr/share/doc/ifupdown/examples/network-interfaces.gz
# See "get-mac-address.sh" for how to avoid issues from mapping if dev name changes
#
#


# /etc/network/interfaces
mapping eth0
    script /usr/local/sbin/map-scheme
    map HOME eth0-bridged
    map LAN eth0-lan

iface eth0-bridged
    address 192.168.1.50
    netmask 255.255.255.0
    # These directives will cause ifup/ifdown to fail if they fail
    # This can be avoided by suffixing them: up cmd || "true"
    #up dostuff
    #pre-up cmd
    #post-up cmd
    #down cmd
    #pre-down cmd
    #post-down cmd
    
# Pre/Post cmd directives also have access to a list of environment variables
# IFACE
# LOGICAL
# ADDRFAM
# METHOD (e.g. dhcp, static)
# MODE (start, stop)
# PHASE
# VERBOSITY - indicates whether verbosity was used or not
# PATH - The command search path

iface eth0-lan inet dhcp

#iface eth0-lan inet static
    #address 192.168.80.50
    #netmask 255.255.255.0


# Manually call these via:
# ifup eth0=HOME
# ifup eth0=LAN
