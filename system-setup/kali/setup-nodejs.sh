#!/bin/bash

# Add GPG keys
curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
# Add APT repositories
echo "deb https://deb.nodesource.com/node buster main" > /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/node buster main" >> /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs
apt-get install -y npm


node -v
npm -v

