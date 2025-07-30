#!/bin/bash
# ============================================================================= #

### CONSTANTS

PY3_VERSION='3.6.2'     # 3.7.0 is out now also

TOR_URL='https://www.torproject.org/dist/torbrowser/7.0.5/tor-browser-linux64-7.0.5_en-US.tar.xz'

# ============================================================================= #
# ============================================================================= #

# ========================[ Base load ]========================
sudo yum update -y


sudo yum install git wget



# ============================================================================= #










# ============================================================================= #
#                               Setup Python
# ============================================================================= #

# =================[    Install Python 3    ]===================== #
# Build python 3: http://ask.xmodulo.com/install-python3-centos.html
#sudo yum install yum-utils
#sudo yum-builddep python
#curl -O https://www.python.org/ftp/python/


# Install compilers and tools
sudo yum groupinstall -y "development tools"
# Libraries needed during compilation to enable all features of Python:
sudo yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel expat-devel

# Python 2.7.14:
#wget http://python.org/ftp/python/2.7.14/Python-2.7.14.tar.xz
#tar xf Python-2.7.14.tar.xz
#cd Python-2.7.14
#./configure --prefix=/usr/local --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
#make && make altinstall



echo "[*] Download and compile Python 3 - starting..."
cd /tmp
# Python 3.6.x:
wget http://python.org/ftp/python/$PY3_VERSION/Python-$PY3_VERSION.tar.xz
tar xf Python-$PY3_VERSION.tar.xz
cd Python-$PY3_VERSION
# TODO: This step not working, permission denied, maybe /usr/local doesn't exist yet?
./configure --prefix=/usr/local --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
sudo make && sudo make altinstall

echo "[*] Python 3 interpreter is now at: /usr/local/bin/python3.6"







# ================================================================================
#                               Tor Setup
# ================================================================================
# Setup tor on CentOS 7: https://stackoverflow.com/questions/41337082/install-tor-on-a-centos-7-server
# Build Relay: https://www.comparitech.com/blog/vpn-privacy/build-tor-relay-node/

# Setup OnionShare: https://www.ostechnix.com/onionshare-share-files-of-any-size-securely-and-anonymously/


### NOTES
# It takes 68 days for a new relay to become full blown and even 
# elibible as a possible entry point for other clients.
# ================================================================================


# ==================[ Install Tor ]=================
# CentOS no longer recommends using their repository, so use epel instead


sudo yum install epel-release
sudo yum install tor



# ===================[ Install OnionShare for file sharing ]=======================
sudo sudo dnf install rpm-build python3-flask python3-stem python3-qt5 -y
./install/build_rpm.sh
sudo yum install dist/onionshare-*.rpm -y



# ===============[ Install Tor Browser ]==============
cd ~
mkdir git && cd git
git clone https://github.com/micahflee/torbrowser-launcher
cd torbrowser-launcher
# Prerequisites for Tor Browser, i think?
sudo yum install python-psutil python-twisted gnupg fakeroot rpm-build python-txsocksx tor pygtk2






## Debian
sudo apt-get -y install tor tor-arm

# Launch the arm app that shows you stats of your relay, via:
#sudo arm










# ===================== [ Help Reference ] ========================= #

# yum
#   distro-sync             # like apt-get update - syncs package lists
#   check-update            # Check if machine has updates available
#                               Returns 0 if no updates, 1 if error occurred
#   repolist                # A list of configured repositories
#
#   info
#   clean
#   search
#   reinstall
#   
#
#
#
#   -q, --quiet
#   -y, --assumeyes         # Answer yes for user input automatically
#   --assumeno              # Answer no automatically
#
#
#
#
#
###         dnf
# [sudo] dnf [options] <command> [<arguments>...]
#
#
#
#
#



# =========[ Setup DNF - Dandified Yum (next-gen yum) ]===========
# WARNING: EPEL 7 DNF is very old and has issues to include security flaws. This appears to be the reason it was removed. That said here is the work around to get it working on Centos 7.

# https://support.rackspace.com/how-to/install-epel-and-additional-repositories-on-centos-and-red-hat/
# https://www.rootusers.com/how-to-install-dnf-package-manager-in-centosrhel/


# TODO: This entire section disabled because it shouldn't be in use.


#sudo yum install epel-release -y
#sudo yum install dnf -y

# If that command doesn’t work, perhaps because the CentOS Extras repository 
# is disabled, use the following manual installation instructions based on 
# your distribution version:

#cd /tmp
#wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#sudo rpm -Uvh epel-release-latest-7*.rpm



# IUS Repository
# The IUS repository provides newer versions of some software in the official 
# CentOS and Red Hat repositories. The IUS repository depends on the EPEL repository.
#cd /tmp
#wget https://centos7.iuscommunity.org/ius-release.rpm
#sudo rpm -Uvh ius-release*.rpm


# Add DNF stack repository to our repo list
#FIN='/tmp/dnf-stack-el7.repo'
#FOUT='/etc/yum.repos.d/dnf-stack-el7.repo'
#cat <<EOF > $FIN
#[dnf-centos]
#name=Copr repo for dnf-stack-el7 owned by @rpm-software-management
##baseurl=https://copr-be.cloud.fedoraproject.org/results/@rpm-software-management/dnf-stack-el7/epel-7-\$basearch/
#baseurl=https://copr-be.cloud.fedoraproject.org/results/@rpm-software-management/dnf-centos/epel-7-x86_64/
#skip_if_unavailable=True
#gpgcheck=1
#gpgkey=https://copr-be.cloud.fedoraproject.org/results/@rpm-software-management/dnf-centos/pubkey.gpg
#enabled=1
#enabled_metadata=1
#EOF
# Place in final destination and ensure perms are correct
#sudo mv $FIN $FOUT
#sudo chmod 0644 $FOUT
# ================================================================================== #



