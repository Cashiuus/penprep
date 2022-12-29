#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ==============================================================================
# Compat:       3.5+


# ==============================================================================
import datetime
import os

LOG_FILE = 'public-ip.log'


def init_logfile():
    """
    Standard function to check our defined log file, ensure we can access it, and
    do all initialization actions needed to use it for this script.
    :return:
    """
    # Does log file exist yet?
    if not os.path.isfile(LOG_FILE):
        with open(LOG_FILE, 'w') as f:
            f.write('# =============[ Public IP Address Log ]============= #\n')
    return


def get_ipify():
    """
    Use the requests library to get public IP. This is based on ipify's recommended code.
    :return:
    """
    from requests import get

    ip = get('https://api.ipify.org').text
    print('My Public IP: {}'.format(ip))
    output = str(datetime.date.today()) + '\t' + ip
    with open(LOG_FILE, 'a') as f:
        f.write('\n')
        f.write(output)

    return


def alternate():
    """
    Another way of getting public IP using Python 3 standard libraries only.
    :return:
    """
    import urllib.request
    ip = urllib.request.urlopen('https://ident.me').read().decode('utf-8')
    print('My Public IP: {}'.format(ip))
    return


def main():
    init_logfile()
    get_ipify()

    return


if __name__ == '__main__':
    main()
