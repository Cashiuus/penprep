#!/bin/bash






# Fix kali's outdated gpg key
echo -e "[*] Adding new Kali key for apt repositories"
wget -q -O - https://archive.kali.org/archive-key.asc  | sudo apt-key add

echo -e "[*] Performing apt-get update..."
sudo apt-get update
