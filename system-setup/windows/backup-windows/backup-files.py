#!/usr/bin/env python
# -*- coding: utf-8 -*-
# =============================================================================
# Created:      01-July-2014          -           Revised Date:    21-Mar-2017
# File:         backup-files.py
# Depends:      colorama
# Compat:       2.7+
# Author:       Cashiuus - Cashiuus{at}gmail
#
# Purpose:      Backup certain files on a scheduled basis by running
#               this script from a Windows scheduled task.
#               The intended use is to backup from various sources, which
#               includes one defined USB drive, and saving all files both
#               as-is and compressed into a single '.zip' archive into the
#               specified Backups folder.
#
#               See the "defaults.py" or "settings.py" files to define params.
#
# =============================================================================
## Copyright (C) 2017 Cashiuus@gmail.com
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
# =============================================================================
from __future__ import absolute_import
from __future__ import print_function
## =======[ IMPORT & CONSTANTS ]========= ##
import errno
import fnmatch
import os
import pip
import re
import shutil
import sys
import time
import zipfile

__version__ = 2.0
__author__ = 'Cashiuus'
VERBOSE = 1
DEBUG = 0
# ========================[ CORE UTILITY FUNCTIONS ]======================== #
def install_pkg(package):
    pip.main(['install', package])

### Imports with exception handling
try: from colorama import init, Fore
except ImportError: install_pkg('colorama')
try: from colorama import init, Fore
except ImportError:
    print("[ERROR] Unable to locate or install pip package 'colorama'")
    exit(1)

def check_ccleaner():
    # If the .ini file does not exist, run the command to create them
    os.system('CCleaner.exe /EXPORT')


def create_file(path):
    """
    Create a file if it doesn't already exist.
    :param path: A full path to the desired file.
    :return:
    """
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
            file_obj.write("### Default Settings for Windows Backup Script\n\n"
                           "import os\n\n"
                           "# If any source files are on a USB Drive, specify its letter here.\n"
                           "# The script checks that it's connected to avoid a conflict if it's\n"
                           "# not connected. If not using a USB, just leave variable blank.\n"
                           "USB_DRIVE = ''\n\n"
                           "BACKUP_PATH = os.path.dirname(os.path.abspath(__file__))\n"
                           "#BACKUP_PATH = os.path.join(os.path.expanduser('~'), 'Backups', "
                           "'Windows')\n\n"
                           "# Designate a file prefix for the output archive. This prefix will\n"
                           "# prepend a datestamp; e.g. 'Backup-Windows-20160503.zip\n"
                           "BACKUP_PREFIX = 'Backup-Windows-'\n\n"
                           "# Populate the empty list below with files you want to backup\n"
                           "LIST_BACKUP_FILES = [\n"
                           "    # Win Example: r'C:\Windows\System32\drivers\etc\hosts',\n"
                           "]\n")
        return True


def check_python_binary():
    # pythonw bug fix to send print() and sys.stdout()
    # calls to be ignored to avoid silent fails.
    if sys.executable.endswith("pythonw.exe"):
        sys.stdout = open(os.devnull, "w")
        sys.stderr = open(os.path.join(os.getenv("TEMP"), "stderr-" + os.path.basename(sys.argv[0])), "w")
    return


def banner():
    # TODO: Adjust this to size according to terminal width
    line = '=' * 80
    try:
        init()
        border = Fore.GREEN + "===============================================================================================" + Fore.RESET
        # ASCII Art Generator: http://patorjk.com/software/taag/#p=display&f=Graffiti&t=Type%20Something%20
        banner_msg = Fore.WHITE + """
 __      __.__            .___                    __________                __
/  \    /  \__| ____    __| _/______  _  ________ \______   \_____    ____ |  | ____ ________
\   \/\/   /  |/    \  / __ |/  _ \ \/ \/ /  ___/  |    |  _/\__  \ _/ ___\|  |/ /  |  \____ \\
 \        /|  |   |  \/ /_/ (  <_> )     /\___ \   |    |   \ / __ \   \___|    <|  |  /  |_> >
  \__/\  / |__|___|  /\____ |\____/ \/\_//____  >  |______  /(____  /\___  >__|_ \____/|   __/
       \/          \/      \/                 \/          \/      \/     \/     \/     |__|
                                v {0}\n""".format(__version__)

    except ImportError:
        border = line
        banner_msg = "Windows Backup Assist -- You should 'pip install colorama' for some flair!"
        banner_msg += "\t\t\t\tv {0}".format(__version__)

    return border + banner_msg + border


class ProgressBar(object):
    """
    A progress bar framework for use in file copying operations

    """
    def __init__(self, message, width=20, progressSymbol=u'\u00bb ', emptySymbol=u'\u002e '):
        self.width = width
        if self.width < 0:
            self.width = 0

        self.message = message
        self.progressSymbol = progressSymbol
        self.emptySymbol = emptySymbol

    def update(self, progress):
        totalBlocks = self.width
        filledBlocks = int(round(progress / (100 / float(totalBlocks)) ))
        emptyBlocks = totalBlocks - filledBlocks

        progressbar = Fore.CYAN + self.progressSymbol * filledBlocks + self.emptySymbol * emptyBlocks

        if not self.message:
            self.message = u''

        progressMessage = u'\r{0} {1} {2}{3}%'.format(self.message, progressbar, Fore.RESET, progress)

        sys.stdout.write(progressMessage)
        sys.stdout.flush()

    def calculate_update(self, done, total):
        progress = int(round( (done / float(total)) * 100) )
        self.update(progress)


