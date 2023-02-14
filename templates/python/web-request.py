#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
#
#
# - Requests Help: https://docs.python-requests.org/en/master/user/quickstart/#timeouts
#
# ==============================================================================
__version__ = '0.0.1'
__author__ = 'Cashiuus'
__license__ = 'MIT'
__copyright__ = 'Copyright (C) 2023 Cashiuus'


import argparse
import os
import re
import sys

from pathlib import Path

import requests
from colorama import Fore, Back, Style

requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)

APP_DIR = Path(__file__).resolve(strict=True).parent

UA_Chrome = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
UA_ChromeMobile = "Mozilla/5.0 (Linux; Android 7.0; SM-G930V Build/NRD90M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.125 Mobile Safari/537.36"

headers = {'user-agent': UA_Chrome}


def jitter_delay(i_max=8):
    """Generate random number for sleep function
            Usage: time.sleep(jitter_delay(i_max=25))
    """
    return randrange(2, i_max, 1)


def format_text(title, item):
    cr = '\n'
    section_break = cr + "*" * 20 + cr
    item = str(item)
    text = ''
    try:
        text = Style.BRIGHT + Fore.RED + title + Fore.RESET + section_break + item + section_break
    except:
        text = f"{title}{section_break}{item}{section_break}"
    return text







def main():
    """
        This script will issue a web request to your target and output the response values
        that include: response code, headers, cookies, and text.

        Usage: script.py <Target_URL> [-p|--proxy]
    """

    parser = argparse.ArgumentParser(description="Template for handling custom web requests")
    parser.add_argument('target', help='URL of target to issue request') # positional arg
    parser.add_argument("-p", "--proxy", dest='proxy', action="store_true",
                        help="Enable proxying the request through defined proxies")

    parser.add_argument('-w', '--wordlist', help='wordlist to use')
    parser.add_argument("-d", "--debug", dest='debug', action="store_true",
                        help="Display extra debug information")
    parser.add_argument('--version', action='version', version='%(prog)s %(__version__)s')
    args = parser.parse_args()

    # If we have a mandatory arg, use it here; if not given, display usage
    if not args.target:
        parser.print_help()
        exit(1)

    if not args.proxy:
        proxies = None
    else:
        proxies = {'http':'http://127.0.0.1:8080', 'https':'http://127.0.0.1:8080'}

    try:
        r = requests.get(args.target, verify=False, timeout=7,
                         proxies=proxies,
                         headers=headers)

        print(format_text('r.status_code is: ', r.status_code))
        print(format_text('r.headers is: ', r.headers))
        print(format_text('r.cookies is: ', r.cookies))
        print(format_text('r.text is: ', r.text))
    except requests.exceptions.ConnectionError as e:
        print("[ERROR] HTTP Connection Error: {}".format(e))

    return


if __name__ == '__main__':
    main()
