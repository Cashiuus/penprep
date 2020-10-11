#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# File:
# Depends:
# Compat:       3.7
# Created:      11-Oct-2020  -   Revised:
# Author:       Cashiuus - Cashiuus@gmail.com
#
# Purpose:
#
# ==============================================================================
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
try:
    # Always use input() regardless of Python version
    input = raw_input
except NameError:
    pass
# ============================[ IMPORT & CONSTANTS ]============================
__version__ = 0.1
__author__ = 'Cashiuus'
RED = '\033[31m' # red
GREEN = '\033[32m' # green
CYAN = '\033[36m' # cyan
WHITE = '\033[0m'  # white


import os
import platform
import sys

APP_BASE = os.path.dirname(os.path.realpath(__file__))

# ==========================[           ]==========================

if platform.system() == 'Linux':
    if os.geteuid() != 0:
        print('\n' + RED + '[-]' + CYAN + ' Please Run as Root!' + '\n')
        sys.exit()
    else:
        pass
else:
    pass










def main():

    return


if __name__ == '__main__':
    main()
