Penprep
========

[![Language](https://img.shields.io/badge/Language-BASH-blue)]
[![Twitter Follow](https://img.shields.io/twitter/follow/Cashiuus?style=social)](https://twitter.com/Cashiuus)


## Overview
This project is primarily an OS setup and prep toolkit with a pentesting focus to get up and running without all the boring setup of various tools. First, you'll want to check out the `system-setup` scripts. There are many projects out there that accomplish system setups in a similar manner, but none of them go beyond the basics. These helpers serve to accomplish every single task needed to install a particular environment or tool.

If you are running on a kali system, a quick base setup with tweaks can be found by running `setup-kali-base.sh`.


## Usage
For now, this is bare bones use of this project, and I use most on a new kali or debian install:

1. `penprep/dotfiles/install-simple.sh` - Install dotfiles for a better console experience (However, next script will also do this step by prompting if you'd like to install them.)
2. `penprep/system-setup/kali/setup-kali-base.sh` - Take a vanilla Kali system and do all the initial setup
3. `penprep/system-setup/kali/setup-kali-tweaks.sh` - Customize kali by creating directories, symlinks, and GUI configuration adjustments (e.g. Gedit, Nautilus, GNOME)
4. `penprep/system-setup/kali/setup-geany.sh` - Install and pre-configure Geany IDE
5. `penprep/system-setup/kali/setup-python.sh` - Install and setup Python 2 & 3 along with initial set of pip packages and pre-made virtualenvs ready to be put to use.


## Settings
The "system-setup" component of this project will create a configuration base if you run any of the setup scripts.

* Configuration Path/File: `${HOME}/.config/penbuilder/settings.conf`






== Other Dotfiles Projects Inspiration ==
* Github - https://dotfiles.github.io
* YADR - https://github.com/skwp/dotfiles
