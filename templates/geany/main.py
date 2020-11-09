#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# File:         file.py
# Author:       Cashiuus
# Created:      14-Oct-2020     -     Revised:
#
# Depends:      n/a
# Compat:       3.7+ (As of Oct 14, 2020, Deb 10 is 3.7, Kali 2020 is 3.8.6)
#
#-[ Usage ]---------------------------------------------------------------------
#
#
#
#
#-[ Notes/Links ]---------------------------------------------------------------
#
#
#-[ Copyright ]-----------------------------------------------------------------
#
#  Copyright (C) 2020 Cashiuus <cashiuus@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ==============================================================================
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
__version__ = 0.1
__author__ = 'Cashiuus'
__license__ = 'MIT'
__copyright__ = 'Copyright (C) 2020 Cashiuus'
## ====[ Python 2/3 Compatibilities ]==== ##
try: input = raw_input
except NameError: pass
try: import thread
except ImportError: import _thread as thread
try: from colorama import init, Fore
except ImportError: pass
## =======[ IMPORT & CONSTANTS ]========= ##

import argparse
import errno
import os
import platform
import subprocess
import sys

from random import randrange
from time import sleep, strftime

VERBOSE = 1
DEBUG = 0
MY_SETTINGS = 'settings.conf'
USER_HOME = os.environ.get('HOME')
ACTIVE_SHELL = os.environ['SHELL']
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SAVE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saved')
LOG_FILE = os.path.join(BASE_DIR, 'log.txt')
PY3 = sys.version_info > (3,)
#PYTHON_VERSION = sys.version_info[0] + '.' + sys.version_info[1] + '.' + sys.version_info[2]


## =========[  TEXT COLORS  ]============= ##
GREEN = '\033[32;1m'    # Green
YELLOW = '\033[01;33m'  # Warnings/Information
RED = '\033[31m'        # Error
ORANGE = '\033[33m'     # Debug
BLUE = '\033[01;34m'    # Heading
PURPLE = '\033[01;35m'  # Other
GREY = '\e[90m'         # Subdued Text
BOLD = '\033[01;01m'    # Highlight
RESET = '\033[00m'      # Normal/White


# ========================[  CORE UTILITY FUNCTIONS  ]======================== #
# Check - Root user
# TODO: If not root, run with sudo
def root_check():
    if not (os.geteuid() == 0):
        print("[-] Not currently root user. Please fix.")
        sys.exit(1)
    return


def delay():
    """Generate random number for sleep function"""
    return randrange(2, 8, 1)


def install_pkg(package):
    pip.main(['install', package])
    if platform.system() == 'Linux':
        if os.geteuid() != 0:
            print('\n' + RED + '[-]' + YELLOW + ' Please Run as Root!' + '\n')
            sys.exit()
        else:
            pass
    else:
        pass


def make_dirs(path):
    """
    Make all directories en route to the full provided path
    """
    # If 'path' is a single directory path, create it, else treat as a list of paths
    # for i in path:
    if not os.path.isdir(path):
        try:
            os.makedirs(path)
        except:
            print("[ERROR] Error creating directory: {}".format(str(path)))
    return


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


# -------------------------
#   Git helper functions
# -------------------------
def locate_directories(pattern, root='/'):
    """
    Locate all occurrences of a directory, such as all .git repositories,
    creating a list in order to update them all.

    Usage:  for i in locate('.git'):
                dir_repo, tail = os.path.split(i)
                # Build a list of git clones on filesystem, absolute paths
                my_apps.append(dir_repo)
                # Or do something with each one in the loop
                git_update(dir_repo)
    """
    for path, dirs, files in os.walk(os.path.abspath(root)):
        for filename in fnmatch.filter(dirs, pattern):
            yield os.path.join(path, filename)


