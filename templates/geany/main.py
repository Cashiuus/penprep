#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# File:         file.py
# Author:       Cashiuus
# Created:      20-May-2021     -     Revised:
#
# Depends:      n/a
# Compat:       3.7+
#
#-[ Usage ]---------------------------------------------------------------------
#
#
#
#
# ==============================================================================
__version__ = '0.0.1'
__author__ = 'Cashiuus'
__license__ = 'MIT'
__copyright__ = 'Copyright (C) 2021 Cashiuus'

## =======[ IMPORT & CONSTANTS ]========= ##
import argparse
import errno
import os
import platform
import subprocess
import sys
from random import randrange
from time import sleep, strftime

try: from colorama import init, Fore
except ImportError: pass

# if using, these must go below `import sys`
if sys.version > '3':
    import urllib.parse as urlparse
    import urllib.parse as urllib
else:
    import urlparse
    import urllib


VERBOSE = 1
DEBUG = 0
#MY_SETTINGS = 'settings.conf'
USER_HOME = os.environ.get('HOME')
ACTIVE_SHELL = os.environ['SHELL']
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SAVE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saved')
LOG_FILE = os.path.join(BASE_DIR, 'debug.log')
#FILE_NAME_WITH_DATE_EXAMPLE = "data_output-" + strftime('%Y%m%d') + ".txt"


## =========[  TEXT COLORS  ]============= ##
class Colors(object):
    """ Access these via 'Colors.GREEN'   """
    GREEN = '\033[32;1m'    # Green
    YELLOW = '\033[01;33m'  # Warnings/Information
    RED = '\033[31m'        # Error or '\033[91m'
    ORANGE = '\033[33m'     # Debug
    BLUE = '\033[01;34m'    # Heading
    PURPLE = '\033[01;35m'  # Other
    GREY = '\e[90m'         # Subdued Text
    BOLD = '\033[01;01m'    # Highlight
    RESET = '\033[00m'      # Normal/White
    BACKBLUE = '\033[44m'   # Blue background
    BACKCYAN = '\033[46m'   # Cyan background
    BACKRED = '\033[41m'    # Red background
    BACKWHITE = '\033[47m'  # White background


# ==========================[ BEGIN APPLICATION ]========================== #











# ---------------------
#       SHUTDOWN
# ---------------------
def shutdown_app():
    #logger.debug("shutdown_app :: Application shutdown function executing")
    print("Application shutting down -- Goodbye!")
    exit(0)

# ---------------------
#   main
# ---------------------
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
    parser.add_argument('target', help='IP/CIDR/URL of target')
    parser.add_argument("-i", "--input-file", dest='input', nargs='*',
                        help="Specify a file containing the output of an nmap "
                             "scan in xml format.")
    parser.add_argument("-o", "--output-file", dest='output',
                        help="Specify output file name")
    parser.add_argument('--url', action='store', default=None, dest='url',
                        help='Pass URL to request')

    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    parser.add_argument("-d", "--debug", action="store_true",
                        help="Display error information")


    args = parser.parse_args()

    # If we have a mandatory arg, use it here; if not given, display usage
    if not args.target:
        parser.print_help()
        exit(1)

    # Now store our args into variables for use
    # NOTE: infile will be a list of files, bc args.filename accepts multiple input files
    infile = args.input
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


# -------------------
#       LOGGING
# -------------------
#   Logging Cookbook: https://docs.python.org/3/howto/logging-cookbook.html#logging-cookbook
#
# Usage:
#   This first line must be at top of the file, outside of any functions, so it's global
#   logger = logging.getLogger(__name__)
#
#   Remainder of setup can be placed into main, or its own function and called from main
#   Tip: the level set in logger determines what messages are sent to handlers, always start with DEBUG
#   logging.basicConfig(level=logging.DEBUG)
#   Console Handler - this is so we can change log levels separate from file writing
#   ch = logging.StreamHandler()
#   Here is where we can condition whether or not to show DEBUG messages in console
#   if DEBUG:
#       ch.setLevel(logging.DEBUG)
#   else:
#       ch.setLevel(logging.INFO)
#   # FileHandler accepts string or Path object for filename; mode 'w' truncates log, 'a' appends
#   fh = logging.FileHandler(LOG_FILE, mode='w')
#   fh.setLevel(logging.DEBUG)
#   # Configure a good format for the logs to save as
#   See here: https://docs.python.org/3/library/logging.html#logrecord-attributes
#   formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(funcName)s : %(message)s')
#   fh.setFormatter(formatter)
#   # Add the handlers to the logger
#   logger.addHandler(fh)
#   logger.addHandler(ch)
#   Now, use configured logger to log messages
#   logger.debug('Logger initialized')
#
# logging statements you can place in code - note: use logger to apply our handler settings
#   logger.debug('foo')
#   logger.debug('var: url_slices is %s', url_slices)
#   logger.error('foo', exc_info=True)
#   logger.info('Destination File already exists')



# =========================================================================== #
# ================================[ RECIPES ]================================ #
#
#

# ========================[  CORE UTILITY FUNCTIONS  ]======================== #
# Check - Root user
# TODO: If not root, run with sudo
def root_check():
    if not (os.geteuid() == 0):
        print("[-] Not currently root user. Please fix.")
        sys.exit(1)
    return


def delay(max=10):
    """Generate random number for sleep function
            Usage: time.sleep(delay(max=30))
    """
    return randrange(2, max, 1)


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


def printer(msg, color=Colors.RESET):
    """
    A print helper with colors for console output. Not for logging purposes.

    Usage:  printer("\n[*] Installing Repository: {}".format(app), color=GREEN)
    """
    if DO_DEBUG and color == Colors.ORANGE:
        print("{0}[DEBUG] {1!s}{2}".format(Colors.ORANGE, msg, Colors.RESET))
    else:
        print("{0}{1!s}{2}".format(color, msg, Colors.RESET))
    return


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
