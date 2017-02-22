#!/bin/sh

# MAC OS X Update script


cd ~

brew update &> /dev/null
pip install --upgrade setuptools
pip install --upgrade pip
# List all outdated apps to manually update them
pip list --outdated
echo "Upgrade these by typing: pip install --upgrade <pkg>"