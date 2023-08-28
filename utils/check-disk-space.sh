#!/bin/bash

### Helper to show disk usage problem areas when you need to reduce consumed disk space


# Get a basic snapshot of the overall system first
df -h



# Start investigating for areas of the system that are causing issues
du -h --summarize /bin 2>/dev/null
du -h --summarize /dev 2>/dev/null
du -h --summarize /etc 2>/dev/null
du -h --summarize /home 2>/dev/null
du -h --summarize /opt 2>/dev/null
du -h --summarize /root 2>/dev/null
du -h --summarize /tmp 2>/dev/null
du -h --summarize /usr 2>/dev/null
du -h --summarize /var 2>/dev/null


# Instead of the above, we can achieve this by adding in one-file-system so it skips the externally mounted drive(s)

# NOTE: if this doesn't work, check your aliases, there might be a "du=du -s -h" screwing it up by adding summarize
du -h --one-file-system --max-depth=1 / 2>/dev/null
echo -e '\n\n'


# if we have tree, we can use that as well



# Find large files only on local filesystem (-xdev) not mounted shares
find / -size +1G -xdev 2>/dev/null


### Some basic housekeeping cleanup quick wins

sudo apt-get clean all          # or yum clean all
sudo rm -rf /var/cache/apt
sudo rm -rf /var/cache/yum


# Manage your journal log space, keep the directory but delete all of the files
journalctl --disk-usage
sudo rm -rf /var/log/journal/*
ls -al /var/log/journal/
journalctl --disk-usage

# or we can do it this way, removing files until the dir is below this threshold of 100 MB
sudo journalctl --vacuum-size=100M

# also decrease the limit on how much space journal can use
#       Uncomment and set: SystemMaxUse=50M
sudo nano /etc/systemd/journald.conf



# Enable compression in logrotate
# Uncomment the line: compress
sudo nano /etc/logrotate.conf


# However, our main problem is that /var/lib has 12 GB of consumed space alone
# If we need to see the size of everything in this directory,
# we can do this:
#cd /var/lib
#du -k 2>/dev/null




# VMware Drag-and-drop directory
# in a user's .cache directory, you have this directory storing files
# you've copied in or out. If those were large, this takes up a lot of space
DIR_PATH="${HOME}/.cache/vmware/drag_and_drop"
ls -al "${DIR_PATH}"
sudo rm -rf "${DIR_PATH}"/*
ls -al "${DIR_PATH}"





