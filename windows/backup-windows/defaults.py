# File:			settings.py
# Purpose:		This is a list of settings, to include the files, and output dir.
# =============================================================================
import os


# If any source files are on a USB Drive, specify its letter here.
# The script checks that it's connected to avoid a conflict if it's
# not connected. If not using a USB, just leave variable blank.
USB_DRIVE = ''

BACKUP_PATH = os.path.join(os.path.expanduser('~'), 'Backups', 'Windows')

# Designate a file prefix for the output archive. This prefix will
# prepend a datestamp; e.g. 'Backup-Windows-20160503.zip
BACKUP_PREFIX = 'Backup-Windows-'

# Populate the empty list below with files you want to backup
FILE_LIST = [



]
