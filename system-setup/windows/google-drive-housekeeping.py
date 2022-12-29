#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ==============================================================================
# File:         google-drive-housekeeping.py
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
try:
    input = raw_input
except NameError:
    pass
try:
    import thread
except ImportError:
    import _thread as thread
import errno
import os
import sys
from decimal import Decimal


GREEN = '\033[32;1m'  # Green
BLUE = '\033[01;34m'  # Heading
YELLOW = '\033[01;33m'  # Warnings/Information
RED = '\033[31m'  # Red/Error
ORANGE = '\033[33m'  # Orange/Debug
RESET = '\033[00m'  # Normal/White


GOOGLE_PATH = r'C:\Users\cashi\Google Drive'
# File size param by which script will search for files larger than this value, Default: 1 GB
MAX_FILE_SIZE = 100000000


# ========= File Size Conversion Code ============ #
SUFFIXES = 'B', 'KB', 'MB', 'GB', 'TB', 'PB'

def filesize_human_readable(nbytes):
    """
    Receive a size in bytes and convert to human-readable file size
    :param nbytes: 
    :return: 
    """
    if nbytes == 0: return '0 B'
    #print("[DEBUG] nbytes param provided: {}".format(repr(nbytes)))

    #i = 0
    #while nbytes >= 1024 and i < len(SUFFIXES) - 1:
    #    nbytes /= 1024.
    #    i += 1
    # Better way of iterating the suffixes
    for s in SUFFIXES:
        if nbytes < 1024:
            break
        nbytes /= 1024.

    #value_human = ('%.2f' % nbytes).rstrip('0').rstrip('.')
    # Better py2 way of doing this
    value_human = Decimal(nbytes).quantize(Decimal('0.00')).normalize()
    # Best way - python 3 - and you could remove the check for '0' at beginning of function
    #value_human = round(Decimal(15.9990234375), 2).normalize()

    #return '%s, %s' % (value_human, SUFFIXES[i])
    return '{} {}'.format(value_human, s)


def file_dist(path, start, end):
    """
    
    :param path: 
    :param start: 
    :param end: 
    :return: 
    """

    # Great info: https://codereview.stackexchange.com/questions/77008/number-of-files-with-specific-file-size-ranges
    for start in [0, 1024, 4096, 16384, 262144, 1048577, 4194305]:
        end = start * 4
    #file_dist(GOOGLE_PATH, start, end)


def shutdown_app():
    print("Application shutting down -- Goodbye!")
    exit(0)
# ==========================[ BEGIN APPLICATION ]========================== #


def find_large_files(path, sizelimit):
    """
    Search directory provided for all files larger than 'sizelimit'
    :param path: 
    :param sizelimit: 
    :return: 
    """

    flist = []
    # Enum the specified parent folder
    #for root, dirs, filenames in os.walk(path):
    for root, dirs, filenames in os.walk(unicode(path)):
        for f in filenames:
            # Default gets file size in Bytes
            #fsize = os.path.getsize(os.path.join(root, f))
            fsize = os.lstat(os.path.join(root, f)).st_size
            if fsize > sizelimit:
                # If file greater than x size, add to list
                print("[+] Large File Found: {} - {}".format(filesize_human_readable(fsize), os.path.join(root, f)))
                flist.append(os.path.join(root, f))



def main():

    #if sys.argv[1]:
    #    MAX_FILE_SIZE = sys.argv[1]

    try:
        # main application flow
        print("[*] Searching directory for large files...\n\n")
        find_large_files(GOOGLE_PATH, MAX_FILE_SIZE)
    except KeyboardInterrupt:
        shutdown_app()
    return


if __name__ == '__main__':
    main()
