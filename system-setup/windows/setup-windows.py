#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# =============================================================================
# File:				setup-windows.py
# Dependencies:		n/a
# Compatibility:	2.7+
# Version:
# Creation Date:	22-SEP-2015   -   Revised Date:		17-OCT-2018
# Author:			Cashiuus
#
# Purpose: 			Setup Windows 7 with certain configs (Win 10 in the works)
#
# =============================================================================
#
#
# Configure recurring scheduled tasks
# =============================================================================
# TODO:
#   1. Figure out how to add virtualenvwrapper-win cmds to auto-completion
#
#
#
# == Python on Windows Notes ==
# Windows will concatenate User variables after System variables, which may cause unexpected results when modifying PATH.
#
# If using WinXP, you must install 3.4 or older. Newer versions do not work.
#
#
#   - http://docs.python-guide.org/en/latest/starting/install/win/
#
# =============================================================================
import os


__version__ = 0.3
__author__ = 'Cashiuus'
__license__ = 'MIT'
__copyright__ = 'Copyright (C) 2018 Cashiuus'


# Folders to create in our new system
FOLDERS = [
    r'c:\Scripts\backup-windows\Scans',
    r'c:\Scripts\virtualenvs',
    r'c:\Tools',
    ]

PIP_CORE_PACKAGES = [
    'beautifulsoup4',
    'colorama',
    'mechanize',
    'Pillow',
    'scrapy',
    'requests',
    'virtualenv',
    'virtualenvwrapper-win',
    'xlrd',
    'xlwt',
]

# These don't install via pip, typically you download them and manually install
# via: pip install somepackage-1.0.whl
PYTHON_SPECIAL_PACKAGES = [
    # lxml you can install via pip only if you are using 32-bit python,
    # we use 64-bit so it's in this special group
    'lxml',
    'numpy',
    'pywin32',
]


# This is for virtualenvwrapper-win
# NOTE: Removed scrapy from my pip installs because it has a TON of dependencies. Only install it if actually needed.
CUSTOM_VIRTUALENV_SCRIPTS = os.path.join()
POSTMKVIRTUALENV_SCRIPT = """# Postmkvirtualenv creation script
pip install beautifulsoup4
pip install pep8
pip install requests
"""

DJANGO_REQUIREMENTS = """cookiecutter
django
django-debug-toolbar
django-environ
django-extensions
django-import-export
django-secure
psycopg2
pygraphviz
six
"""


# -----------------------------------------------------------------------------
#                               Begin Setup
# =============================================================================
def create_file(path):
    # Use os.open to create a file if it doesn't already exist
    flags = os.O_CREAT | os.O_EXCL | os.O_WRONLY
    try:
        file_handle = os.open(path, flags)
    except OSError as e:
        if e.errno == errno.EEXIST:
            # The file already exists
            pass
            return False
        else:
            # Something went wrong, troubleshoot error
            raise
    else:
        # No exception, so file was hopefully created.
        with os.fdopen(file_handle, 'w') as file_obj:
            file_obj.write("### Log File")
        return True

def make_dirs(path):
    """
    Helper function to make all directories necessary in the desired path
    """
    if not os.path.isdir(path):
        try:
            os.makedirs(path)
        except:
            print("[-] Error creating folder: {}".format(str(path)))
    return

def create_folders():
    # Create folder structure
    for i in FOLDERS:
        try:
            os.mkdir(i)
        except:
            print("[-] Error creating folders")
    return


# ==========================[ Python 2.7 ]=========================== #
def install_python2(PKGS):
    PY2_INSTALL_PATH = r'C:\Python27\'

    # Python 2.7 method
    os.system('python -m pip install --upgrade pip')

    # Install all of our core PIP packages
    for i in PKGS:
        # TODO: Fix this command call
        print('[*] Installing via pip: {}'.format(i))
        os.system('py -3 -m pip install', i)
        # pip freeze
        # pip list --outdated
    return


# ----------------[ Setup a virtualenvwrapper-win package ]-------------------------- #
# This assumes virtualenvwrapper-win was already installed
# After installing, make sure that your Python's "Scripts" directory is in your PATH
#   e.g. C:\Python27\Scripts
# Default virtualenvwrapper envs will be at %WORKON_HOME%
# Default WORKON_HOME = %USERPROFILE%\Envs

# To run some commands after mkvirtualenv you can use hooks.
# First you need to define VIRTUALENVWRAPPER_HOOK_DIR variable.
# If it is set, mkvirtualenv will run postmkvirtualenv.bat script from that directory.


# Setup a post-creation script for all new virtualenvs



# Create a virtualenv for python 2.7
mkvirtualenv py27







# TODO: not sure what this is atm
""""# Pyinstaller.bat
@echo
off
python
Configure.py
python
Makespec.py - -onefile - -noconsole
pybd.py
python
Build.py
shellshell.spec
"""


# ==========================[ Python 3.6 ]=========================== #
# Article: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-local-programming-environment-on-windows-10

# Install silently for ALL USERS and add to PATH
# Default install path: C:\Program Files\Python35 or %ProgramFiles%\Python X.Y
# Default install path: %LocalAppData%\Programs\PythonXY
os.chdir('C:\Users\Primary\Downloads')
os.system('python-3.9.0-amd64.exe /quiet InstallAllUsers=1 PrependPath=1')

