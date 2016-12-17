#!/usr/bin/env bash
# ==============================================================================
# File:     install-homebrew.sh
#
# Author:   Cashiuus
# Created:  09-JUN-2016     -     Revised: 16-DEC-2016
#
#-[ Usage ]---------------------------------------------------------------------
#       Install command-line tools using Homebrew.
#
#   1. Modify constants in script below
#   2. Run script and enjoy
#
#-[ Notes/Links ]---------------------------------------------------------------
#   - Credit to: https://raw.githubusercontent.com/mathiasbynens/dotfiles/master/brew.sh
#   - Credit: https://miteshshah.github.io/mac/things-to-do-after-installing-mac-os-x/#install-homebrew
#
#-[ References ]----------------------------------------------------------------
#   - Another option-Vagrant VMs: http://joebergantine.com/projects/django/django-newproj/
#   - Tut: https://hackercodex.com/guide/mac-osx-mavericks-10.9-configuration/
#
#-[ Copyright ]-----------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
# ==============================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
PURPLE="\033[01;35m"   # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
DEBUG=false

echo "XCode already installed? If not, cancel script and install XCode via AppStore first (10-minute install)..."
read -n 7
xcode-select --install
sudo xcodebuild -license

which brew
if [[ $? -eq 1 ]]; then
    echo "[*] Homebrew not yet installed. Installing now..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi
brew doctor

# Add brew to PATH
grep -q '^PATH=/usr/local/bin:/usr/local/sbin:$PATH' ~/.bash_profile 2>/dev/null \
    || echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
source ~/.bash_profile

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade --all

# Enable version functionality with installing packages
brew tap homebrew/versions

# Need Cask for installing fully-built applications
brew cask install kismac
brew cask install sublime-text


# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names



# ============[ Install Bash 4 ]=============== #
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
# TODO: bash 4 isn't completely working and becoming the default shell, fix this before enabling.
#brew install bash

# Switch to using brew-installed bash as default shell
#if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
#  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
#  chsh -s /usr/local/bin/bash;
#fi;

# New bash-completion -- This might require sudo to install
# Having errors with this version, so sticking with regular version for now
#brew install bash-completion2


#Add the following to your ~/.bash_profile:
#  if [ -f $(brew --prefix)/share/bash-completion/bash_completion ]; then
#    . $(brew --prefix)/share/bash-completion/bash_completion
#  fi
# -------------------------------------------- #
# =============[ Install Zsh ]================ #
#brew install zsh
#brew install zsh-completions
#brew install zsh-syntax-highlighting
# -------------------------------------------- #

# Install `wget` with IRI support.
brew install wget --with-iri

# Install RingoJS and Narwhal.
# Note that the order in which these are installed is important;
# see http://git.io/brew-narwhal-ringo.
#brew install ringojs
#brew install narwhal

# Install more recent versions of some OS X tools.
brew install vim --with-override-system-vi
# grep - the argument makes it the default grep instead of prefixing it with 'g'
brew install homebrew/dupes/grep --with-default-names
brew install homebrew/dupes/openssh
brew install homebrew/dupes/screen

# [Cashiuus] Original script install php56, but php70 is the latest version
brew install homebrew/php/php70 --with-gmp

# Install font tools.
#brew tap bramstein/webfonttools
#brew install sfnt2woff
#brew install sfnt2woff-zopfli
#brew install woff2

# Install some CTF tools - https://github.com/ctfs/write-ups
brew install acrogenesis/macchanger/macchanger
brew install aircrack-ng
brew install bfg
brew install binutils
# [Cashiuus] binwalk is a Firmware Analysis Tool - http://binwalk.org
brew install binwalk
brew install cifer
brew install dex2jar
brew install dns2tcp
brew install dnsmap
#brew install ettercap
brew install fcrackzip
brew install foremost
brew install hashpump
brew install hydra
brew install john
brew install knock
# [Cashiuus] mtr is a traceroute tool
brew install mtr
# TODO: Can get mtr version after install via: sudo mtr --version (response: mtr 0.87)
#   store response version for next lines
#MTR_VERSION=$(sudo mtr --version)
sudo chown root:wheel /usr/local/Cellar/mtr/0.87/sbin/mtr
sudo chmod u+s /usr/local/Cellar/mtr/0.87/sbin/mtr
# Add this to ~/.bash_aliases
grep -q 'alias mtr=/usr/local/sbin/mtr' ~/.bash_aliases 2>/dev/null \
    || echo 'alias mtr=/usr/local/sbin/mtr' >> ~/.bash_aliases
brew install netpbm
brew install nikto
brew install nmap
#brew install ophcrack
brew install pdfgrep
brew install pngcheck
brew install privoxy
# Autostart: brew services start privoxy
# Manual Start: privoxy /usr/local/etc/privoxy/config

brew install proxychains-ng
brew install skipfish
brew install socat
brew install sqlmap
brew install stunnel
brew install tcpflow
brew install tcpreplay
brew install tcptrace
brew install tor
# Sample torrc file located at: /usr/local/etc/tor
# Autostart: brew services start tor
# Manual Start: tor start

brew install torsocks
brew install ucspi-tcp # `tcpserver` etc.

# This pkg deprecated.
#brew install xpdf

brew install xz
# App to show the current wifi password; requires keychain access to work
brew install wifi-password

# Install other useful binaries.
brew install ack
brew install dark-mode
#brew install exiv2
#brew install fail2ban
brew install git
brew install git-lfs
brew install imagemagick --with-webp
brew install lua
brew install lynx
#brew install mongodb --with-openssl
#brew install nginx
brew install p7zip
#brew install phantomjs
brew install pigz
# pv: monitor data's progress through a pipe
#brew install pv
brew install pwgen
brew install rename
brew install rhino
brew install sqlite
brew install sqlitebrowser
brew install speedtest_cli
brew install ssh-copy-id
brew install sslscan
# Removing testssl as it no longer works correctly, ues sslscan instead
#brew install testssl
brew install tree
brew install vbindiff
brew install webkit2png
brew install zopfli

# -----[ Setup PostgreSQL DB for Metasploit and Django ]-----
# Get back to global in case we're in a virtualenv
deactivate

brew install postgresql
echo ""
echo "  === POSTGRESQL Cmds ==="
echo "\t- Clean up old installs: brew cleanup postgresql"
echo "\t- Autostart: brew services start postgresql"
echo "\t- Manual Start: postgres -D /usr/local/var/postgres"
echo ""

# -=[ Python/Django Dependencies ]=-
brew install python
pip install --upgrade pip setuptools

brew install graphviz
pip install psycopg2

# Remove outdated versions from the cellar.
brew cleanup
