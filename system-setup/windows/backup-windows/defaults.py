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


# List of directories to exclude from the archive.
# This is to prevent unneeded junk from making our archive size too large.
LIST_EXCLUDES = [
    'LiveContent',
]

# This is a small list of files we want to directly copy over to our destination,
# such as files we want to cloud sync so we can access them from multiple systems.
LIST_COPY_FILES = [


]

# This is a larger list of files/directories you wish to backup into a compressed archive.
LIST_BACKUP_FILES = [

    # Example files to get you started. Note, you need the 'r' prefix for 'raw' assignments
    # to properly handle Windows backslashes in file paths, or you must escape them all.
    # -- SYSTEM FILES --
    r'C:\Windows\System32\drivers\etc\hosts',

    # -- CUSTOM USER FILES --


    # -- APPLICATION SETTINGS FILES --
    # You can also include files using os.path as below
    os.path.join(PATH_APPDATA, 'Microsoft', 'Excel', 'Excel14.xlb'),
    # - Microsoft Office Templates and Files
    # *NOTE: This path below is a directory, not a file. The script will backup all files in entries that are directories!
    os.path.join(PATH_APPDATA, 'Microsoft', 'Templates'),

]
