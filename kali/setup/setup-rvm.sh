#!/bin/bash
# Perform a "mixed mode" RVM install into user's $HOME environments
# Must run this from a non-root user account to work correctly!!!

# Install RVM stable with Ruby
# backslash before curl is to prevent misbehaving if it's aliased with ~/.curlrc
\curl -sSL https://get.rvm.io | sudo bash -s stable --ruby

# Add user to group rvm
usermod -a -G rvm predator
#useradd -G rvm [username]

# Enable RVM for use
source /etc/profile.d/rvm.sh