def count_files(files):
    return len(files)


def create_input_list(input_list):
    """
    Receive an input list and clean up files and directories to build a clean list of files w/o any directory entries.
    This will serve to be a cleaned input file list for the backup zip file, which doesn't easily compress entire directories.

    :param input_list:
    :return:
    """
    # Enumerate the input file list and build a proper input list of files
    verified_list = []

    # Transform excludes glob patterns to regular expressions
    excludes = r'|'.join([fnmatch.translate(x) for x in LIST_EXCLUDES]) or r'$.'

    for item in input_list:
        # Check if input 'file' is a directory or file
        if os.path.isdir(item):
            for root, dirs, filenames in os.walk(item):
                # Exclude dirs we don't want before processing the walk
                dirs[:] = [os.path.join(root, d) for d in dirs]
                dirs[:] = [d for d in dirs if not re.match(excludes, d)]
                # exclude from files iter
                filenames = [os.path.join(root, f) for f in filenames]
                filenames = [f for f in filenames if not re.match(excludes, f)]
                #filenames = [f for f in filenames if re.match(includes, f)]

                for f in filenames:
                    verified_list.append(os.path.join(root, f))
        else:
            verified_list.append(item)

    if DEBUG:
        print(Fore.YELLOW + " [DEBUG :: create_input_list] " + Fore.RESET)
        print(verified_list)
        print("")

    return verified_list


def backup_to_zip(files, dest):
    """
    This function will receive a list of files to backup
    and will copy the files to the pre-defined backup path

    Usage: backup_to_zip(<list of files>, <backup destination folder path>)
    """

    # Check for removable device (defined in defaults.py or settings.py)
    if not os.path.exists(USB_DRIVE):
        if VERBOSE:
            print(Fore.RED + "[WARN]" + Fore.RESET + " USB Drive is not currently connected. Files will be skipped...")

    # Build the archive's resulting file name for the backup
    zip_name = BACKUP_PATH + os.sep + time.strftime('%Y%m%d') + '.zip'
    z = zipfile.ZipFile(zip_name, 'w')

    for file in files:
        # Filter out any patterns we want to skip
        if os.path.basename(file).startswith('~'):
            continue

        # Begin prepping and writing to the archive
        DST_FILE = os.path.join(dest, os.path.basename(file))

        if VERBOSE:
            print(Fore.GREEN + "[*]" + Fore.RESET + " Copying file: {}".format(str(file)))
        try:
            # Copy file; will fail if file is open or locked
            #shutil.copy2(file, DST_FILE)
            z.write(file)
            if DEBUG:
                print(Fore.YELLOW + " [DEBUG : backup_to_zip]" + Fore.RESET + " Copied: {}".format(str(file)))
        except Exception as e:
            if VERBOSE or DEBUG:
                print(Fore.RED + "[ERROR]" + Fore.RESET + " Error copying file: ", e)
            pass

    # Close the zip file when done
    z.close()
    return


def copy_files_with_progress(files, dst):
    """
    Take a list of files and copies them to a specified destination,
    while showing a progress bar for longer copy operations.

    Usage: copy_files_with_progress(<list of files>, <backup destination path>)
    """
    numfiles = count_files(files)
    numcopied = 0
    copy_error = []
    if numfiles > 0:
        for file in files:
            destfile = os.path.join(dst, os.path.basename(file))
            try:
                shutil.copy2(file, destfile)
                numcopied += 1
                if DEBUG:
                    print(" [DEBUG :: copy_files_with_progress] Copied: {}".format(str(file)))
            except:
                copy_error.append(file)
                files.remove(file)
                numfiles -= 1
                if DEBUG:
                    print(" [DEBUG :: copy_files_with_progress] Copy failed exception, file: {}".format(str(file)))
            p.calculate_update(numcopied, numfiles)

        print("\n")
        for f in copy_error:
            print("# ----[ Error copying file: {}".format(f))
    # Return the list, which may have removed files that were missing
    # This way, the next function to zip all files won't include them
    return files


def prune_old_backups(search_path, archive_pattern, keep_archives=10):
    """
    Parse the backups directory and remove certain archives to keep
    size consumed down.

    """
    matches = []
    for root, dirs, filenames in os.walk(search_path):
        for f in filenames:
            if f.endswith(('.zip')):
                matches.append(os.path.join(root, f))

    # TODO: Process this list of identified backup archives to
    #       1) identify valid ones based on our naming variable, and
    #       2) identify the 10 most recent (possibly exclude archives with identical hashes), and delete the rest.

    return matches


if __name__ == '__main__':
    # See if we are running this with python.exe or pythonw.exe
    check_python_binary()
    print(banner())

    # Import settings.py that we don't want stored in version control
    try:
        from settings import *
        # Copy the list of files to destination
        p = ProgressBar('# ----[ Beging Backup & Copy Procedures ]----')
        my_files = copy_files_with_progress(LIST_COPY_FILES, BACKUP_PATH)

        # Backup our larger list of input files to compressed archive
        my_file_list = create_input_list(LIST_BACKUP_FILES)
        backup_to_zip(my_file_list, BACKUP_PATH)


    except ImportError:
        # First time running script or for some reason settings.py doesn't exist
        # Create a fresh settings file with some defaults
        create_file('settings.py')
        print("\n [FIRST-RUN] A default 'settings.py' file has been created for you.")
        print(" [FIRST-RUN] Please update this file with a list of files and backup output path.")
        print(" [FIRST-RUN] Once 'settings.py' has been updated, run this script once more. "
              "Exiting...\n\n")