#PY3_INSTALL_PATH = os.path.join(os.environ('user'), 'AppData', 'Local', 'Programs', 'Python')
#PY3_INSTALL_PATH = r'c:\Program Files\Python35'



# Python 3.5 method
# For an ALL-USERS installation, you need an admin cmd to run this
py -3 -m pip install --upgrade pip

# Install all of our core PIP packages
for i in PIP_PKGS_LIST:
    # TODO: Fix this command call
    print('[*] Installing via pip: {}'.format(i))
    os.system('py -3 -m pip install', i)


# Save original path
#here

# Set new path

# Python 3 path adding
#PY3_NEW_PATH = r'c:\Program Files\Python35\;C:\Program Files\Python35\Scripts\;%path%'


# Create a virtualenv
#PYVENV_PATH = os.path.join(PY3_INSTALL_PATH, 'Tools', 'scripts')

# This isn't needed, set WORKON_PATH to dir you want to store envs into, default is %USERPROFILE%\Envs
#os.chdir('c:\Scripts\virtualenvs')

#ENV_SCRIPT = r'C:\Program Files\Python35\Scripts\mkvirtualenv'
#ENV_NAME = 'py35'

# set PYTHONHOME variable so the mkvirtualenv.bat file will skip setting it based on system PATH
# Thereby specifying which interpreter we want for this virtualenv creation
#PYTHONHOME="C:\Program Files\Python35"
# This didn't work - os.environ['PYTHONHOME'] = "C:\Program Files\Python35"



# run ENV_SCRIPT ENV_NAME




# After setting up, restore original PATH
#here



# ================[ Python Startup Activities ]==================
# You can place a file path in env variable PYTHONSTARTUP and it will execute this script when python is launched
# https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPATH




# Create Django requirements file for use in quickly setting up virtualenvs
f = open("")











# ======================[ Scheduled Tasks ]============================ #
#	1. Python-GetPublicIP - Daily logging of public IP for reference purposes
#	2. Python-BackupFiles - Daily backup to Dropbox

cmds = [
    # Use 'pythonw.exe' to suppress terminal popping up.
    'cmd.exe /c schtasks /Create /F /SC DAILY /ST 11:00 /TN Python-GetPublicIP /TR "pythonw C:\Scripts\backup-windows\getmypublic-ip.py"',
    'cmd.exe /c schtasks /Create /F /SC DAILY /ST 17:00 /TN Python-GetPublicIP /TR "pythonw C:\Scripts\backup-windows\backup-files.py"',
    ]
for i in cmds:
    try:
        os.system(cmds[i])
    except:
        print("[-] Error creating scheduled task")

# Note: Launch a binary and bypass UAC
#	C:\Windows\system32\cpalua.exe -a <binary.exe>

# CCleaner
#"C:\Program Files\CCleaner\CCleaner.exe" $(Arg0)




# -------- [ SysInternals - AccessEnum Scan] ------------ #
os.system("cmd.exe")



# -------- [ SysInternals - Autoruns Scan] ------------ #
os.system("cmd.exe")





# -----------------------------[ MAIN ROUTINE ]------------------------------ #
# =========================================================================== #
def main():
    create_folders()
    install_python2()

    return


if __name__ == '__main__':
    main()


# ----------------------------------[ NOTES ]-------------------------------- #
# =========================================================================== #
# Python INI Customization
# Customization via INI files
# Two .ini files will be searched by the launcher - py.ini in the current user’s “application data” directory (i.e. the directory returned by calling the Windows function SHGetFolderPath with CSIDL_LOCAL_APPDATA) and py.ini in the same directory as the launcher. The same .ini files are used for both the ‘console’ version of the launcher (i.e. py.exe) and for the ‘windows’ version (i.e. pyw.exe)
#
# Customization specified in the “application directory” will have precedence over the one next to the executable, so a user, who may not have write access to the .ini file next to the launcher, can override commands in that global .ini file)
#For example:
#
#Setting PY_PYTHON=3.1 is equivalent to the INI file containing:
#[defaults]
#python=3.1

#Setting PY_PYTHON=3 and PY_PYTHON3=3.1 is equivalent to the INI file containing:
#[defaults]
#python=3
#python3=3.1




# -=[ pyvenv syntax ]=-
"""
usage: venv [-h] [--system-site-packages] [--symlinks | --copies] [--clear]
            [--upgrade] [--without-pip]
            ENV_DIR [ENV_DIR ...]

Creates virtual Python environments in one or more target directories.

positional arguments:
  ENV_DIR             A directory to create the environment in.

optional arguments:
  -h, --help             show this help message and exit
  --system-site-packages Give the virtual environment access to the system
                         site-packages dir.
  --symlinks             Try to use symlinks rather than copies, when symlinks
                         are not the default for the platform.
  --copies               Try to use copies rather than symlinks, even when
                         symlinks are the default for the platform.
  --clear                Delete the contents of the environment directory if it
                         already exists, before environment creation.
  --upgrade              Upgrade the environment directory to use this version
                         of Python, assuming Python has been upgraded in-place.
  --without-pip          Skips installing or upgrading pip in the virtual
                         environment (pip is bootstrapped by default)
"""