def git_owner(ap):
    """
    Get the owner for existing cloned Git repos
    the .git/config file has a line that startswith url that contains remote url
    Unfortunately, there doesn't appear to be any way to get master owner for forks :(

    :param ap:
    :return:
    """
    with open(os.path.join(ap, '.git', 'config'), 'r') as fgit:
        #for line in fgit.readlines():
        #    if line.strip().startswith('url'):
        #        owner_string = line.strip().split(' ')[2]
        owner_string = [x.strip().split(' ')[2] for x in fgit.readlines() if x.strip().startswith('url')]
    return owner_string[0]


def git_update(git_path):
    """
    Update an existing git cloned repository.

    :param git_path:
    :return:
    """
    if os.path.isdir(os.path.join(git_path, '.git')):
        # The path is the root level of a git clone, proceed
        try:
            os.chdir(git_path)
            subprocess.call('git pull', shell=True)
            sleep(3)   # Sleep 3s
        except:
            print("[ERROR] Failed to update git repo at {0}".format(git_path))

    return



# -------------------
#       SHUTDOWN
# -------------------
def shutdown_app():
    print("Application shutting down -- Goodbye!")
    exit(0)


def printer(msg, color=ORANGE):
    """
    A print helper with colors for console output. Not for logging purposes.

    Usage:  printer("\n[*] Installing Repository: {}".format(app), color=GREEN)
    """
    if color == ORANGE and DO_DEBUG:
        print("{0}[DEBUG] {1!s}{2}".format(color, msg, RESET))
    elif color != ORANGE:
        print("{0}{1!s}{2}".format(color, msg, RESET))
    return

# -------------------
#       LOGGING
# -------------------

# Usage:
#   logger = logging.getLogger(__name__)
#   logging.basicConfig(level=logging.DEBUG)
#   handler = logging.FileHandler('debug.log')
#   handler.setLevel(logging.DEBUG)
#   # Configure a good format for the logs to save as
#   formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
#   handler.setFormatter(formatter)
#   # Add the handler to the logger
#   logger.addHandler(handler)
#   logger.debug('Logger initialized')
# logging statements you can place in code
#logger.debug('foo')
#logger.debug('var: url_slices is %s', url_slices)
#logger.error('foo', exc_info=True)
#logger.info('Destination File already exists')


# ==========================[ BEGIN APPLICATION ]========================== #










def main():
    """
    Main function of the script

    """
    # Quick 'n dirty args if not using argparse
    args = sys.argv[1:]

    if not args:
        print('Usage: [--flags options] [inputs] ')
        sys.exit(1)

    # -- arg parsing --
    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description="Description of this tool")
    parser.add_argument("-f", "--filename",
                        nargs='*',
                        help="Specify a file containing the output of an nmap "
                             "scan in xml format.")
    parser.add_argument("-o", "--output",
                        help="Specify output file name")
    parser.add_argument('--url', action='store', default=None, dest='url', help='Pass URL to request')

    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    parser.add_argument("-d", "--debug",
                        help="Display error information",
                        action="store_true")

    args = parser.parse_args()

    # If we have a mandatory arg, use it here; if not given, display usage
    if not args.filename:
        parser.print_help()
        exit(1)

    # Now store our args into variables for use
    # NOTE: infile will be a list of files, bc args.filename accepts multiple input files
    infile = args.filename
    outfile = args.output
    url = args.url


    #  -- Config File parsing --
    #config = ConfigParser()
    #try:
        #config.read(MY_SETTINGS)
        #config_value_format = config.get('youtube', 'format')
        # Split a list into strings from a config file
        #config_value_urls = config.get('youtube', 'urls')
        #urls = shlex.split(config_value_urls)
        #print("[DEBUG] urls: {0}".format(urls))

    try:
        # main application flow
        pass
    except KeyboardInterrupt:
        shutdown_app()
    return


if __name__ == '__main__':
    main()


# =========================================================================== #
# ================================[ RECIPES ]================================ #
#
#

# Enable install of pip requirements within same script file
import subprocess
import sys
requirements = [
    "requests",
    "colorama",
    "xi==1.15.0",
]


def install(packages):
    for package in packages:
        # Update this to use .run instead?
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
    return


#
#
# =========================================================================== #
