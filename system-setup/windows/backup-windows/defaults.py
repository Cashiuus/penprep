# File:			defaults.py
#
# Purpose:		This is a list of settings, to include a USB drive, if applicable,
#               the source files you want to backup, the output directory backups should
#               save to, and a prefix that will be used in naming the '.zip' archive.
#
#               This is the default file that comes pre-bundled
#
# =======================================================================================
import os


# If any source files are on a USB Drive, specify its letter here.
# The script checks that it's connected to avoid a conflict if it's
# not connected. If not using a USB, just leave variable blank.
USB_DRIVE = ''

BACKUP_PATH = os.path.join(os.path.expanduser('~'), 'Backups', 'Windows')

# Designate a file prefix for the output archive. This prefix will
# prepend a date-stamp; e.g. 'Backup-Windows-20160503.zip
BACKUP_PREFIX = 'Backup-Windows-'

# ===[ Get our user-based paths ]===
HOME_DRIVE = os.environ.get('HOMEDRIVE')
USER_NAME = os.environ.get('USERNAME')
PATH_USER_HOME = os.environ.get('USERPROFILE')
PATH_APPDATA = os.environ.get('APPDATA')
PATH_LOCALAPPDATA = os.environ.get('LOCALAPPDATA')

# Populate the empty list below with files you want to backup
FILE_LIST = [

    # Example files to get you started. Note, you need the 'r' prefix for 'raw' assignments
    # to properly handle Windows backslashes in file paths, or you must escape them all.
    # -- SYSTEM FILES --
    r'C:\Windows\System32\drivers\etc\hosts',

    # -- CUSTOM USER FILES --


    # -- APPLICATION SETTINGS FILES --
    # You can also include files using os.path as below
    os.path.join(PATH_APPDATA, 'Microsoft', 'Excel', 'Excel14.xlb'),

]
