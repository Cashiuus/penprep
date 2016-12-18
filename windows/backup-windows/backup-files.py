#!/usr/bin/env python
# -*- coding: utf-8 -*-
# =============================================================================
# Created:      01-July-2014          -           Revised Date:    03-June-2016
# File:         backup-files.py
# Depends:      colorama
# Compat:       2.7+
# Author:       Cashiuus - Cashiuus{at}gmail
#
# Purpose:      Backup certain files on a scheduled basis by running
#               this script from a scheduled task.
#               From specified USB drive to a specified Backups folder
#                   
# =============================================================================
## Copyright (C) 2015 Cashiuus@gmail.com
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
import os
import platform
import shutil
import sys
import time
import zipfile

# TODO: Make this have a fallback in case colorama is not installed.
from colorama import init, Fore

__version__ = 1.5
__author__ = 'Cashiuus'
VERBOSE = 0
# ========================[ CORE UTILITY FUNCTIONS ]======================== #
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
                           "FILE_LIST = [\n"
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
\   \/\/   /  |/    \  / __ |/  _ \ \/ \/ /  ___/  |    |  _/\__  \ _/ ___\|  |/ /  |  \____ \ 
 \        /|  |   |  \/ /_/ (  <_> )     /\___ \   |    |   \ / __ \\  \___|    <|  |  /  |_> >
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


def countFiles(FILE_LIST):
    return len(FILE_LIST)

    
def backup_to_zip(files, dest):
    """
    This function will receive a list of files to backup
    and will copy the files to the pre-defined backup path
    
    Usage: backup_to_zip(<list of files>, <backup destination folder path>)
    """
    
    # If USB drive is not connected, quit
    if not os.path.exists(USB_DRIVE):
        if VERBOSE == 1:
            print(Fore.RED + "# ----[" + Fore.RESET + " USB Drive is not currently connected. Files will be skipped...")
    
    # Build the archive's resulting file name for the backup
    zip_name = BACKUP_PATH + os.sep + time.strftime('%Y%m%d') + '.zip'
    z = zipfile.ZipFile(zip_name, 'w')

    # Then, iter through the files and back them up
    for file in files:
        DST_FILE = os.path.join(dest, os.path.basename(file))
        if VERBOSE == 1:
            print("# ----[ Copying File: {}".format(DST_FILE))
        try:
            # Copy file; will fail if file is open or locked
            shutil.copy2(file, DST_FILE)
            z.write(file)
        except Exception as e:
            if VERBOSE == 1:
                print(Fore.RED + "[-]" + Fore.RESET + " Error copying file: ", e)
            pass
    # Close the zip file when done
    z.close()
    return


def copy_files_with_progress(files, dst):
    """
    Take a list of files and copy them to a specified destination,
    while showing a progress bar for longer copy operations.
    
    Usage: copy_files_with_progress(<list of files>, <backup destination path>)
    """
    numfiles = countFiles(files)
    numcopied = 0
    copy_error = []
    if numfiles > 0:
        for file in files:
            destfile = os.path.join(dst, os.path.basename(file))
            try:
                shutil.copy2(file, destfile)
                numcopied += 1
            except:
                copy_error.append(file)
                files.remove(file)
                numfiles -= 1
                continue
            p.calculate_update(numcopied, numfiles)
        print("\n")
        for f in copy_error:
            print("# ----[ Error copying file: {}".format(f))
    # Return the list, which may have removed files that were missing
    # This way, the next function to zip all files won't include them
    return files


def prune_old_backups():
    """
    Parse the backups directory and remove certain archives to keep
    size consumed down.
    """
    pass
    return
    

if __name__ == '__main__':
    # See if we are running this with python.exe or pythonw.exe
    check_python_binary()

    print(banner())

    # Import settings.py that we don't want stored in version control
    try:
        from settings import *
        # Copy the list of files to destination, then also zip them all into a
        # destination .zip file
        p = ProgressBar('# ----[ Creating Backup ]----')
        my_files = copy_files_with_progress(FILE_LIST, BACKUP_PATH)
        backup_to_zip(my_files, BACKUP_PATH)
    except ImportError:
        # First time running script or for some reason settings.py doesn't exist
        # Create a fresh settings file with some defaults
        create_file('settings.py')
        print("\n [FIRST-RUN] A default 'settings.py' file has been created for you.")
        print(" [FIRST-RUN] Please update this file with a list of files and backup output path.")
        print(" [FIRST-RUN] Once 'settings.py' has been updated, run this script once more. "
              "Exiting...\n\n")
