#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ==============================================================================
# File:         file.py
# Author:       Cashiuus
# Created:      10-DEC-2016     -     Revised:
#
# Depends:      n/a
# Compat:       2.7+ or 3.5+
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
#  Copyright (C) 2016 Cashiuus <cashiuus@gmail.com>
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
__version__ = 0.1
__author__ = 'Cashiuus'
## ====[ Python 2/3 Compatibilities ]==== ##
try: input = raw_input
except NameError: pass
try: import thread
except ImportError: import _thread as thread
## =======[ IMPORT & CONSTANTS ]========= ##
import errno
import os

## ========[ TEXT COLORS ]=============== ##
GREEN = '\033[32;1m'    # Green
BLUE = '\033[01;34m'    # Heading
YELLOW = '\033[01;33m'  # Warnings/Information
RED = '\033[31m'        # Red/Error
ORANGE = '\033[33m'     # Orange/Debug
RESET = '\033[00m'      # Normal/White
# ========================[ CORE UTILITY FUNCTIONS ]======================== #
# Check - Root user
# TODO: If not root, run with sudo
def root_check():
    if not (os.geteuid() == 0):
        print("[-] Not currently root user. Please fix.")
        exit(1)
    return

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


def shutdown_app():
    print("Application shutting down -- Goodbye!")
    exit(0)
# ==========================[ BEGIN APPLICATION ]========================== #



def main():
    try:
        # main application flow

    except KeyboardInterrupt:
        shutdown_app()
    return


if __name__ == '__main__':
    main()
