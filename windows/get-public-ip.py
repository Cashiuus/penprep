#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ==============================================================================
# Created:      01-July-2014         -           Revised:   02-May-2016
# File:         get-public-ip.py
# Depends:      mechanize
# Compat:       2.7+
# Author:       Cashiuus - Cashiuus{at}gmail
#
# Purpose:      This will get public IP and store in log file with
#               date providing a record of what my IP is each day.
#
# ==============================================================================
## Copyright (C) 2016 Cashiuus@gmail.com
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
# ========================================================================
from __future__ import absolute_import
from __future__ import print_function
## =======[ IMPORTS & CONSTANTS ]========= ##
import datetime
import os

import mechanize

LOG_FILE = 'public-ip.log'

# ========================[ CORE UTILITY FUNCTIONS ]======================== #
# Setup the browser object and necessary HTTP headers
br = mechanize.Browser()
br.add_headers = [('User-agent', 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.114 Safari/537.36')]

# Does log file exist yet?
if not os.path.isfile(LOG_FILE):
    with open(LOG_FILE, 'w') as f:
        f.write('# =============[ Public IP Address Log ]============= #\n')

# The 'with' context manager closes the file for us when it's done
with open(LOG_FILE, 'a') as f:
    f.write('\n')
    # Get IP and save it
    try:
        response = br.open('http://api.ipify.org')
        response = response.read()
        print("Public IP: {}\n".format(response))
        output = str(datetime.date.today()) + '\t' + response
        # Write my IP to file
        f.write(output)
    except:
        print("[-] Error with HTTP Request")
