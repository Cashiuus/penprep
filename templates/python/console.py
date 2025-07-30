#!/usr/bin/env python
#
# ===================================================================
# File:				console.py
# Dependencies:		n/a
# Compatibility:	2.x
#
# Creation Date:	7/10/2014   - Revised: 9/7/2023
# Author:			Cashiuus - Cashiuus@gmail.com
#
# Purpose:			Utility for rendering applications via console
#					menu-driven interface.
#					To quit, enter 'q' or 'quit'
# ===================================================================
## Copyright (C) 2023 Cashiuus [at] gmail.com
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
#
# ===================================================================
import os
import textwrap


DEFAULT_CMDS = 	{
            'listen': 'Show list of hosts in database',
            'capture': 'Show list of services in database',
            'crack': 'Attempt to crack the collected data',
            'help': 'Show the complete Help information',
            }

DEFAULT_TITLE = """
/========================================================/
        PYTHON CONSOLE APPLICATION
/========================================================/
"""

class ConsoleViewer(object):
    """
    Print formatted console view for interactive
    menu-driven applications

    Usage: ConsoleViewer(cmds, [custom_title=[]])

    cmds			*Required* - Dictionary of commands and descrips
    custom_title		Must be a list of lines to build title
    """
    def __init__(self, cmds=DEFAULT_CMDS, custom_title=None):
        # get the width of the current console
        self.width = 70
        self.cmds = cmds
        if custom_title == None:
            self.custom_title = None
        else:
            self.custom_title = custom_title

        self.app_title()
        self.app_menu()


    def app_title(self):
        os.system('clear')
        if self.custom_title == None:
            print(DEFAULT_TITLE)
        else:
            # if the provided title is a list type
            for line in self.custom_title:
                print(line)
        print('\n\n')
        return


    def app_menu(self):
        # textwrapping
        # lines = textwrap.wrap(textwrap.dedent(desc).strip(), width=30)
        for k,v in self.cmds.items():
            print("\t%s\t%s" % ('{0: <12}'.format(k), v))
        return


    def app_prompt(self):
        # Return prompt to bottom of console
        skiplines = 10
        skip = '\n' * skiplines
        print(skip)
        # This can either go straight to console
        # or be appended to a list of strings to
        # flush to the screen all at once
        prompt = input("[>>>] Enter selection: ")
        if prompt.lower() == 'q' or prompt.lower() == 'quit':
            self.shutdown()
        else:
            return prompt.lower()


    def print_color(self, text, color='Green'):

        colors = 	{
                    'green': '\e[1m\e[32m',
                    'blue': '\e[1m\e[34m',
                    'red': '\e[1m\e[31m',
                    'orange': '\e[1m\e[33m',
                    'magenta': '\e[1m\e[35m',
                    'cyan': '\e[1m\e[36m',
                    'gray': '\e[37m'
                    }

        if color.lower() in colors.keys():
            print(colors.value(), text, '\e[0m')
        return


    def print_table(self, table, header=None):
        # This will receive a list of tuples from its caller
        if header is not None:
            for elem in header:
                print('\t%s' % ('{0: <7}'.format(elem)))
        try:
            tablesize = len(table)
            for row in table:
                host, ipaddr, os, args = table
                prow = '%(host)\t%(ipaddr)\t%(os)'
                print(prow)
        except:
            pass


    def shutdown(self):
        print("Application Shutting Down -- Goodbye!")
        self = None
        #os.system('clear')
        exit()
# ----------------------------------------------------



def main():
    cv = ConsoleViewer()
    while 1:
        try:
            cv.app_title()
            cv.app_menu()
            getcmd = cv.app_prompt()
        except KeyboardInterrupt:
            cv.shutdown()
    return

if __name__ == '__main__':
    main()