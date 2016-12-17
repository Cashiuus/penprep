#!/usr/bin/env bash
#
# Purpose: Setup pygraphviz in order to use django-extensions python library


#Install Homebrew app
brew install graphviz
brew cleanup

# Activate virtualenv - python side
workon
echo ""
echo "Type name of virtualenv you want to use: "
read choice
workon choice
[[ $? -ne 1 ]] && echo "[-] Error activating virtualenv, try again..." && exit 1
pip install --upgrade pip

# Install py library now using custom include directory paths for the 'c' libraries
pip install pygraphviz --install-option="--include-path=/usr/local/include/graphviz/" --install-option="--library-path=/usr/local/lib/graphviz"
